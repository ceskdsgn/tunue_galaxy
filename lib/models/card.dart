// models/card.dart
import 'package:flutter/material.dart';

enum CardRarity { common, rare, superRare, ultraRare, gold }

class CollectionCard {
  final String id;
  final String name;
  final String description;
  final CardRarity rarity;
  final String imageUrl;
  bool isOwned;
  int quantity;
  final String packId;

  CollectionCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.imageUrl,
    this.isOwned = false,
    this.quantity = 1,
    required this.packId,
  });

  factory CollectionCard.fromJson(Map<String, dynamic> json) {
    return CollectionCard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rarity: CardRarity.values
          .firstWhere((e) => e.toString() == 'CardRarity.${json['rarity']}'),
      imageUrl: json['imageUrl'],
      isOwned: json['isOwned'] ?? false,
      quantity: json['quantity'] ?? 1,
      packId: json['pack_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.toString().split('.').last,
      'imageUrl': imageUrl,
      'isOwned': isOwned,
      'quantity': quantity,
      'pack_id': packId,
    };
  }

  static String getRarityString(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return "Comune";
      case CardRarity.rare:
        return "Rara";
      case CardRarity.superRare:
        return "Super Rara";
      case CardRarity.ultraRare:
        return "Ultra Rara";
      case CardRarity.gold:
        return "Gold";
    }
  }

  static Color getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.superRare:
        return Colors.purple;
      case CardRarity.ultraRare:
        return Colors.red;
      case CardRarity.gold:
        return Colors.amber;
    }
  }
}
