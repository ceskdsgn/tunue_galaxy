// screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthService _authService = AuthService();
  bool _allFieldsValid = false;
  bool _usernameValidationError = false;
  bool _emailValidationError = false;
  bool _passwordValidationError = false;
  bool _confirmPasswordValidationError = false;

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkAllFieldsValid);
    _emailController.addListener(_checkAllFieldsValid);
    _passwordController.addListener(_checkAllFieldsValid);
    _confirmPasswordController.addListener(_checkAllFieldsValid);

    // Aggiungi listener per validare quando si esce da un campo
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        _validateUsernameField();
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmailField();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _validatePasswordField();
        // Se il campo conferma password è già stato compilato, rivalidalo
        if (_confirmPasswordController.text.isNotEmpty) {
          _validateConfirmPasswordField();
        }
      }
    });
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        _validateConfirmPasswordField();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.removeListener(_checkAllFieldsValid);
    _emailController.removeListener(_checkAllFieldsValid);
    _passwordController.removeListener(_checkAllFieldsValid);
    _confirmPasswordController.removeListener(_checkAllFieldsValid);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _checkAllFieldsValid() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isUsernameValid = username.isNotEmpty && username.length >= 3;
    final isEmailValid = email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    final isPasswordValid = password.isNotEmpty && password.length >= 6;
    final isConfirmPasswordValid =
        confirmPassword.isNotEmpty && confirmPassword == password;

    setState(() {
      _allFieldsValid = isUsernameValid &&
          isEmailValid &&
          isPasswordValid &&
          isConfirmPasswordValid;
    });
  }

  void _validateUsernameField() {
    final username = _usernameController.text.trim();
    setState(() {
      if (username.isEmpty) {
        _usernameValidationError = false; // Non mostrare errore se vuoto
      } else {
        _usernameValidationError = username.length < 3;
      }
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
        _passwordValidationError = password.length < 6;
      }
    });
  }

  void _validateConfirmPasswordField() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordValidationError = false; // Non mostrare errore se vuoto
      } else {
        _confirmPasswordValidationError = confirmPassword != password;
      }
    });
  }

  Future<void> _register() async {
    // Valida tutti i campi prima di procedere
    _validateUsernameField();
    _validateEmailField();
    _validatePasswordField();
    _validateConfirmPasswordField();

    // Controlla se ci sono errori
    if (_usernameValidationError ||
        _emailValidationError ||
        _passwordValidationError ||
        _confirmPasswordValidationError) {
      return; // Non procedere se ci sono errori
    }

    // Controlla se tutti i campi sono compilati
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      // Mostra errori per i campi vuoti
      setState(() {
        if (_usernameController.text.trim().isEmpty)
          _usernameValidationError = true;
        if (_emailController.text.trim().isEmpty) _emailValidationError = true;
        if (_passwordController.text.isEmpty) _passwordValidationError = true;
        if (_confirmPasswordController.text.isEmpty)
          _confirmPasswordValidationError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      onSuccess: (user) {
        // Aggiorna il modello utente usando Provider
        final userModel = Provider.of<User>(context, listen: false);
        userModel.update(
          id: user.id,
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          tunueCoins: user.tunueCoins,
          ownedCards: user.ownedCards,
          lastPackOpenTime: user.lastPackOpenTime,
          isAuthenticated: true,
        );

        // Mostra messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrazione completata con successo!'),
            backgroundColor: Colors.green,
          ),
        );

        // Torna alla schermata precedente
        Navigator.of(context).pop();
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
                'Benvenuto in Tunuè',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  fontFamily: 'NeueHaasDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Sottotitolo
              const Text(
                'Crea il tuo account',
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
                    // Campo username
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
                            controller: _usernameController,
                            focusNode: _usernameFocusNode,
                            cursorColor: const Color(0xFF7B7D8A),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: _usernameValidationError
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _usernameValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _usernameValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _usernameValidationError
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
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                          ),
                        ),
                        if (_usernameValidationError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              _getUsernameErrorMessage(),
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

                    // Campo email
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
                                color: _emailValidationError
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _emailValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _emailValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _emailValidationError
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
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        if (_emailValidationError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              _getEmailErrorMessage(),
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

                    // Campo password
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

                    // Campo conferma password
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
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            cursorColor: const Color(0xFF7B7D8A),
                            decoration: InputDecoration(
                              labelText: 'Conferma Password',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: _confirmPasswordValidationError
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _confirmPasswordValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _confirmPasswordValidationError
                                      ? Colors.red
                                      : const Color(0xFF7B7D8A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  color: _confirmPasswordValidationError
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
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  onPressed: _toggleConfirmPasswordVisibility,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'NeueHaasDisplay',
                            ),
                            obscureText: _obscureConfirmPassword,
                          ),
                        ),
                        if (_confirmPasswordValidationError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              _getConfirmPasswordErrorMessage(),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              const Spacer(),

              // Pulsante REGISTRATI
              GestureDetector(
                onTap: (_isLoading || !_allFieldsValid) ? null : _register,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 78, vertical: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    gradient: _allFieldsValid
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF13C931),
                              Color(0xFF3CCC7E),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0A6B1C),
                              Color(0xFF1F7A3A),
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
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _allFieldsValid ? 'Registrati' : 'Continua',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _allFieldsValid
                                    ? Colors.white
                                    : const Color(0xFFF9F9F9),
                                fontSize: 18,
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Link per il login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hai già un account? ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontFamily: 'NeueHaasDisplay',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Accedi',
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

  String _getUsernameErrorMessage() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return 'Inserisci un nome utente';
    } else if (username.length < 3) {
      return 'Il nome utente deve avere almeno 3 caratteri';
    }
    return '';
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
      return 'Inserisci una password';
    } else if (password.length < 6) {
      return 'La password deve avere almeno 6 caratteri';
    }
    return '';
  }

  String _getConfirmPasswordErrorMessage() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    if (confirmPassword.isEmpty) {
      return 'Conferma la tua password';
    } else if (confirmPassword != password) {
      return 'Le password non corrispondono';
    }
    return '';
  }
}
