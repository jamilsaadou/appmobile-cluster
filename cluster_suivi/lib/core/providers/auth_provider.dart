import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  DateTime? _lastActivity;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  // Vérifier si la session est encore valide
  bool get isSessionValid {
    if (_lastActivity == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);
    return difference.inHours < 7; // Session valide 7h
  }

  // Mettre à jour l'activité utilisateur
  void updateActivity() {
    _lastActivity = DateTime.now();
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
        // Sauvegarder le cookie avec timestamp
        final cookie = response.headers['set-cookie'];
        if (cookie != null) {
          await _storage.write(key: 'auth_cookie', value: cookie);
          await _storage.write(key: 'login_time', value: DateTime.now().toIso8601String());
          print('✅ Cookie sauvegardé avec timestamp');
        }
        
        // Récupérer les infos utilisateur
        await getCurrentUser();
        
        _isAuthenticated = true;
        _lastActivity = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Erreur login: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erreur login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Récupérer l'utilisateur avec gestion d'erreur session
  Future<void> getCurrentUser() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) return;

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
        updateActivity();
        notifyListeners();
      } else if (response.statusCode == 401) {
        print('⚠️ Session expirée - déconnexion automatique');
        await logout();
      }
    } catch (e) {
      print('💥 Erreur getCurrentUser: $e');
    }
  }

  // Vérifier périodiquement la session
  Future<bool> checkSession() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }

      // Vérifier si pas trop ancien
      final loginTimeStr = await _storage.read(key: 'login_time');
      if (loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();
        final hoursDiff = now.difference(loginTime).inHours;
        
        if (hoursDiff > 7) {
          print('⚠️ Session trop ancienne (${hoursDiff}h) - déconnexion');
          await logout();
          return false;
        }
      }

      // Test rapide de l'API
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
        updateActivity();
        notifyListeners();
        return true;
      } else {
        print('⚠️ Session invalide - code ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      print('💥 Erreur checkSession: $e');
      return _isAuthenticated; // Garder le statut actuel si erreur réseau
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie != null) {
        await http.post(
          Uri.parse('$apiUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookie,
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('Erreur logout API: $e');
    } finally {
      await _storage.delete(key: 'auth_cookie');
      await _storage.delete(key: 'login_time');
      _isAuthenticated = false;
      _user = null;
      _lastActivity = null;
      notifyListeners();
    }
  }

  // Vérifier au démarrage
  Future<void> checkAuthStatus() async {
    await checkSession();
  }
}