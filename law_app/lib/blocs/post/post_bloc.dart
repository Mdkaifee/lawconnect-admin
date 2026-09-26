import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/post_model.dart';
import '../../repositories/post_repository.dart';

// Events
abstract class PostEvent extends Equatable {
  const PostEvent();
  @override
  List<Object?> get props => [];
}

class LoadPostsEvent extends PostEvent {
  final String? category;
  final String? query;
  const LoadPostsEvent({this.category, this.query});
  @override
  List<Object?> get props => [category, query];
}

class CreatePostEvent extends PostEvent {
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  const CreatePostEvent({required this.title, required this.content, required this.category, this.tags = const []});
  @override
  List<Object?> get props => [title, content, category, tags];
}

class ToggleLikePostEvent extends PostEvent {
  final String postId;
  const ToggleLikePostEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class LoadCommentsEvent extends PostEvent {
  final String postId;
  const LoadCommentsEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class AddCommentEvent extends PostEvent {
  final String postId;
  final String content;
  const AddCommentEvent({required this.postId, required this.content});
  @override
  List<Object?> get props => [postId, content];
}

class ReportPostEvent extends PostEvent {
  final String postId;
  final String reason;
  const ReportPostEvent({required this.postId, required this.reason});
  @override
  List<Object?> get props => [postId, reason];
}

// States
abstract class PostState extends Equatable {
  const PostState();
  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<PostModel> posts;
  final String? selectedCategory;
  const PostLoaded(this.posts, {this.selectedCategory});
  @override
  List<Object?> get props => [posts, selectedCategory];
}

class PostError extends PostState {
  final String message;
  const PostError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _postRepository;

  PostBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(PostInitial()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<CreatePostEvent>(_onCreatePost);
    on<ToggleLikePostEvent>(_onToggleLike);
    on<AddCommentEvent>(_onAddComment);
    on<ReportPostEvent>(_onReportPost);
  }

  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostState> emit) async {
    emit(PostLoading());
    try {
      final posts = await _postRepository.getPosts(category: event.category, query: event.query);
      emit(PostLoaded(posts, selectedCategory: event.category));
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePost(CreatePostEvent event, Emitter<PostState> emit) async {
    try {
      final newPost = await _postRepository.createPost(
        title: event.title,
        content: event.content,
        category: event.category,
        tags: event.tags,
      );
      if (state is PostLoaded) {
        final currentPosts = (state as PostLoaded).posts;
        emit(PostLoaded([newPost, ...currentPosts], selectedCategory: (state as PostLoaded).selectedCategory));
      } else {
        add(const LoadPostsEvent());
      }
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleLike(ToggleLikePostEvent event, Emitter<PostState> emit) async {
    if (state is! PostLoaded) return;
    final currentState = state as PostLoaded;

    // Optimistically toggle like
    final updatedPosts = currentState.posts.map((p) {
      if (p.id == event.postId) {
        final newIsLiked = !p.isLiked;
        final newCount = newIsLiked ? p.likesCount + 1 : (p.likesCount > 0 ? p.likesCount - 1 : 0);
        return p.copyWith(isLiked: newIsLiked, likesCount: newCount);
      }
      return p;
    }).toList();

    emit(PostLoaded(updatedPosts, selectedCategory: currentState.selectedCategory));

    try {
      final result = await _postRepository.toggleLike(event.postId);
      // Sync confirmed state from server
      final confirmedPosts = updatedPosts.map((p) {
        if (p.id == event.postId) {
          return p.copyWith(
            isLiked: result['isLiked'] as bool,
            likesCount: result['likesCount'] as int,
          );
        }
        return p;
      }).toList();
      emit(PostLoaded(confirmedPosts, selectedCategory: currentState.selectedCategory));
    } catch (_) {
      // Revert on failure
      emit(currentState);
    }
  }

  Future<void> _onAddComment(AddCommentEvent event, Emitter<PostState> emit) async {
    try {
      await _postRepository.addComment(event.postId, event.content);
      if (state is PostLoaded) {
        final currentState = state as PostLoaded;
        final updatedPosts = currentState.posts.map((p) {
          if (p.id == event.postId) {
            return p.copyWith(commentsCount: p.commentsCount + 1);
          }
          return p;
        }).toList();
        emit(PostLoaded(updatedPosts, selectedCategory: currentState.selectedCategory));
      }
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReportPost(ReportPostEvent event, Emitter<PostState> emit) async {
    try {
      await _postRepository.reportPost(event.postId, event.reason);
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

