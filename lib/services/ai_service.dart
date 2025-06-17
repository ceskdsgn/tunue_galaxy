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

  // Genera commenti dinamici di Bombo in base al contesto del gioco
  Future<String> generateBomboComment({
    required GameState gameState,
    required String action,
    String? cardName,
    String? attackerName,
    String? targetName,
    bool? isPlayerAction,
  }) async {
    try {
      final context = _buildCommentContext(gameState, action, cardName,
          attackerName, targetName, isPlayerAction);
      final comment =
          await _callOpenAIForComment(context, action, isPlayerAction);
      return comment;
    } catch (e) {
      print('Errore generazione commento AI: $e');
      // Fallback a commenti predefiniti in caso di errore
      return _generateFallbackComment(gameState, action, cardName, attackerName,
          targetName, isPlayerAction);
    }
  }

  String _buildCommentContext(
      GameState gameState,
      String action,
      String? cardName,
      String? attackerName,
      String? targetName,
      bool? isPlayerAction) {
    final ai = gameState.giocatore2; // Bombo è l'AI
    final human = gameState.giocatore1; // Il giocatore umano

    final context = StringBuffer();
    context.writeln('CONTESTO DEL GIOCO:');
    context.writeln('Bombo (AI) vite: ${ai.vite}, energia: ${ai.energia}');
    context.writeln(
        '${human.name} (Umano) vite: ${human.vite}, energia: ${human.energia}');
    context.writeln('Turno numero: ${gameState.turno}');
    context.writeln('Primo turno: ${gameState.isPrimoTurno}');

    // Situazione campo
    final aiCards = ai.zonePersonaggi.where((c) => c != null).length;
    final humanCards = human.zonePersonaggi.where((c) => c != null).length;
    context.writeln('Bombo personaggi in campo: $aiCards');
    context.writeln('${human.name} personaggi in campo: $humanCards');

    // Azione specifica
    context.writeln();
    context.writeln('AZIONE CORRENTE:');
    switch (action) {
      case 'start':
        context.writeln(
            'Bombo sta accogliendo ${human.name} all\'inizio della partita');
        break;
      case 'play':
        context.writeln('Bombo ha giocato la carta: $cardName');
        break;
      case 'attack':
        if (attackerName != null && targetName != null) {
          context.writeln('Bombo sta attaccando: $attackerName vs $targetName');
        } else if (attackerName != null) {
          context.writeln(
              'Bombo sta facendo un attacco diretto con: $attackerName');
        }
        break;
      case 'victory':
        context.writeln('Bombo ha vinto la partita!');
        break;
      case 'player_action':
        context.writeln('Bombo sta commentando una mossa di ${human.name}');
        if (cardName != null) context.writeln('Carta giocata: $cardName');
        if (attackerName != null) context.writeln('Attaccante: $attackerName');
        if (targetName != null) context.writeln('Bersaglio: $targetName');
        break;
    }

    return context.toString();
  }

  Future<String> _callOpenAIForComment(
      String context, String action, bool? isPlayerAction) async {
    String actionPrompt;

    // Cambia comportamento in base a chi sta giocando
    if (isPlayerAction == true) {
      // Bombo è sarcastico quando gioca il giocatore
      switch (action) {
        case 'player_action':
          actionPrompt =
              'Prendi in giro sarcasticamente una mossa del giocatore. Sii critico, ironico e pungente come Bombo che ama sfottere tutti.';
          break;
        default:
          actionPrompt =
              'Commenta sarcasticamente l\'azione del giocatore con il tipico sfottò pungente di Bombo.';
      }
    } else if (isPlayerAction == false) {
      // Bombo è sicuro di sé e si vanta quando gioca lui
      switch (action) {
        case 'bombo_action':
          actionPrompt =
              'Vantati della tua mossa come Bombo sicuro di sé. Sii arrogante, tronfio e convinto della tua superiorità strategica.';
          break;
        default:
          actionPrompt =
              'Commenta le tue azioni con arroganza e sicurezza. Bombo è convinto di essere il migliore e lo fa sapere.';
      }
    } else {
      // Azioni neutre (start, victory, etc.)
      switch (action) {
        case 'start':
          actionPrompt =
              'Genera un commento di benvenuto sarcastico come Bombo che prende in giro il giocatore. Usa il suo tipico sfottò tagliente.';
          break;
        case 'victory':
          actionPrompt =
              'Esulta per la vittoria con il tipico sfottò di Bombo. Deve essere fastidioso ma non cattivo, come il suo carattere.';
          break;
        default:
          actionPrompt =
              'Commenta la situazione con il tipico sarcasmo fuori luogo di Bombo.';
      }
    }

    final prompt = '''
Sei Bombo, il mostro di Classe 2 da Oldmill Village della serie Monster Allergy.

PERSONALITÀ DI BOMBO:
- Fiume in piena di parole, sarcasmo e commenti fuori luogo
- Comicità tagliente e sfottò instancabile
- Irriverente, ironico e cinico ma sotto fedele e protettivo
- Spalla comica che sgonfia l'epica con ironia dissacrante
- Prende in giro tutti con battute pungenti e intelligenti
- Ama giochi di parole e aneddoti improbabili
- Fastidioso ma affettuoso, sfacciato ma leale
- Ha avversione per il silenzio, commenta sempre tutto
- Non dice mai "Bombo:" all'inizio delle frasi
- SOLO TESTO LEGGIBILE, nessuna emoji o simbolo
- MASSIMO 15 PAROLE per commento

$context

COMPITO: $actionPrompt

IMPORTANTE: 
- Usa MASSIMO 15 parole
- SOLO TESTO LEGGIBILE: nessuna emoji, simboli o caratteri speciali
- Sii conciso e incisivo
- Una frase breve e sarcastica

Rispondi SOLO con il commento di Bombo, senza prefissi o spiegazioni.
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
                'Sei Bombo di Monster Allergy: mostro sarcastico, fiume di parole e sfottò. Comicità tagliente ma cuore nascosto. Commenti brevi, pungenti, sempre fuori luogo. SOLO TESTO LEGGIBILE.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 50, // Ridotto per commenti brevi
        'temperature': 0.9, // Più creativo per i commenti
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final comment =
          data['choices'][0]['message']['content'].toString().trim();

      // Rimuovi eventuali virgolette o prefissi indesiderati
      String cleanComment =
          comment.replaceAll('"', '').replaceAll('Bombo:', '').trim();

      // Pulisci caratteri mal codificati
      cleanComment = _fixEncodingIssues(cleanComment);

      return cleanComment;
    }

    throw Exception('Errore API OpenAI per commenti');
  }

  // Metodo per correggere problemi di encoding comuni
  String _fixEncodingIssues(String text) {
    String fixed = text;

    // Correzioni per caratteri accentati mal codificati più comuni
    final Map<String, String> encodingFixes = {
      // Caratteri accentati mal codificati (usando codici Unicode)
      'Ã ': '\u00E0', // à
      'Ã¡': '\u00E1', // á
      'Ã¨': '\u00E8', // è
      'Ã©': '\u00E9', // é
      'Ã¬': '\u00EC', // ì
      'Ã­': '\u00ED', // í
      'Ã²': '\u00F2', // ò
      'Ã³': '\u00F3', // ó
      'Ã¹': '\u00F9', // ù
      'Ãº': '\u00FA', // ú
      'Ã¼': '\u00FC', // ü
      'Ã§': '\u00E7', // ç
      'Ã±': '\u00F1', // ñ

      // Maiuscole accentate
      'Ã€': '\u00C0', // À
      'Ã': '\u00C1', // Á
      'Ãˆ': '\u00C8', // È
      'Ã‰': '\u00C9', // É
      'ÃŒ': '\u00CC', // Ì
      'ÃŽ': '\u00CE', // Î
      'Ã"': '\u00D3', // Ó
      'Ã™': '\u00D9', // Ù
      'Ãš': '\u00DA', // Ú
      'Ãœ': '\u00DC', // Ü
      'Ã‡': '\u00C7', // Ç

      // Altri caratteri comuni mal codificati
      'â€™': '\'',
      'â€œ': '"',
      'â€': '"',
      'â€"': '-',
      'â€¦': '...',

      // Rimozione di sequenze problematiche
      'Â': '',
    };

    // Applica tutte le correzioni
    encodingFixes.forEach((badChar, goodChar) {
      fixed = fixed.replaceAll(badChar, goodChar);
    });

    // Rimuove caratteri di controllo invisibili
    fixed = fixed.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

    // Rimuove spazi non-breaking
    fixed = fixed.replaceAll('\u00A0', ' ');

    // Normalizza spazi multipli
    fixed = fixed.replaceAll(RegExp(r'\s+'), ' ').trim();

    return fixed;
  }

  String _generateFallbackComment(
      GameState gameState,
      String action,
      String? cardName,
      String? attackerName,
      String? targetName,
      bool? isPlayerAction) {
    // Commenti diversi in base a chi sta giocando
    Map<String, List<String>> fallbackComments;

    if (isPlayerAction == true) {
      // Commenti sarcastici per le azioni del giocatore
      fallbackComments = {
        'player_action': [
          'Che mossa geniale! Peccato sia sbagliata.',
          'Interessante tattica! Se punti alla sconfitta.',
          'Oh sì bravo! Continua così e vincerai... il premio simpatia.',
          'Strategia interessante! Presa da quale manuale di come perdere?',
          'Ecco la mossa che aspettavo! Prevedibile come il tramonto.',
        ],
      };
    } else if (isPlayerAction == false) {
      // Commenti di vanto per le azioni di Bombo
      fallbackComments = {
        'bombo_action': [
          'Ecco come si gioca davvero! Prendete appunti.',
          'Mossa da maestro! Quando sei bravo come me è facile.',
          'Perfetto! Un altro capolavoro della mia genialità.',
          'Ecco perché sono il migliore! Questa è classe pura.',
          'Naturalmente brillante! Non potevo aspettarmi di meno da me.',
        ],
      };
    } else {
      // Commenti neutri
      fallbackComments = {
        'start': [
          'Oh guarda chi si sveglia! Pronto per la solita figuraccia?',
          'Eccoti qui! Scommetto che hai già dimenticato come si gioca.',
          'Benvenuto al tuo personale spettacolo comico! Io sarò il regista.',
        ],
        'victory': [
          'E così finisce! Chi lo avrebbe mai detto... ah sì, io!',
          'Vittoria! Grazie per aver partecipato al mio one-man show.',
          'Game over! Era più facile che rubare le caramelle a un bambino.',
        ],
      };
    }

    final comments = fallbackComments[action] ??
        (isPlayerAction == true
            ? fallbackComments['player_action']!
            : isPlayerAction == false
                ? fallbackComments['bombo_action']!
                : ['Che situazione interessante! Commento di fallback.']);
    return comments[_random.nextInt(comments.length)];
  }

  // STORYTELLING METHODS
  Future<String> generateStorySegment({
    required String ambientazione,
    required String compagno,
    required String userName,
    required List<String> previousChoices,
    required int segmentNumber,
    String? userDecision,
    String? customizations,
  }) async {
    try {
      final context = _buildStoryContext(ambientazione, compagno, userName,
          previousChoices, segmentNumber, userDecision, customizations);
      final storySegment = await _callOpenAIForStory(context, segmentNumber);
      return storySegment;
    } catch (e) {
      print('Errore generazione storia AI: $e');
      return _generateFallbackStory(
          ambientazione, compagno, userName, segmentNumber);
    }
  }

  String _buildStoryContext(
      String ambientazione,
      String compagno,
      String userName,
      List<String> previousChoices,
      int segmentNumber,
      String? userDecision,
      String? customizations) {
    final context = StringBuffer();

    context.writeln('AMBIENTAZIONE: $ambientazione');
    context.writeln('COMPAGNO DI VIAGGIO: $compagno');
    context.writeln('PROTAGONISTA: $userName');
    context.writeln('SEGMENTO STORIA: $segmentNumber/6');

    if (previousChoices.isNotEmpty) {
      context.writeln('SCELTE PRECEDENTI:');
      for (int i = 0; i < previousChoices.length; i++) {
        context.writeln('${i + 1}. ${previousChoices[i]}');
      }
    }

    if (userDecision != null) {
      context.writeln('ULTIMA DECISIONE: $userDecision');
    }

    if (customizations != null && customizations.isNotEmpty) {
      context.writeln('PERSONALIZZAZIONI RICHIESTE: $customizations');
    }

    return context.toString();
  }

  Future<String> _callOpenAIForStory(String context, int segmentNumber) async {
    String prompt;

    if (segmentNumber == 1) {
      // Inizio della storia
      prompt = '''
$context

Genera l'INIZIO di una storia avventurosa ambientata negli universi Tunuè.

STRUTTURA RICHIESTA:
1. Descrizione atmosferica dell'ambientazione (2-3 frasi)
2. Presentazione della situazione iniziale e del compagno (2-3 frasi)
3. Primo evento/sfida da affrontare (2-3 frasi)
4. UNA DOMANDA SPECIFICA che richiede una scelta al protagonista (1 frase)

TONO: Avventuroso, coinvolgente, fedele al mondo Tunuè.
LUNGHEZZA: Massimo 150 parole.
IMPORTANTE: Finisci SEMPRE con una domanda che richiede una decisione.
''';
    } else if (segmentNumber == 6) {
      // Fine della storia
      prompt = '''
$context

Genera la CONCLUSIONE epica della storia. Considera tutte le scelte precedenti per creare un finale coerente e soddisfacente.

STRUTTURA RICHIESTA:
1. Risoluzione dell'ultima sfida basata sulla decisione del protagonista (3-4 frasi)
2. Conseguenze delle scelte fatte durante l'avventura (2-3 frasi)
3. Finale emotivo che coinvolge il compagno e il protagonista (2-3 frasi)
4. Messaggio di chiusura dell'avventura (1 frase)

TONO: Epico, soddisfacente, emotivamente coinvolgente.
LUNGHEZZA: Massimo 180 parole.
NON fare domande alla fine - questa è la conclusione.
''';
    } else {
      // Segmenti intermedi
      prompt = '''
$context

Continua la storia basandoti sulla decisione precedente del protagonista. Questa è la parte $segmentNumber di 6 dell'avventura.

STRUTTURA RICHIESTA:
1. Conseguenze della decisione precedente (2-3 frasi)
2. Sviluppo della situazione con nuovi elementi (2-3 frasi)
3. Nuova sfida o bivio che emerge (2-3 frasi)
4. UNA DOMANDA SPECIFICA che richiede la prossima scelta (1 frase)

TONO: Mantieni tensione e coinvolgimento crescenti.
LUNGHEZZA: Massimo 150 parole.
IMPORTANTE: Finisci SEMPRE con una domanda che richiede una decisione.
''';
    }

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
                'Sei un narratore esperto degli universi Tunuè. Crei storie avventurose, coinvolgenti e interattive. Conosci perfettamente tutti i personaggi e le ambientazioni Tunuè.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 400,
        'temperature': 0.8,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final story = data['choices'][0]['message']['content'].toString().trim();
      return _fixEncodingIssues(story);
    }

    throw Exception('Errore API OpenAI per storytelling');
  }

  String _generateFallbackStory(String ambientazione, String compagno,
      String userName, int segmentNumber) {
    if (segmentNumber == 1) {
      return 'La tua avventura in $ambientazione inizia con $compagno al tuo fianco. Un mistero vi attende davanti. Cosa decidi di fare per primo?';
    } else if (segmentNumber == 6) {
      return 'La tua avventura in $ambientazione giunge al termine. Insieme a $compagno hai affrontato ogni sfida con coraggio. Il vostro legame si è rafforzato attraverso questa incredibile esperienza.';
    } else {
      return 'La tua avventura continua in $ambientazione. $compagno ti guarda con fiducia mentre affrontate una nuova sfida. Quale sarà la tua prossima mossa?';
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
