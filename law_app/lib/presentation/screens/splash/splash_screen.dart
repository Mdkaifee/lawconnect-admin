import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../common_widgets/scales_logo.dart';
import '../auth/login_screen.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    context.read<AuthBloc>().add(AppStartedEvent());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToNext(AuthState state) {
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (state is Authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated || state is AuthError) {
          _navigateToNext(state);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),
                  // Center Logo and Title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ScalesLogo(size: 110),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.merriweather(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.lightGold,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Quote
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withAlpha(40)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppConstants.splashQuote,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.merriweather(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConstants.splashQuoteAuthor,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGold,
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
