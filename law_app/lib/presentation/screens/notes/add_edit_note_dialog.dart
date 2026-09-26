import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/note_model.dart';
import '../../../logic/blocs/note/note_bloc.dart';
import '../../../logic/blocs/note/note_event.dart';
import '../../common_widgets/custom_button.dart';
import '../../common_widgets/custom_text_field.dart';

class AddEditNoteDialog extends StatefulWidget {
  final NoteModel? note;
  final String? refType;
  final String? refId;
  final String? refTitle;

  const AddEditNoteDialog({
    super.key,
    this.note,
    this.refType,
    this.refId,
    this.refTitle,
  });

  static Future<void> show(
    BuildContext context, {
    NoteModel? note,
    String? refType,
    String? refId,
    String? refTitle,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddEditNoteDialog(
        note: note,
        refType: refType,
        refId: refId,
        refTitle: refTitle,
      ),
    );
  }

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.note != null) {
        context.read<NoteBloc>().add(
              UpdateNoteEvent(
                id: widget.note!.id,
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
              ),
            );
      } else {
        context.read<NoteBloc>().add(
              AddNoteEvent(
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                refType: widget.refType ?? 'general',
                refId: widget.refId,
                refTitle: widget.refTitle,
              ),
            );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Note' : 'Add Note',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (widget.refTitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Linked to: ${widget.refTitle}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Note Title',
                hint: 'e.g. Basic Structure Summary / Article 21 notes',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _contentController,
                label: 'Note Content',
                hint: 'Type your insights, legal points, or exam summary...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content required' : null,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Save Note',
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
