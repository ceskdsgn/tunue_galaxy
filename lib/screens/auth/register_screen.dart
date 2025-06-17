// screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _registrationSent = false;

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

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      onSuccess: (user) {
        setState(() {
          _isLoading = false;
          _registrationSent = true;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _registrationSent = true;
        });
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
          child:
              _registrationSent ? _buildSuccessMessage() : _buildRegisterForm(),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
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
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'NeueHaasDisplay',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
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
              const SizedBox(height: 16),

              // Campo email
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
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'NeueHaasDisplay',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
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
              const SizedBox(height: 16),

              // Campo password
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
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'NeueHaasDisplay',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
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
              const SizedBox(height: 16),

              // Campo conferma password
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
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'NeueHaasDisplay',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF7B7D8A),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
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
            padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 12),
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
                              : const Color(0xFFB0B0B0),
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
          'Registrazione Completata!',
          style: TextStyle(
            fontSize: 28,
            color: Colors.black,
            fontFamily: 'NeueHaasDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 4),

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
            padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 12),
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
                    fontSize: 16,
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
