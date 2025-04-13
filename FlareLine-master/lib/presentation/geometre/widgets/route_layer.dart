import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flareline/domain/entities/route_entity.dart';

class RouteLayer extends StatelessWidget {
  final RouteEntity route;
  final bool showMarkers;
  final bool showInfoBubble;

  const RouteLayer({
    Key? key,
    required this.route,
    this.showMarkers = true,
    this.showInfoBubble = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (route.points.isEmpty) {
      return Container();
    }
    
    // Vérifier si l'écran est petit
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bubblePadding = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final iconSize = isSmallScreen ? 14.0 : 16.0;
    
    return Stack(
      children: [
        // Ligne de l'itinéraire avec effet de dégradé
        PolylineLayer(
          polylines: [
            Polyline(
              points: route.points,
              strokeWidth: isSmallScreen ? 4.0 : 5.0,
              color: Colors.blue.shade600,
              borderColor: Colors.blue.shade900,
              borderStrokeWidth: isSmallScreen ? 0.5 : 1.0,
              //isDotted: false,
              gradientColors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
              ],
            ),
          ],
        ),
        
        // Marqueurs début/fin si demandés
        if (showMarkers)
          MarkerLayer(
            markers: [
              // Marqueur de départ (position utilisateur)
              Marker(
                point: route.points.first,
                width: isSmallScreen ? 16 : 20,
                height: isSmallScreen ? 16 : 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: isSmallScreen ? 1.5 : 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: isSmallScreen ? 2 : 3,
                        spreadRadius: isSmallScreen ? 0.5 : 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
        // Info-bulle avec distance et durée
        if (showInfoBubble)
          Positioned(
            top: isSmallScreen ? 8 : 10,
            right: isSmallScreen ? 8 : 10,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: bubblePadding, 
                vertical: bubblePadding / 1.5
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isSmallScreen ? 3 : 4,
                    offset: Offset(0, isSmallScreen ? 1 : 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car, size: iconSize, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        route.formattedDistance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: iconSize, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        route.formattedDuration,
                        style: TextStyle(fontSize: fontSize),
                      ),
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