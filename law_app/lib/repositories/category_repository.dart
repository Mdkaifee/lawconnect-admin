import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final http.Client _client;

  CategoryRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get(Uri.parse(ApiConstants.categories));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load categories: ${response.statusCode}');
  }
}
