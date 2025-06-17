import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();
  String? _emailError;
  bool _emailValidationError = false;
  bool _passwordValidationError = false;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {});
    });

    // Aggiungi listener per validare quando si esce da un campo
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmailField();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _validatePasswordField();
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(() {});
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _validateEmailField() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailValidationError = false; // Non mostrare errore se vuoto
      } else {
        _emailValidationError =
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
      }
    });
  }

  void _validatePasswordField() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordValidationError = false; // Non mostrare errore se vuoto
      } else {
        _passwordValidationError =
            password.length < 6; // Aggiungi validazione minima
      }
    });
  }

  String _getEmailErrorMessage() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Inserisci la tua email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Inserisci un indirizzo email valido';
    }
    return '';
  }

  String _getPasswordErrorMessage() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Inserisci la tua password';
    } else if (password.length < 6) {
      return 'La password deve avere almeno 6 caratteri';
    }
    return '';
  }

  Future<void> _login() async {
    // Reset errori precedenti
    setState(() {
      _emailError = null;
      _emailValidationError = false;
      _passwordValidationError = false;
    });

    // Valida tutti i campi prima di procedere
    _validateEmailField();
    _validatePasswordField();

    // Controlla se ci sono errori di validazione
    if (_emailValidationError || _passwordValidationError) {
      return; // Non procedere se ci sono errori
    }

    // Controlla se tutti i campi sono compilati
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      // Mostra errori per i campi vuoti
      setState(() {
        if (_emailController.text.trim().isEmpty) _emailValidationError = true;
        if (_passwordController.text.isEmpty) _passwordValidationError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      onSuccess: (user) {
        // Aggiorna il modello utente usando Provider
        final userModel = Provider.of<User>(context, listen: false);
        userModel.update(
          id: user.id,
          username: user.username,
          email: _emailController.text.trim(),
          tunueCoins: user.tunueCoins,
          ownedCards: user.ownedCards,
          lastPackOpenTime: user.lastPackOpenTime,
          isAuthenticated: true,
        );

        setState(() {
          _isLoading = false;
        });

        // Naviga alla schermata principale
        Navigator.of(context)
            .pop(true); // Ritorna true per indicare login avvenuto
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          // Dato che Supabase non distingue tra email non esistente e password sbagliata
          // per motivi di sicurezza, mostriamo un messaggio generico
          _emailError = 'Email o password non valide';
        });
        // Forza la rivalidazione per attivare i bordi rossi
        _formKey.currentState?.validate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pulsante indietro
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: SvgPicture.asset(
                  'assets/images/icons/svg/arrow_icon.svg',
                  width: 24,
                  height: 24,
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),

              // Titolo principale
              const Text(
                'Bentornato in Tunuè',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  fontFamily: 'NeueHaasDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Sottotitolo
              const Text(
                'Inserisci i tuoi dati',
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontFamily: 'NeueHaasDisplay',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Color(0xFF7B7D8A),
                              selectionColor: Color(0xFF7B7D8A),
                              selectionHandleColor: Colors.transparent,
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            cursorColor: const Color(0xFF7B7D8A),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: (_emailError != null ||
                                        _emailValidationError)
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: (_emailError != null ||
                                          _emailValidationError)
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: (_emailError != null ||
                                          _emailValidationError)
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: (_emailError != null ||
                                          _emailValidationError)
                                      ? Colors.red
                                      : const Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: _emailController.text.isNotEmpty
                                  ? const Color(0xFFF9F9F9)
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        if (_emailError != null || _emailValidationError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              _emailError ?? _getEmailErrorMessage(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campo Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Color(0xFF7B7D8A),
                              selectionColor: Color(0xFF7B7D8A),
                              selectionHandleColor: Colors.transparent,
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            cursorColor: const Color(0xFF7B7D8A),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: _passwordValidationError
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _passwordValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _passwordValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _passwordValidationError
                                      ? Colors.red
                                      : const Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            obscureText: _obscurePassword,
                          ),
                        ),
                        if (_passwordValidationError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              _getPasswordErrorMessage(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Link password dimenticata
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Hai dimenticato la password? ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'NeueHaasDisplay',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ResetPasswordScreen(),
                                ),
                              );
                            },
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0FA127),
                                  Color(0xFF30A365),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Recuperala',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontFamily: 'NeueHaasDisplay',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Pulsante Login
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 78, vertical: 12),
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
                  child: _isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Accedi',
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

              // Link per registrazione
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Non hai un account? ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontFamily: 'NeueHaasDisplay',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Registrati',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: 'NeueHaasDisplay',
                        fontWeight: FontWeight.bold,
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
    );
  }
}
