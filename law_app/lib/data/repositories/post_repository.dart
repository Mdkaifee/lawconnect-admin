import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/post_model.dart';

class PostRepository {
  final ApiClient _apiClient;

  PostRepository(this._apiClient);

  Future<List<PostModel>> getPosts({String? scope, String? query, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (scope != null) params['scope'] = scope;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _apiClient.get(
      ApiConstants.posts,
      queryParams: params,
      withAuth: false,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PostModel> createPost({
    required String title,
    required String content,
    String? category,
    List<String>? tags,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.posts,
      body: {
        'title': title,
        'content': content,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
      },
      withAuth: true,
    );

    if (response is Map && response['item'] != null) {
      return PostModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create post');
  }

  Future<PostModel> likePost(String id) async {
    final response = await _apiClient.post(ApiConstants.likePost(id), withAuth: true);
    if (response is Map && response['item'] != null) {
      return PostModel.fromJson(response['item'] as Map<String, dynamic>).copyWith(isLiked: true);
    }
    throw ApiException('Failed to like post');
  }
}
