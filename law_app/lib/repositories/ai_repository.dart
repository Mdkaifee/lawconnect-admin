import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'auth_repository.dart';

class AiRepository {
  final AuthRepository _authRepository;
  final http.Client _client;

  AiRepository({required AuthRepository authRepository, http.Client? client})
      : _authRepository = authRepository,
        _client = client ?? http.Client();

  Future<String> send(List<Map<String, String>> messages) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.aiChat),
      headers: _authRepository.authHeaders,
      body: jsonEncode({'messages': messages}),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'AI chat is unavailable');
    }
    final reply = data['reply']?.toString().trim() ?? '';
    if (reply.isEmpty) throw Exception('AI returned an empty response');
    return reply;
  }
}
