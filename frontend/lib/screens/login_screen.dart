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
  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
        _errorList = []; // Clear other errors
      });
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
      _error = '';
      _errorList = [];
    });

    _formKey.currentState!.save();

    try {
      // Call the signup method from AuthService instance
      final result = await _authService.signup( // Use instance
        firstName: _firstName,
        lastName: _lastName,
        email: _email,
        password: _password,
      );

      if (!mounted) return;
      setState(() { _loading = false; });

      if (result['success']) {
        if (mounted) { // Token check removed
          await _saveEmail(_email); // Save email on successful signup
          if (mounted) {
            // Navigate to AgencySelectionScreen without token in arguments
            Navigator.pushReplacementNamed(context, '/agencySelection');
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
              _error = result['message'] ?? 'Une erreur inconnue est survenue lors de l\'inscription.';
              _errorList = [];
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur d\'inscription: ${e.toString()}';
          _errorList = [];
        });
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          Text(
            "Inscription",
            style: TextStyle(
              color: AppColors.subTitleColor, // Use AppColors
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Créez votre compte e-retraite",
            style: TextStyle(
              color: AppColors.grayColor, // Use AppColors
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (_errorList.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1), // Use AppColors
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _errorList.map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.errorColor, size: 18), // Use AppColors
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle( // Removed const
                            color: AppColors.errorColor, // Use AppColors
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
                color: AppColors.errorColor.withOpacity(0.1), // Use AppColors
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorColor, size: 18), // Use AppColors
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle( // Removed const
                        color: AppColors.errorColor, // Use AppColors
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
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              labelStyle: TextStyle(color: AppColors.grayColor), // Use AppColors
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryColor), // Use AppColors
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5), // Use AppColors
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSaved: (v) => _firstName = v ?? '',
            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Requis',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Nom',
              labelStyle: TextStyle(color: AppColors.grayColor), // Use AppColors
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryColor), // Use AppColors
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5), // Use AppColors
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSaved: (v) => _lastName = v ?? '',
            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Requis',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Adresse e-mail',
              labelStyle: TextStyle(color: AppColors.grayColor), // Use AppColors
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryColor), // Use AppColors
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5), // Use AppColors
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.emailAddress,
            onSaved: (v) => _email = v ?? '',
            validator: (v) => v != null && v.contains('@') ? null : 'Veuillez entrer une adresse e-mail valide',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: TextStyle(color: AppColors.grayColor), // Use AppColors
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor), // Use AppColors
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.grayColor, // Use AppColors
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5), // Use AppColors
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            obscureText: _obscurePassword,
            onChanged: (v) => _password = v,
            onSaved: (v) => _password = v ?? '',
            validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              labelStyle: TextStyle(color: AppColors.grayColor), // Use AppColors
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor), // Use AppColors
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.grayColor, // Use AppColors
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1), // Use AppColors
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5), // Use AppColors
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            obscureText: _obscureConfirmPassword,
            onChanged: (v) => _confirmPassword = v,
            onSaved: (v) => _confirmPassword = v ?? '',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (v.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
              if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas.';
              return null;
            }
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor, // Use AppColors
                foregroundColor: AppColors.whiteColor, // Use AppColors
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
                            color: AppColors.whiteColor, // Use AppColors
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
      backgroundColor: AppColors.bgLightColor, // Changed to AppColors.bgLightColor
      body: Stack(
        children: [
          Container(
            height: size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryColor, AppColors.bgDarkBlueColor], // Changed to AppColors
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row( // This Row is fine for the back button and title
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/'); // Navigates to LoginScreen
                          },
                        ),
                        const Text(
                          "Créer un compte",
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_animationsInitialized)
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildSignupForm(),
                            ),
                          ),
                        ),
                      )
                    else
                      Card( // Fallback if animations not ready
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildSignupForm(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_animationsInitialized)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/'); // Navigates to LoginScreen
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "Déjà un compte ? ",
                              style: TextStyle(color: AppColors.grayColor),
                              children: [
                                TextSpan(
                                  text: "Connectez-vous",
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      TextButton( // Fallback if animations not ready
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Déjà un compte ? ",
                            style: TextStyle(color: AppColors.grayColor),
                            children: [
                              TextSpan(
                                text: "Connectez-vous",
                                style: TextStyle(
                                  color: AppColors.primaryColor,
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
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 4,
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