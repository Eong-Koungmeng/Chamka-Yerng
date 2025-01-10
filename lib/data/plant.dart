import 'package:json_annotation/json_annotation.dart';
import 'care.dart';

class Plant {
  int id;
  String name;
  String? location;
  String description;
  DateTime createdAt;
  String? picture;
  List<Care> cares;

  Plant({
    required this.name,
    this.id = 0,
    this.location,
    this.description = "",
    required this.createdAt,
    this.picture,
    required this.cares,
  });

  /// Factory method to create a `Plant` from Firebase data.
  factory Plant.fromMap(Map<Object?, Object?> map) {
    return Plant(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? "",
      location: map['location'] as String?,
      description: map['description'] as String? ?? "",
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      picture: map['picture'] as String?,
      cares: (map['cares'] as List<dynamic>?)
          ?.map((e) => Care.fromMap(e as Map<Object?, Object?>))
          .toList() ??
          [],
    );
  }

  /// Method to convert `Plant` to Firebase-compatible Map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'picture': picture,
      'cares': cares.map((e) => e.toMap()).toList(),
    };
  }
}