import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

    // Allow picking a file only if not approved
    if (document.status == DocumentStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce document a déjà été approuvé et ne peut pas être modifié.')),
      );
      return;
    }

    try {
      // Use regular file picker instead of camera scanner to avoid crashes
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
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
          // Background Gradient (same as other screens)
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryColor, AppColors.bgDarkBlueColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildDocumentsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Loading Indicator Overlay
          if (_isLoading)
            const LoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor, size: 28),
              // MODIFIED: This now navigates back to the review screen for a better UX
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/documents-review',
                  arguments: {
                    'declarationId': widget.declarationId,
                    'applicantName': widget.declarantName,
                  },
                );
              },
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        const Icon(
          Icons.upload_file,
          color: Colors.white,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          "Documents Requis",
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.declarantName,
          style: TextStyle(
            color: AppColors.whiteColor.withOpacity(0.8),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Instructions",
              style: TextStyle(
                color: AppColors.subTitleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sélectionnez et téléchargez vos documents. Les champs avec * sont obligatoires.",
              style: TextStyle(
                color: AppColors.grayColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Error Display
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Documents List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = _documents[index];
                return _buildDocumentItem(document);
              },
            ),

            const SizedBox(height: 32),

            // Upload All Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canUploadAll() ? _uploadAllDocuments : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                ),
                icon: const Icon(Icons.cloud_upload, size: 20),
                label: const Text(
                  'Uploader et Continuer',
                  style: TextStyle(
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

  Widget _buildDocumentItem(DeclarationDocument document) {
    final isFileSelected = _selectedFiles.containsKey(document.declarationDocumentId);
    final isUploading = _uploadingStatus[document.declarationDocumentId] ?? false;
    final canSelectFile = document.status != DocumentStatus.approved;

    return GestureDetector(
      onTap: canSelectFile ? () => _pickFile(document.declarationDocumentId) : null,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: canSelectFile ? Colors.white : AppColors.bgLightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFileSelected 
                ? Colors.blue 
                : _getStatusColor(document.status, isFileSelected).withOpacity(0.3),
            width: isFileSelected ? 2 : 1,
          ),
          boxShadow: canSelectFile ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status/Upload Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(document.status, isFileSelected).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _getStatusIcon(document.status, isFileSelected),
                          color: _getStatusColor(document.status, isFileSelected),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: document.documentName,
                          children: [
                            if (document.isMandatory)
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(document.status, isFileSelected, document.rejectionReason),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(document.status, isFileSelected),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Action Indicator
                if (canSelectFile)
                  Icon(
                    isFileSelected ? Icons.edit : Icons.add_circle_outline,
                    color: isFileSelected ? Colors.orange : AppColors.primaryColor,
                    size: 24,
                  ),
              ],
            ),
            
            // Selected File Display
            if (isFileSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fichier sélectionné',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _selectedFiles[document.declarationDocumentId]!.path.split('/').last,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Tap to select hint for empty files
            if (!isFileSelected && canSelectFile) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 14,
                      color: AppColors.primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Toucher pour choisir',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryColor.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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