import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<UserRepository>().getPublicProfile(widget.userId);
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
                        Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
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
            return Card(
              elevation: 0,
              color: AppTheme.cardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderColor(context)),
              ),
              child: ListTile(
                title: Text(post.title, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor(context))),
                subtitle: Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
