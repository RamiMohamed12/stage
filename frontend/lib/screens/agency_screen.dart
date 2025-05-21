import 'package:flutter/material.dart';
import '../services/agency_service.dart'; // Ensure this path is correct

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});
  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  List<dynamic> _agencies = [];
  dynamic _selectedAgency;
  String _status = 'Loading agencies...';
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
        _status = 'Error: Authentication token not found.';
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
          _status = 'Fetched ${_agencies.length} agencies.';
          if (_agencies.isEmpty) {
            _status = 'No agencies found.';
          }
        } else {
          // Handle cases where agencyData is not a list, e.g. if it's a map containing the list
          // For example, if your backend returns { "agencies": [...] }
          // you might need: _agencies = agencyData['agencies'] as List<dynamic>? ?? [];
          _agencies = []; // Default to empty list if structure is unexpected
          _status = 'Unexpected data format for agencies.';
          print('Unexpected agency data format: $agencyData');
        }
      } else {
        _status = 'Error: ${result['message']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Agency')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status),
                  const SizedBox(height: 20),
                  if (_agencies.isNotEmpty) ...[
                    const Text('Select your agency:'),
                    DropdownButton<dynamic>(
                      isExpanded: true,
                      value: _selectedAgency,
                      hint: const Text('Choose an agency'),
                      items: _agencies.map<DropdownMenuItem<dynamic>>((agency) {
                        return DropdownMenuItem<dynamic>(
                          value: agency,
                          child: Text(agency['name_agency'] ?? 'Unnamed Agency'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() { _selectedAgency = value; });
                      },
                    ),
                    if (_selectedAgency != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        // Ensure agency_id exists or handle null
                        child: Text('Selected: ${_selectedAgency['name_agency']} (ID: ${_selectedAgency['agency_id'] ?? 'N/A'})'),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}