// services/auth_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_pkg;

import '../constants/supabase.dart';
import '../models/card.dart';
import '../models/user.dart' as app_models;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final supabase_pkg.SupabaseClient _client = supabase;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Stream per ascoltare i cambiamenti di autenticazione
  Stream<supabase_pkg.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // Ottieni l'utente attualmente autenticato
  supabase_pkg.User? get currentUser => _client.auth.currentUser;

  // Registrazione con email e password
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required Function(app_models.User) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Registra l'utente
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );

      if (response.user == null) {
        throw Exception('Errore durante la registrazione');
      }

      // Crea il profilo utente in Supabase
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'tunue_coins': 100, // Coins iniziali
        'owned_cards': [],
        'last_pack_open_time': DateTime.now().toUtc().toIso8601String(),
        'next_pack_time': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 12))
            .toIso8601String(),
      });

      // Crea l'oggetto utente
      final user = app_models.User(
        id: response.user!.id,
        username: username,
        email: email,
        tunueCoins: 100,
        ownedCards: [],
        lastPackOpenTime: DateTime.now().toUtc(),
        nextPackTime: DateTime.now().toUtc().add(const Duration(hours: 12)),
        isAuthenticated: true,
      );

      onSuccess(user);
    } catch (e) {
      onError(e.toString());
    }
  }

  // Login con email e password
  Future<void> signIn({
    required String email,
    required String password,
    required Function(app_models.User) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Effettua il login
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Errore durante il login');
      }

      // Recupera i dati del profilo
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      // Se il profilo non esiste, crealo
      if (profileResponse == null) {
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'username':
              response.user!.userMetadata?['username'] ?? 'Collezionista',
          'email': response.user!.email ?? email,
          'tunue_coins': 100,
          'owned_cards': [],
          'last_pack_open_time': DateTime.now().toUtc().toIso8601String(),
          'next_pack_time': DateTime.now()
              .toUtc()
              .add(const Duration(hours: 12))
              .toIso8601String(),
        });
      }

      // Ricarica il profilo
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // Converti le carte possedute da JSON a oggetti
      List<CollectionCard> ownedCards = [];
      if (profile['owned_cards'] != null && profile['owned_cards'] is List) {
        for (var cardData in profile['owned_cards']) {
          ownedCards.add(CollectionCard.fromJson(cardData));
        }
      }

      // Crea l'oggetto utente
      final user = app_models.User(
        id: response.user!.id,
        username: profile['username'] ?? 'Collezionista',
        email: response.user!.email ?? email,
        tunueCoins: profile['tunue_coins'] ?? 0,
        ownedCards: ownedCards,
        lastPackOpenTime:
            DateTime.parse(profile['last_pack_open_time']).toLocal(),
        nextPackTime: DateTime.parse(profile['next_pack_time']).toLocal(),
        isAuthenticated: true,
      );

      onSuccess(user);
    } catch (e) {
      debugPrint('Errore durante il login: $e');
      onError(e.toString());
    }
  }

  // Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reimposta password
  Future<void> resetPassword({
    required String email,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verifica se l'utente è autenticato
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // Sincronizza i dati utente con Supabase
  Future<void> syncUserData(app_models.User user) async {
    try {
      // Verifica se il profilo esiste
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        // Se il profilo non esiste, crealo
        await _client.from('profiles').insert({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'tunue_coins': user.tunueCoins,
          'owned_cards': user.ownedCards.map((card) => card.toJson()).toList(),
          'last_pack_open_time':
              user.lastPackOpenTime.toUtc().toIso8601String(),
          'next_pack_time': user.nextPackTime.toUtc().toIso8601String(),
        });
      } else {
        // Altrimenti aggiornalo
        await _client.from('profiles').update({
          'username': user.username,
          'tunue_coins': user.tunueCoins,
          'owned_cards': user.ownedCards.map((card) => card.toJson()).toList(),
          'last_pack_open_time':
              user.lastPackOpenTime.toUtc().toIso8601String(),
          'next_pack_time': user.nextPackTime.toUtc().toIso8601String(),
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Errore durante la sincronizzazione: $e');
    }
  }
}
