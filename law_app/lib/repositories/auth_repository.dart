import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
  }

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _token = data['token'];
      _currentUser = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));

      return _currentUser!;
    } else {
      throw Exception(data['error'] ?? 'Login failed. Please check credentials.');
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name.trim(), 'email': email.trim(), 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _token = data['token'];
      _currentUser = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));

      return _currentUser!;
    } else {
      throw Exception(data['error'] ?? 'Registration failed.');
    }
  }

  Future<UserModel?> fetchProfile() async {
    if (_token == null) return null;
    try {
      final response = await http.get(Uri.parse(ApiConstants.me), headers: authHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        return _currentUser;
      }
    } catch (_) {}
    return _currentUser;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? photoUrl,
    String? headline,
    String? college,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConstants.me),
      headers: authHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'photoUrl': photoUrl?.trim(),
        'headline': headline?.trim(),
        'college': college?.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _currentUser = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      return _currentUser!;
    }

    throw Exception(data['error'] ?? 'Failed to update profile.');
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  Future<void> deleteAccount({String? reason}) async {
    if (_token != null) {
      try {
        final response = await http.post(
          Uri.parse(ApiConstants.deleteAccount),
          headers: authHeaders,
          body: jsonEncode({'reason': reason ?? 'User requested in-app account deletion'}),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await logout();
          return;
        } else {
          final data = jsonDecode(response.body);
          throw Exception(data['error'] ?? 'Failed to delete account.');
        }
      } catch (e) {
        // Still perform local logout if session invalid
        if (e.toString().contains('Invalid') || e.toString().contains('401')) {
          await logout();
        }
        rethrow;
      }
    } else {
      await logout();
    }
  }
}

