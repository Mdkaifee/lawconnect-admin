import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/update_model.dart';

class UpdateRepository {
  final http.Client _client;

  UpdateRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<UpdateModel>> getUpdates({String? court, String? category, String? query}) async {
    final queryParams = {
      if (court != null && court != 'All' && court != 'Latest') 'court': court,
      if (category != null && category != 'All') 'category': category,
      if (query != null && query.isNotEmpty) 'q': query.trim(),
    };

    final uri = Uri.parse(ApiConstants.updates).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => UpdateModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load legal updates: ${response.statusCode}');
    }
  }
}
