import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Assuming this path is correct
import '../constants/colors.dart'; // Assuming this path is correct
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService(); // Instantiate AuthService
  String _email = '';
  String _password = '';
  String _error = '';
  bool _loading = false;
  List<String> _errorList = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _animationsReady = false;

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
          _animationsReady = true;
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
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = '';
      _errorList = [];
    });

    _formKey.currentState!.save();

    try {
      // Use the instance of AuthService
      final result = await _authService.login(_email, _password);
      if (!mounted) return;
      setState(() { _loading = false; });

      if (result['success']) {
        final token = result['data']['token'];
        if (token != null && mounted) {
          await _saveEmail(_email);
          if (mounted) {
            // Navigate to AgencySelectionScreen instead of /agencies
            Navigator.pushReplacementNamed(context, '/agencySelection');
          }
        } else {
          if (mounted) {
            setState(() {
              _error = result['message'] ?? 'Échec de la connexion : aucun jeton reçu.';
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
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
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 60),
                    if (_animationsReady)
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition( // Added FadeTransition for the card
                          opacity: _fadeAnimation,
                          child: _buildLoginCard(),
                        ),
                      )
                    else
                      _buildLoginCard(),
                    const SizedBox(height: 24),
                    if (_animationsReady)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSignUpLink(),
                      )
                    else
                      _buildSignUpLink(),
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
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor, // Changed to AppColors.primaryColor
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Widget content = Column(
      children: [
        Image.asset(
          'assets/logos/e_retraite.png',
          height: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          "Espace Connexion",
          style: TextStyle(
            color: AppColors.whiteColor, // Changed to AppColors.whiteColor
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Bienvenue dans l'espace e-retraite",
          style: TextStyle(
            color: AppColors.whiteColor.withAlpha((255 * 0.8).round()), // Changed to AppColors.whiteColor.withAlpha
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return _animationsReady
      ? FadeTransition(opacity: _fadeAnimation, child: content)
      : content;
  }

  Widget _buildLoginCard() {
    // Changed Container to Card, and updated styling to match SignupScreen
    return Card(
      elevation: 8, // Consistent with SignupScreen
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Consistent with SignupScreen
      ),
      // color: whiteColor, // Card usually defaults to white or Theme.cardColor. If whiteColor is custom, add it.
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connexion",
                style: TextStyle(
                  color: AppColors.subTitleColor, // Changed to AppColors.subTitleColor
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Veuillez entrer vos identifiants",
                style: TextStyle(
                  color: AppColors.grayColor, // Changed to AppColors.grayColor
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withAlpha((255 * 0.1).round()), // Changed to AppColors.errorColor.withAlpha
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _errorList.map((msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18), // Changed to AppColors.errorColor
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(
                                color: AppColors.errorColor, // Changed to AppColors.errorColor
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
                    color: AppColors.errorColor.withAlpha((255 * 0.1).round()), // Changed to AppColors.errorColor.withAlpha
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18), // Changed to AppColors.errorColor
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: AppColors.errorColor, // Changed to AppColors.errorColor
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

              // Email field: Removed Container wrapper, applied OutlineInputBorder
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail',
                  labelStyle: TextStyle(color: AppColors.grayColor), // Changed to AppColors.grayColor
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryColor, size: 20), // Simplified icon
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Consistent with SignupScreen fields
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  // floatingLabelBehavior: FloatingLabelBehavior.never, // Removed for consistency
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _email = v ?? '',
                validator: (v) => v != null && v.contains('@') ? null : 'Veuillez entrer une adresse e-mail valide',
              ),
              const SizedBox(height: 16),

              // Password field: Removed Container wrapper, applied OutlineInputBorder
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: AppColors.grayColor), // Changed to AppColors.grayColor
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 20), // Simplified icon
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.grayColor, // Changed to AppColors.grayColor
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Consistent with SignupScreen fields
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  // floatingLabelBehavior: FloatingLabelBehavior.never, // Removed for consistency
                ),
                obscureText: _obscurePassword,
                onSaved: (v) => _password = v ?? '',
                validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor, // Changed to AppColors.primaryColor
                    foregroundColor: AppColors.whiteColor, // Changed to AppColors.whiteColor
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
                                color: AppColors.whiteColor, // Changed to AppColors.whiteColor
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Connexion en cours...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/signup');
      },
      child: RichText(
        text: TextSpan(
          text: "Pas de compte ? ",
          style: TextStyle(color: AppColors.grayColor), // Changed to AppColors.grayColor
          children: [
            TextSpan(
              text: "Inscrivez-vous",
              style: TextStyle(
                color: AppColors.primaryColor, // Changed to AppColors.primaryColor
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}