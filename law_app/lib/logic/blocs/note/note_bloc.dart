import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/note_repository.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository _noteRepository;

  NoteBloc(this._noteRepository) : super(NoteInitial()) {
    on<FetchNotesEvent>(_onFetchNotes);
    on<AddNoteEvent>(_onAddNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
  }

  Future<void> _onFetchNotes(FetchNotesEvent event, Emitter<NoteState> emit) async {
    emit(NoteLoading());
    try {
      final notes = await _noteRepository.getNotes(refType: event.refType);
      emit(NotesLoaded(
        notes: notes,
        selectedTab: event.refType == 'case' ? 'By Case' : 'All Notes',
      ));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onAddNote(AddNoteEvent event, Emitter<NoteState> emit) async {
    try {
      await _noteRepository.createNote(
        title: event.title,
        content: event.content,
        refType: event.refType,
        refId: event.refId,
        refTitle: event.refTitle,
      );
      add(FetchNotesEvent(refType: event.refType));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NoteState> emit) async {
    try {
      await _noteRepository.updateNote(
        id: event.id,
        title: event.title,
        content: event.content,
      );
      add(const FetchNotesEvent());
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NoteState> emit) async {
    try {
      await _noteRepository.deleteNote(event.id);
      add(const FetchNotesEvent());
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }
}
