import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reading History',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.primaryNavy),
            onPressed: () {
              CustomConfirmationDialog.show(
                context,
                title: 'Clear History',
                message: 'Are you sure you want to clear your entire reading history?',
                confirmText: 'Clear All',
                onConfirm: () {
                  context.read<UserDataBloc>().add(ClearHistoryEvent());
                },
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: BlocBuilder<UserDataBloc, UserDataState>(
        builder: (context, state) {
          if (state is UserDataLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
          }

          if (state is UserDataLoaded) {
            if (state.history.isEmpty) {
              return const Center(child: Text('No reading history recorded yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              itemBuilder: (context, idx) {
                final h = state.history[idx];
                final title = h['title']?.toString() ?? 'Untitled Case';
                final refId = h['refId']?.toString() ?? '';
                final viewedAt = h['viewedAt']?.toString() ?? '';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: AppColors.primaryNavy),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
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

