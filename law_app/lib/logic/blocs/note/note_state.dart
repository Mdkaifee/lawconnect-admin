import 'package:equatable/equatable.dart';
import '../../../data/models/note_model.dart';

abstract class NoteState extends Equatable {
  const NoteState();
  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NotesLoaded extends NoteState {
  final List<NoteModel> notes;
  final String selectedTab;

  const NotesLoaded({
    required this.notes,
    this.selectedTab = 'All Notes',
  });

  @override
  List<Object?> get props => [notes, selectedTab];
}

class NoteError extends NoteState {
  final String message;
  const NoteError(this.message);

  @override
  List<Object?> get props => [message];
}
