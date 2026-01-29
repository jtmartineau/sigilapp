class SavedSigil {
  final String id;
  final String incantation;
  final String imagePath;
  final DateTime dateCreated;

  SavedSigil({
    required this.id,
    required this.incantation,
    required this.imagePath,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incantation': incantation,
      'imagePath': imagePath,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory SavedSigil.fromJson(Map<String, dynamic> json) {
    return SavedSigil(
      id: json['id'],
      incantation: json['incantation'],
      imagePath: json['imagePath'],
      dateCreated: DateTime.parse(json['dateCreated']),
    );
  }
}
