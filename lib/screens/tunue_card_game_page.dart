import 'dart:math';

import 'package:flutter/material.dart';

import '../data/monster_allergy_cards.dart';
import '../models/card_game.dart';
import '../services/card_game_service.dart';

class TunueCardGamePage extends StatefulWidget {
  const TunueCardGamePage({super.key});

  @override
  _TunueCardGamePageState createState() => _TunueCardGamePageState();
}

class _TunueCardGamePageState extends State<TunueCardGamePage>
    with TickerProviderStateMixin {
  final CardGameService _gameService = CardGameService();
  GameCard? _selectedCard;
  PersonaggioCard? _selectedAttacker;
  bool _isSelectingTarget = false;

  // Animazione energia
  late AnimationController _energyAnimationController;
  late Animation<double> _energyFadeAnimation;
  late Animation<Offset> _energySlideAnimation;
  late Animation<double> _energyScaleAnimation;
  bool _showEnergyAnimation = false;

  @override
  void initState() {
    super.initState();

    // Inizializza l'animazione dell'energia
    _energyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
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

    _initializeGame();
  }

  @override
  void dispose() {
    _energyAnimationController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Crea il giocatore umano
    final player1 = Player(
      name: 'Giocatore',
      mazzo: List.from(MonsterAllergyCards.createDefaultDeck()),
    );

    // Configura il callback per gli effetti delle carte
    _gameService.onEffectActivated = (String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.purple.shade600,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    };

    // Configura il callback per l'animazione dell'energia
    _gameService.onEnergyAdded = () {
      _playEnergyAnimation();
    };

    // Configura il callback per le azioni dell'AI
    _gameService.onAIAction = (String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue.shade600,
        ),
      );
    };

    // Inizia partita vs AI
    _gameService.iniziaPartitaVsAI(player1);
    setState(() {});
  }

  void _playEnergyAnimation() {
    if (!mounted) return;

    setState(() {
      _showEnergyAnimation = true;
    });

    _energyAnimationController.reset();
    _energyAnimationController.forward();

    // Nascondi l'animazione dopo che è completata
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showEnergyAnimation = false;
        });
      }
    });
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Non puoi attaccare durante il primo turno!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange.shade600,
                ),
              );
            } else if (_gameService.hasAttackedThisTurn(card.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${card.name} ha già attaccato questo turno!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange.shade600,
                ),
              );
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Non puoi attaccare con ${card.name}: $reason'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange.shade600,
            ),
          );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade600,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_gameService.isGameOver) {
      return _buildGameOverScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4ADE80), // Verde chiaro
              Color(0xFF22C55E), // Verde medio
              Color(0xFF16A34A), // Verde scuro
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background pattern
              _buildBackgroundPattern(),

              // Main circular game field
              _buildCircularGameField(gameState, screenSize),

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CircularPatternPainter(),
      ),
    );
  }

  Widget _buildCircularGameField(GameState gameState, Size screenSize) {
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final radius =
        screenSize.width * 0.35; // Ridotto per dare più spazio alle zone

    return Positioned.fill(
      child: Stack(
        children: [
          // Cerchio principale del campo
          Center(
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
            ),
          ),

          // Zone personaggi avversario (alto) - equilibrio tra vicino e distante
          _buildOpponentCharacterZones(
              gameState, centerX, centerY - radius * 0.9, screenSize),

          // Zone interazioni avversario (davanti ai personaggi avversario) - equilibrio
          _buildOpponentInteractionZones(
              gameState, centerX, centerY - radius * 0.5, screenSize),

          // Ambientazione (centro) - rimpicciolita
          _buildAmbientazioneZone(gameState, centerX, centerY, screenSize),

          // Zone interazioni giocatore (davanti ai personaggi giocatore) - equilibrio
          _buildPlayerInteractionZones(
              gameState, centerX, centerY + radius * 0.5, screenSize),

          // Zone personaggi giocatore (dietro) - equilibrio tra vicino e distante
          _buildPlayerCharacterZones(
              gameState, centerX, centerY + radius * 0.9, screenSize),
        ],
      ),
    );
  }

  Widget _buildSideElements(GameState gameState, Size screenSize) {
    // Mostra sempre le informazioni del giocatore umano (giocatore1), non del giocatore attivo
    final humanPlayer =
        gameState.giocatore1; // Il giocatore umano è sempre giocatore1

    return Stack(
      children: [
        // Mazzo (basso-destra)
        Positioned(
          right: 20,
          bottom: 200,
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.style, color: Colors.white, size: 30),
            ),
          ),
        ),

        // Energie (spostato a sinistra)
        Positioned(
          left: 20,
          bottom: 110,
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${humanPlayer.energia}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'ENERGIE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animazione energia (+1) - spostata a sinistra
        if (_showEnergyAnimation)
          Positioned(
            left: 20,
            bottom: 110,
            child: AnimatedBuilder(
              animation: _energyAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _energySlideAnimation.value,
                  child: Transform.scale(
                    scale: _energyScaleAnimation.value,
                    child: Opacity(
                      opacity: _energyFadeAnimation.value,
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '+1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

        // Cimitero (basso-destra, sopra il mazzo)
        Positioned(
          right: 20,
          bottom: 290,
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.delete, color: Colors.white, size: 30),
            ),
          ),
        ),

        // === ELEMENTI AI (in alto a sinistra, specchiati) ===

        // Mazzo AI (alto-sinistra)
        Positioned(
          left: 20,
          top: 200,
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF), // Blu per distinguere dall'AI
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.style, color: Colors.white, size: 30),
            ),
          ),
        ),

        // Cimitero AI (alto-sinistra, sotto il mazzo)
        Positioned(
          left: 20,
          top: 290,
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF1E3A8A), // Blu più scuro per il cimitero AI
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.delete, color: Colors.white, size: 30),
            ),
          ),
        ),

        // Energie AI (alto-destra, specchiato rispetto al giocatore)
        Positioned(
          right: 20,
          top: 110,
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3), // Colore diverso per l'AI
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${gameState.giocatore2.energia}', // Energia dell'AI
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'ENERGIE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
    // Mostra sempre le carte del giocatore umano (giocatore1), non del giocatore attivo
    final humanPlayer =
        gameState.giocatore1; // Il giocatore umano è sempre giocatore1

    return Positioned(
      bottom: 5, // Ridotto ulteriormente per massimizzare lo spazio
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Hand cards in fan layout
          SizedBox(
            height: 190, // Aumentato da 170 a 190
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
    const maxAngle = 15.0; // gradi massimi di rotazione
    final angle = (offset / centerIndex) * maxAngle * (3.14159 / 180);

    const cardWidth = 100.0; // Aumentato da 80 a 100
    const cardSpacing = 75.0; // Aumentato da 60 a 75
    final baseX =
        (screenSize.width / 2) - (cardWidth / 2) + (offset * cardSpacing);
    final baseY = 30.0 +
        (offset.abs() * 8); // Aumentato da 20.0 a 30.0 per ancora più spazio

    return Positioned(
      left: baseX,
      top: baseY,
      child: Transform.rotate(
        angle: angle,
        child: Draggable<GameCard>(
          data: card,
          // Disabilita drag durante turno AI o se non è il turno del giocatore umano
          dragAnchorStrategy: (_gameService.isAITurn ||
                  _gameService.gameState?.giocatoreAttivo.name != 'Giocatore')
              ? (draggable, context, position) => Offset.zero
              : childDragAnchorStrategy,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: cardWidth,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getCardTypeColor(card.type),
                    width: 4,
                  ),
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
                  child: Stack(
                    children: [
                      // Immagine della carta
                      Image.asset(
                        'assets/images/cards/${card.name.toLowerCase().replaceAll(' ', '_')}.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        color: canPlay ? null : Colors.grey.withOpacity(0.5),
                        colorBlendMode: canPlay ? null : BlendMode.multiply,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color:
                                _getCardTypeColor(card.type).withOpacity(0.3),
                            child: Center(
                              child: Text(
                                card.name,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),

                      // Indicatore energia (alto-sinistra)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '${card.cost}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Indicatore attacco (alto-destra, solo per personaggi)
                      if (card is PersonaggioCard)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '${(card).forza}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
          childWhenDragging: Container(
            width: cardWidth,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey.withOpacity(0.7),
                  BlendMode.multiply,
                ),
                child: Image.asset(
                  'assets/images/cards/${card.name.toLowerCase().replaceAll(' ', '_')}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Text(
                          card.name,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () => _showCardDetails(card),
            onLongPress: () => _selectCard(card),
            child: Container(
              width: cardWidth,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? Colors.yellow : _getCardTypeColor(card.type),
                  width: isSelected ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Immagine della carta
                    Image.asset(
                      'assets/images/cards/${card.name.toLowerCase().replaceAll(' ', '_')}.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      color: canPlay ? null : Colors.grey.withOpacity(0.5),
                      colorBlendMode: canPlay ? null : BlendMode.multiply,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _getCardTypeColor(card.type).withOpacity(0.3),
                          child: Center(
                            child: Text(
                              card.name,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),

                    // Indicatore energia (alto-sinistra)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          '${card.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Indicatore attacco (alto-destra, solo per personaggi)
                    if (card is PersonaggioCard)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '${(card).forza}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // Metodo per ottenere il colore in base al tipo di carta
  Color _getCardTypeColor(CardType type) {
    switch (type) {
      case CardType.personaggio:
        return Colors.purple.shade600;
      case CardType.ambientazione:
        return Colors.green.shade600;
      case CardType.interazione:
        return Colors.orange.shade600;
    }
  }

  void _showCardDetails(GameCard card) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card image
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/cards/${card.name.toLowerCase().replaceAll(' ', '_')}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              card.name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card name
                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Card stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Energy cost
                    _buildStatChip('⚡ ${card.cost}', Colors.amber),

                    // Attack for character cards
                    if (card is PersonaggioCard)
                      _buildStatChip('⚔️ ${card.forza}', Colors.red),
                  ],
                ),

                const SizedBox(height: 16),

                // Card effect
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.description, // Uso description invece di effetto
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Chiudi'),
                ),
              ],
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
    // I controlli sono disponibili solo quando è il turno del giocatore umano (giocatore1)
    final isHumanTurn =
        gameState.giocatoreAttivo.name == gameState.giocatore1.name;
    final isAITurn = _gameService.isAITurn;

    return Stack(
      children: [
        // Next phase button (centro-sinistra) - disponibile solo durante il turno umano
        Positioned(
          left: 20,
          top: screenSize.height * 0.5,
          child: ElevatedButton(
            onPressed: isHumanTurn && !isAITurn ? _nextPhase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isHumanTurn && !isAITurn ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(isHumanTurn && !isAITurn
                ? _getNextPhaseButtonText()
                : 'Turno AI...'),
          ),
        ),

        // Indicatore turno AI
        if (isAITurn)
          Positioned(
            left: 20,
            top: screenSize.height * 0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI sta pensando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partita Terminata'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Text(
              'Partita Terminata!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: Text(
                motivoVittoria,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _initializeGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Nuova Partita',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Torna al Menu',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metodi per le zone di gioco
  Widget _buildAmbientazioneZone(
      GameState gameState, double x, double y, Size screenSize) {
    final ambientazione = gameState.ambientazioneAttiva;

    return Positioned(
      left: x - 50, // Ridotto da 60 a 50
      top: y - 35, // Ridotto da 45 a 35
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
            width: 100, // Ridotto da 120 a 100
            height: 70, // Ridotto da 90 a 70
            decoration: BoxDecoration(
              color: ambientazione != null
                  ? Colors.blue.withOpacity(0.3)
                  : isHighlighted
                      ? Colors.green.withOpacity(0.4)
                      : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // Ridotto da 12 a 10
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
                                  fontSize: 9,
                                  color: Colors.white), // Ridotto font
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
                          size: 24, // Ridotto da 28 a 24
                        ),
                        const SizedBox(height: 2), // Ridotto da 4 a 2
                        Text(
                          'Ambientazione',
                          style: TextStyle(
                              fontSize: 10, // Ridotto da 11 a 10
                              color: isHighlighted
                                  ? Colors.green.shade600
                                  : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.bold),
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
    // Mostra sempre le zone dell'AI (giocatore2), non dell'avversario del giocatore attivo
    final aiPlayer = gameState.giocatore2; // L'AI è sempre giocatore2

    return Positioned(
      left: x - 120, // Ridotto da 135 a 120 per evitare sovrapposizioni
      top: y -
          35, // Ridotto da 45 a 35 per evitare sovrapposizione con interazioni
      child: Row(
        children: List.generate(3, (index) {
          final personaggio = index < aiPlayer.zonePersonaggi.length
              ? aiPlayer.zonePersonaggi[index]
              : null;

          return Container(
            width: 75, // Ridotto da 80 a 75
            height: 70, // Ridotto da 90 a 70 per evitare sovrapposizioni
            margin:
                const EdgeInsets.symmetric(horizontal: 2.5), // Ridotto margine
            decoration: BoxDecoration(
              color: personaggio != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // Ridotto da 12 a 10
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
                                  fontSize: 8,
                                  color: Colors.white), // Ridotto font
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
                          fontSize: 8, // Ridotto font
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
    // Mostra sempre le zone dell'AI (giocatore2), non dell'avversario del giocatore attivo
    final aiPlayer = gameState.giocatore2; // L'AI è sempre giocatore2

    return Positioned(
      left: x - 80, // Ridotto da 85 a 80
      top: y - 25, // Ridotto da 30 a 25 per evitare sovrapposizioni
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          final interazione = index < aiPlayer.zoneInterazioni.length
              ? aiPlayer.zoneInterazioni[index]
              : null;

          return Container(
            width: 75, // Ridotto da 80 a 75
            height: 45, // Ridotto da 50 a 45 per evitare sovrapposizioni
            margin:
                const EdgeInsets.symmetric(horizontal: 2.5), // Ridotto margine
            decoration: BoxDecoration(
              color: interazione != null
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // Ridotto da 12 a 10
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
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
                                  fontSize: 7,
                                  color: Colors.white), // Ridotto font
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
                          fontSize: 7, // Ridotto font
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

  Widget _buildPlayerCharacterZones(
      GameState gameState, double x, double y, Size screenSize) {
    // Mostra sempre le zone del giocatore umano (giocatore1), non del giocatore attivo
    final humanPlayer =
        gameState.giocatore1; // Il giocatore umano è sempre giocatore1

    return Positioned(
      left: x - 120, // Ridotto da 135 a 120 per coerenza
      top: y - 45, // Ridotto da 50 a 45
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
                  width: 75, // Ridotto da 80 a 75 per coerenza
                  height: 90, // Ridotto da 110 a 90
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2.5), // Ridotto margine
                  decoration: BoxDecoration(
                    color: personaggio != null
                        ? Colors.green.withOpacity(0.3)
                        : isHighlighted
                            ? Colors.purple.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(10), // Ridotto da 12 a 10
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
                                      ? Colors.red
                                          .shade400 // Evidenzia in rosso se può attaccare
                                      : Colors.purple.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.5),
                      width: _selectedAttacker == personaggio ? 3 : 2,
                    ),
                    // Aggiungi un'ombra speciale per i personaggi che possono attaccare
                    boxShadow: personaggio != null &&
                            (_gameService.currentPhase == GamePhase.attacco ||
                                _gameService.currentPhase ==
                                    GamePhase.principale) &&
                            _gameService.puoiAttaccare(index) &&
                            !_gameService.hasAttackedThisTurn(personaggio.id)
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
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
                                            fontSize: 9,
                                            color:
                                                Colors.white), // Ridotto font
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Indicatore di attacco
                            if ((_gameService.currentPhase ==
                                        GamePhase.attacco ||
                                    _gameService.currentPhase ==
                                        GamePhase.principale) &&
                                _gameService.puoiAttaccare(index))
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.gps_fixed,
                                    color: Colors.white,
                                    size: 12, // Ridotto da 16 a 12
                                  ),
                                ),
                              ),
                            // Indicatore "ha già attaccato"
                            if ((_gameService.currentPhase ==
                                        GamePhase.attacco ||
                                    _gameService.currentPhase ==
                                        GamePhase.principale) &&
                                _gameService
                                    .hasAttackedThisTurn(personaggio.id))
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12, // Ridotto da 16 a 12
                                  ),
                                ),
                              ),
                            // Indicatore forza del personaggio
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2), // Ridotto padding
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(
                                      6), // Ridotto da 8 a 6
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                                child: Text(
                                  '${personaggio.forza}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9, // Ridotto da 10 a 9
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                size: 20, // Ridotto da 24 a 20
                              ),
                              const SizedBox(height: 2), // Ridotto da 4 a 2
                              Text(
                                'Personaggio',
                                style: TextStyle(
                                    fontSize: 8, // Ridotto da 9 a 8
                                    color: isHighlighted
                                        ? Colors.purple.shade600
                                        : Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.bold),
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
    // Mostra sempre le zone del giocatore umano (giocatore1), non del giocatore attivo
    final humanPlayer =
        gameState.giocatore1; // Il giocatore umano è sempre giocatore1

    return Positioned(
      left: x - 80, // Ridotto da 85 a 80 per coerenza
      top: y - 30, // Ridotto da 35 a 30
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
                width: 75, // Ridotto da 80 a 75 per coerenza
                height: 50, // Ridotto da 60 a 50
                margin: const EdgeInsets.symmetric(
                    horizontal: 2.5), // Ridotto margine
                decoration: BoxDecoration(
                  color: interazione != null
                      ? Colors.orange.withOpacity(0.3)
                      : isHighlighted
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10), // Ridotto da 12 a 10
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
                              color: Colors.orange.shade300,
                              child: Center(
                                child: Text(
                                  interazione.name,
                                  style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white), // Ridotto font
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
                              size: 16, // Ridotto da 20 a 16
                            ),
                            const SizedBox(height: 1), // Ridotto da 2 a 1
                            Text(
                              'Interazione',
                              style: TextStyle(
                                  fontSize: 7, // Ridotto da 8 a 7
                                  color: isHighlighted
                                      ? Colors.orange.shade600
                                      : Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.bold),
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
    // Mostra sempre le informazioni del giocatore umano (giocatore1), non del giocatore attivo
    final humanPlayer =
        gameState.giocatore1; // Il giocatore umano è sempre giocatore1

    return Positioned(
      bottom: 20, // Spostato nell'angolo in basso
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
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
            const SizedBox(width: 6),
            const Text(
              'VITE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(
                humanPlayer.vite,
                (index) =>
                    const Icon(Icons.favorite, color: Colors.red, size: 16)),
          ],
        ),
      ),
    );
  }

  void _playCardInZone(GameCard card, String zone, int index) {
    if (_gameService.puoiGiocareCarta(card)) {
      _gameService.giocaCarta(card);
      setState(() {
        _selectedCard = null;
      });

      // Mostra messaggio di conferma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${card.name} giocata in zona $zone!'),
          duration: const Duration(seconds: 2),
          backgroundColor: _getCardTypeColor(card.type),
        ),
      );
    }
  }

  void _showTargetSelectionDialog() {
    final gameState = _gameService.gameState!;
    final enemyPersonaggi =
        gameState.giocatore2.zonePersonaggi; // AI è sempre giocatore2

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${_selectedAttacker!.name} - Seleziona il bersaglio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostra i personaggi nemici come bersagli
              for (int i = 0; i < enemyPersonaggi.length; i++)
                if (enemyPersonaggi[i] != null)
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.red),
                    title: Text(enemyPersonaggi[i]!.name),
                    subtitle: Text('Forza: ${enemyPersonaggi[i]!.forza}'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _executeTargetedAttack(i);
                    },
                  ),

              // Attacco diretto SOLO se non ci sono personaggi nemici
              if (!gameState.giocatore2.haPersonaggiInCampo)
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('Attacco diretto'),
                  subtitle: const Text('Togli 1 vita all\'avversario'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _executeDirectAttack();
                  },
                ),

              // Messaggio informativo se ci sono personaggi ma non si può attaccare direttamente
              if (gameState.giocatore2.haPersonaggiInCampo)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Devi attaccare i personaggi nemici prima di poter attaccare direttamente',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedAttacker = null;
                  _isSelectingTarget = false;
                });
              },
              child: const Text('Annulla'),
            ),
          ],
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
      top: 0, // Completamente in alto, tocca il bordo superiore
      left: 0,
      right: 0,
      child: SizedBox(
        height: 140, // Aumentato da 120 a 140 per evitare il taglio
        child: Stack(
          children: [
            for (int i = 0; i < aiPlayer.mano.length; i++)
              _buildAIFanCard(i, aiPlayer.mano.length, screenSize),

            // Nome e vite AI di fianco alla mano
            Positioned(
              top: 50, // Centrato verticalmente rispetto alle carte
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      aiPlayer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(
                        aiPlayer.vite,
                        (index) => const Icon(Icons.favorite,
                            color: Colors.red, size: 20)),
                  ],
                ),
              ),
            ),

            // Menu button a sinistra
            Positioned(
              top: 50, // Centrato verticalmente rispetto alle carte
              left: 20,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
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
    final angle = -(offset / centerIndex) *
        maxAngle *
        (3.14159 / 180); // Invertito per l'AI

    const cardWidth = 70.0; // Più piccolo delle carte del giocatore
    const cardSpacing = 55.0; // Più compatto
    final baseX =
        (screenSize.width / 2) - (cardWidth / 2) + (offset * cardSpacing);
    final baseY = 10.0 +
        (offset.abs() * 5); // Inizia dal bordo superiore con piccolo offset

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
            border: Border.all(
              color: Colors.blue.shade600, // Colore distintivo per l'AI
              width: 2,
            ),
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
            child: Container(
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
            ),
          ),
        ),
      ),
    );
  }
}

// Classe per disegnare il pattern circolare di sfondo
class CircularPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2; // Aumentato spessore

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.7; // Aumentato per far uscire dall'area

    // Disegna cerchi concentrici (più grandi)
    for (int i = 1; i <= 5; i++) {
      // Aumentato numero di cerchi
      canvas.drawCircle(center, maxRadius * i / 3, paint);
    }

    // Disegna linee radiali (più lunghe)
    for (int i = 0; i < 12; i++) {
      // Aumentato numero di linee
      final angle = (i * 30) * (3.14159 / 180); // Ogni 30 gradi
      final start = Offset(
        center.dx + (maxRadius * 0.2) * cos(angle),
        center.dy + (maxRadius * 0.2) * sin(angle),
      );
      final end = Offset(
        center.dx + maxRadius * 1.2 * cos(angle), // Esteso oltre l'area
        center.dy + maxRadius * 1.2 * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
