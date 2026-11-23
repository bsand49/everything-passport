import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_dev.dart' as prod; // TODO: Amend to firebase_options_prod.dart once prod project is created
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/user_profile_service.dart';
import 'services/metadata_service.dart';
import 'models/user_profile.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_profile_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/email_verification_banner.dart';

import 'package:http/http.dart' as http;

// coverage:ignore-start
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  const String serverClientId = String.fromEnvironment('SERVER_CLIENT_ID');

  FirebaseOptions selectedOptions;
  if (env == 'prod') {
    selectedOptions = prod.DefaultFirebaseOptions.currentPlatform;
  } else {
    selectedOptions = dev.DefaultFirebaseOptions.currentPlatform;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: selectedOptions);
  }
  // Offline persistence is on by default for mobile, but set it explicitly
  // (with an unbounded cache) so Firestore reads are served from the local
  // cache whenever possible. Must run before any Firestore instance use.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
  runApp(const MyApp());
}
// coverage:ignore-end

class MyApp extends StatelessWidget {
  final AuthService? authService;
  final UserProfileService? userProfileService;
  final MetadataService? metadataService;
  final CacheService? cacheService;
  final http.Client? httpClient;

  const MyApp({
    super.key,
    this.authService,
    this.userProfileService,
    this.metadataService,
    this.cacheService,
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
        Provider<AuthService>(create: (_) => authService ?? AuthService()),
        Provider<UserProfileService>(
          create: (_) => userProfileService ?? UserProfileService(),
        ),
        Provider<MetadataService>(
          create: (_) => metadataService ?? MetadataService(),
        ),
        Provider<CacheService>(
          create: (context) =>
              cacheService ??
              CacheService(service: context.read<MetadataService>()),
        ),
        // lazy: false so the auth/profile streams subscribe on first build
        // rather than on first read — otherwise AuthWrapper briefly sees
        // initialData (null) and flashes the login screen for signed-in
        // users while the first emission is in flight.
        StreamProvider<User?>(
          lazy: false,
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        StreamProvider<UserProfile?>(
          lazy: false,
          create: (context) {
            final userProfileService = context.read<UserProfileService>();
            return context
                .read<AuthService>()
                .user
                // userChanges() emits a fresh User snapshot on reload()
                // (e.g. after email verification); only restart the profile
                // subscription when the signed-in user actually changes.
                .distinct((a, b) => a?.uid == b?.uid)
                .switchMap((user) {
                  if (user == null) return Stream.value(null);
                  return userProfileService.streamProfile(userId: user.uid);
                });
          },
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Everything Passport',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('en', 'GB'), // Changes format to dd/MM/yyyy
          Locale('en', 'US'), // Changes format to MM/dd/yyyy
        ],
        builder: (context, child) {
          // Auth screens have no AppBar to supply a status-bar style, so set
          // icon brightness from the theme to keep them readable on cream.
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              // The navigation bar colour is not controlled by the app, so
              // its icon brightness is left at the native default rather
              // than risking dark-on-dark buttons.
            ),
            child: SafeArea(top: false, bottom: true, child: child!),
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
      return const LoginScreen();
    }

    if (profile == null || profile.isIncomplete) {
      return const EmailVerificationBannerHost(child: UserProfileScreen());
    }

    return const EmailVerificationBannerHost(child: HomeScreen());
  }
}
