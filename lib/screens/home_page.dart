// screens/home_page.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../constants/card_constants.dart';
import '../models/card.dart';
import '../models/pack.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import '../services/supabase_service.dart';
import '../widgets/card_widget.dart';
import '../widgets/countdown_timer.dart';
import 'lucky_wheel_page.dart';
import 'missions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Pack> packs = [];
  Pack? selectedPack;
  bool isOpeningPack = false;
  List<CollectionCard>? drawnCards;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int currentCardIndex = 0;
  String selectedDropdownValue = 'Monster Allergy'; // Variabile per il dropdown

  // Controller per il video
  VideoPlayerController? _videoController;

  // Variabili per il carousel 3D
  int _centralPackIndex = 0;
  late AnimationController _carouselController;
  late Animation<double> _carouselAnimation;
  final double _carouselOffset = 0.0;
  final bool _isCarouselDragging = false;

  // Controller per ListWheelScrollView
  FixedExtentScrollController? _wheelController;

  // Controllo swipe
  Offset? _dragStartPosition;
  bool _isDragging = false;
  double _currentCardOffset = 0;

  // Modalità pacchetto ingrandito
  bool _isPacketEnlarged = false;

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

    // Controller per il carousel 3D
    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _carouselAnimation = CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    );

    // Inizializza il video controller
    _initializeVideo();

    _loadPacks();
  }

  void _initializeVideo() async {
    _videoController =
        VideoPlayerController.asset('assets/videos/background_packs.mp4');
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(0.0); // Video senza audio
    _videoController!.play();
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _carouselController.dispose();
    _wheelController?.dispose();
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
      if (loadedPacks.isNotEmpty) {
        // Calcola l'indice centrale
        _centralPackIndex = loadedPacks.length ~/ 2;
        selectedPack = loadedPacks[_centralPackIndex];

        // Crea il controller al centro
        _wheelController?.dispose(); // Dispose del vecchio se esiste
        _wheelController =
            FixedExtentScrollController(initialItem: _centralPackIndex);
      } else {
        _centralPackIndex = 0;
        selectedPack = null;
      }
    });
  }

  void _selectPack(Pack pack) {
    setState(() {
      selectedPack = pack;
    });
  }

  void _openPack() async {
    if (selectedPack == null) return;
    print('DEBUG: Inizio apertura pacchetto ${selectedPack!.name}');
    print('DEBUG: Pack ID: "${selectedPack!.id}"');

    // Controllo aggiuntivo per verificare che l'id non sia null o vuoto
    if (selectedPack!.id.isEmpty) {
      print('DEBUG: ERRORE - Pack ID è vuoto!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore: Pacchetto non valido')),
      );
      return;
    }

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
    print('DEBUG: Caricamento carte...');
    final cardService = CardService();
    await cardService.loadCards();
    print('DEBUG: Carte caricate, generazione carte casuali...');
    try {
      final cards = cardService.getRandomCards(5, selectedPack!.id);
      print('DEBUG: Carte generate: ${cards.length}');
      for (var card in cards) {
        print('DEBUG: Carta: ${card.name} - ${card.rarity}');
      }
      if (cards.isEmpty) {
        print('DEBUG: Nessuna carta trovata!');
        setState(() {
          isOpeningPack = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Errore nel caricamento delle carte. Riprova più tardi.')),
        );
        return;
      }
      print('DEBUG: Aggiunta carte all\'utente...');
      for (var card in cards) {
        user.addCard(card);
      }
      user.updateLastPackOpenTime();
      print('DEBUG: Sincronizzazione dati...');
      final authService = AuthService();
      await authService.syncUserData(user);
      print('DEBUG: Completato! Showing cards...');
      setState(() {
        isOpeningPack = false;
        drawnCards = cards;
      });
    } catch (e) {
      print('DEBUG: Errore durante getRandomCards: $e');
      setState(() {
        isOpeningPack = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
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

  void _goToNextPack() {
    if (packs.isEmpty) return;

    final nextIndex = (_centralPackIndex + 1) % packs.length;
    _wheelController?.animateToItem(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPack() {
    if (packs.isEmpty) return;

    final prevIndex = (_centralPackIndex - 1 + packs.length) % packs.length;
    _wheelController?.animateToItem(
      prevIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _selectCentralPack() {
    if (packs.isNotEmpty && _centralPackIndex < packs.length) {
      setState(() {
        // Seleziona il pacchetto centrale senza aprire l'overlay
        selectedPack = packs[_centralPackIndex];
        // Solo se si vuole aprire l'overlay, impostare _isPacketEnlarged = true
        // _isPacketEnlarged = true;
      });

      // Feedback tattile per confermare la selezione
      // HapticFeedback.mediumImpact(); // Opzionale
    }
  }

  void _openEnlargedView() {
    if (packs.isNotEmpty && _centralPackIndex < packs.length) {
      setState(() {
        _isPacketEnlarged = true;
        selectedPack = packs[_centralPackIndex];
      });
    }
  }

  void _closeEnlargedPack() {
    setState(() {
      _isPacketEnlarged = false;
      // Non resettare selectedPack, mantieni il pacchetto attualmente selezionato
      // selectedPack = null;
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

  void _openPackFromOverlay() async {
    // Chiudi prima l'overlay
    _closeEnlargedPack();
    // Poi apri il pacchetto
    _openPack();
  }

  void _unlockWithCoinsFromOverlay() async {
    // Chiudi prima l'overlay
    _closeEnlargedPack();
    // Poi sblocca con le coin (che chiamerà automaticamente _openPack)
    _unlockWithCoins();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Contenuto principale
          isOpeningPack
              ? _buildOpeningPackAnimation()
              : drawnCards != null
                  ? _buildPackResults()
                  : _buildPackDisplay(user),

          // Overlay pacchetto ingrandito
          if (_isPacketEnlarged && selectedPack != null)
            Material(
              color: Colors.transparent,
              elevation: 100,
              child: _buildEnlargedPackOverlay(),
            ),
        ],
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 58), // Margin top di 58 pixel
          CountdownTimer(
            duration: user.timeUntilNextFreePack(),
            tunueCoins: user.tunueCoins,
            onComplete: () {
              setState(() {}); // Forza il rebuild per aggiornare l'interfaccia
            },
            textStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          ),

          Transform.translate(
            offset: const Offset(0, -8),
            child: IntrinsicHeight(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: [
                    // Row per le icone laterali (invisibili)
                    Row(
                      children: [
                        // Icona sinistra
                        Container(
                          child: Image.asset(
                            'assets/images/icons/png/vetrina_icon.png',
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.filter_list,
                                color: Colors.blue,
                                size: 48,
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                        // Icona destra con testo "oggetti"
                        Transform.translate(
                          offset: const Offset(12, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                child: Image.asset(
                                  'assets/images/icons/png/oggetti_icon.png',
                                  width: 64,
                                  height: 64,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.inventory,
                                      color: Colors.green,
                                      size: 24,
                                    );
                                  },
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12),
                                child: const Text(
                                  'Oggetti',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color.fromARGB(255, 175, 176, 185),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Dropdown centrato rispetto alla pagina
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Mostra il menu dropdown personalizzato
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: const Text('Monster Allergy'),
                                      onTap: () {
                                        setState(() {
                                          selectedDropdownValue =
                                              'Monster Allergy';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      title: const Text('Avatar Airbender'),
                                      onTap: () {
                                        setState(() {
                                          selectedDropdownValue =
                                              'Avatar Airbender';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      title: const Text('Sonic'),
                                      onTap: () {
                                        setState(() {
                                          selectedDropdownValue = 'Sonic';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: ShapeDecoration(
                            gradient: LinearGradient(
                              begin: const Alignment(0.07, 0.08),
                              end: const Alignment(0.91, 0.97),
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0)
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignCenter,
                                color: Color(0xFFDADCE7),
                              ),
                              borderRadius: BorderRadius.circular(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                selectedDropdownValue,
                                style: const TextStyle(
                                  color: Color(0xFF7B7D8A),
                                  fontSize: 14,
                                  fontFamily: 'Neue Haas Grotesk Display Pro',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF7B7D8A),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ListWheelScrollView orizzontale per i pacchetti con video background
          Container(
            height: 350, // Aumentato da 280 a 450 per contenere il modello
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: packs.isEmpty || _wheelController == null
                ? const Center(child: Text('Nessun pacchetto disponibile.'))
                : Stack(
                    children: [
                      // Video di background
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        Positioned.fill(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          ),
                        ),
                      // ListWheelScrollView sopra il video
                      Container(
                        child: RotatedBox(
                          quarterTurns:
                              3, // Ruota di 270° per renderlo orizzontale
                          child: ListWheelScrollView.useDelegate(
                            controller: _wheelController!,
                            itemExtent: 200, // Rimesso a 200 come richiesto
                            perspective:
                                0.001, // Ridotto da 0.002 per meno inclinazione
                            diameterRatio:
                                1.8, // Ridotto da 2.0 a 1.8 per più compattezza
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _centralPackIndex = index;
                                selectedPack = packs[index];
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index >= packs.length)
                                  return null;
                                return RotatedBox(
                                  quarterTurns:
                                      1, // Ruota gli elementi di 90° per compensare
                                  child: _buildWheelPackItem(
                                    packs[index],
                                    index == _centralPackIndex,
                                  ),
                                );
                              },
                              childCount: packs.length,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Sezione per Ruota della Fortuna e Missioni
          const SizedBox(height: 8),

          // Contenitore per le due sezioni
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Ruota della Fortuna
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToLuckyWheel,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 0),
                            blurRadius: 16,
                            spreadRadius: 0,
                            color: const Color(0xFF666666).withOpacity(0.25),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Parte bianca di base
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          // Parte blu diagonale
                          ClipPath(
                            clipper: DiagonalClipper(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF7F9CFB).withOpacity(0.16),
                                    const Color(0xFF0F4CF3).withOpacity(0.16),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                          // Contenuto sopra
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/icons/png/lucky-wheel_icon.png',
                                    width: 56,
                                    height: 56,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.motion_photos_on,
                                        size: 40,
                                        color: Colors.amber,
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Lucky Wheel',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Lucky Wheel duplicato
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToMissions,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 0),
                            blurRadius: 16,
                            spreadRadius: 0,
                            color: const Color(0xFF666666).withOpacity(0.25),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Parte bianca di base
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          // Parte blu diagonale
                          ClipPath(
                            clipper: DiagonalClipper(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFB7F86).withOpacity(0.16),
                                    const Color(0xFFF30F39).withOpacity(0.16),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                          // Contenuto sopra
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/icons/png/missioni_icon.png',
                                    width: 46,
                                    height: 46,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.motion_photos_on,
                                        size: 40,
                                        color: Colors.amber,
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Missioni',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    '8/12',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildEnlargedPackOverlay() {
    final user = Provider.of<User>(context);
    final canOpenFreePack = user.canOpenFreePack();
    final timeLeft = user.timeUntilNextFreePack();
    final coinCost = timeLeft.inHours + 1;

    return WillPopScope(
      onWillPop: () async {
        _closeEnlargedPack();
        return false; // Previene la chiusura automatica dell'app
      },
      child: Stack(
        children: [
          // Overlay con sfondo blurrato
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // GestureDetector per chiudere toccando fuori, ma non interferisce con i bottoni
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeEnlargedPack,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: GestureDetector(
                      onTap: () {}, // Blocca il tap sui contenuti interni
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pacchetto ingrandito
                          Hero(
                            tag: 'enlarged_pack_${selectedPack!.id}',
                            child: Container(
                              width: 250,
                              height: 350,
                              decoration: BoxDecoration(
                                // Se non ha modello 3D, usa l'immagine
                                image: selectedPack!.model3D == null
                                    ? DecorationImage(
                                        image:
                                            NetworkImage(selectedPack!.image),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: selectedPack!.model3D != null
                                    ? Colors.black87
                                    : null,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  // Prima ombra
                                  BoxShadow(
                                    color: const Color(0xFF35ABD7)
                                        .withOpacity(0.70),
                                    spreadRadius: 35,
                                    blurRadius: 94.5,
                                    offset: const Offset(0, 0),
                                  ),
                                  // Seconda ombra (Drop shadow)
                                  BoxShadow(
                                    color: const Color(0xFF00ADFF)
                                        .withOpacity(0.85),
                                    spreadRadius: 1,
                                    blurRadius: 73.5,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: selectedPack!.model3D != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: ModelViewer(
                                        backgroundColor:
                                            const Color(0x00000000),
                                        src: selectedPack!.model3D!,
                                        alt: selectedPack!.name,
                                        ar: false,
                                        autoRotate: false,
                                        cameraControls: true,
                                        disableZoom: true,
                                        disablePan: true,
                                        disableTap: true,
                                        cameraOrbit: '0deg 85deg 85%',
                                        minCameraOrbit: 'auto 85deg auto',
                                        maxCameraOrbit: 'auto 85deg auto',
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: ModelViewer(
                                        backgroundColor:
                                            const Color(0x00000000),
                                        src: 'assets/models/pack.glb',
                                        alt: selectedPack!.name,
                                        ar: false,
                                        autoRotate: false,
                                        cameraControls: true,
                                        disableZoom: true,
                                        disablePan: true,
                                        disableTap: true,
                                        interactionPrompt:
                                            InteractionPrompt.none,
                                        cameraOrbit: '0deg 85deg 85%',
                                        minCameraOrbit: 'auto 85deg auto',
                                        maxCameraOrbit: 'auto 85deg auto',
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            selectedPack!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          // Bottone di azione
                          canOpenFreePack
                              ? ElevatedButton(
                                  onPressed: () {
                                    _openPackFromOverlay();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  child: const Text('Apri Pacchetto'),
                                )
                              : Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _unlockWithCoinsFromOverlay();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        decoration: ShapeDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF13C931),
                                              Color(0xFF3CCC7E),
                                            ],
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(80),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 8),
                                            Text(
                                              'Sblocca pacchetto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily:
                                                    'Neue Haas Grotesk Display Pro',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Badge con numero di coin
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFACB0B3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/icons/tunue_logo.png',
                                              width: 32,
                                              height: 32,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$coinCost',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelPackItem(Pack pack, bool isSelected) {
    // Debug per vedere se il modello 3D è presente
    print('DEBUG: Pack ${pack.name} - model3D: ${pack.model3D}');

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          // Se è selezionato, apri l'overlay
          _openEnlargedView();
        } else {
          // Se non è selezionato, naviga verso di esso
          final index = packs.indexOf(pack);
          _wheelController?.animateToItem(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Stack(
        children: [
          // Solo il modello 3D puro senza alcun container
          const Center(
            child: SizedBox(
              width: 280, // Larghezza piena per il viewport
              height:
                  420, // Aumentato ancora per eliminare completamente i tagli inferiori
              child: ModelViewer(
                backgroundColor: Color(0x00000000),
                src: 'assets/models/pack.glb',
                alt: 'Pack 3D Model',
                ar: false,
                autoRotate: false, // Rimossa la rotazione automatica
                cameraControls: true, // Riabilita i controlli
                disableZoom: true,
                interactionPrompt: InteractionPrompt.none, // Elimina la manina
                cameraOrbit:
                    '0deg 85deg 85%', // Ruotato leggermente verso l'alto (da 75deg a 85deg)
                minCameraOrbit:
                    'auto 85deg auto', // Aggiornato anche qui per coerenza
                maxCameraOrbit:
                    'auto 85deg auto', // Aggiornato anche qui per coerenza
              ),
            ),
          ),
          // Nome fluttuante sotto il modello
          if (isSelected)
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Text(
                pack.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Crea una forma diagonale spostata più in basso
    path.moveTo(2, size.height * 0);
    path.lineTo(size.width * 2, 0);
    path.lineTo(0, size.height * 0.6);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
