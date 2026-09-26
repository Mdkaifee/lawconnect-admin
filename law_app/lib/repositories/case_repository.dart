import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/case_model.dart';

class CaseSearchResult {
  final List<CaseModel> items;
  final int total;
  final int page;
  final String provider;

  CaseSearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.provider,
  });
}

class CaseRepository {
  final http.Client _client;

  CaseRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<CaseSearchResult> searchCases({
    String query = '',
    String? court,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      'q': query.trim(),
      if (court != null && court != 'All') 'court': court,
      if (year != null) 'year': year.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(ApiConstants.caseSearch).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final items = rawItems.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
      return CaseSearchResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        provider: data['provider']?.toString() ?? 'curated',
      );
    } else {
      throw Exception('Failed to search cases: ${response.statusCode}');
    }
  }

  Future<List<CaseModel>> getCuratedLandmarks() async {
    final uri = Uri.parse('${ApiConstants.cases}?isFeatured=true&limit=10');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<CaseModel> getCaseDetails(String id) async {
    final uri = Uri.parse('${ApiConstants.cases}/$id');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final itemJson = data['item'] as Map<String, dynamic>;
      return CaseModel.fromJson(itemJson);
    } else {
      throw Exception('Failed to load judgment details: ${response.statusCode}');
    }
  }
}

