import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/loading_indicator.dart';

class DocumentsReviewScreen extends StatefulWidget {
  final int declarationId;
  final String? applicantName;

  const DocumentsReviewScreen({
    super.key,
    required this.declarationId,
    this.applicantName,
  });

  @override
  State<DocumentsReviewScreen> createState() => _DocumentsReviewScreenState();
}

class _DocumentsReviewScreenState extends State<DocumentsReviewScreen> {
  final DocumentService _documentService = DocumentService();
  final AuthService _authService = AuthService();
  List<DeclarationDocument> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final documents = await _documentService.getDeclarationDocuments(widget.declarationId);
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
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
        setState(() {
          _errorMessage = 'Erreur de déconnexion: ${e.toString()}';
        });
      }
    }
  }

  String _getReviewStatus() {
    if (_documents.isEmpty) return 'Aucun document';
    
    final hasRejected = _documents.any((doc) => doc.status == DocumentStatus.rejected);
    final hasUploaded = _documents.any((doc) => doc.status == DocumentStatus.uploaded);
    final allApproved = _documents.every((doc) => doc.status == DocumentStatus.approved);
    
    if (hasRejected) {
      return 'Documents à corriger';
    } else if (allApproved) {
      return 'Documents approuvés';
    } else if (hasUploaded) {
      return 'Documents en cours de révision';
    } else {
      return 'Documents en attente';
    }
  }

  Color _getReviewStatusColor() {
    if (_documents.isEmpty) return AppColors.grayColor;
    
    final hasRejected = _documents.any((doc) => doc.status == DocumentStatus.rejected);
    final hasUploaded = _documents.any((doc) => doc.status == DocumentStatus.uploaded);
    final allApproved = _documents.every((doc) => doc.status == DocumentStatus.approved);
    
    if (hasRejected) {
      return Colors.red;
    } else if (allApproved) {
      return Colors.green;
    } else if (hasUploaded) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getReviewStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getReviewStatusColor() == Colors.green 
                  ? Icons.check_circle 
                  : _getReviewStatusColor() == Colors.red
                    ? Icons.error
                    : Icons.schedule,
                size: 48,
                color: _getReviewStatusColor(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getReviewStatus(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getReviewStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.applicantName != null 
                ? 'Déclaration pour: ${widget.applicantName}'
                : 'Déclaration ID: ${widget.declarationId}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subTitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État des documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final document = _documents[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(document.status).withOpacity(0.2),
                    child: Icon(
                      _getStatusIcon(document.status),
                      color: _getStatusColor(document.status),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    document.documentName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getStatusText(document.status)),
                      if (document.rejectionReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Motif: ${document.rejectionReason}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: document.isMandatory
                    ? const Icon(Icons.star, color: Colors.red, size: 16)
                    : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasRejected = _documents.any((doc) => doc.status == DocumentStatus.rejected);
    final allApproved = _documents.every((doc) => doc.status == DocumentStatus.approved);
    
    return Column(
      children: [
        if (hasRejected) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/documents-upload',
                  arguments: {
                    'declarationId': widget.declarationId,
                    'documents': _documents.map((doc) => doc.toJson()).toList(),
                  },
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Corriger les documents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (allApproved) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/agencySelection',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Nouvelle déclaration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documents sous révision',
          style: TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.bgLightColor,
            child: _isLoading
                ? const SizedBox()
                : RefreshIndicator(
                    onRefresh: _loadDocuments,
                    color: AppColors.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatusCard(),
                          const SizedBox(height: 20),
                          
                          if (_documents.isNotEmpty) ...[
                            _buildDocumentsList(),
                            const SizedBox(height: 20),
                          ],
                          
                          _buildActionButtons(),
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Card(
                              color: Colors.red.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Info card
                          Card(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vos documents sont en cours de révision. Vous serez notifié une fois le processus terminé.',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          if (_isLoading)
            const LoadingIndicator(),
        ],
      ),
    );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.uploaded:
        return Colors.blue;
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'En attente';
      case DocumentStatus.uploaded:
        return 'En révision';
      case DocumentStatus.approved:
        return 'Approuvé';
      case DocumentStatus.rejected:
        return 'Rejeté';
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Icons.schedule;
      case DocumentStatus.uploaded:
        return Icons.visibility;
      case DocumentStatus.approved:
        return Icons.check_circle;
      case DocumentStatus.rejected:
        return Icons.cancel;
    }
  }
}