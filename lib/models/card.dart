// models/card.dart
import 'package:flutter/material.dart';

enum CardRarity { common, rare, superRare, ultraRare, gold }

class CollectionCard {
  final String id;
  final String name;
  final String description;
  final String effect;
  final String story;
  final CardRarity rarity;
  final String imageUrl;
  final String link;
  bool isOwned;
  int quantity;
  final String packId;

  CollectionCard({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    required this.story,
    required this.rarity,
    required this.imageUrl,
    required this.link,
    this.isOwned = false,
    this.quantity = 1,
    required this.packId,
  });

  factory CollectionCard.fromJson(Map<String, dynamic> json) {
    return CollectionCard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      effect: json['effect'] ?? '',
      story: json['story'] ?? '',
      rarity: CardRarity.values
          .firstWhere((e) => e.toString() == 'CardRarity.${json['rarity']}'),
      imageUrl: json['imageUrl'],
      link: json['link'] ?? '',
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
      'effect': effect,
      'story': story,
      'rarity': rarity.toString().split('.').last,
      'imageUrl': imageUrl,
      'link': link,
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
        return const Color(0xFFE5E5E5); // Grigio chiarissimo
      case CardRarity.rare:
        return const Color.fromARGB(
            255, 22, 235, 104); // Verde (colore principale del gradient)
      case CardRarity.superRare:
        return const Color.fromARGB(
            255, 28, 95, 197); // Blu chiaro (colore principale del gradient)
      case CardRarity.ultraRare:
        return const Color(
            0xFFFF0040); // Rosso acceso (colore principale del gradient)
      case CardRarity.gold:
        return const Color(0xFFFFD700); // Oro
    }
  }

  static LinearGradient? getRarityGradient(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.rare:
        return const LinearGradient(
          colors: [Color(0xFF18FB3D), Color(0xFF4BFF9E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case CardRarity.superRare:
        return const LinearGradient(
          colors: [
            Color(0xFF87CEEB),
            Color(0xFF1E3A8A)
          ], // Blu chiaro → Blu scuro
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case CardRarity.ultraRare:
        return const LinearGradient(
          colors: [
            Color(0xFFFF0040),
            Color(0xFF8A2BE2)
          ], // Rosso acceso → Violetto
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      default:
        return null; // Le altre rarità non usano gradient
    }
  }

  static bool hasGradient(CardRarity rarity) {
    return rarity == CardRarity.rare ||
        rarity == CardRarity.superRare ||
        rarity == CardRarity.ultraRare;
  }
}
