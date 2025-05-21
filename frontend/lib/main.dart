import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/agency_screen.dart';
import 'screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agency Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
      routes: {
        '/agencies': (context) => const AgencyScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}