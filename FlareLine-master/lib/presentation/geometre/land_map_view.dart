import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/core/services/location_service.dart';
import 'package:flareline/core/services/openroute_service.dart';
import 'package:flareline/core/utils/platform_utils.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/route_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/geometre/LandValidationForm.dart';
import 'package:flareline/presentation/geometre/widgets/map_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math';

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
  late LocationService locationService;

  RouteEntity? route;
  bool showRoute = false;
  bool loadingRoute = false;
  LatLng? currentUserLocation;
  bool isTrackingLocation = false;
  bool isLowAccuracy = false;
  bool isUsingSimulatedLocation = false;
  bool isMapSatellite = false;
  double? currentAccuracyMeters;
  late StreamSubscription<GeometreState> _blocSubscription;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    routeService = getIt<OpenRouteService>();
    locationService = getIt<LocationService>();

    // Ajouter un listener pour gérer les états du bloc
    final geometreBloc = context.read<GeometreBloc>();
    _blocSubscription = geometreBloc.stream.listen((state) {
      if (state is ValidationSuccess) {
        // Fermer le dialogue de validation si ouvert
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
          ),
        );
      } else if (state is ValidationFailure) {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Vérifier si nous sommes sur desktop ou web
    if (PlatformUtils.isDesktop || PlatformUtils.isWeb) {
      // Activer la simulation par défaut
      isUsingSimulatedLocation = true;
    }

    // Obtenir la position initiale
    _getCurrentLocation(showError: false);
  }

  @override
  void dispose() {
    _blocSubscription.cancel();
    super.dispose();
  }

  // Méthode pour obtenir la position actuelle de l'utilisateur
  Future<void> _getCurrentLocation({bool showError = true}) async {
    try {
      setState(() {
        isTrackingLocation = true;
      });

      LatLng? position;

      // Utiliser une position simulée si nécessaire
      if (isUsingSimulatedLocation) {
        position = await _getSimulatedPosition();
      } else {
        position = await locationService.getCurrentLocation();
      }

      if (position != null) {
        setState(() {
          currentUserLocation = position;
          isLowAccuracy = false;
          currentAccuracyMeters = isUsingSimulatedLocation ? 10 : null;
          isTrackingLocation = false;
        });

        // Centrer la carte sur la position actuelle
        mapController.move(currentUserLocation!, 15.0);
      } else {
        setState(() {
          isTrackingLocation = false;
        });

        if (showError) {
          _showErrorDialog('Localisation impossible',
              'Impossible d\'obtenir votre position. Veuillez vérifier vos paramètres de localisation.');
        }
      }
    } catch (e) {
      setState(() {
        isTrackingLocation = false;
      });

      if (showError) {
        _showErrorDialog('Erreur de localisation',
            'Une erreur est survenue lors de la récupération de votre position: ${e.toString()}');
      }
    }
  }

  // Méthode pour obtenir une position simulée près du terrain
  Future<LatLng> _getSimulatedPosition() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    // Obtenir la position du terrain
    final landPosition = LatLng(widget.land.latitude!, widget.land.longitude!);

    // Générer une position aléatoire à proximité du terrain (rayon de 200m)
    final random = Random();

    // Conversion degrés -> mètres (approximative)
    const double metersToDegrees = 0.00001;

    // Distance aléatoire entre 50 et 200 mètres
    final randomDistanceMeters = 50 + random.nextDouble() * 150;
    final randomAngle = random.nextDouble() * 2 * pi;

    // Calculer le déplacement en latitude et longitude
    final offsetLat = sin(randomAngle) * randomDistanceMeters * metersToDegrees;
    final offsetLng = cos(randomAngle) * randomDistanceMeters * metersToDegrees;

    // Créer la position simulée
    return LatLng(
      landPosition.latitude + offsetLat,
      landPosition.longitude + offsetLng,
    );
  }

  void _toggleMapType() {
    setState(() {
      isMapSatellite = !isMapSatellite;
    });
  }

  void _toggleLocationSimulation() {
    setState(() {
      isUsingSimulatedLocation = !isUsingSimulatedLocation;
      // Rafraîchir la position
      _getCurrentLocation(showError: false);
    });
  }

  void _toggleRoute() async {
    // Ajouter des logs pour déboguer
    getIt<Logger>().log(
      Level.info,
      'Toggle route button pressed',
      error: {
        'showRoute': showRoute,
        'route': route != null ? 'exists' : 'null',
        'loadingRoute': loadingRoute,
      },
    );

    if (showRoute) {
      setState(() {
        showRoute = false;
      });
      return;
    }

    if (route == null) {
      await _fetchRoute();
    } else {
      setState(() {
        showRoute = true;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (currentUserLocation == null) {
      await _getCurrentLocation();

      if (currentUserLocation == null) {
        // Si nous ne pouvons toujours pas obtenir la position
        _showErrorDialog('Position introuvable',
            'Impossible d\'obtenir votre position actuelle pour calculer l\'itinéraire.');
        return;
      }
    }

    setState(() {
      loadingRoute = true;
    });

    try {
      // En mode simulation, générer une route simplifiée
      if (isUsingSimulatedLocation) {
        // Simuler un délai réseau
        await Future.delayed(const Duration(seconds: 1));

        // Générer une route simulée
        final List<LatLng> points = [];
        final Random random = Random();

        // Point de départ (position utilisateur)
        final LatLng start = currentUserLocation!;
        // Point d'arrivée (terrain)
        final LatLng end =
            LatLng(widget.land.latitude!, widget.land.longitude!);

        // Ajouter le point de départ
        points.add(start);

        // Calculer la distance directe
        const Distance distance = Distance();
        final double totalDistance = distance(start, end);

        // Calculer un nombre de points intermédiaires en fonction de la distance
        final int numPoints = min(10, max(3, (totalDistance / 1000).round()));

        // Générer des points intermédiaires
        for (int i = 1; i <= numPoints; i++) {
          final double fraction = i / (numPoints + 1);
          // Interpolation linéaire + petite variation aléatoire
          final double lat = start.latitude +
              (end.latitude - start.latitude) * fraction +
              (random.nextDouble() - 0.5) * 0.005;
          final double lng = start.longitude +
              (end.longitude - start.longitude) * fraction +
              (random.nextDouble() - 0.5) * 0.005;
          points.add(LatLng(lat, lng));
        }

        // Ajouter le point d'arrivée
        points.add(end);

        // Estimer la distance totale en mètres
        double routeDistance = 0;
        for (int i = 0; i < points.length - 1; i++) {
          routeDistance += distance(points[i], points[i + 1]);
        }

        // Estimer la durée (en supposant 40 km/h de moyenne)
        final double durationSeconds = (routeDistance / 1000) / 40 * 3600;

        // Créer une route simulée
        route = RouteEntity(
          points: points,
          distance: routeDistance,
          duration: durationSeconds,
        );

        setState(() {
          showRoute = true;
          loadingRoute = false;
        });
        return;
      }

      // Sinon, utiliser l'API réelle
      final routeResult = null;

      if (routeResult != null) {
        setState(() {
          route = routeResult;
          showRoute = true;
        });
      } else {
        _showErrorDialog('Erreur d\'itinéraire',
            'Impossible de calculer l\'itinéraire. Veuillez réessayer.');
      }
    } catch (e) {
      getIt<Logger>().log(
        Level.error,
        'Error fetching route',
        error: e.toString(),
      );

      _showErrorDialog('Erreur d\'itinéraire',
          'Une erreur est survenue lors du calcul de l\'itinéraire: ${e.toString()}');
    } finally {
      setState(() {
        loadingRoute = false;
      });
    }
  }

  Future<void> _startValidation() async {
    // Vérifier d'abord que nous avons une position utilisateur
    if (currentUserLocation == null) {
      await _getCurrentLocation();

      if (currentUserLocation == null) {
        _showErrorDialog('Position requise',
            'Impossible d\'obtenir votre position actuelle. La validation nécessite votre position GPS.');
        return;
      }
    }

    // Calculer la distance entre l'utilisateur et le terrain
    const Distance distance = Distance();
    final landPosition = LatLng(widget.land.latitude!, widget.land.longitude!);
    final distanceInMeters = distance(currentUserLocation!, landPosition);

    // Si l'utilisateur est trop éloigné, afficher un avertissement
    // (sauf en mode simulation)
    if (distanceInMeters > 500 && !isUsingSimulatedLocation) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation à distance'),
          content: Text(
              'Vous êtes à ${(distanceInMeters / 1000).toStringAsFixed(1)} km du terrain. '
              'La validation devrait normalement se faire sur place. '
              'Voulez-vous continuer quand même?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('CONTINUER'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    // Mettre à jour le terrain sélectionné dans le GeometreBloc
    final geometreBloc = context.read<GeometreBloc>();
    geometreBloc.add(SelectLand(land: widget.land));

    // Naviguer vers la page de validation avec le layout complet
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<GeometreBloc>.value(
          value: geometreBloc,
          child: LandValidationFormPage(land: widget.land),
        ),
      ),
    )
        .then((_) {
      // S'assurer que le terrain sélectionné est effacé lorsque l'utilisateur revient
      geometreBloc.add(ClearSelectedLand());
    });
  }

  // Méthode utilitaire pour afficher une boîte de dialogue d'erreur
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isSmallScreen) {
    final mapZoom = isSmallScreen ? 14.0 : 15.0;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.land.latitude!, widget.land.longitude!),
        initialZoom: mapZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Couche de tuiles (fond de carte)
        TileLayer(
          urlTemplate: isMapSatellite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.flareline.app',
          tileProvider: CancellableNetworkTileProvider(),
        ),

        // Marqueur pour le terrain
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(widget.land.latitude!, widget.land.longitude!),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle extérieur
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Icône
                  const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Marqueur pour la position de l'utilisateur
        if (currentUserLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: currentUserLocation!,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle extérieur
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Icône
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // Affichage de l'itinéraire
        if (showRoute && route != null && route!.points.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route!.points,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFloatingButtons(
      bool isSmallScreen, double padding, double buttonSize, double iconSize) {
    return Positioned(
      bottom: padding,
      right: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton pour changer le type de carte
          FloatingActionButton(
            heroTag: 'mapType',
            onPressed: _toggleMapType,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            mini: isSmallScreen,
            child: Icon(
              isMapSatellite ? Icons.map : Icons.satellite,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 8),

          // Bouton pour recentrer sur la position de l'utilisateur
          FloatingActionButton(
            heroTag: 'location',
            onPressed: () => _getCurrentLocation(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            mini: isSmallScreen,
            child: isTrackingLocation
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : Icon(
                    Icons.my_location,
                    size: iconSize,
                  ),
          ),

          // Bouton pour activer/désactiver la simulation de localisation
          // (uniquement sur desktop ou web)
          if (PlatformUtils.isDesktop || PlatformUtils.isWeb)
            const SizedBox(height: 8),

          if (PlatformUtils.isDesktop || PlatformUtils.isWeb)
            FloatingActionButton(
              heroTag: 'simulate',
              onPressed: _toggleLocationSimulation,
              backgroundColor: Colors.white,
              foregroundColor:
                  isUsingSimulatedLocation ? Colors.orange : Colors.grey,
              mini: isSmallScreen,
              child: Icon(
                Icons.location_searching,
                size: iconSize,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(bool isSmallScreen, double padding, double fontSize) {
    return Positioned(
      top: padding,
      left: padding,
      right: padding,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terrain: ${widget.land.title}',
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isSmallScreen) const SizedBox(height: 4),
              Text(
                'ID: ${widget.land.id}',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[700],
                ),
              ),
              if (showRoute && route != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.directions, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Distance: ${_formatDistance(route!.distance)}',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Durée: ${_formatDuration(route!.duration)}',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toInt()}s';
    } else if (seconds < 3600) {
      return '${(seconds / 60).toInt()}min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours${hours == 1 ? 'h' : 'h'} ${minutes > 0 ? '$minutes min' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Ajuster les tailles en fonction de l'écran
    final buttonSize = isSmallScreen ? 40.0 : 56.0;
    final iconSize = isSmallScreen ? 18.0 : 24.0;
    final padding = isSmallScreen ? 8.0 : 16.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;

    return OrientationBuilder(
      builder: (context, orientation) {
        // Définir le layout en fonction de l'orientation
        final isPortrait = orientation == Orientation.portrait;

        // Calculer les proportions de la carte et des contrôles
        final mapFlex = isPortrait ? 75 : 85;
        final controlsFlex = isPortrait ? 25 : 15;

        return Column(
          children: [
            // Carte
            Expanded(
              flex: mapFlex,
              child: Stack(
                children: [
                  // Carte principale
                  _buildMap(isSmallScreen),

                  // Bannière de simulation
                  if (isUsingSimulatedLocation)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.yellow.withOpacity(0.8),
                        padding: EdgeInsets.symmetric(vertical: padding / 2),
                        child: Center(
                          child: Text(
                            'MODE SIMULATION',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Boutons flottants
                  _buildFloatingButtons(
                      isSmallScreen, padding, buttonSize, iconSize),

                  // Panneau d'informations
                  if (currentUserLocation != null)
                    _buildInfoPanel(isSmallScreen, padding, fontSize),
                ],
              ),
            ),

            // Boutons de contrôle
            Expanded(
              flex: controlsFlex,
              child: MapControlButtons(
                onStartValidation: _startValidation,
                onToggleRoute: _toggleRoute,
                showRoute: showRoute,
                loadingRoute: loadingRoute,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        );
      },
    );
  }
}
