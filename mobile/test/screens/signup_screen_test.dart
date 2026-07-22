import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/screens/signup_screen.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'signup_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthService>(),
  MockSpec<UserCredential>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  group('SignUpScreen', () {
    late MockAuthService mockAuthService;
    late MockNavigatorObserver mockObserver;

    setUpAll(() {
      // Provide a dummy Route for Mockito's 'any' null-safety verification
      provideDummy<Route<dynamic>>(
          MaterialPageRoute(builder: (_) => const SizedBox()));
    });

    setUp(() {
      mockAuthService = MockAuthService();
      mockObserver = MockNavigatorObserver();
    });

    Future<void> fillFormAndSubmit(
      WidgetTester tester, {
      required String email,
      required String password,
      required String confirmPassword,
    }) async {
      await tester.enterText(find.byKey(SignUpScreen.emailFieldKey), email);
      await tester.enterText(
          find.byKey(SignUpScreen.passwordFieldKey), password);
      await tester.enterText(
          find.byKey(SignUpScreen.confirmPasswordFieldKey), confirmPassword);
      await tester.tap(find.byKey(SignUpScreen.signUpButtonKey));
      await tester.pump();
    }

    group('Initialization', () {
      testWidgets('displays fields and sign up button with initial state',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpScreen(),
          authService: mockAuthService,
        ));

        expect(find.byKey(SignUpScreen.emailFieldKey), findsOneWidget);
        expect(find.byKey(SignUpScreen.passwordFieldKey), findsOneWidget);
        expect(
            find.byKey(SignUpScreen.confirmPasswordFieldKey), findsOneWidget);
        expect(find.byKey(SignUpScreen.signUpButtonKey), findsOneWidget);

        final emailField = tester.widget<TextField>(find.descendant(
            of: find.byKey(SignUpScreen.emailFieldKey),
            matching: find.byType(TextField)));
        final passwordField = tester.widget<TextField>(find.descendant(
            of: find.byKey(SignUpScreen.passwordFieldKey),
            matching: find.byType(TextField)));
        final confirmPasswordField = tester.widget<TextField>(find.descendant(
            of: find.byKey(SignUpScreen.confirmPasswordFieldKey),
            matching: find.byType(TextField)));

        expect(emailField.controller?.text, isEmpty);
        expect(passwordField.controller?.text, isEmpty);
        expect(confirmPasswordField.controller?.text, isEmpty);
        expect(passwordField.obscureText, isTrue);
        expect(confirmPasswordField.obscureText, isTrue);
      });
    });

    group('Validation', () {
      testWidgets('shows errors on empty inputs', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpScreen(),
          authService: mockAuthService,
        ));

        await tester.tap(find.byKey(SignUpScreen.signUpButtonKey));
        await tester.pump();

        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter a password'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(
            email: anyNamed('email'), password: anyNamed('password')));
      });

      testWidgets('shows error on invalid email format',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpScreen(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'invalid-email',
          password: 'password123',
          confirmPassword: 'password123',
        );

        expect(find.text('Please enter a valid email'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(
            email: anyNamed('email'), password: anyNamed('password')));
      });

      testWidgets('shows error on short password', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpScreen(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: '12345',
          confirmPassword: '12345',
        );

        expect(find.text('Password must be at least 6 characters'),
            findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(
            email: anyNamed('email'), password: anyNamed('password')));
      });

      testWidgets('shows error if passwords do not match',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpScreen(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: 'password123',
          confirmPassword: 'different',
        );

        expect(find.text('Passwords do not match'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(
            email: anyNamed('email'), password: anyNamed('password')));
      });
    });

    group('Interactions', () {
      group('Auth', () {
        testWidgets('calls signUpWithEmail and pops navigation on valid input',
            (WidgetTester tester) async {
          final mockUserCredential = MockUserCredential();

          when(mockAuthService.signUpWithEmail(
                  email: anyNamed('email'), password: anyNamed('password')))
              .thenAnswer((_) async => mockUserCredential);

          await tester.pumpWidget(createTestableWidget(
            child: const SignUpScreen(),
            authService: mockAuthService,
            observer: mockObserver,
          ));

          await fillFormAndSubmit(
            tester,
            email: 'test@example.com',
            password: 'password123',
            confirmPassword: 'password123',
          );

          verify(mockAuthService.signUpWithEmail(
                  email: 'test@example.com', password: 'password123'))
              .called(1);
          verify(mockObserver.didPop(any, any)).called(1);
        });

        testWidgets('shows SnackBar on error', (WidgetTester tester) async {
          when(mockAuthService.signUpWithEmail(
                  email: anyNamed('email'), password: anyNamed('password')))
              .thenThrow(Exception('Network timeout'));

          await tester.pumpWidget(createTestableWidget(
            child: const SignUpScreen(),
            authService: mockAuthService,
          ));

          await fillFormAndSubmit(
            tester,
            email: 'test@example.com',
            password: 'password123',
            confirmPassword: 'password123',
          );

          expect(
              find.textContaining('Sign Up Failed: Exception: Network timeout'),
              findsOneWidget);
        });

        testWidgets('shows loading indicator during request',
            (WidgetTester tester) async {
          final completer = Completer<UserCredential?>();

          when(mockAuthService.signUpWithEmail(
                  email: anyNamed('email'), password: anyNamed('password')))
              .thenAnswer((_) => completer.future);

          await tester.pumpWidget(createTestableWidget(
            child: const SignUpScreen(),
            authService: mockAuthService,
          ));

          await fillFormAndSubmit(
            tester,
            email: 'test@example.com',
            password: 'password123',
            confirmPassword: 'password123',
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          completer.complete(MockUserCredential());
          await tester.pump();

          expect(find.byType(CircularProgressIndicator), findsNothing);
        });
      });
    });

    group('Navigation', () {
      testWidgets('navigates back on back button tap',
          (WidgetTester tester) async {
        // Push SignUpScreen onto a parent route so that a back button appears
        await tester.pumpWidget(createTestableWidget(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('Push'),
              ),
            ),
          ),
          authService: mockAuthService,
          observer: mockObserver,
        ));

        await tester.tap(find.text('Push'));
        await tester.pumpAndSettle();

        // Tap the back button in the AppBar
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verify the screen was popped
        verify(mockObserver.didPop(any, any)).called(1);
        expect(find.byType(SignUpScreen), findsNothing);
      });
    });
  });
}
