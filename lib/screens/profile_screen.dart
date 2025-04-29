// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
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

  @override
  void initState() {
    super.initState();
    // Inizializza il controller con il nome utente attuale
    final user = Provider.of<User>(context, listen: false);
    _usernameController.text = user.username;
  }

  @override
  void dispose() {
    // Pulisce le risorse quando il widget viene distrutto
    _usernameController.dispose();
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
            content: Text('Profilo aggiornato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        // Mostra un messaggio di errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
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
        title: const Text('Conferma logout'),
        content: const Text('Sei sicuro di voler effettuare il logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA'),
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
                  content: Text('Logout effettuato con successo'),
                ),
              );
            },
            child: const Text('LOGOUT'),
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

    // Costruisce l'interfaccia principale della schermata del profilo
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il mio profilo'),
        actions: [
          // Pulsante modifica/salva
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveProfile : _toggleEdit,
          ),
          // Pulsante logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sezione Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sezione Nome Utente
                if (_isEditing)
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nome utente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci un nome utente';
                      }
                      if (value.length < 3) {
                        return 'Il nome utente deve avere almeno 3 caratteri';
                      }
                      return null;
                    },
                  )
                else
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),

                // Sezione Email
                Text(
                  user.email ?? 'Email non disponibile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Sezione Statistiche
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Le tue statistiche',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Riga delle statistiche
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Statistica Tunuè Coins
                          _buildStatItem(
                            icon: Icons.monetization_on,
                            color: Colors.amber,
                            title: user.tunueCoins.toString(),
                            subtitle: 'Tunuè Coins',
                          ),
                          // Statistica Carte collezionate
                          _buildStatItem(
                            icon: Icons.style,
                            color: Colors.blue,
                            title: user.ownedCards.length.toString(),
                            subtitle: 'Carte',
                          ),
                          // Statistica Carte rare
                          _buildStatItem(
                            icon: Icons.star,
                            color: Colors.purple,
                            title: user.ownedCards
                                .where(
                                    (card) => card.rarity != CardRarity.common)
                                .length
                                .toString(),
                            subtitle: 'Rare+',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget per costruire un elemento di statistica
  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
