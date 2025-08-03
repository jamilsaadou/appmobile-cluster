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

  // ✅ FONCTION HELPER POUR LES INITIALES SÉCURISÉE
  String _getUserInitials(Map<String, dynamic>? user) {
    if (user == null) return 'U';
    
    final prenom = user['prenom']?.toString() ?? '';
    final nom = user['nom']?.toString() ?? '';
    
    if (prenom.isEmpty && nom.isEmpty) return 'U';
    
    final prenomInitial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final nomInitial = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    
    return '$prenomInitial$nomInitial'.isEmpty ? 'U' : '$prenomInitial$nomInitial';
  }

  // ✅ FONCTION HELPER POUR LE NOM COMPLET SÉCURISÉE
  String _getUserFullName(Map<String, dynamic>? user) {
    if (user == null) return 'Utilisateur';
    
    final prenom = user['prenom']?.toString() ?? '';
    final nom = user['nom']?.toString() ?? '';
    
    if (prenom.isEmpty && nom.isEmpty) return 'Utilisateur';
    
    return '${prenom.trim()} ${nom.trim()}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Synchronisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getUserFullName(auth.user),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            );
          },
        ),
        actions: [
          // ✅ AVATAR UTILISATEUR SÉCURISÉ
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getUserInitials(auth.user),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnectivity,
            tooltip: 'Vérifier la connexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ CARTE PROFIL UTILISATEUR CORRIGÉE
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // ✅ AVATAR SÉCURISÉ
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Text(
                                _getUserInitials(user),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // ✅ INFORMATIONS UTILISATEUR SÉCURISÉES
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getUserFullName(user),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis, // ✅ ÉVITER L'OVERFLOW
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['email']?.toString() ?? 'Email non disponible',
                                    style: TextStyle(
                                      color: Colors.green[100],
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis, // ✅ ÉVITER L'OVERFLOW
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Rôle: ${user?['role']?.toString() ?? 'Conseiller'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ✅ STATUT DE CONNEXION
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column( // ✅ CHANGÉ EN COLUMN POUR ÉVITER L'OVERFLOW
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    auth.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auth.isOfflineMode ? 'Mode hors ligne' : 'Connecté en ligne',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          auth.isOfflineMode 
                                              ? 'Données sauvegardées localement'
                                              : 'Synchronisation automatique active',
                                          style: TextStyle(
                                            color: Colors.green[100],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12), // ✅ ESPACEMENT
                              // ✅ BOUTON DÉCONNEXION EN PLEINE LARGEUR
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _showLogoutConfirmation,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text(
                                    'Se déconnecter',
                                    style: TextStyle(fontSize: 14),
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
              },
            ),
            
            const SizedBox(height: 20),

            // Statut de connexion internet
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
                            _isOnline ? 'Connexion Internet' : 'Pas de connexion',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isOnline ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            _isOnline 
                                ? 'Connexion internet disponible'
                                : 'Aucune connexion internet détectée',
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

            // ✅ STATISTIQUES SÉCURISÉES
            Consumer2<SitesProvider, ActivitiesProvider>(
              builder: (context, sitesProvider, activitiesProvider, child) {
                final totalSites = sitesProvider.sites.length;
                final totalActivities = activitiesProvider.activities.length;
                final unsyncedActivities = activitiesProvider.activities
                    .where((activity) => !activity.isSynced)
                    .length;
                final approvedActivities = activitiesProvider.activities
                    .where((activity) => activity.statut == 'approuve')
                    .length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tableau de bord',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // ✅ GRILLE RESPONSIVE
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = (constraints.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard('Sites assignés', totalSites, Icons.location_city, Colors.blue),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard('Total activités', totalActivities, Icons.assignment, Colors.green),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard('Non synchronisées', unsyncedActivities, Icons.cloud_upload, 
                                                     unsyncedActivities > 0 ? Colors.orange : Colors.grey),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard('Approuvées', approvedActivities, Icons.check_circle, Colors.green),
                                ),
                              ],
                            );
                          },
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
              'Actions de synchronisation',
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Information hors ligne
            if (!_isOnline)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // ✅ ÉVITER L'OVERFLOW
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mode hors ligne : Vos activités sont sauvegardées localement et seront synchronisées automatiquement dès qu\'une connexion internet sera rétablie.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
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

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column( // ✅ CHANGÉ EN COLUMN POUR ÉVITER L'OVERFLOW
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // ✅ LIMITER LES LIGNES
            overflow: TextOverflow.ellipsis,
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
      await context.read<SitesProvider>().fetchSites();
      final syncCount = await context.read<ActivitiesProvider>().syncPendingActivities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synchronisation réussie - $syncCount activité(s) envoyée(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur de synchronisation'),
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
            content: Text('✅ Sites mis à jour'),
            backgroundColor: Colors.green,
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
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      context.read<AuthProvider>().logout();
    }
  }
}