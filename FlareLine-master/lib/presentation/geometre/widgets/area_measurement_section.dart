import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show pi, cos;

import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';

/// Section pour la mesure de superficie
class AreaMeasurementSection extends StatefulWidget {
  final TextEditingController controller;
  final Land land;

  const AreaMeasurementSection({
    super.key,
    required this.controller,
    required this.land,
  });

  @override
  State<AreaMeasurementSection> createState() => _AreaMeasurementSectionState();
}

class _AreaMeasurementSectionState extends State<AreaMeasurementSection> {
  List<LatLng> _measurementPoints = [];
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutBorderTextFormField(
            controller: widget.controller,
            labelText: "Surface mesurée",
            hintText: "Entrer la surface mesurée en m²",
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La surface mesurée est requise';
              }
              if (double.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _openAreaMeasurement(widget.land),
          icon: const Icon(Icons.square_foot),
          label: const Text('Mesurer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ],
    );
  }

  /// Ouvre la boîte de dialogue pour mesurer la superficie
  void _openAreaMeasurement(Land land) {
    // Copie locale des points pour la boîte de dialogue
    List<LatLng> dialogPoints = List.from(_measurementPoints);
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              child: Column(
                children: [
                  // En-tête du dialogue avec bouton refresh
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Mesure de superficie - ${land.title}',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Bouton Refresh
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recommencer la mesure',
                        onPressed: () {
                          setDialogState(() {
                            dialogPoints.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      if (dialogPoints.length >= 3)
                        TextButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Terminer'),
                          onPressed: () {
                            // Calculer la superficie et l'appliquer au formulaire
                            double area = _calculateAreaFromGpsPoints(dialogPoints);
                            setState(() {
                              _measurementPoints = dialogPoints;
                              widget.controller.text = area.toStringAsFixed(2);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          'Tapez sur la carte pour placer des points autour du terrain. '
                          'Placez au moins 3 points pour calculer la superficie.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        if (dialogPoints.isNotEmpty) 
                          const Text(
                            'Utilisez le bouton ↻ pour recommencer la mesure.',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Carte
                  Expanded(
                    child: _buildMeasurementMap(land, dialogPoints, setDialogState),
                  ),
                  // Pied de page avec statistiques
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Points placés: ${dialogPoints.length}'),
                              if (dialogPoints.length >= 3)
                                Text(
                                  'Surface estimée: ${_calculateAreaFromGpsPoints(dialogPoints).toStringAsFixed(2)} m²',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                        // Bouton pour effacer les points
                        if (dialogPoints.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Effacer tous les points'),
                            onPressed: () {
                              setDialogState(() {
                                dialogPoints.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Construit la carte pour la mesure
  Widget _buildMeasurementMap(Land land, List<LatLng> points, StateSetter setState) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(land.latitude!, land.longitude!),
        initialZoom: 18,
        onTap: (tapPosition, point) {
          // Mise à jour de l'état local du dialogue
          setState(() {
            points.add(point);
            developer.log("Point ajouté: $point"); // Debug
          });
        },
      ),
      children: [
        // Couche de tuiles
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        // Marqueur pour le terrain
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(land.latitude!, land.longitude!),
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ],
        ),
        // Afficher les points de mesure
        MarkerLayer(
          markers: List.generate(
            points.length,
            (i) => Marker(
              width: 30.0,
              height: 30.0,
              point: points[i],
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.7),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Polygone si assez de points
        if (points.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: points,
                color: Colors.orange.withOpacity(0.2),
                borderColor: Colors.orange,
                borderStrokeWidth: 3,
              ),
            ],
          ),
        // Polylignes pour relier les points
        PolylineLayer(
          polylines: [
            Polyline(
              points: points.isEmpty ? [] : [
                ...points,
                if (points.length > 2) points.first
              ],
              color: Colors.orange,
              strokeWidth: 3.0,
            ),
          ],
        ),
      ],
    );
  }

  /// Calcule la superficie en m² à partir de points GPS
  double _calculateAreaFromGpsPoints(List<LatLng> points) {
    if (points.length < 3) return 0;
    
    // Formule de Gauss pour calculer l'aire
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() * 0.5;
    
    // Convertir en mètres carrés (approximatif, dépend de la latitude)
    final center = LatLng(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    );
    
    // Facteurs de conversion
    final double latRad = center.latitude * pi / 180.0;
    final double metersPerDegreeLat = 111132.92 - 559.82 * cos(2 * latRad) + 
        1.175 * cos(4 * latRad);
    final double metersPerDegreeLon = 111412.84 * cos(latRad) - 
        93.5 * cos(3 * latRad);
        
    return area * metersPerDegreeLat * metersPerDegreeLon;
  }
}