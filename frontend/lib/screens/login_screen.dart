import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
      final token = result['data']['token']; // Assuming backend sends { "token": "..." }
      if (token != null && mounted) {
        Navigator.pushReplacementNamed(context, '/agencies', arguments: token);
      } else {
         setState(() { _error = result['message'] ?? 'Login/Signup failed: No token received.'; });
      }
    } else {
      setState(() { _error = result['message'] ?? 'An unknown error occurred.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Added for scrollability if fields overflow
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (v) => _email = v ?? '',
                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (v) => _password = v ?? '',
                  validator: (v) => v != null && v.length >= 6 ? null : 'Password must be at least 6 characters',
                ),
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'First Name (Optional)'),
                    onSaved: (v) => _firstName = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Last Name (Optional)'),
                    onSaved: (v) => _lastName = v ?? '',
                  ),
                ],
                const SizedBox(height: 20),
                if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
                const SizedBox(height: 10),
                if (_loading) const CircularProgressIndicator(),
                if (!_loading)
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = ''; // Clear error when switching modes
                    _formKey.currentState?.reset(); // Reset form fields
                  }),
                  child: Text(_isLogin ? 'No account? Sign Up' : 'Have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}