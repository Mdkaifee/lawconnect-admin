import 'package:equatable/equatable.dart';

abstract class BookmarkEvent extends Equatable {
  const BookmarkEvent();
  @override
  List<Object?> get props => [];
}

class FetchBookmarksEvent extends BookmarkEvent {
  final String? refType; // 'case' / 'section' / 'post' / 'notes'
  const FetchBookmarksEvent({this.refType});

  @override
  List<Object?> get props => [refType];
}

class ToggleBookmarkEvent extends BookmarkEvent {
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

class RemoveBookmarkEvent extends BookmarkEvent {
  final String id;
  const RemoveBookmarkEvent(this.id);

  @override
  List<Object?> get props => [id];
}
