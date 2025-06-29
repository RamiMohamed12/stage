import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class RejectionScreen extends StatelessWidget {
  final int declarationId;
  final String? applicantName;
  final String? rejectionReason;

  const RejectionScreen({
    super.key,
    required this.declarationId,
    this.applicantName,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclaration Rejetée', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.errorColor,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: AppColors.bgLightColor,
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 60,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Votre déclaration a été rejetée',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    applicantName != null
                        ? 'Déclaration pour: $applicantName'
                        : 'ID de la déclaration: $declarationId',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.subTitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
                    const Text(
                      'Motif du rejet:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rejectionReason!,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                  // ======================= [START] UX MODIFICATION =======================
                  const Text(
                    'Veuillez corriger les documents requis. Une fois corrigée, votre déclaration sera automatiquement resoumise pour évaluation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  // ======================== [END] UX MODIFICATION ========================
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/documents-upload',
                        arguments: {
                          'declarationId': declarationId,
                          'applicantName': applicantName,
                        },
                      );
                    },
                    icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
                    label: const Text('Corriger les documents', style: TextStyle(color: AppColors.whiteColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // Pop all the way back to the root/home screen
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}