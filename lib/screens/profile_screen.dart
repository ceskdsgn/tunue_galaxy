// screens/profile_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

// Widget principale della schermata del profilo
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// Stato della schermata del profilo che gestisce la logica e l'interfaccia utente
class _ProfileScreenState extends State<ProfileScreen> {
  // Chiave per il form di modifica del profilo
  final _formKey = GlobalKey<FormState>();
  // Controller per il campo del nome utente
  final _usernameController = TextEditingController();
  // Flag per controllare se l'utente sta modificando il profilo
  bool _isEditing = false;
  // Flag per controllare se è in corso il salvataggio
  bool _isSaving = false;
  // Servizio di autenticazione per gestire le operazioni con il backend
  final AuthService _authService = AuthService();

  // Controller per il video di background
  VideoPlayerController? _videoController;
  bool _isVideoLoaded = false;

  @override
  void initState() {
    super.initState();
    // Inizializza il controller con il nome utente attuale
    final user = Provider.of<User>(context, listen: false);
    _usernameController.text = user.username;

    // Inizializza il video di background
    _initializeVideo();
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
    } catch (e) {
      print('Errore nel caricamento del video: $e');
      setState(() {
        _isVideoLoaded = true; // Considera caricato anche in caso di errore
      });
    }
  }

  @override
  void dispose() {
    // Pulisce le risorse quando il widget viene distrutto
    _usernameController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Funzione per attivare/disattivare la modalità di modifica
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Se si annulla la modifica, ripristina il valore originale
        final user = Provider.of<User>(context, listen: false);
        _usernameController.text = user.username;
      }
    });
  }

  // Funzione per salvare le modifiche al profilo
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Aggiorna il nome utente nel modello
        final user = Provider.of<User>(context, listen: false);
        user.update(username: _usernameController.text);

        // Sincronizza i dati con Supabase
        await _authService.syncUserData(user);

        setState(() {
          _isSaving = false;
          _isEditing = false;
        });

        // Mostra un messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profilo aggiornato con successo!',
              style: TextStyle(
                fontFamily: 'NeueHaasDisplay',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Color(0xFF18FB3D),
          ),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        // Mostra un messaggio di errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore durante il salvataggio: $e',
              style: const TextStyle(
                fontFamily: 'NeueHaasDisplay',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Funzione per gestire il logout
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Conferma logout',
          style: TextStyle(
            fontFamily: 'NeueHaasDisplay',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 54, 55, 58),
          ),
        ),
        content: const Text(
          'Sei sicuro di voler effettuare il logout?',
          style: TextStyle(
            fontFamily: 'NeueHaasDisplay',
            color: Color.fromARGB(255, 54, 55, 58),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ANNULLA',
              style: TextStyle(
                fontFamily: 'NeueHaasDisplay',
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Chiudi il dialogo

              // Esegui il logout
              await _authService.signOut();

              // Resetta i dati utente
              final user = Provider.of<User>(context, listen: false);
              user.reset();

              // Mostra messaggio di conferma
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Logout effettuato con successo',
                    style: TextStyle(
                      fontFamily: 'NeueHaasDisplay',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Color(0xFF18FB3D),
                ),
              );
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(
                fontFamily: 'NeueHaasDisplay',
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    // Se l'utente non è autenticato, mostra la schermata di login
    if (!user.isAuthenticated) {
      return const LoginScreen();
    }

    // Costruisce l'interfaccia principale della schermata del profilo con design glassmorphism
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Video di background
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              Positioned.fill(
                child: Transform.rotate(
                  angle: 1.5708, // 90 gradi in radianti
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
              ),
            // Fallback per quando il video non è caricato
            if (_videoController == null ||
                !_videoController!.value.isInitialized)
              Positioned.fill(
                child: Transform.rotate(
                  angle: 1.5708, // 90 gradi in radianti
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image:
                            AssetImage('assets/images/storie/background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                // Header bianco personalizzato
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
                      // Icona di modifica a sinistra
                      Positioned(
                        left: 20,
                        bottom: 15,
                        child: GestureDetector(
                          onTap: _isEditing ? _saveProfile : _toggleEdit,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              size: 24,
                              color: const Color.fromARGB(255, 54, 55, 58),
                            ),
                          ),
                        ),
                      ),
                      // Titolo al centro
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text(
                            'Il mio profilo',
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
                      // Icona di logout a destra
                      Positioned(
                        right: 20,
                        bottom: 15,
                        child: GestureDetector(
                          onTap: _logout,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.logout_rounded,
                              size: 24,
                              color: Color.fromARGB(255, 54, 55, 58),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenuto principale con glassmorphism
                Expanded(
                  child: Stack(
                    children: [
                      // Overlay scuro sopra il video
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withOpacity(0.1),
                      ),
                      // Contenuto scrollable
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Container principale con glassmorphism
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // Sezione Avatar con immagine profile.jpg
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 2,
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
                                            child: ClipOval(
                                              child: Image.asset(
                                                'assets/images/profile.jpg',
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  // Fallback alla lettera iniziale se l'immagine non carica
                                                  return Center(
                                                    child: Text(
                                                      user.username.isNotEmpty
                                                          ? user.username
                                                              .substring(0, 1)
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily:
                                                            'NeueHaasDisplay',
                                                        color: Colors.white,
                                                        shadows: [
                                                          Shadow(
                                                            offset:
                                                                Offset(1, 1),
                                                            blurRadius: 3,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Sezione Nome Utente
                                          if (_isEditing)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 8, sigmaY: 8),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        _usernameController,
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'NeueHaasDisplay',
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: 'Nome utente',
                                                      labelStyle: TextStyle(
                                                        fontFamily:
                                                            'NeueHaasDisplay',
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              16),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Inserisci un nome utente';
                                                      }
                                                      if (value.length < 3) {
                                                        return 'Il nome utente deve avere almeno 3 caratteri';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Text(
                                              user.username,
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

                                          // Sezione Email
                                          Text(
                                            user.email ??
                                                'Email non disponibile',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'NeueHaasDisplay',
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              shadows: const [
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
                                const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }
}
