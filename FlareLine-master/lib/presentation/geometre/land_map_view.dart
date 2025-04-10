// lib/presentation/geometre/land_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:logger/logger.dart';
import 'package:flareline/core/injection/injection.dart';

class LandMapView extends StatefulWidget {
  final Land land;
  final VoidCallback onStartValidation;

  const LandMapView({
    Key? key,
    required this.land,
    required this.onStartValidation,
  }) : super(key: key);

  @override
  State<LandMapView> createState() => _LandMapViewState();
}

class _LandMapViewState extends State<LandMapView> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  void didUpdateWidget(LandMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.land.id != widget.land.id) {
      // Mise à jour de la position de la carte quand le terrain change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(
          LatLng(widget.land.latitude!, widget.land.longitude!),
          15,
        );
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getIt<Logger>().log(
      Level.info,
      'Building map view for land',
      error: {
        'landId': widget.land.id,
        'timestamp': '2025-04-10 19:52:25',
        'userLogin': 'dalikhouaja008',
        'coordinates': '${widget.land.latitude}, ${widget.land.longitude}'
      },
    );

    return Column(
      children: [
        Expanded(
          flex: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: LatLng(widget.land.latitude!, widget.land.longitude!),
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.flareline.app',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          LatLng(widget.land.latitude!, widget.land.longitude!),
                      width: 80,
                      height: 60, // Réduit la hauteur
                      child: Stack(
                        // Utilisation d'un Stack au lieu d'une Column
                        clipBehavior:
                            Clip.none, // Permet au contenu de déborder du Stack
                        children: [
                          // Label au-dessus
                          Positioned(
                            bottom: 25, // Position au-dessus de l'icône
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.land.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Icône de localisation
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            left: 0,
                            child: Icon(
                              Icons.location_on,
                              color: GlobalColors.primary,
                              size: 25, // Taille légèrement réduite
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleInfo(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: widget.land.location,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleInfo(
                    icon: Icons.square_foot,
                    label: 'Surface',
                    value: '${widget.land.surface} m²',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: GlobalColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
