import 'package:flutter/material.dart';
import 'package:frontend/models/agency.dart';
import 'package:frontend/services/agency_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/constants/colors.dart';

class AgencySelectionScreen extends StatefulWidget {
  const AgencySelectionScreen({super.key});

  static const String routeName = '/agencySelection';

  @override
  State<AgencySelectionScreen> createState() => _AgencySelectionScreenState();
}

class _AgencySelectionScreenState extends State<AgencySelectionScreen> {
  final AgencyService _agencyService = AgencyService();
  final AuthService _authService = AuthService();

  List<Agency> _agencies = [];
  Agency? _selectedAgency;
  String _fetchStatus = 'Chargement des agences...';
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgenciesData();
  }

  Future<void> _fetchAgenciesData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fetchStatus = 'Chargement des agences...';
    });

    try {
      final List<Agency> agencies = await _agencyService.fetchAgencies();
      if (!mounted) return;
      setState(() {
        _agencies = agencies;
        _isLoading = false;
        if (_agencies.isEmpty) {
          _fetchStatus = 'Aucune agence trouvée.';
        } else {
          _fetchStatus = 'Nombre d\'agences récupérées : ${_agencies.length}.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement des agences: ${e.toString()}';
        _fetchStatus = 'Impossible de charger les agences.';
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

  void _navigateToDecujusForm() {
    if (_selectedAgency != null) {
      Navigator.pushNamed(
        context,
        '/decujusForm',
        arguments: {
          'agencyId': _selectedAgency!.agencyId,
          'agencyName': _selectedAgency!.nameAgency,
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
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.whiteColor),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        color: AppColors.bgLightColor,
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(_fetchStatus, style: TextStyle(color: AppColors.subTitleColor, fontSize: 16)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchAgenciesData,
                color: AppColors.primaryColor,
                child: ListView(
                  children: [
                    if (_agencies.isNotEmpty) ...[
                      Text(
                        'Veuillez sélectionner votre agence de retraite:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
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
                          child: DropdownButton<Agency>(
                            value: _selectedAgency,
                            isExpanded: true,
                            hint: Text('Choisissez une agence', style: TextStyle(color: AppColors.subTitleColor)),
                            icon: Icon(Icons.arrow_drop_down_circle, color: AppColors.primaryColor),
                            items: _agencies.map<DropdownMenuItem<Agency>>((Agency agency) {
                              return DropdownMenuItem<Agency>(
                                value: agency,
                                child: Text(
                                  agency.nameAgency,
                                  style: TextStyle(color: AppColors.primaryColor, fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (Agency? newValue) {
                              setState(() {
                                _selectedAgency = newValue;
                                _errorMessage = null;
                              });
                            },
                            dropdownColor: AppColors.whiteColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _selectedAgency != null ? _navigateToDecujusForm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                        ),
                        child: const Text('Continuer', style: TextStyle(color: AppColors.whiteColor)),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryColor, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              _fetchStatus,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.subTitleColor, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
                                label: const Text('Réessayer', style: TextStyle(color: AppColors.whiteColor)),
                                onPressed: _fetchAgenciesData,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                            )
                          ],
                        ),
                      )
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.errorColor, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
