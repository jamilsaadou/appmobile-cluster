import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/database/models/site.dart';
import '../core/database/models/activity.dart';
import '../core/services/location_service.dart';
import '../core/providers/activities_provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/photo_manager_widget.dart';

class AddActivityScreen extends StatefulWidget {
  final Site site;

  const AddActivityScreen({super.key, required this.site});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _thematiqueController = TextEditingController();
  final _dureeController = TextEditingController();
  final _hommesController = TextEditingController(text: '0');
  final _femmesController = TextEditingController(text: '0');
  final _jeunesController = TextEditingController(text: '0');
  final _commentairesController = TextEditingController();

  List<String> _photos = []; // ← AJOUTÉ POUR LES PHOTOS

  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isGettingLocation = false;
  bool _locationValidated = false;
  String? _locationError;

  // Types d'activités prédéfinis
  final List<String> _activityTypes = [
    'Formation',
    'Sensibilisation',
    'Démonstration',
    'Conseil technique',
    'Suivi',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activité - ${widget.site.nom}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Informations du site
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Site : ${widget.site.nom}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Localisation : ${widget.site.fullLocation}'),
                      Text('Superficie : ${widget.site.superficie} ha'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // GÉOLOCALISATION (OBLIGATOIRE)
              Card(
                color: _locationValidated ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _locationValidated ? Icons.location_on : Icons.location_off,
                            color: _locationValidated ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Géolocalisation (Obligatoire)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      if (_currentPosition != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              'Précision: ${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                              style: TextStyle(
                                color: _currentPosition!.accuracy <= 20 
                                    ? Colors.green 
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      if (_locationError != null)
                        Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 10),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(_isGettingLocation 
                              ? 'Localisation en cours...' 
                              : 'Obtenir ma position'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _locationValidated 
                                ? Colors.green 
                                : Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      if (!_locationValidated && _currentPosition != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            '⚠️ Précision insuffisante (> 20m). Réessayez.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (_locationValidated)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            '✅ Position validée avec précision < 20m',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Type d'activité
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type d\'activité *',
                  border: OutlineInputBorder(),
                ),
                items: _activityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  _typeController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un type d\'activité';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Thématique
              TextFormField(
                controller: _thematiqueController,
                decoration: const InputDecoration(
                  labelText: 'Thématique *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Techniques d\'irrigation, Gestion des semences...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer la thématique';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Durée
              TextFormField(
                controller: _dureeController,
                decoration: const InputDecoration(
                  labelText: 'Durée (heures) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 2.5',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer la durée';
                  }
                  final duree = double.tryParse(value);
                  if (duree == null || duree <= 0) {
                    return 'Veuillez entrer une durée valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bénéficiaires
              const Text(
                'Bénéficiaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hommesController,
                      decoration: const InputDecoration(
                        labelText: 'Hommes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _femmesController,
                      decoration: const InputDecoration(
                        labelText: 'Femmes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _jeunesController,
                      decoration: const InputDecoration(
                        labelText: 'Jeunes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Commentaires
              TextFormField(
                controller: _commentairesController,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  border: OutlineInputBorder(),
                  hintText: 'Observations, difficultés rencontrées...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Photos - NOUVEAU WIDGET AJOUTÉ
              PhotoManagerWidget(
                photos: _photos,
                onPhotosChanged: (photos) {
                  setState(() {
                    _photos = photos;
                  });
                },
                maxPhotos: 10,
              ),
              const SizedBox(height: 30),

              // Bouton d'enregistrement
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _locationValidated ? _saveActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enregistrer l\'activité'),
                ),
              ),

              if (!_locationValidated)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'ℹ️ Vous devez obtenir une position GPS précise avant d\'enregistrer',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentPositionWithAccuracy();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationValidated = position.accuracy <= 20;
          if (!_locationValidated) {
            _locationError = 'Précision insuffisante (${position.accuracy.toStringAsFixed(1)}m > 20m)';
          }
        });
      } else {
        setState(() {
          _locationError = 'Impossible d\'obtenir la position';
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Erreur: $e';
      });
    }

    setState(() {
      _isGettingLocation = false;
    });
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate() || !_locationValidated) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    final activity = Activity(
      type: _typeController.text.trim(),
      thematique: _thematiqueController.text.trim(),
      duree: double.parse(_dureeController.text),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      precisionMeters: _currentPosition!.accuracy,
      hommes: int.tryParse(_hommesController.text) ?? 0,
      femmes: int.tryParse(_femmesController.text) ?? 0,
      jeunes: int.tryParse(_jeunesController.text) ?? 0,
      commentaires: _commentairesController.text.trim().isEmpty 
          ? null 
          : _commentairesController.text.trim(),
      siteId: widget.site.id!,
      regionId: widget.site.regionId,
      photos: _photos, // ← AJOUTÉ POUR LES PHOTOS
    );

    // Afficher le dialog de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Enregistrement...'),
          ],
        ),
      ),
    );

    final success = await context.read<ActivitiesProvider>().addActivity(activity);

    // Fermer le dialog
    if (mounted) Navigator.pop(context);

    if (success) {
      // Retour à l'écran précédent
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activité enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _thematiqueController.dispose();
    _dureeController.dispose();
    _hommesController.dispose();
    _femmesController.dispose();
    _jeunesController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }
}