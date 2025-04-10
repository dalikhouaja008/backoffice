import 'package:latlong2/latlong.dart';

class RouteEntity {
  final List<LatLng> points;
  final double distance; 
  final double duration; 
  
  RouteEntity({
    required this.points,
    this.distance = 0.0,
    this.duration = 0.0,
  });
  
  /// Retourne la distance formatée en km ou m
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
  
 /// Retourne la durée formatée en heures, minutes ou secondes
  String get formattedDuration {
    if (duration < 60) {
      return '${duration.toStringAsFixed(0)}s';
    } else if (duration < 3600) {
      return '${(duration / 60).toStringAsFixed(0)}min';
    } else {
      final hours = (duration / 3600).floor();
      final minutes = ((duration % 3600) / 60).floor();
      return '${hours}h${minutes > 0 ? minutes : ''}';
    }
  }
}