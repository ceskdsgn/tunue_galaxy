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
import 'screens/game_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'widgets/custom_nav_icon.dart';

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
      theme: AppTheme.lightTheme.copyWith(
        textTheme: AppTheme.lightTheme.textTheme.apply(
          fontFamily: 'NeueHaasDisplay',
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: AppTheme.darkTheme.textTheme.apply(
          fontFamily: 'NeueHaasDisplay',
        ),
      ),
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
      const GamePage(),
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
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(31, 82, 82, 82),
                  offset: Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              top: 16,
              left: 0,
              right: 0,
              bottom: 48,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => onItemTapped(0),
                  child: CustomNavIcon(
                    iconPath: 'assets/images/icons/png/home.png',
                    selectedIconPath:
                        'assets/images/icons/png/home_selected.png',
                    isSelected: _selectedIndex == 0,
                    size: 28,
                  ),
                ),
                GestureDetector(
                  onTap: () => onItemTapped(1),
                  child: CustomNavIcon(
                    iconPath: 'assets/images/icons/png/collection.png',
                    selectedIconPath:
                        'assets/images/icons/png/collection_selected.png',
                    isSelected: _selectedIndex == 1,
                    size: 36,
                  ),
                ),
                GestureDetector(
                  onTap: () => onItemTapped(2),
                  child: CustomNavIcon(
                    iconPath: 'assets/images/icons/png/game.png',
                    selectedIconPath:
                        'assets/images/icons/png/game_selected.png',
                    isSelected: _selectedIndex == 2,
                    size: 36,
                  ),
                ),
                GestureDetector(
                  onTap: () => onItemTapped(3),
                  child: CustomNavIcon(
                    iconPath: 'assets/images/icons/png/event.png',
                    selectedIconPath:
                        'assets/images/icons/png/event_selected.png',
                    isSelected: _selectedIndex == 3,
                    size: 36,
                  ),
                ),
                GestureDetector(
                  onTap: () => onItemTapped(4),
                  child: CustomNavIcon(
                    iconPath: 'assets/images/icons/png/profile.png',
                    selectedIconPath:
                        'assets/images/icons/png/profile_selected.png',
                    isSelected: _selectedIndex == 4,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
