import 'package:flutter/material.dart';

enum CardType {
  character,
  setting,
  interaction,
}

enum CardRarity {
  common,
  uncommon,
  rare,
  legendary,
}

class GameCard {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int cost;
  final CardType type;
  final CardRarity rarity;

  // Solo per carte Personaggio
  final int? power;
  final String? effect;

  const GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cost,
    required this.type,
    required this.rarity,
    this.power,
    this.effect,
  });

  static Color getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey.shade600;
      case CardRarity.uncommon:
        return Colors.green.shade600;
      case CardRarity.rare:
        return Colors.blue.shade600;
      case CardRarity.legendary:
        return Colors.purple.shade600;
    }
  }

  static String getRarityString(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 'Comune';
      case CardRarity.uncommon:
        return 'Non Comune';
      case CardRarity.rare:
        return 'Rara';
      case CardRarity.legendary:
        return 'Leggendaria';
    }
  }

  static IconData getTypeIcon(CardType type) {
    switch (type) {
      case CardType.character:
        return Icons.person;
      case CardType.setting:
        return Icons.landscape;
      case CardType.interaction:
        return Icons.flash_on;
    }
  }

  static String getTypeString(CardType type) {
    switch (type) {
      case CardType.character:
        return 'Personaggio';
      case CardType.setting:
        return 'Ambientazione';
      case CardType.interaction:
        return 'Interazione';
    }
  }
}

class GamePlayer {
  final String id;
  final String name;
  List<GameCard> deck;
  List<GameCard> hand;
  List<GameCard> field; // Personaggi in campo
  GameCard? activeSetting; // Ambientazione attiva
  int energy;
  int maxEnergy;
  int lives;
  bool hasUsedHeroMoment;

  GamePlayer({
    required this.id,
    required this.name,
    required this.deck,
    this.hand = const [],
    this.field = const [],
    this.activeSetting,
    this.energy = 1,
    this.maxEnergy = 1,
    this.lives = 3,
    this.hasUsedHeroMoment = false,
  });

  void drawCard() {
    if (deck.isNotEmpty) {
      hand.add(deck.removeAt(0));
    }
  }

  void increaseEnergy() {
    maxEnergy = maxEnergy < 10 ? maxEnergy + 1 : 10;
    energy = maxEnergy;
  }

  void playCard(GameCard card) {
    if (energy >= card.cost && hand.contains(card)) {
      energy -= card.cost;
      hand.remove(card);

      switch (card.type) {
        case CardType.character:
          field.add(card);
          break;
        case CardType.setting:
          activeSetting = card;
          break;
        case CardType.interaction:
          // L'effetto dell'interazione verrebbe gestito dalla logica di gioco
          break;
      }
    }
  }

  bool canDrawCard() {
    return deck.isNotEmpty;
  }
}

class GameState {
  GamePlayer player1;
  GamePlayer player2;
  GamePlayer activePlayer;
  int turn;
  bool isGameOver;

  GameState({
    required this.player1,
    required this.player2,
    required this.activePlayer,
    this.turn = 1,
    this.isGameOver = false,
  });

  void nextTurn() {
    activePlayer = activePlayer.id == player1.id ? player2 : player1;
    turn++;

    // Inizio turno: pesca una carta e incrementa energia
    activePlayer.increaseEnergy();

    if (!activePlayer.canDrawCard()) {
      // Se il giocatore non può pescare una carta, perde una vita
      activePlayer.lives--;
      if (activePlayer.lives <= 0) {
        isGameOver = true;
      }
    } else {
      activePlayer.drawCard();
    }
  }

  double calculateWinProbability(GamePlayer player) {
    // Questa sarebbe una logica complessa basata su molti fattori
    // Per ora, restituiamo una semplice approssimazione
    GamePlayer opponent = player.id == player1.id ? player2 : player1;

    int playerPower = player.field
        .where((card) => card.type == CardType.character)
        .fold(0, (sum, card) => sum + (card.power ?? 0));

    int opponentPower = opponent.field
        .where((card) => card.type == CardType.character)
        .fold(0, (sum, card) => sum + (card.power ?? 0));

    int playerHandValue = player.hand.length;
    int opponentHandValue = opponent.hand.length;

    int playerDeckValue = player.deck.length;
    int opponentDeckValue = opponent.deck.length;

    double playerScore = (playerPower * 1.5) +
        (playerHandValue * 0.8) +
        (playerDeckValue * 0.3) +
        (player.lives * 3) +
        (player.energy * 0.5);

    double opponentScore = (opponentPower * 1.5) +
        (opponentHandValue * 0.8) +
        (opponentDeckValue * 0.3) +
        (opponent.lives * 3) +
        (opponent.energy * 0.5);

    double totalScore = playerScore + opponentScore;
    if (totalScore == 0) return 0.5; // Evita divisione per zero

    return playerScore / totalScore;
  }

  bool canUseHeroMoment(GamePlayer player) {
    if (player.hasUsedHeroMoment) return false;

    double winProbability = calculateWinProbability(player);
    return winProbability < 0.2; // Sotto il 20%
  }
}
