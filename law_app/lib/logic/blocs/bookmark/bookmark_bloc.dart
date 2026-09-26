import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/bookmark_repository.dart';
import 'bookmark_event.dart';
import 'bookmark_state.dart';

class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  final BookmarkRepository _bookmarkRepository;

  BookmarkBloc(this._bookmarkRepository) : super(BookmarkInitial()) {
    on<FetchBookmarksEvent>(_onFetchBookmarks);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<RemoveBookmarkEvent>(_onRemoveBookmark);
  }

  Future<void> _onFetchBookmarks(FetchBookmarksEvent event, Emitter<BookmarkState> emit) async {
    emit(BookmarkLoading());
    try {
      final bookmarks = await _bookmarkRepository.getBookmarks(refType: event.refType);
      emit(BookmarksLoaded(
        bookmarks: bookmarks,
        selectedTab: _getTabLabel(event.refType),
      ));
    } catch (e) {
      emit(BookmarkError(e.toString()));
    }
  }

  Future<void> _onToggleBookmark(ToggleBookmarkEvent event, Emitter<BookmarkState> emit) async {
    try {
      await _bookmarkRepository.addBookmark(
        refType: event.refType,
        refId: event.refId,
        title: event.title,
        subtitle: event.subtitle,
      );
      add(FetchBookmarksEvent(refType: event.refType));
    } catch (e) {
      emit(BookmarkError(e.toString()));
    }
  }

  Future<void> _onRemoveBookmark(RemoveBookmarkEvent event, Emitter<BookmarkState> emit) async {
    try {
      await _bookmarkRepository.removeBookmark(event.id);
      add(const FetchBookmarksEvent());
    } catch (e) {
      emit(BookmarkError(e.toString()));
    }
  }

  String _getTabLabel(String? refType) {
    switch (refType) {
      case 'case':
        return 'Cases';
      case 'section':
        return 'Sections';
      case 'post':
        return 'Posts';
      case 'note':
        return 'Notes';
      default:
        return 'Cases';
    }
  }
}
