import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/bookmark_model.dart';

class BookmarkRepository {
  final ApiClient _apiClient;

  BookmarkRepository(this._apiClient);

  Future<List<BookmarkModel>> getBookmarks({String? refType}) async {
    final params = <String, dynamic>{};
    if (refType != null) params['refType'] = refType;

    final response = await _apiClient.get(
      ApiConstants.bookmarks,
      queryParams: params,
      withAuth: true,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => BookmarkModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BookmarkModel> addBookmark({
    required String refType,
    required String refId,
    required String title,
    String? subtitle,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.bookmarks,
      body: {
        'refType': refType,
        'refId': refId,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      },
      withAuth: true,
    );

    if (response is Map && response['item'] != null) {
      return BookmarkModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to add bookmark');
  }

  Future<void> removeBookmark(String id) async {
    await _apiClient.delete('${ApiConstants.bookmarks}/$id', withAuth: true);
  }

  Future<List<Map<String, dynamic>>> getReadingHistory() async {
    final response = await _apiClient.get(ApiConstants.history, withAuth: true);
    if (response is Map && response['items'] is List) {
      return (response['items'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
