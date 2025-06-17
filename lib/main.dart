// main.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'constants/supabase_config.dart';
import 'models/card.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/no_connection_screen.dart';
import 'screens/collection_page.dart';
import 'screens/fair_page.dart';
import 'screens/game_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/card_service.dart';
import 'utils/theme.dart';
import 'widgets/custom_nav_icon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => User(username: ''),
        ),
        Provider<CardService>(
          create: (_) => CardService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _hasInternetConnection = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _initializeApp();
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
    });

    // Ascolta i cambiamenti della connessione
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _hasInternetConnection = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _initializeApp() async {
    final userModel = Provider.of<User>(context, listen: false);

    _authService.authStateChanges.listen((event) async {
      final user = event.session?.user;
      if (user != null) {
        try {
          // Recupera i dati del profilo
          final profile = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

          // Converti le carte possedute da JSON a oggetti
          List<CollectionCard> ownedCards = [];
          if (profile['owned_cards'] != null &&
              profile['owned_cards'] is List) {
            for (var cardData in profile['owned_cards']) {
              ownedCards.add(CollectionCard.fromJson(cardData));
            }
          }

          // Aggiorna i dati utente se autenticato
          userModel.update(
            id: user.id,
            username: user.userMetadata?['username'] ?? 'Collezionista',
            email: user.email,
            tunueCoins: profile['tunue_coins'] ?? 100,
            ownedCards: ownedCards,
            lastPackOpenTime: DateTime.parse(profile['last_pack_open_time'] ??
                DateTime.now().toUtc().toIso8601String()),
            nextPackTime: DateTime.parse(profile['next_pack_time'] ??
                DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 12))
                    .toIso8601String()),
            isAuthenticated: true,
          );
        } catch (e) {
          print('Errore nel caricamento del profilo: $e');
          // In caso di errore, usa i valori di default
          userModel.update(
            id: user.id,
            username: user.userMetadata?['username'] ?? 'Collezionista',
            email: user.email,
            tunueCoins: 100,
            ownedCards: [],
            lastPackOpenTime: DateTime.now().toUtc(),
            nextPackTime: DateTime.now().toUtc().add(const Duration(hours: 12)),
            isAuthenticated: true,
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
      home: !_isInitialized
          ? const SplashScreen()
          : !_hasInternetConnection
              ? const NoConnectionScreen()
              : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(),
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
