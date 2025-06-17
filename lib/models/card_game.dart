enum CardType { personaggio, ambientazione, interazione }

enum CardSeries { monsterAllergy }

abstract class GameCard {
  final String id;
  final String name;
  final int cost;
  final CardType type;
  final CardSeries series;
  final String description;
  final String imageUrl;

  GameCard({
    required this.id,
    required this.name,
    required this.cost,
    required this.type,
    required this.series,
    required this.description,
    required this.imageUrl,
  });
}

class PersonaggioCard extends GameCard {
  final int forza;
  final String? effetto;

  PersonaggioCard({
    required super.id,
    required super.name,
    required super.cost,
    required this.forza,
    required super.series,
    required super.description,
    required super.imageUrl,
    this.effetto,
  }) : super(type: CardType.personaggio);
}

class AmbientazioneCard extends GameCard {
  final String effetto;

  AmbientazioneCard({
    required super.id,
    required super.name,
    required super.cost,
    required this.effetto,
    required super.series,
    required super.description,
    required super.imageUrl,
  }) : super(type: CardType.ambientazione);
}

class InterazioneCard extends GameCard {
  final String effetto;
  final bool permanente;
  final String? legatoAPersonaggio;

  InterazioneCard({
    required super.id,
    required super.name,
    required super.cost,
    required this.effetto,
    required super.series,
    required super.description,
    required super.imageUrl,
    this.permanente = false,
    this.legatoAPersonaggio,
  }) : super(type: CardType.interazione);
}

class Player {
  final String name;
  int vite;
  int energia;
  List<GameCard> mano;
  List<GameCard> mazzo;
  List<GameCard> cimitero;
  List<PersonaggioCard?> zonePersonaggi; // 3 zone
  List<InterazioneCard?> zoneInterazioni; // 3 zone

  Player({
    required this.name,
    this.vite = 3,
    this.energia = 2,
    List<GameCard>? mano,
    List<GameCard>? mazzo,
    List<GameCard>? cimitero,
  })  : mano = mano ?? [],
        mazzo = mazzo ?? [],
        cimitero = cimitero ?? [],
        zonePersonaggi = List.filled(3, null),
        zoneInterazioni = List.filled(3, null);

  bool get haPersonaggiInCampo => zonePersonaggi.any((card) => card != null);

  List<PersonaggioCard> get personaggiInCampo => zonePersonaggi
      .where((card) => card != null)
      .cast<PersonaggioCard>()
      .toList();

  bool get hasSpaceForPersonaggio => zonePersonaggi.any((card) => card == null);
  bool get hasSpaceForInterazione =>
      zoneInterazioni.any((card) => card == null);

  void addPersonaggioToField(PersonaggioCard card) {
    final index = zonePersonaggi.indexOf(null);
    if (index != -1) {
      zonePersonaggi[index] = card;
    }
  }

  void addInterazioneToField(InterazioneCard card) {
    final index = zoneInterazioni.indexOf(null);
    if (index != -1) {
      zoneInterazioni[index] = card;
    }
  }

  // Metodi per inserire carte in posizioni specifiche
  void addPersonaggioToSpecificPosition(PersonaggioCard card, int targetIndex) {
    if (targetIndex >= 0 && targetIndex < zonePersonaggi.length) {
      if (zonePersonaggi[targetIndex] == null) {
        // La posizione target è libera, inserisci direttamente
        zonePersonaggi[targetIndex] = card;
      } else {
        // La posizione target è occupata, trova la prima posizione libera
        addPersonaggioToField(card);
      }
    } else {
      // Indice non valido, usa il metodo standard
      addPersonaggioToField(card);
    }
  }

  void addInterazioneToSpecificPosition(InterazioneCard card, int targetIndex) {
    if (targetIndex >= 0 && targetIndex < zoneInterazioni.length) {
      if (zoneInterazioni[targetIndex] == null) {
        // La posizione target è libera, inserisci direttamente
        zoneInterazioni[targetIndex] = card;
      } else {
        // La posizione target è occupata, trova la prima posizione libera
        addInterazioneToField(card);
      }
    } else {
      // Indice non valido, usa il metodo standard
      addInterazioneToField(card);
    }
  }

  void removePersonaggioFromField(int index) {
    if (index >= 0 && index < zonePersonaggi.length) {
      final card = zonePersonaggi[index];
      if (card != null) {
        cimitero.add(card);
        zonePersonaggi[index] = null;
      }
    }
  }

  void removeInterazioneFromField(int index) {
    if (index >= 0 && index < zoneInterazioni.length) {
      final card = zoneInterazioni[index];
      if (card != null) {
        cimitero.add(card);
        zoneInterazioni[index] = null;
      }
    }
  }

  void pescaCarta() {
    if (mazzo.isNotEmpty) {
      mano.add(mazzo.removeAt(0));
    } else {
      // Danno per esaurimento mazzo
      vite--;
    }
  }

  void mischiaMazzo() {
    mazzo.shuffle();
  }
}

class GameState {
  Player giocatore1;
  Player giocatore2;
  Player giocatoreAttivo;
  AmbientazioneCard? ambientazioneAttiva;
  int turno;
  bool isPrimoTurno;

  GameState({
    required this.giocatore1,
    required this.giocatore2,
  })  : giocatoreAttivo = giocatore1,
        turno = 1,
        isPrimoTurno = true;

  Player get avversario =>
      giocatoreAttivo == giocatore1 ? giocatore2 : giocatore1;

  void cambiaGiocatore() {
    giocatoreAttivo = giocatoreAttivo == giocatore1 ? giocatore2 : giocatore1;
    if (giocatoreAttivo == giocatore1) {
      turno++;
      isPrimoTurno = false;
    }
  }

  bool get isGameOver => giocatore1.vite <= 0 || giocatore2.vite <= 0;

  Player? get vincitore {
    if (giocatore1.vite <= 0) return giocatore2;
    if (giocatore2.vite <= 0) return giocatore1;
    return null;
  }

  String? get motivoVittoria {
    if (giocatore1.vite <= 0)
      return "${giocatore2.name} vince: ${giocatore1.name} ha esaurito le vite!";
    if (giocatore2.vite <= 0)
      return "${giocatore1.name} vince: ${giocatore2.name} ha esaurito le vite!";
    return null;
  }

  void cambiaAmbientazione(AmbientazioneCard nuovaAmbientazione) {
    if (ambientazioneAttiva != null) {
      // Manda la vecchia ambientazione al cimitero
      giocatoreAttivo.cimitero.add(ambientazioneAttiva!);
    }
    ambientazioneAttiva = nuovaAmbientazione;
  }
}
