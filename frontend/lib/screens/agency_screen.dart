import 'package:flutter/material.dart';
import 'package:frontend/models/agency.dart'; // Import Agency model
import 'package:frontend/services/agency_service.dart';
import 'package:frontend/services/auth_service.dart'; // Import AuthService
import 'package:frontend/constants/colors.dart'; // Import AppColors

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});
  // It's good practice to define a routeName if this screen is part of named navigation
  static const String routeName = '/agency'; // Example route name

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  final AgencyService _agencyService = AgencyService(); // Instantiate AgencyService
  final AuthService _authService = AuthService(); // Instantiate AuthService

  List<Agency> _agencies = []; // Typed list of Agency
  Agency? _selectedAgency; // Typed selected agency
  String _status = 'Chargement des agences...';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() { // Changed from didChangeDependencies for initial data fetch
    super.initState();
    _fetchAgenciesData();
  }

  Future<void> _fetchAgenciesData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _status = 'Chargement des agences...';
    });

    try {
      // AgencyService now handles token internally via TokenService
      final agencies = await _agencyService.fetchAgencies();
      if (!mounted) return;

      setState(() {
        _agencies = agencies;
        _isLoading = false;
        if (_agencies.isEmpty) {
          _status = 'Aucune agence trouvée.';
        } else {
          // Corrected string literal for French accents
          _status = 'Nombre d\'agences récupérées : ${_agencies.length}.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement des agences: ${e.toString()}';
        _status = 'Impossible de charger les agences.';
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de déconnexion: ${e.toString()}';
        });
      }
    }
  }

  void _navigateToNextScreen() { // Placeholder for navigation
    if (_selectedAgency != null) {
      // Example: Navigate to DecujusFormScreen
      Navigator.pushNamed(
        context,
        '/decujusForm', // Assuming DecujusFormScreen.routeName
        arguments: {
          'agencyId': _selectedAgency!.agencyId,
          'agencyName': _selectedAgency!.nameAgency,
          // Token is no longer passed as an argument
        },
      );
    } else {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une agence.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner une Agence', style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor, // Use AppColors
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.whiteColor), // Use AppColors
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container( // Added a container for background color
        color: AppColors.bgLightColor, // Use AppColors
        padding: const EdgeInsets.all(20.0), // Standardized padding
        child: _isLoading
            ? Center(
                child: Column( // Enhanced loading display
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor), // Use AppColors
                    ),
                    const SizedBox(height: 20),
                    Text(_status, style: TextStyle(color: AppColors.subTitleColor, fontSize: 16)), // Use AppColors
                  ],
                ),
              )
            : RefreshIndicator( // Added RefreshIndicator
                onRefresh: _fetchAgenciesData,
                color: AppColors.primaryColor, // Use AppColors
                child: ListView( // Changed to ListView for better scrollability and structure
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.errorColor, fontSize: 16), // Use AppColors
                        ),
                      ),
                    if (_agencies.isNotEmpty) ...[
                      Text(
                        'Veuillez sélectionner votre agence de retraite:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor, // Use AppColors
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container( // Styling for dropdown
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor, // Use AppColors
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)), // Use AppColors
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Agency>( // Typed DropdownButton
                            value: _selectedAgency,
                            isExpanded: true,
                            hint: Text('Choisissez une agence', style: TextStyle(color: AppColors.subTitleColor)), // Use AppColors
                            icon: Icon(Icons.arrow_drop_down_circle, color: AppColors.primaryColor), // Use AppColors
                            items: _agencies.map<DropdownMenuItem<Agency>>((Agency agency) { // Typed items
                              return DropdownMenuItem<Agency>(
                                value: agency,
                                child: Text(
                                  agency.nameAgency, // Access property directly
                                  style: TextStyle(color: AppColors.textColor, fontSize: 16), // Use AppColors
                                ),
                              );
                            }).toList(),
                            onChanged: (Agency? newValue) { // Typed onChanged
                              setState(() {
                                _selectedAgency = newValue;
                                _errorMessage = null; // Clear error on new selection
                              });
                            },
                            dropdownColor: AppColors.whiteColor, // Use AppColors
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _selectedAgency != null ? _navigateToNextScreen : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor, // Use AppColors
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5), // Use AppColors
                        ),
                        child: const Text('Continuer', style: TextStyle(color: AppColors.whiteColor)), // Use AppColors
                      ),
                    ] else ...[ // Display when no agencies or error during fetch
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryColor, size: 50), // Use AppColors
                            const SizedBox(height: 10),
                            Text(
                              _status, // Shows "Aucune agence trouvée" or error status
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.subTitleColor, fontSize: 16), // Use AppColors
                            ),
                            const SizedBox(height: 20),
                            if (_errorMessage != null || _agencies.isEmpty && !_isLoading) // Show retry if error or no agencies
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, color: AppColors.whiteColor), // Use AppColors
                                label: const Text('Réessayer', style: TextStyle(color: AppColors.whiteColor)), // Use AppColors
                                onPressed: _fetchAgenciesData,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor), // Use AppColors
                              )
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}