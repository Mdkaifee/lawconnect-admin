import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteRepository {
  final ApiClient _apiClient;

  NoteRepository(this._apiClient);

  Future<List<NoteModel>> getNotes({String? refType}) async {
    final params = <String, dynamic>{};
    if (refType != null) params['refType'] = refType;

    final response = await _apiClient.get(
      ApiConstants.notes,
      queryParams: params,
      withAuth: true,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => NoteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<NoteModel> createNote({
    required String title,
    required String content,
    String? refType,
    String? refId,
    String? refTitle,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.notes,
      body: {
        'title': title,
        'content': content,
        'refType': refType ?? 'general',
        if (refId != null) 'refId': refId,
        if (refTitle != null) 'refTitle': refTitle,
      },
      withAuth: true,
    );

    if (response is Map && response['item'] != null) {
      return NoteModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create note');
  }

  Future<NoteModel> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.notes}/$id',
      body: {'title': title, 'content': content},
      withAuth: true,
    );

    if (response is Map && response['item'] != null) {
      return NoteModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update note');
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.delete('${ApiConstants.notes}/$id', withAuth: true);
  }
}
