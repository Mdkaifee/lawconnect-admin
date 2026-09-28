import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../cases/case_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final bool showBackButton;
  const BookmarksScreen({super.key, this.showBackButton = false});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserDataBloc>().add(LoadUserDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final isDark = AppTheme.isDark(context);

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          appBar: AppBar(
            backgroundColor: AppTheme.appBarColor(context),
            foregroundColor: textPrimary,
            surfaceTintColor: AppTheme.appBarColor(context),
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: widget.showBackButton
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: Text(
              Translation.t('saved_bookmarks'),
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.dividerColor(context)),
            ),
          ),
          body: BlocBuilder<UserDataBloc, UserDataState>(
            builder: (context, state) {
              if (state is UserDataLoading) {
                return Center(child: CircularProgressIndicator(color: primaryOrGold));
              }

              if (state is UserDataLoaded) {
                if (state.bookmarks.isEmpty) {
                  return Center(
                    child: Text(
                      'No bookmarks saved yet.',
                      style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.bookmarks.length,
                  itemBuilder: (context, idx) {
                    final b = state.bookmarks[idx];
                    return Card(
                      elevation: 0,
                      color: cardBg,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            b.refType == 'section' ? Icons.menu_book : Icons.account_balance,
                            color: isDark ? AppColors.goldAccentLight : AppColors.goldAccent,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          b.title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
                        ),
                        subtitle: b.subtitle != null
                            ? Text(b.subtitle!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor(context)))
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_remove, color: AppColors.danger, size: 20),
                          onPressed: () {
                            context.read<UserDataBloc>().add(
                                  ToggleBookmarkEvent(
                                    refType: b.refType,
                                    refId: b.refId,
                                    title: b.title,
                                  ),
                                );
                          },
                        ),
                        onTap: () {
                          if (b.refType == 'case') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: b.refId)),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
