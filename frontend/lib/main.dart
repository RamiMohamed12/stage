import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/login_screen.dart'; // Make sure LoginScreen is imported
import 'package:frontend/screens/agency_selection_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/verification_result_screen.dart';
import 'package:frontend/screens/document_upload_screen.dart'; // Import the correct screen
import 'package:frontend/screens/documents_review_screen.dart'; // Add this import
import 'package:frontend/screens/declaration/create_declaration_screen.dart'; // Add this import
import 'package:frontend/screens/formulaire_download_screen.dart'; // Add this import
import 'package:frontend/screens/notification_screen.dart'; // Add notification screen import
import 'package:frontend/screens/appointment_success_screen.dart'; // Add appointment success screen import
import 'package:frontend/screens/rejection_screen.dart';
import 'package:frontend/constants/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress the mouse tracker assertion error (known Flutter desktop bug)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('MouseTracker._shouldMarkStateDirty') ||
        details.exception.toString().contains('PointerAddedEvent') ||
        details.exception.toString().contains('PointerRemovedEvent')) {
      // Ignore this specific Flutter framework bug
      return;
    }
    // For other errors, use the default handler
    FlutterError.presentError(details);
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decujus Declaration App',
      debugShowCheckedModeBanner: false,
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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: AppColors.borderColor.withOpacity(0.5), width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),
      ),
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/agencySelection': (context) => const AgencySelectionScreen(),
        '/create-declaration': (context) => const CreateDeclarationScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/verificationResult': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>; 
          return VerificationResultScreen(routeArgs: args);
        },
        '/formulaireDownload': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId') || !args.containsKey('declarantName')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for formulaire download.'),
              ),
            );
          }
          return FormulaireDownloadScreen(
            declarationId: args['declarationId'],
            declarantName: args['declarantName'],
          );
        },
        '/documents-upload': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for documents upload.'),
              ),
            );
          }
          
          if (args.containsKey('declarantName')) {
            return DocumentUploadScreen(
              declarationId: args['declarationId'],
              declarantName: args['declarantName'],
            );
          } else {
            return DocumentUploadScreen(
              declarationId: args['declarationId'],
              declarantName: 'Déclarant',
            );
          }
        },
        '/documents-review': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for documents review.'),
              ),
            );
          }
          return DocumentsReviewScreen(
            declarationId: args['declarationId'],
            applicantName: args['applicantName'],
          );
        },
        '/appointment-success': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for appointment success.'),
              ),
            );
          }
          return AppointmentSuccessScreen(
            declarationId: args['declarationId'],
            applicantName: args['applicantName'],
          );
        },
        '/appointment-reject': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for appointment rejection.'),
              ),
            );
          }
          return RejectionScreen(
            declarationId: args['declarationId'],
            applicantName: args['applicantName'] ?? 'Utilisateur',
            rejectionReason: args['rejectionReason'],
          );
        },
        '/rejection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('declarationId')) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid or missing arguments for rejection screen.'),
              ),
            );
          }
          return RejectionScreen(
            declarationId: args['declarationId'],
            applicantName: args['applicantName'],
            rejectionReason: args['rejectionReason'],
          );
        },
      },
    );
  }
}