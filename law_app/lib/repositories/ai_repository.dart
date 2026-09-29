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

  Future<List<Map<String, String>>> loadHistory() async {
    final response = await _client.get(Uri.parse(ApiConstants.aiHistory), headers: _authRepository.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'AI chat history is unavailable');
    }
    return ((data['messages'] as List<dynamic>?) ?? []).map((item) {
      final message = item as Map<String, dynamic>;
      return <String, String>{
        'role': message['role']?.toString() ?? 'assistant',
        'content': message['content']?.toString() ?? '',
      };
    }).where((message) => message['content']!.isNotEmpty).toList();
  }

  Future<String> send(String message) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.aiChat),
      headers: _authRepository.authHeaders,
      body: jsonEncode({'message': message}),
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
