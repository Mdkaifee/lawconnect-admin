import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/act_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/bookmark_repository.dart';
import 'data/repositories/case_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/update_repository.dart';
import 'logic/blocs/act/act_bloc.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/bookmark/bookmark_bloc.dart';
import 'logic/blocs/case/case_bloc.dart';
import 'logic/blocs/note/note_bloc.dart';
import 'logic/blocs/post/post_bloc.dart';
import 'logic/blocs/update/update_bloc.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storage = await StorageService.init();
  final apiClient = ApiClient(storage);

  final authRepo = AuthRepository(apiClient, storage);
  final caseRepo = CaseRepository(apiClient);
  final actRepo = ActRepository(apiClient);
  final updateRepo = UpdateRepository(apiClient);
  final postRepo = PostRepository(apiClient);
  final noteRepo = NoteRepository(apiClient);
  final bookmarkRepo = BookmarkRepository(apiClient);

  runApp(
    LawApp(
      authRepository: authRepo,
      caseRepository: caseRepo,
      actRepository: actRepo,
      updateRepository: updateRepo,
      postRepository: postRepo,
      noteRepository: noteRepo,
      bookmarkRepository: bookmarkRepo,
    ),
  );
}

class LawApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CaseRepository caseRepository;
  final ActRepository actRepository;
  final UpdateRepository updateRepository;
  final PostRepository postRepository;
  final NoteRepository noteRepository;
  final BookmarkRepository bookmarkRepository;

  const LawApp({
    super.key,
    required this.authRepository,
    required this.caseRepository,
    required this.actRepository,
    required this.updateRepository,
    required this.postRepository,
    required this.noteRepository,
    required this.bookmarkRepository,
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
        RepositoryProvider.value(value: noteRepository),
        RepositoryProvider.value(value: bookmarkRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepository)),
          BlocProvider(create: (_) => CaseBloc(caseRepository)),
          BlocProvider(create: (_) => ActBloc(actRepository)),
          BlocProvider(create: (_) => UpdateBloc(updateRepository)),
          BlocProvider(create: (_) => PostBloc(postRepository)),
          BlocProvider(create: (_) => NoteBloc(noteRepository)),
          BlocProvider(create: (_) => BookmarkBloc(bookmarkRepository)),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
