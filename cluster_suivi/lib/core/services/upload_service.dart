import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PhotoUploadService {
  static const String apiUrl = 'https://rapports-c.org/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Convertir une photo en base64
  static Future<String?> photoToBase64(String localFilePath) async {
    try {
      print('📸 [B64] Conversion en base64: $localFilePath');
      
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('❌ [B64] Fichier inexistant: $localFilePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final fileSize = bytes.length;
      
      print('✅ [B64] Conversion réussie: ${fileSize} bytes → ${base64String.length} chars');
      return base64String;
    } catch (e) {
      print('💥 [B64] Erreur conversion: $e');
      return null;
    }
  }

  // Convertir plusieurs photos en base64
  static Future<List<Map<String, String>>> convertPhotosToBase64(List<String> localFilePaths) async {
    print('🚀 [B64] Conversion de ${localFilePaths.length} photos...');
    
    final List<Map<String, String>> base64Photos = [];
    
    for (int i = 0; i < localFilePaths.length; i++) {
      final localPath = localFilePaths[i];
      print('📸 [B64] Photo ${i+1}/${localFilePaths.length}: $localPath');
      
      final base64Data = await photoToBase64(localPath);
      if (base64Data != null) {
        final fileName = localPath.split('/').last;
        base64Photos.add({
          'filename': fileName,
          'data': base64Data,
          'mimetype': 'image/jpeg',
        });
        print('✅ [B64] Photo ${i+1} convertie: $fileName');
      } else {
        print('❌ [B64] Échec photo ${i+1}: $localPath');
      }
    }
    
    print('📊 [B64] Conversion terminée: ${base64Photos.length}/${localFilePaths.length}');
    return base64Photos;
  }

  // Envoyer l'activité avec photos intégrées
  static Future<bool> sendActivityWithPhotos(
    Map<String, dynamic> activityData,
    List<String> localPhotoPaths,
  ) async {
    try {
      print('🚀 [SEND] Envoi activité avec ${localPhotoPaths.length} photos...');
      
      final cookie = await _storage.read(key: 'auth_cookie');
      if (cookie == null) {
        print('❌ [SEND] Pas de cookie auth');
        return false;
      }

      // Convertir les photos en base64
      final base64Photos = await convertPhotosToBase64(localPhotoPaths);
      
      // Ajouter les photos aux données
      final finalData = Map<String, dynamic>.from(activityData);
      finalData['photosBase64'] = base64Photos;
      
      print('📤 [SEND] Données finales:');
      print('   - Type: ${finalData['typeActivite']}');
      print('   - Photos: ${base64Photos.length} photos encodées');
      print('   - Taille totale: ${jsonEncode(finalData).length} chars');

      final response = await http.post(
        Uri.parse('$apiUrl/activites'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
        body: jsonEncode(finalData),
      ).timeout(const Duration(seconds: 60)); // Plus de temps pour les photos

      print('📊 [SEND] Response: ${response.statusCode}');
      print('📄 [SEND] Body: ${response.body}');

      return response.statusCode == 201;
      
    } catch (e) {
      print('💥 [SEND] Erreur: $e');
      return false;
    }
  }
}