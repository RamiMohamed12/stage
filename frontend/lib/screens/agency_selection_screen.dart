import 'package:flutter/material.dart';
import 'package:frontend/models/agency.dart';
import 'package:frontend/services/agency_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/screens/decujus_verification_screen.dart';
import 'package:frontend/widgets/loading_indicator.dart';

class AgencySelectionScreen extends StatefulWidget {
  const AgencySelectionScreen({super.key});

  static const String routeName = '/agencySelection';

  @override
  State<AgencySelectionScreen> createState() => _AgencySelectionScreenState();
}

class _AgencySelectionScreenState extends State<AgencySelectionScreen>
    with TickerProviderStateMixin {
  final AgencyService _agencyService = AgencyService();
  final AuthService _authService = AuthService();

  List<Agency> _agencies = [];
  Agency? _selectedAgency;
  String _fetchStatus = 'Chargement des agences...';
  String? _errorMessage;
  bool _isLoading = true;

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

    _fetchAgenciesData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _navigateToDecujusVerification() {
    if (_selectedAgency != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DecujusVerificationScreen(
            agencyId: _selectedAgency!.agencyId,
            agencyName: _selectedAgency!.nameAgency,
          ),
        ),
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
                      child: _buildAgencySelectionCard(),
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.whiteColor, size: 28),
                onPressed: _logout,
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Sélection d'Agence",
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choisissez votre agence de retraite",
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

  Widget _buildAgencySelectionCard() {
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
              "Sélection d'agence",
              style: TextStyle(
                color: AppColors.subTitleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Veuillez sélectionner votre agence de retraite",
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
                        style: const TextStyle(color: AppColors.errorColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Agency Selection Section
            if (_agencies.isNotEmpty) ...[
              _buildDropdown<Agency>(
                hintText: 'Choisissez une agence',
                value: _selectedAgency,
                items: _agencies,
                onChanged: (Agency? newValue) {
                  setState(() {
                    _selectedAgency = newValue;
                    _errorMessage = null;
                  });
                },
                itemBuilder: (Agency item) => Text(item.nameAgency),
                validator: (value) =>
                    value == null ? 'Veuillez sélectionner une agence' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAgency != null ? _navigateToDecujusVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                  ),
                  child: const Text('Continuer'),
                ),
              ),
            ] else if (!_isLoading) ...[
              // Empty state
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 64,
                      color: AppColors.grayColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fetchStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
                      label: const Text('Réessayer', style: TextStyle(color: AppColors.whiteColor)),
                      onPressed: _fetchAgenciesData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
