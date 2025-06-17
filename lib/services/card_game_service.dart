import '../data/monster_allergy_cards.dart';
import '../models/card_game.dart';
import 'ai_service.dart';

enum GamePhase { energia, pesca, principale, attacco, fine }

class CardGameService {
  GameState? _gameState;
  GamePhase _currentPhase = GamePhase.energia;
  final AIService _aiService = AIService();
  bool _isAIGame = false;
  bool _isAITurn = false;

  // Traccia quali personaggi hanno già attaccato questo turno
  final Set<String> _attackedThisTurn = {};

  // Callback per notificare l'UI degli effetti
  Function(String)? onEffectActivated;

  // Callback specifico per l'animazione dell'energia
  Function()? onEnergyAdded;

  // Callback per le azioni dell'AI
  Function(String)? onAIAction;

  // Callback per le azioni del giocatore umano
  Function(String)? onPlayerAction;

  // Callback per quando viene pescata una carta
  Function(GameCard, bool)? onCardDrawn;

  GameState? get gameState => _gameState;
  GamePhase get currentPhase => _currentPhase;
  bool get isAIGame => _isAIGame;
  bool get isAITurn => _isAITurn;

  // Controlla se un personaggio ha già attaccato questo turno
  bool hasAttackedThisTurn(String personaggioId) {
    return _attackedThisTurn.contains(personaggioId);
  }

  void iniziaPartitaVsAI(Player giocatoreUmano) {
    // Crea il giocatore AI
    final aiPlayer = Player(
      name: 'Bombo',
      mazzo: List.from(MonsterAllergyCards.createDefaultDeck()),
    );

    _isAIGame = true;
    // Assicurati che l'umano sia sempre giocatore1 e l'AI sia giocatore2
    iniziaPartita(giocatoreUmano, aiPlayer);
  }

  void iniziaPartita(Player giocatore1, Player giocatore2) {
    // Mischia i mazzi
    giocatore1.mischiaMazzo();
    giocatore2.mischiaMazzo();

    // Imposta energia iniziale a 2
    giocatore1.energia = 2;
    giocatore2.energia = 2;

    // Pesca mano iniziale (4 carte)
    for (int i = 0; i < 4; i++) {
      giocatore1.pescaCarta();
      giocatore2.pescaCarta();
    }

    _gameState = GameState(
      giocatore1: giocatore1,
      giocatore2: giocatore2,
    );

    print('DEBUG: Partita iniziata');
    print('DEBUG: Giocatore1: ${giocatore1.name}');
    print('DEBUG: Giocatore2: ${giocatore2.name}');
    print('DEBUG: Giocatore attivo: ${_gameState!.giocatoreAttivo.name}');
    print('DEBUG: È partita AI: $_isAIGame');

    // Inizia dalla fase energia, il giocatore umano controlla manualmente le fasi
    _currentPhase = GamePhase.energia;

    // Se è una partita AI e il primo giocatore è l'AI, inizia automaticamente
    if (_isAIGame) {
      _isAITurn = _gameState!.giocatoreAttivo.name == 'Bombo';
      print('DEBUG: È turno AI: $_isAITurn');
      if (_isAITurn) {
        iniziaTurno();
        _executeAITurn();
      } else {
        // Se è il turno del giocatore umano, inizia anche il suo turno
        print('DEBUG: Iniziando turno giocatore umano all\'inizio');
        iniziaTurno();
      }
    }
  }

  void iniziaTurno() {
    if (_gameState == null) return;

    print('DEBUG: Iniziando turno per ${_gameState!.giocatoreAttivo.name}');

    // Reset degli attacchi del turno precedente
    _attackedThisTurn.clear();

    // Fase Energia: +1 energia (solo dal secondo turno)
    if (!_gameState!.isPrimoTurno) {
      _gameState!.giocatoreAttivo.energia++;
      print(
          'DEBUG: Energia aggiunta, totale: ${_gameState!.giocatoreAttivo.energia}');
      // Notifica l'UI per l'animazione dell'energia
      onEnergyAdded?.call();
    }

    // Fase Pesca: pesca 1 carta automaticamente (solo dal secondo turno)
    if (!_gameState!.isPrimoTurno) {
      final giocatore = _gameState!.giocatoreAttivo;
      final isPlayerTurn = giocatore.name != 'Bombo';

      // Memorizza la carta prima di pescarla per il callback
      GameCard? cartaPescata;
      if (giocatore.mazzo.isNotEmpty) {
        cartaPescata = giocatore.mazzo.first;
      }

      giocatore.pescaCarta();

      // Chiama il callback per l'animazione della carta pescata
      if (cartaPescata != null) {
        onCardDrawn?.call(cartaPescata, isPlayerTurn);
      }

      print('DEBUG: Carta pescata, carte in mano: ${giocatore.mano.length}');
    } else {
      print('DEBUG: Primo turno - pesca saltata');
    }

    // Vai direttamente alla fase principale
    _currentPhase = GamePhase.principale;
    print('DEBUG: Fase impostata a: $_currentPhase');
  }

  void pescaFase() {
    if (_gameState == null || _currentPhase != GamePhase.energia) return;

    // Fase Pesca: pesca 1 carta
    _gameState!.giocatoreAttivo.pescaCarta();
    _currentPhase = GamePhase.pesca;
  }

  void fasePrincipale() {
    if (_gameState == null || _currentPhase != GamePhase.pesca) return;
    _currentPhase = GamePhase.principale;
  }

  bool puoiGiocareCarta(GameCard carta) {
    if (_gameState == null || _currentPhase != GamePhase.principale)
      return false;

    final giocatore = _gameState!.giocatoreAttivo;

    // Verifica energia (con costo effettivo che considera effetti ambientazione)
    final costoEffettivo = _calcolaCostoEffettivo(carta);
    if (giocatore.energia < costoEffettivo) return false;

    // Verifica spazio nel campo
    if (carta is PersonaggioCard && !giocatore.hasSpaceForPersonaggio)
      return false;
    if (carta is InterazioneCard && !giocatore.hasSpaceForInterazione)
      return false;

    // Verifica condizioni speciali per carte interazione
    if (carta is InterazioneCard) {
      switch (carta.name) {
        case "Lotta Marina":
          // "Puoi giocare questa carta soltanto se in campo è presente 1 Carta Ambientazione"
          if (_gameState!.ambientazioneAttiva == null) return false;
          break;

        case "Lavoro di Squadra":
          // "Puoi giocare questa carta soltanto se controlli 1 Carta Personaggio "Zick" o "Elena""
          final controllaZickOElena = giocatore.zonePersonaggi.any(
              (personaggio) =>
                  personaggio != null &&
                  (personaggio.name == "Zick" || personaggio.name == "Elena"));
          if (!controllaZickOElena) return false;
          break;
      }
    }

    return true;
  }

  bool giocaCarta(GameCard carta) {
    if (!puoiGiocareCarta(carta)) return false;

    final giocatore = _gameState!.giocatoreAttivo;
    final isPlayerAction = giocatore.name != 'Bombo';

    // Rimuovi carta dalla mano e paga energia (costo effettivo)
    final costoEffettivo = _calcolaCostoEffettivo(carta);
    giocatore.mano.remove(carta);
    giocatore.energia -= costoEffettivo;

    // Gioca la carta
    if (carta is PersonaggioCard) {
      giocatore.addPersonaggioToField(carta);
      _applicaEffettoPersonaggio(carta);
    } else if (carta is AmbientazioneCard) {
      _gameState!.cambiaAmbientazione(carta);
      _applicaEffettoAmbientazione(carta);
    } else if (carta is InterazioneCard) {
      giocatore.addInterazioneToField(carta);
      _applicaEffettoInterazione(carta);
    }

    // Chiamata al callback DOPO che l'azione è stata eseguita
    if (isPlayerAction) {
      onPlayerAction?.call('Giocatore gioca "${carta.name}"');
    }

    return true;
  }

  // Nuovo metodo per giocare una carta in una posizione specifica
  bool giocaCartaInPosizione(GameCard carta, int targetIndex) {
    if (!puoiGiocareCarta(carta)) return false;

    final giocatore = _gameState!.giocatoreAttivo;
    final isPlayerAction = giocatore.name != 'Bombo';

    // Rimuovi carta dalla mano e paga energia (costo effettivo)
    final costoEffettivo = _calcolaCostoEffettivo(carta);
    giocatore.mano.remove(carta);
    giocatore.energia -= costoEffettivo;

    // Gioca la carta nella posizione specifica
    if (carta is PersonaggioCard) {
      giocatore.addPersonaggioToSpecificPosition(carta, targetIndex);
      _applicaEffettoPersonaggio(carta);
    } else if (carta is AmbientazioneCard) {
      _gameState!.cambiaAmbientazione(carta);
      _applicaEffettoAmbientazione(carta);
    } else if (carta is InterazioneCard) {
      giocatore.addInterazioneToSpecificPosition(carta, targetIndex);
      _applicaEffettoInterazione(carta);
    }

    // Chiamata al callback DOPO che l'azione è stata eseguita
    if (isPlayerAction) {
      onPlayerAction?.call('Giocatore gioca "${carta.name}"');
    }

    return true;
  }

  void faseAttacco() {
    if (_gameState == null || _currentPhase != GamePhase.principale) return;

    // Se è il primo turno, salta la fase di attacco e vai direttamente alla fine turno
    if (_gameState!.isPrimoTurno) {
      fineTurno();
      return;
    }

    _currentPhase = GamePhase.attacco;
  }

  bool puoiAttaccare(int indexPersonaggio) {
    if (_gameState == null ||
        (_currentPhase != GamePhase.attacco &&
            _currentPhase != GamePhase.principale)) return false;
    if (_gameState!.isPrimoTurno) return false;

    final personaggio =
        _gameState!.giocatoreAttivo.zonePersonaggi[indexPersonaggio];
    if (personaggio == null) return false;

    // Controlla se il personaggio ha già attaccato questo turno
    if (_attackedThisTurn.contains(personaggio.id)) return false;

    return true;
  }

  void attaccaConPersonaggio(int indexAttaccante, int? indexDifensore) {
    if (!puoiAttaccare(indexAttaccante)) return;

    final attaccante =
        _gameState!.giocatoreAttivo.zonePersonaggi[indexAttaccante]!;
    final avversario = _gameState!.avversario;
    final isPlayerAction = _gameState!.giocatoreAttivo.name != 'Bombo';

    // Marca il personaggio come "ha attaccato questo turno"
    _attackedThisTurn.add(attaccante.id);

    String attackMessage;
    if (indexDifensore != null &&
        avversario.zonePersonaggi[indexDifensore] != null) {
      // Attacco contro un personaggio
      final difensore = avversario.zonePersonaggi[indexDifensore]!;
      attackMessage = 'attacca: ${attaccante.name} vs ${difensore.name}';
      _risolviScontro(attaccante, difensore, indexAttaccante, indexDifensore);
    } else if (!avversario.haPersonaggiInCampo) {
      // Attacco diretto alle vite SOLO se l'avversario non ha personaggi in campo
      avversario.vite--;
      attackMessage = 'attacca direttamente con ${attaccante.name}';
    } else {
      attackMessage = 'attacca con ${attaccante.name}';
    }

    // Chiamata al callback DOPO che l'azione è stata eseguita
    if (isPlayerAction) {
      onPlayerAction?.call('Giocatore $attackMessage');
    }
  }

  void _risolviScontro(PersonaggioCard attaccante, PersonaggioCard difensore,
      int indexAttaccante, int indexDifensore) {
    final forzaAttaccante =
        _calcolaForzaPersonaggio(attaccante, _gameState!.giocatoreAttivo);
    final forzaDifensore =
        _calcolaForzaPersonaggio(difensore, _gameState!.avversario);

    if (forzaAttaccante > forzaDifensore) {
      // Attaccante vince
      _gameState!.avversario.removePersonaggioFromField(indexDifensore);
      onEffectActivated
          ?.call("${attaccante.name} distrugge ${difensore.name}!");
    } else if (forzaDifensore > forzaAttaccante) {
      // Difensore vince
      _gameState!.giocatoreAttivo.removePersonaggioFromField(indexAttaccante);
      onEffectActivated
          ?.call("${difensore.name} distrugge ${attaccante.name}!");
    } else {
      // Pareggio - entrambi distrutti
      _gameState!.avversario.removePersonaggioFromField(indexDifensore);
      _gameState!.giocatoreAttivo.removePersonaggioFromField(indexAttaccante);
      onEffectActivated?.call(
          "${attaccante.name} e ${difensore.name} si distruggono a vicenda!");
    }
  }

  int _calcolaForzaPersonaggio(
      PersonaggioCard personaggio, Player proprietario) {
    int forza = personaggio.forza;

    // Effetto speciale di Elena: +1 Forza se controlli Zick
    if (personaggio.name == "Elena") {
      final controllaZick = proprietario.zonePersonaggi
          .any((carta) => carta != null && carta.name == "Zick");
      if (controllaZick) {
        forza += 1;
      }
    }

    // Applica effetti ambientazione
    if (_gameState!.ambientazioneAttiva != null) {
      forza += _calcolaModificatoreAmbientazione(personaggio, proprietario);
    }

    // Applica effetti interazioni
    for (var interazione in proprietario.zoneInterazioni) {
      if (interazione != null) {
        forza += _calcolaModificatoreInterazione(personaggio, interazione);
      }
    }

    return forza;
  }

  int _calcolaModificatoreAmbientazione(
      PersonaggioCard personaggio, Player proprietario) {
    final ambientazione = _gameState!.ambientazioneAttiva!;

    if (ambientazione.name == "Città dei Mostri" &&
        personaggio.series == CardSeries.monsterAllergy) {
      return 1; // +1 Forza per personaggi Monster Allergy
    }

    return 0;
  }

  // Calcola il costo effettivo di una carta considerando gli effetti ambientazione
  int _calcolaCostoEffettivo(GameCard carta) {
    int costo = carta.cost;

    // Applica effetti ambientazione
    if (_gameState!.ambientazioneAttiva != null) {
      final ambientazione = _gameState!.ambientazioneAttiva!;

      // Casa di Zick: "Le Carte Personaggio di Monster Allergy costano 1 Energia in meno per essere giocate"
      if (ambientazione.name == "Casa di Zick" &&
          carta is PersonaggioCard &&
          carta.series == CardSeries.monsterAllergy) {
        costo -= 1;
      }
    }

    // Il costo non può mai essere minore di 0
    return costo < 0 ? 0 : costo;
  }

  int _calcolaModificatoreInterazione(
      PersonaggioCard personaggio, InterazioneCard interazione) {
    // Implementa logica specifica per ogni interazione
    return 0;
  }

  void _applicaEffettoPersonaggio(PersonaggioCard carta) {
    // Solo mostra gli effetti se è il giocatore umano a giocare la carta
    final isHumanPlayer = _gameState!.giocatoreAttivo.name != 'Bombo';

    // Implementa gli effetti specifici dei personaggi
    switch (carta.name) {
      case "Zick":
        _effettoZick(isHumanPlayer);
        break;
      case "Timothy Moth":
        _effettoTimothy(isHumanPlayer);
        break;
      case "Bombo":
        _effettoBombo(isHumanPlayer);
        break;
      case "Magnacat":
        _effettoMagnacat(isHumanPlayer);
        break;
    }
  }

  void _applicaEffettoAmbientazione(AmbientazioneCard carta) {
    // Gli effetti ambientazione sono applicati passivamente
    // Mostra messaggio di attivazione solo se è il giocatore umano a giocare la carta
    final isHumanPlayer = _gameState!.giocatoreAttivo.name != 'Bombo';

    if (isHumanPlayer) {
      switch (carta.name) {
        case "Casa di Zick":
          onEffectActivated?.call(
              "Casa di Zick attiva: I personaggi Monster Allergy costano 1 energia in meno!");
          break;
        case "Città dei Mostri":
          onEffectActivated?.call(
              "Città dei Mostri attiva: I personaggi Monster Allergy ottengono +1 Forza!");
          break;
      }
    }
  }

  void _applicaEffettoInterazione(InterazioneCard carta) {
    // Solo mostra gli effetti se è il giocatore umano a giocare la carta
    final isHumanPlayer = _gameState!.giocatoreAttivo.name != 'Bombo';

    // Implementa gli effetti specifici delle interazioni
    switch (carta.name) {
      case "A caccia di mostri":
        _effettoCacciaMostri(isHumanPlayer);
        break;
      case "Lotta Marina":
        _effettoLottaMarina(isHumanPlayer);
        break;
      case "Lavoro di Squadra":
        _effettoLavoroSquadra(isHumanPlayer);
        break;
      case "Fame Carnivora":
        _effettoFameCarnivora(isHumanPlayer);
        break;
      case "In un mare di guai":
        _effettoMareGuai(isHumanPlayer);
        break;
      case "Ritirata":
        _effettoRitirata(isHumanPlayer);
        break;
    }
  }

  void _effettoZick(bool showEffect) {
    // "Quando entra in campo, guarda la carta in cima al mazzo dell'avversario"
    final avversario = _gameState!.avversario;
    if (avversario.mazzo.isNotEmpty) {
      // In una UI reale si mostrerebbe la carta al giocatore
      // Per ora registriamo l'effetto come attivato solo se è il giocatore umano
      if (showEffect) {
        onEffectActivated?.call(
            "Zick: Carta in cima al mazzo avversario è ${avversario.mazzo.first.name}!");
      }
    } else {
      if (showEffect) {
        onEffectActivated?.call("Zick: Il mazzo avversario è vuoto!");
      }
    }
  }

  void _effettoTimothy(bool showEffect) {
    // "Quando entra in campo, guarda la mano dell'avversario"
    final avversario = _gameState!.avversario;
    if (avversario.mano.isNotEmpty) {
      // In una UI reale si mostrerebbe la mano al giocatore
      if (showEffect) {
        String carteInMano =
            avversario.mano.map((carta) => carta.name).join(", ");
        onEffectActivated
            ?.call("Timothy: Mano avversario contiene: $carteInMano");
      }
    } else {
      if (showEffect) {
        onEffectActivated?.call("Timothy: L'avversario non ha carte in mano!");
      }
    }
  }

  void _effettoBombo(bool showEffect) {
    // "Quando entra in campo, pesca 1 carta dal tuo mazzo o dal mazzo dell'avversario"
    final giocatore = _gameState!.giocatoreAttivo;
    final avversario = _gameState!.avversario;

    // Per ora pesca sempre dal proprio mazzo se possibile, altrimenti dall'avversario
    if (giocatore.mazzo.isNotEmpty) {
      final cartaPescata = giocatore.mazzo.first;
      giocatore.pescaCarta();
      if (showEffect) {
        onEffectActivated?.call("Pescata ${cartaPescata.name} dal tuo mazzo!");
      }
    } else if (avversario.mazzo.isNotEmpty) {
      final cartaPescata = avversario.mazzo.removeAt(0);
      giocatore.mano.add(cartaPescata);
      if (showEffect) {
        onEffectActivated
            ?.call("Pescata ${cartaPescata.name} dal mazzo avversario!");
      }
    } else {
      if (showEffect) {
        onEffectActivated?.call("Nessun mazzo disponibile per pescare!");
      }
    }
  }

  bool _isImmuneToOpponentEffects(
      PersonaggioCard personaggio, Player proprietario) {
    // Elena è immune agli effetti delle carte avversarie se controlli Zick
    if (personaggio.name == "Elena") {
      final controllaZick = proprietario.zonePersonaggi
          .any((carta) => carta != null && carta.name == "Zick");
      return controllaZick;
    }
    return false;
  }

  void _effettoMagnacat(bool showEffect) {
    // "Quando entra in campo, distruggi/aggiungi alla tua mano/prendi il controllo di 1 Carta dell'avversario"
    final avversario = _gameState!.avversario;
    final giocatore = _gameState!.giocatoreAttivo;

    bool cartaTrovata = false;

    // Cerca la prima carta controllabile dall'avversario (che non sia immune)
    for (int i = 0; i < avversario.zonePersonaggi.length; i++) {
      if (avversario.zonePersonaggi[i] != null) {
        final cartaTarget = avversario.zonePersonaggi[i]!;

        // Controlla se la carta è immune agli effetti
        if (_isImmuneToOpponentEffects(cartaTarget, avversario)) {
          continue; // Salta questa carta se è immune
        }

        // Per ora aggiungiamo alla mano (effetto più semplice da gestire)
        avversario.removePersonaggioFromField(i);
        giocatore.mano.add(cartaTarget);
        if (showEffect) {
          onEffectActivated?.call(
              "Magnacat: ${cartaTarget.name} rubato dal campo avversario!");
        }
        cartaTrovata = true;
        break;
      }
    }

    // Se non ci sono personaggi validi, prova con le interazioni
    if (!cartaTrovata &&
        avversario.zonePersonaggi.every(
            (c) => c == null || (_isImmuneToOpponentEffects(c, avversario)))) {
      for (int i = 0; i < avversario.zoneInterazioni.length; i++) {
        if (avversario.zoneInterazioni[i] != null) {
          final cartaTarget = avversario.zoneInterazioni[i]!;
          avversario.zoneInterazioni[i] = null;
          giocatore.mano.add(cartaTarget);
          if (showEffect) {
            onEffectActivated?.call(
                "Magnacat: ${cartaTarget.name} rubato dalle interazioni avversarie!");
          }
          cartaTrovata = true;
          break;
        }
      }
    }

    if (!cartaTrovata) {
      if (showEffect) {
        onEffectActivated?.call(
            "Magnacat: Nessuna carta rubabile trovata nel campo avversario!");
      }
    }
  }

  void _effettoCacciaMostri(bool showEffect) {
    // "Aggiungi 1 Carta Personaggio "Zick" o "Elena" dal tuo mazzo o cimitero alla tua mano."
    final giocatore = _gameState!.giocatoreAttivo;

    // Cerca prima nel mazzo
    final cartaDalMazzo = giocatore.mazzo
        .where((carta) =>
            carta is PersonaggioCard &&
            (carta.name == "Zick" || carta.name == "Elena"))
        .toList();

    if (cartaDalMazzo.isNotEmpty) {
      final cartaScelta = cartaDalMazzo.first;
      giocatore.mazzo.remove(cartaScelta);
      giocatore.mano.add(cartaScelta);
      giocatore.mischiaMazzo();
      if (showEffect) {
        onEffectActivated?.call(
            "A caccia di mostri: ${cartaScelta.name} aggiunto alla mano dal mazzo!");
      }
      return;
    }

    // Se non trovata nel mazzo, cerca nel cimitero
    final cartaDalCimitero = giocatore.cimitero
        .where((carta) =>
            carta is PersonaggioCard &&
            (carta.name == "Zick" || carta.name == "Elena"))
        .toList();

    if (cartaDalCimitero.isNotEmpty) {
      final cartaScelta = cartaDalCimitero.first;
      giocatore.cimitero.remove(cartaScelta);
      giocatore.mano.add(cartaScelta);
      if (showEffect) {
        onEffectActivated?.call(
            "A caccia di mostri: ${cartaScelta.name} aggiunto alla mano dal cimitero!");
      }
    } else {
      if (showEffect) {
        onEffectActivated
            ?.call("A caccia di mostri: Nessun Zick o Elena trovato!");
      }
    }
  }

  void _effettoLottaMarina(bool showEffect) {
    // "Puoi giocare questa carta soltanto se in campo è presente 1 Carta Ambientazione; distruggila. Puoi aggiungere 1 Carta Ambientazione dal tuo mazzo alla mano."
    if (_gameState!.ambientazioneAttiva != null) {
      final nomeAmbientazione = _gameState!.ambientazioneAttiva!.name;
      // Distruggi l'ambientazione attiva
      _gameState!.ambientazioneAttiva = null;
      if (showEffect) {
        onEffectActivated?.call("Lotta Marina: $nomeAmbientazione distrutto!");
      }

      // Cerca una carta ambientazione nel mazzo
      final giocatore = _gameState!.giocatoreAttivo;
      final ambientazioneDalMazzo =
          giocatore.mazzo.whereType<AmbientazioneCard>().toList();

      if (ambientazioneDalMazzo.isNotEmpty) {
        final nuovaAmbientazione = ambientazioneDalMazzo.first;
        giocatore.mazzo.remove(nuovaAmbientazione);
        giocatore.mano.add(nuovaAmbientazione);
        giocatore.mischiaMazzo();
        if (showEffect) {
          onEffectActivated?.call(
              "Lotta Marina: ${nuovaAmbientazione.name} aggiunto alla mano!");
        }
      }
    }
  }

  void _effettoLavoroSquadra(bool showEffect) {
    // "Puoi giocare questa carta soltanto se controlli 1 Carta Personaggio "Zick" o "Elena". Gioca (direttamente dal tuo mazzo, senza pagarne il costo) 1 Carta Personaggio "Zick" o "Elena"."
    final giocatore = _gameState!.giocatoreAttivo;

    // Verifica che controlli Zick o Elena
    final controllaZickOElena = giocatore.zonePersonaggi.any((carta) =>
        carta != null && (carta.name == "Zick" || carta.name == "Elena"));

    if (controllaZickOElena) {
      // Cerca Zick o Elena nel mazzo
      final personaggiDalMazzo = giocatore.mazzo
          .where((carta) =>
              carta is PersonaggioCard &&
              (carta.name == "Zick" || carta.name == "Elena"))
          .toList();

      if (personaggiDalMazzo.isNotEmpty && giocatore.hasSpaceForPersonaggio) {
        final personaggioScelto = personaggiDalMazzo.first as PersonaggioCard;
        giocatore.mazzo.remove(personaggioScelto);
        giocatore.addPersonaggioToField(personaggioScelto);
        giocatore.mischiaMazzo();

        if (showEffect) {
          onEffectActivated?.call(
              "Lavoro di Squadra: ${personaggioScelto.name} entra in campo!");
        }

        // Applica l'effetto del personaggio entrato in campo
        _applicaEffettoPersonaggio(personaggioScelto);
      } else if (!giocatore.hasSpaceForPersonaggio) {
        if (showEffect) {
          onEffectActivated
              ?.call("Lavoro di Squadra: Nessuno spazio disponibile!");
        }
      } else {
        if (showEffect) {
          onEffectActivated
              ?.call("Lavoro di Squadra: Nessun Zick o Elena nel mazzo!");
        }
      }
    }
  }

  void _effettoFameCarnivora(bool showEffect) {
    // "Guarda la mano del tuo avversario. Scegli ed aggiungi 1 Carta dalla mano del tuo avversario alla tua mano."
    final avversario = _gameState!.avversario;
    final giocatore = _gameState!.giocatoreAttivo;

    if (avversario.mano.isNotEmpty) {
      // Cerca una carta che non sia Elena protetta da Zick
      GameCard? cartaDaRubare;

      for (var carta in avversario.mano) {
        if (carta is PersonaggioCard && carta.name == "Elena") {
          // Controlla se Elena è protetta da Zick
          final controllaZick = avversario.zonePersonaggi.any((personaggio) =>
              personaggio != null && personaggio.name == "Zick");
          if (controllaZick) {
            continue; // Elena è protetta, salta
          }
        }
        cartaDaRubare = carta;
        break;
      }

      // Se non ha trovato nessuna carta valida, prendi la prima disponibile
      cartaDaRubare ??= avversario.mano.first;

      avversario.mano.remove(cartaDaRubare);
      giocatore.mano.add(cartaDaRubare);
      if (showEffect) {
        onEffectActivated?.call(
            "Fame Carnivora: ${cartaDaRubare.name} rubato dalla mano avversaria!");
      }
    } else {
      if (showEffect) {
        onEffectActivated
            ?.call("Fame Carnivora: L'avversario non ha carte in mano!");
      }
    }
  }

  void _effettoMareGuai(bool showEffect) {
    // "Mischia nel mazzo 2 Carte Personaggio dalla tua mano. Rivela ed aggiungi fino a 2 Carte Personaggio dal tuo mazzo alla mano."
    final giocatore = _gameState!.giocatoreAttivo;

    // Trova carte personaggio nella mano
    final personaggiInMano =
        giocatore.mano.whereType<PersonaggioCard>().toList();

    if (personaggiInMano.isEmpty) {
      if (showEffect) {
        onEffectActivated?.call(
            "In un mare di guai: Nessun personaggio in mano da rimescolare!");
      }
      return;
    }

    // Mischia fino a 2 personaggi nel mazzo
    int personaggiDaMischiare =
        personaggiInMano.length > 2 ? 2 : personaggiInMano.length;
    List<String> nomiMischiati = [];

    for (int i = 0; i < personaggiDaMischiare; i++) {
      final personaggio = personaggiInMano[i];
      nomiMischiati.add(personaggio.name);
      giocatore.mano.remove(personaggio);
      giocatore.mazzo.add(personaggio);
    }
    giocatore.mischiaMazzo();

    if (showEffect) {
      onEffectActivated?.call(
          "In un mare di guai: ${nomiMischiati.join(' e ')} rimescolati nel mazzo!");
    }

    // Pesca fino a 2 carte personaggio dal mazzo
    final personaggiDalMazzo =
        giocatore.mazzo.whereType<PersonaggioCard>().take(2).toList();
    List<String> nomiPescati = [];

    for (final personaggio in personaggiDalMazzo) {
      giocatore.mazzo.remove(personaggio);
      giocatore.mano.add(personaggio);
      nomiPescati.add(personaggio.name);
    }
    giocatore.mischiaMazzo();

    if (nomiPescati.isNotEmpty) {
      if (showEffect) {
        onEffectActivated?.call(
            "In un mare di guai: ${nomiPescati.join(' e ')} aggiunti alla mano!");
      }
    } else {
      if (showEffect) {
        onEffectActivated
            ?.call("In un mare di guai: Nessun personaggio trovato nel mazzo!");
      }
    }
  }

  void _effettoRitirata(bool showEffect) {
    // "Fai tornare 1 dei tuoi Personaggi nella tua mano."
    final giocatore = _gameState!.giocatoreAttivo;

    // Trova il primo personaggio in campo
    for (int i = 0; i < giocatore.zonePersonaggi.length; i++) {
      if (giocatore.zonePersonaggi[i] != null) {
        final personaggio = giocatore.zonePersonaggi[i]!;
        giocatore.removePersonaggioFromField(i);
        giocatore.mano.add(personaggio);
        if (showEffect) {
          onEffectActivated
              ?.call("Ritirata: ${personaggio.name} torna nella tua mano!");
        }
        return;
      }
    }

    if (showEffect) {
      onEffectActivated
          ?.call("Ritirata: Nessun personaggio in campo da far ritirare!");
    }
  }

  void fineTurno() {
    if (_gameState == null) return;

    print(
        'DEBUG: Fine turno - Giocatore attivo prima: ${_gameState!.giocatoreAttivo.name}');

    _currentPhase = GamePhase.fine;
    _gameState!.cambiaGiocatore();

    print(
        'DEBUG: Fine turno - Giocatore attivo dopo: ${_gameState!.giocatoreAttivo.name}');

    // Reset degli attacchi quando cambia giocatore
    _attackedThisTurn.clear();

    // Aggiorna se è il turno dell'AI
    if (_isAIGame) {
      _isAITurn = _gameState!.giocatoreAttivo.name == 'Bombo';
      print('DEBUG: È turno AI: $_isAITurn');
    }

    if (!_gameState!.isGameOver) {
      // Solo l'AI inizia automaticamente il turno, il giocatore umano lo controlla manualmente
      if (_isAIGame && _isAITurn) {
        print('DEBUG: Iniziando turno AI automaticamente');
        iniziaTurno();
        _executeAITurn();
      } else {
        print('DEBUG: Iniziando turno giocatore umano');
        // Per il giocatore umano, automatizza energia e pesca, poi va alla fase principale
        iniziaTurno();
      }
    }
  }

  Future<void> _executeAITurn() async {
    if (!_isAITurn || _gameState == null) return;

    // Delay per rendere più naturale il gioco
    await Future.delayed(const Duration(milliseconds: 1000));

    while (_isAITurn && !_gameState!.isGameOver) {
      try {
        final decision =
            await _aiService.makeDecision(_gameState!, _currentPhase);

        final success = await _executeAIDecision(decision);

        if (!success) {
          // Se l'azione AI fallisce, passa alla fase successiva
          _nextPhase();
        }

        // Delay tra le azioni
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        print('Errore durante il turno AI: $e');
        _nextPhase();
      }
    }
  }

  Future<bool> _executeAIDecision(AIDecision decision) async {
    switch (decision.action) {
      case AIAction.playCard:
        return _aiPlayCard(decision.cardName, decision);

      case AIAction.attack:
        return _aiAttack(
            decision.attackerIndex, decision.targetIndex, decision);

      case AIAction.nextPhase:
        _nextPhase();
        return true;
    }
  }

  bool _aiPlayCard(String? cardName, AIDecision decision) {
    if (cardName == null || _gameState == null) return false;

    final ai = _gameState!.giocatoreAttivo;
    final card = ai.mano.firstWhere(
      (c) => c.name == cardName,
      orElse: () => throw Exception('Carta non trovata'),
    );

    if (puoiGiocareCarta(card)) {
      giocaCarta(card);

      // Chiamata al callback DOPO che l'azione è stata eseguita con un delay
      Future.delayed(const Duration(milliseconds: 500), () {
        onAIAction?.call('AI gioca "$cardName"');
      });

      return true;
    }

    return false;
  }

  bool _aiAttack(int? attackerIndex, int? targetIndex, AIDecision decision) {
    if (attackerIndex == null || _gameState == null) return false;

    if (puoiAttaccare(attackerIndex)) {
      final ai = _gameState!.giocatoreAttivo;
      final attacker = ai.zonePersonaggi[attackerIndex];
      String attackMessage;

      if (targetIndex != null) {
        final human = _gameState!.avversario;
        final target = human.zonePersonaggi[targetIndex];
        attackMessage = 'AI attacca: ${attacker?.name} vs ${target?.name}';
      } else {
        attackMessage = 'AI attacca direttamente con ${attacker?.name}';
      }

      attaccaConPersonaggio(attackerIndex, targetIndex);

      // Chiamata al callback DOPO che l'azione è stata eseguita con un delay
      Future.delayed(const Duration(milliseconds: 500), () {
        onAIAction?.call(attackMessage);
      });

      return true;
    }

    return false;
  }

  void _nextPhase() {
    switch (_currentPhase) {
      case GamePhase.energia:
        pescaFase();
        break;
      case GamePhase.pesca:
        fasePrincipale();
        break;
      case GamePhase.principale:
        faseAttacco();
        break;
      case GamePhase.attacco:
        fineTurno();
        break;
      case GamePhase.fine:
        break;
    }
  }

  bool get isGameOver => _gameState?.isGameOver ?? false;
  Player? get vincitore => _gameState?.vincitore;
}
