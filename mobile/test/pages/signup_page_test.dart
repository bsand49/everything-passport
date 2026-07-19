import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/pages/signup_page.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'signup_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthService>(),
  MockSpec<UserCredential>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  late MockAuthService mockAuthService;

  setUpAll(() {
    // Provide a dummy Route for Mockito's 'any' null-safety verification
    provideDummy<Route<dynamic>>(MaterialPageRoute(builder: (_) => const SizedBox()));
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Future<void> fillFormAndSubmit(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await tester.enterText(find.byKey(SignUpPage.emailFieldKey), email);
    await tester.enterText(find.byKey(SignUpPage.passwordFieldKey), password);
    await tester.enterText(find.byKey(SignUpPage.confirmPasswordFieldKey), confirmPassword);
    await tester.tap(find.byKey(SignUpPage.signUpButtonKey));
    await tester.pump();
  }

  group('SignUpPage Widget Tests', () {
    testWidgets('displays fields and sign up button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        child: const SignUpPage(),
        authService: mockAuthService,
      ));

      expect(find.byKey(SignUpPage.emailFieldKey), findsOneWidget);
      expect(find.byKey(SignUpPage.passwordFieldKey), findsOneWidget);
      expect(find.byKey(SignUpPage.confirmPasswordFieldKey), findsOneWidget);
      expect(find.byKey(SignUpPage.signUpButtonKey), findsOneWidget);
    });

    group('Form Validation Tests', () {
      testWidgets('shows errors on empty inputs', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        await tester.tap(find.byKey(SignUpPage.signUpButtonKey));
        await tester.pump();

        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter a password'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(any, any));
      });

      testWidgets('shows error on invalid email format', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'invalid-email',
          password: 'password123',
          confirmPassword: 'password123',
        );

        expect(find.text('Please enter a valid email'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(any, any));
      });

      testWidgets('shows error on short password', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: '12345',
          confirmPassword: '12345',
        );

        expect(find.text('Password must be at least 6 characters'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(any, any));
      });

      testWidgets('shows error if passwords do not match', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: 'password123',
          confirmPassword: 'different',
        );

        expect(find.text('Passwords do not match'), findsOneWidget);
        verifyNever(mockAuthService.signUpWithEmail(any, any));
      });
    });

    group('Auth Action Tests', () {
      testWidgets('calls signUpWithEmail and pops navigation on valid input', (WidgetTester tester) async {
        final mockObserver = MockNavigatorObserver();
        final mockUserCredential = MockUserCredential();

        when(mockAuthService.signUpWithEmail(any, any))
            .thenAnswer((_) async => mockUserCredential);

        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
          observer: mockObserver,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        );

        verify(mockAuthService.signUpWithEmail('test@example.com', 'password123')).called(1);
        verify(mockObserver.didPop(any, any)).called(1);
      });

      testWidgets('shows SnackBar on error', (WidgetTester tester) async {
        when(mockAuthService.signUpWithEmail(any, any))
            .thenThrow(Exception('Network timeout'));

        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        await fillFormAndSubmit(
          tester,
          email: 'test@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        );

        expect(find.textContaining('Sign Up Failed: Exception: Network timeout'), findsOneWidget);
      });

      testWidgets('shows loading indicator during request', (WidgetTester tester) async {
        final completer = Completer<UserCredential?>();

        when(mockAuthService.signUpWithEmail(any, any))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
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

    group('Interactive UI State Tests', () {
      testWidgets('toggles password visibility on suffix icon tap', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        // Find the internal TextField and check obscureText is true initially
        final passwordTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(SignUpPage.passwordFieldKey),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordTextField.obscureText, isTrue);

        // Tap suffix icon on Password field
        final suffixIconFinder = find.descendant(
          of: find.byKey(SignUpPage.passwordFieldKey),
          matching: find.byType(IconButton),
        );
        await tester.tap(suffixIconFinder);
        await tester.pump();

        // Verify state is toggled
        final toggledTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(SignUpPage.passwordFieldKey),
            matching: find.byType(TextField),
          ),
        );
        expect(toggledTextField.obscureText, isFalse);
      });

      testWidgets('toggles confirm password visibility on suffix icon tap', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const SignUpPage(),
          authService: mockAuthService,
        ));

        // Find the internal TextField and check obscureText is true initially
        final confirmPasswordTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(SignUpPage.confirmPasswordFieldKey),
            matching: find.byType(TextField),
          ),
        );
        expect(confirmPasswordTextField.obscureText, isTrue);

        // Tap suffix icon on Confirm Password field
        final suffixIconFinder = find.descendant(
          of: find.byKey(SignUpPage.confirmPasswordFieldKey),
          matching: find.byType(IconButton),
        );
        await tester.tap(suffixIconFinder);
        await tester.pump();

        // Verify state is toggled
        final toggledTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(SignUpPage.confirmPasswordFieldKey),
            matching: find.byType(TextField),
          ),
        );
        expect(toggledTextField.obscureText, isFalse);
      });
    });
  });
}
