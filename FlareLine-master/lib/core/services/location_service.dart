import 'package:flareline/core/utils/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

class LocationService {
  final Logger logger;

  LocationService({required this.logger});

  /// Vérifie si la localisation est disponible
  Future<bool> isLocationAvailable() async {
    // Sur le web ou en simulation, considérer que c'est toujours disponible
    if (PlatformUtils.isWeb) {
      return true;
    }
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission != LocationPermission.denied && 
             permission != LocationPermission.deniedForever;
    } catch (e) {
      logger.e('Erreur lors de la vérification de la localisation: $e');
      return false;
    }
  }

  /// Récupère la position actuelle de l'utilisateur
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Si nous sommes sur le web et que la géolocalisation n'est pas disponible
      if (PlatformUtils.isWeb && !kIsWeb) {
        return null;
      }
      
      // Vérifier les permissions
      bool locationAvailable = await isLocationAvailable();
      if (!locationAvailable) {
        return null;
      }
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      logger.e('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux points en mètres
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude, 
      point1.longitude, 
      point2.latitude, 
      point2.longitude
    );
  }

  /// Démarre la surveillance de la position (stream)
  Stream<LatLng>? getLocationStream({int distanceFilter = 10}) {
    try {
      if (PlatformUtils.isWeb && !kIsWeb) {
        return null;
      }
      
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter, // en mètres
        ),
      ).map((position) => LatLng(position.latitude, position.longitude));
    } catch (e) {
      logger.e('Erreur lors de la création du stream de localisation: $e');
      return null;
    }
  }
}