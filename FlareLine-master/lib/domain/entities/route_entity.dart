import 'package:latlong2/latlong.dart';

class RouteEntity {
  final List<LatLng> points;
  final double distance; // en mètres
  final double duration; // en secondes
  
  RouteEntity({
    required this.points,
    required this.distance,
    required this.duration,
  });
  
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }
  
  String get formattedDuration {
    final int minutes = (duration / 60).floor();
    if (minutes >= 60) {
      final int hours = (minutes / 60).floor();
      final int remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes.toString().padLeft(2, '0')} min';
    }
    return '$minutes min';
  }
}