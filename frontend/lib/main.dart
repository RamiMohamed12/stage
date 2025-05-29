import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart'; // Make sure LoginScreen is imported
import 'package:frontend/screens/agency_selection_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/verification_result_screen.dart';
import 'package:frontend/constants/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decujus Declaration App',
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.bgLightColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          error: AppColors.errorColor,
          background: AppColors.bgLightColor,
          surface: AppColors.whiteColor, // For cards, dialogs etc.
          onPrimary: AppColors.whiteColor, // Text on primary color
          onSecondary: AppColors.whiteColor, // Text on secondary color
          onError: AppColors.whiteColor, // Text on error color
          onBackground: AppColors.textColor, // Text on background color
          onSurface: AppColors.textColor, // Text on surface color
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.whiteColor),
          titleTextStyle: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.whiteColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.whiteColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.errorColor, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.errorColor, width: 2.0),
          ),
          labelStyle: const TextStyle(color: AppColors.textColor, fontSize: 16.0),
          hintStyle: TextStyle(color: AppColors.textColor.withOpacity(0.6), fontSize: 16.0),
          prefixIconColor: AppColors.primaryColor,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold, fontSize: 24.0),
          titleMedium: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600, fontSize: 20.0),
          bodyLarge: TextStyle(color: AppColors.textColor, fontSize: 16.0),
          bodyMedium: TextStyle(color: AppColors.textColor, fontSize: 14.0),
          labelLarge: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold, fontSize: 16.0), // For button text
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: AppColors.borderColor.withOpacity(0.5), width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),
      ),
      // You can keep '/login' as the initial route, or change it to '/'
      // since '/' will now also point to LoginScreen.
      // For clarity, if LoginScreen is your absolute first screen, '/' is conventional.
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginScreen(), // Add this line to define the root route
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/agencySelection': (context) => const AgencySelectionScreen(),
        '/verificationResult': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>; 
          return VerificationResultScreen(routeArgs: args);
        },
      },
    );
  }
}