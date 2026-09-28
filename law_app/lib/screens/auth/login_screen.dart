import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _obscureRegisterPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_loginFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginEvent(
              email: _loginEmailController.text.trim(),
              password: _loginPasswordController.text,
            ),
          );
    }
  }

  void _submitRegister() {
    if (_registerFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterEvent(
              name: _registerNameController.text.trim(),
              email: _registerEmailController.text.trim(),
              password: _registerPasswordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.scale_rounded, color: AppColors.goldAccent, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Law Hub',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translation.t('law_hub_subtitle'),
                    style: TextStyle(fontSize: 13, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.borderLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: isDark ? AppColors.primaryNavyDark : Colors.white,
                      unselectedLabelColor: isDark ? AppColors.textDarkSecondary : AppColors.primaryNavy,
                      indicator: BoxDecoration(
                        color: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: Translation.t('sign_in')),
                        Tab(text: Translation.t('create_account')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Views
                  SizedBox(
                    height: 410,
                    child: TabBarView(
                      controller: _tabController,
                      clipBehavior: Clip.none,
                      children: [
                        // --- Sign In Tab ---
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Form(
                            key: _loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _loginEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: Translation.t('email_address'),
                                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                                  ),
                                  validator: (val) => val == null || !val.contains('@') ? Translation.t('valid_email_error') : null,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _loginPasswordController,
                                  obscureText: _obscureLoginPassword,
                                  decoration: InputDecoration(
                                    labelText: Translation.t('password'),
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureLoginPassword = !_obscureLoginPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (val) => val == null || val.length < 6 ? Translation.t('password_length_error') : null,
                                ),
                                const SizedBox(height: 24),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return ElevatedButton(
                                      onPressed: isLoading ? null : _submitLogin,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(Translation.t('sign_in_to_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- Register Tab ---
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Form(
                            key: _registerFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _registerNameController,
                                  decoration: InputDecoration(
                                    labelText: Translation.t('full_name'),
                                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? Translation.t('enter_name') : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _registerEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: Translation.t('email_address'),
                                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                                  ),
                                  validator: (val) => val == null || !val.contains('@') ? Translation.t('valid_email_error') : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _registerPasswordController,
                                  obscureText: _obscureRegisterPassword,
                                  decoration: InputDecoration(
                                    labelText: Translation.t('create_password'),
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureRegisterPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureRegisterPassword = !_obscureRegisterPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (val) => val == null || val.length < 6 ? Translation.t('password_length_error') : null,
                                ),
                                const SizedBox(height: 22),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return ElevatedButton(
                                      onPressed: isLoading ? null : _submitRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.goldAccent,
                                        foregroundColor: AppColors.primaryNavy,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2),
                                            )
                                          : Text(Translation.t('create_free_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
