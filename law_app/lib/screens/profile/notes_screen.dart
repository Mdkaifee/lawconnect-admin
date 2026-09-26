import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
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
        title: Text(note == null ? 'New Case Note' : 'Edit Note', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Notes / Principles'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Case Study Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditNoteDialog(context),
        backgroundColor: AppColors.primaryNavy,
        child: const Icon(Icons.add, color: AppColors.goldAccent),
      ),
      body: BlocBuilder<UserDataBloc, UserDataState>(
        builder: (context, state) {
          if (state is UserDataLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
          }

          if (state is UserDataLoaded) {
            if (state.notes.isEmpty) {
              return const Center(child: Text('No notes yet. Tap + to create your first note!'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.notes.length,
              itemBuilder: (context, idx) {
                final note = state.notes[idx];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
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
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryNavy),
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
                                  title: 'Delete Note',
                                  message: 'Are you sure you want to permanently delete this note?',
                                  confirmText: 'Delete',
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
                          Text('Ref: ${note.refTitle}', style: const TextStyle(fontSize: 12, color: AppColors.goldAccent, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 8),
                        Text(note.content, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.45)),
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
