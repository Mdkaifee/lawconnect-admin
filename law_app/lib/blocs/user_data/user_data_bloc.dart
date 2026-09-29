import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/note_model.dart';
import '../../models/bookmark_model.dart';
import '../../repositories/user_data_repository.dart';

// Events
abstract class UserDataEvent extends Equatable {
  const UserDataEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserDataEvent extends UserDataEvent {}
class RefreshUserDataSilentlyEvent extends UserDataEvent {}

class SaveNoteEvent extends UserDataEvent {
  final String? id;
  final String title;
  final String content;
  final String refType;
  final String? refId;
  final String? refTitle;

  const SaveNoteEvent({
    this.id,
    required this.title,
    required this.content,
    this.refType = 'general',
    this.refId,
    this.refTitle,
  });

  @override
  List<Object?> get props => [id, title, content, refType, refId, refTitle];
}

class DeleteNoteEvent extends UserDataEvent {
  final String id;
  const DeleteNoteEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleBookmarkEvent extends UserDataEvent {
  final String refType;
  final String refId;
  final String title;
  final String? subtitle;

  const ToggleBookmarkEvent({
    required this.refType,
    required this.refId,
    required this.title,
    this.subtitle,
  });

  @override
  List<Object?> get props => [refType, refId, title, subtitle];
}

class LogHistoryEvent extends UserDataEvent {
  final String refType;
  final String refId;
  final String title;
  const LogHistoryEvent({required this.refType, required this.refId, required this.title});
  @override
  List<Object?> get props => [refType, refId, title];
}

class ClearHistoryEvent extends UserDataEvent {}

// States
abstract class UserDataState extends Equatable {
  const UserDataState();
  @override
  List<Object?> get props => [];
}

class UserDataInitial extends UserDataState {}

class UserDataLoading extends UserDataState {}

class UserDataLoaded extends UserDataState {
  final List<NoteModel> notes;
  final List<BookmarkModel> bookmarks;
  final List<Map<String, dynamic>> history;

  const UserDataLoaded({
    this.notes = const [],
    this.bookmarks = const [],
    this.history = const [],
  });

  bool isBookmarked(String refId) {
    return bookmarks.any((b) => b.refId == refId);
  }

  @override
  List<Object?> get props => [notes, bookmarks, history];
}

class UserDataError extends UserDataState {
  final String message;
  const UserDataError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class UserDataBloc extends Bloc<UserDataEvent, UserDataState> {
  final UserDataRepository _userDataRepository;

  UserDataBloc({required UserDataRepository userDataRepository})
      : _userDataRepository = userDataRepository,
        super(UserDataInitial()) {
    on<LoadUserDataEvent>(_onLoadUserData);
    on<RefreshUserDataSilentlyEvent>(_onRefreshSilently);
    on<SaveNoteEvent>(_onSaveNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<LogHistoryEvent>(_onLogHistory);
    on<ClearHistoryEvent>(_onClearHistory);
  }

  Future<void> _onLoadUserData(LoadUserDataEvent event, Emitter<UserDataState> emit) async {
    emit(UserDataLoading());
    try {
      final results = await Future.wait([
        _userDataRepository.getNotes(),
        _userDataRepository.getBookmarks(),
        _userDataRepository.getHistory(),
      ]);

      emit(UserDataLoaded(
        notes: results[0] as List<NoteModel>,
        bookmarks: results[1] as List<BookmarkModel>,
        history: results[2] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(UserDataError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshSilently(RefreshUserDataSilentlyEvent event, Emitter<UserDataState> emit) async {
    try {
      final results = await Future.wait([
        _userDataRepository.getNotes(),
        _userDataRepository.getBookmarks(),
        _userDataRepository.getHistory(),
      ]);
      emit(UserDataLoaded(
        notes: results[0] as List<NoteModel>,
        bookmarks: results[1] as List<BookmarkModel>,
        history: results[2] as List<Map<String, dynamic>>,
      ));
    } catch (_) {
      // Preserve the current data when a background refresh fails.
    }
  }

  Future<void> _onSaveNote(SaveNoteEvent event, Emitter<UserDataState> emit) async {
    try {
      await _userDataRepository.saveNote(
        id: event.id,
        title: event.title,
        content: event.content,
        refType: event.refType,
        refId: event.refId,
        refTitle: event.refTitle,
      );
      add(LoadUserDataEvent());
    } catch (e) {
      emit(UserDataError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<UserDataState> emit) async {
    try {
      await _userDataRepository.deleteNote(event.id);
      add(LoadUserDataEvent());
    } catch (e) {
      emit(UserDataError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleBookmark(ToggleBookmarkEvent event, Emitter<UserDataState> emit) async {
    try {
      if (state is UserDataLoaded) {
        final current = state as UserDataLoaded;
        final alreadyBookmarked = current.isBookmarked(event.refId);

        if (alreadyBookmarked) {
          await _userDataRepository.removeBookmark(event.refId);
        } else {
          await _userDataRepository.addBookmark(
            refType: event.refType,
            refId: event.refId,
            title: event.title,
            subtitle: event.subtitle,
          );
        }
        add(LoadUserDataEvent());
      }
    } catch (e) {
      emit(UserDataError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogHistory(LogHistoryEvent event, Emitter<UserDataState> emit) async {
    await _userDataRepository.logHistory(refType: event.refType, refId: event.refId, title: event.title);
  }

  Future<void> _onClearHistory(ClearHistoryEvent event, Emitter<UserDataState> emit) async {
    await _userDataRepository.clearHistory();
    add(LoadUserDataEvent());
  }
}

