import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  final StorageService _storage;
  final http.Client _client;

  ApiClient(this._storage, [http.Client? client]) : _client = client ?? http.Client();

  String get _baseUrl {
    final custom = _storage.getApiBase();
    if (custom != null && custom.isNotEmpty) {
      return custom.replaceAll(RegExp(r'/$'), '');
    }
    return ApiConstants.baseUrl;
  }

  Map<String, String> _getHeaders({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
      );
      final response = await _client.get(uri, headers: _getHeaders(withAuth: withAuth));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach the server. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _client.post(
        uri,
        headers: _getHeaders(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach the server. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: _getHeaders(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach the server. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _client.delete(uri, headers: _getHeaders(withAuth: withAuth));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach the server. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else {
      final message = jsonBody is Map ? (jsonBody['error'] ?? jsonBody['message']) : null;
      throw ApiException(
        message?.toString() ?? 'Server error (${response.statusCode})',
        response.statusCode,
      );
    }
  }
}
