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
      return data
          .map((cardData) {
            if (cardData['id'] == null ||
                cardData['name'] == null ||
                cardData['description'] == null ||
                cardData['rarity_id'] == null ||
                cardData['image'] == null ||
                cardData['pack_id'] == null) {
              print('DEBUG: Carta con campi null saltata: $cardData');
              return null;
            }

            return CollectionCard(
              id: cardData['id'],
              name: cardData['name'],
              description: cardData['description'],
              effect: cardData['effect'] ?? '',
              story: cardData['story'] ?? '',
              rarity: _mapRarityFromString(cardData['rarity_id']),
              imageUrl: cardData['image'],
              link: cardData['link'] ?? '',
              packId: cardData['pack_id'],
            );
          })
          .where((card) => card != null)
          .cast<CollectionCard>()
          .toList();
    } catch (e) {
      print('Errore nel recupero delle carte: $e');
      return [];
    }
  }

  CardRarity _mapRarityFromString(String? rarityName) {
    if (rarityName == null) {
      print('Rarità null, usando common come default');
      return CardRarity.common;
    }

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
      print('Recupero pacchetti da Supabase...');
      final response = await _client.from('packs').select();
      print('Risposta da Supabase: $response');

      if (response.isEmpty) {
        print(
            'Nessun pacchetto trovato nel database, creo pacchetti di default con modelli 3D locali...');
        // Pacchetti di default con modelli 3D locali
        return [
          Pack(
            id: 'pack_1',
            name: 'Pack Avventura',
            description: 'Un pacchetto pieno di carte avventurose',
            image:
                'https://via.placeholder.com/200x280/FF6B6B/FFFFFF?text=Pack+1',
            model3D: 'assets/models/pack.glb',
            baseCost: 10,
          ),
          Pack(
            id: 'pack_2',
            name: 'Pack Magico',
            description: 'Carte magiche e misteriose',
            image:
                'https://via.placeholder.com/200x280/4ECDC4/FFFFFF?text=Pack+2',
            model3D: 'assets/models/pack.glb',
            baseCost: 15,
          ),
          Pack(
            id: 'pack_3',
            name: 'Pack Leggendario',
            description: 'Le carte più rare e potenti',
            image:
                'https://via.placeholder.com/200x280/45B7D1/FFFFFF?text=Pack+3',
            model3D: 'assets/models/pack.glb',
            baseCost: 20,
          ),
        ];
      }

      return response.map((pack) => Pack.fromJson(pack)).toList();
    } catch (e) {
      print('Errore durante il recupero dei pacchetti: $e');
      // Ritorna pacchetti di default in caso di errore con modelli 3D
      return [
        Pack(
          id: 'pack_1',
          name: 'Pack Avventura',
          description: 'Un pacchetto pieno di carte avventurose',
          image:
              'https://via.placeholder.com/200x280/FF6B6B/FFFFFF?text=Pack+1',
          model3D: 'assets/models/pack.glb',
          baseCost: 10,
        ),
        Pack(
          id: 'pack_2',
          name: 'Pack Magico',
          description: 'Carte magiche e misteriose',
          image:
              'https://via.placeholder.com/200x280/4ECDC4/FFFFFF?text=Pack+2',
          model3D: 'assets/models/pack.glb',
          baseCost: 15,
        ),
        Pack(
          id: 'pack_3',
          name: 'Pack Leggendario',
          description: 'Le carte più rare e potenti',
          image:
              'https://via.placeholder.com/200x280/45B7D1/FFFFFF?text=Pack+3',
          model3D: 'assets/models/pack.glb',
          baseCost: 20,
        ),
      ];
    }
  }
}
