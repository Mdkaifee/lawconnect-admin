import 'package:equatable/equatable.dart';
import 'user_model.dart';

class ConversationModel extends Equatable {
  final String id;
  final String status;
  final String requestedBy;
  final bool isRequester;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final UserModel otherUser;

  const ConversationModel({
    required this.id,
    required this.status,
    required this.requestedBy,
    required this.isRequester,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.otherUser,
  });

  bool get isActive => status == 'active';
  bool get isRequested => status == 'requested';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['lastMessageAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['lastMessageAt'].toString());
      } catch (_) {}
    }
    return ConversationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'none',
      requestedBy: json['requestedBy']?.toString() ?? '',
      isRequester: json['isRequester'] == true,
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: parsedDate,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      otherUser: UserModel.fromJson((json['otherUser'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  @override
  List<Object?> get props => [id, status, requestedBy, isRequester, lastMessage, lastMessageAt, unreadCount, otherUser];
}

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String body;
  final String kind;
  final DateTime? createdAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.kind,
    this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    DateTime? read;
    try {
      if (json['createdAt'] != null) created = DateTime.parse(json['createdAt'].toString());
      if (json['readAt'] != null) read = DateTime.parse(json['readAt'].toString());
    } catch (_) {}
    return MessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'message',
      createdAt: created,
      readAt: read,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, receiverId, body, kind, createdAt, readAt];
}

class ConversationDetail {
  final ConversationModel conversation;
  final List<MessageModel> messages;
  final ChatAccess chatAccess;

  const ConversationDetail({required this.conversation, required this.messages, required this.chatAccess});
}

class ChatAccess {
  final int sentCount;
  final int freeLimit;
  final double unlockAmount;
  final bool isPaid;
  final bool canSend;

  const ChatAccess({required this.sentCount, required this.freeLimit, required this.unlockAmount, required this.isPaid, required this.canSend});

  bool get isLocked => !canSend && !isPaid;

  factory ChatAccess.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const <String, dynamic>{};
    return ChatAccess(
      sentCount: (value['sentCount'] as num?)?.toInt() ?? 0,
      freeLimit: (value['freeLimit'] as num?)?.toInt() ?? 5,
      unlockAmount: (value['unlockAmount'] as num?)?.toDouble() ?? 11,
      isPaid: value['isPaid'] == true,
      canSend: value['canSend'] != false,
    );
  }
}

class ChatPaymentOrder {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final bool alreadyPaid;

  const ChatPaymentOrder({required this.orderId, required this.amountPaise, required this.currency, required this.keyId, this.alreadyPaid = false});
}

class ChatPaymentRequiredException implements Exception {
  final String message;
  const ChatPaymentRequiredException(this.message);
  @override
  String toString() => message;
}
