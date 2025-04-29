import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/card.dart';
import '../models/pack.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _client = SupabaseClient(
        SupabaseConfig.supabaseUrl, SupabaseConfig.supabaseAnonKey);
  }

  Future<List<CollectionCard>> getAllCards() async {
    try {
      final response = await _client.from('cards').select('*');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((cardData) {
        return CollectionCard(
          id: cardData['id'],
          name: cardData['name'],
          description: cardData['description'],
          rarity: _mapRarityFromString(cardData['rarity_id']),
          imageUrl: cardData['image'],
          packId: cardData['pack_id'],
        );
      }).toList();
    } catch (e) {
      print('Errore nel recupero delle carte: $e');
      return [];
    }
  }

  CardRarity _mapRarityFromString(String rarityName) {
    switch (rarityName.toLowerCase()) {
      case 'common':
        return CardRarity.common;
      case 'rare':
        return CardRarity.rare;
      case 'super-rare':
        return CardRarity.superRare;
      case 'ultra-rare':
        return CardRarity.ultraRare;
      case 'gold':
        return CardRarity.gold;
      default:
        print('Rarità non riconosciuta: $rarityName');
        return CardRarity.common;
    }
  }

  Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: 'https://jfzgmzampwokvpwryftp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmemdtemFtcHdva3Zwd3J5ZnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MTg3MTgsImV4cCI6MjA2MDE5NDcxOH0.YsDMlty3KV87hubOPdH6yDm8ndF-qRkvV2nNhSc-5A8',
    );
  }

  Future<List<Pack>> getAllPacks() async {
    try {
      final response = await _client.from('packs').select('*');
      final List<dynamic> data = response as List<dynamic>;
      return data.map((packData) => Pack.fromJson(packData)).toList();
    } catch (e) {
      print('Errore nel recupero dei pacchetti: $e');
      return [];
    }
  }
}
