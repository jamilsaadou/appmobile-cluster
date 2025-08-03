import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../core/database/models/activity.dart';
import '../core/providers/activities_provider.dart';
import '../core/services/photo_service.dart';
import '../core/models/activity_status.dart';
import 'edit_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Activity _activity;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
  }

  @override
  Widget build(BuildContext context) {
    final status = ActivityStatus.fromString(_activity.statut);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'activité'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_activity.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editActivity,
              tooltip: 'Modifier l\'activité',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshActivity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(status),
              const SizedBox(height: 16),
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildBeneficiariesCard(),
              if (_activity.photos != null && _activity.photos!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPhotosCard(),
              ],
              if (_activity.commentaires != null && _activity.commentaires!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCommentsCard(),
              ],
              if (_activity.isRejected) ...[
                const SizedBox(height: 16),
                _buildRejectionReasonCard(),
              ],
              const SizedBox(height: 16),
              _buildMetadataCard(),
              const SizedBox(height: 100), // Espace pour le FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _activity.canEdit
          ? FloatingActionButton.extended(
              onPressed: _editActivity,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
            )
          : null,
    );
  }

  Widget _buildStatusCard(ActivityStatus status) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              status.icon,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              status.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (!_activity.isSynced) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_problem, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Non synchronisé',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type d\'activité', _activity.type, Icons.category),
            const SizedBox(height: 12),
            _buildInfoRow('Thématique', _activity.thematique, Icons.topic),
            const SizedBox(height: 12),
            _buildInfoRow('Durée', '${_activity.duree} heures', Icons.access_time),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Date de création',
              DateFormat('dd/MM/yyyy à HH:mm').format(_activity.dateCreation),
              Icons.event,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    if (_activity.latitude == null || _activity.longitude == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Géolocalisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
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
                        _activity.latitude!.toStringAsFixed(6),
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Longitude:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(
                        _activity.longitude!.toStringAsFixed(6),
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_activity.precisionMeters != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _activity.precisionMeters! <= 20 ? Icons.gps_fixed : Icons.gps_not_fixed,
                          size: 16,
                          color: _activity.precisionMeters! <= 20 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text('Précision:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          '${_activity.precisionMeters!.toStringAsFixed(1)} m',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activity.precisionMeters! <= 20 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiariesCard() {
    final total = _activity.hommes + _activity.femmes;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Bénéficiaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: $total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBeneficiaryItem('Hommes', _activity.hommes, Icons.person, Colors.blue),
                const SizedBox(width: 16),
                _buildBeneficiaryItem('Femmes', _activity.femmes, Icons.person_outline, Colors.pink),
                const SizedBox(width: 16),
                _buildBeneficiaryItem('Jeunes', _activity.jeunes, Icons.child_care, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiaryItem(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Photos (${_activity.photos!.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activity.photos!.length,
                itemBuilder: (context, index) {
                  return _buildPhotoItem(_activity.photos![index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(String photoName, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _viewPhoto(photoName, index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<String>(
              future: PhotoService.getPhotoPath(photoName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final file = File(snapshot.data!);
                  return FutureBuilder<bool>(
                    future: file.exists(),
                    builder: (context, existsSnapshot) {
                      if (existsSnapshot.data == true) {
                        return Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPhotoError();
                          },
                        );
                      } else {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_download,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sur serveur',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoError() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildCommentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Commentaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _activity.commentaires!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionReasonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Motif de refus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _activity.motifRefus ?? 'Motif de refus non spécifié',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.red[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous pouvez modifier et resoumettre cette activité',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Informations techniques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('ID Local', _activity.localId, Icons.tag, isSmall: true),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Synchronisation',
              _activity.isSynced ? 'Synchronisé' : 'En attente',
              _activity.isSynced ? Icons.cloud_done : Icons.cloud_upload,
              isSmall: true,
            ),
            if (_activity.id != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('ID Serveur', _activity.id.toString(), Icons.cloud, isSmall: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isSmall = false}) {
    return Row(
      children: [
        Icon(icon, size: isSmall ? 16 : 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isSmall ? 12 : 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: isSmall ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _editActivity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(activity: _activity),
      ),
    );

    if (result == true) {
      await _refreshActivity();
    }
  }

  Future<void> _refreshActivity() async {
    try {
      final updatedActivity = await context
          .read<ActivitiesProvider>()
          .getActivityById(_activity.id ?? _activity.localId);
      
      if (updatedActivity != null) {
        setState(() {
          _activity = updatedActivity;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du rechargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewPhoto(String photoName, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: FutureBuilder<String>(
                future: PhotoService.getPhotoPath(photoName),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final file = File(snapshot.data!);
                    return FutureBuilder<bool>(
                      future: file.exists(),
                      builder: (context, existsSnapshot) {
                        if (existsSnapshot.data == true) {
                          return InteractiveViewer(
                            child: Image.file(
                              file,
                              fit: BoxFit.contain,
                            ),
                          );
                        } else {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_download,
                                color: Colors.white,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Photo stockée sur le serveur',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                photoName,
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          );
                        }
                      },
                    );
                  }
                  return const CircularProgressIndicator(color: Colors.white);
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Photo ${index + 1} sur ${_activity.photos!.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}