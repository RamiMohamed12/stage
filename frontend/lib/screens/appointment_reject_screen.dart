import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

class AppointmentRejectScreen extends StatefulWidget {
  final int declarationId;
  final String applicantName;
  final String? rejectionReason;

  const AppointmentRejectScreen({
    Key? key,
    required this.declarationId,
    required this.applicantName,
    this.rejectionReason,
  }) : super(key: key);

  @override
  State<AppointmentRejectScreen> createState() => _AppointmentRejectScreenState();
}

class _AppointmentRejectScreenState extends State<AppointmentRejectScreen> {
  AppointmentModel? appointment;
  bool isLoading = true;
  String? errorMessage;
  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    try {
      final appointmentData = await _appointmentService.getAppointmentByDeclarationId(widget.declarationId);
      if (!mounted) return;
      setState(() {
        appointment = AppointmentModel.fromJson(appointmentData);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Erreur lors du chargement du rendez-vous: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de déconnexion: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToDocumentsReview() {
    Navigator.pushReplacementNamed(
      context,
      '/documents-review',
      arguments: {
        'declarationId': widget.declarationId,
        'applicantName': widget.applicantName,
      },
    );
  }

  void _navigateToDocumentsUpload() {
    Navigator.pushReplacementNamed(
      context,
      '/documents-upload',
      arguments: {
        'declarationId': widget.declarationId,
        'declarantName': widget.applicantName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      appBar: AppBar(
        title: const Text('Rendez-vous Rejeté'),
        backgroundColor: AppColors.errorColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : _buildRejectionView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rejection header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cancel,
                  size: 80,
                  color: Colors.red.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rendez-vous Rejeté',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre demande de rendez-vous a été rejetée. Veuillez corriger les problèmes et soumettre à nouveau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Rejection reason
          if (widget.rejectionReason != null) ...[
            _buildSectionTitle('Motif du Rejet'),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Raison du rejet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.rejectionReason!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Appointment details (if available)
          if (appointment != null) ...[
            _buildSectionTitle('Détails du Rendez-vous Rejeté'),
            const SizedBox(height: 16),
            
            _buildDetailCard([
              _buildDetailRow(Icons.person, 'Demandeur', widget.applicantName),
              _buildDetailRow(Icons.calendar_today, 'Date et Heure', appointment!.formattedDateTime),
              _buildDetailRow(Icons.location_on, 'Lieu', appointment!.location),
              if (appointment!.notes != null && appointment!.notes!.isNotEmpty)
                _buildDetailRow(Icons.note, 'Notes', appointment!.notes!),
              _buildDetailRow(Icons.info, 'Statut', appointment!.statusDisplay),
            ]),
            const SizedBox(height: 32),
          ],

          // Next steps
          _buildSectionTitle('Prochaines Étapes'),
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Que faire maintenant ?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._buildNextSteps(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textColor,
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grayColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNextSteps() {
    final steps = [
      'Vérifiez vos documents et corrigez les problèmes mentionnés',
      'Téléchargez les documents manquants ou corrigés',
      'Attendez la nouvelle révision de votre dossier',
      'Un nouveau rendez-vous sera planifié automatiquement après approbation',
      'Vous recevrez une notification dès que votre dossier sera approuvé',
    ];

    return steps.map((step) => Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - Fix documents
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToDocumentsUpload,
            icon: const Icon(Icons.edit),
            label: const Text('Corriger mes Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary action - Review current documents
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _navigateToDocumentsReview,
            icon: const Icon(Icons.visibility),
            label: const Text('Voir l\'État de mes Documents'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tertiary action - Go to notifications
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications),
            label: const Text('Voir mes Notifications'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Logout button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Se Déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorColor,
              side: BorderSide(color: AppColors.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}