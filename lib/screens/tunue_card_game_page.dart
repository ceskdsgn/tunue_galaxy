import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:provider/provider.dart';

import '../data/monster_allergy_cards.dart';
import '../models/card_game.dart';
import '../models/user.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/card_game_service.dart';

class TunueCardGamePage extends StatefulWidget {
  const TunueCardGamePage({super.key});

  @override
  _TunueCardGamePageState createState() => _TunueCardGamePageState();
}

class _TunueCardGamePageState extends State<TunueCardGamePage>
    with TickerProviderStateMixin {
  final CardGameService _gameService = CardGameService();
  final AIService _aiService = AIService();
  GameCard? _selectedCard;
  PersonaggioCard? _selectedAttacker;
  bool _isSelectingTarget = false;
  bool _bomboCommentsEnabled = true;
  String? _currentBomboComment;

  // Variabili per il loading
  bool _isLoading = true;
  bool _areGameAssetsLoaded = false;
  bool _areCardImagesLoaded = false;
  bool _isGameInitialized = false;

  // Controller per l'animazione del mesh gradient
  late final AnimatedMeshGradientController _meshController =
      AnimatedMeshGradientController();

  // Animazione energia giocatore (mantengo nomi esistenti)
  late AnimationController _energyAnimationController;
  late AnimationController _energyRotationController;
  late AnimationController _energyNumberController;
  late Animation<double> _energyFadeAnimation;
  late Animation<Offset> _energySlideAnimation;
  late Animation<double> _energyScaleAnimation;
  late Animation<double> _energyRotationAnimation;
  late Animation<double> _energyNumberScaleAnimation;
  final bool _showEnergyAnimation = false;
  double _currentEnergyRotation = 0.0;

  // Animazione energia avversario (nuove variabili)
  late AnimationController _aiEnergyRotationController;
  late AnimationController _aiEnergyNumberController;
  late Animation<double> _aiEnergyRotationAnimation;
  late Animation<double> _aiEnergyNumberScaleAnimation;
  double _currentAiEnergyRotation = 0.0;

  // Animazione carta pescata
  late AnimationController _cardDrawAnimationController;
  late Animation<Offset> _cardDrawSlideAnimation;
  late Animation<double> _cardDrawFadeAnimation;
  late Animation<double> _cardDrawScaleAnimation;
  GameCard? _drawnCard;
  bool _showDrawnCard = false;

  @override
  void initState() {
    super.initState();

    // Avvia l'animazione del mesh gradient
    _meshController.start();

    // Inizializza l'animazione dell'energia
    _energyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Controller per la rotazione del giocatore
    _energyRotationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Rallentata ulteriormente
      vsync: this,
    );

    // Controller per l'animazione del numero del giocatore
    _energyNumberController = AnimationController(
      duration: const Duration(milliseconds: 450), // Rallentata
      vsync: this,
    );

    // Controller per la rotazione dell'avversario
    _aiEnergyRotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller per l'animazione del numero dell'avversario
    _aiEnergyNumberController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    // Controller per l'animazione della carta pescata
    _cardDrawAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Ridotto da 1200 a 800ms
      vsync: this,
    );

    _energyFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _energyAnimationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Inizia il fade out dopo un breve delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _energyAnimationController.reverse();
            }
          });
        }
      });

    _energySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -3.0),
    ).animate(CurvedAnimation(
      parent: _energyAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _energyScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _energyAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _energyRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // 360 gradi in radianti
    ).animate(CurvedAnimation(
      parent: _energyRotationController,
      curve: Curves.fastOutSlowIn, // Prima veloce, poi lenta
    ))
      ..addListener(() {
        // Non serve fare nulla qui, usiamo solo il valore nell'AnimatedBuilder
      });

    _energyNumberScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4, // Scala del 40% più grande
    ).animate(CurvedAnimation(
      parent: _energyNumberController,
      curve: Curves.easeOutBack, // Animazione fluida con leggero overshoot
    ));

    _aiEnergyRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // 360 gradi in radianti
    ).animate(CurvedAnimation(
      parent: _aiEnergyRotationController,
      curve: Curves.fastOutSlowIn, // Prima veloce, poi lenta
    ));

    _aiEnergyNumberScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4, // Scala del 40% più grande
    ).animate(CurvedAnimation(
      parent: _aiEnergyNumberController,
      curve: Curves.easeOutBack, // Animazione fluida con leggero overshoot
    ));

    // Animazioni per la carta pescata
    _cardDrawSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0), // Inizia dal basso
      end: const Offset(0, -0.3), // Sale leggermente sopra il centro
    ).animate(CurvedAnimation(
      parent: _cardDrawAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _cardDrawFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardDrawAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _cardDrawScaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardDrawAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _loadGameResources();
  }

  @override
  void dispose() {
    _meshController.dispose();
    _energyAnimationController.dispose();
    _energyRotationController.dispose();
    _energyNumberController.dispose();
    _aiEnergyRotationController.dispose();
    _aiEnergyNumberController.dispose();
    _cardDrawAnimationController.dispose();
    super.dispose();
  }

  // Metodi per il loading delle risorse
  Future<void> _loadGameResources() async {
    await _preloadGameAssets();
    await _preloadCardImages();
    _checkAllResourcesLoaded();
  }

  Future<void> _preloadGameAssets() async {
    try {
      final assetPaths = [
        'assets/images/game/bombo_ai.png',
        'assets/images/game/game_table.png',
        'assets/images/game/deck.png',
        'assets/images/game/deck_avversario.png',
        'assets/images/game/back_carte_avversarie.png',
        'assets/images/game/energy_base_green.png',
        'assets/images/game/energy_base_gray.png',
        'assets/images/icons/png/cards_icon.png',
      ];

      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          await Future.delayed(const Duration(milliseconds: 50));
          print('✅ Precaricato asset di gioco: $assetPath');
        } catch (e) {
          print('❌ Errore nel caricamento asset $assetPath: $e');
        }
      }));

      setState(() {
        _areGameAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload game assets: $e');
      setState(() {
        _areGameAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  Future<void> _preloadCardImages() async {
    try {
      // Ottieni tutte le carte dal deck
      final allCards = MonsterAllergyCards.createDefaultDeck();

      await Future.wait(allCards.map((card) async {
        try {
          final imagePath = card.imageUrl;
          final image = AssetImage(imagePath);
          await precacheImage(image, context);
          await Future.delayed(const Duration(milliseconds: 30));
          print('✅ Precaricata carta: ${card.name}');
        } catch (e) {
          print('❌ Errore nel caricamento carta ${card.name}: $e');
        }
      }));

      setState(() {
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload card images: $e');
      setState(() {
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  void _checkAllResourcesLoaded() {
    if (_areGameAssetsLoaded && _areCardImagesLoaded && !_isGameInitialized) {
      setState(() {
        _isGameInitialized = true;
      });

      // Inizializza il gioco con un breve delay per far vedere il completamento del loading
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _initializeGame();
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _showGameMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(36),
        ),
      ),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(36),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 16),

                  // Toggle commenti Bombo
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bomboCommentsEnabled = !_bomboCommentsEnabled;
                      });
                      Navigator.of(context).pop();
                      _showGlassmorphSnackBar(
                        _bomboCommentsEnabled
                            ? 'Commenti di Bombo riattivati!'
                            : 'Commenti di Bombo disattivati!',
                        Colors.orange.shade600,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: SizedBox(
                          height: 60,
                          child: Stack(
                            children: [
                              // Immagine di Bombo molto grande e clippata (fuori dal padding)
                              Positioned(
                                left: -60,
                                top: -20,
                                child: Image.asset(
                                  'assets/images/game/bombo_ai.png',
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container();
                                  },
                                ),
                              ),
                              // Container con padding solo per il testo e lo sfondo
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.01),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _bomboCommentsEnabled
                                        ? 'Disattiva Bombo'
                                        : 'Attiva Bombo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NeueHaasDisplay',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black54,
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
                  ),
                  const SizedBox(height: 16),

                  // Bottone Nuova Partita
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _initializeGame();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Nuova Partita',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NeueHaasDisplay',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottone Esci
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Esci',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NeueHaasDisplay',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGlassmorphSnackBar(String message, Color accentColor,
      {bool hasAction = false, int durationSeconds = 4}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NeueHaasDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: Duration(seconds: durationSeconds),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }

  Future<void> _handleActionComment(String message,
      {required bool isAI}) async {
    final gameState = _gameService.gameState;
    if (gameState == null || !_bomboCommentsEnabled) return;

    String action = 'general';
    String? cardName;
    String? attackerName;
    String? targetName;

    // Estrai informazioni dal messaggio
    if (message.contains('gioca') || message.contains('played')) {
      action = 'play';
      final cardMatch = RegExp(r'"([^"]+)"').firstMatch(message);
      cardName = cardMatch?.group(1);
    } else if (message.contains('attacca') || message.contains('attack')) {
      action = 'attack';
      final vsMatch = RegExp(r'(\w+)\s+vs\s+(\w+)').firstMatch(message);
      if (vsMatch != null) {
        attackerName = vsMatch.group(1);
        targetName = vsMatch.group(2);
      } else {
        final directMatch = RegExp(r'con\s+(\w+)').firstMatch(message);
        if (directMatch != null) {
          attackerName = directMatch.group(1);
        }
      }
    }

    // Genera commento dinamico usando l'AI
    String comment;
    if (isAI) {
      // Bombo si vanta delle sue azioni (sicuro di sé e arrogante)
      comment = await _aiService.generateBomboComment(
        gameState: gameState,
        action: 'bombo_action', // Azione specifica per quando Bombo gioca
        cardName: cardName,
        attackerName: attackerName,
        targetName: targetName,
        isPlayerAction: false, // Bombo sta giocando
      );
    } else {
      // Bombo è sarcastico verso le azioni del giocatore
      comment = await _aiService.generateBomboComment(
        gameState: gameState,
        action: 'player_action', // Azione del giocatore
        cardName: cardName,
        attackerName: attackerName,
        targetName: targetName,
        isPlayerAction: true, // Il giocatore sta giocando
      );
    }

    // Mostra il commento di Bombo nel fumetto
    if (mounted) {
      setState(() {
        _currentBomboComment = comment;
      });

      // Rimuovi il commento dopo 5 secondi per dare più tempo di lettura
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _currentBomboComment = null;
          });
        }
      });
    }
  }

  void _initializeGame() {
    // Ottieni l'utente loggato
    final user = Provider.of<User>(context, listen: false);

    // Crea il giocatore umano con il nome dell'utente loggato
    final player1 = Player(
      name: user.username.isNotEmpty ? user.username : 'Giocatore',
      mazzo: List.from(MonsterAllergyCards.createDefaultDeck()),
    );

    // Configura il callback per gli effetti delle carte
    _gameService.onEffectActivated = (String message) {
      _showGlassmorphSnackBar(message, Colors.purple.shade600);
    };

    // Configura il callback per l'animazione dell'energia
    _gameService.onEnergyAdded = () {
      // Determina se l'energia è stata aggiunta al giocatore umano o all'AI
      final gameState = _gameService.gameState;
      if (gameState != null) {
        final playerName =
            user.username.isNotEmpty ? user.username : 'Giocatore';
        final isPlayerTurn = gameState.giocatoreAttivo.name == playerName;
        _playEnergyAnimation(isPlayer: isPlayerTurn);
      }
    };

    // Configura il callback per le azioni dell'AI
    _gameService.onAIAction = (String message) {
      _handleActionComment(message, isAI: true);
    };

    // Configura il callback per le azioni del giocatore
    _gameService.onPlayerAction = (String message) {
      _handleActionComment(message, isAI: false);
    };

    // Configura il callback per la carta pescata
    _gameService.onCardDrawn = (GameCard card, bool isPlayer) {
      if (isPlayer) {
        _playCardDrawAnimation(card);
      }
    };

    // Inizia partita vs AI
    _gameService.iniziaPartitaVsAI(player1);

    // Commento di benvenuto dinamico di Bombo
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted && _bomboCommentsEnabled) {
        final gameState = _gameService.gameState;
        if (gameState != null) {
          try {
            final welcomeComment = await _aiService.generateBomboComment(
              gameState: gameState,
              action: 'start',
            );
            if (mounted) {
              setState(() {
                _currentBomboComment = welcomeComment;
              });
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  setState(() {
                    _currentBomboComment = null;
                  });
                }
              });
            }
          } catch (e) {
            print('Errore generazione commento benvenuto: $e');
          }
        }
      }
    });

    setState(() {});
  }

  void _playCardDrawAnimation(GameCard card) {
    if (!mounted) return;

    setState(() {
      _drawnCard = card;
      _showDrawnCard = true;
    });

    // Avvia l'animazione
    _cardDrawAnimationController.forward().then((_) {
      // Ridotto il tempo di visualizzazione
      Future.delayed(const Duration(milliseconds: 800), () {
        // Ridotto da 1500 a 800ms
        if (mounted) {
          _cardDrawAnimationController.reverse().then((_) {
            setState(() {
              _showDrawnCard = false;
              _drawnCard = null;
            });
          });
        }
      });
    });
  }

  void _playEnergyAnimation({bool isPlayer = true}) {
    if (!mounted) return;

    if (isPlayer) {
      // Animazione per il giocatore
      // Controllo per evitare valori NaN
      if (!_currentEnergyRotation.isFinite) {
        _currentEnergyRotation = 0.0;
      }

      _currentEnergyRotation += 2 * 3.14159;

      final beginRotation = _currentEnergyRotation - 2 * 3.14159;
      final endRotation = _currentEnergyRotation;

      // Controllo aggiuntivo per valori finiti
      if (!beginRotation.isFinite || !endRotation.isFinite) {
        print('Warning: Invalid rotation values detected, resetting');
        _currentEnergyRotation = 0.0;
        return;
      }

      _energyRotationAnimation = Tween<double>(
        begin: beginRotation,
        end: endRotation,
      ).animate(CurvedAnimation(
        parent: _energyRotationController,
        curve: Curves.fastOutSlowIn,
      ));

      _energyRotationController.reset();
      _energyRotationController.forward();

      _energyNumberController.reset();
      _energyNumberController.forward().then((_) {
        _energyNumberController.reverse();
      });
    } else {
      // Animazione per l'avversario
      // Controllo per evitare valori NaN
      if (!_currentAiEnergyRotation.isFinite) {
        _currentAiEnergyRotation = 0.0;
      }

      _currentAiEnergyRotation += 2 * 3.14159;

      final beginRotation = _currentAiEnergyRotation - 2 * 3.14159;
      final endRotation = _currentAiEnergyRotation;

      // Controllo aggiuntivo per valori finiti
      if (!beginRotation.isFinite || !endRotation.isFinite) {
        print('Warning: Invalid AI rotation values detected, resetting');
        _currentAiEnergyRotation = 0.0;
        return;
      }

      _aiEnergyRotationAnimation = Tween<double>(
        begin: beginRotation,
        end: endRotation,
      ).animate(CurvedAnimation(
        parent: _aiEnergyRotationController,
        curve: Curves.fastOutSlowIn,
      ));

      _aiEnergyRotationController.reset();
      _aiEnergyRotationController.forward();

      _aiEnergyNumberController.reset();
      _aiEnergyNumberController.forward().then((_) {
        _aiEnergyNumberController.reverse();
      });
    }

    setState(() {});
  }

  void _onCardTapped(GameCard card) {
    final currentPhase = _gameService.currentPhase;

    print('DEBUG: Card tapped: ${card.name}, Phase: $currentPhase');

    if (currentPhase == GamePhase.principale) {
      // Nella fase principale, gestisci sia il gioco delle carte che gli attacchi
      if (card is PersonaggioCard) {
        // Controlla se la carta è un personaggio in campo che può attaccare
        final gameState = _gameService.gameState!;
        final myCards = gameState.giocatoreAttivo.zonePersonaggi;

        print('DEBUG: È un PersonaggioCard, cerco in campo...');
        print(
            'DEBUG: Zone personaggi: ${myCards.map((c) => c?.name ?? 'null').toList()}');

        // Cerca se questo personaggio è in campo
        int index = -1;
        for (int i = 0; i < myCards.length; i++) {
          if (myCards[i] != null && myCards[i]!.id == card.id) {
            index = i;
            break;
          }
        }

        print('DEBUG: Indice trovato: $index');

        if (index != -1) {
          final canAttack = _gameService.puoiAttaccare(index);
          print('DEBUG: Può attaccare: $canAttack');
          print('DEBUG: È primo turno: ${gameState.isPrimoTurno}');
          print(
              'DEBUG: Ha già attaccato: ${_gameService.hasAttackedThisTurn(card.id)}');

          if (canAttack) {
            // È un personaggio in campo che può attaccare
            print('DEBUG: Avviando attacco...');
            _handleAttackPhaseCardTap(card);
          } else {
            // È una carta in campo ma non può attaccare, gestisci normalmente
            print('DEBUG: Personaggio in campo ma non può attaccare');

            // Mostra un messaggio specifico se è il primo turno
            if (gameState.isPrimoTurno) {
              _showGlassmorphSnackBar(
                  'Non puoi attaccare durante il primo turno!',
                  Colors.orange.shade600);
            } else if (_gameService.hasAttackedThisTurn(card.id)) {
              _showGlassmorphSnackBar(
                  '${card.name} ha già attaccato questo turno!',
                  Colors.orange.shade600);
            }

            _handleNormalCardTap(card);
          }
        } else {
          // È una carta in mano o non può attaccare, gestisci normalmente
          print(
              'DEBUG: Personaggio non trovato in campo, gestisco normalmente');
          _handleNormalCardTap(card);
        }
      } else {
        // Non è un personaggio, gestisci normalmente
        print('DEBUG: Non è un personaggio, gestisco normalmente');
        _handleNormalCardTap(card);
      }
    } else if (currentPhase == GamePhase.attacco) {
      _handleAttackPhaseCardTap(card);
    } else {
      _handleNormalCardTap(card);
    }
  }

  void _handleAttackPhaseCardTap(GameCard card) {
    final gameState = _gameService.gameState!;
    final myCards = gameState.giocatoreAttivo.zonePersonaggi;

    print(
        'DEBUG: Clicked card: ${card.name}, Phase: ${_gameService.currentPhase}');
    print('DEBUG: isSelectingTarget: $_isSelectingTarget');
    print('DEBUG: Card is PersonaggioCard: ${card is PersonaggioCard}');

    if (!_isSelectingTarget) {
      // Prima selezione: scegli attaccante dalle tue carte
      if (card is PersonaggioCard) {
        // Cerca la carta nelle zone personaggi in campo
        int index = -1;
        for (int i = 0; i < myCards.length; i++) {
          if (myCards[i] != null && myCards[i]!.id == card.id) {
            index = i;
            break;
          }
        }

        if (index != -1 && _gameService.puoiAttaccare(index)) {
          print('DEBUG: Selecting attacker: ${card.name} at index $index');
          setState(() {
            _selectedAttacker = card;
            _isSelectingTarget = true;
            _selectedCard = null;
          });

          // Mostra dialog per scegliere il bersaglio
          _showTargetSelectionDialog();
        } else {
          String reason = 'Motivo sconosciuto';
          if (index == -1) {
            reason = 'Carta non trovata nel campo';
          } else if (gameState.isPrimoTurno) {
            reason = 'Non puoi attaccare nel primo turno';
          } else if (_gameService.hasAttackedThisTurn(card.id)) {
            reason = 'Questo personaggio ha già attaccato questo turno';
          } else if (_gameService.currentPhase != GamePhase.principale &&
              _gameService.currentPhase != GamePhase.attacco) {
            reason = 'Non sei nella fase principale/attacco';
          }

          _showGlassmorphSnackBar(
              'Non puoi attaccare con ${card.name}: $reason',
              Colors.orange.shade600);
        }
      }
    }
  }

  void _handleNormalCardTap(GameCard card) {
    setState(() {
      _selectedCard = _selectedCard == card ? null : card;
      // Reset attack selection se cambiamo fase
      _selectedAttacker = null;
      _isSelectingTarget = false;
    });
  }

  void _executeAttack(int attackerIndex, int defenderIndex) {
    _gameService.attaccaConPersonaggio(attackerIndex, defenderIndex);
    setState(() {
      _selectedAttacker = null;
      _isSelectingTarget = false;
      _selectedCard = null;
    });

    // Mostra risultato dell'attacco
    _showAttackResult();
  }

  void _executeDirectAttack() {
    if (_selectedAttacker == null) return;

    // Trova l'indice dell'attaccante
    final myCards = _gameService.gameState!.giocatoreAttivo.zonePersonaggi;
    int attackerIndex = -1;
    for (int i = 0; i < myCards.length; i++) {
      if (myCards[i] != null && myCards[i]!.id == _selectedAttacker!.id) {
        attackerIndex = i;
        break;
      }
    }

    if (attackerIndex != -1) {
      _gameService.attaccaConPersonaggio(attackerIndex, null);
      setState(() {
        _selectedAttacker = null;
        _isSelectingTarget = false;
      });
      _showAttackResult();
    }
  }

  void _showAttackResult() {
    final gameState = _gameService.gameState!;
    String message = 'Attacco eseguito!';

    // Controlla se qualche giocatore ha perso vite
    if (gameState.avversario.vite < 3) {
      message =
          'Attacco diretto riuscito! Avversario ha ${gameState.avversario.vite} vite rimaste.';
    }

    _showGlassmorphSnackBar(message, Colors.red.shade600);
  }

  bool _canAttackCard(GameCard card) {
    if (_gameService.currentPhase == GamePhase.principale &&
        card is PersonaggioCard) {
      final gameState = _gameService.gameState!;
      final myCards = gameState.giocatoreAttivo.zonePersonaggi;
      final enemyCards = gameState.avversario.zonePersonaggi;

      if (!_isSelectingTarget) {
        // Può selezionare le proprie carte come attaccanti se sono in campo
        for (int i = 0; i < myCards.length; i++) {
          if (myCards[i] != null && myCards[i]!.id == card.id) {
            return _gameService.puoiAttaccare(i);
          }
        }
        // Se la carta non è in campo, può essere giocata se è in mano
        return _gameService.puoiGiocareCarta(card);
      } else {
        // Può selezionare carte nemiche come bersagli
        for (int i = 0; i < enemyCards.length; i++) {
          if (enemyCards[i] != null && enemyCards[i]!.id == card.id) {
            return true;
          }
        }
      }
    } else if (_gameService.currentPhase == GamePhase.attacco &&
        card is PersonaggioCard) {
      final gameState = _gameService.gameState!;
      final myCards = gameState.giocatoreAttivo.zonePersonaggi;
      final enemyCards = gameState.avversario.zonePersonaggi;

      if (!_isSelectingTarget) {
        // Può selezionare le proprie carte come attaccanti
        for (int i = 0; i < myCards.length; i++) {
          if (myCards[i] != null && myCards[i]!.id == card.id) {
            return _gameService.puoiAttaccare(i);
          }
        }
      } else {
        // Può selezionare carte nemiche come bersagli
        for (int i = 0; i < enemyCards.length; i++) {
          if (enemyCards[i] != null && enemyCards[i]!.id == card.id) {
            return true;
          }
        }
      }
    }

    // Per tutte le altre fasi, usa la logica normale
    if (_gameService.currentPhase == GamePhase.principale) {
      return _gameService.puoiGiocareCarta(card);
    }

    return false;
  }

  bool _isCardSelected(GameCard card) {
    if (_gameService.currentPhase == GamePhase.attacco ||
        _gameService.currentPhase == GamePhase.principale) {
      return _selectedAttacker != null && _selectedAttacker!.id == card.id;
    }
    return _selectedCard != null && _selectedCard!.id == card.id;
  }

  void _nextPhase() {
    final currentPhase = _gameService.currentPhase;

    // Reset attack state quando si cambia fase
    setState(() {
      _selectedAttacker = null;
      _isSelectingTarget = false;
    });

    switch (currentPhase) {
      case GamePhase.energia:
        // Energia e pesca sono automatizzate, vai direttamente alla fase principale
        _gameService.fasePrincipale();
        break;
      case GamePhase.pesca:
        // La pesca è automatizzata, vai direttamente alla fase principale
        _gameService.fasePrincipale();
        break;
      case GamePhase.principale:
        // Ora la fase principale include anche l'attacco, quindi vai direttamente alla fine turno
        _gameService.fineTurno();
        break;
      case GamePhase.attacco:
        // Non dovrebbe più essere raggiungibile, ma per sicurezza
        _gameService.fineTurno();
        break;
      case GamePhase.fine:
        break;
    }

    setState(() {});
  }

  String _getPhaseText() {
    final gameState = _gameService.gameState;

    switch (_gameService.currentPhase) {
      case GamePhase.energia:
        return 'Fase Energia';
      case GamePhase.pesca:
        return 'Fase Pesca';
      case GamePhase.principale:
        return 'Fase Principale/Attacco';
      case GamePhase.attacco:
        // Ora è unita alla fase principale
        return 'Fase Principale/Attacco';
      case GamePhase.fine:
        return 'Fine Turno';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final gameState = _gameService.gameState;
    if (gameState == null || _isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitChasingDots(
            color: Color(0xFFDBDDE7),
            size: 50.0,
          ),
        ),
      );
    }

    // Se il gioco è finito, mostra il dialog nel prossimo frame
    if (_gameService.isGameOver && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }

    return Scaffold(
      body: Container(
        // Background: immagine tavolo + pattern linee sopra
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Gradiente mesh animato
              Positioned.fill(
                child: Stack(
                  children: [
                    // Primo livello di mesh gradient
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
                        child: AnimatedMeshGradient(
                          colors: [
                            const Color.fromARGB(255, 190, 229, 196)
                                .withOpacity(0.9), // Verde chiaro intenso
                            const Color(0xFF4BFF9E)
                                .withOpacity(0.95), // Verde acqua molto intenso
                            Colors.white.withOpacity(0.8), // Bianco brillante
                            const Color.fromARGB(255, 180, 216, 186)
                                .withOpacity(0.9), // Verde chiaro intenso
                          ],
                          options: AnimatedMeshGradientOptions(
                            frequency: 2.0, // Onde molto ampie
                            amplitude: 0.5, // Movimento molto ampio
                            speed: 2.0, // Movimento più veloce
                            grain: 0.05, // Texture molto sottile
                          ),
                          controller: _meshController,
                        ),
                      ),
                    ),
                    // Secondo livello di blur per ammorbidire ulteriormente
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Immagine di background (tavolo)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/game/game_table.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Main circular game field
              _buildLinearGameField(gameState, screenSize),

              // Bombo AI che sbuca da sinistra
              _buildBomboAI(screenSize),

              // Side elements (mazzo, cimitero)
              _buildSideElements(gameState, screenSize),

              // Bottom hand
              _buildBottomHand(gameState, screenSize),

              // Game controls overlay
              _buildGameControlsOverlay(gameState, screenSize),

              // AI hand (mano dell'AI in alto)
              _buildAIHand(gameState, screenSize),

              // Player info (nome e vite in basso a sinistra) - IN PRIMO PIANO
              _buildPlayerInfo(gameState, screenSize),

              // Animazione carta pescata (sopra tutto)
              if (_showDrawnCard && _drawnCard != null)
                _buildCardDrawAnimation(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinearGameField(GameState gameState, Size screenSize) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
            bottom: 180.0), // Regola qui per quanto in alto vuoi il campo
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-0.55), // inclina il campo verso l'utente
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Zone mazzo e cimitero avversario (in alto)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mazzo e cimitero avversario (verticale)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 95,
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/game/deck_avversario.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  // Zone personaggi avversario
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final aiPlayer = gameState.giocatore2;
                      final personaggio = index < aiPlayer.zonePersonaggi.length
                          ? aiPlayer.zonePersonaggi[index]
                          : null;
                      return DragTarget<GameCard>(
                        onWillAcceptWithDetails: (details) {
                          final card = details.data;
                          return card is PersonaggioCard &&
                              personaggio == null &&
                              _gameService.currentPhase ==
                                  GamePhase.principale &&
                              _gameService.puoiGiocareCarta(card);
                        },
                        onAcceptWithDetails: (details) {
                          final card = details.data;
                          if (card is PersonaggioCard) {
                            // Se vuoi permettere di "rubare" slot all'avversario, qui puoi gestire la logica
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHighlighted = candidateData.isNotEmpty;
                          return GestureDetector(
                            onTap: () {
                              if (personaggio != null) {
                                // Se non è in fase di selezione del target, mostra i dettagli della carta
                                if (!_isSelectingTarget) {
                                  // Se è in fase principale/attacco e può attaccare, gestisci l'attacco
                                  if ((_gameService.currentPhase ==
                                              GamePhase.attacco ||
                                          _gameService.currentPhase ==
                                              GamePhase.principale) &&
                                      _gameService.puoiAttaccare(index) &&
                                      !_gameService.hasAttackedThisTurn(
                                          personaggio.id)) {
                                    _onCardTapped(personaggio);
                                  } else {
                                    // Altrimenti mostra i dettagli della carta
                                    _showCardDetails(personaggio);
                                  }
                                } else {
                                  // Se stiamo selezionando un target, continua con la logica di attacco
                                  _onCardTapped(personaggio);
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 85,
                                  height: 110,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: personaggio != null
                                        ? Colors.green.withOpacity(0.3)
                                        : const Color(0xFFB9D3C1),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: personaggio != null &&
                                            (_gameService.currentPhase ==
                                                    GamePhase.attacco ||
                                                _gameService.currentPhase ==
                                                    GamePhase.principale) &&
                                            _gameService.puoiAttaccare(index) &&
                                            !_gameService.hasAttackedThisTurn(
                                                personaggio.id)
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                              spreadRadius: 2,
                                            ),
                                          ],
                                  ),
                                  child: personaggio != null
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.asset(
                                                personaggio.imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color:
                                                        Colors.green.shade300,
                                                    child: Center(
                                                      child: Text(
                                                        personaggio.name,
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            color:
                                                                Colors.white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: Transform.rotate(
                                            angle: 3.14159, // 180 gradi
                                            child: Image.asset(
                                              'assets/images/game/icons/icona_personaggio.png',
                                              width: 32,
                                              height: 32,
                                              color: const Color.fromARGB(
                                                      255, 255, 255, 255)
                                                  .withOpacity(0.15),
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 32,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                ),
                                // Overlay scuro quando highlighted
                                if (isHighlighted)
                                  Container(
                                    width: 85,
                                    height: 110,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Zone interazioni avversario
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final aiPlayer = gameState.giocatore2;
                  final interazione = index < aiPlayer.zoneInterazioni.length
                      ? aiPlayer.zoneInterazioni[index]
                      : null;
                  return DragTarget<GameCard>(
                    onWillAcceptWithDetails: (details) {
                      final card = details.data;
                      return card is InterazioneCard &&
                          interazione == null &&
                          _gameService.currentPhase == GamePhase.principale &&
                          _gameService.puoiGiocareCarta(card);
                    },
                    onAcceptWithDetails: (details) {
                      final card = details.data;
                      if (card is InterazioneCard) {
                        // Se vuoi permettere di "rubare" slot all'avversario, qui puoi gestire la logica
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHighlighted = candidateData.isNotEmpty;
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (interazione != null) {
                                _showCardDetails(interazione);
                              }
                            },
                            child: Container(
                              width: 110,
                              height: 75,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: interazione != null
                                    ? Colors.orange.withOpacity(0.3)
                                    : const Color(0xFFB9D3C1),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: interazione != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: RotatedBox(
                                        quarterTurns: 1, // 90 gradi orario
                                        child: SizedBox(
                                          width:
                                              75, // Deve essere l'altezza della zona finale
                                          height:
                                              110, // Deve essere la larghezza della zona finale
                                          child: Image.asset(
                                            interazione.imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: const Color.fromARGB(
                                                    255, 6, 105, 31),
                                                child: Center(
                                                  child: Text(
                                                    interazione.name,
                                                    style: const TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Transform.rotate(
                                        angle: 3.14159, // 180 gradi
                                        child: Image.asset(
                                          'assets/images/game/icons/icona_interazione.png',
                                          width: 32,
                                          height: 32,
                                          color: Colors.white.withOpacity(0.15),
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.auto_awesome,
                                              size: 32,
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Overlay scuro quando highlighted
                          if (isHighlighted)
                            Container(
                              width: 110,
                              height: 75,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Zona ambientazione (centrale)
              Builder(
                builder: (context) {
                  final ambientazione = gameState.ambientazioneAttiva;
                  return DragTarget<GameCard>(
                    onWillAcceptWithDetails: (details) {
                      final card = details.data;
                      return card is AmbientazioneCard &&
                          _gameService.currentPhase == GamePhase.principale &&
                          _gameService.puoiGiocareCarta(card);
                    },
                    onAcceptWithDetails: (details) {
                      final card = details.data;
                      if (card is AmbientazioneCard) {
                        _playCardInZone(card, 'ambientazione', 0);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHighlighted = candidateData.isNotEmpty;

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (ambientazione != null) {
                                _showCardDetails(ambientazione);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ambientazione == null && !isHighlighted
                                    ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                child: Container(
                                  width: 110, // Aumentato da 90 a 110
                                  height: 75, // Aumentato da 60 a 75
                                  decoration: BoxDecoration(
                                    color: ambientazione != null
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ambientazione != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: RotatedBox(
                                            quarterTurns: 1, // 90 gradi orario
                                            child: SizedBox(
                                              width:
                                                  75, // Deve essere l'altezza della zona finale
                                              height:
                                                  110, // Deve essere la larghezza della zona finale
                                              child: Image.asset(
                                                ambientazione.imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.blue.shade300,
                                                    child: Center(
                                                      child: Text(
                                                        ambientazione.name,
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            color:
                                                                Colors.white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Image.asset(
                                            'assets/images/game/icons/icona_ambientazione.png',
                                            width: 32,
                                            height: 32,
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.landscape,
                                                size: 32,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          // Overlay scuro quando highlighted
                          if (isHighlighted)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 110,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              // Zone interazioni giocatore
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final humanPlayer = gameState.giocatore1;
                  final interazione = index < humanPlayer.zoneInterazioni.length
                      ? humanPlayer.zoneInterazioni[index]
                      : null;
                  return DragTarget<GameCard>(
                    onWillAcceptWithDetails: (details) {
                      final card = details.data;
                      return card is InterazioneCard &&
                          interazione == null &&
                          _gameService.currentPhase == GamePhase.principale &&
                          _gameService.puoiGiocareCarta(card);
                    },
                    onAcceptWithDetails: (details) {
                      final card = details.data;
                      if (card is InterazioneCard) {
                        _playCardInZone(card, 'interazione', index);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHighlighted = candidateData.isNotEmpty;

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (interazione != null) {
                                _showCardDetails(interazione);
                              }
                            },
                            child: Container(
                              width: 110,
                              height: 75,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: interazione != null
                                    ? Colors.orange.withOpacity(0.3)
                                    : const Color(0xFF75E288),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: interazione != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: RotatedBox(
                                        quarterTurns: 1, // 90 gradi orario
                                        child: SizedBox(
                                          width:
                                              75, // Deve essere l'altezza della zona finale
                                          height:
                                              110, // Deve essere la larghezza della zona finale
                                          child: Image.asset(
                                            interazione.imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.orange.shade300,
                                                child: Center(
                                                  child: Text(
                                                    interazione.name,
                                                    style: const TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Image.asset(
                                        'assets/images/game/icons/icona_interazione.png',
                                        width: 32,
                                        height: 32,
                                        color: Colors.white.withOpacity(0.2),
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.auto_awesome,
                                            size: 32,
                                            color:
                                                Colors.white.withOpacity(0.5),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          // Overlay scuro quando highlighted
                          if (isHighlighted)
                            Container(
                              width: 110,
                              height: 75,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Zone personaggi giocatore (in basso)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Zone personaggi utente
                  ...List.generate(3, (index) {
                    final humanPlayer = gameState.giocatore1;
                    final personaggio =
                        index < humanPlayer.zonePersonaggi.length
                            ? humanPlayer.zonePersonaggi[index]
                            : null;
                    return DragTarget<GameCard>(
                      onWillAcceptWithDetails: (details) {
                        final card = details.data;
                        return card is PersonaggioCard &&
                            personaggio == null &&
                            _gameService.currentPhase == GamePhase.principale &&
                            _gameService.puoiGiocareCarta(card);
                      },
                      onAcceptWithDetails: (details) {
                        final card = details.data;
                        if (card is PersonaggioCard) {
                          _playCardInZone(card, 'personaggio', index);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHighlighted = candidateData.isNotEmpty;
                        return GestureDetector(
                          onTap: () {
                            if (personaggio != null) {
                              // Se non è in fase di selezione del target, mostra i dettagli della carta
                              if (!_isSelectingTarget) {
                                // Se è in fase principale/attacco e può attaccare, gestisci l'attacco
                                if ((_gameService.currentPhase ==
                                            GamePhase.attacco ||
                                        _gameService.currentPhase ==
                                            GamePhase.principale) &&
                                    _gameService.puoiAttaccare(index) &&
                                    !_gameService
                                        .hasAttackedThisTurn(personaggio.id)) {
                                  _onCardTapped(personaggio);
                                } else {
                                  // Altrimenti mostra i dettagli della carta
                                  _showCardDetails(personaggio);
                                }
                              } else {
                                // Se stiamo selezionando un target, continua con la logica di attacco
                                _onCardTapped(personaggio);
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 85,
                                height: 110,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: personaggio != null
                                      ? Colors.green.withOpacity(0.3)
                                      : const Color(0xFF75E288),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: personaggio != null &&
                                          (_gameService.currentPhase ==
                                                  GamePhase.attacco ||
                                              _gameService.currentPhase ==
                                                  GamePhase.principale) &&
                                          _gameService.puoiAttaccare(index) &&
                                          !_gameService.hasAttackedThisTurn(
                                              personaggio.id)
                                      ? [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                                    255, 255, 255, 255)
                                                .withOpacity(0.5),
                                            blurRadius: 8, // Ridotto da 8 a 6
                                            spreadRadius: 4, // Ridotto da 4 a 3
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                ),
                                child: personaggio != null
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.asset(
                                              personaggio.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.green.shade300,
                                                  child: Center(
                                                    child: Text(
                                                      personaggio.name,
                                                      style: const TextStyle(
                                                          fontSize: 9,
                                                          color: Colors.white),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Image.asset(
                                          'assets/images/game/icons/icona_personaggio.png',
                                          width: 32,
                                          height: 32,
                                          color: Colors.white.withOpacity(0.2),
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 32,
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                              // Overlay scuro quando highlighted
                              if (isHighlighted)
                                Container(
                                  width: 85,
                                  height: 110,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(width: 6),
                  // Mazzo e cimitero utente (verticale)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 95,
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/game/deck.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideElements(GameState gameState, Size screenSize) {
    // Rimuovo le zone mazzo e cimitero qui, lasciando solo eventuali altre funzionalità (es. energie, animazione energia)
    final humanPlayer = gameState.giocatore1;

    return Stack(
      children: [
        // Energie (solo numero)
        Positioned(
          left: 16,
          bottom: 192,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                // Immagine di sfondo
                AnimatedBuilder(
                  animation:
                      _energyRotationController, // Usa il controller veloce
                  builder: (context, child) {
                    // Controllo sicurezza per valori finiti
                    final rotationValue = _energyRotationAnimation.value;
                    final safeRotation =
                        rotationValue.isFinite ? rotationValue : 0.0;

                    return Transform.rotate(
                      angle: safeRotation,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/game/energy_base_green.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Numero energia
                Positioned(
                  top: 14,
                  left: 26,
                  child: AnimatedBuilder(
                    animation: _energyNumberController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _energyNumberScaleAnimation.value,
                        child: Text(
                          '${humanPlayer.energia}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Energie AI (solo numero)
        Positioned(
          right: 16,
          top: 72,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                // Immagine di sfondo dell'avversario
                AnimatedBuilder(
                  animation: _aiEnergyRotationController,
                  builder: (context, child) {
                    // Controllo sicurezza per valori finiti
                    final rotationValue = _aiEnergyRotationAnimation.value;
                    final safeRotation =
                        rotationValue.isFinite ? rotationValue : 0.0;

                    return Transform.rotate(
                      angle: safeRotation,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/game/energy_base_gray.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Numero energia dell'avversario
                Positioned(
                  top: 14,
                  left: 26,
                  child: AnimatedBuilder(
                    animation: _aiEnergyNumberController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _aiEnergyNumberScaleAnimation.value,
                        child: Text(
                          '${gameState.giocatore2.energia}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHand(GameState gameState, Size screenSize) {
    final humanPlayer = gameState.giocatore1;

    return Positioned(
      bottom: -40, // Riportato alla posizione originale
      left: 0,
      right: 0,
      child: Column(
        children: [
          SizedBox(
            height: 270, // Aumentato per le carte più grandi
            child: Stack(
              children: [
                for (int i = 0; i < humanPlayer.mano.length; i++)
                  _buildFanCard(humanPlayer.mano[i], i, humanPlayer.mano.length,
                      screenSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanCard(
      GameCard card, int index, int totalCards, Size screenSize) {
    final isSelected = _isCardSelected(card);
    final canPlay = _canAttackCard(card);

    // Calcola la posizione e rotazione per l'effetto ventaglio
    final centerIndex = (totalCards - 1) / 2;
    final offset = index - centerIndex;
    const maxAngle = 18.0; // Aumentato per un ventaglio più inarcato

    // Controllo sicurezza: evita divisioni per zero e valori NaN
    final double angle;
    if (centerIndex == 0 || !centerIndex.isFinite) {
      angle =
          0.0; // Nessuna rotazione se c'è solo una carta o valori non validi
    } else {
      final rawAngle = (offset / centerIndex) * maxAngle * (3.14159 / 180);
      angle = rawAngle.isFinite ? rawAngle : 0.0;
    }

    const cardWidth = 120.0; // Ingrandito ulteriormente
    const cardSpacing = 55.0; // Ridotto per avvicinare le carte
    final baseX =
        (screenSize.width / 2) - (cardWidth / 2) + (offset * cardSpacing);
    final baseY = 20.0 +
        (offset.abs() * 8) +
        (offset.abs() > 1
            ? (offset.abs() - 1) * 4
            : 0); // Carte più esterne ancora più basse

    // Ottieni il nome dell'utente per il controllo
    final user = Provider.of<User>(context, listen: false);
    final playerName = user.username.isNotEmpty ? user.username : 'Giocatore';

    return Positioned(
      left: baseX,
      top: baseY,
      child: Transform.rotate(
        angle: angle,
        child: Draggable<GameCard>(
          data: card,
          dragAnchorStrategy: (_gameService.isAITurn ||
                  _gameService.gameState?.giocatoreAttivo.name != playerName)
              ? (draggable, context, position) => Offset.zero
              : childDragAnchorStrategy,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: cardWidth,
                height: 165,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    card.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _getCardTypeColor(card.type).withOpacity(0.3),
                        child: Center(
                          child: Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: const SizedBox.shrink(),
          child: GestureDetector(
            onTap: () => _showCardDetails(card),
            onLongPress: () => _selectCard(card),
            child: Container(
              width: cardWidth,
              height: 165, // Ingrandito ulteriormente
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _getCardTypeColor(card.type).withOpacity(0.3),
                      child: Center(
                        child: Text(
                          card.name,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                          textAlign: TextAlign.center,
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
    );
  }

  // Metodo per ottenere il colore in base al tipo di carta
  Color _getCardTypeColor(CardType type) {
    switch (type) {
      case CardType.personaggio:
        return Colors.green.shade600;
      case CardType.ambientazione:
        return Colors.green.shade600;
      case CardType.interazione:
        return Colors.green.shade600;
    }
  }

  void _showCardDetails(GameCard card) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card image with 3D effect
                      SizedBox(
                        width: 220,
                        height: 330,
                        child: GameInteractive3DCard(
                          card: card,
                          width: 220,
                          enableInteraction: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card effect
                      Text(
                        card.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGameControlsOverlay(GameState gameState, Size screenSize) {
    final isHumanTurn =
        gameState.giocatoreAttivo.name == gameState.giocatore1.name;
    final isAITurn = _gameService.isAITurn;

    return Stack(
      children: [
        // Next phase button (allineato con la zona ambientazione) - visibile solo quando è il turno del giocatore
        if (isHumanTurn && !isAITurn)
          Positioned(
            right: 16,
            top: screenSize.height * 0.37, // Spostato più in alto
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08), // Più scuro
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 11, 90, 38)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _nextPhase,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        _getNextPhaseButtonText(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'NeueHaasDisplay',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _selectCard(GameCard card) {
    setState(() {
      if (_gameService.currentPhase == GamePhase.principale) {
        // In fase principale, controlla se è un personaggio in campo che può attaccare
        if (card is PersonaggioCard) {
          final gameState = _gameService.gameState!;
          final myCards = gameState.giocatoreAttivo.zonePersonaggi;

          // Cerca se questo personaggio è in campo
          int index = -1;
          for (int i = 0; i < myCards.length; i++) {
            if (myCards[i] != null && myCards[i]!.id == card.id) {
              index = i;
              break;
            }
          }

          if (index != -1 && _gameService.puoiAttaccare(index)) {
            // È un personaggio in campo che può attaccare
            _selectedAttacker = card;
            _isSelectingTarget = true;
            _selectedCard = null;
          } else {
            // È una carta in mano o non può attaccare, seleziona normalmente
            _selectedCard = _selectedCard == card ? null : card;
            _selectedAttacker = null;
            _isSelectingTarget = false;
          }
        } else {
          // Non è un personaggio, seleziona normalmente
          _selectedCard = _selectedCard == card ? null : card;
          _selectedAttacker = null;
          _isSelectingTarget = false;
        }
      } else if (_gameService.currentPhase == GamePhase.attacco) {
        // In fase attacco, seleziona per attaccare
        if (card is PersonaggioCard) {
          final player = _gameService.gameState!.giocatoreAttivo;
          final index = player.zonePersonaggi.indexOf(card);
          if (index != -1 && _gameService.puoiAttaccare(index)) {
            _selectedAttacker = card;
            _isSelectingTarget = true;
          }
        }
      } else {
        // In altre fasi, seleziona per giocare
        _selectedCard = _selectedCard == card ? null : card;
        _selectedAttacker = null;
        _isSelectingTarget = false;
      }
    });
  }

  String _getNextPhaseButtonText() {
    switch (_gameService.currentPhase) {
      case GamePhase.energia:
        // Non dovrebbe mai essere mostrato perché energia e pesca sono automatizzate
        return 'Principale';
      case GamePhase.pesca:
        // Non dovrebbe mai essere mostrato perché la pesca è automatizzata
        return 'Principale';
      case GamePhase.principale:
        return 'Fine Turno';
      case GamePhase.attacco:
        return 'Fine Turno';
      case GamePhase.fine:
        return 'Nuovo Turno';
    }
  }

  Widget _buildGameOverScreen() {
    final vincitore = _gameService.vincitore;
    final gameState = _gameService.gameState;
    final motivoVittoria = gameState?.motivoVittoria ?? 'Partita terminata';

    // Controlla se ha vinto Bombo (AI)
    final bomboHaVinto =
        vincitore?.name == 'Bombo' || gameState?.giocatore1.vite == 0;

    // Il commento di vittoria è gestito dal dialog stesso, non serve SnackBar aggiuntivo

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bomboHaVinto ? 'Bombo ha vinto!' : 'Hai vinto!',
                      style: TextStyle(
                        fontSize: bomboHaVinto ? 28 : 42,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NeueHaasDisplay',
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.8)
                                : const Color(0xFF4BFF9E).withOpacity(0.8),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.8)
                                : const Color(0xFF4BFF9E).withOpacity(0.8),
                            blurRadius: 40,
                          ),
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.6)
                                : const Color(0xFF4BFF9E).withOpacity(0.6),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      motivoVittoria,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                        fontFamily: 'NeueHaasDisplay',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _initializeGame();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Nuova Partita',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Esci',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            textAlign: TextAlign.center,
                          ),
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

    // Ritorna un widget vuoto perché il dialog viene mostrato sopra
    return Container();
  }

  // Metodi per le zone di gioco
  Widget _buildAmbientazioneZone(
      GameState gameState, double x, double y, Size screenSize) {
    final ambientazione = gameState.ambientazioneAttiva;

    return Positioned(
      left: x - 55, // Aumentato da 45 a 55 per la carta più grande
      top: y - 35, // Aumentato da 30 a 35 per la carta più grande
      child: DragTarget<GameCard>(
        onWillAcceptWithDetails: (details) {
          final card = details.data;
          return card is AmbientazioneCard &&
              _gameService.currentPhase == GamePhase.principale &&
              _gameService.puoiGiocareCarta(card);
        },
        onAcceptWithDetails: (details) {
          final card = details.data;
          if (card is AmbientazioneCard) {
            _playCardInZone(card, 'ambientazione', 0);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHighlighted = candidateData.isNotEmpty;

          return Container(
            width: 110, // Aumentato da 90 a 110
            height: 75, // Aumentato da 60 a 75
            decoration: BoxDecoration(
              color: ambientazione != null
                  ? Colors.blue.withOpacity(0.3)
                  : isHighlighted
                      ? Colors.green.withOpacity(0.4)
                      : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isHighlighted
                      ? Colors.green.shade600
                      : ambientazione != null
                          ? Colors.green.withOpacity(0.7)
                          : Colors.white.withOpacity(0.5),
                  width: 2),
            ),
            child: ambientazione != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/cards/${ambientazione.name.toLowerCase().replaceAll(' ', '_')}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue.shade300,
                          child: Center(
                            child: Text(
                              ambientazione.name,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.landscape,
                          color: isHighlighted
                              ? Colors.green.shade600
                              : Colors.white.withOpacity(0.7),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ambientazione',
                          style: TextStyle(
                              fontSize: 10,
                              color: isHighlighted
                                  ? Colors.green.shade600
                                  : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'NeueHaasDisplay'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildOpponentCharacterZones(
      GameState gameState, double x, double y, Size screenSize) {
    final aiPlayer = gameState.giocatore2;

    return Positioned(
      left: x - 130, // Aumentato da 110 a 130 per le carte più grandi
      top: y - 40, // Aumentato da 35 a 40 per le carte più grandi
      child: Row(
        children: List.generate(3, (index) {
          final personaggio = index < aiPlayer.zonePersonaggi.length
              ? aiPlayer.zonePersonaggi[index]
              : null;

          return Container(
            width: 85, // Aumentato da 70 a 85
            height: 85, // Aumentato da 70 a 85
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: personaggio != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: personaggio != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/cards/${personaggio.name.toLowerCase().replaceAll(' ', '_')}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red.shade300,
                          child: Center(
                            child: Text(
                              personaggio.name,
                              style: const TextStyle(
                                  fontSize: 8, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Text(
                      'Zone personaggio',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
          );
        }),
      ),
    );
  }

  Widget _buildOpponentInteractionZones(
      GameState gameState, double x, double y, Size screenSize) {
    final aiPlayer = gameState.giocatore2;

    return Positioned(
      left: x - 90, // Aumentato da 75 a 90 per le carte più grandi
      top: y - 30, // Aumentato da 25 a 30 per le carte più grandi
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          final interazione = index < aiPlayer.zoneInterazioni.length
              ? aiPlayer.zoneInterazioni[index]
              : null;
          return DragTarget<GameCard>(
            onWillAcceptWithDetails: (details) {
              final card = details.data;
              return card is InterazioneCard &&
                  interazione == null &&
                  _gameService.currentPhase == GamePhase.principale &&
                  _gameService.puoiGiocareCarta(card);
            },
            onAcceptWithDetails: (details) {
              final card = details.data;
              if (card is InterazioneCard) {
                // Se vuoi permettere di "rubare" slot all'avversario, qui puoi gestire la logica
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;
              return Container(
                width: 110,
                height: 75,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: interazione != null
                      ? Colors.purple.withOpacity(0.3)
                      : isHighlighted
                          ? Colors.purple.withOpacity(0.7)
                          : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isHighlighted
                          ? Colors.purple.shade600
                          : interazione != null
                              ? Colors.purple.withOpacity(0.7)
                              : Colors.white.withOpacity(0.5),
                      width: 2),
                ),
                child: interazione != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/cards/${interazione.name.toLowerCase().replaceAll(' ', '_')}.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.purple.shade300,
                              child: Center(
                                child: Text(
                                  interazione.name,
                                  style: const TextStyle(
                                      fontSize: 7, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Text(
                          'zone interazioni',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPlayerCharacterZones(
      GameState gameState, double x, double y, Size screenSize) {
    final humanPlayer = gameState.giocatore1;

    return Positioned(
      left: x - 130, // Aumentato da 110 a 130 per le carte più grandi
      top: y - 50, // Aumentato da 45 a 50 per le carte più grandi
      child: Row(
        children: List.generate(3, (index) {
          final personaggio = index < humanPlayer.zonePersonaggi.length
              ? humanPlayer.zonePersonaggi[index]
              : null;

          return DragTarget<GameCard>(
            onWillAcceptWithDetails: (details) {
              final card = details.data;
              return card is PersonaggioCard &&
                  personaggio == null &&
                  _gameService.currentPhase == GamePhase.principale &&
                  _gameService.puoiGiocareCarta(card);
            },
            onAcceptWithDetails: (details) {
              final card = details.data;
              if (card is PersonaggioCard) {
                _playCardInZone(card, 'personaggio', index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  if ((_gameService.currentPhase == GamePhase.attacco ||
                          _gameService.currentPhase == GamePhase.principale) &&
                      personaggio != null) {
                    _onCardTapped(personaggio);
                  }
                },
                child: Container(
                  width: 85, // Aumentato da 70 a 85
                  height: 110, // Aumentato da 90 a 110
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: personaggio != null
                        ? Colors.green.withOpacity(0.3)
                        : isHighlighted
                            ? Colors.purple.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedAttacker == personaggio
                          ? Colors.yellow
                          : isHighlighted
                              ? Colors.purple.shade600
                              : personaggio != null
                                  ? (_gameService.currentPhase ==
                                              GamePhase.attacco &&
                                          _gameService.puoiAttaccare(index) &&
                                          !_gameService.hasAttackedThisTurn(
                                              personaggio.id))
                                      ? Colors.red.shade400
                                      : Colors.purple.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.5),
                      width: _selectedAttacker == personaggio ? 3 : 2,
                    ),
                    boxShadow: personaggio != null &&
                            (_gameService.currentPhase == GamePhase.attacco ||
                                _gameService.currentPhase ==
                                    GamePhase.principale) &&
                            _gameService.puoiAttaccare(index) &&
                            !_gameService.hasAttackedThisTurn(personaggio.id)
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: personaggio != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/cards/${personaggio.name.toLowerCase().replaceAll(' ', '_')}.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.green.shade300,
                                    child: Center(
                                      child: Text(
                                        personaggio.name,
                                        style: const TextStyle(
                                            fontSize: 9, color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: isHighlighted
                                    ? Colors.purple.shade600
                                    : Colors.white.withOpacity(0.7),
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Personaggio',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: isHighlighted
                                        ? Colors.purple.shade600
                                        : Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'NeueHaasDisplay'),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPlayerInteractionZones(
      GameState gameState, double x, double y, Size screenSize) {
    final humanPlayer = gameState.giocatore1;

    return Positioned(
      left: x - 90, // Aumentato da 75 a 90 per le carte più grandi
      top: y - 35, // Aumentato da 30 a 35 per le carte più grandi
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          final interazione = index < humanPlayer.zoneInterazioni.length
              ? humanPlayer.zoneInterazioni[index]
              : null;

          return DragTarget<GameCard>(
            onWillAcceptWithDetails: (details) {
              final card = details.data;
              return card is InterazioneCard &&
                  interazione == null &&
                  _gameService.currentPhase == GamePhase.principale &&
                  _gameService.puoiGiocareCarta(card);
            },
            onAcceptWithDetails: (details) {
              final card = details.data;
              if (card is InterazioneCard) {
                _playCardInZone(card, 'interazione', index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;

              return Container(
                width: 110,
                height: 75,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: interazione != null
                      ? Colors.orange.withOpacity(0.3)
                      : isHighlighted
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isHighlighted
                          ? Colors.orange.shade600
                          : interazione != null
                              ? Colors.orange.withOpacity(0.7)
                              : Colors.white.withOpacity(0.5),
                      width: 2),
                ),
                child: interazione != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/cards/${interazione.name.toLowerCase().replaceAll(' ', '_')}.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color.fromARGB(255, 77, 255, 139),
                              child: Center(
                                child: Text(
                                  interazione.name,
                                  style: const TextStyle(
                                      fontSize: 8, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: isHighlighted
                                  ? Colors.orange.shade600
                                  : Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Interazione',
                              style: TextStyle(
                                  fontSize: 7,
                                  color: isHighlighted
                                      ? Colors.orange.shade600
                                      : Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'NeueHaasDisplay'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              );
            },
          );
        }),
      ),
    );
  }

  // Nuovo widget per nome e vite in basso a sinistra
  Widget _buildPlayerInfo(GameState gameState, Size screenSize) {
    final humanPlayer = gameState.giocatore1;

    return Positioned(
      bottom: 20,
      left: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  humanPlayer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: List.generate(3, (index) {
                    final isActive = index < humanPlayer.vite;
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFF18FB3D), Color(0xFF4BFF9E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : Colors.grey.withOpacity(0.4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF18FB3D).withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playCardInZone(GameCard card, String zone, int index) {
    if (_gameService.puoiGiocareCarta(card)) {
      // Se è una carta personaggio o interazione, usa la posizione specifica
      if (card is PersonaggioCard || card is InterazioneCard) {
        _gameService.giocaCartaInPosizione(card, index);
      } else {
        // Per le ambientazioni usa il metodo standard (c'è solo una posizione)
        _gameService.giocaCarta(card);
      }
      setState(() {
        _selectedCard = null;
      });
    }
  }

  void _showTargetSelectionDialog() {
    final gameState = _gameService.gameState!;
    final enemyPersonaggi =
        gameState.giocatore2.zonePersonaggi; // AI è sempre giocatore2

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width:
                    400, // Aggiustato per le carte con ratio corretta (85x110)
                padding: const EdgeInsets.all(24), // Ridotto da 32 a 20
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Testo "Colpisci Bombo" in alto (solo se si può attaccare direttamente)
                    if (!gameState.giocatore2.haPersonaggiInCampo)
                      const Text(
                        'Colpisci Bombo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NeueHaasDisplay',
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (!gameState.giocatore2.haPersonaggiInCampo)
                      const SizedBox(height: 16),
                    // Immagine di Bombo ingrandita (solo se si può attaccare direttamente)
                    if (!gameState.giocatore2.haPersonaggiInCampo)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _executeDirectAttack();
                        },
                        child: SizedBox(
                          width: 160, // Ingrandito da 80 a 140
                          height: 195, // Ingrandito da 100 a 175
                          child: Image.asset(
                            'assets/images/game/bombo_ai.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 140,
                                height: 175,
                                color: Colors.transparent,
                              );
                            },
                          ),
                        ),
                      ),
                    // Vite di Bombo sotto l'immagine
                    if (!gameState.giocatore2.haPersonaggiInCampo) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isActive = index < gameState.giocatore2.vite;
                          return Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isActive
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF18FB3D),
                                        Color(0xFF4BFF9E)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isActive
                                  ? null
                                  : Colors.grey.withOpacity(0.4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF18FB3D)
                                            .withOpacity(0.8),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                    // Mostra i personaggi nemici come carte visive
                    if (enemyPersonaggi.any((card) => card != null))
                      SizedBox(
                        height: 110, // Aggiustato per la nuova ratio
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < enemyPersonaggi.length; i++)
                              if (enemyPersonaggi[i] != null)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6), // Ridotto da 8 a 6
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _executeTargetedAttack(i);
                                    },
                                    child: Container(
                                      width:
                                          85, // Stessa larghezza delle carte in campo
                                      height:
                                          110, // Stessa altezza delle carte in campo
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF18FB3D)
                                              .withOpacity(0.8),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF18FB3D)
                                                .withOpacity(0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          children: [
                                            // Immagine della carta
                                            Image.asset(
                                              enemyPersonaggi[i]!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        const Color(0xFF18FB3D)
                                                            .withOpacity(0.3),
                                                        const Color(0xFF4BFF9E)
                                                            .withOpacity(0.3),
                                                      ],
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      enemyPersonaggi[i]!.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            // Overlay per indicare che è selezionabile
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      const Color(0xFF18FB3D)
                                                          .withOpacity(0.2),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Icona bersaglio al centro
                                            const Positioned(
                                              top: 8, // Ridotto da 12 a 8
                                              left: 8, // Ridotto da 12 a 8
                                              child: Icon(
                                                Icons.gps_fixed,
                                                color: Color(0xFF18FB3D),
                                                size: 20, // Ridotto da 24 a 20
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.white,
                                                    blurRadius:
                                                        3, // Ridotto da 4 a 3
                                                  ),
                                                ],
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
                      ),
                    const SizedBox(height: 16),

                    // Messaggio informativo se ci sono personaggi ma non si può attaccare direttamente
                    if (gameState.giocatore2.haPersonaggiInCampo)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Devi attaccare i personaggi nemici prima di poter attaccare direttamente',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'NeueHaasDisplay',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _executeTargetedAttack(int defenderIndex) {
    if (_selectedAttacker == null) return;

    // Trova l'indice dell'attaccante
    final myCards = _gameService.gameState!.giocatoreAttivo.zonePersonaggi;
    int attackerIndex = -1;
    for (int i = 0; i < myCards.length; i++) {
      if (myCards[i] != null && myCards[i]!.id == _selectedAttacker!.id) {
        attackerIndex = i;
        break;
      }
    }

    if (attackerIndex != -1) {
      _gameService.attaccaConPersonaggio(attackerIndex, defenderIndex);
      setState(() {
        _selectedAttacker = null;
        _isSelectingTarget = false;
      });
      _showAttackResult();
    }
  }

  Widget _buildAIHand(GameState gameState, Size screenSize) {
    // Mostra sempre le carte dell'AI (giocatore2), non del giocatore attivo
    final aiPlayer = gameState.giocatore2; // L'AI è sempre giocatore2

    return Positioned(
      top: -20, // Spostato più in alto di 20 pixel
      left: 0,
      right: 0,
      child: SizedBox(
        height: 140, // Aumentato da 120 a 140 per evitare il taglio
        child: Stack(
          children: [
            for (int i = 0; i < aiPlayer.mano.length; i++)
              _buildAIFanCard(i, aiPlayer.mano.length, screenSize),

            // Sostituisco la sezione AI info in _buildAIHand con un widget simile a _buildPlayerInfo, ma per l'AI e posizionato in alto a destra.
            // Aggiungo una nuova funzione _buildAIInfo simile a _buildPlayerInfo.
            _buildAIInfo(gameState, screenSize),

            // Menu button a sinistra
            Positioned(
              top: 40, // Adeguato alla nuova posizione
              left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: _showGameMenu,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFanCard(int index, int totalCards, Size screenSize) {
    // Calcola la posizione e rotazione per l'effetto ventaglio (invertito)
    final centerIndex = (totalCards - 1) / 2;
    final offset = index - centerIndex;
    const maxAngle = 15.0; // gradi massimi di rotazione

    // Controllo sicurezza: evita divisioni per zero e valori NaN
    final double angle;
    if (centerIndex == 0 || !centerIndex.isFinite) {
      angle =
          0.0; // Nessuna rotazione se c'è solo una carta o valori non validi
    } else {
      final rawAngle = -(offset / centerIndex) * maxAngle * (3.14159 / 180);
      angle = rawAngle.isFinite ? rawAngle : 0.0;
    }

    const cardWidth = 70.0; // Più piccolo delle carte del giocatore
    const cardSpacing = 55.0; // Più compatto
    final baseX =
        (screenSize.width / 2) - (cardWidth / 2) + (offset * cardSpacing);
    final baseY =
        10.0 - (offset.abs() * 5); // Le carte laterali sono più in alto

    return Positioned(
      left: baseX,
      top: baseY,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: cardWidth,
          height: 100, // Più basso delle carte del giocatore
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/game/back_carte_avversarie.png',
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                        Colors.blue.shade400,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'TUNUÉ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInfo(GameState gameState, Size screenSize) {
    final aiPlayer = gameState.giocatore2;
    return Positioned(
      top: 40,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 20, 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  aiPlayer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: List.generate(3, (index) {
                    final isActive = index < aiPlayer.vite;
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFF18FB3D), Color(0xFF4BFF9E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : Colors.grey.withOpacity(0.4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF18FB3D).withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBomboAI(Size screenSize) {
    return Stack(
      children: [
        // Bombo
        Positioned(
          left: -116, // Posizionato per sbuccare a metà da sinistra
          top: screenSize.height * 0.24, // Alzato (era 0.35)
          child: Transform.rotate(
            angle: 0.56, // Inclinazione leggera verso destra (circa 7 gradi)
            child: SizedBox(
              width: 200,
              height: 250,
              child: Image.asset(
                'assets/images/game/bombo_ai.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 250,
                    color: Colors.transparent,
                  );
                },
              ),
            ),
          ),
        ),

        // Fumetto con commento
        if (_currentBomboComment != null)
          Positioned(
            left: 64,
            top: screenSize.height * 0.24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _currentBomboComment!,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 23, 23, 23),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NeueHaasDisplay',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardDrawAnimation(Size screenSize) {
    return Positioned(
      left: screenSize.width / 2 - 75, // Centrato orizzontalmente
      top: screenSize.height / 2 - 100, // Centrato verticalmente
      child: AnimatedBuilder(
        animation: _cardDrawAnimationController,
        builder: (context, child) {
          return SlideTransition(
            position: _cardDrawSlideAnimation,
            child: FadeTransition(
              opacity: _cardDrawFadeAnimation,
              child: ScaleTransition(
                scale: _cardDrawScaleAnimation,
                child: Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Immagine della carta
                        Image.asset(
                          _drawnCard!.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: _getCardTypeColor(_drawnCard!.type)
                                  .withOpacity(0.3),
                              child: Center(
                                child: Text(
                                  _drawnCard!.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGameOverDialog() {
    final vincitore = _gameService.vincitore;
    final gameState = _gameService.gameState;
    if (gameState == null || !mounted) return;

    final motivoVittoria = gameState.motivoVittoria ?? 'Partita terminata';
    final bomboHaVinto =
        vincitore?.name == 'Bombo' || gameState.giocatore1.vite == 0;

    // Se ha vinto il giocatore, aggiungi i Tunue Coin
    if (!bomboHaVinto) {
      final user = Provider.of<User>(context, listen: false);
      user.addCoins(12);
      // Sincronizza i dati con Supabase
      final authService = AuthService();
      authService.syncUserData(user);
    }

    // Il commento di vittoria è gestito dal dialog stesso, non serve SnackBar aggiuntivo

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bomboHaVinto ? 'Bombo ha vinto!' : 'Hai vinto!',
                      style: TextStyle(
                        fontSize: bomboHaVinto ? 28 : 42,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NeueHaasDisplay',
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.8)
                                : const Color(0xFF4BFF9E).withOpacity(0.8),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.8)
                                : const Color(0xFF4BFF9E).withOpacity(0.8),
                            blurRadius: 40,
                          ),
                          Shadow(
                            color: bomboHaVinto
                                ? Colors.orange.withOpacity(0.6)
                                : const Color(0xFF4BFF9E).withOpacity(0.6),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      motivoVittoria,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                        fontFamily: 'NeueHaasDisplay',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!bomboHaVinto) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF18FB3D).withOpacity(0.2),
                              const Color(0xFF4BFF9E).withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFF4BFF9E).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/icons/tunue_logo.png',
                              width: 48,
                              height: 48,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.monetization_on,
                                color: Color(0xFF18FB3D),
                                size: 24,
                              ),
                            ),
                            const Text(
                              '+12 Tunue Coin',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NeueHaasDisplay',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _initializeGame();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Nuova Partita',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NeueHaasDisplay',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Esci',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NeueHaasDisplay',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
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
  }
}

// Widget per la carta 3D interattiva
class GameInteractive3DCard extends StatefulWidget {
  final GameCard card;
  final double width;
  final bool enableInteraction;

  const GameInteractive3DCard({
    super.key,
    required this.card,
    required this.width,
    this.enableInteraction = true,
  });

  @override
  State<GameInteractive3DCard> createState() => _GameInteractive3DCardState();
}

class _GameInteractive3DCardState extends State<GameInteractive3DCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _resetController;

  late Animation<double> _resetRotationX;
  late Animation<double> _resetRotationY;
  late Animation<double> _resetScale;

  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _resetController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resetController.dispose();
    super.dispose();
  }

  void _updateRotation(Offset localPosition, Size size) {
    if (!widget.enableInteraction) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const maxRotation = 0.2;

    setState(() {
      _rotationY = ((localPosition.dx - centerX) / centerX) * maxRotation;
      _rotationX = ((centerY - localPosition.dy) / centerY) * maxRotation;
      _scale = 1.1;
    });
  }

  void _resetCard() {
    if (!widget.enableInteraction) return;

    _resetRotationX = Tween<double>(
      begin: _rotationX,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));

    _resetRotationY = Tween<double>(
      begin: _rotationY,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));

    _resetScale = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));

    _resetController.addListener(() {
      setState(() {
        _rotationX = _resetRotationX.value;
        _rotationY = _resetRotationY.value;
        _scale = _resetScale.value;
      });
    });

    _resetController.forward().then((_) {
      _resetController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.enableInteraction
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              _updateRotation(localPosition, box.size);
            }
          : null,
      onPanEnd: widget.enableInteraction
          ? (details) {
              _resetCard();
            }
          : null,
      onTapDown: widget.enableInteraction
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              _updateRotation(localPosition, box.size);
            }
          : null,
      onTapUp: widget.enableInteraction
          ? (details) {
              _resetCard();
            }
          : null,
      onTapCancel: widget.enableInteraction
          ? () {
              _resetCard();
            }
          : null,
      child: MouseRegion(
        onHover: widget.enableInteraction
            ? (event) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(event.position);
                _updateRotation(localPosition, box.size);
              }
            : null,
        onExit: widget.enableInteraction
            ? (event) {
                _resetCard();
              }
            : null,
        child: AspectRatio(
          aspectRatio: 0.67,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Prospettiva
                  ..rotateX(_rotationX)
                  ..rotateY(_rotationY)
                  ..scale(_scale),
                child: Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(
                          _rotationY * 10,
                          _rotationX * 10 + 5,
                        ),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Immagine della carta
                        Image.asset(
                          widget.card.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: _getCardTypeColor(widget.card.type)
                                  .withOpacity(0.3),
                              child: Center(
                                child: Text(
                                  widget.card.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),

                        // Effetto riflesso basato sulla rotazione
                        _buildReflectionOverlay(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(
              -1.0 + (_rotationY * 2),
              -1.0 + (_rotationX * 2),
            ),
            end: Alignment(
              1.0 + (_rotationY * 2),
              1.0 + (_rotationX * 2),
            ),
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.transparent,
              Colors.transparent,
              Colors.white.withOpacity(0.2),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  Color _getCardTypeColor(CardType type) {
    switch (type) {
      case CardType.personaggio:
        return const Color.fromARGB(255, 30, 217, 64);
      case CardType.ambientazione:
        return const Color.fromARGB(255, 30, 217, 64);
      case CardType.interazione:
        return const Color.fromARGB(255, 30, 217, 64);
    }
  }
}
