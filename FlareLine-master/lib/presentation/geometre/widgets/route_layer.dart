import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flareline/domain/entities/route_entity.dart';

class RouteLayer extends StatelessWidget {
  final RouteEntity route;
  final bool showMarkers;

  const RouteLayer({
    Key? key,
    required this.route,
    this.showMarkers = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (route.points.isEmpty) {
      return Container();
    }

    return Stack(
      children: [
        // Ligne de l'itinéraire
        PolylineLayer(
          polylines: [
            Polyline(
              points: route.points,
              strokeWidth: 4.0,
              color: Colors.blue,
              borderColor: Colors.blue.shade800,
              borderStrokeWidth: 1.0,
            ),
          ],
        ),
        
        // Marqueurs de départ/fin si demandé
        if (showMarkers)
          MarkerLayer(
            markers: [
              // Marqueur de départ
              Marker(
                point: route.points.first,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              // Marqueur d'arrivée (déjà géré par la vue principale)
            ],
          ),
          
        // Info-bulle avec distance et durée
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      route.formattedDistance,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(route.formattedDuration),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}