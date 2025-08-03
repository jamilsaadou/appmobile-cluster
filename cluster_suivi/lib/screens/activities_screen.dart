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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  Future<void> _loadActivities() async {
    final provider = context.read<ActivitiesProvider>();
    await provider.loadLocalActivities();
    // ✅ Synchroniser automatiquement les statuts depuis l'API
    await provider.autoSyncStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Activités'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Bouton de synchronisation des statuts
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshStatuses,
            tooltip: 'Actualiser les statuts',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncActivities,
            tooltip: 'Synchroniser les activités',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Consumer<ActivitiesProvider>(
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
      ),
    );
  }

  // ✅ Carte d'activité avec affichage correct des statuts
  Widget _buildActivityCard(Activity activity) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final totalBeneficiaires = activity.hommes + activity.femmes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewActivityDetail(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type et statuts
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
                  _buildStatusChip(activity.statut),
                ],
              ),
              const SizedBox(height: 8),

              // Thématique
              Text(
                activity.thematique,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Informations détaillées
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.duree}h',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$totalBeneficiaires bénéficiaires',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date de création
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(activity.dateCreation),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (activity.photos != null && activity.photos!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.photo_camera, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.photos!.length} photo(s)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              // ✅ Affichage du motif de refus si l'activité est rejetée
              if (activity.isRejected && activity.motifRefus != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motif de refus:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.motifRefus!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Indication pour voir les détails
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

  // ✅ Chip de statut d'activité avec couleurs correctes
  Widget _buildStatusChip(String statut) {
    Color color;
    IconData icon;
    String text;
    
    switch (statut.toLowerCase()) {
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

  // Chip de statut de synchronisation
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

  void _viewActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    ).then((_) {
      // Recharger les activités au retour
      _loadActivities();
    });
  }

  // ✅ Nouvelle méthode pour actualiser uniquement les statuts
  Future<void> _refreshStatuses() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await context.read<ActivitiesProvider>().syncActivityStatuses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Statuts mis à jour'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Méthode de synchronisation complète
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
            content: Text('✅ $syncCount activité(s) synchronisée(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur de synchronisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode de rafraîchissement pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadActivities();
  }
}