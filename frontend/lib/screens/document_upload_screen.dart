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
    print('🔵 UPLOAD SCREEN: Upload button pressed for document ID: $declarationDocumentId');
    
    final file = _selectedFiles[declarationDocumentId];
    if (file == null) {
      print('🔴 UPLOAD SCREEN: No file selected for document ID: $declarationDocumentId');
      return;
    }

    print('🔵 UPLOAD SCREEN: File selected: ${file.path}');
    print('🔵 UPLOAD SCREEN: Declaration ID: ${widget.declarationId}');

    setState(() {
      _uploadingStatus[declarationDocumentId] = true;
      _errorMessage = null;
    });

    print('🔵 UPLOAD SCREEN: Starting upload process...');

    try {
      await _documentService.uploadDocument(widget.declarationId, declarationDocumentId, file);
      
      print('🟢 UPLOAD SCREEN: Upload completed successfully');
      
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
      print('🔴 UPLOAD SCREEN: Upload failed with error: $e');
      setState(() {
        _uploadingStatus[declarationDocumentId] = false;
        _errorMessage = e.toString();
      });
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
        return 'Téléchargé';
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
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/agencySelection', 
        (route) => false,
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      document.documentName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (document.isMandatory) ...[
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        '*',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
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
                                                    Text(
                                                      _getStatusText(document.status),
                                                      style: TextStyle(
                                                        color: _getStatusColor(document.status),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                                                  style: const TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
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
                                        const SizedBox(height: 8),
                                      ],
                                      // Use LayoutBuilder to determine available width
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isNarrow = constraints.maxWidth < 200;
                                          
                                          if (document.status != DocumentStatus.approved) {
                                            if (isNarrow) {
                                              // Stack buttons vertically on very narrow screens
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  SizedBox(
                                                    height: 36,
                                                    child: ElevatedButton.icon(
                                                      icon: const Icon(Icons.attach_file, color: AppColors.whiteColor, size: 14),
                                                      label: Text(
                                                        selectedFile == null ? 'Fichier' : 'Changer',
                                                        style: const TextStyle(color: AppColors.whiteColor, fontSize: 11),
                                                      ),
                                                      onPressed: () => _pickFile(document.declarationDocumentId),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primaryColor,
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFile != null) ...[
                                                    const SizedBox(height: 4),
                                                    SizedBox(
                                                      height: 36,
                                                      child: ElevatedButton.icon(
                                                        icon: isUploading
                                                            ? const SizedBox(
                                                                width: 12,
                                                                height: 12,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  color: AppColors.whiteColor,
                                                                ),
                                                              )
                                                            : const Icon(Icons.cloud_upload, color: AppColors.whiteColor, size: 14),
                                                        label: Text(
                                                          isUploading ? 'Upload...' : 'Upload',
                                                          style: const TextStyle(color: AppColors.whiteColor, fontSize: 11),
                                                        ),
                                                        onPressed: isUploading ? null : () => _uploadDocument(document.declarationDocumentId),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            } else {
                                              // Use Row layout for wider screens
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    flex: selectedFile == null ? 1 : 2,
                                                    child: SizedBox(
                                                      height: 36,
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(Icons.attach_file, color: AppColors.whiteColor, size: 14),
                                                        label: Text(
                                                          selectedFile == null ? 'Fichier' : 'Changer',
                                                          style: const TextStyle(color: AppColors.whiteColor, fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        onPressed: () => _pickFile(document.declarationDocumentId),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppColors.primaryColor,
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFile != null) ...[
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      flex: 3,
                                                      child: SizedBox(
                                                        height: 36,
                                                        child: ElevatedButton.icon(
                                                          icon: isUploading
                                                              ? const SizedBox(
                                                                  width: 12,
                                                                  height: 12,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth: 2,
                                                                    color: AppColors.whiteColor,
                                                                  ),
                                                                )
                                                              : const Icon(Icons.cloud_upload, color: AppColors.whiteColor, size: 14),
                                                          label: Text(
                                                            isUploading ? 'Upload...' : 'Upload',
                                                            style: const TextStyle(color: AppColors.whiteColor, fontSize: 11),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          onPressed: isUploading ? null : () => _uploadDocument(document.declarationDocumentId),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            }
                                          } else {
                                            // Approved document state
                                            return Container(
                                              height: 36,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Approuvé',
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canNavigateNext() ? _navigateToNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Terminer',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.errorColor),
                          textAlign: TextAlign.center,
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