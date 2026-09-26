import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class StorageService {
  static const String _tokenKey = 'lawhub_token';
  static const String _userKey = 'lawhub_user';
  static const String _apiBaseKey = 'lawhub_api_base';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  // User Management
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final str = _prefs.getString(_userKey);
    if (str == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // Custom API Base Override
  Future<void> saveApiBase(String url) async {
    await _prefs.setString(_apiBaseKey, url);
  }

  String? getApiBase() {
    return _prefs.getString(_apiBaseKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }
}
