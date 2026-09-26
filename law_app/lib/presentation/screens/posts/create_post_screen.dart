import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/blocs/post/post_bloc.dart';
import '../../../logic/blocs/post/post_event.dart';
import '../../common_widgets/custom_button.dart';
import '../../common_widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedCategory = 'Supreme Court';

  final List<String> _categories = [
    'Supreme Court',
    'Constitution',
    'Criminal Law',
    'High Court',
    'Contract Law',
    'General Law',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim().replaceAll('#', ''))
          .where((t) => t.isNotEmpty)
          .toList();

      context.read<PostBloc>().add(
            CreatePostEvent(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              category: _selectedCategory,
              tags: tags,
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Law Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Legal Analysis & Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Publish your analysis, case notes or legal updates to the student and advocate community.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _titleController,
                label: 'Post Title *',
                hint: 'e.g. SC grants interim relief on bail plea in PMLA case',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _contentController,
                label: 'Post Content *',
                hint: 'Write your legal analysis, case ratio, or opinion...',
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _tagsController,
                label: 'Hashtags (comma separated)',
                hint: 'SupremeCourt, Bail, PMLA, Article21',
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Publish Post',
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
