// screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/card_constants.dart';
import '../models/card.dart';
import '../models/pack.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import '../services/supabase_service.dart';
import '../widgets/card_widget.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/pack_widget.dart';
import 'lucky_wheel_page.dart';
import 'missions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Pack> packs = [];
  Pack? selectedPack;
  bool isOpeningPack = false;
  List<CollectionCard>? drawnCards;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int currentCardIndex = 0;

  // Controllo swipe
  Offset? _dragStartPosition;
  bool _isDragging = false;
  double _currentCardOffset = 0;

  @override
  void initState() {
    super.initState();

    // Controller per l'animazione
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadPacks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPacks() async {
    final supabaseService = SupabaseService();
    final loadedPacks = await supabaseService.getAllPacks();
    print('Pacchetti caricati:');
    for (final p in loadedPacks) {
      print('id: \\${p.id} - name: \\${p.name} - image: \\${p.image}');
    }
    setState(() {
      packs = loadedPacks;
      selectedPack = null;
    });
  }

  void _selectPack(Pack pack) {
    setState(() {
      selectedPack = pack;
    });
  }

  void _openPack() async {
    if (selectedPack == null) return;
    final user = Provider.of<User>(context, listen: false);
    setState(() {
      isOpeningPack = true;
      drawnCards = null;
      currentCardIndex = 0;
      _currentCardOffset = 0;
    });
    _animationController.reset();
    _animationController.forward();
    await Future.delayed(const Duration(seconds: 2));
    final cardService = CardService();
    await cardService.loadCards();
    final cards = cardService.getRandomCards(5, selectedPack!.id);
    if (cards.isEmpty) {
      setState(() {
        isOpeningPack = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Errore nel caricamento delle carte. Riprova più tardi.')),
      );
      return;
    }
    for (var card in cards) {
      user.addCard(card);
    }
    user.updateLastPackOpenTime();
    final authService = AuthService();
    await authService.syncUserData(user);
    setState(() {
      isOpeningPack = false;
      drawnCards = cards;
    });
  }

  void _unlockWithCoins() {
    if (selectedPack == null) return;
    final user = Provider.of<User>(context, listen: false);
    final authService = AuthService();
    if (user.spendCoins(selectedPack!.baseCost)) {
      authService.syncUserData(user);
      _openPack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunuè Coin insufficienti!')),
      );
    }
  }

  void _showNextCard() {
    if (drawnCards != null && currentCardIndex < drawnCards!.length - 1) {
      setState(() {
        currentCardIndex++;
        _currentCardOffset = 0;
      });
    } else {
      // Se siamo all'ultima carta, torniamo alla schermata dei pacchetti
      setState(() {
        drawnCards = null;
        currentCardIndex = 0;
        _currentCardOffset = 0;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStartPosition == null) return;

    final dx = details.globalPosition.dx - _dragStartPosition!.dx;

    setState(() {
      // Limita lo spostamento orizzontale
      _currentCardOffset = dx.clamp(-200.0, 200.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    // Velocità di swipe
    final velocity = details.velocity.pixelsPerSecond.dx;

    // Decidi se è uno swipe basato sulla posizione o sulla velocità
    final isSwipe = _currentCardOffset.abs() > 100 || velocity.abs() > 800;

    if (isSwipe) {
      // Determina la direzione dello swipe
      final isRight = _currentCardOffset > 0 || velocity > 0;

      if (!isRight) {
        // Swipe a sinistra: prossima carta
        _showNextCard();
      } else {
        // Swipe a destra: carta precedente (opzionale)
        if (currentCardIndex > 0 && drawnCards != null) {
          setState(() {
            currentCardIndex--;
            _currentCardOffset = 0;
          });
        } else {
          // Torna ai pacchetti se si swipa a destra sulla prima carta
          setState(() {
            drawnCards = null;
            currentCardIndex = 0;
            _currentCardOffset = 0;
          });
        }
      }
    } else {
      // Non è uno swipe, rimetti la carta in posizione
      setState(() {
        _currentCardOffset = 0;
      });
    }

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _navigateToLuckyWheel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LuckyWheelPage(),
      ),
    );
  }

  void _navigateToMissions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MissionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunuè Collection'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${user.tunueCoins}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: isOpeningPack
            ? _buildOpeningPackAnimation()
            : drawnCards != null
                ? _buildPackResults()
                : _buildPackDisplay(user),
      ),
    );
  }

  Widget _buildPackDisplay(User user) {
    if (packs.isEmpty) {
      return const Text('Nessun pacchetto disponibile.');
    }
    final canOpenFreePack = user.canOpenFreePack();
    final timeLeft = user.timeUntilNextFreePack();
    final coinCost = timeLeft.inHours + 1;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Scegli un pacchetto da aprire:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: packs.map((pack) {
              final isSelected = selectedPack?.id == pack.id;
              return Flexible(
                flex: isSelected ? 4 : 2,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: GestureDetector(
                    onTap: () => _selectPack(pack),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: PackWidget(
                        pack: pack,
                        showDetails: true,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          CountdownTimer(
            duration: user.timeUntilNextFreePack(),
            tunueCoins: user.tunueCoins,
            onComplete: () {
              setState(() {}); // Forza il rebuild per aggiornare l'interfaccia
            },
            textStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (selectedPack != null)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 250),
              child: canOpenFreePack
                  ? ElevatedButton(
                      onPressed: _openPack,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Apri Pacchetto'),
                    )
                  : ElevatedButton(
                      onPressed: _unlockWithCoins,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text('Sblocca con $coinCost Tunuè Coin'),
                    ),
            ),

          // Separatore
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(thickness: 1),
          ),

          // Sezione per Ruota della Fortuna e Missioni
          const Text('Altre Attività',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Contenitore per le due sezioni
          Row(
            children: [
              // Ruota della Fortuna
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToLuckyWheel,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.motion_photos_on,
                            size: 40,
                            color: Colors.amber,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ruota della Fortuna',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gira e vinci!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Missioni
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToMissions,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 40,
                            color: Colors.green,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Missioni',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Completa e ottieni ricompense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOpeningPackAnimation() {
    return ScaleTransition(
      scale: _animation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Qui idealmente ci sarebbe un'animazione GIF o Lottie
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 7, 255, 90).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 100,
              color: Color.fromARGB(255, 7, 255, 90),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Apertura pacchetto in corso...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 7, 255, 90)),
          ),
        ],
      ),
    );
  }

  Widget _buildPackResults() {
    if (drawnCards == null || drawnCards!.isEmpty) {
      return const Center(
        child: Text("Nessuna carta ottenuta"),
      );
    }

    final currentCard = drawnCards![currentCardIndex];
    final isLastCard = currentCardIndex >= drawnCards!.length - 1;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcola l'angolo di rotazione basato sul movimento
    final rotationAngle = _currentCardOffset / 1000;

    // Calcola l'opacità in base a quanto è lontana la carta
    final opacity = 1.0 - (_currentCardOffset.abs() / 200).clamp(0.0, 0.5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Carta ${currentCardIndex + 1} di ${drawnCards!.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Text(
          'Scorri a sinistra per vedere la prossima carta',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 20),

        // Visualizzazione singola carta con swipe
        GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(_currentCardOffset, 0),
            child: Transform.rotate(
              angle: rotationAngle,
              child: Opacity(
                opacity: opacity,
                child: SizedBox(
                  width: CardConstants.homeCardWidth,
                  height: CardConstants.homeCardHeight,
                  child: Hero(
                    tag: 'card_${currentCard.id}',
                    child: CardWidget(
                      card: currentCard,
                      isHomePage: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currentCard.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (currentCard.quantity > 1) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: CollectionCard
                                                      .getRarityColor(
                                                          currentCard.rarity),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Text(
                                                'x${currentCard.quantity}',
                                                style: TextStyle(
                                                  color: CollectionCard
                                                      .getRarityColor(
                                                          currentCard.rarity),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  CollectionCard.getRarityColor(
                                                      currentCard.rarity),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              CollectionCard.getRarityString(
                                                  currentCard.rarity),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AspectRatio(
                                    aspectRatio:
                                        CardConstants.detailCardAspectRatio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Image.network(
                                        currentCard.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                    child: Icon(Icons.image,
                                                        size: 80)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Descrizione:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentCard.description,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    child: const Text('Chiudi'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Indicatori delle carte
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            drawnCards!.length,
            (index) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentCardIndex
                    ? CollectionCard.getRarityColor(drawnCards![index].rarity)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
