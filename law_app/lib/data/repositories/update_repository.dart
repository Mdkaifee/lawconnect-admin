import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/legal_update_model.dart';

class UpdateRepository {
  final ApiClient _apiClient;

  UpdateRepository(this._apiClient);

  Future<List<LegalUpdateModel>> getLegalUpdates({String? court, int limit = 30}) async {
    final params = <String, dynamic>{'limit': limit};
    if (court != null && court != 'Latest') params['court'] = court;

    final response = await _apiClient.get(
      ApiConstants.updates,
      queryParams: params,
      withAuth: false,
    );

    if (response is Map && response['items'] is List) {
      return (response['items'] as List)
          .map((item) => LegalUpdateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
