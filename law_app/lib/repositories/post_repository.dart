import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_repository.dart';

class PostRepository {
  final http.Client _client;
  final AuthRepository _authRepo;

  PostRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  Future<List<PostModel>> getPosts({String? category, String? query, int page = 1}) async {
    final queryParams = {
      if (category != null && category != 'All' && category != 'Feed') 'category': category,
      if (query != null && query.isNotEmpty) 'q': query.trim(),
      'page': page.toString(),
      'limit': '25',
    };

    final uri = Uri.parse(ApiConstants.posts).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final currentUserId = _authRepo.currentUser?.id;
      return rawItems.map((e) => PostModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId)).toList();
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<PostModel> createPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.posts),
      headers: _authRepo.authHeaders,
      body: jsonEncode({
        'title': title.trim(),
        'content': content.trim(),
        'category': category,
        'tags': tags,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return PostModel.fromJson(data['item'] as Map<String, dynamic>, currentUserId: _authRepo.currentUser?.id);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create post');
    }
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.posts}/$postId/like'),
      headers: _authRepo.authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return {
        'isLiked': data['isLiked'] == true,
        'likesCount': (data['likesCount'] as num?)?.toInt() ?? 0,
      };
    } else {
      throw Exception('Failed to like/unlike post');
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final uri = Uri.parse('${ApiConstants.posts}/$postId/comments');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.posts}/$postId/comments'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'content': content.trim()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return CommentModel.fromJson(data['item'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to add comment');
    }
  }

  Future<void> reportPost(String postId, String reason) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.posts}/$postId/report'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'reason': reason, 'targetType': 'post'}),
    );

    if (response.statusCode >= 300) {
      throw Exception('Failed to submit report');
    }
  }
}
