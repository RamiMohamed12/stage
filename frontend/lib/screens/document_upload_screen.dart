// lib/screens/DocumentUploadScreen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/services/scanService.dart' as scanService;
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/loading_indicator.dart';

// Helper class to store the file and whether it was scanned.
class _SelectedFile {
  final File file;
  // We keep this flag to know the origin, even if the upload service doesn't need it.
  // It could be useful for analytics in the future.
  final bool isScanned;

  _SelectedFile(this.file, {this.isScanned = false});
}

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
  Map<int, _SelectedFile> _selectedFiles = {};
  Map<int, bool> _uploadingStatus = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final documents =
          await _documentService.getDeclarationDocuments(widget.declarationId);
      if (mounted) {
        setState(() {
          _documents = documents;
          if (!isRefresh) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isRefresh) {
            _isLoading = false;
          }
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickFile(int declarationDocumentId) async {
    final document =
        _documents.firstWhere((d) => d.declarationDocumentId == declarationDocumentId);

    if (document.status == DocumentStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Ce document a déjà été approuvé et ne peut pas être modifié.')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'svg',
          'heic'
        ],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles[declarationDocumentId] =
              _SelectedFile(File(result.files.single.path!));
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection du fichier: $e';
      });
    }
  }

  Future<void> _scanDocument(int declarationDocumentId) async {
     final document =
        _documents.firstWhere((d) => d.declarationDocumentId == declarationDocumentId);

    if (document.status == DocumentStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Ce document a déjà été approuvé et ne peut pas être modifié.')),
      );
      return;
    }

    try {
      String filePath = await scanService.getImageBalayage(lang: "fr");

      if (filePath.isNotEmpty && mounted) {
        setState(() {
          _selectedFiles[declarationDocumentId] =
              _SelectedFile(File(filePath), isScanned: true);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du scan: $e';
        });
      }
    }
  }
  
  Future<void> _uploadSingleDocument(int declarationDocumentId) async {
    final selectedFile = _selectedFiles[declarationDocumentId];
    if (selectedFile == null) return;

    setState(() {
      _uploadingStatus[declarationDocumentId] = true;
      _errorMessage = null;
    });

    try {
      // [MODIFICATION] The call to the service is now simpler.
      // We no longer pass the 'isScanned' flag.
      await _documentService.uploadDocument(
        widget.declarationId,
        declarationDocumentId,
        selectedFile.file,
      );

      await _loadDocuments(isRefresh: true);

      if (mounted) {
        setState(() {
          _uploadingStatus[declarationDocumentId] = false;
          _selectedFiles.remove(declarationDocumentId);
        });
      }
      
      if (await selectedFile.file.exists()) {
        await selectedFile.file.delete();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingStatus[declarationDocumentId] = false;
          // Don't set the global error message here; let the calling function handle it.
        });
      }
      // Re-throw the error so _uploadAllDocuments knows something went wrong.
      throw e;
    }
  }

  Future<void> _uploadAllDocuments() async {
    final mandatoryDocuments = _documents.where((d) => d.isMandatory).toList();
    final missingDocuments = mandatoryDocuments.where((d) {
      final isPending =
          d.status == DocumentStatus.pending || d.status == DocumentStatus.rejected;
      final noFileSelected = _selectedFiles[d.declarationDocumentId] == null;
      return isPending && noFileSelected;
    }).toList();

    if (missingDocuments.isNotEmpty) {
      setState(() {
        _errorMessage =
            'Veuillez sélectionner tous les documents obligatoires.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? errorDuringUpload;

    try {
      final keysToUpload = _selectedFiles.keys.toList();
      for (final key in keysToUpload) {
        if (!mounted) continue;
        try {
          await _uploadSingleDocument(key);
        } catch (e) {
          errorDuringUpload = e.toString();
          break; 
        }
      }
    } catch (e) {
       errorDuringUpload = 'Une erreur inattendue est survenue: $e';
    } finally {
      if (!mounted) return;

      if (errorDuringUpload != null) {
        setState(() {
          _errorMessage = errorDuringUpload;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents téléchargés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/documents-review',
          arguments: {
            'declarationId': widget.declarationId,
            'applicantName': widget.declarantName,
          },
        );
      }
    }
  }

  bool _canUploadAll() {
    final mandatoryDocuments = _documents.where((d) => d.isMandatory).toList();
    if (_selectedFiles.isEmpty) {
      return false;
    }
    
    return mandatoryDocuments.every((d) {
      if (d.status == DocumentStatus.approved || d.status == DocumentStatus.uploaded) {
        return true;
      }
      return _selectedFiles.containsKey(d.declarationDocumentId);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
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
          if (_isLoading) const LoadingIndicator(),
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
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.whiteColor, size: 28),
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
                    const Icon(Icons.error_outline,
                        color: AppColors.errorColor, size: 18),
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = _documents[index];
                return _buildDocumentItem(document);
              },
            ),
            const SizedBox(height: 32),
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
                  disabledBackgroundColor:
                      AppColors.primaryColor.withOpacity(0.5),
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
    final isFileSelected =
        _selectedFiles.containsKey(document.declarationDocumentId);
    final isUploading = _uploadingStatus[document.declarationDocumentId] ?? false;
    final canSelectFile = document.status != DocumentStatus.approved;

    return GestureDetector(
      onTap:
          canSelectFile ? () => _pickFile(document.declarationDocumentId) : null,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: canSelectFile ? Colors.white : AppColors.bgLightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFileSelected
                ? Colors.blue
                : _getStatusColor(document.status, isFileSelected)
                    .withOpacity(0.3),
            width: isFileSelected ? 2 : 1,
          ),
          boxShadow: canSelectFile
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(document.status, isFileSelected)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _getStatusIcon(document.status, isFileSelected),
                          color:
                              _getStatusColor(document.status, isFileSelected),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
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
                        _getStatusText(document.status, isFileSelected,
                            document.rejectionReason),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              _getStatusColor(document.status, isFileSelected),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (canSelectFile)
                  Icon(
                    isFileSelected ? Icons.edit : Icons.add_circle_outline,
                    color: isFileSelected ? Colors.orange : AppColors.primaryColor,
                    size: 24,
                  ),
                if (canSelectFile)
                  IconButton(
                      onPressed: () => _scanDocument(document.declarationDocumentId),
                      icon: const Icon(
                        Icons.document_scanner,
                        color: AppColors.primaryColor,
                        size: 24,
                      ))
              ],
            ),
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
                            _selectedFiles[document.declarationDocumentId]!
                                .file
                                .path
                                .split('/')
                                .last,
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
            if (!isFileSelected && canSelectFile) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

  String _getStatusText(
      DocumentStatus status, bool isFileSelected, String? rejectionReason) {
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