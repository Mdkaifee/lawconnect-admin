import 'package:equatable/equatable.dart';
import '../../../data/models/post_model.dart';

abstract class PostState extends Equatable {
  const PostState();
  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostsLoaded extends PostState {
  final List<PostModel> posts;
  final String selectedTab;

  const PostsLoaded({
    required this.posts,
    this.selectedTab = 'All',
  });

  @override
  List<Object?> get props => [posts, selectedTab];
}

class PostActionSuccess extends PostState {
  final String message;
  const PostActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PostError extends PostState {
  final String message;
  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}
