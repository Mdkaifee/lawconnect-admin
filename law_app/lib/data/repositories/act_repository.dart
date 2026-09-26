import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/act_model.dart';

class ActRepository {
  final ApiClient _apiClient;

  ActRepository(this._apiClient);

  Future<List<ActModel>> getActs({String? query, String? type}) async {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (type != null && type != 'All Acts') params['type'] = type;

    final response = await _apiClient.get(
      ApiConstants.acts,
      queryParams: params,
      withAuth: false,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => ActModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ActModel> getActDetails(String id) async {
    final response = await _apiClient.get('${ApiConstants.acts}/$id', withAuth: false);
    if (response is Map && response['item'] != null) {
      return ActModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Act not found');
  }

  Future<List<SectionModel>> searchSections(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _apiClient.get(
      ApiConstants.searchSections,
      queryParams: {'q': query.trim()},
      withAuth: false,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => SectionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
