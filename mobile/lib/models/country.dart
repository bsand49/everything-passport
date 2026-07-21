import 'package:flutter/foundation.dart';

/// Represents a country with its identification and metadata.
@immutable
class Country {
  final String id;
  final String name;
  final List<String> searchKeywords;

  /// Creates a [Country] instance.
  const Country({
    required this.id,
    required this.name,
    required this.searchKeywords,
  });

  /// Creates a [Country] instance from a [Map].
  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      searchKeywords: (map['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Converts the [Country] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'searchKeywords': searchKeywords,
    };
  }

  /// Creates a copy of this [Country] but with the given fields replaced with the new values.
  Country copyWith({
    String? id,
    String? name,
    List<String>? searchKeywords,
  }) {
    return Country(
      id: id ?? this.id,
      name: name ?? this.name,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(searchKeywords, other.searchKeywords);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ searchKeywords.hashCode;
}
