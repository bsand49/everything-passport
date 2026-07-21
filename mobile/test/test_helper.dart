import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:everything_passport/services/auth_service.dart';
import 'package:everything_passport/services/user_profile_service.dart';
import 'package:everything_passport/services/metadata_service.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/models/country.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

// Manual Fake classes with call tracking to avoid Mockito null-safety issues with 'any'
class FakeAuthService extends Fake implements AuthService {
  final _userSubject = BehaviorSubject<User?>.seeded(null);

  String? lastEmail;
  String? lastPassword;
  int signInWithEmailCalls = 0;
  int signInWithGoogleCalls = 0;
  int signUpWithEmailCalls = 0;
  int signOutCalls = 0;

  bool throwError = false;
  String errorMessage = 'Test Error';
  Completer<UserCredential?>? loginCompleter;

  @override
  User? get currentUser => _userSubject.value;

  @override
  Stream<User?> get user => _userSubject.stream;

  void emitUser(User? user) => _userSubject.add(user);

  Future<UserCredential?> _handleAuth(Function() increment) async {
    if (loginCompleter != null) {
      await loginCompleter!.future;
    }
    increment();
    if (throwError) throw Exception(errorMessage);
    return null;
  }

  @override
  Future<UserCredential?> signInWithEmail(
      {required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    return _handleAuth(() => signInWithEmailCalls++);
  }

  @override
  Future<UserCredential?> signUpWithEmail(
      {required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    return _handleAuth(() => signUpWithEmailCalls++);
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    return _handleAuth(() => signInWithGoogleCalls++);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (throwError) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteAccount() async {
    if (throwError) throw Exception(errorMessage);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (throwError) throw Exception(errorMessage);
  }
}

class FakeUserProfileService extends Fake implements UserProfileService {
  final _profileSubject = BehaviorSubject<UserProfile?>.seeded(null);

  int isUsernameAvailableCalls = 0;
  int saveProfileCalls = 0;
  int uploadProfilePictureCalls = 0;
  UserProfile? lastSavedProfile;
  bool isUsernameAvailableResponse = true;
  bool throwError = false;
  String errorMessage = 'Test Error';
  Completer<void>? saveCompleter;

  @override
  Stream<UserProfile?> streamProfile({required String userId}) =>
      _profileSubject.stream;

  void emitProfile(UserProfile? profile) => _profileSubject.add(profile);

  @override
  Future<bool> isUsernameAvailable(
      {required String username, required String currentUserId}) async {
    isUsernameAvailableCalls++;
    return isUsernameAvailableResponse;
  }

  @override
  Future<void> saveProfile(
      {required UserProfile profile, required String oldUsername}) async {
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    saveProfileCalls++;
    if (throwError) throw Exception(errorMessage);
    lastSavedProfile = profile;
  }

  @override
  Future<String> uploadProfilePicture(
      {required String userId, required dynamic image}) async {
    uploadProfilePictureCalls++;
    return 'https://example.com/photo.jpg';
  }
}

class FakeMetadataService extends Fake implements MetadataService {
  List<Country> countries = [
    Country(id: 'US', name: 'United States', searchKeywords: ['usa']),
  ];
  @override
  Future<List<Country>> getCountries({bool forceRefresh = false}) async =>
      countries;
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_user';
  @override
  String? get email => 'test@example.com';
  @override
  String? get photoURL => 'https://example.com/photo.jpg';
}

Widget createTestableWidget({
  required Widget child,
  AuthService? authService,
  UserProfileService? userProfileService,
  MetadataService? metadataService,
  User? user,
  UserProfile? userProfile,
  NavigatorObserver? observer,
  http.Client? httpClient,
}) {
  return MultiProvider(
    providers: [
      Provider<http.Client>.value(value: httpClient ?? http.Client()),
      Provider<AuthService>.value(value: authService ?? FakeAuthService()),
      Provider<UserProfileService>.value(
          value: userProfileService ?? FakeUserProfileService()),
      Provider<MetadataService>.value(
          value: metadataService ?? FakeMetadataService()),
      Provider<User?>.value(value: user),
      Provider<UserProfile?>.value(value: userProfile),
    ],
    child: MaterialApp(
      home: child,
      navigatorObservers: observer != null ? [observer] : [],
    ),
  );
}
