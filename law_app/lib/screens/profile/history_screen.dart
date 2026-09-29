import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../cases/case_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: textPrimary,
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          Translation.t('reading_history'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: primaryOrGold),
            onPressed: () {
              CustomConfirmationDialog.show(
                context,
                title: Translation.t('clear_history'),
                message: Translation.t('clear_history_confirm'),
                confirmText: Translation.t('clear_all'),
                onConfirm: () {
                  context.read<UserDataBloc>().add(ClearHistoryEvent());
                },
              );
            },
          ),
        ],
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
            if (state.history.isEmpty) {
              return Center(
                child: Text(
                  Translation.t('no_reading_history'),
                  style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              itemBuilder: (context, idx) {
                final h = state.history[idx];
                final title = h['title']?.toString() ?? Translation.t('untitled_case');
                final refId = h['refId']?.toString() ?? '';
                final viewedAt = h['viewedAt']?.toString() ?? '';

                return Card(
                  elevation: 0,
                  color: cardBg,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.history, color: primaryOrGold),
                    title: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: viewedAt.isNotEmpty
                        ? Text(viewedAt.split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                    onTap: () {
                      if (refId.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: refId)),
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

