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
    final document = _documents.firstWhere((d) => d.declarationDocumentId == declarationDocumentId);

    // Allow picking a file only if the document is not yet approved.
    if (document.status == DocumentStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce document a déjà été approuvé et ne peut pas être modifié.')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'svg', 'heic'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles[declarationDocumentId] = File(result.files.single.path!);
          // Reset error message when a file is picked
          _errorMessage = null;
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
        _errorMessage = 'Erreur lors de l\'upload du document: $e';
      });
    }
  }

  Future<void> _uploadAllDocuments() async {
    final mandatoryDocuments = _documents.where((d) => d.isMandatory).toList();
    final missingDocuments = mandatoryDocuments.where((d) {
      final isPending = d.status == DocumentStatus.pending || d.status == DocumentStatus.rejected;
      final noFileSelected = _selectedFiles[d.declarationDocumentId] == null;
      return isPending && noFileSelected;
    }).toList();

    if (missingDocuments.isNotEmpty) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner tous les documents obligatoires.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      for (final entry in _selectedFiles.entries) {
        await _uploadDocument(entry.key);
      }

      // Check for any upload errors before navigating
      if (_errorMessage == null) {
        Navigator.pushReplacementNamed(
          context,
          '/documents-review',
          arguments: {
            'declarationId': widget.declarationId,
            'applicantName': widget.declarantName,
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _canUploadAll() {
    final mandatoryDocuments = _documents.where((d) => d.isMandatory).toList();
    if (mandatoryDocuments.isEmpty) return _selectedFiles.isNotEmpty;

    return mandatoryDocuments.every((d) {
      // Can upload if the document is already approved or uploaded
      if (d.status == DocumentStatus.approved || d.status == DocumentStatus.uploaded) {
        return true;
      }
      // Or if a file has been selected for it
      return _selectedFiles.containsKey(d.declarationDocumentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournir les Documents', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.bgLightColor,
            padding: const EdgeInsets.all(20.0),
            child: _isLoading && _documents.isEmpty
                ? const SizedBox()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Déclaration pour: ${widget.declarantName}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez fournir les documents requis. Les champs marqués d\'une * sont obligatoires.',
                        style: TextStyle(fontSize: 16, color: AppColors.subTitleColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final document = _documents[index];
                            final isFileSelected = _selectedFiles.containsKey(document.declarationDocumentId);
                            final isUploading = _uploadingStatus[document.declarationDocumentId] ?? false;
                            final canSelectFile = document.status != DocumentStatus.approved;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: isUploading
                                    ? const CircularProgressIndicator()
                                    : Icon(
                                        _getStatusIcon(document.status, isFileSelected),
                                        color: _getStatusColor(document.status, isFileSelected),
                                      ),
                                title: Text.rich(
                                  TextSpan(
                                    text: document.documentName,
                                    children: [
                                      if (document.isMandatory)
                                        const TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  _getStatusText(document.status, isFileSelected, document.rejectionReason),
                                  style: TextStyle(color: _getStatusColor(document.status, isFileSelected)),
                                ),
                                trailing: canSelectFile
                                    ? TextButton(
                                        onPressed: () => _pickFile(document.declarationDocumentId),
                                        child: Text(isFileSelected ? 'Changer' : 'Choisir'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.errorColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _canUploadAll() ? _uploadAllDocuments : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                        ),
                        child: const Text('Tout Uploader et Continuer', style: TextStyle(color: AppColors.whiteColor)),
                      ),
                    ],
                  ),
          ),
          if (_isLoading && _documents.isNotEmpty)
            const LoadingIndicator(),
        ],
      ),
    );
  }

  Color _getStatusColor(DocumentStatus status, bool isFileSelected) {
    if (isFileSelected) return Colors.blue;
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

  String _getStatusText(DocumentStatus status, bool isFileSelected, String? rejectionReason) {
    if (isFileSelected) return 'Prêt à uploader';
    switch (status) {
      case DocumentStatus.pending:
        return 'En attente de document';
      case DocumentStatus.uploaded:
        return 'En révision';
      case DocumentStatus.approved:
        return 'Approuvé';
      case DocumentStatus.rejected:
        return 'Rejeté: ${rejectionReason ?? 'Raison non spécifiée'}';
    }
  }

  IconData _getStatusIcon(DocumentStatus status, bool isFileSelected) {
    if (isFileSelected) return Icons.attach_file;
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