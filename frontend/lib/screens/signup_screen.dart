import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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
  bool get _passwordsMatch => _password == _confirmPassword && _password.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
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
    setState(() { _loading = true; _error = ''; _errorList = []; });
    _formKey.currentState!.save();

    final result = await AuthService.signup(
      email: _email,
      password: _password,
      firstName: _firstName,
      lastName: _lastName,
    );

    setState(() { _loading = false; });

    if (result['success']) {
      final token = result['data']['token'];
      if (token != null && mounted) {
        await _saveEmail(_email);
        Navigator.pushReplacementNamed(context, '/agencies', arguments: token);
      } else {
        setState(() { _error = result['message'] ?? 'Échec de l\'inscription : aucun jeton reçu.'; });
      }
    } else {
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_errorList.isNotEmpty)
                      Column(
                        children: _errorList.map((msg) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(msg, style: TextStyle(color: errorColor, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        )).toList(),
                      ),
                    if (_error.isNotEmpty)
                      Text(
                        _error,
                        style: TextStyle(color: errorColor),
                        textAlign: TextAlign.center,
                      ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        labelStyle: TextStyle(color: subTitleColor),
                      ),
                      onSaved: (v) => _firstName = v ?? '',
                      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Le prénom est requis',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nom de famille',
                        labelStyle: TextStyle(color: subTitleColor),
                      ),
                      onSaved: (v) => _lastName = v ?? '',
                      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Le nom de famille est requis',
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        labelStyle: TextStyle(color: subTitleColor),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) => _email = v ?? '',
                      validator: (v) => v != null && v.contains('@') ? null : 'Veuillez entrer une adresse e-mail valide',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: TextStyle(color: subTitleColor),
                      ),
                      obscureText: true,
                      onChanged: (v) => setState(() { _password = v; }),
                      onSaved: (v) => _password = v ?? '',
                      validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        labelStyle: const TextStyle(color: subTitleColor),
                        suffixIcon: _confirmPassword.isEmpty
                            ? null
                            : (_passwordsMatch
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.cancel, color: Colors.red)),
                      ),
                      obscureText: true,
                      onChanged: (v) => setState(() { _confirmPassword = v; }),
                      validator: (v) => v != null && v.isNotEmpty ? null : 'Veuillez confirmer le mot de passe',
                    ),
                    const SizedBox(height: 20),
                    if (!_loading)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: primaryColor,
                          ),
                          onPressed: _submit,
                          child: const Text("S'inscrire"),
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Text(
                        'Vous avez déjà un compte ? Connectez-vous',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/loading_animation.json',
                  width: 250,
                  height: 250,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 