import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double requiredAccuracy = 20.0; // Précision requise

  // Vérifier les permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtenir la position avec précision
  Future<Position?> getCurrentPositionWithAccuracy() async {
    if (!await checkPermissions()) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      // Vérifier la précision
      if (position.accuracy <= requiredAccuracy) {
        return position;
      }

      return null; // Précision insuffisante
    } catch (e) {
      print('Erreur localisation: $e');
      return null;
    }
  }

  // Écouter les changements de position
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    );
  }
}