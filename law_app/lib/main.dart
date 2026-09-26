import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/case_repository.dart';
import 'repositories/act_repository.dart';
import 'repositories/update_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/user_data_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/case/case_bloc.dart';
import 'blocs/act/act_bloc.dart';
import 'blocs/update/update_bloc.dart';
import 'blocs/post/post_bloc.dart';
import 'blocs/user_data/user_data_bloc.dart';
import 'core/widgets/connectivity_wrapper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = AuthRepository();
  await authRepository.init();

  final caseRepository = CaseRepository();
  final actRepository = ActRepository();
  final updateRepository = UpdateRepository();
  final postRepository = PostRepository(authRepo: authRepository);
  final userDataRepository = UserDataRepository(authRepo: authRepository);

  runApp(
    LawHubApp(
      authRepository: authRepository,
      caseRepository: caseRepository,
      actRepository: actRepository,
      updateRepository: updateRepository,
      postRepository: postRepository,
      userDataRepository: userDataRepository,
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

  const LawHubApp({
    super.key,
    required this.authRepository,
    required this.caseRepository,
    required this.actRepository,
    required this.updateRepository,
    required this.postRepository,
    required this.userDataRepository,
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
        child: MaterialApp(
          title: 'Law Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) => ConnectivityWrapper(child: child ?? const SizedBox.shrink()),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

