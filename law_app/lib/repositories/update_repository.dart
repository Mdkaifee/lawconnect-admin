import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/update_model.dart';

class UpdatePageResult {
  final List<UpdateModel> items;
  final int total;
  final int page;
  final int limit;

  const UpdatePageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class UpdateRepository {
  final http.Client _client;

  UpdateRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdatePageResult> getUpdates({String? court, String? category, String? query, int page = 1, int limit = 20}) async {
    final queryParams = {
      if (court != null && court != 'All' && court != 'Latest') 'court': court,
      if (category != null && category != 'All') 'category': category,
      if (query != null && query.isNotEmpty) 'q': query.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(ApiConstants.updates).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final items = rawItems.map((e) => UpdateModel.fromJson(e as Map<String, dynamic>)).toList();
      return UpdatePageResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
      );
    } else {
      throw Exception('Failed to load legal updates: ${response.statusCode}');
    }
  }
}

