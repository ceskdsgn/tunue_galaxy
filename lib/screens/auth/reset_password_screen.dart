// screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  final AuthService _authService = AuthService();
  bool _emailValidationError = false;

  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Aggiungi listener per validare quando si esce dal campo
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmailField();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
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

  String _getEmailErrorMessage() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Inserisci la tua email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Inserisci un indirizzo email valido';
    }
    return '';
  }

  Future<void> _resetPassword() async {
    // Reset errori precedenti
    setState(() {
      _emailValidationError = false;
    });

    // Valida il campo email prima di procedere
    _validateEmailField();

    // Controlla se ci sono errori di validazione
    if (_emailValidationError) {
      return; // Non procedere se ci sono errori
    }

    // Controlla se il campo è compilato
    if (_emailController.text.trim().isEmpty) {
      // Mostra errore per il campo vuoto
      setState(() {
        _emailValidationError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _authService.resetPassword(
      email: _emailController.text.trim(),
      onSuccess: () {
        setState(() {
          _isLoading = false;
          _resetSent = true;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
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
          child: _resetSent ? _buildSuccessMessage() : _buildResetForm(),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
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
          'Reimposta Password',
          style: TextStyle(
            fontSize: 32,
            color: Colors.black,
            fontFamily: 'NeueHaasDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),

        // Sottotitolo
        const Text(
          'Ricevi il link via email',
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
        ),

        const Spacer(),

        // Pulsante Invia Link
        GestureDetector(
          onTap: _isLoading ? null : _resetPassword,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 16),
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
                        'Invia Link',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
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

        // Link per tornare al login
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ricordi la tua password? ',
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
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
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
          'Link Inviato!',
          style: TextStyle(
            fontSize: 32,
            color: Colors.black,
            fontFamily: 'NeueHaasDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),

        // Sottotitolo
        Text(
          'Abbiamo inviato un\'email a ${_emailController.text}',
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 0, 0, 0),
            fontFamily: 'NeueHaasDisplay',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Messaggio di istruzione
        const Text(
          'Controlla la tua casella di posta',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontFamily: 'NeueHaasDisplay',
          ),
        ),

        const Spacer(),

        // Pulsante Torna al Login
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 16),
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
                  'Torna al login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'NeueHaasDisplay',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
