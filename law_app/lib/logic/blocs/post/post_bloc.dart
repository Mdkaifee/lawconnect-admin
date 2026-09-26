import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/post_repository.dart';
import 'post_event.dart';
import 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _postRepository;

  PostBloc(this._postRepository) : super(PostInitial()) {
    on<FetchPostsEvent>(_onFetchPosts);
    on<CreatePostEvent>(_onCreatePost);
    on<LikePostEvent>(_onLikePost);
  }

  Future<void> _onFetchPosts(FetchPostsEvent event, Emitter<PostState> emit) async {
    if (!event.refresh && state is! PostsLoaded) {
      emit(PostLoading());
    }
    try {
      final posts = await _postRepository.getPosts(
        scope: event.scope,
        query: event.query,
      );
      emit(PostsLoaded(
        posts: posts,
        selectedTab: event.scope == 'mine' ? 'My Posts' : 'All',
      ));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onCreatePost(CreatePostEvent event, Emitter<PostState> emit) async {
    try {
      await _postRepository.createPost(
        title: event.title,
        content: event.content,
        category: event.category,
        tags: event.tags,
      );
      emit(const PostActionSuccess('Post created successfully!'));
      add(const FetchPostsEvent(refresh: true));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onLikePost(LikePostEvent event, Emitter<PostState> emit) async {
    try {
      final updated = await _postRepository.likePost(event.id);
      if (state is PostsLoaded) {
        final current = (state as PostsLoaded).posts;
        final list = current.map((p) => p.id == updated.id ? updated : p).toList();
        emit(PostsLoaded(posts: list, selectedTab: (state as PostsLoaded).selectedTab));
      }
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }
}
