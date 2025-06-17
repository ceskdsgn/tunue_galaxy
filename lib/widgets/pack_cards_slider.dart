import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/pack.dart';
import 'card_widget.dart';

class PackCardsSlider extends StatefulWidget {
  final Pack pack;
  final List<CollectionCard> allCards;

  const PackCardsSlider({
    super.key,
    required this.pack,
    required this.allCards,
  });

  @override
  State<PackCardsSlider> createState() => _PackCardsSliderState();
}

class _PackCardsSliderState extends State<PackCardsSlider>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  late AnimationController _exitController;
  late AnimationController _enterController;

  final ScrollController _listScrollController = ScrollController();
  List<CollectionCard> _packCards = [];
  List<CollectionCard> _previousPackCards = [];
  bool _isTransitioning = false;
  bool _showEnteringCards = false;
  String? _currentPackId;

  @override
  void initState() {
    super.initState();

    // Controller per lo scroll automatico
    _scrollController = AnimationController(
      duration: const Duration(seconds: 100),
      vsync: this,
    );

    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scrollController)
      ..addListener(() {
        if (_listScrollController.hasClients) {
          final maxScroll = _listScrollController.position.maxScrollExtent;
          _listScrollController.jumpTo(maxScroll * _scrollAnimation.value);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isTransitioning) {
          _scrollController.reset();
          _scrollController.forward();
        }
      });

    // Controller per l'animazione di uscita (carte che scendono)
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Controller per l'animazione di entrata (carte che salgono)
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _currentPackId = widget.pack.id;
    _updatePackCards();
    _scrollController.forward();
  }

  @override
  void didUpdateWidget(PackCardsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pack.id != widget.pack.id) {
      _animatePackChange();
    }
  }

  Future<void> _animatePackChange() async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _showEnteringCards = false;
      _previousPackCards = List.from(_packCards);
    });

    // Ferma lo scroll automatico durante la transizione
    _scrollController.stop();

    // Animazione di uscita: carte che scendono
    await _exitController.forward();

    // Aggiorna le carte del nuovo pacchetto
    _updatePackCards();

    // Delay ridotto per una transizione più fluida
    await Future.delayed(const Duration(milliseconds: 200));

    // Mostra le carte in entrata e avvia l'animazione
    setState(() {
      _showEnteringCards = true;
    });

    // Reset dell'animazione di uscita
    _exitController.reset();

    // Animazione di entrata: carte che salgono
    await _enterController.forward();

    setState(() {
      _isTransitioning = false;
      _showEnteringCards = false;
      _previousPackCards.clear();
    });

    // Reset dell'animazione di entrata dopo aver nascosto le carte in entrata
    _enterController.reset();

    // Riprende lo scroll automatico
    _scrollController.forward();
  }

  void _updatePackCards() {
    setState(() {
      _packCards = widget.allCards
          .where((card) => card.packId == widget.pack.id)
          .toList();
      _currentPackId = widget.pack.id;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _exitController.dispose();
    _enterController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_packCards.isEmpty && _previousPackCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: 72,
            child: Stack(
              children: [
                // Carte in uscita (scendono verso il basso)
                if (_isTransitioning &&
                    !_showEnteringCards &&
                    _previousPackCards.isNotEmpty)
                  _buildExitingCards(),

                // Carte in entrata (salgono dal basso)
                if (_showEnteringCards) _buildEnteringCards(),

                // Carte normali (stato finale)
                if (!_isTransitioning) _buildNormalCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitingCards() {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return ListView.builder(
          controller: _listScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: _previousPackCards.length * 2,
          itemBuilder: (context, index) {
            final card = _previousPackCards[index % _previousPackCards.length];
            final cardIndex = index % _previousPackCards.length;

            // Calcola il delay scaglionato in modo dinamico affinché l'ultimo delay non superi 0.8
            final maxIndex = (_previousPackCards.length - 1)
                .clamp(1, _previousPackCards.length);
            final delayUnit =
                0.9 / maxIndex; // 0.9 di range, 0.1 di margine per finale
            final delayFactor = cardIndex * delayUnit;
            final animationProgress =
                (_exitController.value - delayFactor).clamp(0.0, 1.0);

            // Trasformazioni per l'uscita
            final translateY = animationProgress * 150.0; // Scende di 150px
            final opacity = 1.0 - animationProgress;
            final scale = 1.0 - (animationProgress * 0.2);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: 88,
                child: OverflowBox(
                  minHeight: 120,
                  maxHeight: 120,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, 4 + translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: -0.1396,
                          child: CardWidget(
                            card: card,
                            isCompactMode: true,
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnteringCards() {
    if (_packCards.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _enterController,
      builder: (context, child) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _packCards.length * 2,
          itemBuilder: (context, index) {
            final card = _packCards[index % _packCards.length];
            final cardIndex = index % _packCards.length;

            // Animazione di entrata con delay scaglionato dinamico
            final maxIndex =
                (_packCards.length - 1).clamp(1, _packCards.length);
            final delayUnit = 0.9 /
                maxIndex; // 0.9 di range per evitare che il delay superi 1
            final delayFactor = cardIndex * delayUnit;
            final animationProgress =
                (_enterController.value - delayFactor).clamp(0.0, 1.0);

            // Trasformazioni per l'entrata
            final translateY =
                (1.0 - animationProgress) * 120.0; // Sale da 120px sotto
            final opacity = animationProgress;
            final scale = 0.8 + (animationProgress * 0.2); // Scala da 0.8 a 1.0

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: 88,
                child: OverflowBox(
                  minHeight: 120,
                  maxHeight: 120,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, 4 + translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: -0.1396,
                          child: CardWidget(
                            card: card,
                            isCompactMode: true,
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNormalCards() {
    if (_packCards.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _scrollAnimation,
      builder: (context, child) {
        return ListView.builder(
          controller: _listScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: _packCards.length * 2,
          itemBuilder: (context, index) {
            final card = _packCards[index % _packCards.length];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: 88,
                child: OverflowBox(
                  minHeight: 120,
                  maxHeight: 120,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, 4),
                    child: Transform.rotate(
                      angle: -0.1396,
                      child: CardWidget(
                        card: card,
                        isCompactMode: true,
                        onTap: null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCardDialog(CollectionCard card) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CollectionCard.getRarityColor(card.rarity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CollectionCard.getRarityString(card.rarity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    card.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image, size: 80),
                    ),
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
              Text(card.description),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Chiudi'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
