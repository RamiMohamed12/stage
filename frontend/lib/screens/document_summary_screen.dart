import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/widgets/loading_indicator.dart';

class DocumentSummaryScreen extends StatefulWidget {
  final int declarationId;
  final String declarantName;

  const DocumentSummaryScreen({
    super.key,
    required this.declarationId,
    required this.declarantName,
  });

  static const String routeName = '/documentSummary';

  @override
  State<DocumentSummaryScreen> createState() => _DocumentSummaryScreenState();
}

class _DocumentSummaryScreenState extends State<DocumentSummaryScreen> {
  final DocumentService _documentService = DocumentService();
  List<DeclarationDocument> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final documents = await _documentService.getDeclarationDocuments(widget.declarationId);
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToDeclarationCompletion() {
    Navigator.pushReplacementNamed(
      context,
      '/declarationCompletion',
      arguments: {
        'declarationId': widget.declarationId,
        'declarantName': widget.declarantName,
      },
    );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.uploaded:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.pending:
        return Colors.grey;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'Approuvé';
      case DocumentStatus.uploaded:
        return 'Téléchargé';
      case DocumentStatus.rejected:
        return 'Rejeté';
      case DocumentStatus.pending:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé des documents', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: AppColors.bgLightColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Déclaration pour: ${widget.declarantName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voici un résumé de tous vos documents téléchargés.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subTitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur: $_error',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadDocuments,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _documents.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun document trouvé.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _documents.length,
                              itemBuilder: (context, index) {
                                final document = _documents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.description,
                                      color: _getStatusColor(document.status),
                                    ),
                                    title: Text(
                                      document.documentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Statut: ${_getStatusText(document.status)}',
                                          style: TextStyle(
                                            color: _getStatusColor(document.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (document.uploadedAt != null)
                                          Text(
                                            'Téléchargé le: ${document.uploadedAt!.day}/${document.uploadedAt!.month}/${document.uploadedAt!.year}',
                                            style: TextStyle(
                                              color: AppColors.subTitleColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (document.rejectionReason != null)
                                          Text(
                                            'Raison du rejet: ${document.rejectionReason}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(document.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(document.status).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        document.isMandatory ? 'Obligatoire' : 'Optionnel',
                                        style: TextStyle(
                                          color: _getStatusColor(document.status),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToDeclarationCompletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Terminer la déclaration',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}