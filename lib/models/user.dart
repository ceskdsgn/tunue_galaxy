// models/user.dart
import 'package:flutter/foundation.dart';

import 'card.dart';

class User extends ChangeNotifier {
  String id;
  String username;
  String? email; // Aggiunto campo email
  int tunueCoins;
  List<CollectionCard> ownedCards;
  DateTime lastPackOpenTime;
  DateTime
      nextPackTime; // Aggiungo il campo per il prossimo pacchetto disponibile
  bool isAuthenticated; // Aggiunto flag per l'autenticazione

  User({
    this.id = '',
    required this.username, // Rimuovo il valore di default e lo rendo required
    this.email,
    this.tunueCoins = 50,
    List<CollectionCard>? ownedCards,
    DateTime? lastPackOpenTime,
    DateTime? nextPackTime,
    this.isAuthenticated = false, // Default è non autenticato
  })  : ownedCards = ownedCards ?? [],
        lastPackOpenTime = lastPackOpenTime ??
            DateTime.now().toUtc().subtract(const Duration(hours: 12)),
        nextPackTime = nextPackTime ??
            DateTime.now().toUtc().add(const Duration(hours: 12));

  void addCard(CollectionCard card) {
    card.isOwned = true;
    final existingCardIndex = ownedCards.indexWhere((c) => c.id == card.id);
    if (existingCardIndex == -1) {
      ownedCards.add(card);
    } else {
      ownedCards[existingCardIndex].quantity++;
    }
    notifyListeners();
  }

  void addCoins(int amount) {
    tunueCoins += amount;
    notifyListeners();
  }

  bool canOpenFreePack() {
    return DateTime.now().isAfter(nextPackTime);
  }

  Duration timeUntilNextFreePack() {
    return nextPackTime.difference(DateTime.now());
  }

  void updateLastPackOpenTime() {
    lastPackOpenTime = DateTime.now().toUtc();
    nextPackTime = DateTime.now().toUtc().add(const Duration(hours: 12));
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (tunueCoins >= amount) {
      tunueCoins -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Aggiorna i dati dell'utente
  void update({
    String? id,
    String? username,
    String? email,
    int? tunueCoins,
    List<CollectionCard>? ownedCards,
    DateTime? lastPackOpenTime,
    DateTime? nextPackTime,
    bool? isAuthenticated,
  }) {
    if (id != null) this.id = id;
    if (username != null) this.username = username;
    if (email != null) this.email = email;
    if (tunueCoins != null) this.tunueCoins = tunueCoins;
    if (ownedCards != null) this.ownedCards = ownedCards;
    if (lastPackOpenTime != null) this.lastPackOpenTime = lastPackOpenTime;
    if (nextPackTime != null) this.nextPackTime = nextPackTime;
    if (isAuthenticated != null) this.isAuthenticated = isAuthenticated;
    notifyListeners();
  }

  // Imposta l'utente come autenticato
  void setAuthenticated(bool value) {
    isAuthenticated = value;
    notifyListeners();
  }

  // Reset utente (per logout)
  void reset() {
    id = '';
    username = ''; // Rimuovo il valore di default anche qui
    email = null;
    tunueCoins = 50;
    ownedCards = [];
    lastPackOpenTime =
        DateTime.now().toUtc().subtract(const Duration(hours: 12));
    nextPackTime = DateTime.now().toUtc().add(const Duration(hours: 12));
    isAuthenticated = false;
    notifyListeners();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      tunueCoins: json['tunueCoins'],
      ownedCards: (json['ownedCards'] as List)
          .map((card) => CollectionCard.fromJson(card))
          .toList(),
      lastPackOpenTime: DateTime.parse(json['lastPackOpenTime']),
      nextPackTime: DateTime.parse(json['nextPackTime']),
      isAuthenticated: json['isAuthenticated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'tunueCoins': tunueCoins,
      'ownedCards': ownedCards.map((card) => card.toJson()).toList(),
      'lastPackOpenTime': lastPackOpenTime.toIso8601String(),
      'nextPackTime': nextPackTime.toIso8601String(),
      'isAuthenticated': isAuthenticated,
    };
  }
}
