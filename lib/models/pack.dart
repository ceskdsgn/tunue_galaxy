// models/pack.dart

class Pack {
  final String id;
  final String name;
  final String description;
  final String image;
  final String? model3D; // Percorso del modello 3D (opzionale)
  final int baseCost;

  Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.model3D,
    this.baseCost = 12,
  });

  factory Pack.fromJson(Map<String, dynamic> json) {
    // Verifica che i campi obbligatori non siano null
    if (json['id'] == null ||
        json['name'] == null ||
        json['description'] == null ||
        json['image'] == null) {
      throw Exception('Pack with null fields: $json');
    }

    return Pack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      model3D: json['model3D'],
      baseCost: json['price'] ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'model3D': model3D,
      'baseCost': baseCost,
    };
  }
}
