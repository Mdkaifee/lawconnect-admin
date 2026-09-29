import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../repositories/ai_repository.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await context.read<AiRepository>().loadHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _loadingHistory) return;
    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
    });
    _scrollToBottom();
    try {
      final reply = await context.read<AiRepository>().send(text);
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last['role'] == 'user' && _messages.last['content'] == text) {
            _messages.removeLast();
          }
        });
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final bottom = _scrollController.position.maxScrollExtent;
        if (jump) {
          _scrollController.jumpTo(bottom);
        } else {
          _scrollController.animateTo(bottom, duration: const Duration(milliseconds: 220), curve: Curves.easeOut).then((_) {
            if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > _scrollController.position.pixels) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOrGold(context);
    final textColor = AppTheme.textPrimaryColor(context);
    final secondary = AppTheme.textSecondaryColor(context);
    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.appBarColor(context),
          foregroundColor: textColor,
          title: const Text('AI Legal Chat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: _loadingHistory
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 38, color: primary),
                            const SizedBox(height: 12),
                            Text('Ask a legal research question', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text('AI can make mistakes. Verify important information with a qualified lawyer.', style: TextStyle(color: secondary), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primary))),
                          );
                        }
                        final message = _messages[index];
                        final mine = message['role'] == 'user';
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: mine ? primary : AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: mine ? null : Border.all(color: AppTheme.borderColor(context)),
                            ),
                            child: SelectableText(message['content'] ?? '', style: TextStyle(color: mine ? Colors.white : textColor, height: 1.4)),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(12, 9, 12, 10 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(color: AppTheme.cardColor(context), border: Border(top: BorderSide(color: AppTheme.borderColor(context)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Ask Law Hub AI', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sending ? null : _send, icon: Icon(_sending ? Icons.hourglass_top_rounded : Icons.send_rounded)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
