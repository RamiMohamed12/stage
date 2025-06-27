import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:frontend/models/death_cause.dart';
import 'package:frontend/models/decujus.dart';
import 'package:frontend/models/relationship.dart';
import 'package:frontend/services/death_cause_service.dart';
import 'package:frontend/services/declaration_service.dart';
import 'package:frontend/services/relationship_service.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/services/decujus_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class DecujusVerificationScreen extends StatefulWidget {
  final int agencyId;
  final String agencyName;

  const DecujusVerificationScreen({
    super.key,
    required this.agencyId,
    required this.agencyName,
  });

  static const String routeName = '/decujusVerification';

  @override
  State<DecujusVerificationScreen> createState() => _DecujusVerificationScreenState();
}

class _DecujusVerificationScreenState extends State<DecujusVerificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DecujusService _decujusService = DecujusService();
  final DeclarationService _declarationService = DeclarationService();
  final RelationshipService _relationshipService = RelationshipService();
  final DeathCauseService _deathCauseService = DeathCauseService();

  final TextEditingController _pensionNumberController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _verificationResult;
  Decujus? _verifiedDecujus;

  // State for declaration form
  bool _showDeclarationForm = false;
  List<Relationship> _relationships = [];
  Relationship? _selectedRelationship;
  List<DeathCause> _deathCauses = [];
  DeathCause? _selectedDeathCause;
  bool _isDeclarationLoading = false;
  String? _declarationErrorMessage;
  String? _declarationSuccessMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pensionNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyDecujus() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationResult = null;
      _verifiedDecujus = null;
      _showDeclarationForm = false; // Reset declaration form on new verification
      _declarationSuccessMessage = null;
      _declarationErrorMessage = null;
    });

    try {
      final result = await _decujusService.verifyDecujusByPensionNumberAndAgencyId(
        _pensionNumberController.text.trim(),
        widget.agencyId,
      );
      
      if (!mounted) return;
      
      setState(() {
        _verificationResult = result;
        if (result['exists'] == true && result['data'] != null) {
          _verifiedDecujus = Decujus.fromJson(result['data'] as Map<String, dynamic>);
          
          // Always allow verification to proceed to declaration form
          _showDeclarationForm = true;
          _fetchDeclarationDropdownData(); // Fetch data needed for the declaration
          
          if (!_verifiedDecujus!.isPensionActive) {
            // Update message for inactive pension but still allow declaration
            _verificationResult!['message'] = 'Ce decujus a été trouvé mais sa pension a été désactivée car il a déjà été déclaré précédemment. Vous pouvez toujours procéder à une nouvelle déclaration.';
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _fetchDeclarationDropdownData() async {
    setState(() {
      _isDeclarationLoading = true; // Use a separate loader for this part
      _declarationErrorMessage = null;
    });
    try {
      final causes = await _deathCauseService.getAllDeathCauses();
      final relationships = await _relationshipService.getAllRelationships();
      if (!mounted) return;
      setState(() {
        _deathCauses = causes;
        _relationships = relationships;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _declarationErrorMessage = "Erreur de chargement des données pour la déclaration: ${e.toString().replaceFirst('Exception: ', '')}";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeclarationLoading = false;
      });
    }
  }

  Future<void> _submitDeclaration() async {
    if (_selectedRelationship == null || _selectedDeathCause == null) {
      setState(() {
        _declarationErrorMessage = 'Veuillez sélectionner une relation et une cause de décès.';
      });
      return;
    }
    if (_verifiedDecujus == null) {
       setState(() {
        _declarationErrorMessage = 'Aucun decujus vérifié pour la déclaration.';
      });
      return;
    }

    setState(() {
      _isDeclarationLoading = true;
      _declarationErrorMessage = null;
      _declarationSuccessMessage = null;
    });

    try {
      final response = await _declarationService.createDeclaration(
        decujusPensionNumber: _verifiedDecujus!.pensionNumber,
        relationshipId: _selectedRelationship!.relationshipId,
        deathCauseId: _selectedDeathCause!.deathCauseId,
        declarationDate: DateTime.now(), // Always use current date and time
      );
      
      if (!mounted) return;
      
      // Handle the new response format with duplicate detection
      if (response['isDuplicate'] == true) {
        setState(() {
          _declarationErrorMessage = response['message'] ?? 'Une déclaration existe déjà pour ce decujus.';
          _showDeclarationForm = false; 
        });
      } else {
        setState(() {
          _declarationSuccessMessage = response['message'] ?? 'Déclaration enregistrée avec succès. La pension du decujus a été désactivée.';
          _showDeclarationForm = false;
        });
        
        // Navigate to formulaire download page first, then to documents upload
        if (response['declaration'] != null && response['declaration']['declaration_id'] != null) {
          Navigator.pushReplacementNamed(
            context,
            '/formulaireDownload',
            arguments: {
              'declarationId': response['declaration']['declaration_id'], // Keep as int
              'declarantName': '${_verifiedDecujus!.firstName} ${_verifiedDecujus!.lastName}',
            },
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _declarationErrorMessage = "Erreur d'enregistrement de la déclaration: ${e.toString().replaceFirst('Exception: ', '')}";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeclarationLoading = false;
      });
    }
  }


  void _resetForm() {
    setState(() {
      _verificationResult = null;
      _errorMessage = null;
      _pensionNumberController.clear();
      _verifiedDecujus = null;
      _showDeclarationForm = false;
      _selectedRelationship = null;
      _selectedDeathCause = null;
      _declarationErrorMessage = null;
      _declarationSuccessMessage = null;
      _relationships = [];
      _deathCauses = [];
    });
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      // If parsing fails, return the original string or a placeholder
      return dateString; 
    }
  }

  Widget _buildVerificationResultCard() {
    if (_verificationResult == null) return const SizedBox.shrink();
    
    final bool exists = _verificationResult!['exists'] == true;
    final bool isPensionActive = _verifiedDecujus?.isPensionActive ?? true;
    
    if (!exists) {
      // Show comprehensive not found screen
      return _buildNotFoundCard();
    }
    
    // Determine the card color and status based on verification result and pension status
    Color cardColor;
    Color textColor;
    Color borderColor;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;
    
    if (!isPensionActive) {
      // Decujus found but pension already deactivated (previously declared)
      cardColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange.shade700;
      borderColor = Colors.orange;
      statusIcon = Icons.history;
      statusTitle = "Décès déjà déclaré";
      statusMessage = "Ce décès a déjà été déclaré précédemment. La pension a été désactivée. Vous pouvez toujours procéder à une nouvelle déclaration si nécessaire.";
    } else {
      // Decujus found and pension is active (new declaration)
      cardColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green.shade700;
      borderColor = Colors.green;
      statusIcon = Icons.verified_user;
      statusTitle = "Décès confirmé - Nouveau";
      statusMessage = "Enregistrement trouvé et pension active. Vous pouvez procéder à la déclaration de décès.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with status
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: borderColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Decujus details section
          if (_verifiedDecujus != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: borderColor.withOpacity(0.3),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Informations du défunt",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, "Nom complet", 
                    "${_verifiedDecujus!.firstName} ${_verifiedDecujus!.lastName}".trim(),
                    textColor),
                  if (_verifiedDecujus!.dateOfBirth.isNotEmpty)
                    _buildInfoRow(Icons.cake, "Date de naissance", 
                      _formatDate(_verifiedDecujus!.dateOfBirth), textColor),
                  _buildInfoRow(Icons.credit_card, "Numéro de pension", 
                    _verifiedDecujus!.pensionNumber, textColor),
                  _buildInfoRow(
                    isPensionActive ? Icons.check_circle : Icons.cancel,
                    "Statut de la pension",
                    isPensionActive ? "Active" : "Désactivée",
                    isPensionActive ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotFoundCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Décès non enregistré",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Numéro de pension introuvable.",
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1,
            color: Colors.red.withOpacity(0.2),
          ),
          
          // Information section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Solutions :",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSuggestionItem(
                  Icons.edit_outlined,
                  "Vérifiez le numéro saisi",
                  Colors.red.shade600,
                ),
                _buildSuggestionItem(
                  Icons.business_outlined,
                  "Changez d'agence si nécessaire",
                  Colors.red.shade600,
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                // Primary action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Secondary action button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Go back to agency selection
                    },
                    icon: const Icon(Icons.business, size: 18),
                    label: const Text('Changer agence'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
          // Background Gradient
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
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildVerificationCard(),
                      ),
                    ),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Vérification Decujus",
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Agence: ${widget.agencyName}",
            style: TextStyle(
              color: AppColors.whiteColor.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    // If verification result shows "not found", return only the not found card
    // This card has its own reset logic, so it's a terminal state for this view.
    if (_verificationResult != null && _verificationResult!['exists'] == false) {
      return _buildNotFoundCard();
    }

    // If a declaration was just successfully submitted, show a success message.
    if (_declarationSuccessMessage != null) {
        return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 50),
                        const SizedBox(height: 16),
                        const Text('Succès', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.subTitleColor)),
                        const SizedBox(height: 8),
                        Text(
                            _declarationSuccessMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.grayColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Effectuer une autre déclaration'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.whiteColor,
                            ),
                        )
                    ],
                ),
            ),
        );
    }
    
    // Otherwise show the normal verification card content
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form( // The form should wrap the content
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only show title if we haven't verified yet
              if (_verificationResult == null) ...[
                const Text(
                  "Vérification par numéro de pension",
                  style: TextStyle(
                    color: AppColors.subTitleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Saisissez le numéro de pension du défunt",
                  style: TextStyle(
                    color: AppColors.grayColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            
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

              // Show verification form only if no verification has been attempted yet
              if (_verificationResult == null) ...[
                TextFormField(
                  controller: _pensionNumberController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters, // Suggest uppercase input
                  decoration: InputDecoration(
                    labelText: 'Numéro de Pension',
                    hintText: 'Entrez le numéro de pension',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  inputFormatters: [UpperCaseTextFormatter()], // Force uppercase
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de pension est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyDecujus,
                    icon: const Icon(Icons.search),
                    label: const Text('Vérifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Changer d\'agence'),
                  ),
                ),
              ],

              // Verification Result Display (only for found decujus)
              if (_verificationResult != null && _verificationResult!['exists'] == true)
                _buildVerificationResultCard(),

              // Declaration Form Section
              if (_showDeclarationForm && _verifiedDecujus != null)
                _buildDeclarationForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeclarationForm() {
    if (_isDeclarationLoading && _relationships.isEmpty && _deathCauses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enregistrer la Déclaration",
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdown<Relationship>(
            hintText: 'Votre lien de parenté avec le défunt',
            value: _selectedRelationship,
            items: _relationships,
            onChanged: (Relationship? newValue) {
              setState(() {
                _selectedRelationship = newValue;
              });
            },
            itemBuilder: (Relationship item) => Text(
              item.relationshipName.isNotEmpty ? item.relationshipName : "[Lien de parenté sans nom]",
            ),
            validator: (value) =>
                value == null ? 'Veuillez sélectionner une relation' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown<DeathCause>(
            hintText: 'Cause du Décès',
            value: _selectedDeathCause,
            items: _deathCauses,
            onChanged: (DeathCause? newValue) {
              setState(() {
                _selectedDeathCause = newValue;
              });
            },
            itemBuilder: (DeathCause item) => Text(
              item.causeName.isNotEmpty ? item.causeName : "[Cause de décès sans nom]",
            ),
            validator: (value) =>
                value == null ? 'Veuillez sélectionner une cause de décès' : null,
          ),
          const SizedBox(height: 24),
          if (_declarationErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(_declarationErrorMessage!,
                  style: const TextStyle(color: AppColors.errorColor, fontSize: 14)),
            ),
          if (_declarationSuccessMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(_declarationSuccessMessage!,
                  style: const TextStyle(color: Colors.green, fontSize: 14)),
            ),
          if (_isDeclarationLoading)
             const Center(child: Padding(
               padding: EdgeInsets.all(8.0),
               child: CircularProgressIndicator(),
             ))
          else if (_declarationSuccessMessage == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitDeclaration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('Enregistrer la Déclaration'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hintText,
    T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T item) itemBuilder,
    FormFieldValidator<T>? validator,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: const TextStyle(fontSize: 16, color: AppColors.grayColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      ),
      value: value,
      hint: Text(hintText, style: const TextStyle(color: AppColors.grayColor, fontSize: 16)),
      isExpanded: true,
      dropdownColor: AppColors.whiteColor,
      items: items.map<DropdownMenuItem<T>>((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: DefaultTextStyle(
            style: const TextStyle(color: AppColors.textColor, fontSize: 16),
            child: itemBuilder(item),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

// Add this formatter class at the end of the file
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
