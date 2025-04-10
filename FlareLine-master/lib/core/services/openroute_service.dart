// lib/core/api/openroute_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flareline/domain/entities/route_entity.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';

class OpenRouteService {
  final String apiKey;
  final String baseUrl;

  OpenRouteService({
    required this.apiKey,
    this.baseUrl = 'https://api.openrouteservice.org',
  });

  /// Récupère un itinéraire entre deux points pour le transport en voiture
  Future<RouteEntity?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Utilisation de POST avec l'en-tête Authorization comme spécifié dans la documentation
      final uri = Uri.parse('$baseUrl/v2/directions/driving-car/geojson');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey,  // Clé fournie dans l'en-tête Authorization
        },
        body: jsonEncode({
          'coordinates': [
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude],
          ],
        }),
      );

      getIt<Logger>().log(
        Level.info,
        'OpenRouteService API response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseRouteResponse(data);
      } else {
        getIt<Logger>().log(
          Level.error,
          'Failed to fetch route from OpenRouteService',
          error: {
            'status': response.statusCode,
            'response': response.body,
          },
        );
        return null;
      }
    } catch (e) {
      getIt<Logger>().log(
        Level.error,
        'Error calling OpenRouteService API',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Version alternative utilisant GET (à utiliser si la méthode POST ne fonctionne pas)
  Future<RouteEntity?> getRouteViaGet({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final startPoint = '${origin.longitude},${origin.latitude}';
      final endPoint = '${destination.longitude},${destination.latitude}';
      
      // Construction de l'URL avec les paramètres
      final uri = Uri.parse(
        '$baseUrl/v2/directions/driving-car?api_key=$apiKey&start=$startPoint&end=$endPoint'
      );
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseRouteResponse(data);
      } else {
        getIt<Logger>().log(
          Level.error,
          'Failed to fetch route from OpenRouteService via GET',
          error: {
            'status': response.statusCode,
            'response': response.body,
          },
        );
        return null;
      }
    } catch (e) {
      getIt<Logger>().log(
        Level.error,
        'Error calling OpenRouteService API via GET',
        error: e.toString(),
      );
      return null;
    }
  }

  RouteEntity _parseRouteResponse(Map<String, dynamic> data) {
    try {
      // Extraire les coordonnées de l'itinéraire
      final List<dynamic> coordinates = 
          data['features'][0]['geometry']['coordinates'] as List;
      
      final List<LatLng> points = coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
      
      // Extraire la durée et la distance
      final Map<String, dynamic> summary = 
          data['features'][0]['properties']['summary'] as Map<String, dynamic>;
      
      final double distance = summary['distance'] as double;
      final double duration = summary['duration'] as double;
      
      return RouteEntity(
        points: points,
        distance: distance,
        duration: duration,
      );
    } catch (e) {
      getIt<Logger>().log(
        Level.error,
        'Error parsing OpenRouteService response',
        error: e.toString(),
      );
      // Retourner un itinéraire vide en cas d'erreur de parsing
      return RouteEntity(
        points: [],
        distance: 0,
        duration: 0,
      );
    }
  }
}