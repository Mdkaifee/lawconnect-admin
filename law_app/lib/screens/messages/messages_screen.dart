import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message_model.dart';
import '../../repositories/message_repository.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<ConversationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<MessageRepository>().getConversations();
  }

  Future<void> _refresh() async {
    setState(() => _future = context.read<MessageRepository>().getConversations());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryOrGold(context);

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          appBar: AppBar(
            backgroundColor: AppTheme.appBarColor(context),
            foregroundColor: textPrimary,
            surfaceTintColor: AppTheme.appBarColor(context),
            title: Text(Translation.t('messages'), style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
          ),
          body: FutureBuilder<List<ConversationModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primary));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return RefreshIndicator(
                  color: primary,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                      Icon(Icons.forum_outlined, size: 46, color: textSecondary),
                      const SizedBox(height: 12),
                      Text(Translation.t('no_messages_yet'), textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: primary,
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.dividerColor(context)),
                  itemBuilder: (context, index) {
                    final conversation = items[index];
                    final user = conversation.otherUser;
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primary,
                            backgroundImage: user.photoUrl?.trim().isNotEmpty == true ? NetworkImage(user.photoUrl!.trim()) : null,
                            child: user.photoUrl?.trim().isNotEmpty == true
                                ? null
                                : Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: user.isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.backgroundColor(context), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(user.name, style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
                      subtitle: Text(
                        conversation.isRequested
                            ? (conversation.isRequester ? Translation.t('message_request_sent') : Translation.t('new_message_request'))
                            : conversation.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: conversation.unreadCount > 0 ? textPrimary : textSecondary, fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w400),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(DateFormatter.timeAgo(conversation.lastMessageAt), style: TextStyle(fontSize: 11, color: textSecondary)),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFFEA580C) : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(conversation.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation.id)));
                        if (mounted) _refresh();
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
