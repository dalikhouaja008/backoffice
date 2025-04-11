import 'dart:developer' as developer;

import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/core/utils/platform_utils.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline/presentation/pages/layout.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show pi, cos;

/// Page principale héritant du layout avec sidebar et navbar
class LandValidationFormPage extends LayoutWidget {
  final Land? land;

  const LandValidationFormPage({super.key, this.land});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation de terrain';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: LandValidationForm(),
    );
  }
}

/// Widget de formulaire de validation de terrain
class LandValidationForm extends StatefulWidget {
  const LandValidationForm({super.key});

  @override
  State<LandValidationForm> createState() => _LandValidationFormState();
}

class _LandValidationFormState extends State<LandValidationForm> {
  // Contrôleurs et états du formulaire
  final _formKey = GlobalKey<FormState>();
  final _measuredSurfaceController = TextEditingController();
  final _commentsController = TextEditingController();
  bool _isValid = false;
  
  // Variables pour la mesure de superficie
  List<LatLng> _measurementPoints = [];
  MapController _mapController = MapController();
  
  @override
  void dispose() {
    _measuredSurfaceController.dispose();
    _commentsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // SECTION: Méthodes de calcul de superficie
  //------------------------------------------
  
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

  // SECTION: Gestion de l'interface de mesure
  //------------------------------------------
  
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
                    // Bouton Refresh - NOUVEAU
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
                            _measurementPoints = dialogPoints;  // Mettre à jour les points dans l'état principal
                            _measuredSurfaceController.text = area.toStringAsFixed(2);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
                const Divider(),
                // Instructions - Ajout d'information sur le bouton refresh
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
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(land.latitude!, land.longitude!),
                      initialZoom: 18,
                      onTap: (tapPosition, point) {
                        // Mise à jour de l'état local du dialogue
                        setDialogState(() {
                          dialogPoints.add(point);
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
                          dialogPoints.length,
                          (i) => Marker(
                            width: 30.0,
                            height: 30.0,
                            point: dialogPoints[i],
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
                      if (dialogPoints.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: dialogPoints,
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
                            points: dialogPoints.isEmpty ? [] : [
                              ...dialogPoints,
                              if (dialogPoints.length > 2) dialogPoints.first
                            ],
                            color: Colors.orange,
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      // Bouton Refresh alternatif dans le pied de page
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
  
  /// Construit la boîte de dialogue pour la mesure
  Widget _buildMeasurementDialog(BuildContext context, Land land) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            _buildMeasurementDialogHeader(context, land),
            const Divider(),
            _buildMeasurementInstructions(),
            Expanded(
              child: _buildMeasurementMap(land),
            ),
            _buildMeasurementFooter(),
          ],
        ),
      ),
    );
  }
  
  /// Construit l'en-tête de la boîte de dialogue de mesure
  Widget _buildMeasurementDialogHeader(BuildContext context, Land land) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Text(
          'Mesure de superficie - ${land.title}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        if (_measurementPoints.length >= 3)
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Terminer la mesure'),
            onPressed: () {
              // Calculer la superficie et l'appliquer au formulaire
              double area = _calculateAreaFromGpsPoints(_measurementPoints);
              setState(() {
                _measuredSurfaceController.text = area.toStringAsFixed(2);
              });
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
  
  /// Construit les instructions pour l'utilisateur
  Widget _buildMeasurementInstructions() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'Tapez sur la carte pour placer des points autour du terrain. '
        'Placez au moins 3 points pour calculer la superficie.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
  
  /// Construit la carte pour la mesure
  Widget _buildMeasurementMap(Land land) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(land.latitude!, land.longitude!),
        initialZoom: 18,  // Zoom élevé pour une meilleure précision
        onTap: (tapPosition, point) {
          setState(() {
            _measurementPoints.add(point);
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
        // Marqueurs pour les points de mesure
        MarkerLayer(
          markers: [
            for (int i = 0; i < _measurementPoints.length; i++)
              Marker(
                width: 30.0,
                height: 30.0,
                point: _measurementPoints[i],
                child: _buildPointMarker(i),
              ),
          ],
        ),
        // Polygone coloré si assez de points
        if (_measurementPoints.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _measurementPoints,
                color: Colors.orange.withOpacity(0.2),
                borderColor: Colors.orange,
                borderStrokeWidth: 3,
              ),
            ],
          ),
        // Lignes reliant les points
        PolylineLayer(
          polylines: [
            Polyline(
              points: _measurementPoints.isEmpty ? [] : [
                ..._measurementPoints, 
                // Relier au premier point pour fermer le polygone
                if (_measurementPoints.length > 2) _measurementPoints.first
              ],
              color: Colors.orange,
              strokeWidth: 3.0,
            ),
          ],
        ),
      ],
    );
  }
  
  /// Construit le marqueur pour un point de mesure
  Widget _buildPointMarker(int index) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.withOpacity(0.7),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  /// Construit le pied de page de la boîte de dialogue
  Widget _buildMeasurementFooter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Points placés: ${_measurementPoints.length}'),
          if (_measurementPoints.length >= 3)
            Text(
              'Surface estimée: ${_calculateAreaFromGpsPoints(_measurementPoints).toStringAsFixed(2)} m²',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  // SECTION: Comparaison des superficies
  //------------------------------------
  
  /// Construit le widget de comparaison des superficies
  Widget _buildAreaComparisonCard(Land land) {
    final double declaredArea = land.surface;
    final double measuredArea = double.parse(_measuredSurfaceController.text);
    final double difference = measuredArea - declaredArea;
    final double percentDiff = (difference / declaredArea) * 100;
    final bool isSignificantDiff = percentDiff.abs() > 5; // Seuil de 5%
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSignificantDiff ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSignificantDiff ? Colors.amber : Colors.green,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison des superficies',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Différence: ${difference.toStringAsFixed(2)} m² (${percentDiff.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: isSignificantDiff ? Colors.deepOrange : Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSignificantDiff)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Attention: Écart significatif détecté! Veuillez vérifier la mesure ou noter cette différence dans les commentaires.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // SECTION: Construction du formulaire principal
  //---------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeometreBloc, GeometreState>(
      builder: (context, state) {
        if (state is GeometreLoaded && state.selectedLand != null) {
          return _buildForm(context, state.selectedLand!);
        }
        return const Center(
          child: Text('Sélectionnez un terrain pour le valider'),
        );
      },
    );
  }

  /// Construit le formulaire principal
  Widget _buildForm(BuildContext context, Land land) {
    return CommonCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section surface déclarée
            _buildDeclaredAreaField(land),
            const SizedBox(height: 16),
            
            // Section surface mesurée avec bouton de mesure
            _buildMeasuredAreaSection(),
            
            // Comparaison des superficies (conditionnelle)
            if (_measuredSurfaceController.text.isNotEmpty && 
                double.tryParse(_measuredSurfaceController.text) != null)
              _buildAreaComparisonCard(land),
            
            const SizedBox(height: 16),
            
            // Section commentaires
            _buildCommentsField(),
            
            const SizedBox(height: 16),
            
            // Checkbox de validation
            _buildValidationCheckbox(),
            
            const SizedBox(height: 24),
            
            // Bouton de soumission
            _buildSubmitButton(land),
          ],
        ),
      ),
    );
  }
  
  /// Champ pour afficher la surface déclarée
  Widget _buildDeclaredAreaField(Land land) {
    return OutBorderTextFormField(
      labelText: "Surface déclarée",
      hintText: "${land.surface} m²",
      enabled: false,
    );
  }
  
  /// Section pour la surface mesurée avec bouton
  Widget _buildMeasuredAreaSection() {
    return Row(
      children: [
        Expanded(
          child: OutBorderTextFormField(
            controller: _measuredSurfaceController,
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
          onPressed: () {
            final state = context.read<GeometreBloc>().state;
            if (state is GeometreLoaded && state.selectedLand != null) {
              _openAreaMeasurement(state.selectedLand!);
            }
          },
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
  
  /// Champ pour les commentaires
  Widget _buildCommentsField() {
    return OutBorderTextFormField(
      controller: _commentsController,
      labelText: "Commentaires",
      hintText: "Ajouter vos observations",
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Les commentaires sont requis';
        }
        if (value.length < 10) {
          return 'Les commentaires doivent faire au moins 10 caractères';
        }
        return null;
      },
    );
  }
  
  /// Checkbox de validation
  Widget _buildValidationCheckbox() {
    return ValidationCheckbox(
      value: _isValid,
      label: "Je confirme que les informations saisies sont correctes",
      checkColor: GlobalColors.primary,
      onChanged: (value) {
        setState(() {
          _isValid = value ?? false;
        });
      },
    );
  }
  
  /// Bouton de soumission du formulaire
  Widget _buildSubmitButton(Land land) {
    return BlocBuilder<GeometreBloc, GeometreState>(
      builder: (context, state) {
        final bool isValidating = state is ValidationInProgress;

        return ButtonForm(
          btnText: isValidating
              ? "Validation en cours..."
              : "Valider le terrain",
          type: ButtonType.primary.type,
          isLoading: isValidating,
          onPressed: isValidating
              ? null
              : () => _submitForm(context, land),
        );
      },
    );
  }
  
  /// Gestion de la soumission du formulaire
  void _submitForm(BuildContext context, Land land) {
    if (_formKey.currentState!.validate() && _isValid) {
      context.read<GeometreBloc>().add(ValidateLand(
            landId: land.id,
            isValid: _isValid,
            comments: _commentsController.text,
          ));
    } else if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez confirmer les informations en cochant la case'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}