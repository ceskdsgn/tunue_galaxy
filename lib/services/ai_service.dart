import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/card_game.dart';
import 'card_game_service.dart';

class AIService {
  final Random _random = Random();

  // Regolamento del gioco per l'AI
  static const String _gameRules = '''
REGOLAMENTO GIOCO DI CARTE TUNUÉ

OBIETTIVO: Ridurre le vite dell'avversario a 0.

SETUP:
- Ogni giocatore inizia con 3 vite e 2 energie
- Mazzo di 20 carte, mano iniziale di 4 carte
- 3 zone personaggi, 2 zone interazioni, 1 zona ambientazione condivisa

TIPI DI CARTE:
1. PERSONAGGI: Hanno forza d'attacco, possono attaccare
2. AMBIENTAZIONI: Effetti passivi globali
3. INTERAZIONI: Effetti immediati o permanenti

FASI DEL TURNO:
1. ENERGIA: +1 energia (dal 2° turno)
2. PESCA: Pesca 1 carta
3. PRINCIPALE: Gioca carte pagando energia
4. ATTACCO: Attacca con personaggi (dal 2° turno)
5. FINE: Passa il turno

COMBATTIMENTO:
- Personaggi possono attaccare altri personaggi o direttamente le vite
- Se l'avversario ha personaggi in campo, DEVI attaccare i personaggi (non puoi attaccare direttamente)
- Se l'avversario NON ha personaggi in campo, puoi attaccare direttamente le vite
- Forza maggiore vince, pareggio = entrambi distrutti

CARTE SPECIALI:
- Elena: +1 forza se controlli Zick, immune agli effetti se controlli Zick
- Ambientazioni: Effetti che modificano il gioco
- Interazioni: Alcune richiedono condizioni specifiche
''';

  Future<AIDecision> makeDecision(
      GameState gameState, GamePhase currentPhase) async {
    try {
      // Prepara il contesto di gioco per l'AI
      final gameContext = _buildGameContext(gameState, currentPhase);

      // Chiama l'API OpenAI
      final decision = await _callOpenAI(gameContext);

      return decision;
    } catch (e) {
      print('Errore AI: $e');
      // Fallback a decisioni casuali se l'API fallisce
      return _makeFallbackDecision(gameState, currentPhase);
    }
  }

  String _buildGameContext(GameState gameState, GamePhase currentPhase) {
    // L'AI è sempre giocatore2, l'umano è sempre giocatore1
    final ai = gameState.giocatore2; // L'AI è sempre giocatore2
    final human = gameState.giocatore1; // L'umano è sempre giocatore1

    final context = StringBuffer();
    context.writeln('STATO ATTUALE DEL GIOCO:');
    context.writeln('Turno: ${gameState.turno}');
    context.writeln('Fase: ${_phaseToString(currentPhase)}');
    context.writeln('Primo turno: ${gameState.isPrimoTurno}');
    context.writeln();

    context.writeln('TUE INFORMAZIONI (AI):');
    context.writeln('Vite: ${ai.vite}');
    context.writeln('Energia: ${ai.energia}');
    context.writeln('Carte in mano: ${ai.mano.length}');
    context.writeln(
        'Mano: ${ai.mano.map((c) => '${c.name}(${c.cost}E${c is PersonaggioCard ? ',${c.forza}F' : ''})').join(', ')}');
    context.writeln(
        'Personaggi in campo: ${ai.zonePersonaggi.where((p) => p != null).map((p) => '${p!.name}(${p.forza}F)').join(', ')}');
    context.writeln(
        'Interazioni in campo: ${ai.zoneInterazioni.where((i) => i != null).map((i) => i!.name).join(', ')}');
    context.writeln();

    context.writeln('INFORMAZIONI AVVERSARIO:');
    context.writeln('Vite: ${human.vite}');
    context.writeln('Energia: ${human.energia}');
    context.writeln('Carte in mano: ${human.mano.length}');
    context.writeln(
        'Personaggi in campo: ${human.zonePersonaggi.where((p) => p != null).map((p) => '${p!.name}(${p.forza}F)').join(', ')}');
    context.writeln(
        'Interazioni in campo: ${human.zoneInterazioni.where((i) => i != null).map((i) => i!.name).join(', ')}');
    context.writeln();

    if (gameState.ambientazioneAttiva != null) {
      context.writeln(
          'AMBIENTAZIONE ATTIVA: ${gameState.ambientazioneAttiva!.name}');
      context.writeln();
    }

    return context.toString();
  }

  Future<AIDecision> _callOpenAI(String gameContext) async {
    final prompt = '''
$_gameRules

$gameContext

Come AI, devi decidere la prossima azione. Rispondi SOLO con un JSON nel seguente formato:
{
  "action": "PLAY_CARD|ATTACK|NEXT_PHASE",
  "cardName": "nome carta da giocare (se action=PLAY_CARD)",
  "attackerIndex": "indice attaccante (se action=ATTACK)",
  "targetIndex": "indice bersaglio o null per attacco diretto (se action=ATTACK)",
  "reasoning": "breve spiegazione della strategia"
}

Priorità strategiche:
1. Sopravvivenza: Difendi se hai poche vite
2. Controllo campo: Mantieni personaggi in campo
3. Efficienza energia: Non sprecare energia
4. Pressione: Attacca quando hai vantaggio
5. Vittoria: Cerca di ridurre le vite avversarie a 0
''';

    final response = await http.post(
      Uri.parse(ApiConfig.openAIBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.openAIApiKey}',
      },
      body: jsonEncode({
        'model': ApiConfig.openAIModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'Sei un\'AI esperta nel gioco di carte Tunué. Rispondi sempre con JSON valido.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': ApiConfig.maxTokens,
        'temperature': ApiConfig.temperature,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Estrai il JSON dalla risposta
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final decisionJson = jsonDecode(jsonMatch.group(0)!);
        return AIDecision.fromJson(decisionJson);
      }
    }

    throw Exception('Risposta API non valida');
  }

  AIDecision _makeFallbackDecision(
      GameState gameState, GamePhase currentPhase) {
    final ai = gameState.giocatore2; // L'AI è sempre giocatore2

    switch (currentPhase) {
      case GamePhase.principale:
        // Prova a giocare una carta casuale se possibile
        final playableCards = ai.mano
            .where((card) =>
                ai.energia >= card.cost && _canPlayCard(card, gameState))
            .toList();

        if (playableCards.isNotEmpty) {
          final randomCard =
              playableCards[_random.nextInt(playableCards.length)];
          return AIDecision(
              action: AIAction.playCard,
              cardName: randomCard.name,
              reasoning: 'Decisione casuale di fallback');
        }
        break;

      case GamePhase.attacco:
        // Attacca con un personaggio casuale se possibile
        final attackers = ai.zonePersonaggi
            .asMap()
            .entries
            .where((entry) => entry.value != null)
            .toList();

        if (attackers.isNotEmpty && !gameState.isPrimoTurno) {
          final randomAttacker = attackers[_random.nextInt(attackers.length)];

          // Se l'avversario ha personaggi in campo, deve attaccare uno di quelli
          final human = gameState.giocatore1;
          if (human.haPersonaggiInCampo) {
            final defenders = human.zonePersonaggi
                .asMap()
                .entries
                .where((entry) => entry.value != null)
                .toList();

            if (defenders.isNotEmpty) {
              final randomDefender =
                  defenders[_random.nextInt(defenders.length)];
              return AIDecision(
                  action: AIAction.attack,
                  attackerIndex: randomAttacker.key,
                  targetIndex: randomDefender.key,
                  reasoning: 'Attacco personaggio nemico (fallback)');
            }
          } else {
            // Solo se non ci sono personaggi nemici, attacco diretto
            return AIDecision(
                action: AIAction.attack,
                attackerIndex: randomAttacker.key,
                targetIndex: null, // Attacco diretto
                reasoning: 'Attacco diretto (fallback)');
          }
        }
        break;

      default:
        break;
    }

    // Default: passa alla fase successiva
    return AIDecision(
        action: AIAction.nextPhase, reasoning: 'Passa alla fase successiva');
  }

  bool _canPlayCard(GameCard card, GameState gameState) {
    final ai = gameState.giocatore2; // L'AI è sempre giocatore2

    if (card is PersonaggioCard) {
      return ai.hasSpaceForPersonaggio;
    } else if (card is InterazioneCard) {
      return ai.hasSpaceForInterazione;
    } else if (card is AmbientazioneCard) {
      return true; // Può sempre giocare ambientazioni
    }

    return false;
  }

  String _phaseToString(GamePhase phase) {
    switch (phase) {
      case GamePhase.energia:
        return 'Energia';
      case GamePhase.pesca:
        return 'Pesca';
      case GamePhase.principale:
        return 'Principale';
      case GamePhase.attacco:
        return 'Attacco';
      case GamePhase.fine:
        return 'Fine';
    }
  }
}

enum AIAction { playCard, attack, nextPhase }

class AIDecision {
  final AIAction action;
  final String? cardName;
  final int? attackerIndex;
  final int? targetIndex;
  final String reasoning;

  AIDecision({
    required this.action,
    this.cardName,
    this.attackerIndex,
    this.targetIndex,
    required this.reasoning,
  });

  factory AIDecision.fromJson(Map<String, dynamic> json) {
    AIAction action;
    switch (json['action']) {
      case 'PLAY_CARD':
        action = AIAction.playCard;
        break;
      case 'ATTACK':
        action = AIAction.attack;
        break;
      default:
        action = AIAction.nextPhase;
    }

    return AIDecision(
      action: action,
      cardName: json['cardName'],
      attackerIndex: json['attackerIndex'],
      targetIndex: json['targetIndex'],
      reasoning: json['reasoning'] ?? 'Nessuna spiegazione',
    );
  }
}
