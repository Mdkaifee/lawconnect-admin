import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/translation.dart';
import 'repositories/auth_repository.dart';
import 'repositories/case_repository.dart';
import 'repositories/act_repository.dart';
import 'repositories/update_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/user_data_repository.dart';
import 'repositories/user_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/case/case_bloc.dart';
import 'blocs/act/act_bloc.dart';
import 'blocs/update/update_bloc.dart';
import 'blocs/post/post_bloc.dart';
import 'blocs/user_data/user_data_bloc.dart';
import 'screens/splash_screen.dart';
import 'widgets/no_internet_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity monitoring service
  ConnectivityService.instance.initialize();
  await Translation.instance.init();

  final authRepository = AuthRepository();
  await authRepository.init();
  await NotificationService.instance.initialize(authRepository);

  final caseRepository = CaseRepository();
  final actRepository = ActRepository();
  final updateRepository = UpdateRepository();
  final postRepository = PostRepository(authRepo: authRepository);
  final userDataRepository = UserDataRepository(authRepo: authRepository);
  final userRepository = UserRepository(authRepo: authRepository);

  runApp(
    LawHubApp(
      authRepository: authRepository,
      caseRepository: caseRepository,
      actRepository: actRepository,
      updateRepository: updateRepository,
      postRepository: postRepository,
      userDataRepository: userDataRepository,
      userRepository: userRepository,
    ),
  );
}

class LawHubApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CaseRepository caseRepository;
  final ActRepository actRepository;
  final UpdateRepository updateRepository;
  final PostRepository postRepository;
  final UserDataRepository userDataRepository;
  final UserRepository userRepository;

  const LawHubApp({
    super.key,
    required this.authRepository,
    required this.caseRepository,
    required this.actRepository,
    required this.updateRepository,
    required this.postRepository,
    required this.userDataRepository,
    required this.userRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: caseRepository),
        RepositoryProvider.value(value: actRepository),
        RepositoryProvider.value(value: updateRepository),
        RepositoryProvider.value(value: postRepository),
        RepositoryProvider.value(value: userDataRepository),
        RepositoryProvider.value(value: userRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)..add(CheckAuthEvent())),
          BlocProvider(create: (_) => CaseBloc(caseRepository: caseRepository)),
          BlocProvider(create: (_) => ActBloc(actRepository: actRepository)),
          BlocProvider(create: (_) => UpdateBloc(updateRepository: updateRepository)),
          BlocProvider(create: (_) => PostBloc(postRepository: postRepository)),
          BlocProvider(create: (_) => UserDataBloc(userDataRepository: userDataRepository)..add(LoadUserDataEvent())),
        ],
        child: AnimatedBuilder(
          animation: Translation.instance,
          builder: (context, _) {
            return MaterialApp(
              title: 'Rishikesh Law Hub',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return NoInternetOverlay(child: child ?? const SizedBox.shrink());
              },
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
