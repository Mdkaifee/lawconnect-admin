import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Saved Bookmarks',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: BlocBuilder<UserDataBloc, UserDataState>(
        builder: (context, state) {
          if (state is UserDataLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
          }

          if (state is UserDataLoaded) {
            if (state.bookmarks.isEmpty) {
              return const Center(child: Text('No bookmarks saved yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookmarks.length,
              itemBuilder: (context, idx) {
                final b = state.bookmarks[idx];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        b.refType == 'section' ? Icons.menu_book : Icons.account_balance,
                        color: AppColors.goldAccent,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      b.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryNavy),
                    ),
                    subtitle: b.subtitle != null
                        ? Text(b.subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
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
  }
}
