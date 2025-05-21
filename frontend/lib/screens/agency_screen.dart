import 'package:flutter/material.dart';
import '../services/agency_service.dart'; // Ensure this path is correct
import '../constants/colors.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});
  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  List<dynamic> _agencies = [];
  dynamic _selectedAgency;
  String _status = 'Chargement des agences...';
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure this runs only once after the dependencies are available
    if (_isLoading) {
      _fetchAgenciesData();
    }
  }

  Future<void> _fetchAgenciesData() async {
    final token = ModalRoute.of(context)!.settings.arguments as String?;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _status = "Erreur : jeton d'authentification introuvable.";
        _isLoading = false;
      });
      return;
    }

    final result = await AgencyService.fetchAgencies(token);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success']) {
        // Assuming result['data'] is the list of agencies
        // If result['data'] is a map containing the list, adjust accordingly e.g. result['data']['agencies']
        final dynamic agencyData = result['data'];
        if (agencyData is List) {
          _agencies = agencyData;
          _status = 'Nombre d\'agences récupérées : ${_agencies.length}.';
          if (_agencies.isEmpty) {
            _status = 'Aucune agence trouvée.';
          }
        } else {
          // Handle cases where agencyData is not a list, e.g. if it's a map containing the list
          // For example, if your backend returns { "agencies": [...] }
          // you might need: _agencies = agencyData['agencies'] as List<dynamic>? ?? [];
          _agencies = []; // Default to empty list if structure is unexpected
          _status = 'Format de données inattendu pour les agences.';
          print('Format de données inattendu pour les agences : $agencyData');
        }
      } else {
        _status = 'Erreur : ${result['message']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner une agence'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status, style: TextStyle(color: subTitleColor)),
                  const SizedBox(height: 20),
                  if (_agencies.isNotEmpty) ...[
                    const Text('Sélectionnez votre agence :', style: TextStyle(color: subTitleColor)),
                    DropdownButton<dynamic>(
                      isExpanded: true,
                      value: _selectedAgency,
                      hint: const Text('Choisissez une agence', style: TextStyle(color: subTitleColor)),
                      items: _agencies.map<DropdownMenuItem<dynamic>>((agency) {
                        return DropdownMenuItem<dynamic>(
                          value: agency,
                          child: Text(agency['name_agency'] ?? 'Agence sans nom', style: TextStyle(color: primaryColor)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() { _selectedAgency = value; });
                      },
                    ),
                    if (_selectedAgency != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text('Sélectionné : ${_selectedAgency['name_agency']} (ID : ${_selectedAgency['agency_id'] ?? 'N/A'})', style: TextStyle(color: primaryColor)),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}