import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/pack.dart';
import '../models/special_pack.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import '../services/supabase_service.dart';
import '../widgets/special_pack_widget.dart';

class Prize {
  final String name;
  final Color color;
  final String description;
  final IconData icon;
  final SpecialPack specialPack;
  final Function(BuildContext context, User user) onWin;

  const Prize({
    required this.name,
    required this.color,
    required this.description,
    required this.icon,
    required this.specialPack,
    required this.onWin,
  });
}

class LuckyWheelPage extends StatefulWidget {
  const LuckyWheelPage({super.key});

  @override
  _LuckyWheelPageState createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage>
    with SingleTickerProviderStateMixin {
  StreamController<int> controller = StreamController<int>();
  int selected = 0;
  bool isSpinning = false;
  bool showResult = false;
  bool showPack = false;
  bool isOpeningPack = false;
  bool packOpened = false;
  String resultMessage = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<CollectionCard>? drawnCards;

  // Definizione dei premi disponibili
  List<Prize> prizes = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _initializePrizes();
  }

  void _initializePrizes() {
    prizes = [
      Prize(
        name: "Pacchetto\ncon carta rara",
        color: Colors.blue,
        description: "Hai vinto un pacchetto con all'interno una carta rara!",
        icon: Icons.card_giftcard,
        specialPack: SpecialPack.rareCardPack(),
        onWin: (context, user) async {
          final cardService = CardService();
          await cardService.loadCards();

          // Trova un pacchetto casuale
          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];

          // Crea una carta rara
          final List<CollectionCard> rareCards = cardService
              .getCardsByRarityAndPack(CardRarity.rare, randomPack.id);
          if (rareCards.isEmpty) return;

          final randomCard = rareCards[Random().nextInt(rareCards.length)];
          drawnCards = [randomCard];
        },
      ),
      Prize(
        name: "Pacchetto\ncon carta super-rara",
        color: Colors.purple,
        description:
            "Hai vinto un pacchetto con all'interno una carta super-rara!",
        icon: Icons.card_giftcard,
        specialPack: SpecialPack.superRareCardPack(),
        onWin: (context, user) async {
          final cardService = CardService();
          await cardService.loadCards();

          // Trova un pacchetto casuale
          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];

          // Crea una carta super-rara
          final List<CollectionCard> superRareCards = cardService
              .getCardsByRarityAndPack(CardRarity.superRare, randomPack.id);
          if (superRareCards.isEmpty) return;

          final randomCard =
              superRareCards[Random().nextInt(superRareCards.length)];
          drawnCards = [randomCard];
        },
      ),
      Prize(
        name: "Pacchetto\ncon carta ultra-rara",
        color: Colors.red,
        description:
            "Hai vinto un pacchetto con all'interno una carta ultra-rara!",
        icon: Icons.card_giftcard,
        specialPack: SpecialPack.ultraRareCardPack(),
        onWin: (context, user) async {
          final cardService = CardService();
          await cardService.loadCards();

          // Trova un pacchetto casuale
          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];

          // Crea una carta ultra-rara
          final List<CollectionCard> ultraRareCards = cardService
              .getCardsByRarityAndPack(CardRarity.ultraRare, randomPack.id);
          if (ultraRareCards.isEmpty) return;

          final randomCard =
              ultraRareCards[Random().nextInt(ultraRareCards.length)];
          drawnCards = [randomCard];
        },
      ),
      Prize(
        name: "12 Tunuè Coin",
        color: Colors.amber,
        description: "Hai vinto 12 Tunuè Coin!",
        icon: Icons.monetization_on,
        specialPack: SpecialPack.coinPack(),
        onWin: (context, user) async {
          // Non ci sono carte per questo premio
          drawnCards = [];
        },
      ),
      Prize(
        name: "Pacchetto\nFire Destruction",
        color: Colors.orange,
        description: "Hai vinto un pacchetto Fire Destruction gratis!",
        icon: Icons.local_fire_department,
        specialPack: SpecialPack.fireDestructionPack(),
        onWin: (context, user) async {
          final cardService = CardService();
          await cardService.loadCards();

          // Trova il pacchetto Fire Destruction
          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          final firePack = packs.firstWhere(
            (pack) =>
                pack.name.contains("Fire") || pack.name.contains("Destruction"),
            orElse: () => packs.isNotEmpty
                ? packs.first
                : Pack(
                    id: '1',
                    name: 'Default Pack',
                    description: 'Default',
                    image: 'https://example.com/image.jpg'),
          );

          // Ottieni 5 carte casuali dal pacchetto
          final cards = cardService.getRandomCards(5, firePack.id);
          drawnCards = cards;
        },
      ),
      Prize(
        name: "Niente",
        color: Colors.grey,
        description: "Peccato! Non hai vinto niente questa volta.",
        icon: Icons.do_not_disturb,
        specialPack: SpecialPack.emptyPack(),
        onWin: (context, user) {
          // Non fa nulla
          drawnCards = [];
        },
      ),
    ];
  }

  @override
  void dispose() {
    controller.close();
    _animationController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (isSpinning) return;

    setState(() {
      isSpinning = true;
      showResult = false;
      showPack = false;
      isOpeningPack = false;
      packOpened = false;
      drawnCards = null;
    });

    // Genera un numero casuale per il premio
    final random = Random();
    final randomIndex = random.nextInt(prizes.length);

    // Spinner gira per 5 secondi poi si ferma al premio casuale
    controller.add(randomIndex);

    // Attendi la fine dell'animazione
    Future.delayed(const Duration(milliseconds: 5000), () {
      setState(() {
        selected = randomIndex;
        isSpinning = false;
        showResult = true;
        resultMessage = prizes[randomIndex].description;
      });

      _animationController.forward();

      // Prepara il premio per l'utente
      final user = Provider.of<User>(context, listen: false);
      prizes[randomIndex].onWin(context, user);

      // Mostra il pacchetto dopo un breve ritardo
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          showPack = true;
        });
      });
    });
  }

  void _openSpecialPack() {
    if (isOpeningPack || packOpened) return;

    setState(() {
      isOpeningPack = true;
    });

    // Simula l'apertura del pacchetto
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        isOpeningPack = false;
        packOpened = true;
      });

      // Se ci sono carte vinte, aggiungiamole all'utente
      if (drawnCards != null && drawnCards!.isNotEmpty) {
        final user = Provider.of<User>(context, listen: false);
        for (var card in drawnCards!) {
          user.addCard(card);
        }

        // Se è il premio delle monete
        if (selected == 3) {
          // 12 Tunuè Coin
          user.addCoins(12);
        }

        // Salva i dati utente
        final authService = AuthService();
        authService.syncUserData(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wheelSize = size.width * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruota della Fortuna'),
      ),
      body: Stack(
        children: [
          // Contenuto principale
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Gira la ruota e vinci premi!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Puoi vincere carte rare, monete o pacchetti gratuiti',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: wheelSize,
                    width: wheelSize,
                    child: FortuneWheel(
                      selected: controller.stream,
                      animateFirst: false,
                      duration: const Duration(seconds: 5),
                      indicators: const [
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(
                            color: Colors.red,
                          ),
                        ),
                      ],
                      items: [
                        for (var prize in prizes)
                          FortuneItem(
                            style: FortuneItemStyle(
                              color: prize.color,
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 60, right: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    prize.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      prize.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      onAnimationEnd: () {
                        // L'animazione è terminata
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: isSpinning || showPack ? null : _spinWheel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(isSpinning ? 'Girando...' : 'Gira la Ruota'),
                  ),
                  const SizedBox(height: 30),
                  // Visualizzazione risultato
                  if (showResult && !showPack)
                    ScaleTransition(
                      scale: _animation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: prizes[selected].color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: prizes[selected].color, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              prizes[selected].icon,
                              size: 60,
                              color: prizes[selected].color,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              resultMessage,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: prizes[selected].color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 100), // Spazio per il pacchetto
                ],
              ),
            ),
          ),

          // Overlay per il pacchetto premio
          if (showPack)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (!isOpeningPack && !packOpened) {
                    _openSpecialPack();
                  }
                },
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Visualizza il pacchetto
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: packOpened
                              ? _buildOpenedPackContent()
                              : SpecialPackWidget(
                                  key: const ValueKey('pack'),
                                  pack: prizes[selected].specialPack,
                                  onTap: _openSpecialPack,
                                  isFlipped: isOpeningPack,
                                ),
                        ),
                        const SizedBox(height: 30),
                        if (!packOpened)
                          Text(
                            isOpeningPack
                                ? 'Apertura in corso...'
                                : 'Tocca per aprire!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (packOpened)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showPack = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Chiudi'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpenedPackContent() {
    // Mostra il contenuto del pacchetto aperto
    if (drawnCards == null) return const SizedBox.shrink();

    if (selected == 3) {
      // 12 Tunuè Coin
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on,
              size: 80,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              '12 Tunuè Coin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      );
    } else if (selected == 5) {
      // Niente
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.do_not_disturb,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Ritenta la prossima volta!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else if (drawnCards!.isEmpty) {
      return const Center(
        child: Text(
          'Pacchetto vuoto',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Mostra le carte
      return SizedBox(
        height: 300,
        child: drawnCards!.length == 1
            ? _buildSingleCardView(drawnCards!.first)
            : _buildMultiCardView(),
      );
    }
  }

  Widget _buildSingleCardView(CollectionCard card) {
    return Container(
      width: 220,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CollectionCard.getRarityColor(card.rarity).withOpacity(0.7),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                card.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CollectionCard.getRarityColor(card.rarity),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  CollectionCard.getRarityString(card.rarity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiCardView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: drawnCards!.length,
      itemBuilder: (context, index) {
        final card = drawnCards![index];
        return Container(
          width: 160,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    CollectionCard.getRarityColor(card.rarity).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    card.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CollectionCard.getRarityColor(card.rarity),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CollectionCard.getRarityString(card.rarity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
