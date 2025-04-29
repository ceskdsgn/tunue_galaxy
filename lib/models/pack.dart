// models/pack.dart

class Pack {
  final String id;
  final String name;
  final String description;
  final String image;
  final int baseCost;

  Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.baseCost = 12,
  });

  factory Pack.fromJson(Map<String, dynamic> json) {
    return Pack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      baseCost: json['price'] ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'baseCost': baseCost,
    };
  }
}
