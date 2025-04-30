import 'package:flutter/material.dart';

import 'card.dart';

class SpecialPack {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final Color color;
  final IconData icon;
  final CardRarity? guaranteedRarity;
  final String? specificPackId;
  final int numCards;

  SpecialPack({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.color,
    required this.icon,
    this.guaranteedRarity,
    this.specificPackId,
    this.numCards = 5,
  });

  // Pacchetto con carta rara garantita
  static SpecialPack rareCardPack() {
    return SpecialPack(
      id: 'rare_pack',
      name: 'Pacchetto Carta Rara',
      description: 'Contiene una carta rara garantita!',
      imageUrl:
          'https://placekitten.com/400/600', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.blue,
      icon: Icons.card_giftcard,
      guaranteedRarity: CardRarity.rare,
      numCards: 1,
    );
  }

  // Pacchetto con carta super-rara garantita
  static SpecialPack superRareCardPack() {
    return SpecialPack(
      id: 'super_rare_pack',
      name: 'Pacchetto Carta Super Rara',
      description: 'Contiene una carta super-rara garantita!',
      imageUrl:
          'https://placekitten.com/400/601', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.purple,
      icon: Icons.card_giftcard,
      guaranteedRarity: CardRarity.superRare,
      numCards: 1,
    );
  }

  // Pacchetto con carta ultra-rara garantita
  static SpecialPack ultraRareCardPack() {
    return SpecialPack(
      id: 'ultra_rare_pack',
      name: 'Pacchetto Carta Ultra Rara',
      description: 'Contiene una carta ultra-rara garantita!',
      imageUrl:
          'https://placekitten.com/400/602', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.red,
      icon: Icons.card_giftcard,
      guaranteedRarity: CardRarity.ultraRare,
      numCards: 1,
    );
  }

  // Pacchetto Fire Destruction
  static SpecialPack fireDestructionPack() {
    return SpecialPack(
      id: 'fire_destruction_pack',
      name: 'Pacchetto Fire Destruction',
      description: 'Pacchetto Fire Destruction esclusivo!',
      imageUrl:
          'https://placekitten.com/400/603', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.orange,
      icon: Icons.local_fire_department,
      numCards: 5,
    );
  }

  // Pacchetto di monete
  static SpecialPack coinPack() {
    return SpecialPack(
      id: 'coin_pack',
      name: '12 Tunuè Coin',
      description: '12 Tunuè Coin da spendere nel negozio!',
      imageUrl:
          'https://placekitten.com/400/604', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.amber,
      icon: Icons.monetization_on,
      numCards: 0,
    );
  }

  // Pacchetto vuoto (nessun premio)
  static SpecialPack emptyPack() {
    return SpecialPack(
      id: 'empty_pack',
      name: 'Nessun Premio',
      description: 'Peccato! Ritenta la prossima volta.',
      imageUrl:
          'https://placekitten.com/400/605', // Segnaposto, da sostituire con immagine effettiva
      color: Colors.grey,
      icon: Icons.do_not_disturb,
      numCards: 0,
    );
  }
}
