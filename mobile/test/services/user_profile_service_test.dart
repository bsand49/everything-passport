import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/services/user_profile_service.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everything_passport/exceptions/username_already_taken_exception.dart';
import 'user_profile_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseFirestore>(as: #MockFirestore),
  MockSpec<FirebaseStorage>(as: #MockStorage),
  MockSpec<Reference>(as: #MockStorageReference),
  MockSpec<UploadTask>(as: #MockUploadTaskMockito),
  MockSpec<TaskSnapshot>(as: #MockTaskSnapshotMockito),
])
void main() {
  group('UserProfileService Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late MockFirebaseStorage mockStorage;
    late UserProfileService userProfileService;
    late Directory tempDir;
    late File tempFile;

    const String usersProfilesCollection = 'userProfiles';
    const String usernamesCollection = 'usernames';

    setUp(() async {
      mockFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      userProfileService =
          UserProfileService(db: mockFirestore, storage: mockStorage);

      // Secure directory isolated to each individual test run
      tempDir =
          await Directory.systemTemp.createTemp('user_profile_service_test_');
      tempFile = File('${tempDir.path}/test_image.jpg');
      await tempFile.create(recursive: true);
    });

    tearDown(() async {
      // Clean up local system directory/files after testing
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Constructor', () {
      test(
          'UserProfileService constructor hits Firestore fallback when db is null',
          () {
        expect(
          () => UserProfileService(storage: mockStorage),
          throwsA(anyOf(
            isA<StateError>(),
            isA<FirebaseException>(),
          )),
        );
      });

      test(
          'UserProfileService constructor hits Storage fallback when storage is null',
          () {
        expect(
          () => UserProfileService(db: mockFirestore),
          throwsA(anyOf(
            isA<StateError>(),
            isA<FirebaseException>(),
          )),
        );
      });
    });

    group('streamProfile', () {
      test('emits UserProfile when document exists', () async {
        final userId = 'user_123';
        await mockFirestore
            .collection(usersProfilesCollection)
            .doc(userId)
            .set({
          'username': 'hero',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'isPublic': true,
        });

        final profile =
            await userProfileService.streamProfile(userId: userId).first;
        expect(
          profile,
          isA<UserProfile>()
              .having((p) => p.username, 'username', 'hero')
              .having((p) => p.isPublic, 'isPublic', isTrue),
        );
      });

      test('emits null when document does not exist', () async {
        final profile = await userProfileService
            .streamProfile(userId: 'non_existent')
            .first;
        expect(profile, isNull);
      });

      test('emits null on error during mapping', () async {
        final userId = 'user_123';
        await mockFirestore
            .collection(usersProfilesCollection)
            .doc(userId)
            .set({
          'username': 123, // Malformed type throws in UserProfile.fromMap
        });

        final profile =
            await userProfileService.streamProfile(userId: userId).first;
        expect(profile, isNull);
      });

      test('emits updated UserProfile when document is updated', () async {
        final userId = 'user_123';
        final userDocRef =
            mockFirestore.collection(usersProfilesCollection).doc(userId);

        await userDocRef.set({
          'username': 'hero',
          'firstName': 'John',
          'lastName': 'Doe',
        });

        final stream = userProfileService.streamProfile(userId: userId);

        expectLater(
          stream,
          emitsInOrder([
            isA<UserProfile>().having((p) => p.username, 'username', 'hero'),
            isA<UserProfile>()
                .having((p) => p.username, 'username', 'super_hero'),
            isNull,
          ]),
        );

        await Future.delayed(Duration.zero);
        await userDocRef.update({'username': 'super_hero'});

        await Future.delayed(Duration.zero);
        await userDocRef.delete();
      });
    });

    group('saveProfile', () {
      test('creates both documents for a new user and normalizes casing',
          () async {
        final profile = UserProfile(
          userId: 'user_123',
          username: 'New_HeRo',
          firstName: 'John',
          lastName: 'Doe',
        );

        await userProfileService.saveProfile(profile: profile, oldUsername: '');

        final userDoc = await mockFirestore
            .collection(usersProfilesCollection)
            .doc('user_123')
            .get();
        expect(userDoc.data()?['username'], 'new_hero');

        final usernameDoc = await mockFirestore
            .collection(usernamesCollection)
            .doc('new_hero')
            .get();
        expect(usernameDoc.data()?['userId'], 'user_123');
      });

      test('handles username change and deletes old mapping', () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('old_name')
            .set({'userId': 'user_123'});

        final profile = UserProfile(
          userId: 'user_123',
          username: 'new_name',
          firstName: 'John',
          lastName: 'Doe',
        );

        await userProfileService.saveProfile(
            profile: profile, oldUsername: 'old_name');

        expect(
            (await mockFirestore
                    .collection(usernamesCollection)
                    .doc('old_name')
                    .get())
                .exists,
            isFalse);
        expect(
            (await mockFirestore
                    .collection(usernamesCollection)
                    .doc('new_name')
                    .get())
                .data()?['userId'],
            'user_123');
      });

      test('does not update mapping if username is unchanged', () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('same')
            .set({'userId': 'user_123'});

        final profile = UserProfile(
          userId: 'user_123',
          username: 'same',
          firstName: 'Updated',
          lastName: 'Doe',
        );

        await userProfileService.saveProfile(
            profile: profile, oldUsername: 'same');

        final usernameDoc = await mockFirestore
            .collection(usernamesCollection)
            .doc('same')
            .get();
        expect(usernameDoc.exists, isTrue);
        expect(usernameDoc.data()?['userId'], 'user_123');

        final userDoc = await mockFirestore
            .collection(usersProfilesCollection)
            .doc('user_123')
            .get();
        expect(userDoc.data()?['firstName'], 'Updated');
      });

      test(
          'throws Exception if username taken by someone else during transaction',
          () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('stolen')
            .set({'userId': 'villain'});

        final profile = UserProfile(
          userId: 'user_123',
          username: 'stolen',
          firstName: 'Hero',
          lastName: 'Doe',
        );

        expect(
          () =>
              userProfileService.saveProfile(profile: profile, oldUsername: ''),
          throwsA(isA<UsernameAlreadyTakenException>().having(
              (e) => e.toString(),
              'description',
              contains('is already taken'))),
        );
      });

      test('throws generic exception', () async {
        final mockFailingFirestore = MockFirestore();
        when(mockFailingFirestore.collection(any)).thenAnswer((invocation) {
          final path = invocation.positionalArguments[0] as String;
          return mockFirestore.collection(path);
        });
        when(mockFailingFirestore.runTransaction<void>(any,
                timeout: anyNamed('timeout'),
                maxAttempts: anyNamed('maxAttempts')))
            .thenThrow(Exception('Transaction failed'));

        final failingService =
            UserProfileService(db: mockFailingFirestore, storage: mockStorage);

        final profile = UserProfile(
          userId: 'user_123',
          username: 'new_name',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(
          () => failingService.saveProfile(
              profile: profile, oldUsername: 'old_name'),
          throwsException,
        );
      });
    });

    group('isUsernameAvailable', () {
      test('returns true for non-existent username', () async {
        final available = await userProfileService.isUsernameAvailable(
            username: 'new_user', currentUserId: 'user_123');
        expect(available, isTrue);
      });

      test('returns false for username taken by another user', () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('taken')
            .set({'userId': 'other_user'});
        final available = await userProfileService.isUsernameAvailable(
            username: 'taken', currentUserId: 'user_123');
        expect(available, isFalse);
      });

      test('returns false when checking availability with mixed case',
          () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('taken')
            .set({'userId': 'other_user'});
        final available = await userProfileService.isUsernameAvailable(
            username: 'TaKeN', currentUserId: 'user_123');
        expect(available, isFalse);
      });

      test('returns true if username belongs to current user', () async {
        await mockFirestore
            .collection(usernamesCollection)
            .doc('myname')
            .set({'userId': 'user_123'});
        final available = await userProfileService.isUsernameAvailable(
            username: 'myname', currentUserId: 'user_123');
        expect(available, isTrue);
      });

      test('returns false on error', () async {
        final mockFailingFirestore = MockFirestore();
        when(mockFailingFirestore.collection(any))
            .thenThrow(Exception('Firestore Error'));

        final failingService =
            UserProfileService(db: mockFailingFirestore, storage: mockStorage);
        final available = await failingService.isUsernameAvailable(
            username: 'new_user', currentUserId: 'user_123');
        expect(available, isFalse);
      });
    });

    group('uploadProfilePicture', () {
      test('uploads file and returns download URL', () async {
        final url = await userProfileService.uploadProfilePicture(
            userId: 'user_123', image: tempFile);

        expect(url, isNotEmpty);
        expect(url, contains('user_123'));
      });

      test('throws exception on failed upload', () async {
        final mockStorage = MockStorage();
        final mockRef = MockStorageReference();
        final mockUploadTask = MockUploadTaskMockito();

        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any, any)).thenAnswer((_) => mockUploadTask);

        // Make the UploadTask act like a Future that completes with an error
        when(mockUploadTask.then(any, onError: anyNamed('onError')))
            .thenAnswer((invocation) {
          final onValue = invocation.positionalArguments[0] as Function;
          final onError = invocation.namedArguments[#onError] as Function?;
          return Future<TaskSnapshot>.error(Exception('Upload failed')).then(
            (snapshot) => onValue(snapshot),
            onError: onError,
          );
        });

        final failingService =
            UserProfileService(db: mockFirestore, storage: mockStorage);

        await expectLater(
          failingService.uploadProfilePicture(
              userId: 'user_123', image: tempFile),
          throwsException,
        );
      });

      test(
          'throws exception when upload task completes with a non-success state',
          () async {
        final mockStorage = MockStorage();
        final mockRef = MockStorageReference();
        final mockUploadTask = MockUploadTaskMockito();
        final mockSnapshot = MockTaskSnapshotMockito();

        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any, any)).thenAnswer((_) => mockUploadTask);

        when(mockSnapshot.state).thenReturn(TaskState.error);

        // Make the UploadTask act like a Future that completes with the error snapshot
        when(mockUploadTask.then(any, onError: anyNamed('onError')))
            .thenAnswer((invocation) {
          final onValue = invocation.positionalArguments[0] as Function;
          final onError = invocation.namedArguments[#onError] as Function?;
          return Future<TaskSnapshot>.value(mockSnapshot).then(
            (snapshot) => onValue(snapshot),
            onError: onError,
          );
        });

        final stateFailingService =
            UserProfileService(db: mockFirestore, storage: mockStorage);

        await expectLater(
          stateFailingService.uploadProfilePicture(
              userId: 'user_123', image: tempFile),
          throwsA(isA<Exception>().having((e) => e.toString(), 'description',
              contains('Upload failed with state'))),
        );
      });
    });
  });
}
