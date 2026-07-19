import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseAuth>(as: #MockAuth),
  MockSpec<User>(as: #MockUserMockito),
  MockSpec<GoogleSignIn>(as: #MockGoogleSignInMockito),
  MockSpec<GoogleSignInAccount>(as: #MockGoogleSignInAccountMockito),
  MockSpec<GoogleSignInAuthentication>(as: #MockGoogleSignInAuthenticationMockito),
  MockSpec<GoogleSignInAuthorizationClient>(as: #MockGoogleSignInAuthorizationClient),
  MockSpec<GoogleSignInClientAuthorization>(as: #MockGoogleSignInClientAuthorization),
  MockSpec<UserCredential>(as: #MockUserCredential),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
    });

    group('Constructor', () {
      test('AuthService() throws FirebaseException when Firebase is not initialized', () {
        expect(() => AuthService(), throwsA(isA<FirebaseException>()));
      });

      test('AuthService(auth: mockAuth) initializes successfully', () {
        expect(() => AuthService(auth: mockAuth), returnsNormally);
      });

      test('AuthService(googleSignIn: mockGoogleSignIn) throws FirebaseException when Firebase is not initialized', () {
        expect(() => AuthService(googleSignIn: mockGoogleSignIn), throwsA(isA<FirebaseException>()));
      });
    });

    group('currentUser', () {
      test('returns null when not logged in', () {
        expect(authService.currentUser, isNull);
      });

      test('returns user when logged in', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, 'test@example.com');
      });
    });

    group('User Stream', () {
      test('emits correct user state', () async {
        final streamExpectation = expectLater(
          authService.user,
          emitsInOrder([
            isNull,
            isNotNull,
            isNull,
          ]),
        );

        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        await authService.signOut();

        await streamExpectation;
      });
    });

    group('Email Auth', () {
      test('Sign in with email and password success', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');

        final result = await authService.signInWithEmail(
            'test@example.com', 'password123');
        expect(result?.user?.email, 'test@example.com');
      });

      test('Sign in with email and password FirebaseAuthException rethrows',
          () async {
        final failingAuth = MockAuth();
        when(failingAuth.signInWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signInWithEmail('error@test.com', 'pass'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('Sign in with email and password generic Exception rethrows',
          () async {
        final failingAuth = MockAuth();
        when(failingAuth.signInWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signInWithEmail('error@test.com', 'pass'),
          throwsException,
        );
      });

      test('Sign up with email and password success', () async {
        final result =
            await authService.signUpWithEmail('new@example.com', 'password123');
        expect(result?.user?.email, 'new@example.com');
      });

      test('Sign up with email and password FirebaseAuthException rethrows',
          () async {
        final failingAuth = MockAuth();
        when(failingAuth.createUserWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signUpWithEmail('error@test.com', 'pass'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('Sign up with email and password generic Exception rethrows',
          () async {
        final failingAuth = MockAuth();
        when(failingAuth.createUserWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signUpWithEmail('error@test.com', 'pass'),
          throwsException,
        );
      });
    });

    group('Google Auth', () {
      test('signInWithGoogle success path returns user credentials', () async {
        final mockGoogle = MockGoogleSignInMockito();
        final mockAccount = MockGoogleSignInAccountMockito();
        final mockAuthDetails = MockGoogleSignInAuthenticationMockito();
        final mockAuthClient = MockGoogleSignInAuthorizationClient();
        final mockClientAuth = MockGoogleSignInClientAuthorization();

        when(mockGoogle.authenticate()).thenAnswer((_) async => mockAccount);
        when(mockAccount.authentication).thenReturn(mockAuthDetails);
        when(mockAccount.authorizationClient).thenReturn(mockAuthClient);
        when(mockAuthClient.authorizationForScopes(any)).thenAnswer((_) async => mockClientAuth);
        when(mockAuthDetails.idToken).thenReturn('fake-id');
        when(mockClientAuth.accessToken).thenReturn('fake-token');

        final service = AuthService(googleSignIn: mockGoogle, auth: mockAuth);

        final result = await service.signInWithGoogle();
        expect(result, isNotNull);
        expect(service.currentUser, isNotNull);
      });

      test('signInWithGoogle success path when authorizationForScopes returns null (calls authorizeScopes)', () async {
        final mockGoogle = MockGoogleSignInMockito();
        final mockAccount = MockGoogleSignInAccountMockito();
        final mockAuthDetails = MockGoogleSignInAuthenticationMockito();
        final mockAuthClient = MockGoogleSignInAuthorizationClient();
        final mockClientAuth = MockGoogleSignInClientAuthorization();

        when(mockGoogle.authenticate()).thenAnswer((_) async => mockAccount);
        when(mockAccount.authentication).thenReturn(mockAuthDetails);
        when(mockAccount.authorizationClient).thenReturn(mockAuthClient);
        when(mockAuthClient.authorizationForScopes(any)).thenAnswer((_) async => null);
        when(mockAuthClient.authorizeScopes(any)).thenAnswer((_) async => mockClientAuth);
        when(mockAuthDetails.idToken).thenReturn('fake-id');
        when(mockClientAuth.accessToken).thenReturn('fake-token');

        final service = AuthService(googleSignIn: mockGoogle, auth: mockAuth);

        final result = await service.signInWithGoogle();
        expect(result, isNotNull);
        expect(service.currentUser, isNotNull);

        verify(mockAuthClient.authorizationForScopes(any)).called(1);
        verify(mockAuthClient.authorizeScopes(any)).called(1);
      });

      test('signInWithGoogle returns null on user cancellation (GoogleSignInException)',
          () async {
        final cancelledGoogle = MockGoogleSignInMockito();
        when(cancelledGoogle.authenticate()).thenThrow(
            const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));

        final service =
            AuthService(googleSignIn: cancelledGoogle, auth: mockAuth);

        final result = await service.signInWithGoogle();
        expect(result, isNull);
      });

      test('signInWithGoogle catch generic Exception rethrows', () async {
        final failingGoogle = MockGoogleSignInMockito();
        when(failingGoogle.authenticate()).thenThrow(Exception('test'));

        final service =
            AuthService(googleSignIn: failingGoogle, auth: mockAuth);

        expect(
          () => service.signInWithGoogle(),
          throwsException,
        );
      });
    });

    group('Password Reset', () {
      test('sendPasswordResetEmail success', () async {
        await authService.sendPasswordResetEmail('test@example.com');
        // Success if no exception thrown
      });

      test('sendPasswordResetEmail FirebaseAuthException rethrows', () async {
        final failingAuth = MockAuth();
        when(failingAuth.sendPasswordResetEmail(
                email: anyNamed('email'),
                actionCodeSettings: anyNamed('actionCodeSettings')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.sendPasswordResetEmail('error@test.com'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('sendPasswordResetEmail generic Exception rethrows', () async {
        final failingAuth = MockAuth();
        when(failingAuth.sendPasswordResetEmail(
                email: anyNamed('email'),
                actionCodeSettings: anyNamed('actionCodeSettings')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.sendPasswordResetEmail('error@test.com'),
          throwsException,
        );
      });
    });

    group('Account Management', () {
      test('deleteAccount success', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        expect(authService.currentUser, isNotNull);
        await authService.deleteAccount();
        expect(authService.currentUser, isNull);
      });

      test('deleteAccount does nothing and remains null if no user logged in', () async {
        expect(authService.currentUser, isNull);
        await authService.deleteAccount();
        expect(authService.currentUser, isNull);
      });

      test('deleteAccount FirebaseAuthException rethrows', () async {
        final mockAuthFailing = MockAuth();
        final mockUser = MockUserMockito();

        when(mockAuthFailing.currentUser).thenReturn(mockUser);
        when(mockUser.delete())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: mockAuthFailing, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.deleteAccount(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('deleteAccount generic Exception rethrows', () async {
        final mockAuthFailing = MockAuth();
        final mockUser = MockUserMockito();

        when(mockAuthFailing.currentUser).thenReturn(mockUser);
        when(mockUser.delete()).thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: mockAuthFailing, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.deleteAccount(),
          throwsException,
        );
      });
    });

    group('Sign Out', () {
      test('Sign out success', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        await authService.signOut();
        expect(mockAuth.currentUser, isNull);
      });

      test('Sign out FirebaseAuthException rethrows', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signOut(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('Sign out generic Exception rethrows', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut()).thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signOut(),
          throwsException,
        );
      });
    });
  });
}
