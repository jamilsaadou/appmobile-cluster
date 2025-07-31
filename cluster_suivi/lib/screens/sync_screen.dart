import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/providers/activities_provider.dart';
import '../core/providers/sites_provider.dart';
import '../core/providers/auth_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isOnline = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronisation'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnectivity,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut de connexion
            Card(
              color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi : Icons.wifi_off,
                      color: _isOnline ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'En ligne' : 'Hors ligne',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isOnline ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            _isOnline 
                                ? 'Connexion internet disponible'
                                : 'Aucune connexion internet',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Informations utilisateur
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;
                if (user == null) return const SizedBox();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Utilisateur connecté',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${user['prenom']} ${user['nom']}'),
                        Text('Email: ${user['email']}'),
                        Text('Rôle: ${user['role']}'),
                        if (user['regions'] != null && user['regions'].isNotEmpty)
                          Text('Régions: ${user['regions'].length}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Statistiques locales
            Consumer2<SitesProvider, ActivitiesProvider>(
              builder: (context, sitesProvider, activitiesProvider, child) {
                final totalSites = sitesProvider.sites.length;
                final totalActivities = activitiesProvider.activities.length;
                final unsyncedActivities = activitiesProvider.activities
                    .where((activity) => !activity.isSynced)
                    .length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Données locales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow('Sites', totalSites, Icons.location_city),
                        _buildStatRow('Activités totales', totalActivities, Icons.assignment),
                        _buildStatRow(
                          'Activités non synchronisées', 
                          unsyncedActivities, 
                          Icons.cloud_upload,
                          color: unsyncedActivities > 0 ? Colors.orange : Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Actions de synchronisation
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Bouton synchronisation complète
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOnline && !_isSyncing ? _performFullSync : null,
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Synchronisation...' : 'Synchronisation complète'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton actualiser les sites
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isOnline && !_isSyncing ? _refreshSites : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser les sites'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (!_isOnline)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'ℹ️ Mode hors ligne : Vos activités sont sauvegardées localement et seront synchronisées dès qu\'une connexion internet sera disponible.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // Synchroniser les sites
      await context.read<SitesProvider>().fetchSites();
      
      // Synchroniser les activités
      final syncCount = await context.read<ActivitiesProvider>().syncPendingActivities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation réussie - $syncCount activité(s) envoyée(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de synchronisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSyncing = false;
    });
  }

  Future<void> _refreshSites() async {
    try {
      await context.read<SitesProvider>().fetchSites();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sites mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}