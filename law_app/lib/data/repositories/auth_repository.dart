import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    final token = response['token']?.toString() ?? '';
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveToken(token);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      body: {'name': name, 'email': email, 'password': password},
      withAuth: false,
    );
    final token = response['token']?.toString() ?? '';
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveToken(token);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel?> getProfile() async {
    final cached = _storage.getUser();
    final token = _storage.getToken();
    if (token == null || token.isEmpty) return cached;

    try {
      final response = await _apiClient.get(ApiConstants.me, withAuth: true);
      if (response != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        await _storage.saveUser(user);
        return user;
      }
    } catch (_) {}
    return cached;
  }

  Future<UserModel> updateProfile({
    String? name,
    String? headline,
    String? college,
    String? photoUrl,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.me,
      body: {
        if (name != null) 'name': name,
        if (headline != null) 'headline': headline,
        if (college != null) 'college': college,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
      withAuth: true,
    );
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  bool isAuthenticated() {
    return _storage.getToken() != null && _storage.getToken()!.isNotEmpty;
  }

  UserModel? get currentUser => _storage.getUser();
}
