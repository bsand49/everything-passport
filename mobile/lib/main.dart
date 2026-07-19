import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_dev.dart'
    as prod; // TODO: Amend to firebase_options_prod.dart once prod project is created
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/metadata_service.dart';
import 'models/user_profile.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/user_profile_page.dart';
import 'package:http/http.dart' as http;

// coverage:ignore-start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  const String serverClientId = String.fromEnvironment('SERVER_CLIENT_ID');

  FirebaseOptions selectedOptions;
  if (env == 'prod') {
    selectedOptions = prod.DefaultFirebaseOptions.currentPlatform;
  } else {
    selectedOptions = dev.DefaultFirebaseOptions.currentPlatform;
  }

  await Firebase.initializeApp(
    options: selectedOptions,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
  );
  runApp(const MyApp());
}
// coverage:ignore-end

class MyApp extends StatelessWidget {
  final AuthService? authService;
  final UserService? userService;
  final MetadataService? metadataService;
  final http.Client? httpClient;

  const MyApp({
    super.key,
    this.authService,
    this.userService,
    this.metadataService,
    this.httpClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => httpClient ?? http.Client(),
          dispose: (_, client) {
            if (httpClient == null) client.close();
          },
        ),
        Provider<AuthService>(
          create: (_) => authService ?? AuthService(),
        ),
        Provider<UserService>(
          create: (_) => userService ?? UserService(),
        ),
        Provider<MetadataService>(
          create: (_) => metadataService ?? MetadataService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        StreamProvider<UserProfile?>(
          create: (context) {
            final userService = context.read<UserService>();
            return context.read<AuthService>().user.switchMap((user) {
              if (user == null) return Stream.value(null);
              return userService.streamProfile(user.uid);
            });
          },
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Everything Passport',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'GB'), // Changes format to dd/MM/yyyy
          Locale('en', 'US'), // Changes format to MM/dd/yyyy
        ],
        builder: (context, child) {
          return SafeArea(
            top: false,
            bottom: true,
            child: child!,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final profile = context.watch<UserProfile?>();

    if (user == null) {
      return const LoginPage();
    }

    if (profile == null || profile.isIncomplete) {
      return const UserProfilePage();
    }

    return const HomePage();
  }
}
