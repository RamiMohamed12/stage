import 'package:flutter/material.dart';
import 'package:frontend/models/decujus_verification_payload.dart';
import 'package:frontend/models/decujus_verification_result.dart';
import 'package:frontend/services/decujus_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart';

class DecujusFormScreen extends StatefulWidget {
  final Map<String, dynamic> routeArgs;

  const DecujusFormScreen({super.key, required this.routeArgs});

  static const String routeName = '/decujusForm';

  @override
  State<DecujusFormScreen> createState() => _DecujusFormScreenState();
}

class _DecujusFormScreenState extends State<DecujusFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DecujusService _decujusService = DecujusService();

  String? _pensionNumber;
  String? _firstName;
  String? _lastName;
  DateTime? _dateOfBirth;
  int? _agencyId; // Changed to int?
  String? _agencyName;

  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _agencyId = widget.routeArgs['agencyId'] as int?; // Cast to int?
    _agencyName = widget.routeArgs['agencyName'] as String?;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.whiteColor,
              onSurface: AppColors.textColor,
            ),
            dialogBackgroundColor: AppColors.bgLightColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_agencyId == null) {
        setState(() {
          _errorMessage = 'ID de l\'agence manquant. Veuillez réessayer.';
        });
        return;
      }
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final payload = DecujusVerificationPayload(
        agencyId: _agencyId!, // Now correctly an int
        pensionNumber: _pensionNumber!,
        firstName: _firstName!,
        lastName: _lastName!,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
      );

      try {
        // Corrected: verifyDecujus now only takes payload
        final DecujusVerificationResult result = await _decujusService.verifyDecujus(payload);
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/verificationResult',
            arguments: {
              'result': result,
              'agencyId': _agencyId, 
              'agencyName': _agencyName,
            },
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    TextEditingController? controller,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.primaryColor.withOpacity(0.8)),
        filled: true,
        fillColor: AppColors.whiteColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
      ),
      style: const TextStyle(color: AppColors.textColor),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSaved: onSaved,
      validator: validator,
      onTap: onTap,
      readOnly: readOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Déclarer un Décès - ${_agencyName ?? "Agence"}', style: const TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: Container(
        color: AppColors.bgLightColor,
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Veuillez saisir les informations du défunt affilié à l\'agence ${_agencyName ?? "sélectionnée"}.',
                  style: TextStyle(fontSize: 16, color: AppColors.subTitleColor, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                _buildTextField(
                  label: 'N° de Pension',
                  onSaved: (value) => _pensionNumber = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir le numéro de pension.';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Prénom',
                  onSaved: (value) => _firstName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir le prénom.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Nom',
                  onSaved: (value) => _lastName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir le nom.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Date de Naissance',
                  controller: _dobController,
                  onSaved: (value) { /* Handled by _selectDate */ }, 
                  validator: (value) {
                    if (_dateOfBirth == null) {
                      return 'Veuillez sélectionner la date de naissance.';
                    }
                    return null;
                  },
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                else
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Vérifier Décujus', style: TextStyle(color: AppColors.whiteColor)),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.errorColor, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
