import 'package:flutter/material.dart';
import 'package:frontend/models/decujus_verification_result.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart'; // Ensure intl is imported
// import 'package:lottie/lottie.dart'; // Lottie can be added later if specific animations are used

class VerificationResultScreen extends StatefulWidget {
  final Map<String, dynamic> routeArgs;

  const VerificationResultScreen({super.key, required this.routeArgs});

  static const String routeName = '/verificationResult';

  @override
  State<VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> {
  late DecujusVerificationResult _result;
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _result = widget.routeArgs['result'] as DecujusVerificationResult;
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de déconnexion: ${e.toString()}';
        });
      }
    }
  }

  void _declareAnother() {
    Navigator.pushNamedAndRemoveUntil(context, '/agencySelection', (route) => false);
  }

  // Helper to parse date string to DateTime, returns null if parsing fails
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr); // Assumes YYYY-MM-DD format from backend
    } catch (e) {
      // print("Error parsing date: $dateStr, $e"); // Optional: for debugging
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = _result.success;
    // Use result.message directly as it's non-nullable in the model
    final String message = _result.message;

    Widget decujusDetailsWidget = const SizedBox.shrink();
    if (isSuccess && _result.decujus != null) {
      final decujus = _result.decujus!;
      final DateTime? dob = _parseDate(decujus.dateOfBirth);
      final String formattedDob = dob != null ? DateFormat('dd/MM/yyyy').format(dob) : 'N/A';

      decujusDetailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations du Défunt:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          const SizedBox(height: 8),
          Text('Nom: ${decujus.lastName}', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
          Text('Prénom: ${decujus.firstName}', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
          Text('N° de Pension: ${decujus.pensionNumber}', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
          Text('Date de Naissance: $formattedDob', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat de la Vérification', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: isSuccess ? AppColors.successColor : AppColors.errorColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: AppColors.bgLightColor,
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? AppColors.successColor : AppColors.errorColor,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.successColor : AppColors.errorColor,
                  ),
                ),
                const SizedBox(height: 15),
                if (isSuccess && _result.decujus != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      color: AppColors.whiteColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: decujusDetailsWidget,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.whiteColor),
                  label: const Text('Déclarer un Autre Décès', style: TextStyle(color: AppColors.whiteColor, fontSize: 16)),
                  onPressed: _declareAnother,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.primaryColor),
                  label: const Text('Se Déconnecter', style: TextStyle(color: AppColors.primaryColor, fontSize: 16)),
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.errorColor, fontSize: 16),
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
