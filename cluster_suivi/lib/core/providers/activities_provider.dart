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

// ✅ Méthode _trySyncActivity COMPLÈTEMENT RÉÉCRITE
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
      await _markActivityAsSynced(activity);
    } else {
      print('❌ [SYNC] Erreur: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('💥 [SYNC] Erreur complète: $e');
    print('💥 [SYNC] Stack trace: ${StackTrace.current}');
  }
}

// ✅ NOUVELLE méthode helper pour marquer comme synchronisé
Future<void> _markActivityAsSynced(Activity activity) async {
  try {
    final db = await DatabaseHelper().database;
    final rowsUpdated = await db.update(
      'activities',
      {'is_synced': 1},
      where: 'local_id = ?',
      whereArgs: [activity.localId],
    );
    
    print('📝 [SYNC] Activité marquée comme synchronisée: $rowsUpdated lignes mises à jour');
    
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

  // Synchroniser toutes les activités non synchronisées
  Future<int> syncPendingActivities() async {
    int syncCount = 0;
    
    try {
      print('🔄 Début synchronisation des activités en attente...');
      
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
}