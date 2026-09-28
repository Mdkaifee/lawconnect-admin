import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../models/note_model.dart';
import '../../widgets/custom_confirmation_dialog.dart';

class NotesScreen extends StatefulWidget {
  final bool showBackButton;
  const NotesScreen({super.key, this.showBackButton = false});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserDataBloc>().add(LoadUserDataEvent());
  }

  void _showEditNoteDialog(BuildContext context, {NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? Translation.t('new_case_note') : Translation.t('edit_note'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: Translation.t('title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(labelText: Translation.t('notes_principles')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translation.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                context.read<UserDataBloc>().add(
                      SaveNoteEvent(
                        id: note?.id,
                        title: titleController.text.trim(),
                        content: contentController.text.trim(),
                        refType: note?.refType ?? 'general',
                        refId: note?.refId,
                        refTitle: note?.refTitle,
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: Text(Translation.t('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
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
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          Translation.t('case_study_notes'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditNoteDialog(context),
        backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(Icons.add, color: isDark ? AppColors.primaryNavyDark : Colors.white),
      ),
      body: BlocBuilder<UserDataBloc, UserDataState>(
        builder: (context, state) {
          if (state is UserDataLoading) {
            return Center(child: CircularProgressIndicator(color: primaryOrGold));
          }

          if (state is UserDataLoaded) {
            if (state.notes.isEmpty) {
              return Center(
                child: Text(
                  Translation.t('no_notes_yet'),
                  style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.notes.length,
              itemBuilder: (context, idx) {
                final note = state.notes[idx];
                return Card(
                  elevation: 0,
                  color: cardBg,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              onPressed: () => _showEditNoteDialog(context, note: note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              onPressed: () {
                                CustomConfirmationDialog.show(
                                  context,
                                  title: Translation.t('delete_note'),
                                  message: Translation.t('delete_note_confirm'),
                                  confirmText: Translation.t('delete'),
                                  onConfirm: () {
                                    context.read<UserDataBloc>().add(DeleteNoteEvent(note.id));
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        if (note.refTitle != null && note.refTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('${Translation.t('ref')}: ${note.refTitle}', style: const TextStyle(fontSize: 12, color: AppColors.goldAccent, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          note.content,
                          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondaryColor(context), height: 1.45),
                        ),
                      ],
                    ),
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
