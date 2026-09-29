import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/act/act_bloc.dart';
import '../../blocs/update/update_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/url_helper.dart';
import '../../models/act_model.dart';
import '../../models/category_model.dart';
import '../../repositories/category_repository.dart';
import '../cases/case_search_screen.dart';
import '../cases/case_detail_screen.dart';
import '../acts/act_detail_screen.dart';
import '../acts/acts_list_screen.dart';
import '../community/community_feed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../messages/ai_chat_screen.dart';
import 'legal_category_screen.dart';
import '../profile/about_us_screen.dart';
import '../profile/bookmarks_screen.dart';
import '../profile/history_screen.dart';
import '../profile/notes_screen.dart';
import '../profile/settings_screen.dart';
import '../profile/users_screen.dart';
import '../messages/messages_screen.dart';
import '../../widgets/case_card.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/legal_category_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickSearchController = TextEditingController();
  final CategoryRepository _categoryRepository = CategoryRepository();
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    context.read<CaseBloc>().add(LoadCuratedLandmarksEvent());
    context.read<ActBloc>().add(const LoadActsEvent());
    context.read<UpdateBloc>().add(const LoadUpdatesEvent());
    context.read<PostBloc>().add(const LoadPostsEvent());
    context.read<NotificationBloc>().add(const LoadNotificationsEvent());
    _categoriesFuture = _loadCategories();
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
  }

  Future<void> _openGmailSupport(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'rishikesh4287@gmail.com',
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translation.t('contact_support_email')),
            backgroundColor: const Color(0xFF0F1E36),
          ),
        );
      }
    }
  }

  Future<List<CategoryModel>> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (categories.isNotEmpty) return categories;
    } catch (_) {}
    return _fallbackCategories;
  }

  void _openCategory(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalCategoryScreen(category: category)),
    );
  }

  void _openMoreCategories(List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  Translation.t('all_categories'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor(ctx),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.dividerColor(ctx)),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withValues(alpha: 0.14),
                        child: Icon(category.iconData, color: category.color),
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor(ctx)),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondaryColor(ctx)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCategory(category);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Translation.t('good_morning');
    if (hour < 17) return Translation.t('good_afternoon');
    if (hour < 21) return Translation.t('good_evening');
    return Translation.t('good_night');
  }

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isDark = ThemeManager.instance.isDarkMode;
    final defaultIconColor = iconColor ?? (isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36));
    final defaultTextColor = textColor ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36));
    final dividerColor = isDark ? const Color(0xFF1E2F4D) : const Color(0xFFF1F5F9);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(icon, color: defaultIconColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: defaultTextColor,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
          onTap: onTap,
        ),
        Divider(height: 1, color: dividerColor, indent: 20, endIndent: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Translation.instance, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final bgColor = isDark ? const Color(0xFF090E17) : AppColors.backgroundLight;
        final surfaceColor = isDark ? const Color(0xFF0F1827) : Colors.white;
        final borderColor = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
        final textColor = isDark ? const Color(0xFFF1F5F9) : AppColors.primaryNavy;
        final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final cardColor = isDark ? const Color(0xFF131D2D) : Colors.white;
        final dividerColor = isDark ? const Color(0xFF1E2F4D) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          drawer: Drawer(
            backgroundColor: surfaceColor,
            child: SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final user = state is Authenticated ? state.user : null;
                  final userName = user?.name.isNotEmpty == true ? user!.name : 'User';
                  final headline = user?.headline.trim() ?? '';
                  final college = user?.college.trim() ?? '';
                  final photoUrl = user?.photoUrl?.trim() ?? '';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Top Profile Header Row (Avatar + Name + Subtitle)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Circular Profile Avatar
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF1B283D) : const Color(0xFF0F1E36),
                                  border: Border.all(color: borderColor, width: 2),
                                  image: photoUrl.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: photoUrl.isEmpty
                                    ? Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            color: isDark ? AppColors.goldAccentLight : Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              // Name & Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            userName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        if (user?.isChatPaid == true) ...[
                                          const SizedBox(width: 6),
                                          const Tooltip(
                                            message: 'Premium member',
                                            child: Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF0F9F8F)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (user?.isChatPaid == true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          'Chat plan expires ${DateFormat('dd MMM yyyy').format(user!.chatPaidUntil!.toLocal())}',
                                          style: const TextStyle(color: Color(0xFF0F9F8F), fontSize: 10.5, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    if (headline.isNotEmpty)
                                      Text(
                                        headline,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: textMuted,
                                        ),
                                      ),
                                    if (college.isNotEmpty)
                                      Text(
                                        college,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w400,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: dividerColor),

                    // Menu Items List (matching exact profile screen)
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.bookmark_border_rounded,
                      title: Translation.t('my_posts'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CommunityFeedScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: Translation.t('my_notes'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotesScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.bookmark_outline_rounded,
                      title: Translation.t('bookmarks'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookmarksScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.history_rounded,
                      title: Translation.t('reading_history'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: Translation.t('users'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UsersScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.forum_outlined,
                      title: Translation.t('messages'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MessagesScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Legal Chat',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AiChatScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: Translation.t('notifications'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: Translation.t('settings'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.shield_outlined,
                      title: Translation.t('privacy_policy'),
                      onTap: () {
                        Navigator.pop(context);
                        UrlHelper.openInAppUrl(
                          context,
                          'https://rishikesh-law-hub-admin.onrender.com/privacy-policy',
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: Translation.t('help_support'),
                      onTap: () {
                        Navigator.pop(context);
                        _openGmailSupport(context);
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: Translation.t('about_us'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: Translation.t('log_out'),
                      onTap: () {
                        final authBloc = context.read<AuthBloc>();
                        CustomConfirmationDialog.show(
                          context,
                          title: Translation.t('confirm_sign_out'),
                          message: Translation.t('confirm_sign_out_msg'),
                          confirmText: Translation.t('log_out'),
                          cancelText: Translation.t('cancel'),
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFEF4444),
                          onConfirm: () {
                            authBloc.add(LogoutEvent());
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: textColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.55,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name = state is Authenticated ? state.user.name : 'Advocate';
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_timeBasedGreeting(), style: TextStyle(fontSize: 11, color: textMuted)),
                  Row(
                    children: [
                      if (state is Authenticated && state.user.isChatPaid) ...[
                        const Tooltip(
                          message: 'Premium member',
                          child: Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF0F9F8F)),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.waving_hand_rounded, size: 13, color: AppColors.goldAccent),
                    ],
                  ),
                  Text(Translation.t('learn_explore_grow'), style: TextStyle(fontSize: 9, color: textMuted)),
                ],
              );
            },
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: textColor),
                    tooltip: Translation.t('notifications'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CaseBloc>().add(LoadCuratedLandmarksEvent());
          context.read<ActBloc>().add(const LoadActsEvent());
          context.read<UpdateBloc>().add(const LoadUpdatesEvent());
          context.read<NotificationBloc>().add(const LoadNotificationsEvent(isRefresh: true));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Greeting & Quick Search
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Search Bar
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CaseSearchScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: isDark ? AppColors.goldAccentLight : AppColors.textMuted, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Translation.t('quick_search_hint'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textMuted, fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Reference-style quote and court banner.
              Container(
                margin: EdgeInsets.zero,
                height: 156,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1827) : Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/sci.png'),
                    fit: BoxFit.fill,
                    opacity: 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            (isDark ? const Color(0xFF090E17) : Colors.white).withValues(alpha: 0.88),
                            (isDark ? const Color(0xFF090E17) : Colors.white).withValues(alpha: 0.55),
                            (isDark ? const Color(0xFF090E17) : Colors.white).withValues(alpha: 0),
                          ],
                          stops: const [0, 0.45, 0.72],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 14, right: 118, bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '"The Constitution is\nnot a mere lawyers\' document,\nit is a vehicle of life, and its spirit\nis always the spirit of the age."\n\n- Dr. B.R. Ambedkar',
                              maxLines: 7,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF061328),
                                fontSize: 10.8,
                                height: 1.16,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic legal category grid
              FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? _fallbackCategories;
                  return LegalCategoryGrid(
                    categories: categories,
                    onCategoryTap: _openCategory,
                    onMoreTap: () => _openMoreCategories(categories),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Bare Acts Quick Access
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translation.t('key_bare_acts'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActsListScreen()),
                        );
                        if (mounted) context.read<ActBloc>().add(const LoadActsEvent());
                      },
                      child: Text(
                        Translation.t('view_all'),
                        style: TextStyle(
                          color: isDark ? AppColors.goldAccentLight : AppColors.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<ActBloc, ActState>(
                builder: (context, state) {
                  if (state is ActListLoaded) {
                    final acts = state.acts.isNotEmpty ? state.acts : _fallbackActs;
                    return _KeyBareActsList(acts: acts);
                  }
                  if (state is ActInitial || state is ActLoading) {
                    return SizedBox(
                      height: 105,
                      child: Center(child: CircularProgressIndicator(color: isDark ? AppColors.goldAccentLight : AppColors.primaryNavy)),
                    );
                  }
                  if (state is ActError) {
                    return const _KeyBareActsList(acts: _fallbackActs);
                  }
                  return const _KeyBareActsList(acts: _fallbackActs);
                },
              ),

              const SizedBox(height: 24),

              // Landmark Judgments Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  Translation.t('landmark_judgments'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              BlocBuilder<CaseBloc, CaseState>(
                builder: (context, state) {
                  if (state is CaseLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: isDark ? AppColors.goldAccentLight : AppColors.primaryNavy),
                      ),
                    );
                  }
                  if (state is CaseSearchSuccess && state.items.isNotEmpty) {
                    return Column(
                      children: state.items.take(4).map((c) {
                        return CaseCard(
                          caseItem: c,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: c.id)),
                            );
                          },
                        );
                      }).toList(),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(Translation.t('no_landmark_judgments')),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Verified Legal Updates Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      Translation.t('verified_legal_updates'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<UpdateBloc, UpdateState>(
                builder: (context, state) {
                  if (state is UpdateLoaded && state.updates.isNotEmpty) {
                    return Column(
                      children: state.updates.take(3).map((u) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2F4D) : AppColors.primaryNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.article_outlined, color: isDark ? AppColors.goldAccentLight : AppColors.primaryNavy, size: 22),
                            ),
                            title: Text(
                              u.title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${u.source} • ${u.category}',
                                style: TextStyle(fontSize: 11, color: textMuted),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _KeyBareActsList extends StatelessWidget {
  final List<ActModel> acts;

  const _KeyBareActsList({required this.acts});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final cardBg = isDark ? const Color(0xFF131D2D) : Colors.white;
    final cardBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final titleColor = isDark ? AppColors.textDarkPrimary : AppColors.primaryNavy;
    final textMuted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: acts.take(6).length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final act = acts[idx];
          return GestureDetector(
            onTap: () {
              if (act.id.isEmpty) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActsListScreen()));
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ActDetailScreen(actId: act.id, actName: act.name)),
              );
            },
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, color: AppColors.goldAccent, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    act.shortName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    act.sectionsCount > 0 ? '${act.sectionsCount} Sections' : 'Tap to explore',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

const List<ActModel> _fallbackActs = [
  ActModel(id: '', name: 'Constitution of India', shortName: 'Constitution'),
  ActModel(id: '', name: 'Bharatiya Nyaya Sanhita', shortName: 'BNS'),
  ActModel(id: '', name: 'Bharatiya Nagarik Suraksha Sanhita', shortName: 'BNSS'),
  ActModel(id: '', name: 'Bharatiya Sakshya Adhiniyam', shortName: 'BSA'),
  ActModel(id: '', name: 'Indian Contract Act', shortName: 'Contract Act'),
  ActModel(id: '', name: 'Code of Civil Procedure', shortName: 'CPC'),
];

const List<CategoryModel> _fallbackCategories = [
  CategoryModel(
    id: 'constitution',
    name: 'Constitution',
    slug: 'constitution',
    icon: 'book',
    color: Color(0xFF2196F3),
    order: 1,
  ),
  CategoryModel(
    id: 'criminal-law',
    name: 'Criminal Law',
    slug: 'criminal-law',
    icon: 'gavel',
    color: Color(0xFFFF9800),
    order: 2,
  ),
  CategoryModel(
    id: 'contract',
    name: 'Contract',
    slug: 'contract',
    icon: 'handshake',
    color: Color(0xFF22C55E),
    order: 3,
  ),
  CategoryModel(
    id: 'torts',
    name: 'Torts',
    slug: 'torts',
    icon: 'landmark',
    color: Color(0xFF4F46E5),
    order: 4,
  ),
  CategoryModel(
    id: 'family-law',
    name: 'Family Law',
    slug: 'family-law',
    icon: 'users',
    color: Color(0xFF7C3AED),
    order: 5,
  ),
  CategoryModel(
    id: 'labour-law',
    name: 'Labour Law',
    slug: 'labour-law',
    icon: 'briefcase',
    color: Color(0xFFEF4444),
    order: 6,
  ),
  CategoryModel(
    id: 'environment',
    name: 'Environment',
    slug: 'environment',
    icon: 'leaf',
    color: Color(0xFF14B8A6),
    order: 7,
  ),
];
