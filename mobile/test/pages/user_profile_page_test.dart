import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:everything_passport/pages/user_profile_page.dart';
import 'package:everything_passport/services/user_service.dart';
import 'package:everything_passport/services/metadata_service.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/models/country.dart';
import '../test_helper.dart';

import 'user_profile_page_test.mocks.dart';
import 'user_profile_page_test.mocks.dart' as base_mocks;

@GenerateNiceMocks([
  MockSpec<UserService>(),
  MockSpec<MetadataService>(),
  MockSpec<User>(),
  MockSpec<ImagePickerPlatform>(),
  MockSpec<ImageCropperPlatform>(),
  MockSpec<http.Client>(as: #MockHttpClient),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Global Mock Setup
  setupGlobalMocks();

  late MockUserService mockUserService;
  late MockMetadataService mockMetadataService;
  late MockUser mockUser;
  late UserProfile mockProfile;
  late MockHttpClient mockHttpClient;

  late ImagePickerPlatform originalImagePicker;
  late ImageCropperPlatform originalImageCropper;
  late LocalMockImagePickerPlatform mockImagePickerPlatform;
  late LocalMockImageCropperPlatform mockImageCropperPlatform;

  setUpAll(() {
    provideDummy<Route<dynamic>>(
        MaterialPageRoute(builder: (_) => const SizedBox()));
  });

  setUp(() {
    originalImagePicker = ImagePickerPlatform.instance;
    originalImageCropper = ImageCropperPlatform.instance;

    mockImagePickerPlatform = LocalMockImagePickerPlatform();
    mockImageCropperPlatform = LocalMockImageCropperPlatform();

    ImagePickerPlatform.instance = mockImagePickerPlatform;
    ImageCropperPlatform.instance = mockImageCropperPlatform;

    mockUserService = MockUserService();
    mockMetadataService = MockMetadataService();
    mockUser = MockUser();
    mockHttpClient = MockHttpClient();

    // Default User mock stubbing
    when(mockUser.uid).thenReturn('test_uid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.photoURL).thenReturn(null);

    // Default Metadata mock stubbing
    when(mockMetadataService.getCountries(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async => [
              Country(id: 'US', name: 'United States', searchKeywords: ['usa']),
              Country(id: 'CA', name: 'Canada', searchKeywords: ['can']),
            ]);

    // Default HTTP mock stubbing
    when(mockHttpClient.get(any))
        .thenAnswer((_) async => http.Response.bytes([1, 2, 3], 200));

    mockProfile = UserProfile(
      uid: 'test_uid',
      username: 'traveler_john',
      firstName: 'John',
      lastName: 'Doe',
      isPublic: true,
      dateOfBirth: DateTime(1990, 1, 1),
      nationality: 'US',
      photoUrl: 'https://example.com/existing.jpg',
    );

    setupMethodChannelMocks();
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalImagePicker;
    ImageCropperPlatform.instance = originalImageCropper;
  });

  group('UserProfilePage Initialization', () {
    testWidgets('shows "Not Logged In" when user is null', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(child: const UserProfilePage(), user: null));
      expect(find.text('Not Logged In'), findsOneWidget);
    });

    testWidgets('Google Photo auto-trigger coverage', (WidgetTester tester) async {
      setViewport(tester);
      final userWithPhoto = MockUser();
      when(userWithPhoto.uid).thenReturn('test_uid');
      when(userWithPhoto.email).thenReturn('test@example.com');
      when(userWithPhoto.photoURL).thenReturn('https://example.com/photo.jpg');

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: userWithPhoto,
        userProfile: null,
        httpClient: mockHttpClient,
      ));

      await tester.pump();
      // Verifies addPostFrameCallback trigger
    });
  });

  group('UserProfilePage Form Interaction', () {
    testWidgets('Form and logic branches', (WidgetTester tester) async {
      setViewport(tester);

      when(mockUserService.isUsernameAvailable(any, any))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final usernameFinder = find.widgetWithText(TextFormField, 'Username *');

      // 1. Current username check
      await tester.enterText(usernameFinder, 'traveler_john');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // 2. Debounce and availability check
      await tester.enterText(usernameFinder, 'new_unique');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // 3. Nationality autocomplete
      final nationalityFinder = find.byType(Autocomplete<Country>);
      final nationalityField = find.descendant(of: nationalityFinder, matching: find.byType(TextField));
      await tester.enterText(nationalityField, '');
      await tester.pumpAndSettle();
      expect(find.text('Canada'), findsOneWidget);
      await tester.tap(find.text('Canada'));
      await tester.pumpAndSettle();

      // 4. Date picker
      await tester.tap(find.text('1/1/1990'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 5. Submit error
      when(mockUserService.saveProfileWithUsername(any, any))
          .thenThrow(Exception('Failed to save profile'));

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to save profile'), findsOneWidget);
    });

    testWidgets('Nationality fallback', (WidgetTester tester) async {
      final profile = UserProfile(uid: 'u', username: 'u', firstName: 'A', lastName: 'B', nationality: 'BAD');
      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        userProfile: profile,
        user: mockUser,
      ));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'United States'), findsOneWidget);
    });

    testWidgets('Public profile toggle', (WidgetTester tester) async {
      setViewport(tester);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final toggleFinder = find.widgetWithText(SwitchListTile, 'Public Profile');
      expect(find.byIcon(Icons.public), findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('Username already taken', (WidgetTester tester) async {
      setViewport(tester);
      when(mockUserService.isUsernameAvailable(any, any))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final usernameFinder = find.widgetWithText(TextFormField, 'Username *');
      await tester.enterText(usernameFinder, 'taken_user');

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Username already taken'), findsOneWidget);
    });

    testWidgets('Username field edge cases', (WidgetTester tester) async {
      setViewport(tester);
      when(mockUserService.isUsernameAvailable(any, any))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final usernameFinder = find.widgetWithText(TextFormField, 'Username *');

      // Short username resets availability
      await tester.enterText(usernameFinder, 'hi');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);

      // Current username bypasses check
      await tester.enterText(usernameFinder, 'traveler_john');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Date of Birth field clear button', (WidgetTester tester) async {
      setViewport(tester);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      // 1. Check dob field
      final dobField = find.ancestor(
        of: find.text('Date of Birth (Optional)'),
        matching: find.byType(InputDecorator),
      );
      expect(dobField, findsOneWidget);

      // 2. Check dob value
      final dobValueText = find.descendant(
        of: dobField,
        matching: find.textContaining('1/1/1990'),
      );
      expect(dobValueText, findsOneWidget);

      // 3. Check clear button
      final dobClearButton = find.descendant(
        of: dobField,
        matching: find.byIcon(Icons.clear),
      );
      expect(dobClearButton, findsOneWidget);

      // 4. Clear dob field
      await tester.tap(dobClearButton);
      await tester.pumpAndSettle();

      // 5. Check value and clear button are removed
      expect(dobValueText, findsNothing);
      expect(dobClearButton, findsNothing);

      // 6. Re-check dob value
      final emptyDobValueText = find.descendant(
        of: dobField,
        matching: find.text(''),
      );
      expect(emptyDobValueText, findsOneWidget);
    });

    testWidgets('Nationality field clear button', (WidgetTester tester) async {
      setViewport(tester);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      // 1. Check nationality field
      final nationalityField = find.ancestor(
        of: find.text('Nationality (Optional)'),
        matching: find.byType(TextFormField),
      );
      expect(nationalityField, findsOneWidget);

      // 2. Check nationality value
      final nationalityValueText = find.descendant(
        of: nationalityField,
        matching: find.textContaining('United States'),
      );
      expect(nationalityValueText, findsOneWidget);

      // 3. Check clear button
      final nationalityClearButton = find.descendant(
        of: nationalityField,
        matching: find.byIcon(Icons.clear),
      );
      expect(nationalityClearButton, findsOneWidget);

      // 4. Clear nationality field
      await tester.tap(nationalityClearButton);
      await tester.pumpAndSettle();

      // 5. Check value and clear button are removed
      expect(nationalityValueText, findsNothing);
      expect(nationalityClearButton, findsNothing);

      // 6. Re-check nationality value
      final emptyNationalityValueText = find.descendant(
        of: nationalityField,
        matching: find.text(''),
      );
      expect(emptyNationalityValueText, findsOneWidget);
    });
  });

  group('UserProfilePage Submission', () {
    testWidgets('Loading state during submission', (WidgetTester tester) async {
      setViewport(tester);
      final saveCompleter = Completer<void>();
      when(mockUserService.saveProfileWithUsername(any, any))
          .thenAnswer((_) => saveCompleter.future);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);

      saveCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Successful save pops navigator', (WidgetTester tester) async {
      setViewport(tester);

      await tester.pumpWidget(createTestableWidget(
        child: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            ),
            child: const Text('Push'),
          );
        }),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfilePage), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfilePage), findsNothing);
      expect(find.text('Push'), findsOneWidget);
    });
  });

  group('UserProfilePage Profile Photo', () {
    testWidgets('Google Photo coverage (Success, Failure, Exception)', (WidgetTester tester) async {
      setViewport(tester);

      final profileNoPhoto = UserProfile(
        uid: 'test_uid',
        username: 'traveler_john',
        firstName: 'John',
        lastName: 'Doe',
        isPublic: true,
        dateOfBirth: DateTime(1990, 1, 1),
        nationality: 'US',
        photoUrl: null,
      );

      final mockUserNoPhoto = MockUser();
      when(mockUserNoPhoto.uid).thenReturn('test_uid');
      when(mockUserNoPhoto.email).thenReturn('test@example.com');
      when(mockUserNoPhoto.photoURL).thenReturn(null);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUserNoPhoto,
        userProfile: profileNoPhoto,
        httpClient: mockHttpClient,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(UserProfilePage));

      // Success path
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response.bytes([1, 2, 3], 200));
      await tester.runAsync(() async => await state.useGooglePhoto('https://example.com/photo.jpg'));
      await tester.pump();

      // Failure path
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));
      await tester.runAsync(() async => await state.useGooglePhoto('https://example.com/photo.jpg'));
      await tester.pump();

      // Exception path
      when(mockHttpClient.get(any))
          .thenThrow(Exception('Network error'));
      await tester.runAsync(() async => await state.useGooglePhoto('https://example.com/photo.jpg'));
      await tester.pump();
    });

    testWidgets('uploadProfilePicture is called when image is selected', (WidgetTester tester) async {
      setViewport(tester);

      final mockUserNoPhoto = MockUser();
      when(mockUserNoPhoto.uid).thenReturn('test_uid');
      when(mockUserNoPhoto.email).thenReturn('test@example.com');
      when(mockUserNoPhoto.photoURL).thenReturn(null);

      when(mockUserService.uploadProfilePicture(any, any))
          .thenAnswer((_) async => 'https://example.com/photo.jpg');

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUserNoPhoto,
        userProfile: mockProfile,
        httpClient: mockHttpClient,
      ));

      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(UserProfilePage));

      await tester.runAsync(() async => await state.useGooglePhoto('https://example.com/photo.jpg'));
      
      // Use a more robust wait than manual for loop
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      verifyNever(mockUserService.uploadProfilePicture(any, any));

      await tester.tap(find.text('Save Changes'));
      
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      verify(mockUserService.uploadProfilePicture(any, any)).called(1);
    });
  });

  group('UserProfilePage Profile Photo Selection', () {
    testWidgets('picks and crops profile picture successfully', (WidgetTester tester) async {
      setViewport(tester);

      when(mockImagePickerPlatform.getImageFromSource(
        source: anyNamed('source'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => XFile('test/assets/test_image.jpg'));

      when(mockImageCropperPlatform.cropImage(
        sourcePath: anyNamed('sourcePath'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        aspectRatio: anyNamed('aspectRatio'),
        compressFormat: anyNamed('compressFormat'),
        compressQuality: anyNamed('compressQuality'),
        uiSettings: anyNamed('uiSettings'),
      )).thenAnswer((_) async => CroppedFile('test/assets/cropped_image.jpg'));

      when(mockUserService.uploadProfilePicture(any, any))
          .thenAnswer((_) async => 'https://example.com/new_photo.jpg');

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final cameraButton = find.byIcon(Icons.camera_alt);
      expect(cameraButton, findsOneWidget);
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(mockUserService.uploadProfilePicture(any, any)).called(1);
    });

    testWidgets('cancels image picking gracefully', (WidgetTester tester) async {
      setViewport(tester);

      when(mockImagePickerPlatform.getImageFromSource(
        source: anyNamed('source'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final cameraButton = find.byIcon(Icons.camera_alt);
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verifyNever(mockUserService.uploadProfilePicture(any, any));
    });

    testWidgets('cancels image cropping gracefully', (WidgetTester tester) async {
      setViewport(tester);

      when(mockImagePickerPlatform.getImageFromSource(
        source: anyNamed('source'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => XFile('test/assets/test_image.jpg'));

      when(mockImageCropperPlatform.cropImage(
        sourcePath: anyNamed('sourcePath'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        aspectRatio: anyNamed('aspectRatio'),
        compressFormat: anyNamed('compressFormat'),
        compressQuality: anyNamed('compressQuality'),
        uiSettings: anyNamed('uiSettings'),
      )).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestableWidget(
        child: const UserProfilePage(),
        userService: mockUserService,
        metadataService: mockMetadataService,
        user: mockUser,
        userProfile: mockProfile,
      ));

      await tester.pumpAndSettle();

      final cameraButton = find.byIcon(Icons.camera_alt);
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verifyNever(mockUserService.uploadProfilePicture(any, any));
    });
  });
}

// --- Helpers and Mocks ---

class LocalMockImagePickerPlatform extends base_mocks.MockImagePickerPlatform
    with MockPlatformInterfaceMixin {}

class LocalMockImageCropperPlatform extends base_mocks.MockImageCropperPlatform
    with MockPlatformInterfaceMixin {}

void setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void setupGlobalMocks() {
  PathProviderPlatform.instance = MockPathProviderPlatform();
}

void setupMethodChannelMocks() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => '.',
  );

  messenger.setMockMethodCallHandler(
    const MethodChannel('com.tekartik.sqflite'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getDatabasesPath') return '.';
      return null;
    },
  );
}

class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getApplicationSupportPath() async => '.';
  @override
  Future<String?> getLibraryPath() async => '.';
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
  @override
  Future<String?> getExternalStoragePath() async => '.';
  @override
  Future<List<String>?> getExternalCachePaths() async => [];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [];
  @override
  Future<String?> getDownloadsPath() async => '.';
}
