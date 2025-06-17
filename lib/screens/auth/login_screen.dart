// screens/auth/login_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/auth_service.dart';
import 'email_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/logos/background_login-page.jpg'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Spazio flessibile superiore
                const Spacer(flex: 2),

                // Spazio flessibile inferiore (più grande)
                const Spacer(flex: 3),

                // Pulsanti social login
                _buildSocialButton(
                  icon: Icons.apple,
                  text: 'Continua con Apple',
                  onPressed: () {
                    // TODO: Implementare Apple Sign In
                  },
                  iconColor: Colors.white,
                  iconSize: 28,
                ),
                const SizedBox(height: 16),

                _buildSocialButton(
                  icon: Icons.g_translate,
                  text: 'Continua con Google',
                  onPressed: () {
                    // TODO: Implementare Google Sign In
                  },
                  isGoogleIcon: true,
                ),
                const SizedBox(height: 16),

                _buildSocialButton(
                  icon: Icons.facebook,
                  text: 'Continua con Facebook',
                  onPressed: () {
                    // TODO: Implementare Facebook Sign In
                  },
                  iconColor: Colors.blue,
                  iconSize: 28,
                ),

                const SizedBox(height: 16),

                // Separatore "oppure" con linee
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: const Color(0xFF494B51),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'oppure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'NeueHaasDisplay',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: const Color(0xFF494B51),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pulsante "Crea un account"
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 78, vertical: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF13C931),
                          Color(0xFF3CCC7E),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Crea un account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'NeueHaasDisplay',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Link per accedere
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Hai già un account? ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'NeueHaasDisplay',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmailLoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Accedi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NeueHaasDisplay',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isGoogleIcon = false,
    double? iconSize,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: InkWell(
              onTap: onPressed,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              splashFactory: InkRipple.splashFactory,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF1B1C1E), width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGoogleIcon)
                      SvgPicture.asset(
                        'assets/images/icons/svg/Google_Favicon_2025.svg',
                        height: iconSize ?? 22,
                      ),
                    if (!isGoogleIcon)
                      Icon(
                        icon,
                        color: iconColor ?? Colors.black,
                        size: iconSize ?? 24,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NeueHaasDisplay',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
