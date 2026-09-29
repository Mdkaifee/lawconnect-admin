import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
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
  final bool mine;
  final bool following;
  final int page;
  final bool isNewLoad;

  const LoadPostsEvent({
    this.category,
    this.query,
    this.mine = false,
    this.following = false,
    this.page = 1,
    this.isNewLoad = true,
  });

  @override
  List<Object?> get props => [category, query, mine, following, page, isNewLoad];
}

class CreatePostEvent extends PostEvent {
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String? imageData;
  final String? imageMimeType;
  final Completer<PostModel>? completer;
  const CreatePostEvent({required this.title, required this.content, required this.category, this.tags = const [], this.imageData, this.imageMimeType, this.completer});
  @override
  List<Object?> get props => [title, content, category, tags, imageData, imageMimeType];
}

class ToggleLikePostEvent extends PostEvent {
  final String postId;
  final Completer<Map<String, dynamic>>? completer;
  const ToggleLikePostEvent(this.postId, {this.completer});
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

class CommentAddedLocallyEvent extends PostEvent {
  final String postId;
  const CommentAddedLocallyEvent(this.postId);
  @override
  List<Object?> get props => [postId];
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
  final int page;
  final int total;
  final bool hasMore;
  const PostLoaded(
    this.posts, {
    this.selectedCategory,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  @override
  List<Object?> get props => [posts, selectedCategory, page, total, hasMore];
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
    on<CommentAddedLocallyEvent>(_onCommentAddedLocally);
    on<ReportPostEvent>(_onReportPost);
  }

  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostState> emit) async {
    if (event.isNewLoad) emit(PostLoading());
    try {
      final result = await _postRepository.getPosts(
        category: event.category,
        query: event.query,
        mine: event.mine,
        following: event.following,
        page: event.page,
      );
      final combinedPosts = !event.isNewLoad && state is PostLoaded
          ? [...(state as PostLoaded).posts, ...result.items]
          : result.items;
      emit(PostLoaded(
        combinedPosts,
        selectedCategory: event.category,
        page: result.page,
        total: result.total,
        hasMore: combinedPosts.length < result.total && result.items.isNotEmpty,
      ));
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
        imageData: event.imageData,
        imageMimeType: event.imageMimeType,
      );
      if (state is PostLoaded) {
        final currentState = state as PostLoaded;
        final currentPosts = currentState.posts;
        emit(PostLoaded(
          [newPost, ...currentPosts],
          selectedCategory: currentState.selectedCategory,
          page: currentState.page,
          total: currentState.total + 1,
          hasMore: currentState.hasMore,
        ));
      } else {
        add(const LoadPostsEvent());
      }
      event.completer?.complete(newPost);
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
      if (!(event.completer?.isCompleted ?? true)) event.completer!.completeError(e);
    }
  }

  Future<void> _onToggleLike(ToggleLikePostEvent event, Emitter<PostState> emit) async {
    if (state is! PostLoaded) return;
    final currentState = state as PostLoaded;

    // Optimistic update
    final optimisticPosts = currentState.posts.map((p) {
      if (p.id == event.postId) {
        final newIsLiked = !p.isLiked;
        return p.copyWith(
          isLiked: newIsLiked,
          likesCount: newIsLiked ? p.likesCount + 1 : (p.likesCount > 0 ? p.likesCount - 1 : 0),
        );
      }
      return p;
    }).toList();

    emit(PostLoaded(
      optimisticPosts,
      selectedCategory: currentState.selectedCategory,
      page: currentState.page,
      total: currentState.total,
      hasMore: currentState.hasMore,
    ));

    try {
      final result = await _postRepository.toggleLike(event.postId);
      // Sync confirmed state from server if state is still PostLoaded
      if (state is PostLoaded) {
        final activeState = state as PostLoaded;
        final confirmedPosts = activeState.posts.map((p) {
          if (p.id == event.postId) {
            return p.copyWith(
              isLiked: result['isLiked'] as bool,
              likesCount: result['likesCount'] as int,
            );
          }
          return p;
        }).toList();
        emit(PostLoaded(
          confirmedPosts,
          selectedCategory: activeState.selectedCategory,
          page: activeState.page,
          total: activeState.total,
          hasMore: activeState.hasMore,
        ));
      }
      event.completer?.complete(result);
    } catch (_) {
      // Revert to original state on failure
      emit(currentState);
      if (!(event.completer?.isCompleted ?? true)) event.completer!.completeError(Exception('Unable to update like'));
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
        emit(PostLoaded(
          updatedPosts,
          selectedCategory: currentState.selectedCategory,
          page: currentState.page,
          total: currentState.total,
          hasMore: currentState.hasMore,
        ));
      }
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onCommentAddedLocally(CommentAddedLocallyEvent event, Emitter<PostState> emit) {
    final currentState = state;
    if (currentState is! PostLoaded) return;
    emit(PostLoaded(
      currentState.posts.map((post) {
        if (post.id != event.postId) return post;
        return post.copyWith(commentsCount: post.commentsCount + 1);
      }).toList(),
      selectedCategory: currentState.selectedCategory,
      page: currentState.page,
      total: currentState.total,
      hasMore: currentState.hasMore,
    ));
  }

  Future<void> _onReportPost(ReportPostEvent event, Emitter<PostState> emit) async {
    try {
      await _postRepository.reportPost(event.postId, event.reason);
    } catch (e) {
      emit(PostError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
