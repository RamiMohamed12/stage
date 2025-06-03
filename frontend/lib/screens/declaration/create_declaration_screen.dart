import 'package:flutter/material.dart';
import 'package:frontend/models/death_cause.dart';
import 'package:frontend/models/relationship.dart';
import 'package:frontend/services/death_cause_service.dart';
import 'package:frontend/services/relationship_service.dart';
import 'package:frontend/services/declaration_service.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_text_field.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart'; // For date formatting

class CreateDeclarationScreen extends StatefulWidget {
  static const String routeName = '/create-declaration';

  const CreateDeclarationScreen({super.key});

  @override
  State<CreateDeclarationScreen> createState() =>
      _CreateDeclarationScreenState();
}

class _CreateDeclarationScreenState extends State<CreateDeclarationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deathCauseService = DeathCauseService();
  final _relationshipService = RelationshipService();
  final _declarationService = DeclarationService();

  final _pensionNumberController = TextEditingController();
  DateTime? _selectedDate;

  List<DeathCause> _deathCauses = [];
  DeathCause? _selectedDeathCause;
  List<Relationship> _relationships = [];
  Relationship? _selectedRelationship;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final causes = await _deathCauseService.getAllDeathCauses();
      final relationships = await _relationshipService.getAllRelationships();
      setState(() {
        _deathCauses = causes;
        _relationships = relationships;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor, // header background color
              onPrimary: AppColors.whiteColor, // header text color
              onSurface: AppColors.textColor, // body text color
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: AppColors.bgLightColor, // Use DialogThemeData.backgroundColor
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitDeclaration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRelationship == null || _selectedDeathCause == null) {
      setState(() {
        _errorMessage =
            'Veuillez sélectionner une relation et une cause de décès.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _declarationService.createDeclaration(
        decujusPensionNumber: _pensionNumberController.text.trim(),
        relationshipId: _selectedRelationship!.relationshipId,
        deathCauseId: _selectedDeathCause!.deathCauseId,
        declarationDate: _selectedDate,
      );
      setState(() {
        _successMessage = 'Déclaration créée avec succès!';
        _formKey.currentState?.reset();
        _pensionNumberController.clear();
        _selectedDate = null;
        _selectedDeathCause = null;
        _selectedRelationship = null;
        // Optionally navigate away or show a success dialog
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pensionNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Créer une Déclaration'),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  CustomTextField(
                    controller: _pensionNumberController,
                    labelText: 'Numéro de Pension du Défunt',
                    hintText: 'Entrez le numéro de pension',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le numéro de pension';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<Relationship>(
                    hintText: 'Sélectionner la Relation',
                    value: _selectedRelationship,
                    items: _relationships,
                    onChanged: (Relationship? newValue) {
                      setState(() {
                        _selectedRelationship = newValue;
                      });
                    },
                    itemBuilder: (Relationship item) =>
                        Text(item.relationshipName),
                    validator: (value) =>
                        value == null ? 'Veuillez sélectionner une relation' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<DeathCause>(
                    hintText: 'Sélectionner la Cause du Décès',
                    value: _selectedDeathCause,
                    items: _deathCauses,
                    onChanged: (DeathCause? newValue) {
                      setState(() {
                        _selectedDeathCause = newValue;
                      });
                    },
                    itemBuilder: (DeathCause item) => Text(item.causeName),
                     validator: (value) =>
                        value == null ? 'Veuillez sélectionner une cause de décès' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      _selectedDate == null
                          ? 'Sélectionner la Date de Déclaration'
                          : 'Date de Déclaration: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.grayColor
                              : AppColors.textColor),
                    ),
                    trailing: const Icon(Icons.calendar_today,
                        color: AppColors.primaryColor),
                    onTap: () => _pickDate(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: AppColors.borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.errorColor, fontSize: 14)),
                    ),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_successMessage!,
                          style: const TextStyle(color: Colors.green, fontSize: 14)),
                    ),
                  CustomButton(
                    text: 'Soumettre la Déclaration',
                    onPressed: _isLoading ? null : _submitDeclaration,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading && _deathCauses.isEmpty && _relationships.isEmpty) // Show full screen loader only on initial data fetch
            const LoadingIndicator(),
          if (_isLoading && (_deathCauses.isNotEmpty || _relationships.isNotEmpty)) // Show smaller loading for submission
             Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withOpacity(0.8), // Kept withOpacity for clarity, can be changed if needed
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)),
              ),
            )
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
      items: items.map<DropdownMenuItem<T>>((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
