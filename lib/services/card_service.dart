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
    print('DEBUG: getRandomCards chiamata con count=$count, packId=$packId');
    final random = Random();
    final List<CollectionCard> result = [];

    // Verifica che ci siano carte disponibili per questo pacchetto
    final allCardsInPack = getCardsByPack(packId);
    print(
        'DEBUG: Carte totali nel pacchetto $packId: ${allCardsInPack.length}');
    if (allCardsInPack.isEmpty) {
      print('DEBUG: Nessuna carta trovata per il pacchetto $packId');
      return [];
    }

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

      print('DEBUG: Carta ${i + 1}, rarità selezionata: $selectedRarity');

      final List<CollectionCard> cardsOfRarity =
          getCardsByRarityAndPack(selectedRarity, packId);

      print(
          'DEBUG: Carte disponibili per rarità $selectedRarity: ${cardsOfRarity.length}');

      CollectionCard? selectedCard;

      // Se non ci sono carte della rarità selezionata, prova con la rarità più vicina
      if (cardsOfRarity.isEmpty) {
        print(
            'DEBUG: Nessuna carta per rarità $selectedRarity, usando fallback');
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
          print(
              'DEBUG: Fallback rarità $rarity: ${fallbackCards.length} carte');
          if (fallbackCards.isNotEmpty) {
            selectedCard = fallbackCards[random.nextInt(fallbackCards.length)];
            print(
                'DEBUG: Carta selezionata dal fallback: ${selectedCard.name}');
            break;
          }
        }
      } else {
        // Se ci sono carte della rarità selezionata, scegli una casualmente
        selectedCard = cardsOfRarity[random.nextInt(cardsOfRarity.length)];
        print('DEBUG: Carta selezionata: ${selectedCard.name}');
      }

      // Aggiungi la carta solo se ne è stata trovata una
      if (selectedCard != null) {
        final cardCopy = CollectionCard(
          id: selectedCard.id,
          name: selectedCard.name,
          description: selectedCard.description,
          rarity: selectedCard.rarity,
          imageUrl: selectedCard.imageUrl,
          packId: selectedCard.packId,
        );
        result.add(cardCopy);
        print('DEBUG: Carta aggiunta al risultato: ${cardCopy.name}');
      } else {
        print(
            'DEBUG: Nessuna carta trovata per nessuna rarità, using random dalla lista completa');
        // Se non sono state trovate carte per nessuna rarità,
        // aggiungi una carta qualsiasi dal pacchetto
        if (allCardsInPack.isNotEmpty) {
          final randomCard =
              allCardsInPack[random.nextInt(allCardsInPack.length)];
          final cardCopy = CollectionCard(
            id: randomCard.id,
            name: randomCard.name,
            description: randomCard.description,
            rarity: randomCard.rarity,
            imageUrl: randomCard.imageUrl,
            packId: randomCard.packId,
          );
          result.add(cardCopy);
          print('DEBUG: Carta random aggiunta: ${cardCopy.name}');
        }
      }
    }

    print('DEBUG: getRandomCards restituisce ${result.length} carte');
    return result;
  }
}
