import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _error = '';
  bool _loading = false;
  List<String> _errorList = [];
  final TextEditingController _emailController = TextEditingController();

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
    setState(() { _loading = true; _error = ''; _errorList = []; });
    _formKey.currentState!.save();

    await Future.delayed(const Duration(seconds: 2)); // Artificial delay
    final result = await AuthService.login(_email, _password);

    setState(() { _loading = false; });

    if (result['success']) {
      final token = result['data']['token'];
      if (token != null && mounted) {
        await _saveEmail(_email);
        Navigator.pushReplacementNamed(context, '/agencies', arguments: token);
      } else {
        setState(() { _error = result['message'] ?? 'Échec de la connexion : aucun jeton reçu.'; });
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
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/lottie/loading_animation.json',
            width: 250,
            height: 250,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
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
                  onSaved: (v) => _password = v ?? '',
                  validator: (v) => v != null && v.length >= 6 ? null : 'Le mot de passe doit contenir au moins 6 caractères',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: primaryColor,
                    ),
                    onPressed: _submit,
                    child: const Text('Se connecter'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
                  },
                  child: Text(
                    "Pas de compte ? Inscrivez-vous",
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}