import 'package:flutter/material.dart';
import 'package:frontend/widgets/loading_indicator.dart'; // Import the custom loading indicator
import '../services/auth_service.dart';
import '../services/declaration_service.dart'; // Add this import
import '../services/appointment_service.dart'; // Add this import
import '../constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  // It's good practice to have a routeName for screens navigated to by name
  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final DeclarationService _declarationService = DeclarationService(); // Add this
  final AppointmentService _appointmentService = AppointmentService(); // Add this
  String _email = '';
  String _password = '';
  String _error = '';
  bool _loading = false; // Renamed from _isLoading for consistency with your code
  List<String> _errorList = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _animationsInitialized = false;

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
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = '';
      _errorList = [];
    });

    _formKey.currentState!.save();

    try {
      final result = await _authService.login(_email, _password);
      if (!mounted) return;

      if (result['success']) {
        final token = result['data']?['token'];
        if (token != null && mounted) {
          await _saveEmail(_email);
          
          // Check for active appointments first
          try {
            final activeAppointment = await _appointmentService.getActiveAppointment();
            
            if (mounted && activeAppointment != null) {
              // Check if the appointment is cancelled (rejected)
              if (activeAppointment['status'] == 'cancelled') {
                // User has a rejected appointment - redirect to rejection screen
                Navigator.pushReplacementNamed(
                  context, 
                  '/appointment-reject',
                  arguments: {
                    'declarationId': activeAppointment['declaration_id'],
                    'applicantName': result['data']?['user']?['first_name'] ?? 'Utilisateur',
                    'rejectionReason': 'Votre rendez-vous a été annulé. Veuillez vérifier vos notifications pour plus de détails.',
                  },
                );
                return;
              }
              
              // User has an active appointment - redirect to appointment success screen
              Navigator.pushReplacementNamed(
                context, 
                '/appointment-success',
                arguments: {
                  'declarationId': activeAppointment['declaration_id'],
                  'applicantName': result['data']?['user']?['first_name'] ?? 'Utilisateur',
                },
              );
              return;
            }
          } catch (appointmentError) {
            // If checking appointments fails, continue with normal flow
            print('Warning: Failed to check active appointments: $appointmentError');
          }
          
          // Check for pending declarations after successful login
          try {
            final pendingDeclaration = await _declarationService.getUserPendingDeclaration();
            
            if (mounted) {
              if (pendingDeclaration != null) {
                // User has pending documents under review - redirect to review screen
                Navigator.pushReplacementNamed(
                  context, 
                  '/documents-review',
                  arguments: {
                    'declarationId': pendingDeclaration['declaration']['declaration_id'],
                    'applicantName': result['data']?['user']?['firstName'],
                  },
                );
              } else {
                // No pending declarations - proceed to agency selection
                Navigator.pushReplacementNamed(context, '/agencySelection');
              }
            }
          } catch (pendingError) {
            // If checking pending declarations fails, continue to agency selection
            // This ensures users can still log in even if the pending check fails
            print('Warning: Failed to check pending declarations: $pendingError');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/agencySelection');
            }
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
              _errorList = List<String>.from(
                  (result['errors'] as List).map((e) => e is Map ? e['msg'].toString() : e.toString())
              );
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
          _error = 'Erreur de connexion: ${e.toString()}';
          _errorList = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose(); // Dispose directly, stop() is called internally
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Initial loading state before animations are ready
    if (!_animationsInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.bgLightColor,
        body: Center(child: LoadingIndicator(animationSize: 100)), // Ensure this line uses animationSize
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryColor, AppColors.bgDarkBlueColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main Content
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
                    // Animated Login Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildLoginCard(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Animated Sign Up Link
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildSignUpLink(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Loading Indicator Overlay
          if (_loading)
            const LoadingIndicator(), // Your custom Lottie loading widget
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition( // Apply fade to header as well
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Image.asset(
            'assets/logos/e_retraite.png', // Ensure this asset exists
            height: 80,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 80, color: AppColors.whiteColor), // Placeholder if image fails
          ),
          const SizedBox(height: 16),
          const Text(
            "Espace Connexion",
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bienvenue dans l'espace e-retraite",
            style: TextStyle(
              color: AppColors.whiteColor.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  color: AppColors.subTitleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Veuillez entrer vos identifiants",
                style: TextStyle(
                  color: AppColors.grayColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Error Display Area
              if (_errorList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errorList.map((msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(
                                color: AppColors.errorColor,
                                fontWeight: FontWeight.w500, // Changed from bold for better readability
                                fontSize: 13,
                              )
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              if (_error.isNotEmpty && _errorList.isEmpty) // Show general error only if no list
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: AppColors.errorColor,
                            fontWeight: FontWeight.w500, // Changed from bold
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail',
                  labelStyle: TextStyle(color: AppColors.grayColor.withOpacity(0.8)),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryColor, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _email = v ?? '',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer une adresse e-mail.';
                  if (!v.contains('@') || !v.contains('.')) return 'Adresse e-mail invalide.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: AppColors.grayColor.withOpacity(0.8)),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.grayColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                obscureText: _obscurePassword,
                onSaved: (v) => _password = v ?? '',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe.';
                  if (v.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50, // Adjusted height
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    elevation: 2, // Added subtle elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                color: AppColors.whiteColor,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Connexion...'), // Shorter text
                          ],
                        )
                      : const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/signup');
      },
      child: RichText(
        text: TextSpan(
          text: "Pas de compte ? ",
          style: TextStyle(color: AppColors.grayColor.withOpacity(0.9), fontSize: 14),
          children: const [
            TextSpan(
              text: "Inscrivez-vous",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.underline, // Added underline for better affordance
              ),
            ),
          ],
        ),
      ),
    );
  }
}