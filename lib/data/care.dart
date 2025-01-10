import 'package:json_annotation/json_annotation.dart';

class Care {
  int id;
  String name;
  int cycles;
  DateTime? effected;

  Care({
    required this.name,
    this.cycles = 0,
    this.effected,
    this.id = 0,
  });

  /// Factory method to create a `Care` from Firebase data.
  factory Care.fromMap(Map<Object?, Object?> map) {
    return Care(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? "",
      cycles: (map['cycles'] as num?)?.toInt() ?? 0,
      effected: map['effected'] == null
          ? null
          : DateTime.parse(map['effected'] as String? ?? ""),
    );
  }

  /// Method to convert `Care` to Firebase-compatible Map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'cycles': cycles,
      'effected': effected?.toIso8601String(),
    };
  }
}
