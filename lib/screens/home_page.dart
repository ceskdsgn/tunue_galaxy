// screens/home_page.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
import '../widgets/infinite_dragable_slider.dart';
import '../widgets/pack_cards_slider.dart';
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
  bool isLoading = true;

  // Variabili per tracciare il completamento del caricamento
  bool _isVideoLoaded = false;
  bool _arePacksLoaded = false;
  bool _areCardsLoaded = false;
  bool _arePackImagesLoaded = false;
  bool _areCardImagesLoaded = false;
  bool _areUIAssetsLoaded = false;

  List<CollectionCard>? drawnCards;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int currentCardIndex = 0;
  String selectedDropdownValue = 'Monster Allergy'; // Variabile per il dropdown

  // Controller per il video
  VideoPlayerController? _videoController;

  // Controller per il video della carta Zanne della foresta
  VideoPlayerController? _aangVideoController;

  // Variabili per il carousel 3D
  int _centralPackIndex = 0;
  late AnimationController _carouselAnimationController;
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
  // Stato animazione apertura pacchetto
  bool _isPackOpeningAnimation = false;
  // Controller animazione apertura pacchetto
  late AnimationController _packOpenAnimationController;
  late Animation<double> _packOpenAnimation;

  // Controller per l'animazione di chiusura overlay
  late AnimationController _overlayCloseController;
  late Animation<double> _overlayCloseAnimation;

  // Controller per l'animazione di apertura overlay
  late AnimationController _overlayOpenController;
  late Animation<double> _overlayOpenAnimation;

  // 1. Dichiarazione controller e animazione
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // 1. Dichiarazione controller e animazione per la rotazione
  late AnimationController _floatRotationController;
  late Animation<double> _floatRotationAnimation;

  // Variabili per il meccanismo dello slider nell'apertura pacchetti
  bool _isSliderActive = false;
  double _sliderValue = 0.0;
  bool _hasSliderCompleted = false;

  // Controller per l'animazione della scia luminosa
  late AnimationController _trailController;
  late Animation<double> _trailAnimation;

  late AnimationController _cardEnterAnimationController;
  late List<Animation<double>> _cardEnterAnimations;

  // Variabili per tracciare le carte nuove
  Set<String> _previouslyOwnedCardIds = {};
  int _centerCardIndex = 0;

  // Animazione per il badge "Nuova"
  late AnimationController _newBadgeController;
  late Animation<double> _newBadgeScaleAnimation;
  late Animation<double> _newBadgeOpacityAnimation;

  // Animazione per le ombre colorate
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Animazione loop per l'effetto pulsante
  late AnimationController _glowPulseController;
  late Animation<double> _glowPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Inizializza le animazioni prima di tutto
    _initializeAnimations();

    // Inizializza il video
    _initializeVideo();

    // Inizializza il video della carta Zanne della foresta
    _initializeAangVideo();

    // Carica le risorse in parallelo
    _loadAllResources();
  }

  void _initializeAnimations() {
    // Controller per l'animazione
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Controller per l'animazione del carousel
    _carouselAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _carouselAnimation = CurvedAnimation(
      parent: _carouselAnimationController,
      curve: Curves.easeInOut,
    );

    // Controller per l'animazione di chiusura overlay
    _overlayCloseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _overlayCloseAnimation = CurvedAnimation(
      parent: _overlayCloseController,
      curve: Curves.easeInOut,
    );

    // Controller per l'animazione di apertura overlay
    _overlayOpenController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _overlayOpenAnimation = CurvedAnimation(
      parent: _overlayOpenController,
      curve: Curves.easeInOut,
    );

    // 2. Inizializzazione in initState
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -2.8, end: 2.8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 2. Inizializzazione in initState
    _floatRotationController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat(reverse: true);
    _floatRotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(
          parent: _floatRotationController, curve: Curves.easeInOut),
    );

    // Controller animazione apertura pacchetto
    _packOpenAnimationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _packOpenAnimation = CurvedAnimation(
      parent: _packOpenAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Controller per l'animazione della scia luminosa
    _trailController = AnimationController(
      duration: const Duration(milliseconds: 2800), // Rallentato
      vsync: this,
    )..repeat(reverse: true);
    _trailAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trailController, curve: Curves.easeInOut),
    );

    // Listener per l'animazione del pacchetto con meccanismo slider
    _packOpenAnimationController.addListener(() {
      // Non facciamo nulla qui, lasciamo che l'animazione si completi
    });

    _packOpenAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !_isSliderActive &&
          !_hasSliderCompleted) {
        // Quando l'animazione è completata, attiva lo slider
        setState(() {
          _isSliderActive = true;
        });
      } else if (status == AnimationStatus.completed && _hasSliderCompleted) {
        // Chiudi overlay e apri pacchetto dopo che lo slider è stato completato
        setState(() {
          _isPacketEnlarged = false;
          _isPackOpeningAnimation = false;
          _isSliderActive = false;
          _hasSliderCompleted = false;
          _sliderValue = 0.0;
        });
        openPack();
      }
    });

    // Controller per l'animazione di entrata delle carte
    _cardEnterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Inizializza la lista delle animazioni
    _cardEnterAnimations = [];

    // Controller per l'animazione del badge "Nuova"
    _newBadgeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _newBadgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _newBadgeController,
        curve: Curves.elasticOut,
      ),
    );

    _newBadgeOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _newBadgeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Controller per l'animazione delle ombre colorate
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Controller per l'animazione pulsante loop
    _glowPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowPulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Listener per avviare il loop dopo l'animazione iniziale
    _glowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowPulseController.repeat(reverse: true);
      }
    });
  }

  void _initializeCardAnimations() {
    if (drawnCards == null) return;

    _cardEnterAnimations = List.generate(
      drawnCards!.length,
      (index) {
        final delay = index * 0.2; // Ritardo di 0.2 secondi tra ogni carta
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _cardEnterAnimationController,
            curve: Interval(
              delay,
              delay + 0.4, // Durata di 0.4 secondi per ogni carta
              curve: Curves.easeOutCubic,
            ),
          ),
        );
      },
    );
  }

  void _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.asset('assets/videos/background_packs.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0); // Video senza audio

      // Aspetta un frame per assicurarsi che il video sia pronto
      await Future.delayed(const Duration(milliseconds: 100));
      _videoController!.play();

      setState(() {
        _isVideoLoaded = true;
      });

      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore nel caricamento del video: $e');
      setState(() {
        _isVideoLoaded = true; // Considera caricato anche in caso di errore
      });
      _checkAllResourcesLoaded();
    }
  }

  void _initializeAangVideo() async {
    try {
      _aangVideoController =
          VideoPlayerController.asset('assets/videos/immersive_card.mp4');
      await _aangVideoController!.initialize();
      _aangVideoController!.setLooping(false);
      _aangVideoController!
          .setVolume(1.0); // Video con audio per la carta Zanne della foresta
      // Non far partire il video automaticamente
      print('Video Zanne della foresta inizializzato con successo');
    } catch (e) {
      print('Errore nel caricamento del video Zanne della foresta: $e');
    }
  }

  void _loadAllResources() async {
    // Carica le carte
    _loadCards();

    // Carica i pacchetti
    loadPacks();

    // Precarica gli asset UI
    _preloadUIAssets();
  }

  void _loadCards() async {
    try {
      await Provider.of<CardService>(context, listen: false).loadCards();
      setState(() {
        _areCardsLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore nel caricamento delle carte: $e');
      setState(() {
        _areCardsLoaded = true; // Considera caricato anche in caso di errore
      });
      _checkAllResourcesLoaded();
    }
  }

  void _checkAllResourcesLoaded() {
    if (_isVideoLoaded &&
        _arePacksLoaded &&
        _areCardsLoaded &&
        _arePackImagesLoaded &&
        _areCardImagesLoaded &&
        _areUIAssetsLoaded) {
      // Buffer più grande per assicurarsi che tutte le immagini siano completamente renderizzate
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _preloadPackImages() async {
    if (packs.isEmpty) {
      setState(() {
        _arePackImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
      return;
    }

    try {
      // Uso Future.wait per assicurarmi che TUTTE le immagini siano caricate
      await Future.wait(packs.map((pack) async {
        try {
          final image = NetworkImage(pack.image);
          await precacheImage(image, context);
          // Triplo controllo: aspetto che sia effettivamente caricata e renderizzabile
          await Future.delayed(const Duration(milliseconds: 200));
          // Verifica aggiuntiva del caricamento
          final completer = Completer<void>();
          image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, call) {
              if (!completer.isCompleted) completer.complete();
            }),
          );
          await completer.future
              .timeout(const Duration(seconds: 2), onTimeout: () {});
          print('✅ Precaricata immagine pacchetto: ${pack.name}');
        } catch (e) {
          print('❌ Errore nel caricamento immagine pacchetto ${pack.name}: $e');
        }
      }));

      setState(() {
        _arePackImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload pacchetti: $e');
      setState(() {
        _arePackImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  Future<void> _preloadCardImages() async {
    try {
      if (selectedPack == null || _areCardsLoaded == false) {
        setState(() {
          _areCardImagesLoaded = true;
        });
        _checkAllResourcesLoaded();
        return;
      }

      final cardService = Provider.of<CardService>(context, listen: false);
      final allCards = cardService.getAllCards();
      final packCards =
          allCards.where((card) => card.packId == selectedPack!.id).toList();

      if (packCards.isEmpty) {
        setState(() {
          _areCardImagesLoaded = true;
        });
        _checkAllResourcesLoaded();
        return;
      }

      // Precarica solo le prime 15 carte per evitare di sovraccaricare
      final cardsToPreload = packCards.take(15).toList();

      await Future.wait(cardsToPreload.map((card) async {
        try {
          final image = NetworkImage(card.imageUrl);
          await precacheImage(image, context);
          // Tempo maggiore per le carte che sono più pesanti
          await Future.delayed(const Duration(milliseconds: 300));
          // Verifica aggiuntiva del caricamento
          final completer = Completer<void>();
          image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, call) {
              if (!completer.isCompleted) completer.complete();
            }),
          );
          await completer.future
              .timeout(const Duration(seconds: 3), onTimeout: () {});
          print('✅ Precaricata immagine carta: ${card.name}');
        } catch (e) {
          print('❌ Errore nel caricamento immagine carta ${card.name}: $e');
        }
      }));

      setState(() {
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload carte: $e');
      setState(() {
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  Future<void> _preloadUIAssets() async {
    try {
      final assetPaths = [
        'assets/images/icons/png/vetrina_icon.png',
        'assets/images/icons/png/oggetti_icon.png',
        'assets/images/icons/png/lucky-wheel_icon.png',
        'assets/images/icons/png/missioni_icon.png',
        'assets/images/logos/monster-allergy_logo.png',
        'assets/images/logos/avatar_logo.png',
        'assets/images/logos/sonic_logo.png',
        'assets/images/icons/tunue_logo.png',
      ];

      // Uso Future.wait per caricare tutto in parallelo e aspettare la fine
      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          // Doppio controllo per essere sicuri
          await Future.delayed(const Duration(milliseconds: 50));
          print('✅ Precaricato asset: $assetPath');
        } catch (e) {
          print('❌ Errore nel caricamento asset $assetPath: $e');
        }
      }));

      // Precarica anche le immagini delle carte del slider se disponibili
      await _preloadSliderCardImages();

      setState(() {
        _areUIAssetsLoaded = true;
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload UI assets: $e');
      setState(() {
        _areUIAssetsLoaded = true;
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  Future<void> _preloadSliderCardImages() async {
    if (selectedPack == null || !_areCardsLoaded) return;

    try {
      final cardService = Provider.of<CardService>(context, listen: false);
      final allCards = cardService.getAllCards();
      final packCards = allCards
          .where((card) => card.packId == selectedPack!.id)
          .take(8)
          .toList();

      if (packCards.isEmpty) return;

      // Precarica le prime 8 carte del slider per essere sicuri
      await Future.wait(packCards.map((card) async {
        try {
          final image = NetworkImage(card.imageUrl);
          await precacheImage(image, context);
          // Triplo controllo per le carte del slider che sono visibili subito
          await Future.delayed(const Duration(milliseconds: 150));
          print('✅ Precaricata carta slider: ${card.name}');
        } catch (e) {
          print('❌ Errore nel caricamento carta slider ${card.name}: $e');
        }
      }));
    } catch (e) {
      print('Errore nel preload carte slider: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _aangVideoController?.dispose();
    _carouselAnimationController.dispose();
    _overlayCloseController.dispose();
    _overlayOpenController.dispose();
    _wheelController?.dispose();
    _floatController.dispose();
    _floatRotationController.dispose();
    _packOpenAnimationController.dispose();
    _trailController.dispose();
    _cardEnterAnimationController.dispose();
    _newBadgeController.dispose();
    _glowController.dispose();
    _glowPulseController.dispose();
    super.dispose();
  }

  Future<void> loadPacks() async {
    try {
      final supabaseService = SupabaseService();
      final loadedPacks = await supabaseService.getAllPacks();
      print('Pacchetti caricati:');
      for (final p in loadedPacks) {
        print('id: ${p.id} - name: ${p.name} - image: ${p.image}');
      }

      // Riordina i pacchetti per mettere Air Power al centro
      if (loadedPacks.length >= 3) {
        final airPowerIndex =
            loadedPacks.indexWhere((pack) => pack.name == 'Air Power');
        if (airPowerIndex != -1) {
          final airPower = loadedPacks.removeAt(airPowerIndex);
          loadedPacks.insert(1, airPower); // Inserisce Air Power al centro
        }
      }

      setState(() {
        packs = loadedPacks;
        if (loadedPacks.isNotEmpty) {
          _centralPackIndex = 1; // Imposta l'indice centrale a 1 (Air Power)
          selectedPack = loadedPacks[_centralPackIndex];

          _wheelController?.dispose();
          _wheelController =
              FixedExtentScrollController(initialItem: _centralPackIndex);
        } else {
          _centralPackIndex = 0;
          selectedPack = null;
        }
        _arePacksLoaded = true;
      });

      // Precarica le immagini dei pacchetti
      await _preloadPackImages();
    } catch (e) {
      print('Errore nel caricamento dei pacchetti: $e');
      setState(() {
        _arePacksLoaded = true;
        _arePackImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  void selectPack(Pack pack) {
    setState(() {
      selectedPack = pack;
    });
  }

  void openPack() async {
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

    // Memorizza le carte che l'utente possedeva prima dell'apertura del pacchetto
    _previouslyOwnedCardIds = Set.from(user.ownedCards.map((card) => card.id));

    // Scala i Tunue Coin prima di aprire il pacchetto
    if (!user.canOpenFreePack()) {
      user.spendCoins(selectedPack!.baseCost);
    }

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

      // Ordina le carte per rarità
      cards.sort((a, b) {
        // Ordine delle rarità usando l'enum CardRarity
        final rarityOrder = {
          CardRarity.common: 0,
          CardRarity.rare: 1,
          CardRarity.superRare: 2,
          CardRarity.ultraRare: 3,
          CardRarity.gold: 4,
        };

        // Usa direttamente l'enum per l'ordinamento
        return rarityOrder[a.rarity]!.compareTo(rarityOrder[b.rarity]!);
      });

      print('DEBUG: Carte ordinate per rarità:');
      for (var card in cards) {
        print('DEBUG: Carta: ${card.name} - ${card.rarity} - ID: ${card.id}');
        if (card.name.toLowerCase().contains('zanne della foresta')) {
          print('🎯 TROVATA CARTA ZANNE DELLA FORESTA: ${card.name}');
        }
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

      // Reinizializza il video quando si mostrano le carte
      if (_videoController != null) {
        await _videoController!.dispose();
      }
      _videoController =
          VideoPlayerController.asset('assets/videos/background_packs.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      _videoController!.play();

      setState(() {
        isOpeningPack = false;
        drawnCards = cards;
      });

      // Inizializza le animazioni per le nuove carte
      _initializeCardAnimations();

      // Avvia l'animazione di entrata delle carte
      _cardEnterAnimationController.reset();
      _cardEnterAnimationController.forward();
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

  void unlockWithCoins() {
    if (selectedPack == null) return;
    final user = Provider.of<User>(context, listen: false);
    final authService = AuthService();
    if (user.spendCoins(selectedPack!.baseCost)) {
      authService.syncUserData(user);
      openPack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunuè Coin insufficienti!')),
      );
    }
  }

  void showNextCard() {
    if (drawnCards != null && currentCardIndex < drawnCards!.length - 1) {
      setState(() {
        currentCardIndex++;
        _currentCardOffset = 0;
      });
    } else {
      // Se siamo all'ultima carta, torniamo alla schermata dei pacchetti
      // Ferma il video di Zanne della foresta se è in riproduzione
      if (_aangVideoController != null) {
        _aangVideoController!.pause();
        _aangVideoController!.seekTo(Duration.zero);
      }
      setState(() {
        drawnCards = null;
        currentCardIndex = 0;
        _currentCardOffset = 0;
      });
    }
  }

  void handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
    });
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStartPosition == null) return;

    final dx = details.globalPosition.dx - _dragStartPosition!.dx;

    setState(() {
      // Limita lo spostamento orizzontale
      _currentCardOffset = dx.clamp(-200.0, 200.0);
    });
  }

  void handleDragEnd(DragEndDetails details) {
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
        showNextCard();
      } else {
        // Swipe a destra: carta precedente (opzionale)
        if (currentCardIndex > 0 && drawnCards != null) {
          setState(() {
            currentCardIndex--;
            _currentCardOffset = 0;
          });
        } else {
          // Torna ai pacchetti se si swipa a destra sulla prima carta
          // Ferma il video di Zanne della foresta se è in riproduzione
          if (_aangVideoController != null) {
            _aangVideoController!.pause();
            _aangVideoController!.seekTo(Duration.zero);
          }
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

  void goToNextPack() {
    if (packs.isEmpty) return;

    final nextIndex = (_centralPackIndex + 1) % packs.length;
    _carouselAnimationController.forward(from: 0.0);
    _wheelController?.animateToItem(
      nextIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void goToPreviousPack() {
    if (packs.isEmpty) return;

    final prevIndex = (_centralPackIndex - 1 + packs.length) % packs.length;
    _carouselAnimationController.forward(from: 0.0);
    _wheelController?.animateToItem(
      prevIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void selectCentralPack() {
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

  void openEnlargedView() {
    if (packs.isNotEmpty && _centralPackIndex < packs.length) {
      setState(() {
        _isPacketEnlarged = true;
        selectedPack = packs[_centralPackIndex];
      });
      // Reset e avvio dell'animazione di apertura
      _overlayCloseController.reset();
      _overlayOpenController.reset();
      _overlayOpenController.forward();
    }
  }

  void closeEnlargedPack() {
    setState(() {
      _isPacketEnlarged = false;
      // Non resettare selectedPack, mantieni il pacchetto attualmente selezionato
      // selectedPack = null;
    });
  }

  void closeEnlargedPackWithTransition() async {
    setState(() {
      _isPacketEnlarged = false;
    });
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void navigateToLuckyWheel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LuckyWheelPage(),
      ),
    );
  }

  void navigateToMissions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MissionsPage(),
      ),
    );
  }

  void startPackOpeningAnimation() {
    setState(() {
      _isPackOpeningAnimation = true;
      // Reset delle variabili dello slider
      _isSliderActive = false;
      _sliderValue = 0.0;
      _hasSliderCompleted = false;
    });
    _packOpenAnimationController.forward(from: 0.0);
  }

  // Gestisce il cambio del valore dello slider
  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
    });

    // Quando lo slider raggiunge 5, completa l'animazione
    if (value >= 5.0 && !_hasSliderCompleted) {
      _completePackOpening();
    }
  }

  // Completa l'animazione di apertura del pacchetto
  void _completePackOpening() {
    setState(() {
      _hasSliderCompleted = true;
      _isSliderActive = false;
    });
    // Chiudi overlay e apri pacchetto immediatamente
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isPacketEnlarged = false;
        _isPackOpeningAnimation = false;
        _isSliderActive = false;
        _hasSliderCompleted = false;
        _sliderValue = 0.0;
      });
      openPack();
    });
  }

  void openPackFromOverlay() async {
    startPackOpeningAnimation();
  }

  void unlockWithCoinsFromOverlay() async {
    startPackOpeningAnimation();
  }

  // Funzione per verificare se una carta è nuova
  bool _isNewCard(CollectionCard card) {
    return !_previouslyOwnedCardIds.contains(card.id);
  }

  // Callback per quando cambia la carta al centro
  void _onCenterCardChanged(int index) {
    setState(() {
      _centerCardIndex = index;
    });

    // Ferma l'animazione pulsante precedente
    _glowPulseController.stop();
    _glowPulseController.reset();

    // Avvia l'animazione delle ombre per la nuova carta centrale
    _glowController.reset();
    _glowController.forward();

    // Avvia l'animazione del badge se la carta è nuova
    if (drawnCards != null &&
        index < drawnCards!.length &&
        _isNewCard(drawnCards![index])) {
      _newBadgeController.reset();
      _newBadgeController.forward();
    }

    // Gestisci il video della carta Zanne della foresta
    if (drawnCards != null && _aangVideoController != null) {
      if (index < drawnCards!.length) {
        final currentCard = drawnCards![index];
        print(
            'DEBUG: Carta al centro - Nome: "${currentCard.name}", ID: "${currentCard.id}"');
        print(
            'DEBUG: Controller video Zanne della foresta inizializzato: ${_aangVideoController!.value.isInitialized}');

        if (currentCard.name.toLowerCase().contains('zanne della foresta')) {
          // Se la carta Zanne della foresta è al centro, avvia il video
          _aangVideoController!.play();
          print(
              '✅ Video Zanne della foresta avviato per carta: ${currentCard.name}');
        } else {
          // Altrimenti ferma il video e torna all'inizio
          _aangVideoController!.pause();
          _aangVideoController!.seekTo(Duration.zero);
          print(
              '⏹️ Video Zanne della foresta fermato per carta: ${currentCard.name}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Contenuto principale
          isLoading
              ? const Center(
                  child: SpinKitChasingDots(
                    color: Color(0xFFDBDDE7),
                    size: 50.0,
                  ),
                )
              : isOpeningPack
                  ? buildOpeningPackAnimation()
                  : drawnCards != null
                      ? buildPackResults()
                      : buildPackDisplay(user),

          // Overlay pacchetto ingrandito
          if (_isPacketEnlarged &&
              selectedPack != null &&
              _overlayCloseAnimation.value < 0.85)
            Material(
              color: Colors.transparent,
              elevation: 100,
              child: buildEnlargedPackOverlay(),
            ),

          // Overlay slider che appare sopra tutto quando attivo
          if (_isSliderActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // Previene la chiusura quando si tocca lo slider
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Container che contiene sia la scia che lo slider sovrapposti
                      Container(
                        width: 320, // Aumentato da 280 a 320
                        margin: const EdgeInsets.only(top: 200),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Slider alla base
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 0,
                                ),
                                activeTrackColor:
                                    null, // Usiamo un custom track
                                inactiveTrackColor: Colors.transparent,
                                trackShape: _GlowingGradientTrackShape(),
                              ),
                              child: Slider(
                                value: _sliderValue,
                                min: 0.0,
                                max: 5.0,
                                onChanged: _onSliderChanged,
                              ),
                            ),
                            // Scia luminosa sovrapposta
                            AnimatedBuilder(
                              animation: _trailAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  left: _trailAnimation.value *
                                      280, // Aumentato da 240 a 280 (320-40)
                                  child: Container(
                                    width: 40,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.8),
                                          Colors.white,
                                          Colors.white.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      // boxShadow rimosso per evitare i puntini bianchi ai lati
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Puntino bianco luminoso allungato che si muove
                            AnimatedBuilder(
                              animation: _trailAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  left: _trailAnimation.value * 280, // 320-40
                                  child: Container(
                                    width: 38, // Più largo per ellisse
                                    height:
                                        22, // Più alto per effetto glow arrotondato
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: const Alignment(0, 0),
                                        radius: 0.7,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.7),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.6, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.95),
                                          blurRadius: 16,
                                          spreadRadius: 6,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 32,
                                          spreadRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPackDisplay(User user) {
    if (packs.isEmpty) {
      return const Text('Nessun pacchetto disponibile.');
    }
    final canOpenFreePack = user.canOpenFreePack();
    final timeLeft = user.timeUntilNextFreePack();
    final coinCost = timeLeft.inHours + 1;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
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
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(36),
                                ),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.01),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(36),
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 24, top: 16),
                                          child: Text(
                                            'Seleziona l\'espansione',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'NeueHaasDisplay',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 32),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedDropdownValue =
                                                        'Monster Allergy';
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Image.asset(
                                                  'assets/images/logos/monster-allergy_logo.png',
                                                  height: 48,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedDropdownValue =
                                                        'Avatar Airbender';
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Image.asset(
                                                  'assets/images/logos/avatar_logo.png',
                                                  height: 36,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedDropdownValue =
                                                        'Sonic';
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Image.asset(
                                                  'assets/images/logos/sonic_logo.png',
                                                  height: 36,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                  fontFamily: 'NeueHaasDisplay',
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
            height:
                380, // Aumentato da 320 a 420 per dare più spazio ai pacchetti
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // border: Border.all(color: Colors.green, width: 1), RIMOSSO
            ),
            child: packs.isEmpty || _wheelController == null
                ? const Center(child: Text('Nessun pacchetto disponibile.'))
                : Stack(
                    children: [
                      // Video di background
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height:
                              320, // Manteniamo l'altezza originale del video
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
                      Positioned.fill(
                        child: Transform.translate(
                          offset: const Offset(0,
                              -28), // Sposto tutto il carousel verso l'alto di 20px
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0, bottom: 0),
                            child: Container(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: ListWheelScrollView.useDelegate(
                                  controller: _wheelController!,
                                  itemExtent: 170,
                                  perspective: 0.001,
                                  diameterRatio: 4.5,
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
                                        quarterTurns: 1,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0,
                                              index == _centralPackIndex
                                                  ? -10
                                                  : 0),
                                          child: buildWheelPackItem(
                                            packs[index],
                                            index == _centralPackIndex,
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: packs.length,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Container unico per slider carte e bottoni
          Transform.translate(
            offset: const Offset(0, -56), // Sposto tutto verso l'alto di 40px
            child: Column(
              children: [
                // Aggiungo lo slider delle carte
                if (selectedPack != null)
                  PackCardsSlider(
                    pack: selectedPack!,
                    allCards: Provider.of<CardService>(context, listen: false)
                        .getAllCards(),
                  ),

                // Sezione per Ruota della Fortuna e Missioni
                const SizedBox(height: 16),

                // Contenitore per le due sezioni
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Ruota della Fortuna
                      Expanded(
                        child: GestureDetector(
                          onTap: navigateToLuckyWheel,
                          child: Container(
                            height: 112,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 0),
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                  color:
                                      const Color(0xFF666666).withOpacity(0.25),
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
                                          const Color.fromARGB(255, 38, 80, 217)
                                              .withOpacity(0.16),
                                          const Color(0xFF0F4CF3)
                                              .withOpacity(0.16),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                // Contenuto sopra
                                Positioned.fill(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/icons/png/lucky-wheel_icon.png',
                                        width: 56,
                                        height: 56,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          fontFamily: 'NeueHaasDisplay',
                                          color: Color(0xFF7B7D8A),
                                        ),
                                      ),
                                      const Text(
                                        'Gira e vinci!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'NeueHaasDisplay',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
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
                          onTap: navigateToMissions,
                          child: Container(
                            height: 112,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 0),
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                  color:
                                      const Color(0xFF666666).withOpacity(0.25),
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
                                          const Color(0xFFFB7F86)
                                              .withOpacity(0.26),
                                          const Color(0xFFF30F39)
                                              .withOpacity(0.26),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/icons/png/missioni_icon.png',
                                          width: 52,
                                          height: 52,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.motion_photos_on,
                                              size: 40,
                                              color: Colors.amber,
                                            );
                                          },
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0, 4),
                                          child: const Text(
                                            'Missioni',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              fontFamily: 'NeueHaasDisplay',
                                              color: Color(0xFF7B7D8A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '8/12',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'NeueHaasDisplay',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOpeningPackAnimation() {
    return Container(
      color: Colors.white,
      child: const SizedBox.expand(),
    );
  }

  Widget buildPackResults() {
    if (drawnCards == null || drawnCards!.isEmpty) {
      return const Center(
        child: Text("Nessuna carta ottenuta"),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          // Video di background
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: Transform.rotate(
                angle: 1.5708, // 90 gradi in radianti (π/2)
                child: AspectRatio(
                  aspectRatio: 1 /
                      _videoController!
                          .value.aspectRatio, // Inverso per la rotazione
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              ),
            ),
          // Bottone di chiusura
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Ferma il video di Zanne della foresta se è in riproduzione
                  if (_aangVideoController != null) {
                    _aangVideoController!.pause();
                    _aangVideoController!.seekTo(Duration.zero);
                  }

                  setState(() {
                    drawnCards = null;
                    currentCardIndex = 0;
                    _currentCardOffset = 0;
                    _centerCardIndex = 0;
                    _previouslyOwnedCardIds.clear();
                  });
                  _newBadgeController.reset();
                  _glowController.reset();
                  _glowPulseController.stop();
                  _glowPulseController.reset();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7B7D8A),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // Contenuto principale
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      children: [
                        // InfiniteDragableSlider
                        AnimatedBuilder(
                          animation: _cardEnterAnimationController,
                          builder: (context, child) {
                            return InfiniteDragableSlider(
                              itemCount: drawnCards!.length,
                              onCenterChanged: _onCenterCardChanged,
                              itemBuilder: (context, index) {
                                final card = drawnCards![index];
                                final animation = _cardEnterAnimations[index];
                                final isNewCard = _isNewCard(card);
                                final isCenterCard = index == _centerCardIndex;

                                return Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1 - animation.value) *
                                          MediaQuery.of(context).size.height),
                                  child: Transform.scale(
                                    scale: 0.8 + (animation.value * 0.2),
                                    child: Opacity(
                                      opacity: animation.value,
                                      child: SizedBox(
                                        width: CardConstants.homeCardWidth,
                                        height: CardConstants.homeCardHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Carta principale
                                            Hero(
                                              tag: 'card_${card.id}',
                                              child: AnimatedBuilder(
                                                animation: Listenable.merge([
                                                  _glowController,
                                                  _glowPulseController
                                                ]),
                                                builder: (context, child) {
                                                  // Calcola il colore pulsante mescolando con il bianco
                                                  final baseColor =
                                                      CollectionCard
                                                          .getRarityColor(
                                                              card.rarity);
                                                  final pulseColor = Color.lerp(
                                                        baseColor,
                                                        Colors.white,
                                                        _glowPulseAnimation
                                                                .value *
                                                            0.3, // 30% di bianco al massimo
                                                      ) ??
                                                      baseColor;

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      boxShadow: [
                                                        // Ombra standard
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          spreadRadius: 0,
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                              0, 5),
                                                        ),
                                                        // Ombre luminose colorate animate con effetto pulsante
                                                        if (isCenterCard &&
                                                            card.rarity !=
                                                                CardRarity
                                                                    .common)
                                                          BoxShadow(
                                                            color: pulseColor
                                                                .withOpacity(0.8 *
                                                                    _glowAnimation
                                                                        .value),
                                                            spreadRadius: 8 *
                                                                _glowAnimation
                                                                    .value,
                                                            blurRadius: 25,
                                                            offset:
                                                                const Offset(
                                                                    0, 0),
                                                          ),
                                                        if (isCenterCard &&
                                                            card.rarity !=
                                                                CardRarity
                                                                    .common)
                                                          BoxShadow(
                                                            color: pulseColor
                                                                .withOpacity(0.4 *
                                                                    _glowAnimation
                                                                        .value),
                                                            spreadRadius: 15 *
                                                                _glowAnimation
                                                                    .value,
                                                            blurRadius: 40,
                                                            offset:
                                                                const Offset(
                                                                    0, 0),
                                                          ),
                                                      ],
                                                    ),
                                                    child: CardWidget(
                                                      card: card,
                                                      isHomePage: true,
                                                      videoController: card.name
                                                              .toLowerCase()
                                                              .contains(
                                                                  'zanne della foresta')
                                                          ? _aangVideoController
                                                          : null,
                                                      shouldPlayVideo: card.name
                                                              .toLowerCase()
                                                              .contains(
                                                                  'zanne della foresta') &&
                                                          isCenterCard,
                                                      onTap: null,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // Badge "Nuova" che segue la carta centrale
                                            if (isNewCard && isCenterCard)
                                              Positioned(
                                                top:
                                                    -50, // Posizionato sopra la carta
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: AnimatedBuilder(
                                                    animation:
                                                        _newBadgeController,
                                                    builder: (context, child) {
                                                      return Transform.scale(
                                                        scale:
                                                            _newBadgeScaleAnimation
                                                                .value,
                                                        child: Opacity(
                                                          opacity:
                                                              _newBadgeOpacityAnimation
                                                                  .value,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25),
                                                            child:
                                                                BackdropFilter(
                                                              filter: ImageFilter
                                                                  .blur(
                                                                      sigmaX:
                                                                          10,
                                                                      sigmaY:
                                                                          10),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.15),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              25),
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.3),
                                                                    width: 1.2,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      blurRadius:
                                                                          12,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              4),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Nuova',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontFamily:
                                                                        'NeueHaasDisplay',
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildEnlargedPackOverlay() {
    final user = Provider.of<User>(context);
    final canOpenFreePack = user.canOpenFreePack();
    final timeLeft = user.timeUntilNextFreePack();
    final coinCost = timeLeft.inHours + 1;

    return WillPopScope(
      onWillPop: () async {
        if (!_isPackOpeningAnimation) {
          closeEnlargedPackWithTransition();
        }
        return false;
      },
      child: Stack(
        children: [
          // Overlay con sfondo blurrato
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_overlayCloseAnimation, _overlayOpenAnimation]),
              builder: (context, child) {
                double opacity = 1.0;
                if (_overlayOpenAnimation.value < 1.0) {
                  opacity = _overlayOpenAnimation.value > 0.15
                      ? (_overlayOpenAnimation.value - 0.15) / 0.85
                      : 0.0;
                } else if (_overlayCloseAnimation.value > 0.0) {
                  opacity = _overlayCloseAnimation.value > 0.85
                      ? 0.0
                      : 1.0 - (_overlayCloseAnimation.value / 0.85);
                }
                final blurValue = 2.4 * opacity;
                return Opacity(
                  opacity: opacity,
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
          // GestureDetector per chiudere toccando fuori, ma non interferisce con i bottoni
          Positioned.fill(
            child: GestureDetector(
              onTap: _isPackOpeningAnimation
                  ? null
                  : closeEnlargedPackWithTransition,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bottone Tassi di comparsa sopra al pacchetto
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _packOpenAnimationController,
                              _overlayCloseAnimation,
                              _overlayOpenAnimation
                            ]),
                            builder: (context, child) {
                              double buttonOpacity = 1.0;
                              // Fade out come il bottone "apri/sblocca"
                              if (_isPackOpeningAnimation) {
                                buttonOpacity = 0.0;
                              } else if (_overlayOpenAnimation.value < 1.0) {
                                buttonOpacity = _overlayOpenAnimation.value >
                                        0.2
                                    ? (_overlayOpenAnimation.value - 0.2) / 0.8
                                    : 0.0;
                              } else if (_overlayCloseAnimation.value > 0.0) {
                                buttonOpacity = _overlayCloseAnimation.value >
                                        0.2
                                    ? 0.0
                                    : 1.0 -
                                        (_overlayCloseAnimation.value / 0.2);
                              }
                              return Opacity(
                                opacity: buttonOpacity,
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              onTap: _isPackOpeningAnimation
                                  ? null
                                  : () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24)),
                                        ),
                                        builder: (context) =>
                                            buildDropRatesSheet(),
                                      );
                                    },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(80),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(80),
                                      border: Border.all(
                                          color: const Color(0xFFDBDDE7),
                                          width: 1.5),
                                    ),
                                    child: const Text(
                                      'Tassi di comparsa',
                                      style: TextStyle(
                                        color: Color(0xFFDBDDE7),
                                        fontSize: 12,
                                        fontFamily: 'NeueHaasDisplay',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Pacchetto ingrandito con animazione apertura
                          Hero(
                            tag: 'enlarged_pack_${selectedPack!.id}',
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _overlayCloseAnimation,
                                _overlayOpenAnimation,
                                _packOpenAnimationController
                              ]),
                              builder: (context, child) {
                                double scale = 1.0;
                                double opacity = 1.0;
                                double translateY = 0.0;
                                // Animazione overlay
                                if (_overlayOpenAnimation.value < 1.0) {
                                  scale =
                                      0.8 + (_overlayOpenAnimation.value * 0.2);
                                  opacity = _overlayOpenAnimation.value > 0.15
                                      ? (_overlayOpenAnimation.value - 0.15) /
                                          0.85
                                      : 0.0;
                                } else if (_overlayCloseAnimation.value > 0.0) {
                                  scale = 1.0 -
                                      (_overlayCloseAnimation.value * 0.2);
                                  opacity = _overlayCloseAnimation.value > 0.85
                                      ? 0.0
                                      : 1.0 -
                                          (_overlayCloseAnimation.value / 0.85);
                                }
                                // Animazione apertura pacchetto
                                if (_isPackOpeningAnimation) {
                                  double packAnimValue =
                                      _packOpenAnimation.value;
                                  scale = 1.0 + 0.522 * packAnimValue;
                                  translateY = 0 + 331.5 * packAnimValue;
                                  opacity = 1.0; // Manteniamo l'opacità al 100%
                                }
                                return Transform.translate(
                                  offset: Offset(0, translateY),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Container(
                                        width: 220,
                                        height: 380,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            if (selectedPack!.name
                                                .toLowerCase()
                                                .contains(
                                                    'fire destruction')) ...[
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 250, 48, 37)
                                                    .withOpacity(
                                                        0.70 * opacity),
                                                spreadRadius: 35,
                                                blurRadius: 94.5,
                                                offset: const Offset(0, 0),
                                              ),
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 24, 7, 7)
                                                    .withOpacity(
                                                        0.85 * opacity),
                                                spreadRadius: 1,
                                                blurRadius: 73.5,
                                                offset: const Offset(0, 0),
                                              ),
                                            ] else if (selectedPack!.name
                                                .toLowerCase()
                                                .contains('earth defence')) ...[
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 62, 255, 194)
                                                    .withOpacity(
                                                        0.70 * opacity),
                                                spreadRadius: 35,
                                                blurRadius: 94.5,
                                                offset: const Offset(0, 0),
                                              ),
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 19, 139, 61)
                                                    .withOpacity(
                                                        0.85 * opacity),
                                                spreadRadius: 1,
                                                blurRadius: 73.5,
                                                offset: const Offset(0, 0),
                                              ),
                                            ] else if (selectedPack!.name
                                                .toLowerCase()
                                                .contains('air power')) ...[
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 28, 90, 198)
                                                    .withOpacity(
                                                        0.70 * opacity),
                                                spreadRadius: 35,
                                                blurRadius: 94.5,
                                                offset: const Offset(0, 0),
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF00E1FF)
                                                    .withOpacity(
                                                        0.85 * opacity),
                                                spreadRadius: 1,
                                                blurRadius: 73.5,
                                                offset: const Offset(0, 0),
                                              ),
                                            ]
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: Image.network(
                                            selectedPack!.image,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Bottoni con fade
                    AnimatedBuilder(
                      animation: _packOpenAnimationController,
                      builder: (context, child) {
                        // I bottoni scompaiono quando inizia l'animazione
                        double buttonOpacity =
                            _isPackOpeningAnimation ? 0.0 : 1.0;

                        return Opacity(
                          opacity: buttonOpacity,
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_overlayCloseAnimation, _overlayOpenAnimation]),
                        builder: (context, child) {
                          double buttonOpacity = 1.0;
                          if (_overlayOpenAnimation.value < 1.0) {
                            buttonOpacity = _overlayOpenAnimation.value > 0.2
                                ? (_overlayOpenAnimation.value - 0.2) / 0.8
                                : 0.0;
                          } else if (_overlayCloseAnimation.value > 0.0) {
                            buttonOpacity = _overlayCloseAnimation.value > 0.2
                                ? 0.0
                                : 1.0 - (_overlayCloseAnimation.value / 0.2);
                          }
                          return Opacity(
                            opacity: buttonOpacity,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: _isPackOpeningAnimation
                              ? null
                              : () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (context) => buildDropRatesSheet(),
                                  );
                                },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              canOpenFreePack
                                  ? GestureDetector(
                                      onTap: _isPackOpeningAnimation
                                          ? null
                                          : () {
                                              startPackOpeningAnimation();
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
                                              'Apri pacchetto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: 'NeueHaasDisplay',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        GestureDetector(
                                          onTap: user.tunueCoins >=
                                                      selectedPack!.baseCost &&
                                                  !_isPackOpeningAnimation
                                              ? () {
                                                  startPackOpeningAnimation();
                                                }
                                              : null,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            decoration: ShapeDecoration(
                                              gradient: user.tunueCoins >=
                                                      selectedPack!.baseCost
                                                  ? const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF13C931),
                                                        Color(0xFF3CCC7E),
                                                      ],
                                                    )
                                                  : const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF0A6B1C),
                                                        Color(0xFF1F7A3A),
                                                      ],
                                                    ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(80),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Sblocca pacchetto',
                                                  style: TextStyle(
                                                    color: user.tunueCoins >=
                                                            selectedPack!
                                                                .baseCost
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFFB0B0B0),
                                                    fontSize: 18,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: -16,
                                          right: -8,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 10, sigmaY: 10),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFACB0B3)
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/icons/tunue_logo.png',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$coinCost',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            'NeueHaasDisplay',
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

          // Testo che appare dopo l'animazione del pacchetto
          if (_isPacketEnlarged)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _packOpenAnimationController,
                builder: (context, child) {
                  double textOpacity = _packOpenAnimationController.status ==
                          AnimationStatus.completed
                      ? 1.0
                      : 0.0;
                  return Center(
                    child: Transform.translate(
                      offset: const Offset(
                          0, -40), // Posizionato sopra il pacchetto
                      child: AnimatedOpacity(
                        opacity: textOpacity,
                        duration: const Duration(milliseconds: 900),
                        child: Text(
                          'Taglia il pacchetto per scoprire!',
                          style: TextStyle(
                            color: const Color.fromARGB(171, 255, 255, 255),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NeueHaasDisplay',
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildWheelPackItem(Pack pack, bool isSelected) {
    // Scala in base alla selezione: 1.0 per il centrale, 0.85 per i laterali
    final double scale = isSelected ? 1.0 : 0.85;
    final int index = packs.indexOf(pack);
    final double rotation =
        isSelected ? 0.0 : (index < _centralPackIndex ? -0.1 : 0.1);

    Widget content = AnimatedBuilder(
      animation: _carouselAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Container per l'ombra
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_overlayCloseAnimation, _overlayOpenAnimation]),
                    builder: (context, child) {
                      if (_isPacketEnlarged && selectedPack?.id == pack.id) {
                        double carouselOpacity = 1.0;

                        if (_overlayOpenAnimation.value > 0.5) {
                          carouselOpacity =
                              1.0 - ((_overlayOpenAnimation.value - 0.5) * 2.0);
                        } else if (_overlayCloseAnimation.value > 0.5) {
                          carouselOpacity =
                              (_overlayCloseAnimation.value - 0.5) * 2.0;
                        } else {
                          carouselOpacity = 0.0;
                        }

                        return Opacity(
                          opacity: carouselOpacity,
                          child: child!,
                        );
                      }
                      return child!;
                    },
                    child: Container(
                      width: 220,
                      height: 300,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Immagine del pacchetto
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_overlayCloseAnimation, _overlayOpenAnimation]),
                    builder: (context, child) {
                      if (_isPacketEnlarged && selectedPack?.id == pack.id) {
                        double carouselOpacity = 1.0;

                        if (_overlayOpenAnimation.value > 0.5) {
                          carouselOpacity =
                              1.0 - ((_overlayOpenAnimation.value - 0.5) * 2.0);
                        } else if (_overlayCloseAnimation.value > 0.5) {
                          carouselOpacity =
                              (_overlayCloseAnimation.value - 0.5) * 2.0;
                        } else {
                          carouselOpacity = 0.0;
                        }

                        return Opacity(
                          opacity: carouselOpacity,
                          child: child!,
                        );
                      }
                      return child!;
                    },
                    child: Container(
                      width: 220,
                      height: 300,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          pack.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // GestureDetector trasparente per catturare i tap
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        openEnlargedView();
                      } else {
                        final index = packs.indexOf(pack);
                        _carouselAnimationController.forward(from: 0.0);
                        _wheelController?.animateToItem(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Se è il pacchetto centrale, applica la fluttuazione
    if (isSelected) {
      content = AnimatedBuilder(
        animation: Listenable.merge([_floatAnimation, _floatRotationAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.rotate(
              angle: _floatRotationAnimation.value,
              child: child,
            ),
          );
        },
        child: content,
      );
    }
    return content;
  }

  Widget buildDropRatesSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(36),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.01),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(36),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24, top: 16),
                  child: Text(
                    'Tassi di comparsa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NeueHaasDisplay',
                    ),
                  ),
                ),
              ),
              buildDropRateRow('Comune', '70%'),
              buildDropRateRow('Rara', '20%'),
              buildDropRateRow('Super Rara', '8%'),
              buildDropRateRow('Ultra Rara', '1.5%'),
              buildDropRateRow('Gold', '0.5%'),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'I tassi sono indicativi e possono variare in base agli eventi o ai pacchetti speciali.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'NeueHaasDisplay',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropRateRow(String rarity, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rarity,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NeueHaasDisplay',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            rate,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NeueHaasDisplay',
              fontWeight: FontWeight.w600,
              color: Colors.white,
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

// Custom track shape per la barra di progresso con gradiente e glow
class _GlowingGradientTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 0, // non required
  }) {
    if (sliderTheme.trackHeight == 0) return;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF13C931),
          Colors.white,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx - trackRect.left,
        trackRect.height,
      ));
    // Glow
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(
        trackRect.left,
        trackRect.top - 8,
        thumbCenter.dx - trackRect.left,
        trackRect.height + 16,
      ));
    // Disegna la parte attiva (progresso)
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left,
          trackRect.top,
          thumbCenter.dx,
          trackRect.bottom,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    // Glow sopra la parte attiva
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left,
          trackRect.top - 4,
          thumbCenter.dx,
          trackRect.bottom + 4,
        ),
        const Radius.circular(8),
      ),
      glowPaint,
    );
  }
}
