import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _animationController;
  late Animation<double> _resultAnimation;

  int selected = 0;
  bool isSpinning = false;
  bool showResult = false;
  bool showPack = false;
  bool isOpeningPack = false;
  bool packOpened = false;
  String resultMessage = '';
  List<CollectionCard>? drawnCards;

  // Definizione dei premi disponibili
  List<Prize> prizes = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _resultAnimation = CurvedAnimation(
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

          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];
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

          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];
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

          final supabaseService = SupabaseService();
          final packs = await supabaseService.getAllPacks();
          if (packs.isEmpty) return;

          final randomPack = packs[Random().nextInt(packs.length)];
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
          drawnCards = [];
        },
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_controller.isAnimating) return;

    setState(() {
      isSpinning = true;
      showResult = false;
      showPack = false;
      isOpeningPack = false;
      packOpened = false;
      drawnCards = null;
    });

    final random = Random();
    final randomRotations = 5 + random.nextDouble() * 5; // 5-10 giri

    _animation = Tween<double>(
      begin: _animation.value,
      end: _animation.value + randomRotations,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.forward(from: 0.0).then((_) {
      _determineWinner();
    });
  }

  void _determineWinner() {
    final rotations = _animation.value;
    final normalizedRotation = (rotations * 2 * pi) % (2 * pi);
    final segmentAngle = 2 * pi / prizes.length;

    // Calcola quale segmento è in cima (invertito perché la ruota gira in senso orario)
    int winnerIndex = ((2 * pi - normalizedRotation) / segmentAngle).floor();
    winnerIndex = winnerIndex % prizes.length;

    setState(() {
      selected = winnerIndex;
      isSpinning = false;
      showResult = true;
      resultMessage = prizes[winnerIndex].description;
    });

    _animationController.forward();

    // Prepara il premio per l'utente
    final user = Provider.of<User>(context, listen: false);
    prizes[winnerIndex].onWin(context, user);

    // Mostra il pacchetto dopo un breve ritardo
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        showPack = true;
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
      body: Stack(
        children: [
          // Contenuto principale
          SingleChildScrollView(
            child: Column(
              children: [
                // Header personalizzato
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3FC0C0C0),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text(
                            'Ruota della Fortuna',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color.fromARGB(255, 54, 55, 58),
                              fontSize: 18,
                              fontFamily: 'NeueHaasDisplay',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Pulsante back
                      Positioned(
                        left: 20,
                        bottom: 15,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: SvgPicture.asset(
                            'assets/images/icons/svg/arrow_icon.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value * 2 * pi,
                            child: CustomPaint(
                              size: Size(wheelSize, wheelSize),
                              painter: WheelPainter(prizes),
                            ),
                          );
                        },
                      ),
                      // Indicatore fisso in cima
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 0,
                          height: 0,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 15,
                                color: Colors.transparent,
                              ),
                              right: BorderSide(
                                width: 15,
                                color: Colors.transparent,
                              ),
                              bottom: BorderSide(
                                width: 30,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottone centrale
                      GestureDetector(
                        onTap: isSpinning || showPack ? null : _spinWheel,
                        child: Image.asset(
                          'assets/images/icons/png/lucky-wheel_icon.png',
                          width: wheelSize * 0.25,
                          height: wheelSize * 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Visualizzazione risultato
                if (showResult && !showPack)
                  ScaleTransition(
                    scale: _resultAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: prizes[selected].color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: prizes[selected].color, width: 2),
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

class WheelPainter extends CustomPainter {
  final List<Prize> prizes;

  WheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      // Disegna il segmento
      final paint = Paint()
        ..color = prizes[i].color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Disegna il bordo
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Calcola la posizione del testo
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      // Disegna il rettangolo con angoli arrotondati per il testo
      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Rettangolo di sfondo per il testo
      final textRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(textX, textY),
          width: textPainter.width + 16,
          height: textPainter.height + 8,
        ),
        const Radius.circular(8),
      );

      final textBgPaint = Paint()..color = Colors.black.withOpacity(0.3);

      canvas.drawRRect(textRect, textBgPaint);

      // Disegna il testo
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }

    // Disegna il cerchio centrale
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 30, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 30, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
