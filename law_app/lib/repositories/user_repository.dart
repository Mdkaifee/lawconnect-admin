import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AppUserConnection {
  final UserModel user;
  final String connectionStatus;

  const AppUserConnection({required this.user, required this.connectionStatus});

  factory AppUserConnection.fromJson(Map<String, dynamic> json) {
    return AppUserConnection(
      user: UserModel.fromJson(json),
      connectionStatus: json['connectionStatus']?.toString() ?? 'none',
    );
  }
}

class UserRepository {
  final AuthRepository _authRepo;
  final http.Client _client;

  UserRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  Future<List<AppUserConnection>> getAppUsers() async {
    final response = await _client.get(Uri.parse(ApiConstants.appUsers), headers: _authRepo.authHeaders);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => AppUserConnection.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<String> connect(String userId) async {
    final response = await _client.post(Uri.parse('${ApiConstants.users}/$userId/connect'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['status']?.toString() ?? 'requested';
    }
    throw Exception(data['error'] ?? 'Failed to update connection');
  }

  Future<String> accept(String userId) async {
    final response = await _client.post(Uri.parse('${ApiConstants.users}/$userId/accept'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['status']?.toString() ?? 'friend';
    }
    throw Exception(data['error'] ?? 'Failed to accept request');
  }
}
