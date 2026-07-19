import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a user's profile information within the application.
@immutable
class UserProfile {
  /// The unique identifier for the user (usually from Firebase Auth).
  final String uid;

  /// The user's email address.
  final String? email;

  /// The unique username chosen by the user.
  final String username;

  /// The user's first name.
  final String firstName;

  /// The user's last name.
  final String lastName;

  /// Whether the user's profile is visible to other users.
  final bool isPublic;

  /// The user's date of birth.
  final DateTime? dateOfBirth;

  /// The user's nationality (e.g., ISO country code).
  final String? nationality;

  /// URL to the user's profile picture.
  final String? photoUrl;

  /// Creates a [UserProfile] instance.
  const UserProfile({
    required this.uid,
    this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.isPublic = false,
    this.dateOfBirth,
    this.nationality,
    this.photoUrl,
  });

  /// Creates a [UserProfile] instance from a Firestore map.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String?,
      username: map['username'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? false,
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      nationality: map['nationality'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  /// Converts the [UserProfile] instance to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'isPublic': isPublic,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'nationality': nationality,
      'photoUrl': photoUrl,
    };
  }

  /// Returns the full name of the user by joining first and last name.
  String get fullName => '$firstName $lastName'.trim();

  /// Returns true if any of the essential profile information is missing.
  bool get isIncomplete =>
      username.isEmpty || firstName.isEmpty || lastName.isEmpty;

  /// Creates a copy of this [UserProfile] but with the given fields replaced with the new values.
  UserProfile copyWith({
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    bool? isPublic,
    DateTime? dateOfBirth,
    String? nationality,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isPublic: isPublic ?? this.isPublic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, username: $username, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.uid == uid &&
        other.email == email &&
        other.username == username &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.isPublic == isPublic &&
        other.dateOfBirth == dateOfBirth &&
        other.nationality == nationality &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        username.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        isPublic.hashCode ^
        dateOfBirth.hashCode ^
        nationality.hashCode ^
        photoUrl.hashCode;
  }
}
