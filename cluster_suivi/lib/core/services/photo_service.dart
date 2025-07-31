import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  // Prendre une photo avec la caméra
  static Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        return await _savePhotoLocally(photo);
      }
    } catch (e) {
      print('Erreur prise de photo: $e');
    }
    return null;
  }

  // Sélectionner une photo depuis la galerie
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        return await _savePhotoLocally(photo);
      }
    } catch (e) {
      print('Erreur sélection photo: $e');
    }
    return null;
  }

  // Sauvegarder la photo localement
  static Future<String> _savePhotoLocally(XFile photo) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String photoDir = path.join(appDir.path, 'photos');
    
    // Créer le dossier photos s'il n'existe pas
    await Directory(photoDir).create(recursive: true);
    
    // Générer un nom unique
    final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String localPath = path.join(photoDir, fileName);
    
    // Copier le fichier
    await File(photo.path).copy(localPath);
    
    return fileName; // Retourner juste le nom, pas le chemin complet
  }

  // Obtenir le chemin complet d'une photo
  static Future<String> getPhotoPath(String fileName) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'photos', fileName);
  }

  // Vérifier si une photo existe
  static Future<bool> photoExists(String fileName) async {
    final String fullPath = await getPhotoPath(fileName);
    return File(fullPath).exists();
  }

  // Supprimer une photo
  static Future<bool> deletePhoto(String fileName) async {
    try {
      final String fullPath = await getPhotoPath(fileName);
      final File file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Erreur suppression photo: $e');
    }
    return false;
  }
}