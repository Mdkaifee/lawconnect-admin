import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  String? _photoUrl;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _headlineController = TextEditingController(text: widget.user.headline);
    _collegeController = TextEditingController(text: widget.user.college);
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 900,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final mimeType = picked.mimeType ?? (picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    if (!mounted) return;
    context.read<AuthBloc>().add(UploadProfilePhotoEvent(imageBytes: bytes, mimeType: mimeType));
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryNavy),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryNavy),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            photoUrl: _photoUrl,
          ),
        );
    _savingProfile = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _photoUrl = state.user.photoUrl;
          if (mounted) setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
          );
          if (_savingProfile) {
            _savingProfile = false;
            Navigator.of(context).pop();
          }
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
            final previewUrl = state is Authenticated ? state.user.photoUrl ?? _photoUrl ?? '' : _photoUrl ?? '';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tap photo to change',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 22),
                _ProfileField(label: 'Name', controller: _nameController),
                const SizedBox(height: 14),
                _ProfileField(label: 'Headline', controller: _headlineController),
                const SizedBox(height: 14),
                _ProfileField(label: 'College / Organization', controller: _collegeController),
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
