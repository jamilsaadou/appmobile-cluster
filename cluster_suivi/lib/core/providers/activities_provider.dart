import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import '../database/database_helper.dart';
import '../database/models/activity.dart';
import '../services/upload_service.dart';
import '../services/photo_service.dart';

class ActivitiesProvider with ChangeNotifier {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Ajouter une activité (mode offline)
  Future<bool> addActivity(Activity activity) async {
    try {
      print('🚀 Tentative d\'ajout activité: ${activity.type}');
      
      final db = await DatabaseHelper().database;
      
      // Vérifier les champs obligatoires
      if (activity.type.isEmpty || activity.thematique.isEmpty) {
        print('❌ Champs obligatoires manquants');
        return false;
      }
      
      // Préparer les données
      final activityMap = activity.toMap();
      print('📝 Données à insérer: $activityMap');
      
      // Insérer en local
      await db.insert('activities', activityMap);
      print('✅ Activité insérée en base locale');
      
      // Mettre à jour la liste
      _activities.insert(0, activity);
      notifyListeners();
      
      // Essayer de synchroniser immédiatement
      await _trySyncActivity(activity);
      
      return true;
    } catch (e) {
      print('💥 Erreur addActivity: $e');
      _error = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE : Synchroniser les statuts depuis l'API
  Future<void> syncActivityStatuses() async {
    try {
      print('🔄 [SYNC_STATUS] Début synchronisation des statuts...');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('⚠️ [SYNC_STATUS] Pas de cookie - pas de sync');
        return;
      }

      // Récupérer les activités depuis l'API
      final response = await http.get(
        Uri.parse('$apiUrl/activites'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 [SYNC_STATUS] Response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> apiActivities = jsonDecode(response.body);
        print('📄 [SYNC_STATUS] ${apiActivities.length} activités récupérées de l\'API');

        final db = await DatabaseHelper().database;
        int updatedCount = 0;

        // Mettre à jour les statuts des activités existantes
        for (final apiActivity in apiActivities) {
          try {
            final apiId = apiActivity['id'];
            if (apiId != null) {
              final statut = apiActivity['statut'] ?? 'en_attente';
              final motifRefus = apiActivity['motifRejet'] ?? apiActivity['motifRefus'];

              // Chercher l'activité locale correspondante (par ID si synchronisée)
              final existingActivities = await db.query(
                'activities',
                where: 'id = ? OR local_id = ?',
                whereArgs: [apiId, apiId.toString()],
              );

              if (existingActivities.isNotEmpty) {
                final localActivity = existingActivities.first;
                final currentStatus = localActivity['statut'] ?? 'en_attente';

                // Mettre à jour seulement si le statut a changé
                if (currentStatus != statut) {
                  await db.update(
                    'activities',
                    {
                      'statut': statut,
                      'motif_refus': motifRefus,
                      'id': apiId, // S'assurer que l'ID serveur est sauvegardé
                      'is_synced': 1,
                    },
                    where: 'local_id = ? OR id = ?',
                    whereArgs: [localActivity['local_id'], apiId],
                  );

                  updatedCount++;
                  print('✅ [SYNC_STATUS] Activité ${localActivity['local_id']} mise à jour: $currentStatus -> $statut');
                }
              } else {
                // Activité n'existe pas localement, l'ajouter
                final newActivity = Activity.fromApiJson(apiActivity);
                await db.insert('activities', newActivity.toMap());
                updatedCount++;
                print('✅ [SYNC_STATUS] Nouvelle activité ajoutée: ${newActivity.localId}');
              }
            }
          } catch (e) {
            print('⚠️ [SYNC_STATUS] Erreur traitement activité individuelle: $e');
          }
        }

        print('📊 [SYNC_STATUS] Synchronisation terminée: $updatedCount activités mises à jour');

        // Recharger les activités depuis la base locale
        await loadLocalActivities();
      } else {
        print('❌ [SYNC_STATUS] Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 [SYNC_STATUS] Erreur complète: $e');
    }
  }

  // Méthode _trySyncActivity COMPLÈTEMENT RÉÉCRITE
  Future<void> _trySyncActivity(Activity activity) async {
    try {
      print('🎯 [SYNC] Début sync: ${activity.type}');
      print('🎯 [SYNC] Local ID: ${activity.localId}');
      print('🎯 [SYNC] Photos: ${activity.photos?.length ?? 0}');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('⚠️ [SYNC] Pas de cookie - pas de sync');
        return;
      }

      // Préparer les données de base
      final apiData = activity.toApiJson();
      print('📝 [SYNC] Données API de base: $apiData');
      
      // ✅ Vérifier s'il y a des photos à envoyer
      if (activity.photos != null && activity.photos!.isNotEmpty) {
        print('📸 [SYNC] Activité avec ${activity.photos!.length} photos');
        
        // Convertir les noms en chemins complets
        List<String> localPaths = [];
        for (final photoName in activity.photos!) {
          final fullPath = await PhotoService.getPhotoPath(photoName);
          final file = File(fullPath);
          if (await file.exists()) {
            localPaths.add(fullPath);
            print('✅ [SYNC] Photo trouvée: $photoName -> $fullPath');
          } else {
            print('❌ [SYNC] Photo manquante: $photoName -> $fullPath');
          }
        }
        
        if (localPaths.isNotEmpty) {
          print('📸 [SYNC] ${localPaths.length} photos valides trouvées');
          
          // ✅ Utiliser le service d'upload corrigé
          final success = await PhotoUploadService.sendActivityWithPhotos(apiData, localPaths);
          
          if (success) {
            print('✅ [SYNC] Activité + photos envoyées avec succès');
            await _markActivityAsSynced(activity);
          } else {
            print('❌ [SYNC] Échec envoi activité + photos');
          }
          return;
        } else {
          print('⚠️ [SYNC] Aucune photo valide trouvée, envoi sans photos');
          // Continuer sans photos
        }
      }
      
      // ✅ Activité sans photos OU photos manquantes - méthode normale
      print('📤 [SYNC] Envoi activité sans photos');
      print('📤 [SYNC] Données: ${jsonEncode(apiData)}');
      
      final response = await http.post(
        Uri.parse('$apiUrl/activites'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
        body: jsonEncode(apiData),
      ).timeout(const Duration(seconds: 30));

      print('📊 [SYNC] Response code: ${response.statusCode}');
      print('📄 [SYNC] Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ [SYNC] Activité synchronisée sans photos');
        
        // ✅ Récupérer l'ID serveur de la réponse
        try {
          final responseData = jsonDecode(response.body);
          final serverId = responseData['id'];
          if (serverId != null) {
            await _markActivityAsSynced(activity, serverId: serverId);
          } else {
            await _markActivityAsSynced(activity);
          }
        } catch (e) {
          print('⚠️ [SYNC] Erreur parsing réponse: $e');
          await _markActivityAsSynced(activity);
        }
      } else {
        print('❌ [SYNC] Erreur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 [SYNC] Erreur complète: $e');
      print('💥 [SYNC] Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ MÉTHODE helper pour marquer comme synchronisé (mise à jour)
  Future<void> _markActivityAsSynced(Activity activity, {int? serverId}) async {
    try {
      final db = await DatabaseHelper().database;
      
      final updateData = <String, dynamic>{
        'is_synced': 1,
      };
      
      // Si on a un ID serveur, le sauvegarder
      if (serverId != null) {
        updateData['id'] = serverId;
      }
      
      final rowsUpdated = await db.update(
        'activities',
        updateData,
        where: 'local_id = ?',
        whereArgs: [activity.localId],
      );
      
      print('📝 [SYNC] Activité marquée comme synchronisée: $rowsUpdated lignes mises à jour');
      if (serverId != null) {
        print('📝 [SYNC] ID serveur sauvegardé: $serverId');
      }
      
      // Recharger la liste des activités
      await loadLocalActivities();
    } catch (e) {
      print('💥 [SYNC] Erreur marquage sync: $e');
    }
  }

  // Charger les activités locales
  Future<void> loadLocalActivities() async {
    try {
      print('📂 Chargement activités locales...');
      
      final db = await DatabaseHelper().database;
      final activitiesData = await db.query(
        'activities',
        orderBy: 'date_creation DESC',
      );
      
      print('📊 ${activitiesData.length} activités trouvées');
      
      _activities = activitiesData.map((data) {
        try {
          return Activity.fromMap(data);
        } catch (e) {
          print('⚠️ Erreur parsing activité: $e');
          print('📝 Données: $data');
          return null;
        }
      }).where((activity) => activity != null).cast<Activity>().toList();
      
      notifyListeners();
    } catch (e) {
      print('💥 Erreur loadLocalActivities: $e');
    }
  }

  // ✅ MÉTHODE MISE À JOUR : Synchroniser toutes les activités et les statuts
  Future<int> syncPendingActivities() async {
    int syncCount = 0;
    
    try {
      print('🔄 Début synchronisation complète...');
      
      // 1. D'abord synchroniser les statuts depuis l'API
      await syncActivityStatuses();
      
      // 2. Ensuite envoyer les activités non synchronisées
      final db = await DatabaseHelper().database;
      final pendingActivities = await db.query(
        'activities',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      print('📊 ${pendingActivities.length} activités à synchroniser');

      for (final activityData in pendingActivities) {
        try {
          final activity = Activity.fromMap(activityData);
          print('🔄 Sync activité: ${activity.type} (${activity.localId})');
          await _trySyncActivity(activity);
          syncCount++;
        } catch (e) {
          print('⚠️ Erreur sync activité individuelle: $e');
        }
      }
      
      print('📊 Synchronisation terminée: $syncCount activités traitées');
    } catch (e) {
      print('💥 Erreur syncPendingActivities: $e');
    }

    return syncCount;
  }

  // Récupérer une activité par ID
  Future<Activity?> getActivityById(dynamic id) async {
    try {
      final db = await DatabaseHelper().database;
      
      List<Map<String, dynamic>> results;
      if (id is String) {
        // Recherche par local_id
        results = await db.query(
          'activities',
          where: 'local_id = ?',
          whereArgs: [id],
        );
      } else {
        // Recherche par id
        results = await db.query(
          'activities',
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      if (results.isNotEmpty) {
        return Activity.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('💥 Erreur getActivityById: $e');
      return null;
    }
  }

  // Mettre à jour une activité
  Future<bool> updateActivity(Activity activity) async {
    try {
      print('🔄 [UPDATE] Début mise à jour activité: ${activity.type}');
      
      final db = await DatabaseHelper().database;
      
      // Mettre à jour en base locale
      final activityMap = activity.toMap();
      activityMap['is_synced'] = 0; // Marquer comme non synchronisé
      
      int rowsUpdated;
      if (activity.id != null) {
        rowsUpdated = await db.update(
          'activities',
          activityMap,
          where: 'id = ?',
          whereArgs: [activity.id],
        );
      } else {
        rowsUpdated = await db.update(
          'activities',
          activityMap,
          where: 'local_id = ?',
          whereArgs: [activity.localId],
        );
      }
      
      print('✅ [UPDATE] Activité mise à jour: $rowsUpdated lignes affectées');
      
      // Recharger la liste
      await loadLocalActivities();
      
      // Essayer de synchroniser immédiatement
      await _trySyncActivity(activity);
      
      return rowsUpdated > 0;
    } catch (e) {
      print('💥 [UPDATE] Erreur updateActivity: $e');
      _error = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE : Synchroniser automatiquement les statuts
  Future<void> autoSyncStatuses() async {
    try {
      print('⏰ [AUTO_SYNC] Synchronisation automatique des statuts...');
      await syncActivityStatuses();
      print('✅ [AUTO_SYNC] Synchronisation automatique terminée');
    } catch (e) {
      print('💥 [AUTO_SYNC] Erreur: $e');
    }
  }
}