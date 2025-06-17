import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tunue_card_game_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Variabili per il caricamento
  bool isLoading = true;
  bool _areAssetsLoaded = false;
  bool _areUIAssetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllResources();
  }

  void _loadAllResources() async {
    // Carica tutte le risorse in parallelo
    await Future.wait([
      _preloadGameAssets(),
      _preloadUIAssets(),
    ]);
  }

  Future<void> _preloadGameAssets() async {
    try {
      final assetPaths = [
        'assets/images/game/tunue_heroes.png',
        'assets/images/game/bombo_ai.png',
      ];

      // Precarica tutti gli asset del gioco (PNG/JPG)
      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          // Tempo maggiore per assicurarsi che sia completamente caricata
          await Future.delayed(const Duration(milliseconds: 250));
          // Verifica aggiuntiva del caricamento per asset locali
          final completer = Completer<void>();
          image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, call) {
              if (!completer.isCompleted) completer.complete();
            }),
          );
          await completer.future
              .timeout(const Duration(seconds: 2), onTimeout: () {});
          print('✅ Precaricato asset gioco: $assetPath');
        } catch (e) {
          print('❌ Errore nel caricamento asset $assetPath: $e');
        }
      }));

      setState(() {
        _areAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload asset gioco: $e');
      setState(() {
        _areAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    }
  }

  Future<void> _preloadUIAssets() async {
    try {
      final assetPaths = [
        'assets/images/icons/png/home.png',
        'assets/images/icons/png/collection.png',
        'assets/images/icons/png/game.png',
        'assets/images/icons/png/event.png',
        'assets/images/icons/png/profile.png',
      ];

      // Precarica gli asset dell'interfaccia
      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          // Tempo maggiore per assicurarsi che sia completamente caricata
          await Future.delayed(const Duration(milliseconds: 150));
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

  void _checkAllResourcesLoaded() {
    if (_areAssetsLoaded && _areUIAssetsLoaded) {
      // Buffer più grande per assicurarsi che tutte le immagini siano completamente renderizzate
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  void _startCardGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TunueCardGamePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: SpinKitChasingDots(
                color: Color(0xFFDBDDE7),
                size: 50.0,
              ),
            )
          : Column(
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
                  child: const Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text(
                            'Tunuè Heroes',
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
                    ],
                  ),
                ),
                // Contenuto principale con immagine di background
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image:
                            AssetImage('assets/images/game/tunue_heroes.png'),
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              // VS AI

                              Expanded(
                                child: GestureDetector(
                                  onTap: _startCardGame,
                                  child: Container(
                                    height: 112,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(0, 0),
                                          blurRadius: 16,
                                          spreadRadius: 0,
                                          color: const Color(0xFF666666)
                                              .withOpacity(0.25),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Parte bianca di base
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                        ),
                                        // Parte diagonale
                                        ClipPath(
                                          clipper: DiagonalClipper(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color.fromARGB(
                                                          255, 28, 123, 195)
                                                      .withOpacity(0.3),
                                                  const Color.fromARGB(
                                                          255, 3, 11, 84)
                                                      .withOpacity(0.3),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                        // Contenuto sopra
                                        Positioned.fill(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Transform.translate(
                                                offset: const Offset(4, 4),
                                                child: SvgPicture.asset(
                                                  'assets/images/icons/svg/icona_online.svg',
                                                  width: 56,
                                                  height: 56,
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: const Offset(0, 4),
                                                child: const Text(
                                                  'Online',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                    color: Color(0xFF7B7D8A),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Presto!',
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
                              Expanded(
                                child: GestureDetector(
                                  onTap: _startCardGame,
                                  child: Container(
                                    height: 112,
                                    clipBehavior: Clip.none,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(0, 0),
                                          blurRadius: 16,
                                          spreadRadius: 0,
                                          color: const Color(0xFF666666)
                                              .withOpacity(0.25),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Parte bianca di base
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                        ),
                                        // Parte diagonale
                                        ClipPath(
                                          clipper: DiagonalClipper(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFFFB7F86)
                                                      .withOpacity(0.16),
                                                  const Color(0xFFF30F39)
                                                      .withOpacity(0.16),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                        // Contenuto sopra
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Bombo posizionato in alto
                                            Positioned(
                                              top: -72,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Image.asset(
                                                  'assets/images/game/bombo_caffe.png',
                                                  width: 128,
                                                  height: 128,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Icon(
                                                      Icons.smart_toy,
                                                      size: 40,
                                                      color: Color.fromARGB(
                                                          255, 92, 97, 95),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            // Testi posizionati in basso
                                            const Positioned(
                                              bottom: 10,
                                              left: 0,
                                              right: 0,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'VS AI',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      fontFamily:
                                                          'NeueHaasDisplay',
                                                      color: Color(0xFF7B7D8A),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Sfida Bombo!',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontFamily:
                                                          'NeueHaasDisplay',
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Online
                            ],
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
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(2, size.height * 0);
    path.lineTo(size.width * 2, 0);
    path.lineTo(0, size.height * 0.6);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
