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

  testWidgets('LoginScreen displays email, password fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginScreen(),
      authService: mockAuthService,
    ));

    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors on empty submission',
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

  testWidgets('LoginScreen toggles password visibility',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginScreen(),
      authService: mockAuthService,
    ));

    final passwordFinder = find.byKey(const Key('passwordField'));
    expect(
        tester
            .widget<TextField>(find.descendant(
                of: passwordFinder, matching: find.byType(TextField)))
            .obscureText,
        isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(
        tester
            .widget<TextField>(find.descendant(
                of: passwordFinder, matching: find.byType(TextField)))
            .obscureText,
        isFalse);
  });

  testWidgets('LoginScreen calls signInWithEmail on Login button tap',
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

  testWidgets('LoginScreen calls signInWithGoogle on Google button tap',
      (WidgetTester tester) async {
    when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => null);

    await tester.pumpWidget(createTestableWidget(
      child: const LoginScreen(),
      authService: mockAuthService,
    ));

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    verify(mockAuthService.signInWithGoogle()).called(1);
  });

  testWidgets('LoginScreen shows SnackBar on failed email login',
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
    await tester.enterText(find.byKey(const Key('passwordField')), 'wrong');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Login Failed: Exception: Invalid credentials'),
        findsOneWidget);
  });

  testWidgets('LoginScreen shows SnackBar on failed Google login',
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

  testWidgets('LoginScreen shows loading indicator during request',
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

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(null);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('LoginScreen navigates to SignUpScreen on Sign Up tap',
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
}
