import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/ai_service.dart';

class FairPage extends StatefulWidget {
  const FairPage({super.key});

  @override
  _FairPageState createState() => _FairPageState();
}

class _FairPageState extends State<FairPage> with TickerProviderStateMixin {
  final AIService _aiService = AIService();

  // Stati del sistema
  StoryState _currentState = StoryState.selection;
  String? _selectedAmbientazione;
  String? _selectedCompagno;
  String _currentStoryText = '';
  final List<String> _userChoices = [];
  final List<String> _storySegments = [];
  int _currentSegment = 1;
  bool _isLoading = false;

  // Variabili per il caricamento iniziale
  bool _isInitialLoading = true;
  bool _areStoryAssetsLoaded = false;
  bool _areUIAssetsLoaded = false;

  // Controller per animazioni
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Controller per input
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _customizationController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _selectionScrollController = ScrollController();

  // Dati delle ambientazioni e compagni
  final Map<String, List<String>> _ambientazioniCompagni = {
    'Monster Allergy': ['Elena Potato', 'Jeremy Joth', 'Bombo'],
    'Sonic': ['Sonic', 'Tails', 'Knuckles'],
    'Avatar the last Airbender': ['Aang', 'Katara', 'Toph'],
    'Clash of Clans': ['Barbarian', 'Archer', 'Wizard'],
    'Spongebob': ['Spongebob', 'Patrick', 'Squidward'],
    'Elle': ['Elle', 'Luna', 'Stella'],
  };

  // Mappatura delle immagini per le ambientazioni
  final Map<String, String> _ambientazioniImmagini = {
    'Monster Allergy': 'assets/images/storie/monster_allergy.png',
    'Sonic': 'assets/images/storie/sonic.png',
    'Avatar the last Airbender': 'assets/images/storie/avatar.jpg',
    'Clash of Clans': 'assets/images/storie/clash.jpg',
    'Spongebob': 'assets/images/storie/spongebob.png',
    'Elle': 'assets/images/storie/elle.png',
  };

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();

    // Carica tutte le risorse iniziali
    _loadAllResources();
  }

  void _loadAllResources() async {
    // Carica tutte le risorse in parallelo
    await Future.wait([
      _preloadStoryAssets(),
      _preloadUIAssets(),
    ]);
  }

  Future<void> _preloadStoryAssets() async {
    try {
      final assetPaths = [
        'assets/images/storie/background.png',
        'assets/images/storie/monster_allergy.png',
        'assets/images/storie/sonic.png',
        'assets/images/storie/avatar.png',
        'assets/images/storie/clash_of_clans.png',
        'assets/images/storie/spongebob.png',
        'assets/images/storie/elle.png',
      ];

      // Precarica tutti gli asset delle storie
      await Future.wait(assetPaths.map((assetPath) async {
        try {
          final image = AssetImage(assetPath);
          await precacheImage(image, context);
          // Tempo maggiore per assicurarsi che sia completamente caricata
          await Future.delayed(const Duration(milliseconds: 300));
          // Verifica aggiuntiva del caricamento per asset locali
          final completer = Completer<void>();
          image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, call) {
              if (!completer.isCompleted) completer.complete();
            }),
          );
          await completer.future
              .timeout(const Duration(seconds: 2), onTimeout: () {});
          print('✅ Precaricato asset storia: $assetPath');
        } catch (e) {
          print('❌ Errore nel caricamento asset $assetPath: $e');
        }
      }));

      setState(() {
        _areStoryAssetsLoaded = true;
      });
      _checkAllResourcesLoaded();
    } catch (e) {
      print('Errore generale nel preload asset storie: $e');
      setState(() {
        _areStoryAssetsLoaded = true;
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
    if (_areStoryAssetsLoaded && _areUIAssetsLoaded) {
      // Buffer più grande per assicurarsi che tutte le immagini siano completamente renderizzate
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _inputController.dispose();
    _customizationController.dispose();
    _scrollController.dispose();
    _selectionScrollController.dispose();
    super.dispose();
  }

  void _selectAmbientazione(String ambientazione) {
    setState(() {
      _selectedAmbientazione = ambientazione;
      _selectedCompagno = null;
    });
    _slideController.forward();

    // Scroll automatico verso la sezione compagno di viaggio
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_selectionScrollController.hasClients) {
        _selectionScrollController.animateTo(
          _selectionScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _selectCompagno(String compagno) {
    setState(() {
      _selectedCompagno = compagno;
    });

    // Scroll automatico verso la sezione aggiungi dettagli
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_selectionScrollController.hasClients) {
        _selectionScrollController.animateTo(
          _selectionScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _startStory() async {
    if (_selectedAmbientazione == null || _selectedCompagno == null) return;

    final user = Provider.of<User>(context, listen: false);
    final customizations = _customizationController.text.trim();

    setState(() {
      _currentState = StoryState.storytelling;
      _isLoading = true;
      _currentSegment = 1;
      _userChoices.clear();
    });

    try {
      final storyText = await _aiService.generateStorySegment(
        ambientazione: _selectedAmbientazione!,
        compagno: _selectedCompagno!,
        userName: user.username,
        previousChoices: _userChoices,
        segmentNumber: _currentSegment,
        customizations: customizations.isNotEmpty ? customizations : null,
      );

      setState(() {
        _currentStoryText = storyText;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _currentStoryText = 'Errore nel generare la storia. Riprova più tardi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _continueStory(String userInput) async {
    if (userInput.trim().isEmpty || _currentSegment >= 6) return;

    final user = Provider.of<User>(context, listen: false);

    setState(() {
      _isLoading = true;
      _userChoices.add(userInput.trim());
      _currentSegment++;
    });

    _inputController.clear();

    try {
      final storyText = await _aiService.generateStorySegment(
        ambientazione: _selectedAmbientazione!,
        compagno: _selectedCompagno!,
        userName: user.username,
        previousChoices: _userChoices,
        segmentNumber: _currentSegment,
        userDecision: userInput.trim(),
      );

      setState(() {
        _currentStoryText = storyText;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _currentStoryText =
            'Errore nel continuare la storia. Riprova più tardi.';
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetStory() {
    setState(() {
      _currentState = StoryState.selection;
      _selectedAmbientazione = null;
      _selectedCompagno = null;
      _currentStoryText = '';
      _userChoices.clear();
      _currentSegment = 1;
      _isLoading = false;
    });
    _slideController.reset();
    _inputController.clear();
    _customizationController.clear();
  }

  Widget _buildAmbientazioneButton(
      String ambientazione, double width, double height) {
    final isSelected = _selectedAmbientazione == ambientazione;
    final imagePath = _ambientazioniImmagini[ambientazione]!;

    return GestureDetector(
      onTap: () => _selectAmbientazione(ambientazione),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: width,
            height: width + 50, // Rende quadrato + spazio per testo
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ambientazione,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NeueHaasDisplay',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialLoading
          ? const Center(
              child: SpinKitChasingDots(
                color: Color(0xFFDBDDE7),
                size: 50.0,
              ),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/storie/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  // Header bianco
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
                              'Tunuè RolePlay',
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
                        if (_currentState == StoryState.storytelling)
                          Positioned(
                            right: 20,
                            bottom: 15,
                            child: GestureDetector(
                              onTap: _resetStory,
                              child: const Icon(
                                Icons.refresh,
                                size: 24,
                                color: Color.fromARGB(255, 54, 55, 58),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Contenuto principale
                  Expanded(
                    child: Stack(
                      children: [
                        // Overlay scuro sopra l'immagine di background
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black.withOpacity(0.1),
                        ),
                        _buildContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case StoryState.selection:
        return _buildSelectionScreen();
      case StoryState.storytelling:
        return _buildStorytellingScreen();
    }
  }

  Widget _buildSelectionScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  controller: _selectionScrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Scegli la tua avventura',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NeueHaasDisplay',
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Crea la tua storia con le tue scelte',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'NeueHaasDisplay',
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(246, 255, 255, 255),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonWidth = (constraints.maxWidth - 12) /
                              2; // 12px spacing tra i bottoni
                          final buttonHeight =
                              buttonWidth; // L'altezza base per l'immagine
                          final ambientazioni =
                              _ambientazioniCompagni.keys.toList();

                          return Column(
                            children: [
                              // Prima riga
                              Row(
                                children: [
                                  _buildAmbientazioneButton(ambientazioni[0],
                                      buttonWidth, buttonWidth),
                                  const SizedBox(width: 12),
                                  _buildAmbientazioneButton(ambientazioni[1],
                                      buttonWidth, buttonWidth),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Seconda riga
                              Row(
                                children: [
                                  _buildAmbientazioneButton(ambientazioni[2],
                                      buttonWidth, buttonWidth),
                                  const SizedBox(width: 12),
                                  _buildAmbientazioneButton(ambientazioni[3],
                                      buttonWidth, buttonWidth),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Terza riga
                              Row(
                                children: [
                                  _buildAmbientazioneButton(ambientazioni[4],
                                      buttonWidth, buttonWidth),
                                  const SizedBox(width: 12),
                                  _buildAmbientazioneButton(ambientazioni[5],
                                      buttonWidth, buttonWidth),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      if (_selectedAmbientazione != null) ...[
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  'Compagno di viaggio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NeueHaasDisplay',
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: _ambientazioniCompagni[
                                        _selectedAmbientazione]!
                                    .map(
                                  (compagno) {
                                    final isSelected =
                                        _selectedCompagno == compagno;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: GestureDetector(
                                        onTap: () => _selectCompagno(compagno),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 16, sigmaY: 16),
                                            child: Container(
                                              width: double.infinity,
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
                                                  color: isSelected
                                                      ? Colors.white
                                                          .withOpacity(0.8)
                                                      : Colors.white
                                                          .withOpacity(0.2),
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  compagno,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        'NeueHaasDisplay',
                                                    color: Colors.white,
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
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_selectedCompagno != null) ...[
                          const Center(
                            child: Text(
                              'Aggiungi dettagli per la tua storia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NeueHaasDisplay',
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _customizationController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'NeueHaasDisplay',
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Es: Vorrei una storia misteriosa con elementi magici...',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'NeueHaasDisplay',
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: _startStory,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.01),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Inizia l\'Avventura!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'NeueHaasDisplay',
                                        color: Colors.white,
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
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorytellingScreen() {
    return Column(
      children: [
        // Story content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story info con glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAmbientazione!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NeueHaasDisplay',
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Compagno: $_selectedCompagno',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'NeueHaasDisplay',
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress bar con glassmorphism
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: LinearProgressIndicator(
                                value: _currentSegment / 6,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF18FB3D)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Parte $_currentSegment di 6',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'NeueHaasDisplay',
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Story text con glassmorphism
                if (_isLoading)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              SpinKitThreeBounce(
                                color: Color(0xFF18FB3D),
                                size: 30,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Generando la storia...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'NeueHaasDisplay',
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
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
                        child: Text(
                          _currentStoryText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NeueHaasDisplay',
                            color: Colors.white,
                            height: 1.6,
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
                  ),

                // User choices history con glassmorphism
                if (_userChoices.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Le tue scelte:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NeueHaasDisplay',
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(_userChoices.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.01),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${index + 1}. ${_userChoices[index]}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'NeueHaasDisplay',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Input section
        if (!_isLoading && _currentSegment < 6 && _currentStoryText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(100),
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
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: 'Qual è la tua prossima mossa',
                            hintStyle: TextStyle(
                                fontFamily: 'NeueHaasDisplay',
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          style: const TextStyle(
                            fontFamily: 'NeueHaasDisplay',
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: null,
                          onSubmitted: _continueStory,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _continueStory(_inputController.text),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
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
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_currentSegment >= 6 && !_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: GestureDetector(
                onTap: _resetStory,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Nuova Avventura!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NeueHaasDisplay',
                          color: Colors.white,
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
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum StoryState {
  selection,
  storytelling,
}
