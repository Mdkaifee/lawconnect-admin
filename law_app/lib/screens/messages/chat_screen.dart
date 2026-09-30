import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/message_repository.dart';

enum _PaymentReconcileResult { paid, notCaptured, unknown }

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  Future<ConversationDetail>? _future;
  bool _sending = false;
  bool _paymentInProgress = false;
  bool _checkingPaymentStatus = false;
  bool _restoringPendingOrder = true;
  String? _paymentNotice;
  ChatAccess? _chatAccess;
  late final Razorpay _razorpay;
  String? _pendingPaymentOrderId;
  String? _pendingPaidMessage;
  ChatPaymentOrder? _pendingPaymentOrder;
  bool _reconcilingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _load();
    _restorePendingPaymentOrder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingPaymentOrderId != null) {
      _reconcilePendingPayment();
    }
  }

  String get _pendingOrderStorageKey {
    final userId = context.read<AuthRepository>().currentUser?.id ?? 'current';
    return 'chat_payment_order_${userId}_${widget.conversationId}';
  }

  Future<void> _restorePendingPaymentOrder() async {
    try {
      final storageKey = _pendingOrderStorageKey;
      final preferences = await SharedPreferences.getInstance();
      final orderId = preferences.getString(storageKey);
      if (orderId != null && orderId.isNotEmpty && mounted) {
        _pendingPaymentOrderId = orderId;
        await _reconcilePendingPayment();
      }
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] pending order restore failed error=$error');
    } finally {
      _restoringPendingOrder = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _savePendingPaymentOrder(String? orderId) async {
    try {
      final storageKey = _pendingOrderStorageKey;
      final preferences = await SharedPreferences.getInstance();
      if (orderId == null || orderId.isEmpty) {
        await preferences.remove(storageKey);
      } else {
        await preferences.setString(storageKey, orderId);
      }
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] pending order persistence failed error=$error');
    }
  }

  Future<_PaymentReconcileResult> _reconcilePendingPayment() async {
    final orderId = _pendingPaymentOrderId;
    if (orderId == null || orderId.isEmpty || _reconcilingPayment) return _PaymentReconcileResult.unknown;
    _reconcilingPayment = true;
    _checkingPaymentStatus = true;
    _paymentInProgress = true;
    _paymentNotice = null;
    if (mounted) setState(() {});
    debugPrint('[CHAT_PAYMENT] reconcile start orderId=$orderId');
    var gotResponse = false;
    var everyAttemptReturned = true;
    const retryDelays = [Duration.zero, Duration(seconds: 3), Duration(seconds: 6), Duration(seconds: 10)];
    try {
      for (var index = 0; index < retryDelays.length; index++) {
        if (index > 0) await Future.delayed(retryDelays[index]);
        if (!mounted) return _PaymentReconcileResult.unknown;
        try {
          final result = await context.read<MessageRepository>().reconcileChatUnlockOrder(
            widget.conversationId,
            orderId,
          );
          gotResponse = true;
          debugPrint('[CHAT_PAYMENT] reconcile attempt=${index + 1} orderId=$orderId paid=${result['paid'] == true}');
          if (result['paid'] == true) {
            await _completeConfirmedPayment(orderId);
            return _PaymentReconcileResult.paid;
          }
        } catch (error) {
          everyAttemptReturned = false;
          debugPrint('[CHAT_PAYMENT] reconcile attempt=${index + 1} failed orderId=$orderId error=$error');
        }
      }
      if (mounted) {
        _paymentNotice = gotResponse
            ? 'No captured payment confirmed yet. You can retry this same order.'
            : 'Payment status is still unavailable. Please check again before retrying.';
        _paymentInProgress = false;
        _checkingPaymentStatus = false;
        setState(() {});
      }
      return gotResponse && everyAttemptReturned ? _PaymentReconcileResult.notCaptured : _PaymentReconcileResult.unknown;
    } finally {
      _reconcilingPayment = false;
      _checkingPaymentStatus = false;
    }
  }

  Future<void> _completeConfirmedPayment(String orderId, {bool alreadyUnlocked = false}) async {
    if (!mounted) return;
    debugPrint('[CHAT_PAYMENT] backend confirmed captured payment orderId=$orderId');
    _pendingPaymentOrderId = null;
    _pendingPaymentOrder = null;
    await _savePendingPaymentOrder(null);
    _paymentInProgress = false;
    context.read<AuthBloc>().add(CheckAuthEvent());
    final pendingMessage = _pendingPaidMessage;
    await _refresh();
    final hasChatAccess = _chatAccess?.isPaid == true;
    if (hasChatAccess && pendingMessage != null && pendingMessage.isNotEmpty) {
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
    if (mounted) {
      setState(() {});
      final message = !hasChatAccess
          ? 'Payment was recorded, but chat access is not active. Refresh the chat or contact support.'
          : alreadyUnlocked
              ? 'Chat is already unlocked.'
              : 'Payment confirmed. Chat is unlocked.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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
      final detail = await _future;
      _chatAccess = detail?.chatAccess;
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
    if (_paymentInProgress || _restoringPendingOrder) return;
    debugPrint('[CHAT_PAYMENT] start conversation=${widget.conversationId} reusingPending=${_pendingPaymentOrder != null}');
    setState(() => _paymentInProgress = true);
    if (messageToSend != null) _pendingPaidMessage = messageToSend;
    try {
      if (_pendingPaymentOrderId != null) {
        final status = await _reconcilePendingPayment();
        if (status != _PaymentReconcileResult.notCaptured) return;
        if (!mounted) return;
        setState(() {
          _paymentInProgress = true;
          _paymentNotice = null;
        });
      }
      final order = _pendingPaymentOrder ?? await context.read<MessageRepository>().createChatUnlockOrder(widget.conversationId);
      if (!mounted) return;
      debugPrint('[CHAT_PAYMENT] order response paid=${order.alreadyPaid} orderId=${order.orderId.isEmpty ? '(none)' : order.orderId} amountPaise=${order.amountPaise} currency=${order.currency}');
      if (order.alreadyPaid) {
        context.read<AuthBloc>().add(CheckAuthEvent());
        await _completeConfirmedPayment('server-entitlement', alreadyUnlocked: true);
        return;
      }
      _pendingPaymentOrder = order;
      _pendingPaymentOrderId = order.orderId;
      await _savePendingPaymentOrder(order.orderId);
      debugPrint('[CHAT_PAYMENT] opening checkout orderId=${order.orderId}');
      final currentUser = context.read<AuthRepository>().currentUser;
      _razorpay.open({
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'Rishikesh Law Hub',
        'description': 'Unlock this chat',
        'timeout': 180, // 3 minutes for UPI app switching & bank approval
        'retry': {'enabled': true, 'max_count': 3},
        'send_sms_hash': true,
        'prefill': {
          'email': currentUser?.email ?? '',
          'contact': currentUser?.phone ?? '',
        },
      });
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] order/checkout start failed error=$error');
      _paymentInProgress = false;
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
      await _completeConfirmedPayment(orderId);
    } catch (error) {
      debugPrint('[CHAT_PAYMENT] success callback verification failed orderId=${orderId ?? '(missing)'} error=$error');
      if (orderId != null) await _reconcilePendingPayment();
    } finally {
      _paymentInProgress = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _onPaymentError(PaymentFailureResponse response) async {
    final orderId = _pendingPaymentOrderId;
    debugPrint('[CHAT_PAYMENT] checkout error orderId=${orderId ?? '(missing)'} code=${response.code} message=${response.message} description=${response.error?['description']}');
    _paymentNotice = 'Checking payment status...';
    _checkingPaymentStatus = true;
    _paymentInProgress = true;
    if (mounted) setState(() {});
    if (orderId == null || orderId.isEmpty) {
      _paymentInProgress = false;
      _checkingPaymentStatus = false;
      if (mounted) setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment status is unavailable. Check your payment before retrying.')));
      return;
    }
    await _reconcilePendingPayment();
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
