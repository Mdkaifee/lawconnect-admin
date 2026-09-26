import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/case_model.dart';

class CaseRepository {
  final ApiClient _apiClient;

  CaseRepository(this._apiClient);

  Future<List<CaseModel>> getCases({
    String? query,
    String? court,
    int? year,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (court != null && court != 'All') params['court'] = court;
    if (year != null) params['year'] = year;
    if (category != null && category.isNotEmpty) params['category'] = category;

    final response = await _apiClient.get(
      ApiConstants.cases,
      queryParams: params,
      withAuth: false,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => CaseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<CaseModel> getCaseDetails(String id) async {
    final response = await _apiClient.get('${ApiConstants.cases}/$id', withAuth: false);
    if (response is Map && response['item'] != null) {
      return CaseModel.fromJson(response['item'] as Map<String, dynamic>);
    }
    throw ApiException('Case details not found');
  }

  Future<void> recordReadingHistory(String caseId, String title) async {
    try {
      await _apiClient.post(
        ApiConstants.history,
        body: {
          'refType': 'case',
          'refId': caseId,
          'title': title,
        },
        withAuth: true,
      );
    } catch (_) {}
  }
}
