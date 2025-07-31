import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/location_service.dart';

class LocationWidget extends StatefulWidget {
  final Function(Position?) onLocationChanged;
  final Function(bool) onValidationChanged;

  const LocationWidget({
    super.key,
    required this.onLocationChanged,
    required this.onValidationChanged,
  });

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  bool _isGettingLocation = false;
  bool _locationValidated = false;
  String? _locationError;
  int _attemptCount = 0;
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation pour l'effet de pulsation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation pour la barre de progression
    _progressController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _getCardColor(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContent(),
            const SizedBox(height: 16),
            _buildActionButton(),
            if (_isGettingLocation) _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: _getIconColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Géolocalisation GPS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              Text(
                _getSubtitle(),
                style: TextStyle(
                  fontSize: 14,
                  color: _getSubtitleColor(),
                ),
              ),
            ],
          ),
        ),
        if (_locationValidated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'VALIDÉ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isGettingLocation) {
      return _buildSearchingContent();
    } else if (_currentPosition != null) {
      return _buildLocationDetails();
    } else if (_locationError != null) {
      return _buildErrorContent();
    } else {
      return _buildInstructionsContent();
    }
  }

  Widget _buildSearchingContent() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Recherche de position GPS...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tentative ${_attemptCount + 1}/3',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _buildTips(),
      ],
    );
  }

  Widget _buildLocationDetails() {
    final precision = _currentPosition!.accuracy;
    final isPrecise = precision <= 20;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrecise ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrecise ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Indicateur de précision visuel
          Row(
            children: [
              Icon(
                isPrecise ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: isPrecise ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPrecise ? 'Position précise obtenue' : 'Précision insuffisante',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPrecise ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                    Text(
                      'Précision: ${precision.toStringAsFixed(1)}m ${isPrecise ? '(< 20m ✓)' : '(> 20m ✗)'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrecise ? Colors.green[600] : Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrecise ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${precision.toInt()}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Coordonnées avec style moderne
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Latitude:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      _currentPosition!.latitude.toStringAsFixed(6),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Longitude:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      _currentPosition!.longitude.toStringAsFixed(6),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isPrecise) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Réessayez pour une meilleure précision',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de géolocalisation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _locationError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 12),
          _buildTroubleshootingTips(),
        ],
      ),
    );
  }

  Widget _buildInstructionsContent() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_off,
            color: Colors.grey[600],
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Position GPS requise',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Une position précise (< 20m) est nécessaire pour enregistrer l\'activité',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _buildTips(),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Conseils pour une meilleure précision',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...['Sortez à l\'extérieur', 'Évitez les zones couvertes', 'Attendez quelques secondes']
              .map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.blue[600])),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_outlined, color: Colors.amber[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Solutions possibles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...['Vérifiez que le GPS est activé', 'Autorisez la localisation', 'Redémarrez l\'application']
              .map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.amber[600])),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isGettingLocation ? null : _getCurrentLocation,
        icon: _isGettingLocation
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getButtonTextColor(),
                  ),
                ),
              )
            : Icon(_getButtonIcon(), color: _getButtonTextColor()),
        label: Text(
          _getButtonText(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getButtonTextColor(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          foregroundColor: _getButtonTextColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isGettingLocation ? 0 : 2,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 4,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Recherche en cours... Restez immobile',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes pour les couleurs et styles dynamiques
  Color _getCardColor() {
    if (_locationValidated) return Colors.green.withOpacity(0.05);
    if (_locationError != null) return Colors.red.withOpacity(0.05);
    if (_isGettingLocation) return Colors.blue.withOpacity(0.05);
    return Colors.grey.withOpacity(0.02);
  }

  Color _getIconBackgroundColor() {
    if (_locationValidated) return Colors.green.withOpacity(0.2);
    if (_locationError != null) return Colors.red.withOpacity(0.2);
    if (_isGettingLocation) return Colors.blue.withOpacity(0.2);
    return Colors.grey.withOpacity(0.2);
  }

  Color _getIconColor() {
    if (_locationValidated) return Colors.green;
    if (_locationError != null) return Colors.red;
    if (_isGettingLocation) return Colors.blue;
    return Colors.grey;
  }

  IconData _getHeaderIcon() {
    if (_locationValidated) return Icons.gps_fixed;
    if (_locationError != null) return Icons.gps_off;
    if (_isGettingLocation) return Icons.gps_not_fixed;
    return Icons.location_off;
  }

  Color _getTextColor() {
    if (_locationValidated) return Colors.green[700]!;
    if (_locationError != null) return Colors.red[700]!;
    return Colors.grey[800]!;
  }

  Color _getSubtitleColor() {
    return Colors.grey[600]!;
  }

  String _getSubtitle() {
    if (_locationValidated) return 'Position validée avec précision';
    if (_locationError != null) return 'Erreur de localisation';
    if (_isGettingLocation) return 'Recherche en cours...';
    return 'Obligatoire pour enregistrer l\'activité';
  }

  Color _getButtonColor() {
    if (_locationValidated) return Colors.green;
    if (_locationError != null) return Colors.orange;
    return Colors.blue;
  }

  Color _getButtonTextColor() {
    return Colors.white;
  }

  IconData _getButtonIcon() {
    if (_locationValidated) return Icons.refresh;
    return Icons.my_location;
  }

  String _getButtonText() {
    if (_isGettingLocation) return 'Localisation en cours...';
    if (_locationValidated) return 'Actualiser la position';
    if (_locationError != null) return 'Réessayer';
    return 'Obtenir ma position GPS';
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
      _attemptCount++;
    });

    // Démarrer les animations
    _pulseController.repeat(reverse: true);
    _progressController.forward();

    try {
      final position = await _locationService.getCurrentPositionWithAccuracy();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationValidated = position.accuracy <= 20;
          if (!_locationValidated) {
            _locationError = null; // Pas d'erreur, juste précision insuffisante
          }
        });
        
        widget.onLocationChanged(position);
        widget.onValidationChanged(_locationValidated);
      } else {
        setState(() {
          _locationError = 'Impossible d\'obtenir la position GPS';
        });
        widget.onValidationChanged(false);
      }
    } catch (e) {
      setState(() {
        _locationError = 'Erreur: $e';
      });
      widget.onValidationChanged(false);
    }

    // Arrêter les animations
    _pulseController.stop();
    _progressController.reset();

    setState(() {
      _isGettingLocation = false;
    });
  }
}