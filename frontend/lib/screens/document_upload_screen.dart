import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/loading_indicator.dart';

class DocumentUploadScreen extends StatefulWidget {
  final int declarationId;
  final String declarantName;

  const DocumentUploadScreen({
    super.key,
    required this.declarationId,
    required this.declarantName,
  });

  static const String routeName = '/documentUpload';

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final DocumentService _documentService = DocumentService();
  
  List<DeclarationDocument> _documents = [];
  Map<int, File?> _selectedFiles = {};
  Map<int, bool> _uploadingStatus = {};
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

  Future<void> _pickFile(int declarationDocumentId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'svg', 'heic'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles[declarationDocumentId] = File(result.files.single.path!);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection du fichier: $e';
      });
    }
  }

  Future<void> _uploadDocument(int declarationDocumentId) async {
    final file = _selectedFiles[declarationDocumentId];
    if (file == null) return;

    setState(() {
      _uploadingStatus[declarationDocumentId] = true;
      _errorMessage = null;
    });

    try {
      await _documentService.uploadDocument(widget.declarationId, declarationDocumentId, file);
      
      // Refresh the documents list to show updated status
      await _loadDocuments();
      
      setState(() {
        _uploadingStatus[declarationDocumentId] = false;
        _selectedFiles[declarationDocumentId] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadingStatus[declarationDocumentId] = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _uploadAllFiles() async {
    // Get all selected files that haven't been uploaded yet
    final filesToUpload = <int>[];
    
    for (final entry in _selectedFiles.entries) {
      if (entry.value != null) {
        final document = _documents.firstWhere(
          (doc) => doc.declarationDocumentId == entry.key,
          orElse: () => throw Exception('Document not found')
        );
        // Only upload if document is still pending or rejected
        if (document.status == DocumentStatus.pending || document.status == DocumentStatus.rejected) {
          filesToUpload.add(entry.key);
        }
      }
    }

    if (filesToUpload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fichier à télécharger'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Upload all files sequentially
    for (final documentId in filesToUpload) {
      await _uploadDocument(documentId);
    }
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
        return 'Uploadé'; // Changed from 'Téléchargé'
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
        return Icons.cloud_upload;
      case DocumentStatus.approved:
        return Icons.check_circle;
      case DocumentStatus.rejected:
        return Icons.error;
    }
  }

  bool _canNavigateNext() {
    final mandatoryDocs = _documents.where((doc) => doc.isMandatory);
    return mandatoryDocs.every((doc) => 
      doc.status == DocumentStatus.uploaded || 
      doc.status == DocumentStatus.approved
    );
  }

  void _navigateToNext() {
    if (_canNavigateNext()) {
      Navigator.pushReplacementNamed(
        context,
        '/documents-review',
        arguments: {
          'declarationId': widget.declarationId,
          'applicantName': widget.declarantName,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez télécharger tous les documents obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Requis', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/formulaireDownload',
              arguments: {
                'declarationId': widget.declarationId,
                'declarantName': widget.declarantName,
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.bgLightColor,
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const SizedBox()
                : Column(
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
                                'Veuillez télécharger tous les documents requis ci-dessous:',
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
                        child: RefreshIndicator(
                          onRefresh: _loadDocuments,
                          color: AppColors.primaryColor,
                          child: ListView.builder(
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              final isUploading = _uploadingStatus[document.declarationDocumentId] ?? false;
                              final selectedFile = _selectedFiles[document.declarationDocumentId];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Document header
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  document.documentName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      _getStatusIcon(document.status),
                                                      color: _getStatusColor(document.status),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded( // Wrap the status Text with Expanded
                                                      child: Text(
                                                        _getStatusText(document.status),
                                                        style: TextStyle(
                                                          color: _getStatusColor(document.status),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis, // Optional: handle very long text
                                                        maxLines: 2, // Optional: allow wrapping up to 2 lines
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Mandatory indicator
                                          if (document.isMandatory)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                'OBLIGATOIRE',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      
                                      // Rejection reason if applicable
                                      if (document.rejectionReason != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info, color: Colors.red, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Motif de rejet: ${document.rejectionReason}',
                                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 12),
                                      
                                      // File selection and display
                                      if (document.status == DocumentStatus.pending || document.status == DocumentStatus.rejected) ...[
                                        if (selectedFile != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.insert_drive_file, color: Colors.blue),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    selectedFile.path.split('/').last,
                                                    style: const TextStyle(color: Colors.blue),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedFiles[document.declarationDocumentId] = null;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () => _pickFile(document.declarationDocumentId),
                                              icon: const Icon(Icons.attach_file),
                                              label: const Text('Sélectionner un fichier'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primaryColor,
                                                side: BorderSide(color: AppColors.primaryColor),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ] else if (document.status == DocumentStatus.approved) ...[
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text(
                                                'Document approuvé',
                                                style: TextStyle(color: Colors.green),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Bottom buttons
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _canNavigateNext() ? () => _uploadAllFiles().then((_) => _navigateToNext()) : null,
                          icon: const Icon(Icons.upload_file, color: AppColors.whiteColor), // Ensure icon color contrasts with button
                          label: const Text(
                            'Tout Uploader et Continuer', // Changed button text
                            style: TextStyle(color: AppColors.whiteColor, fontSize: 16), // Ensure text color contrasts
                            textAlign: TextAlign.center, // Center align text
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjusted padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                            textStyle: const TextStyle( // Added textStyle here for consistency
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        ),
                      ),
                      
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.errorColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
}