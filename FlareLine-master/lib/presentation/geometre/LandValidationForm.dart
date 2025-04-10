import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LandValidationForm extends StatefulWidget {
  const LandValidationForm({super.key});

  @override
  State<LandValidationForm> createState() => _LandValidationFormState();
}

class _LandValidationFormState extends State<LandValidationForm> {
  
  final _formKey = GlobalKey<FormState>();
  final _measuredSurfaceController = TextEditingController();
  final _commentsController = TextEditingController();
  bool _isValid = false;

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

  Widget _buildForm(BuildContext context, Land land) {
    return CommonCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutBorderTextFormField(
              labelText: "Surface déclarée",
              hintText: "${land.surface} m²",
              enabled: false,
            ),
            const SizedBox(height: 16),
            OutBorderTextFormField(
              controller: _measuredSurfaceController,
              labelText: "Surface mesurée",
              hintText: "Entrer la surface mesurée en m²",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            OutBorderTextFormField(
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
            ),
            const SizedBox(height: 16),
            ValidationCheckbox(
              value: _isValid,
              label: "Je confirme que les informations saisies sont correctes",
              checkColor: GlobalColors.primary,
              onChanged: (value) {
                setState(() {
                  _isValid = value ?? false;
                });

              },
            ),
            const SizedBox(height: 24),
            BlocBuilder<GeometreBloc, GeometreState>(
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
                      : () {
                          if (_formKey.currentState!.validate() && _isValid) {
                            context.read<GeometreBloc>().add(ValidateLand(
                                  landId: land.id,
                                  isValid: _isValid,
                                  comments: _commentsController.text,
                                ));
                          } else if (!_isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Veuillez confirmer les informations en cochant la case'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
