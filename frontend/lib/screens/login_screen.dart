import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _error = '';
  bool _loading = false;
  List<String> _errorList = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;  
  
  // Initialize animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _loadingController;
  
  // Track if animations are ready to use
  bool _animationsReady = false;
  @override
  void initState() {
    super.initState();
    
    // Initialize animations with optimized durations
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
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Delay animations to prevent blocking UI
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
    
    // Prevent multiple submissions
    if (_loading) return;
    
    setState(() { 
      _loading = true; 
      _error = ''; 
      _errorList = []; 
    });
    
    _formKey.currentState!.save();

    try {
      // Start loading animation only if not already running
      if (!_loadingController.isAnimating) {
        _loadingController.repeat();
      }
      
      final result = await AuthService.login(_email, _password);

      if (!mounted) return;

      setState(() { _loading = false; });
      _loadingController.stop();
      _loadingController.reset();

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
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }
  @override
  void dispose() {
    // Properly dispose of controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    
    // Stop and dispose animation controllers
    _animationController.stop();
    _animationController.dispose();
    
    _loadingController.stop();
    _loadingController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: bgLightColor,
      body: Stack(
        children: [
          // Background design with curved shapes
          Container(
            height: size.height * 0.4,
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
                    const SizedBox(height: 40),
                    
                    // Header with logo and title
                    _buildHeader(),
                    
                    const SizedBox(height: 60),
                    
                    // Login card with form
                    if (_animationsReady)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginCard(),
                      )
                    else
                      _buildLoginCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Sign up link
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
            // Loading overlay with optimized performance
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black54, // Direct color instead of withOpacity
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      color: primaryColor,
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
            color: whiteColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),        Text(
          "Bienvieu dans l'espace e-retraite",
          style: TextStyle(
            color: whiteColor.withValues(alpha: 0.8),
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
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(24),        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Text(
                "Connexion",
                style: TextStyle(
                  color: subTitleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                "Veuillez entrer vos identifiants",
                style: TextStyle(
                  color: grayColor,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error messages              if (_errorList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
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
                    color: errorColor.withValues(alpha: 0.1),
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
                  // Email field
              Container(
                decoration: BoxDecoration(
                  color: bgLightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _emailController,                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail',
                    labelStyle: TextStyle(color: grayColor),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(Icons.email_outlined, color: primaryColor, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
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
                  controller: _passwordController,                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: grayColor),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
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
                  onSaved: (v) => _password = v ?? '',
                  validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Login button
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
          style: TextStyle(color: grayColor),
          children: [
            TextSpan(
              text: "Inscrivez-vous",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}