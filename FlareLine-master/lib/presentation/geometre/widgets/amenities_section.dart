// File: lib/presentation/geometre/widgets/amenities_section.dart
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/core/extensions/string_extensions.dart';

/// Widget pour la section d'aménités à valider
class AmenitiesSection extends StatefulWidget {
  final Land land;
  final Map<String, bool> validatedAmenities;
  final Function(Map<String, bool>) onAmenitiesChanged;

  const AmenitiesSection({
    super.key,
    required this.land,
    required this.validatedAmenities,
    required this.onAmenitiesChanged,
  });

  @override
  State<AmenitiesSection> createState() => _AmenitiesSectionState();
}

class _AmenitiesSectionState extends State<AmenitiesSection> {
  late Map<String, bool> _localAmenities;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialiser sans notifier
    _initializeAmenities(notify: false);

    // Utiliser un Future.microtask pour notifier après le build initial
    Future.microtask(() {
      if (mounted && !_isInitialized) {
        _initializeAmenities(notify: true);
        _isInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(AmenitiesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.land != widget.land) {
      _initializeAmenities(notify: true);
    }
  }

  void _initializeAmenities({bool notify = true}) {
    // Si les aménités validées sont vides, initialiser avec celles du terrain
    if (widget.validatedAmenities.isEmpty && widget.land.amenities != null) {
      _localAmenities = Map.from(widget.land.amenities!);
      // Notifier le parent seulement si demandé
      if (notify) {
        widget.onAmenitiesChanged(_localAmenities);
      }
    } else {
      _localAmenities = Map.from(widget.validatedAmenities);
    }
  }

  // Le reste du code reste inchangé...

  @override
  Widget build(BuildContext context) {
    // Si le terrain n'a pas d'aménités définies
    if (widget.land.amenities == null || widget.land.amenities!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Aucun équipement ou caractéristique à valider pour ce terrain.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Équipements et caractéristiques',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Vérifiez la présence de ces éléments sur le terrain :',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          ),
        ),
        // Utiliser Wrap au lieu de GridView pour un affichage plus compact
        Wrap(
          spacing: 8.0, // espacement horizontal entre les éléments
          runSpacing: 8.0, // espacement vertical entre les lignes
          children: widget.land.amenities!.entries.map((entry) {
            return _buildAmenityChip(
              amenityName: entry.key,
              isDeclared: entry.value,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_hasAmenityDiscrepancies())
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Différences détectées',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Des différences ont été constatées entre les équipements déclarés et ceux observés. '
                  'Veuillez détailler ces observations dans les commentaires.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Construit une puce compacte pour une aménité avec icône
  Widget _buildAmenityChip({
    required String amenityName,
    required bool isDeclared,
  }) {
    // Obtenir l'icône et le nom d'affichage pour cette aménité
    final amenityInfo = _getAmenityInfo(amenityName);

    // Déterminer si l'élément a été modifié par rapport à la déclaration
    final isChanged = _localAmenities[amenityName] != isDeclared;
    final isValidated = _localAmenities[amenityName] ?? false;

    return Container(
      width: 160, // Largeur fixe pour uniformité
      height: 40, // Hauteur fixe pour une apparence compacte
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isChanged
              ? Colors.orange
              : (isValidated
                  ? GlobalColors.primary.withOpacity(0.5)
                  : Colors.grey.shade300),
          width: isChanged ? 1.5 : 1,
        ),
        color: isValidated
            ? (isChanged
                ? Colors.orange.withOpacity(0.1)
                : GlobalColors.primary.withOpacity(0.05))
            : Colors.grey.shade50,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() {
              _localAmenities[amenityName] =
                  !(_localAmenities[amenityName] ?? false);
              widget.onAmenitiesChanged(_localAmenities);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Case à cocher
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _localAmenities[amenityName],
                    onChanged: (value) {
                      setState(() {
                        _localAmenities[amenityName] = value ?? false;
                        widget.onAmenitiesChanged(_localAmenities);
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                // Icône
                Icon(
                  amenityInfo.icon,
                  size: 18,
                  color:
                      isValidated ? GlobalColors.primary : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                // Texte
                Expanded(
                  child: Text(
                    amenityInfo.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isChanged ? FontWeight.bold : FontWeight.normal,
                      color:
                          isValidated ? Colors.black87 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Statut déclaré/non-déclaré
                Tooltip(
                  message: isDeclared
                      ? 'Déclaré dans le dossier'
                      : 'Non déclaré dans le dossier',
                  child: Icon(
                    isDeclared
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    size: 14,
                    color: isDeclared
                        ? Colors.green.shade400
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Vérifie s'il y a des différences entre les aménités déclarées et validées
  bool _hasAmenityDiscrepancies() {
    if (widget.land.amenities == null || _localAmenities.isEmpty) return false;

    for (final entry in widget.land.amenities!.entries) {
      if (_localAmenities[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }
}

/// Classe pour stocker les informations d'une aménité
class AmenityInfo {
  final String displayName;
  final IconData icon;

  const AmenityInfo(this.displayName, this.icon);
}

/// Retourne les informations (nom d'affichage et icône) pour une aménité
AmenityInfo _getAmenityInfo(String name) {
  // Mapping des noms techniques vers des noms affichables et des icônes
  final amenityInfoMap = {
    'electricity': const AmenityInfo('Électricité', Icons.power),
    'gas': const AmenityInfo('Gaz', Icons.local_fire_department),
    'water': const AmenityInfo('Eau courante', Icons.water_drop),
    'sewer': const AmenityInfo('Tout-à-l\'égout', Icons.plumbing),
    'internet': const AmenityInfo('Internet', Icons.wifi),
    'roadAccess': const AmenityInfo('Accès routier', Icons.add_road),
    'pavedRoad': const AmenityInfo('Route goudronnée', Icons.aod),
    'boundaryMarkers': const AmenityInfo('Bornes', Icons.fence),
    'fenced': const AmenityInfo('Clôturé', Icons.security),
    'trees': const AmenityInfo('Arbres', Icons.park),
    'flatTerrain': const AmenityInfo('Terrain plat', Icons.horizontal_rule),
    'parking': const AmenityInfo('Parking', Icons.local_parking),
    'lighting': const AmenityInfo('Éclairage', Icons.light),
    'irrigation': const AmenityInfo('Irrigation', Icons.water),
    'shelter': const AmenityInfo('Abri', Icons.home),
    'electricityMeter':
        const AmenityInfo('Compteur élec.', Icons.electric_meter),
    'waterMeter': const AmenityInfo('Compteur eau', Icons.water_damage),
    'buildingPermit': const AmenityInfo('Permis construire', Icons.description),
    'accessibleDisabled':
        const AmenityInfo('Accès handicapés', Icons.accessible),
    'garden': const AmenityInfo('Jardin', Icons.yard),
  };

  // Si le nom n'est pas dans le mapping, créer un AmenityInfo par défaut
  if (amenityInfoMap.containsKey(name)) {
    return amenityInfoMap[name]!;
  } else {
    // Formater le texte pour les noms non répertoriés
    final formattedName = name
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}')
        .toLowerCase()
        .capitalize();
    return AmenityInfo(formattedName, Icons.check_box_outline_blank);
  }
}
