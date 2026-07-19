import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import '../models/user_profile.dart';

/// Exception thrown when a user attempts to claim a username that is already taken.
class UsernameAlreadyTakenException implements Exception {
  final String username;
  UsernameAlreadyTakenException(this.username);
  @override
  String toString() => 'Username "$username" is already taken.';
}

/// Service class for managing user-related data in Firestore and Firebase Storage.
class UserService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const String _usersCollection = 'users';
  static const String _usernamesCollection = 'usernames';
  static const String _profilePicturesPath = 'profile_pictures';

  UserService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Returns a stream of the [UserProfile] for a given [uid].
  ///
  /// Returns `null` if the profile does not exist or an error occurs.
  Stream<UserProfile?> streamProfile(String uid) {
    return _db.collection(_usersCollection).doc(uid).snapshots().map((snapshot) {
      try {
        if (snapshot.exists && snapshot.data() != null) {
          return UserProfile.fromMap(uid, snapshot.data()!);
        }
      } catch (e) {
        debugPrint('Error mapping UserProfile for $uid: $e');
      }
      return null;
    });
  }

  /// Checks if a [username] is available for use.
  ///
  /// A username is available if it doesn't exist or if it already belongs to [currentUid].
  Future<bool> isUsernameAvailable(String username, String currentUid) async {
    try {
      final doc = await _db
          .collection(_usernamesCollection)
          .doc(username.toLowerCase())
          .get();
      if (!doc.exists) return true;

      // If it exists, it's available only if it belongs to the current user
      return doc.data()?['uid'] == currentUid;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  /// Saves a user's profile and ensures the username is unique using a Firestore transaction.
  ///
  /// [oldUsername] should be the username currently stored in the database to handle
  /// mapping updates correctly.
  ///
  /// Throws a [UsernameAlreadyTakenException] if the new username is already in use by another user.
  Future<void> saveProfileWithUsername(
      UserProfile profile, String oldUsername) async {
    final newUsername = profile.username.toLowerCase();
    final normalizedOldUsername = oldUsername.toLowerCase();

    final userRef = _db.collection(_usersCollection).doc(profile.uid);
    final usernameRef = _db.collection(_usernamesCollection).doc(newUsername);

    try {
      await _db.runTransaction((transaction) async {
        // 1. Check if the new username is already taken by someone else
        final usernameDoc = await transaction.get(usernameRef);
        if (usernameDoc.exists && usernameDoc.data()?['uid'] != profile.uid) {
          throw UsernameAlreadyTakenException(profile.username);
        }

        // 2. Handle username mapping updates
        if (normalizedOldUsername != newUsername) {
          // If they are changing their username, remove the old mapping
          if (normalizedOldUsername.isNotEmpty) {
            final oldUsernameRef =
                _db.collection(_usernamesCollection).doc(normalizedOldUsername);
            transaction.delete(oldUsernameRef);
          }
          // Create the new mapping
          transaction.set(usernameRef, {'uid': profile.uid});
        }

        // 3. Update the user profile
        // We force the lowercased username in the profile document for consistency
        final profileMap = profile.toMap();
        profileMap['username'] = newUsername;

        transaction.set(userRef, profileMap, SetOptions(merge: true));
      });
    } catch (e) {
      if (e is UsernameAlreadyTakenException) rethrow;
      debugPrint('Error saving profile with username: $e');
      rethrow;
    }
  }

  /// Uploads a profile picture to Firebase Storage and returns the download URL.
  ///
  /// The file is stored at `profile_pictures/{uid}` (no extension) to ensure
  /// that a user only ever has one profile picture file.
  Future<String> uploadProfilePicture(String uid, File image) async {
    try {
      final ref = _storage.ref().child(_profilePicturesPath).child(uid);

      // Detect the actual mime type of the file
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      final uploadTask = ref.putFile(
        image,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }
}
