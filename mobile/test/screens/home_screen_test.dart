import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:everything_passport/screens/home_screen.dart';
import 'package:everything_passport/screens/settings_screen.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/services/auth_service.dart';
import 'package:everything_passport/services/user_profile_service.dart';
import 'package:everything_passport/services/metadata_service.dart';
import 'package:everything_passport/widgets/profile_avatar.dart';
import '../test_helper.dart';

import 'home_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NavigatorObserver>(),
  MockSpec<User>(),
  MockSpec<AuthService>(),
  MockSpec<UserProfileService>(),
  MockSpec<MetadataService>(),
])
void main() {
  group('HomeScreen', () {
    late MockUser mockUser;
    late MockNavigatorObserver mockObserver;
    late UserProfile mockProfile;

    setUpAll(() {
      // Provide a dummy Route for Mockito's 'any' / 'captureAny' null-safety verification
      provideDummy<Route<dynamic>>(
          MaterialPageRoute(builder: (_) => const SizedBox()));
      HttpOverrides.global = MockHttpOverrides();
    });

    setUp(() {
      mockUser = MockUser();
      mockObserver = MockNavigatorObserver();
      mockProfile = UserProfile(
        userId: 'test_user',
        username: 'traveler_john',
        firstName: 'John',
        lastName: 'Doe',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // Stub mock user properties required by HomeScreen
      when(mockUser.uid).thenReturn('test_user');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
    });

    // Helper to ensure uniform testing dimensions for modals and sheets
    void setLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
    }

    group('Initialization', () {
      testWidgets('displays "Not Logged In" when user is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: null,
        ));

        expect(find.text('Not Logged In'), findsOneWidget);
      });

      testWidgets('displays loader when userProfile is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: mockUser,
          userProfile: null,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays username and welcome message with correct name',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: mockUser,
          userProfile: mockProfile,
        ));

        expect(find.text('traveler_john'), findsOneWidget);
        expect(
            find.text('Welcome to Everything Passport, John!'), findsOneWidget);
      });

      testWidgets('displays ProfileAvatar with correct photoUrl',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const HomeScreen(),
          user: mockUser,
          userProfile: mockProfile,
        ));

        final profileAvatarFinder = find.byType(ProfileAvatar);
        expect(profileAvatarFinder, findsOneWidget);

        final ProfileAvatar avatar = tester.widget(profileAvatarFinder);
        expect(avatar.photoUrl, mockProfile.photoUrl);
        expect(avatar.radius, 60);
      });
    });

    group('Interactions', () {
      testWidgets('opens bottom sheet and handles Add Trip tap',
          (WidgetTester tester) async {
        setLargeViewport(tester);

        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: mockUser,
          userProfile: mockProfile,
        ));

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.text('Add New'), findsOneWidget);

        await tester.tap(find.text('Add Trip'));
        await tester.pumpAndSettle();

        expect(find.text('Add New'), findsNothing); // Verify sheet popped
      });

      testWidgets('opens bottom sheet and handles Add Event tap',
          (WidgetTester tester) async {
        setLargeViewport(tester);

        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: mockUser,
          userProfile: mockProfile,
        ));

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Event'));
        await tester.pumpAndSettle();

        expect(find.text('Add New'), findsNothing); // Verify sheet popped
      });
    });

    group('Navigation', () {
      testWidgets(
          'navigates to SettingsScreen on settings button tap (isolated route test)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: HomeScreen(),
          user: mockUser,
          userProfile: mockProfile,
          observer: mockObserver,
        ));

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Capture and verify navigation occurred using Mockito's captureAny and called(2)
        final verification = verify(mockObserver.didPush(captureAny, any))
          ..called(2);
        final Route<dynamic> route = verification.captured[1] as Route<dynamic>;
        expect(route, isA<MaterialPageRoute>());

        final BuildContext context = tester.element(find.byType(Navigator));
        final widget = (route as MaterialPageRoute).builder(context);
        expect(widget, isA<SettingsScreen>());
      });
    });
  });
}

// --- Http overrides mock for network image providers in testing environment ---

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.value(MockHttpClientRequest());
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.value(MockHttpClientRequest());
  @override
  set autoUncompress(bool value) {}
  @override
  void close({bool force = false}) {}
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();
  @override
  set followRedirects(bool value) {}
  @override
  set maxRedirects(int value) {}
  @override
  set persistentConnection(bool value) {}
  @override
  set contentLength(int value) {}
  @override
  Future<HttpClientResponse> get done => close();
  @override
  Future<HttpClientResponse> close() => Future.value(MockHttpClientResponse());
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  void write(Object? obj) {}
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  String get reasonPhrase => 'OK';
  @override
  int get contentLength => 3;
  @override
  HttpHeaders get headers => MockHttpHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  List<Cookie> get cookies => [];
  @override
  List<RedirectInfo> get redirects => [];
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final stream = Stream<List<int>>.fromIterable([
      [1, 2, 3]
    ]);
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _headers = {};
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  List<String>? operator [](String name) => _headers[name];
  @override
  void forEach(void Function(String name, List<String> values) f) {
    _headers.forEach(f);
  }

  @override
  set contentType(ContentType? value) {}
}
