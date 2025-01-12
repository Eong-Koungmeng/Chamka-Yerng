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

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'cycles': cycles,
      'effected': effected?.toIso8601String(),
    };
  }
}
