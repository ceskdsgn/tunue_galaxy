// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'constants/supabase_config.dart';
import 'models/card.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/collection_page.dart';
import 'screens/fair_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => User(username: ''),
      child: const CollectionApp(),
    ),
  );
}

class CollectionApp extends StatefulWidget {
  const CollectionApp({super.key});

  @override
  _CollectionAppState createState() => _CollectionAppState();
}

class _CollectionAppState extends State<CollectionApp> {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Ascolta i cambiamenti di autenticazione
    _authService.authStateChanges.listen((AuthState authState) async {
      final currentUser = authState.session?.user;
      final userModel = Provider.of<User>(context, listen: false);

      if (currentUser != null) {
        try {
          // Ottieni i dati dell'utente dal database
          final userData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', currentUser.id)
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
            id: currentUser.id,
            username: userData['username'] ?? 'Ospite',
            email: currentUser.email,
            tunueCoins: userData['tunue_coins'],
            ownedCards: ownedCards,
            lastPackOpenTime: DateTime.parse(userData['last_pack_open_time']),
            nextPackTime: DateTime.parse(userData['next_pack_time']),
            isAuthenticated: true,
          );
        } catch (e) {
          debugPrint('Errore nel recupero dei dati utente: $e');
          // In caso di errore, impostiamo almeno un username di default
          userModel.update(
            username: 'Ospite',
            isAuthenticated: false,
          );
        }
      } else {
        // Resetta i dati utente se non autenticato
        userModel.reset();
      }

      if (!_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunuè Collection',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: !_isInitialized ? const SplashScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icona dell'app
            Icon(
              Icons.card_giftcard,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Tunuè Collection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    // Controlla se l'utente è autenticato
    if (!user.isAuthenticated) {
      return const LoginScreen();
    }

    final List<Widget> pages = [
      const HomePage(),
      const CollectionPage(),
      const FairPage(),
      const ProfileScreen(),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections),
              label: 'Collezione',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Eventi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profilo',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          onTap: onItemTapped,
        ),
      ),
    );
  }
}
