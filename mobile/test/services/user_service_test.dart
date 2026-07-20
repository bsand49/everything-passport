import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/services/user_service.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseFirestore>(as: #MockFirestore),
  MockSpec<FirebaseStorage>(as: #MockStorage),
  MockSpec<Reference>(as: #MockStorageReference),
  MockSpec<UploadTask>(as: #MockUploadTaskMockito),
  MockSpec<TaskSnapshot>(as: #MockTaskSnapshotMockito),
])
void main() {
  group('UserService Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late MockFirebaseStorage mockStorage;
    late UserService userService;
    late Directory tempDir;
    late File tempFile;

    setUp(() async {
      mockFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      userService = UserService(db: mockFirestore, storage: mockStorage);

      // Secure directory isolated to each individual test run
      tempDir = await Directory.systemTemp.createTemp('user_service_test_');
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
      test('UserService constructor hits Firestore fallback when db is null',
          () {
        expect(
          () => UserService(storage: mockStorage),
          throwsA(anyOf(
            isA<StateError>(),
            isA<FirebaseException>(),
          )),
        );
      });

      test('UserService constructor hits Storage fallback when storage is null',
          () {
        expect(
          () => UserService(db: mockFirestore),
          throwsA(anyOf(
            isA<StateError>(),
            isA<FirebaseException>(),
          )),
        );
      });
    });

    group('streamProfile', () {
      test('emits UserProfile when document exists', () async {
        final uid = 'uid_123';
        await mockFirestore.collection('users').doc(uid).set({
          'username': 'hero',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'isPublic': true,
        });

        final profile = await userService.streamProfile(uid).first;
        expect(
          profile,
          isA<UserProfile>()
              .having((p) => p.username, 'username', 'hero')
              .having((p) => p.isPublic, 'isPublic', isTrue),
        );
      });

      test('emits null when document does not exist', () async {
        final profile = await userService.streamProfile('non_existent').first;
        expect(profile, isNull);
      });

      test('emits null on error during mapping', () async {
        final uid = 'uid_123';
        await mockFirestore.collection('users').doc(uid).set({
          'username': 123, // Malformed type throws in UserProfile.fromMap
        });

        final profile = await userService.streamProfile(uid).first;
        expect(profile, isNull);
      });

      test('emits updated UserProfile when document is updated', () async {
        final uid = 'uid_123';
        final userDocRef = mockFirestore.collection('users').doc(uid);

        await userDocRef.set({
          'username': 'hero',
          'firstName': 'John',
          'lastName': 'Doe',
        });

        final stream = userService.streamProfile(uid);

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

    group('isUsernameAvailable', () {
      test('returns true for non-existent username', () async {
        final available =
            await userService.isUsernameAvailable('new_user', 'uid_123');
        expect(available, isTrue);
      });

      test('returns false for username taken by another user', () async {
        await mockFirestore
            .collection('usernames')
            .doc('taken')
            .set({'uid': 'other_uid'});
        final available =
            await userService.isUsernameAvailable('taken', 'uid_123');
        expect(available, isFalse);
      });

      test('returns false when checking availability with mixed case',
          () async {
        await mockFirestore
            .collection('usernames')
            .doc('taken')
            .set({'uid': 'other_uid'});
        final available =
            await userService.isUsernameAvailable('TaKeN', 'uid_123');
        expect(available, isFalse);
      });

      test('returns true if username belongs to current user', () async {
        await mockFirestore
            .collection('usernames')
            .doc('myname')
            .set({'uid': 'uid_123'});
        final available =
            await userService.isUsernameAvailable('myname', 'uid_123');
        expect(available, isTrue);
      });

      test('returns false on error', () async {
        final mockFailingFirestore = MockFirestore();
        when(mockFailingFirestore.collection(any))
            .thenThrow(Exception('Firestore Error'));

        final failingService =
            UserService(db: mockFailingFirestore, storage: mockStorage);
        final available =
            await failingService.isUsernameAvailable('new_user', 'uid_123');
        expect(available, isFalse);
      });
    });

    group('saveProfileWithUsername', () {
      test('creates both documents for a new user and normalizes casing',
          () async {
        final profile = UserProfile(
          uid: 'uid_123',
          username: 'New_HeRo',
          firstName: 'John',
          lastName: 'Doe',
        );

        await userService.saveProfileWithUsername(profile, '');

        final userDoc =
            await mockFirestore.collection('users').doc('uid_123').get();
        expect(userDoc.data()?['username'], 'new_hero');

        final usernameDoc =
            await mockFirestore.collection('usernames').doc('new_hero').get();
        expect(usernameDoc.data()?['uid'], 'uid_123');
      });

      test('handles username change and deletes old mapping', () async {
        await mockFirestore
            .collection('usernames')
            .doc('old_name')
            .set({'uid': 'uid_123'});

        final profile = UserProfile(
          uid: 'uid_123',
          username: 'new_name',
          firstName: 'John',
          lastName: 'Doe',
        );

        await userService.saveProfileWithUsername(profile, 'old_name');

        expect(
            (await mockFirestore.collection('usernames').doc('old_name').get())
                .exists,
            isFalse);
        expect(
            (await mockFirestore.collection('usernames').doc('new_name').get())
                .data()?['uid'],
            'uid_123');
      });

      test('does not update mapping if username is unchanged', () async {
        await mockFirestore
            .collection('usernames')
            .doc('same')
            .set({'uid': 'uid_123'});

        final profile = UserProfile(
          uid: 'uid_123',
          username: 'same',
          firstName: 'Updated',
          lastName: 'Doe',
        );

        await userService.saveProfileWithUsername(profile, 'same');

        final usernameDoc =
            await mockFirestore.collection('usernames').doc('same').get();
        expect(usernameDoc.exists, isTrue);
        expect(usernameDoc.data()?['uid'], 'uid_123');

        final userDoc =
            await mockFirestore.collection('users').doc('uid_123').get();
        expect(userDoc.data()?['firstName'], 'Updated');
      });

      test(
          'throws Exception if username taken by someone else during transaction',
          () async {
        await mockFirestore
            .collection('usernames')
            .doc('stolen')
            .set({'uid': 'villain'});

        final profile = UserProfile(
          uid: 'uid_123',
          username: 'stolen',
          firstName: 'Hero',
          lastName: 'Doe',
        );

        expect(
          () => userService.saveProfileWithUsername(profile, ''),
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
            UserService(db: mockFailingFirestore, storage: mockStorage);

        final profile = UserProfile(
          uid: 'uid_123',
          username: 'new_name',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(
          () => failingService.saveProfileWithUsername(profile, 'old_name'),
          throwsException,
        );
      });
    });

    group('uploadProfilePicture', () {
      test('uploads file and returns download URL', () async {
        final url = await userService.uploadProfilePicture('uid_123', tempFile);

        expect(url, isNotEmpty);
        expect(url, contains('uid_123'));
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
            UserService(db: mockFirestore, storage: mockStorage);

        await expectLater(
          failingService.uploadProfilePicture('uid_123', tempFile),
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
            UserService(db: mockFirestore, storage: mockStorage);

        await expectLater(
          stateFailingService.uploadProfilePicture('uid_123', tempFile),
          throwsA(isA<Exception>().having((e) => e.toString(), 'description',
              contains('Upload failed with state'))),
        );
      });
    });
  });
}
