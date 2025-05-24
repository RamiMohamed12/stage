import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Assuming this path is correct
import '../constants/colors.dart'; // Assuming this path is correct
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _error = '';
  bool _loading = false;
  List<String> _errorList = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool get _passwordsMatch => _password == _confirmPassword && _password.isNotEmpty;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _animationsInitialized = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced duration
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Simpler curve
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3), // Reduced distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Less intensive curve
    ));

    // Delay initialization to prevent blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedEmail();
      if (mounted) {
        setState(() {
          _animationsInitialized = true;
        });
        _animationController.forward();
      }
    });
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    if (savedEmail.isNotEmpty) {
      setState(() {
        _email = savedEmail;
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_passwordsMatch) {
      setState(() {
        _error = 'Les mots de passe ne correspondent pas.';
        _errorList = [];
      });
      return;
    }

    // Prevent multiple submissions
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = '';
      _errorList = [];
    });

    _formKey.currentState!.save();

    try {
      final result = await AuthService.signup(
        email: _email,
        password: _password,
        firstName: _firstName,
        lastName: _lastName,
      );

      if (!mounted) return;

      setState(() { _loading = false; });

      if (result['success']) {
        final token = result['data']['token'];
        if (token != null && mounted) {
          await _saveEmail(_email);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/agencies', arguments: token);
          }
        } else {
          if (mounted) {
            setState(() {
              _error = result['message'] ?? 'Échec de l\'inscription : aucun jeton reçu.';
            });
          }
        }
      } else {
        if (mounted) {
          if (result['errors'] != null && result['errors'] is List) {
            setState(() {
              _errorList = List<String>.from(result['errors'].map((e) => e['msg'].toString()));
              _error = '';
            });
          } else {
            setState(() {
              _error = result['message'] ?? 'Une erreur inconnue est survenue.';
              _errorList = [];
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur de connexion: ${e.toString()}';
          _errorList = [];
        });
      }
    }
  }
  @override
  void dispose() {
    // Properly dispose of all controllers
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Stop and dispose animation controller
    _animationController.stop();
    _animationController.dispose();

    super.dispose();
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title
          Text(
            "Inscription",
            style: TextStyle(
              color: subTitleColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Créez votre compte e-retraite",
            style: TextStyle(
              color: grayColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Error messages
          if (_errorList.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1), // Used withOpacity for consistency
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _errorList.map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: errorColor, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(
                            color: errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1), // Used withOpacity for consistency
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: errorColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(
                        color: errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_error.isNotEmpty || _errorList.isNotEmpty)
            const SizedBox(height: 24),

          // Name fields row
          Row(
            children: [
              // First name field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgLightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      labelStyle: TextStyle(color: grayColor),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Icon(Icons.person_outline, color: primaryColor, size: 20),
                      ),
                      // prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48,), // REMOVED
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    onSaved: (v) => _firstName = v ?? '',
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Requis',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Last name field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgLightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: grayColor),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Icon(Icons.person_outline, color: primaryColor, size: 20),
                      ),
                      // prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48,), // REMOVED
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    onSaved: (v) => _lastName = v ?? '',
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Requis',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email field
          Container(
            decoration: BoxDecoration(
              color: bgLightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Adresse e-mail',
                labelStyle: TextStyle(color: grayColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.email_outlined, color: primaryColor, size: 20),
                ),
                // prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48,), // REMOVED
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _email = v ?? '',
              validator: (v) => v != null && v.contains('@') ? null : 'Veuillez entrer une adresse e-mail valide',
            ),
          ),

          const SizedBox(height: 16),

          // Password field
          Container(
            decoration: BoxDecoration(
              color: bgLightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: TextStyle(color: grayColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                ),
                // prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48,), // REMOVED
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: grayColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              obscureText: _obscurePassword,
              onChanged: (v) => _password = v, // Capture password on change for _passwordsMatch
              onSaved: (v) => _password = v ?? '',
              validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
            ),
          ),

          const SizedBox(height: 16),

          // Confirm password field
          Container(
            decoration: BoxDecoration(
              color: bgLightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                labelStyle: TextStyle(color: grayColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                ),
                // prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48,), // REMOVED
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: grayColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              obscureText: _obscureConfirmPassword,
              onChanged: (v) => _confirmPassword = v, // Capture confirm password on change for _passwordsMatch
              onSaved: (v) => _confirmPassword = v ?? '',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas.';
                return null;
              }
            ),
          ),

          const SizedBox(height: 24),

          // Signup button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: whiteColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: whiteColor,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Inscription en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Créer mon compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: bgLightColor, // Changed to whiteColor as per original design for form card area
      body: Stack(
        children: [
          // Background design with curved shapes
          Container(
            height: size.height * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, bgDarkBlueColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button and page title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                        ),
                        const Text(
                          "Créer un compte",
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 20),
                    // Registration form card
                    if (_animationsInitialized)
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition( // Added FadeTransition for smoother appearance
                          opacity: _fadeAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: whiteColor, // Form card background
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.15), // Used withOpacity
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildSignupForm(),
                            ),
                          ),
                        ),
                      )
                    else
                      Container( // Fallback if animations not initialized
                        decoration: BoxDecoration(
                          color: whiteColor, // Form card background
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.15), // Used withOpacity
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildSignupForm(),
                        ),
                      ),

                    const SizedBox(height: 20),
                    // Login link
                    if (_animationsInitialized)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "Déjà un compte ? ",
                              style: TextStyle(color: grayColor),
                              children: [
                                TextSpan(
                                  text: "Connectez-vous",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      TextButton( // Fallback if animations not initialized
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Déjà un compte ? ",
                            style: TextStyle(color: grayColor),
                            children: [
                              TextSpan(
                                text: "Connectez-vous",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
            // Loading overlay with optimized performance
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black54, // Direct color instead of withOpacity
                child: Center(
                  child: SizedBox( // Constrain the CircularProgressIndicator
                    width: 80, // Adjusted size
                    height: 80, // Adjusted size
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 4, // Adjusted strokeWidth
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Make sure you have your color constants defined in '../constants/colors.dart':
// Example (ensure these match your actual definitions):
/*
// In ../constants/colors.dart
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFYOUR_PRIMARY_COLOR_HEX); // e.g., Colors.blue
const Color subTitleColor = Color(0xFFYOUR_SUBTITLE_COLOR_HEX); // e.g., Colors.black87
const Color grayColor = Color(0xFFYOUR_GRAY_COLOR_HEX); // e.g., Colors.grey
const Color bgLightColor = Color(0xFFYOUR_BGLIGHT_COLOR_HEX); // e.g., Colors.white
const Color whiteColor = Color(0xFFFFFFFF);
const Color errorColor = Color(0xFFYOUR_ERROR_COLOR_HEX); // e.g., Colors.red
const Color bgDarkBlueColor = Color(0xFFYOUR_DARKBLUE_COLOR_HEX); // e.g., Colors.indigo
*/

// And your AuthService in '../services/auth_service.dart':
// Example (ensure this matches your actual service structure):
/*
// In ../services/auth_service.dart
class AuthService {
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    // Example success response
    // return {
    //   'success': true,
    //   'data': {'token': 'fake_jwt_token_12345'},
    //   'message': 'Inscription réussie!'
    // };

    // Example error response (validation)
    // return {
    //   'success': false,
    //   'message': 'Erreur de validation',
    //   'errors': [
    //     {'msg': 'L\'adresse e-mail est déjà utilisée.'},
    //     {'msg': 'Le mot de passe est trop faible.'}
    //   ]
    // };

    // Example general error response
    return {
      'success': false,
      'message': 'Une erreur serveur est survenue.',
    };
  }
}
*/