import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/activities_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/database/models/activity.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesProvider>().loadLocalActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Activités'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncActivities,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Consumer<ActivitiesProvider>(
        builder: (context, activitiesProvider, child) {
          if (activitiesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activitiesProvider.activities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune activité enregistrée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Retournez aux sites pour ajouter des activités',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activitiesProvider.activities.length,
            itemBuilder: (context, index) {
              final activity = activitiesProvider.activities[index];
              return _buildActivityCard(activity);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final totalBeneficiaires = activity.hommes + activity.femmes + activity.jeunes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et statut de sync
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSyncStatusChip(activity.isSynced),
              ],
            ),
            const SizedBox(height: 8),

            // Thématique
            Text(
              activity.thematique,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Informations principales
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${activity.duree}h'),
                const SizedBox(width: 20),
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$totalBeneficiaires bénéficiaires'),
              ],
            ),
            const SizedBox(height: 8),

            // Détail des bénéficiaires
            if (totalBeneficiaires > 0)
              Text(
                'Hommes: ${activity.hommes} • Femmes: ${activity.femmes} • Jeunes: ${activity.jeunes}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

            // Géolocalisation
            if (activity.latitude != null && activity.longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.latitude!.toStringAsFixed(6)}, ${activity.longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    if (activity.precisionMeters != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(±${activity.precisionMeters!.toStringAsFixed(1)}m)',
                        style: TextStyle(
                          fontSize: 12,
                          color: activity.precisionMeters! <= 20 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Commentaires
            if (activity.commentaires != null && activity.commentaires!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  activity.commentaires!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),

            // Date
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                dateFormatter.format(activity.dateCreation),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusChip(bool isSynced) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSynced ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_upload,
            size: 16,
            color: isSynced ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Synchronisé' : 'En attente',
            style: TextStyle(
              fontSize: 12,
              color: isSynced ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncActivities() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Synchronisation...'),
          ],
        ),
      ),
    );

    try {
      final syncCount = await context.read<ActivitiesProvider>().syncPendingActivities();
      
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$syncCount activité(s) synchronisée(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de synchronisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}