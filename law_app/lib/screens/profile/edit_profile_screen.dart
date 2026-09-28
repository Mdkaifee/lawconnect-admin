import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _collegeController;
  late final TextEditingController _photoUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _headlineController = TextEditingController(text: widget.user.headline);
    _collegeController = TextEditingController(text: widget.user.college);
    _photoUrlController = TextEditingController(text: widget.user.photoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _collegeController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          UpdateProfileEvent(
            name: name,
            headline: _headlineController.text.trim(),
            college: _collegeController.text.trim(),
            photoUrl: _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
          );
          Navigator.of(context).pop();
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryNavy,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final previewUrl = _photoUrlController.text.trim();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryNavy,
                    backgroundImage: previewUrl.isNotEmpty ? NetworkImage(previewUrl) : null,
                    child: previewUrl.isEmpty
                        ? Text(
                            _nameController.text.trim().isNotEmpty ? _nameController.text.trim()[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 22),
                _ProfileField(label: 'Name', controller: _nameController),
                const SizedBox(height: 14),
                _ProfileField(label: 'Headline', controller: _headlineController),
                const SizedBox(height: 14),
                _ProfileField(label: 'College / Organization', controller: _collegeController),
                const SizedBox(height: 14),
                _ProfileField(
                  label: 'Profile Image URL',
                  controller: _photoUrlController,
                  hint: 'Paste uploaded photo link here',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
