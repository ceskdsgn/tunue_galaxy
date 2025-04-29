// services/card_service.dart
import 'dart:math';

import '../models/card.dart';
import 'supabase_service.dart';

class CardService {
  final SupabaseService _supabaseService = SupabaseService();
  static final CardService _instance = CardService._internal();
  List<CollectionCard> _allCards = [];

  factory CardService() {
    return _instance;
  }

  CardService._internal();

  Future<void> loadCards() async {
    _allCards = await _supabaseService.getAllCards();
  }

  List<CollectionCard> getAllCards() {
    return List.from(_allCards);
  }

  CollectionCard getCardById(String id) {
    return _allCards.firstWhere((card) => card.id == id);
  }

  List<CollectionCard> getCardsByRarity(CardRarity rarity) {
    return _allCards.where((card) => card.rarity == rarity).toList();
  }

  List<CollectionCard> getCardsByPack(String packId) {
    return _allCards.where((card) => card.packId == packId).toList();
  }

  List<CollectionCard> getCardsByRarityAndPack(
      CardRarity rarity, String packId) {
    return _allCards
        .where((card) => card.rarity == rarity && card.packId == packId)
        .toList();
  }

  List<CollectionCard> getRandomCards(int count, String packId) {
    final random = Random();
    final List<CollectionCard> result = [];

    for (int i = 0; i < count; i++) {
      final rarityRoll = random.nextInt(100) + 1;

      CardRarity selectedRarity;

      // Nuove probabilità:
      // 75% comune, 20% rara, 4% super rara, 0.9% ultra rara, 0.1% gold
      if (rarityRoll <= 75) {
        selectedRarity = CardRarity.common;
      } else if (rarityRoll <= 95) {
        selectedRarity = CardRarity.rare;
      } else if (rarityRoll <= 99) {
        selectedRarity = CardRarity.superRare;
      } else if (rarityRoll <= 99.9) {
        selectedRarity = CardRarity.ultraRare;
      } else {
        selectedRarity = CardRarity.gold;
      }

      final List<CollectionCard> cardsOfRarity =
          getCardsByRarityAndPack(selectedRarity, packId);

      // Se non ci sono carte della rarità selezionata, prova con la rarità più vicina
      if (cardsOfRarity.isEmpty) {
        final List<CardRarity> fallbackRarities = [
          CardRarity.common,
          CardRarity.rare,
          CardRarity.superRare,
          CardRarity.ultraRare,
          CardRarity.gold,
        ];

        // Cerca la rarità più vicina che ha delle carte
        for (final rarity in fallbackRarities) {
          final fallbackCards = getCardsByRarityAndPack(rarity, packId);
          if (fallbackCards.isNotEmpty) {
            final selectedCard =
                fallbackCards[random.nextInt(fallbackCards.length)];
            final cardCopy = CollectionCard(
              id: selectedCard.id,
              name: selectedCard.name,
              description: selectedCard.description,
              rarity: selectedCard.rarity,
              imageUrl: selectedCard.imageUrl,
              packId: selectedCard.packId,
            );
            result.add(cardCopy);
            break;
          }
        }
      } else {
        // Se ci sono carte della rarità selezionata, scegli una casualmente
        final selectedCard =
            cardsOfRarity[random.nextInt(cardsOfRarity.length)];
        final cardCopy = CollectionCard(
          id: selectedCard.id,
          name: selectedCard.name,
          description: selectedCard.description,
          rarity: selectedCard.rarity,
          imageUrl: selectedCard.imageUrl,
          packId: selectedCard.packId,
        );
        result.add(cardCopy);
      }
    }

    return result;
  }
}
