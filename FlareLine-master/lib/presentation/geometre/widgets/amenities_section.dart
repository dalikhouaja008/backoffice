import 'package:flareline/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

/// Widget pour afficher et valider les aménités d'un terrain
class AmenitiesSection extends StatefulWidget {
  final Land land;
  final Map<String, bool> validatedAmenities;
  final Function(Map<String, bool>) onAmenitiesChanged;

  const AmenitiesSection({
    Key? key,
    required this.land,
    required this.validatedAmenities,
    required this.onAmenitiesChanged,
  }) : super(key: key);

  @override
  State<AmenitiesSection> createState() => _AmenitiesSectionState();
}

class _AmenitiesSectionState extends State<AmenitiesSection> {
  late Map<String, bool> _validatedAmenities;

  @override
  void initState() {
    super.initState();
    _validatedAmenities = Map<String, bool>.from(widget.validatedAmenities);
    
    // Utiliser un post-frame callback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAmenities();
      }
    });
  }

  @override
  void didUpdateWidget(AmenitiesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.land.id != widget.land.id) {
      _validatedAmenities = Map<String, bool>.from(widget.validatedAmenities);
      
      // Utiliser un post-frame callback pour éviter setState pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeAmenities();
        }
      });
    }
  }

  void _initializeAmenities() {
    // Debug - afficher le contenu des aménités
    print("DEBUG - Aménités du terrain [${widget.land.id}]: ${widget.land.amenities}");
    
    if (widget.land.amenities == null || widget.land.amenities!.isEmpty) {
      print("DEBUG - Aménités nulles ou vides");
      _notifyChanges();
      return;
    }
    
    // Créer une nouvelle map pour éviter les problèmes de référence
    final newValidatedAmenities = <String, bool>{};
    
    // Traiter toutes les clés des aménités
    widget.land.amenities!.forEach((key, value) {
      // Ne prendre que les aménités déclarées comme présentes (value == true)
      if (value == true) {
        // Initialiser avec la valeur existante ou false par défaut
        newValidatedAmenities[key] = widget.validatedAmenities[key] ?? false;
        print("DEBUG - Ajout de l'aménité: $key = $value, validée: ${newValidatedAmenities[key]}");
      }
    });
    
    setState(() {
      _validatedAmenities = newValidatedAmenities;
    });
    
    // Notifier le parent après setState
    _notifyChanges();
  }
  
  void _notifyChanges() {
    // Utiliser un post-frame callback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAmenitiesChanged(_validatedAmenities);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si pas d'aménités ou aménités vides
    if (widget.land.amenities == null || widget.land.amenities!.isEmpty) {
      return _buildNoAmenitiesMessage();
    }
    
    // Filtrer les aménités qui sont marquées comme présentes (true)
    final presentAmenities = widget.land.amenities!.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
    
    // Si aucune aménité n'est présente
    if (presentAmenities.isEmpty) {
      return _buildNoAmenitiesMessage();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Équipements et Aménités',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Carte avec les aménités
        CommonCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                const Text(
                  'Veuillez confirmer la présence des équipements suivants :',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                
                // Liste des aménités
                ...presentAmenities.map(_buildAmenityCheckbox).toList(),
                
                // Message si toutes les aménités sont validées
                if (_allAmenitiesValidated() && presentAmenities.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Tous les équipements ont été vérifiés',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _allAmenitiesValidated() {
    return _validatedAmenities.isNotEmpty && 
           _validatedAmenities.values.every((isValidated) => isValidated);
  }

  Widget _buildAmenityCheckbox(String amenityKey) {
    bool isChecked = _validatedAmenities[amenityKey] ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                _validatedAmenities[amenityKey] = value ?? false;
              });
              
              // Notifier le parent après setState
              _notifyChanges();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatAmenityName(amenityKey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAmenitiesMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Équipements et Aménités',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CommonCard(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Aucun équipement ou aménité déclaré pour ce terrain.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmenityName(String key) {
    // Conversion des clés techniques en noms lisibles
    switch (key) {
      case 'water': return 'Accès à l\'eau';
      case 'electricity': return 'Électricité';
      case 'gas': return 'Gaz';
      case 'sewer': return 'Tout-à-l\'égout';
      case 'internet': return 'Connexion Internet';
      case 'roadAccess': return 'Accès routier';
      case 'pavedRoad': return 'Route pavée';
      case 'boundaryMarkers': return 'Bornes de délimitation';
      case 'fenced': return 'Terrain clôturé';
      case 'trees': return 'Arbres';
      case 'flatTerrain': return 'Terrain plat';
      case 'buildingPermit': return 'Permis de construire';
      default:
        // Formater les autres clés (convertir camelCase et underscores en texte lisible)
        return key
            .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)!.toLowerCase()}')
            .replaceAll('_', ' ')
            .trim()
            .capitalize();
    }
  }
}

