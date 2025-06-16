import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/constants/colors.dart';
import 'dart:io';
import 'dart:async';
import 'package:frontend/screens/documents_review_screen.dart';

class DocumentsUploadScreen extends StatefulWidget {
  final dynamic declarationId; // Accept any type (int or String)
  final List<dynamic> documents;

  const DocumentsUploadScreen({
    super.key,
    required this.declarationId,
    required this.documents,
  });

  @override
  State<DocumentsUploadScreen> createState() => _DocumentsUploadScreenState();
}

class _DocumentsUploadScreenState extends State<DocumentsUploadScreen> {
  final DocumentService _documentService = DocumentService();
  List<DeclarationDocument> _declarationDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<int, PlatformFile?> _selectedFiles = {}; // Store selected files for each document
  Map<int, bool> _uploadingFiles = {}; // Track upload status for each document

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: Currently on DocumentsUploadScreen');
    print('🔍 DEBUG: Declaration ID: ${widget.declarationId}');
    print('🔍 DEBUG: Raw documents data: ${widget.documents}');
    _initializeDocuments();
    // Set up periodic refresh to check for status updates
    _setupPeriodicRefresh();
  }

  Timer? _refreshTimer;

  void _setupPeriodicRefresh() {
    // Refresh every 10 seconds to check for status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshDocuments();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializeDocuments() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Parse documents from the passed data
      if (widget.documents.isNotEmpty) {
        _declarationDocuments = widget.documents
            .map((doc) {
              if (doc is Map<String, dynamic>) {
                return DeclarationDocument.fromJson(doc);
              } else {
                print('🚨 DEBUG: Invalid document format: $doc');
                return null;
              }
            })
            .where((doc) => doc != null)
            .cast<DeclarationDocument>()
            .toList();
      }

      print('🔍 DEBUG: Parsed ${_declarationDocuments.length} documents');
      for (var doc in _declarationDocuments) {
        print('🔍 DEBUG: Document: ${doc.documentName}, Status: ${doc.status}, Mandatory: ${doc.isMandatory}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('🚨 DEBUG: Error initializing documents: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des documents: $e';
      });
    }
  }

  Future<void> _pickFile(int declarationDocumentId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'pdf', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles[declarationDocumentId] = result.files.single;
        });
        print('🔍 DEBUG: File selected for document $declarationDocumentId: ${result.files.single.name}');
      }
    } catch (e) {
      print('🚨 DEBUG: Error picking file: $e');
      setState(() {
        _errorMessage = 'Erreur lors de la sélection du fichier: $e';
      });
    }
  }

  Future<void> _uploadFile(DeclarationDocument document) async {
    final file = _selectedFiles[document.declarationDocumentId];
    if (file == null || file.path == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner un fichier pour ${document.documentName}';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _uploadingFiles[document.declarationDocumentId] = true; // Mark as uploading
      });

      print('🔍 DEBUG: Uploading file for document: ${document.documentName}');
      print('🔍 DEBUG: Declaration Document ID: ${document.declarationDocumentId}');
      print('🔍 DEBUG: File path: ${file.path}');
      print('🔍 DEBUG: File name: ${file.name}');
      print('🔍 DEBUG: File size: ${file.size} bytes');
      
      // Convert PlatformFile to File
      final dartFile = File(file.path!);
      
      await _documentService.uploadDocument(
        int.parse(widget.declarationId.toString()), // Pass declarationId
        document.declarationDocumentId,
        dartFile,
      );

      print('🔍 DEBUG: Upload successful for document ID: ${document.declarationDocumentId}');

      // Refresh the documents list after upload
      _refreshDocuments();
      
      setState(() {
        _selectedFiles.remove(document.declarationDocumentId);
        _uploadingFiles[document.declarationDocumentId] = false; // Mark as not uploading
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document ${document.documentName} téléchargé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('🚨 DEBUG: Error uploading file: $e');
      setState(() {
        _errorMessage = 'Erreur lors du téléchargement: $e';
        _uploadingFiles[document.declarationDocumentId] = false; // Mark as not uploading
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDocuments() async {
    try {
      final documents = await _documentService.getDeclarationDocuments(
        int.parse(widget.declarationId.toString())
      );
      setState(() {
        _declarationDocuments = documents;
      });
    } catch (e) {
      print('🚨 DEBUG: Error refreshing documents: $e');
    }
  }

  bool _canNavigateNext() {
    final mandatoryDocs = _declarationDocuments.where((doc) => doc.isMandatory).toList();
    return mandatoryDocs.every((doc) => 
      doc.status == DocumentStatus.uploaded || 
      doc.status == DocumentStatus.approved
    );
  }

  void _navigateToNext() {
    // Check if all mandatory documents are uploaded
    final mandatoryDocs = _declarationDocuments.where((doc) => doc.isMandatory).toList();
    final allMandatoryUploaded = mandatoryDocs.every((doc) => 
      doc.status == DocumentStatus.uploaded || 
      doc.status == DocumentStatus.approved
    );

    if (allMandatoryUploaded) {
      // Navigate to review screen instead of agency selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentsReviewScreen(
            declarationId: int.parse(widget.declarationId.toString()),
            applicantName: null, // You can pass user name if available
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Télécharger les Documents', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Debug info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 DEBUG INFO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Text('Screen: DocumentsUploadScreen'),
                      Text('Declaration ID: ${widget.declarationId}'),
                      Text('Documents Count: ${_declarationDocuments.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.errorColor),
                    ),
                  ),

                const SizedBox(height: 16),

                // Documents list
                Expanded(
                  child: _declarationDocuments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: AppColors.grayColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun document trouvé',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.grayColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les documents requis n\'ont pas pu être chargés.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grayColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _declarationDocuments.length,
                          itemBuilder: (context, index) {
                            final document = _declarationDocuments[index];
                            final selectedFile = _selectedFiles[document.declarationDocumentId];
                            final uploading = _uploadingFiles[document.declarationDocumentId] ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          document.isMandatory ? Icons.star : Icons.star_border,
                                          color: document.isMandatory ? Colors.red : AppColors.grayColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            document.documentName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Status indicator
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(document.status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusText(document.status),
                                            style: TextStyle(
                                              color: _getStatusColor(document.status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (document.isMandatory)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
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
                                    
                                    const SizedBox(height: 12),
                                    
                                    // File selection and upload
                                    if (document.status == DocumentStatus.pending) ...[
                                      if (selectedFile != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.attach_file, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  selectedFile.name,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, size: 16),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedFiles.remove(document.declarationDocumentId);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: uploading ? null : () => _uploadFile(document),
                                          icon: const Icon(Icons.upload, size: 16),
                                          label: const Text('Télécharger'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryColor,
                                          ),
                                        ),
                                      ] else ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _pickFile(document.declarationDocumentId),
                                          icon: const Icon(Icons.folder_open, size: 16),
                                          label: const Text('Choisir un fichier'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ] else if (document.status == DocumentStatus.uploaded) ...[
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 8),
                                          Text('Document téléchargé - En attente de validation'),
                                        ],
                                      ),
                                    ] else if (document.status == DocumentStatus.approved) ...[
                                      const Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green, size: 16),
                                          SizedBox(width: 8),
                                          Text('Document approuvé'),
                                        ],
                                      ),
                                    ] else if (document.status == DocumentStatus.rejected) ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.cancel, color: Colors.red, size: 16),
                                              SizedBox(width: 8),
                                              Text('Document rejeté'),
                                            ],
                                          ),
                                          if (document.rejectionReason != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Raison: ${document.rejectionReason}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _pickFile(document.declarationDocumentId),
                                            icon: const Icon(Icons.refresh, size: 16),
                                            label: const Text('Télécharger à nouveau'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Navigation button
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _canNavigateNext() ? _navigateToNext : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Terminer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
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
        return 'EN ATTENTE';
      case DocumentStatus.uploaded:
        return 'TÉLÉCHARGÉ';
      case DocumentStatus.approved:
        return 'APPROUVÉ';
      case DocumentStatus.rejected:
        return 'REJETÉ';
    }
  }
}