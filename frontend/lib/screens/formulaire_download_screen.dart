import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/constants/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';

class FormulaireDownloadScreen extends StatefulWidget {
  final int declarationId;
  final String declarantName;

  const FormulaireDownloadScreen({
    super.key,
    required this.declarationId,
    required this.declarantName,
  });

  static const String routeName = '/formulaireDownload';

  @override
  State<FormulaireDownloadScreen> createState() => _FormulaireDownloadScreenState();
}

class _FormulaireDownloadScreenState extends State<FormulaireDownloadScreen> {
  bool _isDownloading = false;
  bool _hasDownloaded = false;

  final TokenService _tokenService = TokenService();

  Future<void> _downloadFormulaire() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Get the authentication token
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification non trouvé. Veuillez vous reconnecter.');
      }

      // Make authenticated HTTP request to download the formulaire
      final response = await http.get(
        Uri.parse('${ApiEndpoints.declarations}/formulaire/${widget.declarationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Get the downloads directory - use app-specific directory
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory(); // App-specific external path
          if (directory != null) {
            // Create a Downloads folder within app directory if you prefer
            final downloadsDir = Directory('${directory.path}/Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            directory = downloadsDir;
          }
        } else {
          // For iOS and other platforms
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final fileName = 'formulaire_declaration_${widget.declarationId}.zip';
          final file = File('${directory.path}/$fileName');
          
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            _hasDownloaded = true;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Formulaire téléchargé: $fileName\nEmplacement: ${directory.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Impossible d\'accéder au répertoire de téléchargement');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé à cette déclaration.');
      } else if (response.statusCode == 404) {
        throw Exception('Formulaire non trouvé pour cette déclaration.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _navigateToDocumentUpload() {
    Navigator.pushReplacementNamed(
      context,
      '/documents-upload',
      arguments: {
        'declarationId': widget.declarationId,
        'declarantName': widget.declarantName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulaire à télécharger', style: TextStyle(color: AppColors.whiteColor)),
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
                      'Téléchargez le formulaire pré-rempli, imprimez-le, signez-le et scannez-le pour le télécharger ensuite.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subTitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description,
                      size: 80,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Formulaire de déclaration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cliquez sur "Télécharger" pour obtenir votre formulaire pré-rempli.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subTitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadFormulaire,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.whiteColor,
                                ),
                              )
                            : const Icon(Icons.download, color: AppColors.whiteColor),
                        label: Text(
                          _isDownloading ? 'Téléchargement...' : 'Télécharger le formulaire',
                          style: const TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    if (_hasDownloaded) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Formulaire téléchargé! Imprimez-le, signez-le et scannez-le.',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToDocumentUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Continuer vers les documents',
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