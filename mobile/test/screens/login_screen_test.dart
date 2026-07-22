import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:everything_passport/screens/login_screen.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'login_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NavigatorObserver>(),
  MockSpec<AuthService>(),
])
void main() {
  group('LoginScreen', () {
    late MockAuthService mockAuthService;
    late MockNavigatorObserver mockObserver;

    setUpAll(() {
      provideDummy<Route<dynamic>>(
          MaterialPageRoute(builder: (_) => const SizedBox()));
    });

    setUp(() {
      mockAuthService = MockAuthService();
      mockObserver = MockNavigatorObserver();
    });

    group('Initialization', () {
      testWidgets(
          'displays email, password fields and buttons with initial state',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const LoginScreen(),
          authService: mockAuthService,
        ));

        expect(find.byKey(const Key('emailField')), findsOneWidget);
        expect(find.byKey(const Key('passwordField')), findsOneWidget);

        final emailField = tester.widget<TextField>(find.descendant(
            of: find.byKey(const Key('emailField')),
            matching: find.byType(TextField)));
        final passwordField = tester.widget<TextField>(find.descendant(
            of: find.byKey(const Key('passwordField')),
            matching: find.byType(TextField)));

        expect(emailField.controller?.text, isEmpty);
        expect(passwordField.controller?.text, isEmpty);
        expect(passwordField.obscureText, isTrue);

        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
        expect(find.text('Sign in with Google'), findsOneWidget);
        expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
      });
    });

    group('Interactions', () {
      group('Auth', () {
        testWidgets('calls signInWithEmail on Login button tap',
            (WidgetTester tester) async {
          when(mockAuthService.signInWithEmail(
                  email: anyNamed('email'), password: anyNamed('password')))
              .thenAnswer((_) async => null);

          await tester.pumpWidget(createTestableWidget(
            child: const LoginScreen(),
            authService: mockAuthService,
          ));

          await tester.enterText(
              find.byKey(const Key('emailField')), 'test@example.com');
          await tester.enterText(
              find.byKey(const Key('passwordField')), 'password123');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
          await tester.pump();

          verify(mockAuthService.signInWithEmail(
                  email: 'test@example.com', password: 'password123'))
              .called(1);
        });

        testWidgets('calls signInWithGoogle on Google button tap',
            (WidgetTester tester) async {
          when(mockAuthService.signInWithGoogle())
              .thenAnswer((_) async => null);

          await tester.pumpWidget(createTestableWidget(
            child: const LoginScreen(),
            authService: mockAuthService,
          ));

          await tester.tap(find.text('Sign in with Google'));
          await tester.pump();

          verify(mockAuthService.signInWithGoogle()).called(1);
        });

        testWidgets('shows SnackBar on failed email login',
            (WidgetTester tester) async {
          when(mockAuthService.signInWithEmail(
                  email: anyNamed('email'), password: anyNamed('password')))
              .thenThrow(Exception('Invalid credentials'));

          await tester.pumpWidget(createTestableWidget(
            child: const LoginScreen(),
            authService: mockAuthService,
          ));

          await tester.enterText(
              find.byKey(const Key('emailField')), 'test@example.com');
          await tester.enterText(
              find.byKey(const Key('passwordField')), 'wrong');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
          await tester.pumpAndSettle();

          expect(
              find.textContaining(
                  'Login Failed: Exception: Invalid credentials'),
              findsOneWidget);
        });

        testWidgets('shows SnackBar on failed Google login',
            (WidgetTester tester) async {
          when(mockAuthService.signInWithGoogle())
              .thenThrow(Exception('Account restricted'));

          await tester.pumpWidget(createTestableWidget(
            child: const LoginScreen(),
            authService: mockAuthService,
          ));

          await tester.tap(find.text('Sign in with Google'));
          await tester.pumpAndSettle();

          expect(
              find.textContaining(
                  'Google Login Failed: Exception: Account restricted'),
              findsOneWidget);
        });

        testWidgets('shows loading indicator during request',
            (WidgetTester tester) async {
          final completer = Completer<UserCredential?>();
          when(mockAuthService.signInWithGoogle())
              .thenAnswer((_) => completer.future);

          await tester.pumpWidget(createTestableWidget(
            child: const LoginScreen(),
            authService: mockAuthService,
          ));

          await tester.tap(find.text('Sign in with Google'));
          await tester.pump();

          expect(
              find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

          completer.complete(null);
          await tester.pump();

          expect(find.byType(CircularProgressIndicator), findsNothing);
        });
      });
    });

    group('Validation', () {
      testWidgets('shows validation errors on empty submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const LoginScreen(),
          authService: mockAuthService,
        ));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
        verifyNever(mockAuthService.signInWithEmail(
            email: anyNamed('email'), password: anyNamed('password')));
      });
    });

    group('Navigation', () {
      testWidgets('navigates to SignUpScreen on Sign Up tap',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const LoginScreen(),
          authService: mockAuthService,
          observer: mockObserver,
        ));

        await tester.tap(find.text('Don\'t have an account? Sign Up'));
        await tester.pumpAndSettle();

        verify(mockObserver.didPush(any, any)).called(2);
      });
    });
  });
}
