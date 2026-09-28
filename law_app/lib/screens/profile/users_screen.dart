import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/user_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<AppUserConnection>> _usersFuture;
  final Set<String> _busyUserIds = {};

  @override
  void initState() {
    super.initState();
    _usersFuture = context.read<UserRepository>().getAppUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = context.read<UserRepository>().getAppUsers();
    });
    await _usersFuture;
  }

  Future<void> _updateConnection(AppUserConnection item) async {
    if (_busyUserIds.contains(item.user.id)) return;
    setState(() => _busyUserIds.add(item.user.id));
    try {
      if (item.connectionStatus == 'incoming') {
        await context.read<UserRepository>().accept(item.user.id);
      } else {
        await context.read<UserRepository>().connect(item.user.id);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(item.user.id));
    }
  }

  String _buttonText(String status) {
    switch (status) {
      case 'friend':
        return 'Unfriend';
      case 'requested':
        return 'Cancel Request';
      case 'incoming':
        return 'Accept Request';
      default:
        return 'Follow';
    }
  }

  Color _buttonColor(String status, BuildContext context) {
    final isDark = AppTheme.isDark(context);
    switch (status) {
      case 'friend':
        return AppColors.danger;
      case 'requested':
        return AppColors.textMuted;
      case 'incoming':
        return AppColors.goldAccent;
      default:
        return isDark ? AppColors.goldAccent : AppColors.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: textPrimary,
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        title: Text('Users', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      body: FutureBuilder<List<AppUserConnection>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryOrGold));
          }
          if (snapshot.hasError) {
            return Center(
              child: ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text('No users found.', style: TextStyle(color: AppTheme.textSecondaryColor(context))),
            );
          }

          return RefreshIndicator(
            color: primaryOrGold,
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.dividerColor(context), indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final item = users[index];
                final user = item.user;
                final color = _buttonColor(item.connectionStatus, context);
                final isBusy = _busyUserIds.contains(user.id);
                const canTap = true;
                final isDefaultFollow = item.connectionStatus != 'friend' && item.connectionStatus != 'requested' && item.connectionStatus != 'incoming';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.surfaceDarkElevated : AppColors.primaryNavy,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: isDark ? AppColors.goldAccentLight : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  subtitle: Text(
                    '${user.headline}\n${user.college}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: SizedBox(
                    width: item.connectionStatus == 'requested' ? 132 : 112,
                    child: ElevatedButton(
                      onPressed: canTap && !isBusy ? () => _updateConnection(item) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: (isDark && isDefaultFollow) ? AppColors.primaryNavyDark : Colors.white,
                        disabledBackgroundColor: color.withValues(alpha: 0.72),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      child: isBusy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _buttonText(item.connectionStatus),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
