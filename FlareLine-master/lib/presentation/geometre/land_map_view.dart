import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flareline/core/api/openroute_service.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/route_entity.dart';
import 'package:flareline/presentation/geometre/widgets/route_layer.dart';
import 'package:flareline/presentation/geometre/widgets/map_control_buttons.dart';
import 'package:logger/logger.dart';

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
  late OpenRouteService routeService;

  RouteEntity? route;
  bool showRoute = false;
  bool loadingRoute = false;

  @override
void initState() {
  super.initState();
  mapController = MapController();
  
  routeService = getIt<OpenRouteService>();
  
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
        // Réinitialiser l'itinéraire si on change de terrain
        setState(() {
          route = null;
          showRoute = false;
        });
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  // Fonction pour récupérer l'itinéraire
  Future<void> _fetchRoute() async {
    setState(() {
      loadingRoute = true;
    });

    try {
      // Simulez la position actuelle de l'utilisateur
      final userLat = widget.land.latitude! - 0.02;
      final userLng = widget.land.longitude! - 0.01;

      final origin = LatLng(userLat, userLng);
      final destination = LatLng(widget.land.latitude!, widget.land.longitude!);

      // Essayez d'abord avec la méthode POST
      var fetchedRoute = await routeService.getRoute(
        origin: origin,
        destination: destination,
      );

      // Si la méthode POST échoue, essayez la méthode GET
      if (fetchedRoute == null) {
        getIt<Logger>().log(
          Level.info,
          'POST request failed, trying GET request',
        );

        fetchedRoute = await routeService.getRouteViaGet(
          origin: origin,
          destination: destination,
        );
      }

      if (fetchedRoute != null && fetchedRoute.points.isNotEmpty) {
        setState(() {
          route = fetchedRoute;
          showRoute = true;
          loadingRoute = false;
        });

        // Ajuster la vue de la carte pour montrer tout l'itinéraire
        final bounds = LatLngBounds.fromPoints(fetchedRoute.points);
        mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(padding: EdgeInsets.all(30)),
        );
      } else {
        setState(() {
          loadingRoute = false;
        });

        _showErrorDialog(
            'Impossible de récupérer l\'itinéraire. Veuillez réessayer.');
      }
    } catch (e) {
      getIt<Logger>().log(
        Level.error,
        'Error fetching route',
        error: e.toString(),
      );

      setState(() {
        loadingRoute = false;
      });

      _showErrorDialog(
          'Une erreur s\'est produite. Veuillez réessayer plus tard.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Fonction pour afficher ou masquer l'itinéraire
  void _toggleRoute() async {
    if (showRoute) {
      setState(() {
        showRoute = false;
      });
    } else {
      if (route == null) {
        await _fetchRoute();
      } else {
        setState(() {
          showRoute = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carte
        Expanded(
          flex: 80,
          child: _buildMap(),
        ),

        // Boutons de contrôle
        Expanded(
          flex: 20,
          child: MapControlButtons(
            onStartValidation: widget.onStartValidation,
            onToggleRoute: _toggleRoute,
            showRoute: showRoute,
            loadingRoute: loadingRoute,
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(widget.land.latitude!, widget.land.longitude!),
          zoom: 15,
        ),
        children: [
          // Couche de tuiles (fond de carte)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.flareline.app',
            tileProvider: CancellableNetworkTileProvider(),
          ),

          // Couche d'itinéraire (si actif)
          if (showRoute && route != null) RouteLayer(route: route!),

          // Marqueur du terrain
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(widget.land.latitude!, widget.land.longitude!),
                width: 80,
                height: 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Label du terrain
                    Positioned(
                      bottom: 25,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
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
                        color: Colors.deepPurple,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
