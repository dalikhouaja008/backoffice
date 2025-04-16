import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/geometre/widgets/land_images_gallery.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';

import 'area_measurement_section.dart';
import 'amenities_section.dart';

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

  // Variable pour la vérification des images
  bool _imagesAreReal = false;

  // État pour les aménités
  Map<String, bool> _validatedAmenities = {};

  @override
  void dispose() {
    _measuredSurfaceController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

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

  void _updateAmenities(Map<String, bool> newAmenities) {
    // Utiliser un post-frame callback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _validatedAmenities = newAmenities;
        });
      }
    });
  }

  /// Construit le formulaire principal
  Widget _buildForm(BuildContext context, Land land) {
    return CommonCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section galerie d'images
            LandImagesGallery(land: land),
            const SizedBox(height: 16),

            // Section surface déclarée
            _buildDeclaredAreaField(land),
            const SizedBox(height: 16),

            // Section surface mesurée avec bouton de mesure
            AreaMeasurementSection(
              controller: _measuredSurfaceController,
              land: land,
            ),

            // Comparaison des superficies (conditionnelle)
            if (_measuredSurfaceController.text.isNotEmpty &&
                double.tryParse(_measuredSurfaceController.text) != null)
              _buildAreaComparisonCard(land),

            const SizedBox(height: 16),

            // Section des aménités
            AmenitiesSection(
              land: land,
              validatedAmenities: _validatedAmenities,
              onAmenitiesChanged: _updateAmenities,
            ),

            const SizedBox(height: 16),

            // Section pour valider les images
            _buildImagesValidationSection(land),

            const SizedBox(height: 16),

            // Section commentaires modifiée
            _buildCommentsField(land),

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

  /// Construit la section de validation des images
  Widget _buildImagesValidationSection(Land land) {
    // Vérifier si le terrain a des images
    final hasImages = land.imageUrls.isNotEmpty || land.imageCIDs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Validation des images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Message si aucune image n'est disponible
        if (!hasImages)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Aucune image disponible pour ce terrain.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),

        // Checkbox pour confirmer que les images sont réelles
        if (hasImages)
          ValidationCheckbox(
            value: _imagesAreReal,
            label:
                "Je confirme que les images sont réelles et correspondent au terrain visité",
            checkColor: GlobalColors.primary,
            onChanged: (value) {
              setState(() {
                _imagesAreReal = value ?? false;
              });
            },
          ),

        // Avertissement si les images ne sont pas validées
        if (hasImages && !_imagesAreReal)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 32.0),
            child: Text(
              'Vous devez confirmer la validité des images pour finaliser la validation',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 8),
      ],
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
          color: isSignificantDiff
              ? Colors.amber.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
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
                color: isSignificantDiff
                    ? Colors.deepOrange
                    : Colors.green.shade700,
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

  /// Champ pour les commentaires
  Widget _buildCommentsField(Land land) {
    // Construire un texte de suggestion qui mentionne les images
    final hasImages = land.imageUrls.isNotEmpty || land.imageCIDs.isNotEmpty;
    final suggestionText = hasImages
        ? "Ajouter vos observations sur le terrain et les images (qualité, représentativité, éventuelles divergences...)"
        : "Ajouter vos observations sur le terrain";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section avec bouton de génération
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Commentaires',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Bouton pour générer un commentaire automatique
            ElevatedButton.icon(
              onPressed: () => _generateComment(land),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Générer un commentaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),

        // Champ de texte pour les commentaires
        OutBorderTextFormField(
          controller: _commentsController,
          labelText: "Commentaires détaillés",
          hintText: suggestionText,
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
        ),

        // Suggestions pour les commentaires
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            'Suggestions: état général du terrain, conformité de la surface, ${hasImages ? 'qualité des images, ' : ''}accès, limites, etc.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Génère un commentaire basé sur les informations du formulaire
  void _generateComment(Land land) {
    // Vérifier si une surface mesurée a été saisie
    final hasMeasuredSurface = _measuredSurfaceController.text.isNotEmpty &&
        double.tryParse(_measuredSurfaceController.text) != null;

    // Extraire les informations nécessaires
    final double declaredArea = land.surface;
    final double? measuredArea = hasMeasuredSurface
        ? double.tryParse(_measuredSurfaceController.text)
        : null;

    // Calculer la différence de surface si disponible
    String surfaceComparison = '';
    if (measuredArea != null) {
      final double difference = measuredArea - declaredArea;
      final double percentDiff = (difference / declaredArea) * 100;

      if (percentDiff.abs() <= 2) {
        surfaceComparison =
            'La surface mesurée est conforme à la surface déclarée (écart de ${percentDiff.toStringAsFixed(2)}%).';
      } else if (percentDiff.abs() <= 5) {
        surfaceComparison =
            'La surface mesurée présente un léger écart de ${percentDiff.toStringAsFixed(2)}% par rapport à la surface déclarée.';
      } else {
        surfaceComparison =
            'La surface mesurée présente un écart significatif de ${percentDiff.toStringAsFixed(2)}% par rapport à la surface déclarée.';
      }
    }

    // Vérifier les aménités validées (si la section existe)
    String amenitiesComment = '';
    if (_validatedAmenities.isNotEmpty) {
      final validatedCount =
          _validatedAmenities.values.where((isValid) => isValid).length;
      final totalCount = _validatedAmenities.length;

      if (validatedCount == totalCount) {
        amenitiesComment =
            'Tous les équipements déclarés ont été vérifiés et confirmés.';
      } else if (validatedCount == 0) {
        amenitiesComment =
            'Aucun des équipements déclarés n\'a pu être confirmé.';
      } else {
        amenitiesComment =
            '$validatedCount sur $totalCount équipements déclarés ont été confirmés.';
      }
    }

    // Commentaire sur les images
    final hasImages = land.imageUrls.isNotEmpty || land.imageCIDs.isNotEmpty;
    String imagesComment = '';
    if (hasImages) {
      if (_imagesAreReal) {
        imagesComment =
            'Les images fournies sont conformes à la réalité du terrain.';
      } else {
        imagesComment = 'Les images fournies n\'ont pas encore été vérifiées.';
      }
    }

    // Construction du commentaire complet
    final StringBuilder = StringBuffer();

    StringBuilder.writeln(
        'Rapport de validation pour le terrain "${land.title}" situé à ${land.location}:');
    StringBuilder.writeln();

    // Information sur la surface
    if (hasMeasuredSurface) {
      StringBuilder.writeln('Surface déclarée: ${declaredArea} m²');
      StringBuilder.writeln(
          'Surface mesurée: ${measuredArea!.toStringAsFixed(2)} m²');
      StringBuilder.writeln(surfaceComparison);
      StringBuilder.writeln();
    }

    // Commentaire sur les aménités
    if (amenitiesComment.isNotEmpty) {
      StringBuilder.writeln(amenitiesComment);
      StringBuilder.writeln();
    }

    // Commentaire sur les images
    if (hasImages) {
      StringBuilder.writeln(imagesComment);
      StringBuilder.writeln();
    }

    // Conclusion générale
    StringBuilder.writeln(
        'Conclusion: Le terrain a été visité et inspecté conformément aux procédures de validation.');

    // Mettre à jour le contrôleur de texte
    setState(() {
      _commentsController.text = StringBuilder.toString();
    });

    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commentaire généré avec succès !'),
        backgroundColor: Colors.green,
      ),
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
          btnText:
              isValidating ? "Validation en cours..." : "Valider le terrain",
          type: ButtonType.primary.type,
          isLoading: isValidating,
          onPressed: isValidating ? null : () => _submitForm(context, land),
        );
      },
    );
  }

  /// Gestion de la soumission du formulaire
  void _submitForm(BuildContext context, Land land) {
    if (_formKey.currentState!.validate()) {
      // Vérifier si la case de validation générale est cochée
      if (!_isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Veuillez confirmer les informations en cochant la case'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Vérifier si des images sont disponibles et si la case de validation des images est cochée
      final hasImages = land.imageUrls.isNotEmpty || land.imageCIDs.isNotEmpty;
      if (hasImages && !_imagesAreReal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez confirmer que les images sont réelles'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Inclure l'information sur la validation des images dans les commentaires
      final commentsWithImageValidation = hasImages
          ? '${_commentsController.text}\n\nValidation des images : ${_imagesAreReal ? "Images confirmées comme réelles" : "Non validé"}'
          : _commentsController.text;

      // Soumettre le formulaire
      context.read<GeometreBloc>().add(ValidateLand(
            landId: land.id,
            isValid: _isValid,
            comments: commentsWithImageValidation,
          ));
    }
  }
}
