import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everything_passport/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    const testUid = 'uid_123';

    test('Constructor creates UserProfile with default isPublic', () {
      const profile = UserProfile(
        uid: testUid,
        username: 'hero',
        firstName: 'John',
        lastName: 'Doe',
      );

      expect(profile.uid, testUid);
      expect(profile.isPublic, isFalse);
      expect(profile.username, 'hero');
    });

    test('fromMap creates UserProfile with complete data', () {
      final dob = DateTime(1990, 1, 1);
      final map = {
        'email': 'john@example.com',
        'username': 'johndoe',
        'firstName': 'John',
        'lastName': 'Doe',
        'isPublic': true,
        'dateOfBirth': Timestamp.fromDate(dob),
        'nationality': 'US',
        'photoUrl': 'https://example.com/photo.jpg',
      };

      final profile = UserProfile.fromMap(testUid, map);

      expect(profile.uid, testUid);
      expect(profile.email, 'john@example.com');
      expect(profile.username, 'johndoe');
      expect(profile.firstName, 'John');
      expect(profile.lastName, 'Doe');
      expect(profile.isPublic, isTrue);
      expect(profile.dateOfBirth, dob);
      expect(profile.nationality, 'US');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
    });

    test('fromMap handles missing data with defaults', () {
      final profile = UserProfile.fromMap(testUid, {});

      expect(profile.username, '');
      expect(profile.firstName, '');
      expect(profile.lastName, '');
      expect(profile.isPublic, isFalse);
      expect(profile.dateOfBirth, isNull);
    });

    test('toMap serializes all fields correctly', () {
      final dob = DateTime(1990, 1, 1);
      final profile = UserProfile(
        uid: testUid,
        email: 'john@example.com',
        username: 'johndoe',
        firstName: 'John',
        lastName: 'Doe',
        isPublic: true,
        dateOfBirth: dob,
        nationality: 'US',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final map = profile.toMap();

      expect(map['email'], 'john@example.com');
      expect(map['username'], 'johndoe');
      expect(map['firstName'], 'John');
      expect(map['lastName'], 'Doe');
      expect(map['isPublic'], isTrue);
      expect(map['dateOfBirth'], isA<Timestamp>());
      expect((map['dateOfBirth'] as Timestamp).toDate(), dob);
      expect(map['nationality'], 'US');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
    });

    test('fullName returns correct string', () {
      const profile = UserProfile(
        uid: '1',
        username: 'u',
        firstName: 'John',
        lastName: 'Doe',
      );
      expect(profile.fullName, 'John Doe');
    });

    test('fullName handles empty names', () {
      const profile1 =
          UserProfile(uid: '1', username: 'u', firstName: 'John', lastName: '');
      expect(profile1.fullName, 'John');

      const profile2 =
          UserProfile(uid: '1', username: 'u', firstName: '', lastName: 'Doe');
      expect(profile2.fullName, 'Doe');

      const profile3 =
          UserProfile(uid: '1', username: 'u', firstName: '', lastName: '');
      expect(profile3.fullName, '');
    });

    test('copyWith updates specified fields', () {
      const profile = UserProfile(
        uid: '1',
        username: 'u',
        firstName: 'A',
        lastName: 'B',
      );

      final updated = profile.copyWith(username: 'new_u', isPublic: true);

      expect(updated.uid, '1');
      expect(updated.username, 'new_u');
      expect(updated.isPublic, isTrue);
      expect(updated.firstName, 'A');
      expect(updated.lastName, 'B');
    });

    test('copyWith returns same instance values when no arguments provided',
        () {
      const profile =
          UserProfile(uid: '1', username: 'u', firstName: 'A', lastName: 'B');
      final updated = profile.copyWith();
      expect(updated, equals(profile));
    });

    test('equality works correctly', () {
      final dob = DateTime(2000, 1, 1);
      final p1 = UserProfile(
        uid: '1',
        username: 'u',
        firstName: 'A',
        lastName: 'B',
        dateOfBirth: dob,
      );
      final p2 = UserProfile(
        uid: '1',
        username: 'u',
        firstName: 'A',
        lastName: 'B',
        dateOfBirth: dob,
      );
      final p3 = p1.copyWith(username: 'v');

      // Reflexive
      expect(p1, equals(p1));

      // Symmetric
      expect(p1, equals(p2));
      expect(p2, equals(p1));

      // HashCode
      expect(p1.hashCode, equals(p2.hashCode));

      // Not equal
      expect(p1, isNot(equals(p3)));
      expect(p1, isNot(equals(null)));
      expect(p1, isNot(equals('not a profile')));
    });

    test('toString returns expected format', () {
      const profile = UserProfile(
        uid: '123',
        username: 'jdoe',
        firstName: 'John',
        lastName: 'Doe',
      );
      expect(profile.toString(),
          'UserProfile(uid: 123, username: jdoe, fullName: John Doe)');
    });

    test('fromMap handles null values by using defaults', () {
      final profile = UserProfile.fromMap('123', {
        'username': null,
        'firstName': null,
        'lastName': null,
        'isPublic': null,
      });
      expect(profile.username, '');
      expect(profile.firstName, '');
      expect(profile.lastName, '');
      expect(profile.isPublic, isFalse);
    });

    group('isIncomplete logic', () {
      test('is true if username is empty', () {
        const profile =
            UserProfile(uid: '1', username: '', firstName: 'A', lastName: 'B');
        expect(profile.isIncomplete, isTrue);
      });

      test('is true if firstName is empty', () {
        const profile =
            UserProfile(uid: '1', username: 'U', firstName: '', lastName: 'B');
        expect(profile.isIncomplete, isTrue);
      });

      test('is true if lastName is empty', () {
        const profile =
            UserProfile(uid: '1', username: 'U', firstName: 'A', lastName: '');
        expect(profile.isIncomplete, isTrue);
      });

      test('is false if all required fields are present', () {
        const profile =
            UserProfile(uid: '1', username: 'U', firstName: 'A', lastName: 'B');
        expect(profile.isIncomplete, isFalse);
      });
    });
  });
}
