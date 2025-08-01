import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/database/models/activity.dart';
import '../core/providers/activities_provider.dart';
import '../widgets/location_widget.dart';
import '../widgets/photo_manager_widget.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;

  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _thematiqueController = TextEditingController();
  final _dureeController = TextEditingController();
  final _hommesController = TextEditingController();
  final _femmesController = TextEditingController();
  final _jeunesController = TextEditingController();
  final _commentairesController = TextEditingController();

  List<String> _photos = [];
  Position? _currentPosition;
  bool _locationValidated = false;
  bool _hasChanges = false;

  final List<String> _activityTypes = [
    'Formation',
    'Sensibilisation',
    'Démonstration',
    'Conseil technique',
    'Suivi',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _typeController.text = widget.activity.type;
    _thematiqueController.text = widget.activity.thematique;
    _dureeController.text = widget.activity.duree.toString();
    _hommesController.text = widget.activity.hommes.toString();
    _femmesController.text = widget.activity.femmes.toString();
    _jeunesController.text = widget.activity.jeunes.toString();
    _commentairesController.text = widget.activity.commentaires ?? '';
    _photos = List.from(widget.activity.photos ?? []);

    if (widget.activity.latitude != null && widget.activity.longitude != null) {
      _currentPosition = Position(
        latitude: widget.activity.latitude!,
        longitude: widget.activity.longitude!,
        timestamp: DateTime.now(),
        accuracy: widget.activity.precisionMeters ?? 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _locationValidated = (widget.activity.precisionMeters ?? 0) <= 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modifier l\'activité'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _hasChanges ? _saveChanges : null,
              child: Text(
                'SAUVEGARDER',
                style: TextStyle(
                  color: _hasChanges ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_hasChanges) {
              setState(() {
                _hasChanges = true;
              });
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Alerte de modification
              if (widget.activity.statut == 'rejete')
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modifiez votre activité et resoumettez-la pour validation',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Géolocalisation
              LocationWidget(
                onLocationChanged: (position) {
                  setState(() {
                    _currentPosition = position;
                    _hasChanges = true;
                  });
                },
                onValidationChanged: (isValid) {
                  setState(() {
                    _locationValidated = isValid;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Type d'activité
              DropdownButtonFormField<String>(
                value: _typeController.text.isNotEmpty ? _typeController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Type d\'activité *',
                  border: OutlineInputBorder(),
                ),
                items: _activityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  _typeController.text = value ?? '';
                  setState(() {
                    _hasChanges = true;
                  });
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
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Photos
              PhotoManagerWidget(
                photos: _photos,
                onPhotosChanged: (photos) {
                  setState(() {
                    _photos = photos;
                    _hasChanges = true;
                  });
                },
                maxPhotos: 10,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
                onPressed: _locationValidated ? _saveChanges : null,
                backgroundColor: _locationValidated ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder'),
              )
            : null,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Voulez-vous quitter sans sauvegarder vos modifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || !_locationValidated) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Sauvegarde...'),
          ],
        ),
      ),
    );

    try {
      // Créer l'activité modifiée
      final updatedActivity = Activity(
        id: widget.activity.id,
        localId: widget.activity.localId,
        type: _typeController.text.trim(),
        thematique: _thematiqueController.text.trim(),
        duree: double.parse(_dureeController.text),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        precisionMeters: _currentPosition?.accuracy,
        hommes: int.tryParse(_hommesController.text) ?? 0,
        femmes: int.tryParse(_femmesController.text) ?? 0,
        jeunes: int.tryParse(_jeunesController.text) ?? 0,
        commentaires: _commentairesController.text.trim().isEmpty 
            ? null 
            : _commentairesController.text.trim(),
        siteId: widget.activity.siteId,
        regionId: widget.activity.regionId,
        photos: _photos,
        dateCreation: widget.activity.dateCreation,
        isSynced: false, // Marquer comme non synchronisé après modification
      );

      // Sauvegarder via le provider
      final success = await context.read<ActivitiesProvider>().updateActivity(updatedActivity);

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Activité modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retourner avec succès
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la modification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
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