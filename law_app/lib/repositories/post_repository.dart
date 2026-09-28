import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_repository.dart';

class PostPageResult {
  final List<PostModel> items;
  final int total;
  final int page;
  final int limit;

  const PostPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class CommentPageResult {
  final List<CommentModel> items;
  final int total;
  final int page;
  final int limit;

  const CommentPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class PostRepository {
  final http.Client _client;
  final AuthRepository _authRepo;

  PostRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  Future<PostPageResult> getPosts({
    String? category,
    String? query,
    bool mine = false,
    bool following = false,
    int page = 1,
    int limit = 25,
  }) async {
    final queryParams = <String, String>{
      if (category != null && category != 'All' && category != 'Feed' && category != 'Following') 'category': category,
      if (query != null && query.isNotEmpty) 'q': query.trim(),
      if (mine && _authRepo.currentUser != null) ...{
        'scope': 'mine',
        'authorId': _authRepo.currentUser!.id,
      },
      if (following && _authRepo.currentUser != null) 'scope': 'following',
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(ApiConstants.posts).replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: _authRepo.authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final currentUserId = _authRepo.currentUser?.id;
      final items = rawItems.map((e) => PostModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId)).toList();
      return PostPageResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
      );
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> toggleFollowAuthor(String authorId) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.follow}/$authorId'),
      headers: _authRepo.authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return {
        'ok': data['ok'] == true,
        'isFollowing': data['isFollowing'] == true,
        'status': data['status']?.toString() ?? '',
        'message': data['message']?.toString() ?? '',
        'following': (data['following'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      };
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to follow/unfollow author');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to follow/unfollow author');
      }
    }
  }

  Future<List<String>> getFollowingAuthors() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.following),
        headers: _authRepo.authHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return (data['following'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      }
    } catch (_) {}
    return [];
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

  Future<CommentPageResult> getComments(String postId, {int page = 1, int limit = 20}) async {
    final uri = Uri.parse('${ApiConstants.posts}/$postId/comments').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final items = rawItems.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
      return CommentPageResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
      );
    }
    return const CommentPageResult(items: [], total: 0, page: 1, limit: 20);
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
