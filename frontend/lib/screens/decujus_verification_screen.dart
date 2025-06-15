import 'package:flutter/material.dart';
import 'package:frontend/models/death_cause.dart';
import 'package:frontend/models/decujus.dart';
import 'package:frontend/models/relationship.dart';
import 'package:frontend/services/death_cause_service.dart';
import 'package:frontend/services/declaration_service.dart';
import 'package:frontend/services/relationship_service.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/services/decujus_service.dart';
import 'package:frontend/constants/colors.dart';

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
          if (_verifiedDecujus!.isPensionActive) {
            _showDeclarationForm = true;
            _fetchDeclarationDropdownData(); // Fetch data needed for the declaration
          } else {
            // Pension is not active, meaning decujus might have been declared already or other reasons
            _verificationResult!['message'] = 'Ce decujus a déjà été déclaré ou la pension est inactive. Vérification des documents...';
            // TODO: Later, navigate to document status/upload screen
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
        
        // Navigate to documents upload page with the declaration ID
        if (response['declaration'] != null && response['declaration']['declaration_id'] != null) {
          Navigator.pushReplacementNamed(
            context,
            '/documents-upload',
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
              "Vérification par numéro de pension",
              style: TextStyle(
                color: AppColors.subTitleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saisissez le numéro de pension du défunt",
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

            // Verification Result Display
            if (_verificationResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _verificationResult!['exists'] == true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _verificationResult!['exists'] == true
                        ? Colors.green
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _verificationResult!['exists'] == true
                              ? Icons.check_circle
                              : Icons.info,
                          color: _verificationResult!['exists'] == true
                              ? Colors.green
                              : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _verificationResult!['exists'] == true
                                ? "Decujus trouvé ✓"
                                : "Decujus non trouvé",
                            style: TextStyle(
                              color: _verificationResult!['exists'] == true
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verificationResult!['message'] ?? '',
                      style: TextStyle(
                        color: _verificationResult!['exists'] == true
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                    if (_verificationResult!['exists'] == true && _verificationResult!['data'] != null)
                      ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (_verifiedDecujus != null) ...[
                           Text(
                            "Nom: ${_verifiedDecujus!.firstName} ${_verifiedDecujus!.lastName}".trim(),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (_verifiedDecujus!.dateOfBirth.isNotEmpty)
                            Text(
                              "Date de naissance: ${_verifiedDecujus!.dateOfBirth}",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                           Text(
                            "Pension Active: ${_verifiedDecujus!.isPensionActive ? 'Oui' : 'Non'}",
                            style: TextStyle(
                              color: _verifiedDecujus!.isPensionActive ? Colors.green.shade700 : Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ] else if (_verificationResult!['data']?['first_name'] != null || // Fallback if _verifiedDecujus is somehow null
                            _verificationResult!['data']?['last_name'] != null)
                          Text(
                            "Nom: ${_verificationResult!['data']?['first_name'] ?? ''} ${_verificationResult!['data']?['last_name'] ?? ''}".trim(),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        if (_verificationResult!['data']?['date_of_birth'] != null)
                          Text(
                            "Date de naissance: ${_verificationResult!['data']?['date_of_birth']}",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                      ],
                  ],
                ),
              ),

            // Declaration Form Section
            if (_showDeclarationForm && _verifiedDecujus != null && _verifiedDecujus!.isPensionActive)
              _buildDeclarationForm(),

            // Form for pension number input
            if (!_showDeclarationForm || _verifiedDecujus == null || !_verifiedDecujus!.isPensionActive)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _pensionNumberController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de pension',
                      labelStyle: TextStyle(color: AppColors.grayColor.withOpacity(0.8)),
                      prefixIcon: const Icon(Icons.assignment_ind, color: AppColors.primaryColor, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Ex: QWER12345',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un numéro de pension';
                      }
                      if (value.trim().length < 5) {
                        return 'Le numéro de pension doit contenir au moins 5 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_verificationResult != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetForm,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Nouvelle vérification',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_verificationResult != null)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyDecujus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.whiteColor,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _verificationResult != null ? 'Vérifier à nouveau' : 'Vérifier',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              style: const TextStyle(color: AppColors.primaryColor),
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
              style: const TextStyle(color: AppColors.primaryColor),
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
          else if (_declarationSuccessMessage == null) // Show button only if not successful yet
            ElevatedButton(
              onPressed: _submitDeclaration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('Enregistrer la Déclaration'),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      value: value,
      hint: Text(hintText, style: const TextStyle(color: AppColors.grayColor)),
      isExpanded: true,
      dropdownColor: AppColors.whiteColor, // Set dropdown background color
      items: items.map<DropdownMenuItem<T>>((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}