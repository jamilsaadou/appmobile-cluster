import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  DateTime? _lastActivity;
  bool _isOfflineMode = false; // ← NOUVEAU

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode; // ← NOUVEAU

  // Vérifier si la session est encore valide LOCALEMENT
  bool get isSessionValid {
    if (_lastActivity == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);
    return difference.inHours < 72; // 72h au lieu de 7h pour plus de persistance
  }

  // Mettre à jour l'activité utilisateur
  void updateActivity() {
    _lastActivity = DateTime.now();
    _storage.write(key: 'last_activity', value: _lastActivity!.toIso8601String());
  }

  // Connexion avec session persistante
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔐 Tentative de connexion...');
      
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final cookie = response.headers['set-cookie'];
        if (cookie != null) {
          await _storage.write(key: 'auth_cookie', value: cookie);
          await _storage.write(key: 'login_time', value: DateTime.now().toIso8601String());
          await _storage.write(key: 'user_email', value: email); // ← NOUVEAU
          await _storage.write(key: 'user_password_hash', value: password.hashCode.toString()); // ← NOUVEAU
          print('✅ Cookie et identifiants sauvegardés');
        }
        
        // Récupérer et sauvegarder les infos utilisateur
        await getCurrentUser();
        
        _isAuthenticated = true;
        _isOfflineMode = false;
        _lastActivity = DateTime.now();
        await _storage.write(key: 'last_activity', value: _lastActivity!.toIso8601String());
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Erreur login: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erreur login online: $e');
      
      // ← NOUVEAU : Tentative de connexion offline
      final offlineSuccess = await _tryOfflineLogin(email, password);
      if (offlineSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ← NOUVELLE MÉTHODE : Connexion offline
  Future<bool> _tryOfflineLogin(String email, String password) async {
    try {
      final storedEmail = await _storage.read(key: 'user_email');
      final storedPasswordHash = await _storage.read(key: 'user_password_hash');
      final storedUserData = await _storage.read(key: 'cached_user_data');
      
      if (storedEmail == email && 
          storedPasswordHash == password.hashCode.toString() && 
          storedUserData != null) {
        
        print('✅ Connexion offline réussie');
        _user = jsonDecode(storedUserData);
        _isAuthenticated = true;
        _isOfflineMode = true;
        _lastActivity = DateTime.now();
        await _storage.write(key: 'last_activity', value: _lastActivity!.toIso8601String());
        
        return true;
      }
    } catch (e) {
      print('💥 Erreur connexion offline: $e');
    }
    
    return false;
  }

  // Récupérer l'utilisateur avec gestion offline améliorée
  Future<void> getCurrentUser() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) return;

      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        try {
          final response = await http.get(
            Uri.parse('$apiUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookie,
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            _user = jsonDecode(response.body);
            _isAuthenticated = true;
            _isOfflineMode = false;
            
            // ← NOUVEAU : Sauvegarder les données utilisateur pour usage offline
            await _storage.write(key: 'cached_user_data', value: response.body);
            
            updateActivity();
            notifyListeners();
            return;
          } else if (response.statusCode == 401) {
            print('⚠️ Session expirée - vérification locale...');
            // Ne pas déconnecter immédiatement, essayer en local d'abord
          }
        } catch (e) {
          print('💥 Erreur API getCurrentUser: $e');
          // Continuer avec les données locales
        }
      }

      // ← NOUVEAU : Fallback sur les données locales
      await _loadUserFromCache();
      
    } catch (e) {
      print('💥 Erreur getCurrentUser: $e');
      await _loadUserFromCache();
    }
  }

  // ← NOUVELLE MÉTHODE : Charger utilisateur depuis le cache
  Future<void> _loadUserFromCache() async {
    try {
      final cachedUserData = await _storage.read(key: 'cached_user_data');
      final lastActivityStr = await _storage.read(key: 'last_activity');
      
      if (cachedUserData != null) {
        _user = jsonDecode(cachedUserData);
        _isAuthenticated = true;
        _isOfflineMode = true;
        
        if (lastActivityStr != null) {
          _lastActivity = DateTime.parse(lastActivityStr);
        }
        
        print('✅ Utilisateur chargé depuis le cache (mode offline)');
        notifyListeners();
      }
    } catch (e) {
      print('💥 Erreur chargement cache utilisateur: $e');
    }
  }

  // Vérifier la session de manière intelligente
  Future<bool> checkSession() async {
    try {
      // Vérifier d'abord localement
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }

      // Vérifier si la session locale n'est pas trop ancienne
      final loginTimeStr = await _storage.read(key: 'login_time');
      if (loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();
        final hoursDiff = now.difference(loginTime).inHours;
        
        // ← MODIFIÉ : 72h au lieu de 7h
        if (hoursDiff > 72) {
          print('⚠️ Session trop ancienne (${hoursDiff}h) - déconnexion');
          await logout();
          return false;
        }
      }

      // ← NOUVEAU : D'abord charger depuis le cache
      await _loadUserFromCache();

      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        // ← MODIFIÉ : Essayer de mettre à jour depuis l'API sans déconnecter en cas d'échec
        try {
          final response = await http.get(
            Uri.parse('$apiUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookie,
            },
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            _user = jsonDecode(response.body);
            _isAuthenticated = true;
            _isOfflineMode = false;
            
            // Mettre à jour le cache
            await _storage.write(key: 'cached_user_data', value: response.body);
            
            updateActivity();
            notifyListeners();
            return true;
          } else {
            print('⚠️ Réponse API non-200: ${response.statusCode} - reste en mode offline');
            _isOfflineMode = true;
            notifyListeners();
            return _isAuthenticated; // Garder l'état actuel
          }
        } catch (e) {
          print('💥 Erreur API checkSession: $e - reste en mode offline');
          _isOfflineMode = true;
          notifyListeners();
          return _isAuthenticated; // Garder l'état actuel
        }
      } else {
        print('📱 Pas d\'internet - mode offline maintenu');
        _isOfflineMode = true;
        notifyListeners();
        return _isAuthenticated;
      }
    } catch (e) {
      print('💥 Erreur checkSession: $e');
      // En cas d'erreur, garder la session si elle existe localement
      await _loadUserFromCache();
      return _isAuthenticated;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie != null) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          try {
            await http.post(
              Uri.parse('$apiUrl/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookie,
              },
            ).timeout(const Duration(seconds: 5));
          } catch (e) {
            print('Erreur logout API: $e');
          }
        }
      }
    } finally {
      // ← MODIFIÉ : Nettoyer toutes les données
      await _storage.deleteAll();
      _isAuthenticated = false;
      _user = null;
      _lastActivity = null;
      _isOfflineMode = false;
      notifyListeners();
    }
  }

  // Vérifier au démarrage avec persistance offline
  Future<void> checkAuthStatus() async {
    print('🔐 Vérification du statut d\'authentification...');
    
    // Charger d'abord les données locales
    await _loadUserFromCache();
    
    // Puis vérifier la session
    await checkSession();
  }
}