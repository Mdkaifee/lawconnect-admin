import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/message_model.dart';
import 'auth_repository.dart';

class MessageRepository {
  final AuthRepository _authRepo;
  final http.Client _client;

  MessageRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  Future<List<ConversationModel>> getConversations() async {
    final response = await _client.get(Uri.parse('${ApiConstants.messages}/conversations'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['error'] ?? 'Failed to load messages');
  }

  Future<ConversationDetail> getConversation(String conversationId) async {
    final response = await _client.get(Uri.parse('${ApiConstants.messages}/conversations/$conversationId'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ConversationDetail(
        conversation: ConversationModel.fromJson(data['conversation'] as Map<String, dynamic>),
        messages: ((data['messages'] as List<dynamic>?) ?? []).map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList(),
        chatAccess: ChatAccess.fromJson(data['chatAccess'] as Map<String, dynamic>?),
      );
    }
    throw Exception(data['error'] ?? 'Failed to load chat');
  }

  Future<({String conversationId, String status, bool isFriend, bool isRequester})> getOrCreateForUser(String userId) async {
    final response = await _client.get(Uri.parse('${ApiConstants.messages}/users/$userId'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (
        conversationId: data['conversationId']?.toString() ?? '',
        status: data['status']?.toString() ?? 'none',
        isFriend: data['isFriend'] == true,
        isRequester: data['isRequester'] == true,
      );
    }
    throw Exception(data['error'] ?? 'Failed to open chat');
  }

  Future<String> sendMessageRequest(String userId, String body) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.messages}/users/$userId/request'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'body': body}),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) return data['conversationId']?.toString() ?? '';
    throw Exception(data['error'] ?? 'Failed to send message request');
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.messages}/conversations/$conversationId/messages'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'body': body}),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode == 402 && data['paymentRequired'] == true) {
      throw ChatPaymentRequiredException(data['error']?.toString() ?? 'Unlock this chat to continue.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error'] ?? 'Failed to send message');
  }

  Future<ChatPaymentOrder> createChatUnlockOrder(String conversationId) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.messages}/conversations/$conversationId/payment/order'),
      headers: _authRepo.authHeaders,
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error'] ?? 'Unable to start payment');
    if (data['paid'] == true) return const ChatPaymentOrder(orderId: '', amountPaise: 0, currency: 'INR', keyId: '');
    return ChatPaymentOrder(
      orderId: data['orderId']?.toString() ?? '',
      amountPaise: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency']?.toString() ?? 'INR',
      keyId: data['keyId']?.toString() ?? '',
    );
  }

  Future<void> verifyChatUnlockPayment({required String conversationId, required String orderId, required String paymentId, required String signature}) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.messages}/conversations/$conversationId/payment/verify'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'razorpayOrderId': orderId, 'razorpayPaymentId': paymentId, 'razorpaySignature': signature}),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300 || data['paid'] != true) {
      throw Exception(data['error'] ?? 'Payment verification failed');
    }
  }

  Future<bool> cancelChatUnlockOrder(String conversationId, String orderId) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.messages}/conversations/$conversationId/payment/cancel'),
      headers: _authRepo.authHeaders,
      body: jsonEncode({'razorpayOrderId': orderId}),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Could not confirm payment status');
    }
    return data['paid'] == true;
  }

  Future<void> acceptRequest(String conversationId) async {
    final response = await _client.post(Uri.parse('${ApiConstants.messages}/conversations/$conversationId/accept'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error'] ?? 'Failed to accept request');
  }

  Future<void> ignoreRequest(String conversationId) async {
    final response = await _client.post(Uri.parse('${ApiConstants.messages}/conversations/$conversationId/ignore'), headers: _authRepo.authHeaders);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error'] ?? 'Failed to ignore request');
  }

  Future<void> markRead(String conversationId) async {
    await _client.post(Uri.parse('${ApiConstants.messages}/conversations/$conversationId/read'), headers: _authRepo.authHeaders);
  }
}
