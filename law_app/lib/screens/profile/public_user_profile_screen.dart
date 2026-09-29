import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/premium_member_badge.dart';
import '../messages/chat_screen.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? fallbackName;

  const PublicUserProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
  });

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  late Future<UserModel> _profileFuture;
  Future<List<PostModel>>? _postsFuture;
  int _selectedTab = 0;
  bool _messageLoading = false;
  String _messageStatus = 'unknown';
  String _conversationId = '';
  bool _isMessageRequester = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<UserRepository>().getPublicProfile(widget.userId);
    _loadMessageStatus();
  }

  Future<void> _loadMessageStatus() async {
    final currentUserId = context.read<AuthRepository>().currentUser?.id;
    if (currentUserId == null || currentUserId == widget.userId) return;
    try {
      final state = await context.read<MessageRepository>().getOrCreateForUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _conversationId = state.conversationId;
        _messageStatus = state.status;
        _isMessageRequester = state.isRequester;
      });
    } catch (_) {}
  }

  Future<void> _openMessage(UserModel user) async {
    if (_messageLoading) return;
    setState(() => _messageLoading = true);
    try {
      final repo = context.read<MessageRepository>();
      var conversationId = _conversationId;
      var status = _messageStatus;
      if (conversationId.isEmpty || status == 'unknown') {
        final state = await repo.getOrCreateForUser(user.id);
        conversationId = state.conversationId;
        status = state.status;
      }
      if ((status == 'active' || user.isFriend) && conversationId.isNotEmpty) {
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversationId)));
        await _loadMessageStatus();
        return;
      }
      if (!mounted) return;
      await _showMessageRequestDialog(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _messageLoading = false);
    }
  }

  Future<void> _showMessageRequestDialog(UserModel user) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MessageRequestDialog(
        user: user,
        onSuccess: (id) {
          if (!mounted) return;
          setState(() {
            _conversationId = id;
            _messageStatus = 'requested';
            _isMessageRequester = true;
          });
        },
      ),
    );
  }

  void _loadPostsIfNeeded() {
    _postsFuture ??= context.read<PostRepository>().getPostsByAuthor(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final cardBg = AppTheme.cardColor(context);

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          appBar: AppBar(
            backgroundColor: AppTheme.appBarColor(context),
            foregroundColor: textPrimary,
            surfaceTintColor: AppTheme.appBarColor(context),
            title: Text(
              Translation.t('profile'),
              style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ),
          body: FutureBuilder<UserModel>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryOrGold));
              }
              if (snapshot.hasError) {
                return Center(child: Text(Translation.t('profile_load_failed'), style: TextStyle(color: textSecondary)));
              }

              final user = snapshot.data!;
              final tabs = user.isFriend ? [Translation.t('profile'), Translation.t('posts')] : [Translation.t('profile')];

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    color: cardBg,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: primaryOrGold,
                          backgroundImage: user.photoUrl?.trim().isNotEmpty == true ? NetworkImage(user.photoUrl!.trim()) : null,
                          child: user.photoUrl?.trim().isNotEmpty == true
                              ? null
                              : Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary), overflow: TextOverflow.ellipsis)),
                            if (user.isChatPaid) ...[
                              const SizedBox(width: 6),
                              const PremiumMemberBadge(),
                            ],
                          ],
                        ),
                        if (user.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(user.email, style: TextStyle(fontSize: 13, color: textSecondary)),
                        ],
                        if (user.headline.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(user.headline, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w700)),
                        ],
                        if (user.college.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(user.college, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: textSecondary)),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Stat(label: Translation.t('posts'), value: user.postsCount.toString()),
                            const SizedBox(width: 22),
                            _Stat(label: Translation.t('followers'), value: user.followersCount.toString()),
                            const SizedBox(width: 22),
                            _Stat(label: Translation.t('following'), value: user.followingCount.toString()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (context.read<AuthRepository>().currentUser?.id != user.id)
                          FilledButton.icon(
                            onPressed: (_messageLoading || (_messageStatus == 'requested' && _isMessageRequester)) ? null : () => _openMessage(user),
                            icon: _messageLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.forum_outlined),
                            label: Text(
                              _messageStatus == 'requested'
                                  ? (_isMessageRequester ? Translation.t('message_request_sent') : Translation.t('open_request'))
                                  : (user.isFriend || _messageStatus == 'active')
                                      ? Translation.t('message')
                                      : Translation.t('message_request'),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _OnlineLine(user: user),
                      ],
                    ),
                  ),
                  if (tabs.length > 1)
                    Container(
                      color: cardBg,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: tabs.asMap().entries.map((entry) {
                          final selected = _selectedTab == entry.key;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() => _selectedTab = entry.key);
                                  if (entry.key == 1) _loadPostsIfNeeded();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? primaryOrGold : AppTheme.backgroundColor(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.borderColor(context)),
                                  ),
                                  child: Text(
                                    entry.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected ? Colors.white : textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Expanded(
                    child: _selectedTab == 0
                        ? _ProfileDetails(user: user)
                        : _PostsTab(postsFuture: _postsFuture ?? context.read<PostRepository>().getPostsByAuthor(widget.userId)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _OnlineLine extends StatelessWidget {
  final UserModel user;

  const _OnlineLine({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = user.isOnline ? Colors.green : AppTheme.textSecondaryColor(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: user.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          user.isOnline ? Translation.t('online') : '${Translation.t('last_seen')} ${user.lastActiveAt == null ? Translation.t('recently') : _shortLastSeen(user.lastActiveAt!)}',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  String _shortLastSeen(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return Translation.t('recently');
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor(context))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor(context))),
      ],
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final UserModel user;

  const _ProfileDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailTile(icon: Icons.person_outline, label: Translation.t('name'), value: user.name),
        _DetailTile(icon: Icons.mail_outline, label: Translation.t('email'), value: user.email),
        _DetailTile(icon: Icons.school_outlined, label: Translation.t('college_org'), value: user.college),
        _DetailTile(icon: Icons.badge_outlined, label: Translation.t('headline'), value: user.headline),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrGold(context)),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor(context))),
        subtitle: Text(
          value.trim().isEmpty ? Translation.t('not_added') : value,
          style: TextStyle(color: AppTheme.textSecondaryColor(context)),
        ),
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final Future<List<PostModel>> postsFuture;

  const _PostsTab({required this.postsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostModel>>(
      future: postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryOrGold(context)));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Text(Translation.t('no_posts_found'), style: TextStyle(color: AppTheme.textSecondaryColor(context))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final post = posts[index];
            final titleText = post.title.trim().isNotEmpty
                ? post.title.trim()
                : (post.content.trim().isNotEmpty
                    ? post.content.trim().split('\n').first
                    : (post.imageData != null ? 'Photo Post' : 'Post'));
            final subtitleText = post.content.trim().isNotEmpty
                ? post.content.trim()
                : (post.imageData != null ? 'Shared a photo' : '');

            return Card(
              elevation: 0,
              color: AppTheme.cardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderColor(context)),
              ),
              child: ListTile(
                leading: post.imageData != null
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrGold(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_outlined, color: AppTheme.primaryOrGold(context), size: 20),
                      )
                    : null,
                title: Text(titleText, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor(context))),
                subtitle: subtitleText.isNotEmpty
                    ? Text(
                        subtitleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _MessageRequestDialog extends StatefulWidget {
  final UserModel user;
  final ValueChanged<String> onSuccess;

  const _MessageRequestDialog({required this.user, required this.onSuccess});

  @override
  State<_MessageRequestDialog> createState() => _MessageRequestDialogState();
}

class _MessageRequestDialogState extends State<_MessageRequestDialog> {
  late final TextEditingController _controller;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final id = await context.read<MessageRepository>().sendMessageRequest(widget.user.id, text);
      if (!mounted) return;
      widget.onSuccess(id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translation.t('message_request_sent'))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Translation.t('message_request')),
      content: TextField(
        controller: _controller,
        maxLength: 250,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(hintText: Translation.t('message_request_hint')),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(Translation.t('cancel')),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(Translation.t('send')),
        ),
      ],
    );
  }
}

