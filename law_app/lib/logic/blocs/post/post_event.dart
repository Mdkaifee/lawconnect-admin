import 'package:equatable/equatable.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();
  @override
  List<Object?> get props => [];
}

class FetchPostsEvent extends PostEvent {
  final String? scope; // 'all' / 'mine'
  final String? query;
  final bool refresh;

  const FetchPostsEvent({this.scope = 'all', this.query, this.refresh = false});

  @override
  List<Object?> get props => [scope, query, refresh];
}

class CreatePostEvent extends PostEvent {
  final String title;
  final String content;
  final String? category;
  final List<String>? tags;

  const CreatePostEvent({
    required this.title,
    required this.content,
    this.category,
    this.tags,
  });

  @override
  List<Object?> get props => [title, content, category, tags];
}

class LikePostEvent extends PostEvent {
  final String id;
  const LikePostEvent(this.id);

  @override
  List<Object?> get props => [id];
}
