import 'package:equatable/equatable.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();
  @override
  List<Object?> get props => [];
}

class FetchNotesEvent extends NoteEvent {
  final String? refType;
  const FetchNotesEvent({this.refType});

  @override
  List<Object?> get props => [refType];
}

class AddNoteEvent extends NoteEvent {
  final String title;
  final String content;
  final String? refType;
  final String? refId;
  final String? refTitle;

  const AddNoteEvent({
    required this.title,
    required this.content,
    this.refType,
    this.refId,
    this.refTitle,
  });

  @override
  List<Object?> get props => [title, content, refType, refId, refTitle];
}

class UpdateNoteEvent extends NoteEvent {
  final String id;
  final String title;
  final String content;

  const UpdateNoteEvent({
    required this.id,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [id, title, content];
}

class DeleteNoteEvent extends NoteEvent {
  final String id;
  const DeleteNoteEvent(this.id);

  @override
  List<Object?> get props => [id];
}
