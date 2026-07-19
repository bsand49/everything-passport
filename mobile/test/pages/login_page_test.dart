import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:everything_passport/pages/login_page.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'login_page_test.mocks.dart';

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

  testWidgets('LoginPage displays email, password fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
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

  testWidgets('LoginPage shows validation errors on empty submission',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    verifyNever(mockAuthService.signInWithEmail(any, any));
  });

  testWidgets('LoginPage toggles password visibility',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    final passwordFinder = find.byKey(const Key('passwordField'));
    expect(
        tester
            .widget<TextField>(
                find.descendant(of: passwordFinder, matching: find.byType(TextField)))
            .obscureText,
        isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(
        tester
            .widget<TextField>(
                find.descendant(of: passwordFinder, matching: find.byType(TextField)))
            .obscureText,
        isFalse);
  });

  testWidgets('LoginPage calls signInWithEmail on Login button tap',
      (WidgetTester tester) async {
    when(mockAuthService.signInWithEmail(any, any))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    await tester.enterText(
        find.byKey(const Key('emailField')), 'test@example.com');
    await tester.enterText(
        find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    verify(mockAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
  });

  testWidgets('LoginPage calls signInWithGoogle on Google button tap',
      (WidgetTester tester) async {
    when(mockAuthService.signInWithGoogle())
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    verify(mockAuthService.signInWithGoogle()).called(1);
  });

  testWidgets('LoginPage shows SnackBar on failed email login',
      (WidgetTester tester) async {
    when(mockAuthService.signInWithEmail(any, any))
        .thenThrow(Exception('Invalid credentials'));

    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
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

  testWidgets('LoginPage shows SnackBar on failed Google login',
      (WidgetTester tester) async {
    when(mockAuthService.signInWithGoogle())
        .thenThrow(Exception('Account restricted'));

    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining(
            'Google Login Failed: Exception: Account restricted'),
        findsOneWidget);
  });

  testWidgets('LoginPage shows loading indicator during request',
      (WidgetTester tester) async {
    final completer = Completer<UserCredential?>();
    when(mockAuthService.signInWithGoogle())
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
    ));

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(null);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('LoginPage navigates to SignUpPage on Sign Up tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const LoginPage(),
      authService: mockAuthService,
      observer: mockObserver,
    ));

    await tester.tap(find.text('Don\'t have an account? Sign Up'));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any)).called(2);
  });
}
