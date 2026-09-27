import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../core/theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _minimumDurationComplete = false;
  AuthState? _pendingAuthState;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckAuthEvent());
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _minimumDurationComplete = true);
      _continueAfterSplash(_pendingAuthState);
    });
  }

  void _continueAfterSplash(AuthState? state) {
    if (!_minimumDurationComplete || !mounted || state == null) return;
    if (state is Authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (state is Unauthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _pendingAuthState = state;
        _continueAfterSplash(state);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071426),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 12),
                // Upper Section: Logo & Titles
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/upper.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Rishikesh Law Hub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Learn Law • Find Cases •\nUnderstand Justice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                // Middle Section: Lord Acton Quote
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '“Justice delayed is justice denied.”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '— Lord Acton',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC5A059),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Lower Section: Pillar Building Graphic
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.asset(
                    'assets/belowpillar.png',
                    width: 160,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
