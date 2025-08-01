import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/activities_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/database/models/activity.dart';
import 'activity_detail_screen.dart';


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

// ✅ REMPLACER _buildActivityCard dans activities_screen.dart
Widget _buildActivityCard(Activity activity) {
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final totalBeneficiaires = activity.hommes + activity.femmes + activity.jeunes;

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell( // ← AJOUTER InkWell pour le tap
      onTap: () => _viewActivityDetail(activity), // ← AJOUTER cette ligne
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et statut
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
                const SizedBox(width: 8),
                _buildStatusChip(activity.statut), // ← AJOUTER
              ],
            ),
            // ... reste du code existant ...
            
            // ✅ AJOUTER à la fin des children
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Appuyez pour voir les détails',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ✅ AJOUTER ces méthodes dans _ActivitiesScreenState
Widget _buildStatusChip(String statut) {
  Color color;
  IconData icon;
  String text;
  
  switch (statut) {
    case 'approuve':
      color = Colors.green;
      icon = Icons.check_circle;
      text = 'Approuvé';
      break;
    case 'rejete':
      color = Colors.red;
      icon = Icons.cancel;
      text = 'Refusé';
      break;
    default:
      color = Colors.orange;
      icon = Icons.schedule;
      text = 'En attente';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

void _viewActivityDetail(Activity activity) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ActivityDetailScreen(activity: activity),
    ),
  ).then((_) {
    // Recharger les activités au retour
    context.read<ActivitiesProvider>().loadLocalActivities();
  });
}
  // ✅ REMPLACER la méthode _buildSyncStatusChip pour gérer le nouveau modèle
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