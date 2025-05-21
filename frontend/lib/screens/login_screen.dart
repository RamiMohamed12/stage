import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLogin = true;
  String _error = '';
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    _formKey.currentState!.save();

    Map<String, dynamic> result;
    if (_isLogin) {
      result = await AuthService.login(_email, _password);
    } else {
      result = await AuthService.signup(
        email: _email,
        password: _password,
        firstName: _firstName,
        lastName: _lastName,
      );
    }

    setState(() { _loading = false; });

    if (result['success']) {
      final token = result['data']['token'];
      if (token != null && mounted) {
        Navigator.pushReplacementNamed(context, '/agencies', arguments: token);
      } else {
         setState(() { _error = result['message'] ?? 'Échec de la connexion/inscription : aucun jeton reçu.'; });
      }
    } else {
      setState(() { _error = result['message'] ?? 'Une erreur inconnue est survenue.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Connexion' : 'Inscription'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
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
                if (!_isLogin) ...[
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
                ],
                const SizedBox(height: 20),
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style: TextStyle(color: errorColor),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 10),
                if (_loading)
                  const CircularProgressIndicator(),
                if (!_loading)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: primaryColor,
                      ),
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Se connecter' : "S'inscrire"),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = '';
                    _formKey.currentState?.reset();
                  }),
                  child: Text(
                    _isLogin ? "Pas de compte ? Inscrivez-vous" : 'Vous avez déjà un compte ? Connectez-vous',
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