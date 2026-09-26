import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/act_model.dart';

class ActPageResult {
  final List<ActModel> items;
  final int total;
  final int page;
  final int limit;

  const ActPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class ActRepository {
  final http.Client _client;

  ActRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<ActPageResult> getActs({String? query, String? type, int page = 1, int limit = 20}) async {
    final queryParams = {
      if (query != null && query.isNotEmpty) 'q': query.trim(),
      if (type != null && type != 'All') 'type': type,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(ApiConstants.acts).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final items = rawItems.map((e) => ActModel.fromJson(e as Map<String, dynamic>)).toList();
      return ActPageResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
      );
    } else {
      throw Exception('Failed to load acts: ${response.statusCode}');
    }
  }

  Future<ActModel> getActDetails(String id) async {
    final uri = Uri.parse('${ApiConstants.acts}/$id');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return ActModel.fromJson(data['item'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load act details: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> searchSections(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(ApiConstants.actSectionSearch).replace(queryParameters: {'q': query.trim()});
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

