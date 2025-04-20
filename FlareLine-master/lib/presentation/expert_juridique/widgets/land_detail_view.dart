import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/enums/validation_enums.dart';
import 'package:flareline/presentation/geometre/widgets/land_images_gallery.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';

class LandDetailView extends StatelessWidget {
  final Land land;
  final VoidCallback onStartValidation;

  const LandDetailView({
    super.key,
    required this.land,
    required this.onStartValidation,
  });
  
@override
  Widget build(BuildContext context) {
    // Utiliser un SingleChildScrollView pour rendre tout le contenu scrollable
    return Column(
      children: [
        // En-tête fixe (reste toujours visible)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.gavel,
                color: GlobalColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du Terrain',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: GlobalColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      land.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Contenu défilable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galerie d'images
                LandImagesGallery(land: land),
                const SizedBox(height: 24),
        
                // Résumé juridique
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: GlobalColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlobalColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, size: 20, color: GlobalColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Résumé juridique',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLegalSummaryItem(
                        'Localisation',
                        land.location,
                        Icons.location_on_outlined,
                      ),
                      const Divider(height: 16),
                      _buildLegalSummaryItem(
                        'Type de propriété',
                        land.landtype.toUpperCase(),
                        Icons.business_outlined,
                      ),
                      const Divider(height: 16),
                      _buildLegalSummaryItem(
                        'Statut actuel',
                        _getStatusText(land.status),
                        Icons.info_outline,
                        _getStatusColor(land.status),
                      ),
                      if (land.documentUrls.isNotEmpty)
                        Column(
                          children: [
                            const Divider(height: 16),
                            _buildLegalSummaryItem(
                              'Documents disponibles',
                              '${land.documentUrls.length} document(s)',
                              Icons.folder_outlined,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
        
                // Infos du terrain
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations détaillées',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Surface', '${land.surface} m²'),
                    _buildInfoRow('ID Blockchain', land.blockchainLandId),
                    _buildInfoRow('Propriétaire', land.ownerAddress),
  
                  ],
                ),
                
                // Espace supplémentaire en bas pour assurer que tout est visible
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        
        Container(
          width: double.infinity, // Assurer que le container prend toute la largeur
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ElevatedButton.icon( 
            onPressed: () {
              print("Bouton cliqué dans LandDetailView"); 
              onStartValidation(); 
            },
            icon: const Icon(Icons.gavel),
            label: const Text("Commencer la validation juridique"),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Méthode pour construire un élément du résumé juridique
  Widget _buildLegalSummaryItem(
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? GlobalColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir le texte de statut pour l'affichage
  String _getStatusText(LandValidationStatus status) {
    switch (status) {
      case LandValidationStatus.PENDING_VALIDATION:
        return 'En attente de validation';
      case LandValidationStatus.PARTIALLY_VALIDATED:
        return 'Partiellement validé';
      case LandValidationStatus.VALIDATED:
        return 'Entièrement validé';
      case LandValidationStatus.REJECTED:
        return 'Validation rejetée';
      case LandValidationStatus.TOKENIZED:
        return 'Tokenisé';
    }
  }

  // Obtenir la couleur du statut
  Color _getStatusColor(LandValidationStatus status) {
    switch (status) {
      case LandValidationStatus.PENDING_VALIDATION:
        return Colors.orange;
      case LandValidationStatus.PARTIALLY_VALIDATED:
        return Colors.blue;
      case LandValidationStatus.VALIDATED:
        return Colors.green;
      case LandValidationStatus.REJECTED:
        return Colors.red;
      case LandValidationStatus.TOKENIZED:
        return GlobalColors.primary;
    }
  }
}