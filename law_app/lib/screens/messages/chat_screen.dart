import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/message_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  Future<ConversationDetail>? _future;
  bool _sending = false;
  bool _paymentInProgress = false;
  ChatAccess? _chatAccess;
  late final Razorpay _razorpay;
  String? _pendingPaymentOrderId;
  String? _pendingPaidMessage;
  ChatPaymentOrder? _preparedRetryOrder;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _load() {
    _future = context.read<MessageRepository>().getConversation(widget.conversationId);
    context.read<MessageRepository>().markRead(widget.conversationId);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _load();
    });
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (_chatAccess?.isLocked == true) {
      await _startPayment(text);
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<MessageRepository>().sendMessage(widget.conversationId, text);
      _controller.clear();
      await _refresh();
    } on ChatPaymentRequiredException {
      if (mounted) await _startPayment(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startPayment([String? messageToSend]) async {
    if (_paymentInProgress) return;
    debugPrint('[CHAT_PAYMENT] start conversation=${widget.conversationId} retryPrepared=${_preparedRetryOrder != null}');
    setState(() => _paymentInProgress = true);
    _pendingPaidMessage = messageToSend;
    try {
      final order = _preparedRetryOrder ??
          await context.read<MessageRepository>().createChatUnlockOrder(widget.conversationId);
      _preparedRetryOrder = null;
      if (!mounted) return;
      debugPrint('[CHAT_PAYMENT] order response paid=${order.alreadyPaid} orderId=${order.orderId.isEmpty ? '(none)' : order.orderId} amountPaise=${order.amountPaise} currency=${order.currency}');
      if (order.alreadyPaid) {
        context.read<AuthBloc>().add(CheckAuthEvent());
        final pendingMessage = _pendingPaidMessage;
        if (pendingMessage != null && pendingMessage.isNotEmpty) {
          try {
            await context.read<MessageRepository>().sendMessage(widget.conversationId, pendingMessage);
            if (_controller.text.trim() == pendingMessage) _controller.clear();
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment confirmed, but the message could not be sent: ${error.toString().replaceFirst('Exception: ', '')}')),
              );
            }
          }
        }
        _pendingPaidMessage = null;
        _pendingPaymentOrderId = null;
        _paymentInProgress = false;
        await _refresh();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed. Chat is unlocked.')),
          );
        }
        return;
      }
      _pendingPaymentOrderId = order.orderId;
      debugPrint('[CHAT_PAYMENT] opening checkout orderId=${order.orderId}');
      _razorpay.open({
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'Rishikesh Law Hub',
        'description': 'Unlock this chat',
        // Checkout retries reuse this order ID. Retry from the app so the
        // backend can reconcile the attempt and issue a fresh order.
        'retry': {'enabled': false},
        'prefill': {'email': context.read<AuthRepository>().currentUser?.email ?? ''},
      });
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] order/checkout start failed error=$error');
      _paymentInProgress = false;
      _pendingPaidMessage = null;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? _pendingPaymentOrderId;
    final paymentId = response.paymentId;
    final signature = response.signature;
    debugPrint('[CHAT_PAYMENT] checkout success orderId=${orderId ?? '(missing)'} paymentId=${paymentId ?? '(missing)'} signaturePresent=${signature?.isNotEmpty == true}');
    try {
      if (orderId == null || paymentId == null || signature == null) throw Exception('Razorpay returned incomplete payment details');
      await context.read<MessageRepository>().verifyChatUnlockPayment(
            conversationId: widget.conversationId,
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );
      debugPrint('[CHAT_PAYMENT] verify succeeded orderId=$orderId');
      context.read<AuthBloc>().add(CheckAuthEvent());
      final pendingMessage = _pendingPaidMessage;
      if (pendingMessage != null && pendingMessage.isNotEmpty) {
        await context.read<MessageRepository>().sendMessage(widget.conversationId, pendingMessage);
        if (_controller.text.trim() == pendingMessage) _controller.clear();
      }
      _pendingPaidMessage = null;
      await _refresh();
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] success callback verification failed orderId=${orderId ?? '(missing)'} error=$error');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      _paymentInProgress = false;
      _pendingPaymentOrderId = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _onPaymentError(PaymentFailureResponse response) async {
    final orderId = _pendingPaymentOrderId;
    final pendingMessage = _pendingPaidMessage;
    _paymentInProgress = false;
    _pendingPaymentOrderId = null;
    _pendingPaidMessage = null;
    debugPrint('[CHAT_PAYMENT] checkout error orderId=${orderId ?? '(missing)'} code=${response.code} message=${response.message} description=${response.error?['description']}');
    if (mounted) setState(() {});

    var paymentWasCaptured = false;
    var paymentStatusChecked = false;
    if (orderId != null && orderId.isNotEmpty) {
      try {
        paymentWasCaptured = await context
            .read<MessageRepository>()
            .cancelChatUnlockOrder(widget.conversationId, orderId);
        paymentStatusChecked = true;
        debugPrint('[CHAT_PAYMENT] reconciliation response orderId=$orderId paid=$paymentWasCaptured');
      } catch (error) {
        debugPrint('[CHAT_PAYMENT] reconciliation request failed orderId=$orderId error=$error');
      }
    }
    if (!paymentStatusChecked) debugPrint('[CHAT_PAYMENT] reconciliation failed/unavailable orderId=${orderId ?? '(missing)'}');

    if (!mounted) return;

    if (paymentWasCaptured) {
      context.read<AuthBloc>().add(CheckAuthEvent());
      if (pendingMessage != null && pendingMessage.isNotEmpty) {
        try {
          await context.read<MessageRepository>().sendMessage(widget.conversationId, pendingMessage);
          if (_controller.text.trim() == pendingMessage) _controller.clear();
        } catch (_) {}
      }
      await _refresh();
    }

    if (!mounted) return;
    setState(() {});
    final message = response.message?.trim() ?? '';
    final detail = response.error?['description']?.toString().trim() ?? '';
    if (!paymentWasCaptured && paymentStatusChecked) {
      try {
        final replacement = await context
            .read<MessageRepository>()
            .createChatUnlockOrder(widget.conversationId);
        if (replacement.alreadyPaid) {
          paymentWasCaptured = true;
          context.read<AuthBloc>().add(CheckAuthEvent());
          if (pendingMessage != null && pendingMessage.isNotEmpty) {
            try {
              await context.read<MessageRepository>().sendMessage(widget.conversationId, pendingMessage);
              if (_controller.text.trim() == pendingMessage) _controller.clear();
            } catch (_) {}
          }
          await _refresh();
        } else {
          _preparedRetryOrder = replacement;
          debugPrint('[CHAT_PAYMENT] replacement order ready orderId=${replacement.orderId}');
        }
      } catch (error) {
        debugPrint('[CHAT_PAYMENT] replacement order request failed error=$error');
      }
    }
    if (!mounted) return;
    final wasCancelled = response.code == 2 ||
        message.toLowerCase().contains('cancel') ||
        message.toLowerCase() == 'undefined';
    final notice = paymentWasCaptured
        ? 'Payment confirmed. Chat is unlocked.'
        : _preparedRetryOrder != null
            ? 'Payment was not completed. Tap Unlock to try again with a fresh checkout.'
        : !paymentStatusChecked && orderId != null
            ? 'Payment status could not be confirmed. Please refresh before trying again.'
        : wasCancelled
            ? 'Payment cancelled. No amount was charged.'
            : 'Payment failed${detail.isNotEmpty ? ': $detail' : message.isNotEmpty && message != 'undefined' ? ': $message' : '. Please try again.'}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
  }

  Future<void> _accept() async {
    await context.read<MessageRepository>().acceptRequest(widget.conversationId);
    await _refresh();
  }

  Future<void> _ignore() async {
    await context.read<MessageRepository>().ignoreRequest(widget.conversationId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthRepository>().currentUser?.id ?? '';
    final primary = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return FutureBuilder<ConversationDetail>(
          future: _future,
          builder: (context, snapshot) {
            final detail = snapshot.data;
            if (detail != null) _chatAccess = detail.chatAccess;
            final otherUser = detail?.conversation.otherUser;
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor(context),
              appBar: AppBar(
                backgroundColor: AppTheme.appBarColor(context),
                foregroundColor: textPrimary,
                surfaceTintColor: AppTheme.appBarColor(context),
                titleSpacing: 0,
                title: otherUser == null
                    ? Text(Translation.t('messages'))
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: primary,
                            backgroundImage: otherUser.photoUrl?.trim().isNotEmpty == true ? NetworkImage(otherUser.photoUrl!.trim()) : null,
                            child: otherUser.photoUrl?.trim().isNotEmpty == true ? null : Text(otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(otherUser.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                                    ),
                                    if (otherUser.isChatPaid) ...[
                                      const SizedBox(width: 6),
                                      const Tooltip(
                                        message: 'Premium member',
                                        child: Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF0F9F8F)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  otherUser.isOnline ? Translation.t('online') : '${Translation.t('last_seen')} ${DateFormatter.timeAgo(otherUser.lastActiveAt)}',
                                  style: TextStyle(fontSize: 11, color: otherUser.isOnline ? Colors.green : textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : detail == null
                      ? Center(child: Text(Translation.t('chat_load_failed'), style: TextStyle(color: textSecondary)))
                      : Column(
                          children: [
                            if (detail.conversation.isRequested)
                              _RequestBanner(
                                isRequester: detail.conversation.isRequester,
                                onAccept: _accept,
                                onIgnore: _ignore,
                              ),
                            if (detail.conversation.isActive && detail.chatAccess.isLocked)
                              Material(
                                color: AppTheme.primaryOrGold(context).withValues(alpha: 0.10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Free message limit reached. Unlock this chat for ₹${detail.chatAccess.unlockAmount.toStringAsFixed(0)}.',
                                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _paymentInProgress ? null : () => _startPayment(),
                                        child: _paymentInProgress
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                            : const Text('Unlock'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Expanded(
                              child: RefreshIndicator(
                                color: primary,
                                onRefresh: _refresh,
                                child: ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.all(14),
                                  itemCount: detail.messages.length,
                                  itemBuilder: (context, index) {
                                    final message = detail.messages[detail.messages.length - 1 - index];
                                    final mine = message.senderId == currentUserId;
                                    return Align(
                                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: mine ? primary : AppTheme.cardColor(context),
                                          borderRadius: BorderRadius.circular(14),
                                          border: mine ? null : Border.all(color: AppTheme.borderColor(context)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(message.body, style: TextStyle(color: mine ? Colors.white : textPrimary, height: 1.35)),
                                            const SizedBox(height: 4),
                                            Text(DateFormatter.timeAgo(message.createdAt), style: TextStyle(color: mine ? Colors.white70 : textSecondary, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (detail.conversation.isActive)
                              SafeArea(
                                top: false,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor(context),
                                    border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          minLines: 1,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText: detail.chatAccess.isLocked ? 'Pay to unlock messaging' : Translation.t('type_message'),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: _sending || _paymentInProgress ? null : _send,
                                        icon: _sending || _paymentInProgress
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : Icon(detail.chatAccess.isLocked ? Icons.lock_open_rounded : Icons.send_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
            );
          },
        );
      },
    );
  }
}

class _RequestBanner extends StatelessWidget {
  final bool isRequester;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  const _RequestBanner({required this.isRequester, required this.onAccept, required this.onIgnore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppTheme.primaryOrGold(context).withValues(alpha: 0.10),
      child: isRequester
          ? Text(Translation.t('waiting_message_request_accept'), textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w700))
          : Row(
              children: [
                Expanded(child: Text(Translation.t('incoming_message_request'), style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w700))),
                TextButton(onPressed: onIgnore, child: Text(Translation.t('ignore'))),
                FilledButton(onPressed: onAccept, child: Text(Translation.t('accept'))),
              ],
            ),
    );
  }
}
