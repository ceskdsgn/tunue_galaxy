// widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/card.dart';
import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    final userModel = Provider.of<User>(context, listen: false);

    if (session != null) {
      try {
        // Ottieni i dati dell'utente dal database
        final userData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .single();

        // Converti i dati delle carte possedute da JSON a oggetti
        List<CollectionCard> ownedCards = [];
        if (userData['owned_cards'] != null &&
            userData['owned_cards'] is List) {
          for (var cardData in userData['owned_cards']) {
            ownedCards.add(CollectionCard.fromJson(cardData));
          }
        }

        // Aggiorna il modello utente
        userModel.update(
          id: session.user.id,
          username: userData['username'],
          email: session.user.email,
          tunueCoins: userData['tunue_coins'],
          ownedCards: ownedCards,
          lastPackOpenTime: DateTime.parse(userData['last_pack_open_time']),
          nextPackTime: DateTime.parse(userData['next_pack_time']),
          isAuthenticated: true,
        );

        // Sincronizza i dati con Supabase
        await _authService.syncUserData(userModel);
      } catch (e) {
        debugPrint('Errore nel recupero dei dati utente: $e');
      }
    } else {
      // Resetta i dati utente se non autenticato
      userModel.reset();
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = Provider.of<User>(context);
    if (!user.isAuthenticated) {
      return const LoginScreen();
    }

    return widget.child;
  }
}
