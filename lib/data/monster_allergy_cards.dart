import '../models/card_game.dart';

class MonsterAllergyCards {
  static List<GameCard> getAllCards() {
    return [
      ...getPersonaggi(),
      ...getAmbientazioni(),
      ...getInterazioni(),
    ];
  }

  static List<PersonaggioCard> getPersonaggi() {
    return [
      PersonaggioCard(
        id: 'ma_zick',
        name: 'Zick',
        cost: 1,
        forza: 3,
        series: CardSeries.monsterAllergy,
        description:
            'Quando entra in campo, guarda la carta in cima al mazzo dell\'avversario.',
        imageUrl: 'assets/images/game/cards/zick.png',
        effetto:
            'Quando entra in campo, guarda la carta in cima al mazzo dell\'avversario.',
      ),
      PersonaggioCard(
        id: 'ma_elena',
        name: 'Elena',
        cost: 1,
        forza: 1,
        series: CardSeries.monsterAllergy,
        description:
            'Se controlli "Zick", ottiene +1 Forza e non subisce gli effetti delle Carte dell\'avversario.',
        imageUrl: 'assets/images/game/cards/elena.png',
        effetto:
            'Se controlli "Zick", ottiene +1 Forza e non subisce gli effetti delle Carte dell\'avversario.',
      ),
      PersonaggioCard(
        id: 'ma_timothy',
        name: 'Timothy Moth',
        cost: 2,
        forza: 2,
        series: CardSeries.monsterAllergy,
        description: 'Quando entra in campo, guarda la mano dell\'avversario.',
        imageUrl: 'assets/images/game/cards/timothy-moth.png',
        effetto: 'Quando entra in campo, guarda la mano dell\'avversario.',
      ),
      PersonaggioCard(
        id: 'ma_bombo',
        name: 'Bombo',
        cost: 2,
        forza: 2,
        series: CardSeries.monsterAllergy,
        description:
            'Quando entra in campo, pesca 1 carta dal tuo mazzo o dal mazzo dell\'avversario.',
        imageUrl: 'assets/images/game/cards/bombo.png',
        effetto:
            'Quando entra in campo, pesca 1 carta dal tuo mazzo o dal mazzo dell\'avversario.',
      ),
      PersonaggioCard(
        id: 'ma_magnacat',
        name: 'Magnacat',
        cost: 4,
        forza: 5,
        series: CardSeries.monsterAllergy,
        description:
            'Quando entra in campo, distruggi/aggiungi alla tua mano/prendi il controllo di 1 Carta dell\'avversario.',
        imageUrl: 'assets/images/game/cards/magnacat.png',
        effetto:
            'Quando entra in campo, distruggi/aggiungi alla tua mano/prendi il controllo di 1 Carta dell\'avversario.',
      ),
    ];
  }

  static List<AmbientazioneCard> getAmbientazioni() {
    return [
      AmbientazioneCard(
        id: 'ma_casa_zick',
        name: 'Casa di Zick',
        cost: 1,
        series: CardSeries.monsterAllergy,
        description:
            'Le Carte Personaggio di "Monster Allergy" costano 1 Energia in meno per essere giocate.',
        imageUrl: 'assets/images/game/cards/casa-zick.png',
        effetto:
            'Le Carte Personaggio di "Monster Allergy" costano 1 Energia in meno per essere giocate.',
      ),
      AmbientazioneCard(
        id: 'ma_citta_mostri',
        name: 'Città dei Mostri',
        cost: 2,
        series: CardSeries.monsterAllergy,
        description:
            'Le Carte Personaggio di "Monster Allergy" guadagnano +1 Forza.',
        imageUrl: 'assets/images/game/cards/citta-mostri.png',
        effetto:
            'Le Carte Personaggio di "Monster Allergy" guadagnano +1 Forza.',
      ),
    ];
  }

  static List<InterazioneCard> getInterazioni() {
    return [
      InterazioneCard(
        id: 'ma_caccia_mostri',
        name: 'A caccia di mostri',
        cost: 0,
        series: CardSeries.monsterAllergy,
        description:
            'Aggiungi 1 Carta Personaggio "Zick" o "Elena" dal tuo mazzo o cimitero alla tua mano.',
        imageUrl: 'assets/images/game/cards/caccia-di-mostri.png',
        effetto:
            'Aggiungi 1 Carta Personaggio "Zick" o "Elena" dal tuo mazzo o cimitero alla tua mano.',
      ),
      InterazioneCard(
        id: 'ma_lotta_marina',
        name: 'Lotta Marina',
        cost: 1,
        series: CardSeries.monsterAllergy,
        description:
            'Puoi giocare questa carta soltanto se in campo è presente 1 Carta Ambientazione; distruggila. Puoi aggiungere 1 Carta Ambientazione dal tuo mazzo alla mano.',
        imageUrl: 'assets/images/game/cards/lotta-marina.png',
        effetto:
            'Puoi giocare questa carta soltanto se in campo è presente 1 Carta Ambientazione; distruggila. Puoi aggiungere 1 Carta Ambientazione dal tuo mazzo alla mano.',
      ),
      InterazioneCard(
        id: 'ma_lavoro_squadra',
        name: 'Lavoro di Squadra',
        cost: 1,
        series: CardSeries.monsterAllergy,
        description:
            'Puoi giocare questa carta soltanto se controlli 1 Carta Personaggio "Zick" o "Elena". Gioca (direttamente dal tuo mazzo, senza pagarne il costo) 1 Carta Personaggio "Zick" o "Elena".',
        imageUrl: 'assets/images/game/cards/lavoro-di-squadra.png',
        effetto:
            'Puoi giocare questa carta soltanto se controlli 1 Carta Personaggio "Zick" o "Elena". Gioca (direttamente dal tuo mazzo, senza pagarne il costo) 1 Carta Personaggio "Zick" o "Elena".',
      ),
      InterazioneCard(
        id: 'ma_fame_carnivora',
        name: 'Fame Carnivora',
        cost: 2,
        series: CardSeries.monsterAllergy,
        description:
            'Guarda la mano del tuo avversario. Scegli ed aggiungi 1 Carta dalla mano del tuo avversario alla tua mano.',
        imageUrl: 'assets/images/game/cards/fame-carnivora.png',
        effetto:
            'Guarda la mano del tuo avversario. Scegli ed aggiungi 1 Carta dalla mano del tuo avversario alla tua mano.',
      ),
      InterazioneCard(
        id: 'ma_mare_guai',
        name: 'In un mare di guai',
        cost: 1,
        series: CardSeries.monsterAllergy,
        description:
            'Mischia nel mazzo 2 Carte Personaggio dalla tua mano. Rivela ed aggiungi fino a 2 Carte Personaggio dal tuo mazzo alla mano.',
        imageUrl: 'assets/images/game/cards/mare-di-guai.png',
        effetto:
            'Mischia nel mazzo 2 Carte Personaggio dalla tua mano. Rivela ed aggiungi fino a 2 Carte Personaggio dal tuo mazzo alla mano.',
      ),
      InterazioneCard(
        id: 'ma_ritirata',
        name: 'Ritirata',
        cost: 0,
        series: CardSeries.monsterAllergy,
        description: 'Fai tornare 1 dei tuoi Personaggi nella tua mano.',
        imageUrl: 'assets/images/game/cards/ritirata.png',
        effetto: 'Fai tornare 1 dei tuoi Personaggi nella tua mano.',
      ),
    ];
  }

  static List<GameCard> createDefaultDeck() {
    // Crea un mazzo predefinito con 20 carte (max 2 copie per carta)
    final deck = <GameCard>[];

    // Aggiungi 2 copie di ogni personaggio
    final personaggi = getPersonaggi();
    for (var personaggio in personaggi) {
      deck.add(personaggio);
      deck.add(personaggio);
    }

    // Aggiungi 1 copia di ogni ambientazione
    final ambientazioni = getAmbientazioni();
    for (var ambientazione in ambientazioni) {
      deck.add(ambientazione);
    }

    // Aggiungi 1-2 copie di alcune interazioni per arrivare a 20 carte
    final interazioni = getInterazioni();
    deck.add(interazioni[0]); // A caccia di mostri
    deck.add(interazioni[0]); // A caccia di mostri (2a copia)
    deck.add(interazioni[2]); // Lavoro di squadra
    deck.add(interazioni[5]); // Ritirata
    deck.add(interazioni[4]); // In un mare di guai
    deck.add(interazioni[1]); // Lotta Marina

    return deck;
  }
}
