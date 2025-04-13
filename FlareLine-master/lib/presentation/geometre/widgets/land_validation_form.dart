import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
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

  // État pour les aménités
  Map<String, bool> _validatedAmenities = {};

  // Éviter les initialisations qui provoquent setState pendant le build
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
              onAmenitiesChanged: (newAmenities) {
                setState(() {
                    _updateAmenities(newAmenities);
                });
              },
            ),

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
    if (_formKey.currentState!.validate() && _isValid) {
      context.read<GeometreBloc>().add(ValidateLand(
            landId: land.id,
            isValid: _isValid,
            comments: _commentsController.text,
          ));
    } else if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Veuillez confirmer les informations en cochant la case'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
