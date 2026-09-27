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
        backgroundColor: AppColors.primaryNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 150,
                height: 150,
                child: Image(image: AssetImage('assets/upper.png'), fit: BoxFit.contain),
              ),
              const SizedBox(height: 28),
              const Text(
                'Rishikesh Law Hub',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn Law • Find Cases • Understand Justice',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 64),
              const Text('“Justice delayed is justice denied.”', style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              const Text('— Lord Acton', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 48),
              SizedBox(
                height: 105,
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 96,
                  color: AppColors.goldAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
