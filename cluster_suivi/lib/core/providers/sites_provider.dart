import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../database/models/site.dart';

class SitesProvider with ChangeNotifier {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  List<Site> _sites = [];
  bool _isLoading = false;
  String? _error;

  List<Site> get sites => _sites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupérer les sites (API + local)
  Future<void> fetchSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // D'abord charger les sites locaux
      await _loadLocalSites();
      
      // Puis essayer de synchroniser avec l'API
      await _syncWithApi();
      
    } catch (e) {
      _error = 'Erreur lors du chargement des sites: $e';
      print('Erreur fetchSites: $e');
      
      // En cas d'erreur API, on garde les sites locaux
      await _loadLocalSites();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Charger les sites depuis la base locale
  Future<void> _loadLocalSites() async {
    try {
      final db = await DatabaseHelper().database;
      final sitesData = await db.query('sites', orderBy: 'nom ASC');
      
      _sites = sitesData.map((data) => Site.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur _loadLocalSites: $e');
    }
  }

  // Synchroniser avec l'API
  Future<void> _syncWithApi() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) return;

      final response = await http.get(
        Uri.parse('$apiUrl/sites'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiSites = data['sites'] as List;
        
        // Sauvegarder en local et mettre à jour la liste
        await _saveSitesToLocal(apiSites);
        await _loadLocalSites();
      }
    } catch (e) {
      print('Erreur sync API: $e');
      // On continue avec les données locales
    }
  }

  // Sauvegarder les sites en local
  Future<void> _saveSitesToLocal(List<dynamic> apiSites) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Vider la table (on fait une synchronisation complète)
      await db.delete('sites');
      
      // Insérer les nouveaux sites
      for (final apiSite in apiSites) {
        final site = Site.fromApi(apiSite);
        await db.insert('sites', site.toMap());
      }
    } catch (e) {
      print('Erreur _saveSitesToLocal: $e');
    }
  }
}