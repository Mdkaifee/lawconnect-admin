import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          Translation.t('update_profile_photo'),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryNavy),
              title: Text(Translation.t('take_photo'), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryNavy),
              title: Text(Translation.t('choose_from_gallery'), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translation.t('name_required'))),
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
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              _photoUrl = state.user.photoUrl;
              if (mounted) setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(Translation.t('profile_updated')), backgroundColor: AppColors.success),
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
            backgroundColor: AppTheme.backgroundColor(context),
            appBar: AppBar(
              backgroundColor: AppTheme.appBarColor(context),
              foregroundColor: textPrimary,
              surfaceTintColor: AppTheme.appBarColor(context),
              elevation: 0,
              title: Text(
                Translation.t('edit_profile'),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textPrimary),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: AppTheme.dividerColor(context)),
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
                              backgroundColor: isDark ? AppColors.surfaceDarkElevated : AppColors.primaryNavy,
                              backgroundImage: previewUrl.isNotEmpty ? NetworkImage(previewUrl) : null,
                              child: previewUrl.isEmpty
                                  ? Text(
                                      _nameController.text.trim().isNotEmpty ? _nameController.text.trim()[0].toUpperCase() : 'U',
                                      style: TextStyle(color: isDark ? AppColors.goldAccentLight : Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
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
                                  border: Border.all(color: cardBg, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        Translation.t('tap_photo_to_change'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ProfileField(label: Translation.t('name'), controller: _nameController),
                    const SizedBox(height: 14),
                    _ProfileField(label: Translation.t('headline'), controller: _headlineController),
                    const SizedBox(height: 14),
                    _ProfileField(label: Translation.t('college_org'), controller: _collegeController),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
                        foregroundColor: isDark ? AppColors.primaryNavyDark : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.primaryNavyDark : Colors.white))
                          : Text(Translation.t('save_profile'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _ProfileField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
