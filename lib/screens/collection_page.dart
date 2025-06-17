// screens/collection_page.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/card.dart';
import '../models/pack.dart';
import '../models/user.dart';
import '../services/card_service.dart';
import '../services/supabase_service.dart';
import '../widgets/card_widget.dart';
import 'lucky_wheel_page.dart';
import 'missions_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final CardService cardService = CardService();
  List<CollectionCard> allCards = [];
  List<CollectionCard> filteredCards = [];
  List<Pack> packs = [];
  bool isLoading = true;
  late AnimationController _bottomSheetController;

  // Variabili per la carta selezionata
  CollectionCard? _selectedCard;
  bool _isCardExpanded = false;

  // Animazione per la sezione informazioni
  late AnimationController _sectionAnimationController;
  late Animation<Offset> _sectionSlideAnimation;
  late Animation<double> _sectionOpacityAnimation;

  // Controller per il video della carta Zanne della foresta
  VideoPlayerController? _zanneVideoController;

  // Variabili per tracciare il completamento del caricamento
  bool _arePacksLoaded = false;
  bool _areCardsLoaded = false;
  bool _arePackImagesLoaded = false;
  bool _areCardImagesLoaded = false;
  bool _areUIAssetsLoaded = false;

  Set<CardRarity> rarityFilters = {};
  bool showOnlyOwned = false;
  String searchQuery = '';
  bool isCompactMode = false;
  String? selectedPackId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _sectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sectionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sectionAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _sectionOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sectionAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _loadAllResources();
    _initializeZanneVideo();
  }

  void _loadAllResources() async {
    // Carica le risorse in parallelo
    _loadPacks();
    _loadCards();
    _preloadUIAssets();
  }

  void _loadPacks() async {
    try {
      final supabaseService = SupabaseService();
      final loadedPacks = await supabaseService.getAllPacks();

      setState(() {
        // Ordina i pacchetti per mettere prima quelli di Air Power/Avatar
        loadedPacks.sort((a, b) {
          final bool aIsAir = a.name.toLowerCase().contains('air') ||
              a.name.toLowerCase().contains('avatar') ||
              a.name.toLowerCase().contains('airbender');
          final bool bIsAir = b.name.toLowerCase().contains('air') ||
              b.name.toLowerCase().contains('avatar') ||
              b.name.toLowerCase().contains('airbender');

          if (aIsAir && !bIsAir) return -1;
          if (!aIsAir && bIsAir) return 1;
          return 0; // Mantieni l'ordine originale per gli altri
        });

        packs = loadedPacks;
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

  void _loadCards() async {
    try {
      await cardService.loadCards();
      setState(() {
        allCards = cardService.getAllCards();
        filteredCards = List.from(allCards);
        _areCardsLoaded = true;
      });

      // Precarica le immagini delle carte (prime 20 per non sovraccaricare)
      await _preloadCardImages();
    } catch (e) {
      print('Errore nel caricamento delle carte: $e');
      setState(() {
        _areCardsLoaded = true;
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
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
    if (allCards.isEmpty) {
      setState(() {
        _areCardImagesLoaded = true;
      });
      _checkAllResourcesLoaded();
      return;
    }

    try {
      // Precarica le prime 20 carte più visibili per evitare di sovraccaricare
      final cardsToPreload = allCards.take(20).toList();

      // Uso Future.wait per assicurarmi che TUTTE le immagini siano caricate
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
        'assets/images/icons/png/lucky-wheel_icon.png',
        'assets/images/icons/png/missioni_icon.png',
        'assets/images/icons/png/vetrina_icon.png',
        'assets/images/icons/png/mazzi_icon.png',
        'assets/images/logos/avatar_logo.png',
        'assets/images/logos/earth-defence_logo.webp',
        'assets/images/logos/fire-destruction_logo.png',
      ];

      // Uso Future.wait per caricare tutto in parallelo e aspettare la fine
      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          // Doppio controllo per essere sicuri
          await Future.delayed(const Duration(milliseconds: 50));
          print('✅ Precaricato asset UI: $assetPath');
        } catch (e) {
          print('❌ Errore nel caricamento asset $assetPath: $e');
        }
      }));

      setState(() {
        _areUIAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload UI assets: $e');
      setState(() {
        _areUIAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  void _initializeZanneVideo() async {
    try {
      _zanneVideoController =
          VideoPlayerController.asset('assets/videos/immersive_card.mp4');
      await _zanneVideoController!.initialize();
      _zanneVideoController!.setLooping(false);
      _zanneVideoController!.setVolume(1.0);
      print(
          'Video Zanne della foresta inizializzato con successo in collection');
    } catch (e) {
      print(
          'Errore nel caricamento del video Zanne della foresta in collection: $e');
    }
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _sectionAnimationController.dispose();
    _zanneVideoController?.dispose();
    super.dispose();
  }

  void _applyFilters(User user, String? packId) {
    if (allCards.isEmpty) return;

    setState(() {
      filteredCards = allCards.where((card) {
        // Filtro per pacchetto
        if (packId != null && card.packId != packId) {
          return false;
        }

        // Filtro per rarità
        if (rarityFilters.isNotEmpty && !rarityFilters.contains(card.rarity)) {
          return false;
        }

        // Filtro per possesso
        if (showOnlyOwned && !user.ownedCards.any((c) => c.id == card.id)) {
          return false;
        }

        // Filtro per ricerca
        if (searchQuery.isNotEmpty &&
            !card.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  List<CollectionCard> _getCardsByPack(String packId, User user) {
    return allCards.where((card) {
      // Filtro per pacchetto
      if (card.packId != packId) return false;

      // Applica altri filtri
      if (rarityFilters.isNotEmpty && !rarityFilters.contains(card.rarity))
        return false;
      if (showOnlyOwned && !user.ownedCards.any((c) => c.id == card.id))
        return false;
      if (searchQuery.isNotEmpty &&
          !card.name.toLowerCase().contains(searchQuery.toLowerCase()))
        return false;

      return true;
    }).toList()
      ..sort((a, b) {
        // Ordina per rarità: comune, rara, super rara, ultra rara, gold
        const rarityOrder = {
          CardRarity.common: 0,
          CardRarity.rare: 1,
          CardRarity.superRare: 2,
          CardRarity.ultraRare: 3,
          CardRarity.gold: 4,
        };

        int rarityA = rarityOrder[a.rarity] ?? 5;
        int rarityB = rarityOrder[b.rarity] ?? 5;

        if (rarityA != rarityB) {
          return rarityA.compareTo(rarityB);
        }

        // Se hanno la stessa rarità, ordina alfabeticamente per nome
        return a.name.compareTo(b.name);
      });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = Provider.of<User>(context);

    // Applica i filtri quando l'utente cambia
    if (!isLoading &&
        filteredCards.length == allCards.length &&
        user.ownedCards.isNotEmpty) {
      _applyFilters(user, null);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Contenuto principale sempre visibile, ma disabilitato quando c'è una carta espansa
          IgnorePointer(
            ignoring: _isCardExpanded,
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                      fontFamily: 'NeueHaasDisplay',
                    ),
              ),
              child: Column(
                children: [
                  // Header personalizzato
                  Container(
                    width: double.infinity,
                    height: 98,
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
                              'Collezione',
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
                        Positioned(
                          left: 20,
                          bottom: 15,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isCompactMode = !isCompactMode;
                              });
                            },
                            child: Icon(
                              isCompactMode
                                  ? Icons.view_module
                                  : Icons.grid_view,
                              size: 24,
                              color: const Color.fromARGB(255, 54, 55, 58),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 15,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                transitionAnimationController:
                                    _bottomSheetController,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(36),
                                  ),
                                ),
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setModalState) {
                                      return ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(36),
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 16, sigmaY: 16),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.01),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(36),
                                              ),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Header
                                                const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 16),
                                                    child: Text(
                                                      'Cerca e Filtra',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontFamily:
                                                            'NeueHaasDisplay',
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),

                                                // Barra di ricerca
                                                TextField(
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: 'Cerca carte...',
                                                    hintStyle: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontFamily:
                                                          'NeueHaasDisplay',
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 24,
                                                            vertical: 16),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      borderSide: BorderSide(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.2)),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      borderSide: BorderSide(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.2)),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      borderSide:
                                                          const BorderSide(
                                                              color:
                                                                  Colors.white),
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white
                                                        .withOpacity(0.1),
                                                  ),
                                                  onChanged: (value) {
                                                    setModalState(() {
                                                      searchQuery = value;
                                                      _applyFilters(user, null);
                                                    });
                                                  },
                                                ),
                                                const SizedBox(height: 24),

                                                // Titolo filtri
                                                const Text(
                                                  'Rarità',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),

                                                // Filtri rarità
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          showOnlyOwned =
                                                              !showOnlyOwned;
                                                          _applyFilters(
                                                              user, null);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color: showOnlyOwned
                                                                ? Colors.white
                                                                : Colors.white
                                                                    .withOpacity(
                                                                        0.2),
                                                            width: 1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: const Text(
                                                          'Possedute',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    ...CardRarity.values
                                                        .map((rarity) {
                                                      final isSelected =
                                                          rarityFilters
                                                              .contains(rarity);
                                                      return GestureDetector(
                                                        onTap: () {
                                                          setModalState(() {
                                                            if (isSelected) {
                                                              rarityFilters
                                                                  .remove(
                                                                      rarity);
                                                            } else {
                                                              rarityFilters
                                                                  .add(rarity);
                                                            }
                                                            _applyFilters(
                                                                user, null);
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? CollectionCard
                                                                      .getRarityColor(
                                                                          rarity)
                                                                  : Colors.white
                                                                      .withOpacity(
                                                                          0.2),
                                                              width: 1,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Text(
                                                            CollectionCard
                                                                .getRarityString(
                                                                    rarity),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                                const SizedBox(height: 24),

                                                // Titolo pacchetti
                                                const Text(
                                                  'Pacchetti',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),

                                                // Filtri pacchetti
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ...packs.map((pack) {
                                                      final isSelected =
                                                          selectedPackId ==
                                                              pack.id;
                                                      return Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      4),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              setModalState(() {
                                                                selectedPackId =
                                                                    isSelected
                                                                        ? null
                                                                        : pack
                                                                            .id;
                                                                _applyFilters(
                                                                    user, null);
                                                              });
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border:
                                                                    Border.all(
                                                                  color: isSelected
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.2),
                                                                  width: 1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child: pack.name
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          'air power')
                                                                  ? Image.asset(
                                                                      'assets/images/logos/avatar_logo.png',
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    )
                                                                  : pack.name
                                                                          .toLowerCase()
                                                                          .contains(
                                                                              'earth defence')
                                                                      ? Image
                                                                          .asset(
                                                                          'assets/images/logos/earth-defence_logo.webp',
                                                                          fit: BoxFit
                                                                              .contain,
                                                                        )
                                                                      : pack.name
                                                                              .toLowerCase()
                                                                              .contains('fire destruction')
                                                                          ? Image.asset(
                                                                              'assets/images/logos/fire-destruction_logo.png',
                                                                              fit: BoxFit.contain,
                                                                            )
                                                                          : Text(
                                                                              pack.name,
                                                                              style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 14,
                                                                                fontWeight: FontWeight.w400,
                                                                              ),
                                                                            ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: const Icon(
                              Icons.search,
                              size: 24,
                              color: Color.fromARGB(255, 54, 55, 58),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenuto - pacchetti uno sotto l'altro
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: SpinKitChasingDots(
                              color: Color(0xFFDBDDE7),
                              size: 50.0,
                            ),
                          )
                        : packs.isEmpty
                            ? const Center(
                                child: Text('Nessun pacchetto disponibile'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                    top: 16, left: 8, right: 8, bottom: 8),
                                itemCount: packs.length +
                                    1, // +1 per la sezione Vetrina e Mazzi
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    // Sezione Vetrina e Mazzi
                                    return _buildVetrinaMazziSection();
                                  }
                                  final pack = packs[index - 1];
                                  final packCards =
                                      _getCardsByPack(pack.id, user);
                                  return _buildPackSection(
                                      pack, packCards, user);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay per la carta espansa
          if (_isCardExpanded && _selectedCard != null)
            Material(
              elevation: 1000, // Elevation molto alta per stare sopra tutto
              color: Colors.transparent,
              child: _buildExpandedCardOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedCardOverlay() {
    return Stack(
      children: [
        // Sfondo scuro con blur
        Positioned.fill(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: GestureDetector(
                onTap: _closeExpandedCard,
                child: Container(
                  color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),

        // Layout scrollabile completo
        if (_selectedCard != null)
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pulsante di chiusura allineato a sinistra (senza background)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: IconButton(
                            onPressed: _closeExpandedCard,
                            icon: SvgPicture.asset(
                              'assets/images/icons/svg/arrow_icon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const Spacer(), // Spinge l'icona a sinistra
                      ],
                    ),

                    // Carta interattiva (non toccabile per chiudere)
                    GestureDetector(
                      onTap:
                          () {}, // Previene la chiusura quando si tocca la carta
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Interactive3DCard(
                          card: _selectedCard!,
                          isOwned: true,
                          width: MediaQuery.of(context).size.width * 0.7,
                          enableInteraction: true,
                          isCompactMode: false,
                          isCollection: true,
                          videoController: _selectedCard!.name
                                  .toLowerCase()
                                  .contains('zanne della foresta')
                              ? _zanneVideoController
                              : null,
                          shouldPlayVideo: _selectedCard!.name
                              .toLowerCase()
                              .contains('zanne della foresta'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pulsante Immersive per "Zanne della foresta" - posizionato sotto la carta
                    if (_selectedCard!.name
                        .toLowerCase()
                        .contains('zanne della foresta'))
                      GestureDetector(
                        onTap: () {
                          if (_zanneVideoController != null &&
                              _zanneVideoController!.value.isInitialized) {
                            _zanneVideoController!.seekTo(Duration.zero);
                            _zanneVideoController!.play();
                            print(
                                '▶️ Video Zanne della foresta avviato da collection');
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                25), // Completamente rotondo
                            border: Border.all(
                              color: _selectedCard!.rarity == CardRarity.common
                                  ? Colors.white.withOpacity(0.3)
                                  : CollectionCard.getRarityColor(
                                          _selectedCard!.rarity)
                                      .withOpacity(0.6),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Immergiti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NeueHaasDisplay',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Sezione informazioni animata dal basso
                    AnimatedBuilder(
                      animation: _sectionAnimationController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _sectionSlideAnimation,
                          child: FadeTransition(
                            opacity: _sectionOpacityAnimation,
                            child: GestureDetector(
                              onTap:
                                  () {}, // Previene la chiusura quando si tocca la sezione
                              child: SizedBox(
                                width:
                                    double.infinity, // 100% larghezza garantita
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border(
                                      top: BorderSide(
                                        color: _selectedCard!.rarity ==
                                                CardRarity.common
                                            ? Colors.white.withOpacity(0.2)
                                            : CollectionCard.getRarityColor(
                                                _selectedCard!.rarity),
                                        width: 1,
                                      ),
                                      left: BorderSide(
                                        color: _selectedCard!.rarity ==
                                                CardRarity.common
                                            ? Colors.white.withOpacity(0.2)
                                            : CollectionCard.getRarityColor(
                                                _selectedCard!.rarity),
                                        width: 1,
                                      ),
                                      right: BorderSide(
                                        color: _selectedCard!.rarity ==
                                                CardRarity.common
                                            ? Colors.white.withOpacity(0.2)
                                            : CollectionCard.getRarityColor(
                                                _selectedCard!.rarity),
                                        width: 1,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Nome della carta
                                      Text(
                                        _selectedCard!.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'NeueHaasDisplay',
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Link "Compra" se presente
                                      if (_selectedCard!.link.isNotEmpty)
                                        GestureDetector(
                                          onTap: () async {
                                            final Uri url =
                                                Uri.parse(_selectedCard!.link);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            child: SizedBox(
                                              height: 60,
                                              child: Stack(
                                                children: [
                                                  // Container con blur e background
                                                  Positioned.fill(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      child: BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 8,
                                                                sigmaY: 8),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.01),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.2),
                                                              width: 1,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.2),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                        0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Immagine di Bombo sopra il blur
                                                  Positioned(
                                                    left: -60,
                                                    top: -20,
                                                    child: Image.asset(
                                                      'assets/images/game/bombo_ai.png',
                                                      width: 170,
                                                      height: 170,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container();
                                                      },
                                                    ),
                                                  ),
                                                  // Testo centrato
                                                  Positioned.fill(
                                                    child: Center(
                                                      child: Text(
                                                        'Compra ${_selectedCard!.name}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily:
                                                              'NeueHaasDisplay',
                                                          shadows: [
                                                            Shadow(
                                                              offset:
                                                                  Offset(1, 1),
                                                              blurRadius: 3,
                                                              color: Colors
                                                                  .black54,
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

                                      const SizedBox(height: 20),

                                      // Effetto
                                      if (_selectedCard!.effect.isNotEmpty) ...[
                                        const Text(
                                          'Effetto',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NeueHaasDisplay',
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 8, sigmaY: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                      vertical: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.01),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _selectedCard!.effect,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontFamily: 'NeueHaasDisplay',
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Storia
                                      if (_selectedCard!.story.isNotEmpty) ...[
                                        const Text(
                                          'Storia',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NeueHaasDisplay',
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 8, sigmaY: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                      vertical: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.01),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _selectedCard!.story,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontFamily: 'NeueHaasDisplay',
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
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
      ],
    );
  }

  Widget _buildVetrinaMazziSection() {
    return Padding(
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
                              const Color(0xFF7FFBFB).withOpacity(0.16),
                              const Color(0xFF0faff3).withOpacity(0.16),
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
                              'assets/images/icons/png/vetrina_icon.png',
                              width: 72,
                              height: 72,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.motion_photos_on,
                                  size: 40,
                                  color: Colors.amber,
                                );
                              },
                            ),
                            const Text(
                              'Vetrina',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'NeueHaasDisplay',
                                color: Color(0xFF7B7D8A),
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
          // Missioni
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
                              const Color(0xFFFF0040).withOpacity(0.16),
                              const Color(0xFFea00ff).withOpacity(0.16),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    // Contenuto sopra
                    Positioned.fill(
                      child: SizedBox(
                        height: 130,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              top: -16,
                              child: Image.asset(
                                'assets/images/icons/png/mazzi_icon.png',
                                width: 128,
                                height: 128,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.motion_photos_on,
                                    size: 40,
                                    color: Colors.amber,
                                  );
                                },
                              ),
                            ),
                            const Positioned(
                              top: 84,
                              child: Text(
                                'Mazzi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  fontFamily: 'NeueHaasDisplay',
                                  color: Color(0xFF7B7D8A),
                                ),
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
    );
  }

  Widget _buildPackSection(Pack pack, List<CollectionCard> cards, User user) {
    // Calcola progresso per questo pacchetto
    final allCardsInPack =
        allCards.where((card) => card.packId == pack.id).toList();
    final ownedCardsInPack = allCardsInPack
        .where((card) =>
            user.ownedCards.any((ownedCard) => ownedCard.id == card.id))
        .toList();
    final packProgress = allCardsInPack.isEmpty
        ? 0.0
        : ownedCardsInPack.length / allCardsInPack.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo del pacchetto
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: pack.name.toLowerCase().contains('air power')
              ? Center(
                  child: Image.asset(
                    'assets/images/logos/avatar_logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                )
              : pack.name.toLowerCase().contains('earth defence')
                  ? Center(
                      child: Image.asset(
                        'assets/images/logos/earth-defence_logo.webp',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    )
                  : pack.name.toLowerCase().contains('fire destruction')
                      ? Center(
                          child: Image.asset(
                            'assets/images/logos/avatar_logo.png',
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Text(
                          pack.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NeueHaasDisplay',
                            color: Color.fromARGB(255, 54, 55, 58),
                          ),
                        ),
        ),

        // Progresso del pacchetto e contatori per rarità
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Contatori per rarità
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRarityCounter(
                    'C',
                    CardRarity.common,
                    _getOwnedCardsByRarity(pack.id, CardRarity.common, user),
                    _getTotalCardsByRarity(pack.id, CardRarity.common),
                  ),
                  const SizedBox(width: 8),
                  _buildRarityCounter(
                    'R',
                    CardRarity.rare,
                    _getOwnedCardsByRarity(pack.id, CardRarity.rare, user),
                    _getTotalCardsByRarity(pack.id, CardRarity.rare),
                  ),
                  const SizedBox(width: 8),
                  _buildRarityCounter(
                    'SR',
                    CardRarity.superRare,
                    _getOwnedCardsByRarity(pack.id, CardRarity.superRare, user),
                    _getTotalCardsByRarity(pack.id, CardRarity.superRare),
                  ),
                  const SizedBox(width: 8),
                  _buildRarityCounter(
                    'UR',
                    CardRarity.ultraRare,
                    _getOwnedCardsByRarity(pack.id, CardRarity.ultraRare, user),
                    _getTotalCardsByRarity(pack.id, CardRarity.ultraRare),
                  ),
                  const SizedBox(width: 8),
                  _buildRarityCounter(
                    'G',
                    CardRarity.gold,
                    _getOwnedCardsByRarity(pack.id, CardRarity.gold, user),
                    _getTotalCardsByRarity(pack.id, CardRarity.gold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Griglia delle carte del pacchetto
        if (cards.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Center(
              child: Text(
                'Nessuna carta trovata per questo pacchetto',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'NeueHaasDisplay',
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompactMode ? 3 : 4,
                childAspectRatio: 0.67,
                crossAxisSpacing: isCompactMode ? 1 : 2,
                mainAxisSpacing: isCompactMode ? 1 : 2,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final ownedCard = user.ownedCards.firstWhere(
                  (c) => c.id == card.id,
                  orElse: () => card,
                );
                final isOwned = user.ownedCards.any((c) => c.id == card.id);

                return _buildCardWidget(card, ownedCard, isOwned, index, user);
              },
            ),
          ),

        // Spazio tra i pacchetti
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCardWidget(CollectionCard card, CollectionCard ownedCard,
      bool isOwned, int index, User user) {
    // Nascondi le carte non possedute solo quando è espansa "Zanne della foresta"
    if (!isOwned &&
        _isCardExpanded &&
        _selectedCard != null &&
        _selectedCard!.name.toLowerCase().contains('zanne della foresta')) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        return CardWidget(
          card: ownedCard,
          greyOut: !isOwned,
          isCompactMode: isCompactMode,
          isCollection: true,
          onTap: () {
            if (isOwned && !_isCardExpanded) {
              _expandCard(ownedCard);
            }
          },
        );
      },
    );
  }

  void _expandCard(CollectionCard card) {
    setState(() {
      _selectedCard = card;
      _isCardExpanded = true;
    });

    // Avvia l'animazione della sezione dopo un piccolo delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _sectionAnimationController.forward();
      }
    });
  }

  void _closeExpandedCard() {
    _sectionAnimationController.reverse().then((_) {
      setState(() {
        _selectedCard = null;
        _isCardExpanded = false;
      });
    });
  }

  Color _getOwnedCardColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return const Color(0xFF9E9E9E); // Grigio più scuro
      case CardRarity.rare:
        return const Color(
            0xFF128A2A); // Verde più scuro ma leggermente più chiaro
      default:
        return CollectionCard.getRarityColor(
            rarity); // Altri colori rimangono uguali
    }
  }

  Widget _buildRarityCounter(
      String label, CardRarity rarity, int owned, int total) {
    return Stack(
      children: [
        // Container di base senza bordo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$owned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NeueHaasDisplay',
                    color: _getOwnedCardColor(rarity),
                  ),
                ),
                const TextSpan(
                  text: ' /',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'NeueHaasDisplay',
                    color: Color(0xFFACB0B3),
                  ),
                ),
                TextSpan(
                  text: '$total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'NeueHaasDisplay',
                    color: Color(0xFFACB0B3),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Accent colorato - bordo curvato senza chiusura
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(24, 12),
            painter: CurvedBorderPainter(
              color: CollectionCard.getRarityColor(rarity),
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  int _getOwnedCardsByRarity(String packId, CardRarity rarity, User user) {
    return allCards.where((card) {
      return card.packId == packId &&
          card.rarity == rarity &&
          user.ownedCards.any((ownedCard) => ownedCard.id == card.id);
    }).length;
  }

  int _getTotalCardsByRarity(String packId, CardRarity rarity) {
    return allCards.where((card) {
      return card.packId == packId && card.rarity == rarity;
    }).length;
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

  void _checkAllResourcesLoaded() {
    if (_arePacksLoaded &&
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
}

class CurvedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CurvedBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Inizia dal bottom left
    path.moveTo(0, size.height);
    // Linea orizzontale verso destra
    path.lineTo(size.width - 12, size.height);
    // Curva verso l'alto
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - 12,
    );
    // Linea verticale verso l'alto
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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

// Widget per la carta 3D interattiva
class Interactive3DCard extends StatefulWidget {
  final CollectionCard card;
  final bool isOwned;
  final double width;
  final bool enableInteraction;
  final bool isCompactMode;
  final bool isCollection;
  final VideoPlayerController? videoController;
  final bool shouldPlayVideo;

  const Interactive3DCard({
    super.key,
    required this.card,
    required this.isOwned,
    required this.width,
    this.enableInteraction = true,
    this.isCompactMode = false,
    this.isCollection = false,
    this.videoController,
    this.shouldPlayVideo = false,
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _resetController;

  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _scale = 1.0;

  // Valori per l'animazione di reset
  late Animation<double> _resetRotationX;
  late Animation<double> _resetRotationY;
  late Animation<double> _resetScale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
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

    final center = Offset(size.width / 2, size.height / 2);
    final offset = localPosition - center;

    // Calcola la rotazione basata sulla posizione del tocco/mouse
    const maxRotation = 0.3; // Massimo 17 gradi circa
    final rotationY = (offset.dx / (size.width / 2)) * maxRotation;
    final rotationX = -(offset.dy / (size.height / 2)) * maxRotation;

    setState(() {
      _rotationX = rotationX.clamp(-maxRotation, maxRotation);
      _rotationY = rotationY.clamp(-maxRotation, maxRotation);
      _scale = 1.05; // Leggero zoom durante l'interazione
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
                        color: widget.isOwned
                            ? CollectionCard.getRarityColor(widget.card.rarity)
                                .withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(
                          _rotationY * 10, // Ombra che segue la rotazione
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
                        // Immagine della carta o video
                        _buildCardMedia(widget.card),

                        // Effetto grigio se non posseduta
                        if (!widget.isOwned)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.lock,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Effetto olografico solo se posseduta e interazione abilitata
                        if (widget.isOwned &&
                            widget.enableInteraction &&
                            widget.card.rarity != CardRarity.common)
                          _buildHolographicOverlay(),

                        // Riflesso basato sulla rotazione solo se interazione abilitata
                        if (widget.enableInteraction) _buildReflectionOverlay(),

                        // Overlay con quantità (solo se maggiore di 1 e in modalità griglia)
                        if (widget.isOwned &&
                            widget.card.quantity > 1 &&
                            !widget.isCompactMode &&
                            !widget.enableInteraction)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                                child: Container(
                                  width: 32,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  decoration: ShapeDecoration(
                                    gradient: LinearGradient(
                                      begin: const Alignment(-0.00, 0.00),
                                      end: const Alignment(1.00, 1.01),
                                      colors: [
                                        Colors.white.withOpacity(0.7),
                                        Colors.white.withOpacity(0.4),
                                        Colors.white.withOpacity(0)
                                      ],
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color(0x28000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 0),
                                        spreadRadius: 0,
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${widget.card.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.black,
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

  Widget _buildHolographicOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Colors.white.withOpacity(0.1),
              CollectionCard.getRarityColor(widget.card.rarity)
                  .withOpacity(0.2),
              Colors.transparent,
              Colors.white.withOpacity(0.05),
            ],
            transform: GradientRotation(_rotationY + _rotationX),
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

  Widget _buildCardMedia(CollectionCard card) {
    // Se c'è un video controller e dovrebbe riprodurre il video, mostra il video
    if (widget.videoController != null &&
        widget.shouldPlayVideo &&
        widget.videoController!.value.isInitialized) {
      return SizedBox.expand(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: widget.videoController!.value.size.width,
              height: widget.videoController!.value.size.height,
              child: VideoPlayer(widget.videoController!),
            ),
          ),
        ),
      );
    }

    // Altrimenti mostra l'immagine normale
    return _buildCardImage(card);
  }

  Widget _buildCardImage(CollectionCard card) {
    // Se l'URL inizia con http, usa Image.network
    if (card.imageUrl.startsWith('http')) {
      return SizedBox.expand(
        child: Image.network(
          card.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(card);
          },
        ),
      );
    } else {
      // Prova prima con il percorso diretto
      return SizedBox.expand(
        child: Image.asset(
          card.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Se fallisce, prova con il formato del gioco delle carte
            return Image.asset(
              card.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error2, stackTrace2) {
                return _buildFallbackImage(card);
              },
            );
          },
        ),
      );
    }
  }

  Widget _buildFallbackImage(CollectionCard card) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: CollectionCard.getRarityColor(card.rarity).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 60,
                color: CollectionCard.getRarityColor(card.rarity),
              ),
              const SizedBox(height: 8),
              Text(
                card.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CollectionCard.getRarityColor(card.rarity),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
