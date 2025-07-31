import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart'; // ← NOUVEAU IMPORT NÉCESSAIRE
import 'package:http_parser/http_parser.dart'; // ← IMPORT POUR MediaType

class PhotoUploadService {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ✅ MÉTHODE POUR DÉTECTER LE BON TYPE MIME
  static String _getMimeType(String filePath) {
    // Essayer de détecter automatiquement
    String? mimeType = lookupMimeType(filePath);
    
    if (mimeType != null && mimeType.startsWith('image/')) {
      return mimeType;
    }
    
    // Fallback selon l'extension
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // Par défaut
    }
  }

  // Upload d'images en multipart - VERSION CORRIGÉE
  static Future<List<String>> uploadImages(List<String> localPhotoPaths) async {
    List<String> uploadedFilenames = [];
    
    try {
      print('📸 [UPLOAD] Début upload de ${localPhotoPaths.length} images...');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('❌ [UPLOAD] Pas de cookie auth');
        return [];
      }

      for (int i = 0; i < localPhotoPaths.length; i++) {
        final localPath = localPhotoPaths[i];
        print('📸 [UPLOAD] Image ${i+1}/${localPhotoPaths.length}: $localPath');
        
        final filename = await _uploadSingleImage(localPath, cookie);
        if (filename != null) {
          uploadedFilenames.add(filename);
          print('✅ [UPLOAD] Image ${i+1} uploadée: $filename');
        } else {
          print('❌ [UPLOAD] Échec image ${i+1}: $localPath');
        }
      }
      
      print('📊 [UPLOAD] Upload terminé: ${uploadedFilenames.length}/${localPhotoPaths.length}');
      return uploadedFilenames;
      
    } catch (e) {
      print('💥 [UPLOAD] Erreur générale: $e');
      return uploadedFilenames;
    }
  }

  // ✅ Upload d'une seule image - VERSION CORRIGÉE AVEC MIME TYPE
  static Future<String?> _uploadSingleImage(String localPath, String cookie) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        print('❌ [UPLOAD] Fichier inexistant: $localPath');
        return null;
      }

      // ✅ Détecter le bon type MIME
      final mimeType = _getMimeType(localPath);
      final fileSize = await file.length();
      
      print('📋 [UPLOAD] Infos fichier:');
      print('   - Chemin: $localPath');
      print('   - Taille: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      print('   - Type MIME détecté: $mimeType');

      // Créer la requête multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/upload/images'),
      );

      // Ajouter les headers
      request.headers['Cookie'] = cookie;

      // ✅ Ajouter le fichier avec le bon type MIME
      final multipartFile = await http.MultipartFile.fromPath(
        'files', // Nom du champ attendu par l'API
        localPath,
        filename: localPath.split('/').last,
        contentType: MediaType.parse(mimeType), // ← FIX PRINCIPAL ICI
      );
      
      request.files.add(multipartFile);

      print('📤 [UPLOAD] Envoi avec type MIME: $mimeType');
      print('📤 [UPLOAD] Nom fichier: ${localPath.split('/').last}');
      
      // Envoyer la requête
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60)
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📊 [UPLOAD] Response: ${response.statusCode}');
      print('📄 [UPLOAD] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extraire le nom du fichier uploadé selon le format de réponse
        if (responseData['files'] != null && responseData['files'].isNotEmpty) {
          // Format: {"success": true, "files": [{"filename": "xxx.jpg", "fileName": "xxx.jpg"}]}
          final firstFile = responseData['files'][0];
          final fileName = firstFile['fileName'] ?? firstFile['filename'];
          print('✅ [UPLOAD] Fichier uploadé: $fileName');
          return fileName;
        } else if (responseData['filenames'] != null && responseData['filenames'].isNotEmpty) {
          // Format: {"filenames": ["xxx.jpg"]}
          final fileName = responseData['filenames'][0];
          print('✅ [UPLOAD] Fichier uploadé: $fileName');
          return fileName;
        } else if (responseData['filename'] != null) {
          // Format: {"filename": "xxx.jpg"}
          final fileName = responseData['filename'];
          print('✅ [UPLOAD] Fichier uploadé: $fileName');
          return fileName;
        } else {
          print('⚠️ [UPLOAD] Réponse inattendue: $responseData');
        }
      } else {
        print('❌ [UPLOAD] Erreur HTTP ${response.statusCode}: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('💥 [UPLOAD] Erreur upload image: $e');
      return null;
    }
  }

  // Envoyer activité avec photos uploadées
  static Future<bool> sendActivityWithPhotos(
    Map<String, dynamic> activityData,
    List<String> localPhotoPaths,
  ) async {
    try {
      print('🚀 [SEND] Début envoi activité avec ${localPhotoPaths.length} photos...');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('❌ [SEND] Pas de cookie auth');
        return false;
      }

      // 1. D'abord uploader les images
      final uploadedFilenames = await uploadImages(localPhotoPaths);
      
      if (uploadedFilenames.isEmpty && localPhotoPaths.isNotEmpty) {
        print('❌ [SEND] Aucune image uploadée, abandon');
        return false;
      }

      // 2. Préparer les données de l'activité avec les noms de fichiers uploadés
      final finalData = Map<String, dynamic>.from(activityData);
      finalData['photos'] = uploadedFilenames;
      
      print('📤 [SEND] Données finales:');
      print('   - Type: ${finalData['typeActivite']}');
      print('   - Photos: ${uploadedFilenames.length} fichiers uploadés');
      print('   - Photos list: $uploadedFilenames');

      // 3. Envoyer l'activité
      final response = await http.post(
        Uri.parse('$apiUrl/activites'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
        body: jsonEncode(finalData),
      ).timeout(const Duration(seconds: 30));

      print('📊 [SEND] Response: ${response.statusCode}');
      print('📄 [SEND] Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ [SEND] Activité créée avec succès');
        return true;
      } else {
        print('❌ [SEND] Erreur création activité: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('💥 [SEND] Erreur: $e');
      return false;
    }
  }

  // ✅ MÉTHODE DE TEST améliorée
  static Future<void> testImageUpload(String localPath) async {
    try {
      print('🧪 [TEST] ======== TEST UPLOAD ========');
      print('🧪 [TEST] Chemin: $localPath');
      
      final file = File(localPath);
      if (!await file.exists()) {
        print('❌ [TEST] Fichier inexistant');
        return;
      }
      
      final size = await file.length();
      final mimeType = _getMimeType(localPath);
      
      print('🧪 [TEST] Taille: ${(size / 1024).toStringAsFixed(1)} KB');
      print('🧪 [TEST] Type MIME: $mimeType');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('❌ [TEST] Pas de cookie');
        return;
      }

      final filename = await _uploadSingleImage(localPath, cookie);
      if (filename != null) {
        print('✅ [TEST] Upload réussi: $filename');
      } else {
        print('❌ [TEST] Upload échoué');
      }
      
      print('🧪 [TEST] ========================');
    } catch (e) {
      print('💥 [TEST] Erreur: $e');
    }
  }
}