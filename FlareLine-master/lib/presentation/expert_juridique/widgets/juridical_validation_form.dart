import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/expert_juridique/widgets/land_info_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/legal_header.dart';
import 'package:flareline/presentation/expert_juridique/widgets/document_list_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/legal_verification_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/comments_field.dart';
import 'package:flareline/presentation/DocuSign/docusign_section.dart';
import 'package:flareline/presentation/geometre/widgets/land_images_gallery.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

class JuridicalValidationForm extends StatefulWidget {
  final Land land;
  
  const JuridicalValidationForm({
    super.key,
    required this.land,
  });

  @override
  State<JuridicalValidationForm> createState() => _JuridicalValidationFormState();
}

class _JuridicalValidationFormState extends State<JuridicalValidationForm> {
  // Contrôleurs et états du formulaire
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  bool _isValid = false;
  bool _legalVerificationsComplete = false;
  
  // Variables pour les vérifications juridiques
  final Map<String, bool> _legalVerifications = {
    'title_valid': false,
    'no_disputes': false,
    'boundaries_valid': false,
    'usage_rights': false,
  };

  // Variable pour la vérification des documents
  bool _documentsAreValid = false;

  // Variables DocuSign
  String? _envelopeId;
  String? _signatureStatus;
  bool _isDocuSignReady = false;

  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification DocuSign
    context.read<DocuSignBloc>().add(CheckDocuSignAuthenticationEvent());
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocuSignBloc, DocuSignState>(
      listener: (context, docuSignState) {
        if (docuSignState is DocuSignAuthenticated) {
          setState(() {
            _isDocuSignReady = true;
          });
        } else if (docuSignState is EnvelopeCreated) {
          setState(() {
            _envelopeId = docuSignState.envelopeId;
            _signatureStatus = "Envoyé";
          });
        } else if (docuSignState is EnvelopeStatusLoaded) {
          setState(() {
            _signatureStatus = docuSignState.envelope.status;
          });
        }
      },
      builder: (context, docuSignState) {
        return BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
          builder: (context, state) {
            return CommonCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section galerie d'images
                    LandImagesGallery(land: widget.land),
                    const SizedBox(height: 16),

                    // Section titre juridique
                    const LegalHeader(),
                    const SizedBox(height: 16),

                    // Section informations du terrain
                    LandInfoSection(land: widget.land),
                    const SizedBox(height: 16),

                    // Section liste des documents
                    DocumentListSection(
                      land: widget.land,
                      onDocumentsValidated: (isValid) {
                        setState(() {
                          _documentsAreValid = isValid;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section de vérifications juridiques
                    LegalVerificationSection(
                      onVerificationsUpdated: 
                        (Map<String, bool> verifications, bool allComplete) {
                        setState(() {
                          _legalVerifications.addAll(verifications);
                          _legalVerificationsComplete = allComplete;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section commentaires
                    CommentsField(
                      controller: _commentsController,
                      land: widget.land,
                      onGenerateComment: () => _generateComment(widget.land),
                    ),
                    const SizedBox(height: 16),

                    // Section DocuSign
                    DocuSignSection(
                      land: widget.land,
                      state: docuSignState,
                      envelopeId: _envelopeId,
                      signatureStatus: _signatureStatus,
                      isDocuSignReady: _isDocuSignReady,
                      onDocuSignStatusChanged: (bool isReady) {
                        setState(() {
                          _isDocuSignReady = isReady;
                        });
                      },
                      onEnvelopeIdChanged: (String envelopeId) {
                        setState(() {
                          _envelopeId = envelopeId;
                        });
                      },
                      onStatusChanged: (String status) {
                        setState(() {
                          _signatureStatus = status;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Checkbox de validation
                    ValidationCheckbox(
                      value: _isValid,
                      label: "Je confirme que les informations juridiques saisies sont correctes",
                      checkColor: GlobalColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _isValid = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bouton de soumission
                    _buildSubmitButton(widget.land),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Bouton de soumission du formulaire
  Widget _buildSubmitButton(Land land) {
    return BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
      builder: (context, state) {
        final bool isValidating = state is ValidationInProgress;

        return ButtonForm(
          btnText:
              isValidating ? "Validation en cours..." : "Valider juridiquement",
          type: ButtonType.primary.type,
          isLoading: isValidating,
          onPressed: isValidating ? null : () => _submitForm(context, land),
        );
      },
    );
  }

  /// Génère un commentaire juridique basé sur les informations du terrain
  void _generateComment(Land land) {
    // Vérifier si des documents sont disponibles
    final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

    // Construction du commentaire complet
    final StringBuilder = StringBuffer();
    final timestamp = "2025-04-26 22:08:23"; // Date actualisée (UTC)

    StringBuilder.writeln('RAPPORT DE VALIDATION JURIDIQUE');
    StringBuilder.writeln('Terrain: "${land.title}" situé à ${land.location}');
    StringBuilder.writeln('ID Blockchain: ${land.blockchainLandId}');
    StringBuilder.writeln('Date de validation: $timestamp');
    StringBuilder.writeln();

    // Commentaire sur les documents
    if (hasDocuments) {
      if (_documentsAreValid) {
        StringBuilder.writeln('DOCUMENTS JURIDIQUES EXAMINÉS:');
        StringBuilder.writeln('✓ Titres de propriété vérifiés et authentiques');
        StringBuilder.writeln('✓ Documentation cadastrale conforme');
        StringBuilder.writeln('✓ Absence de servitudes non déclarées');
        StringBuilder.writeln('✓ Conformité avec le plan local d\'urbanisme');
      } else {
        StringBuilder.writeln('DOCUMENTS JURIDIQUES - STATUT:');
        StringBuilder.writeln('⚠ Vérification des titres de propriété nécessaire');
        StringBuilder.writeln('⚠ Statut des éventuels litiges à confirmer');
        StringBuilder.writeln('⚠ Conformité aux règles d\'urbanisme à vérifier');
      }
      StringBuilder.writeln();
    } else {
      StringBuilder.writeln('ABSENCE DE DOCUMENTS:');
      StringBuilder.writeln('⚠ Aucun document juridique n\'a été fourni pour ce terrain.');
      StringBuilder.writeln('⚠ Une validation complète des titres de propriété et des droits associés est nécessaire avant toute tokenisation.');
      StringBuilder.writeln();
    }

    // Section des vérifications juridiques
    StringBuilder.writeln('VÉRIFICATIONS JURIDIQUES:');
    
    for (final entry in _legalVerifications.entries) {
      final isValid = entry.value;
      final prefix = isValid ? "✓" : "⚠";
      
      String description;
      switch (entry.key) {
        case 'title_valid':
          description = isValid 
              ? 'Titres de propriété authentiques et valides' 
              : 'Vérification supplémentaire des titres nécessaire';
          break;
        case 'no_disputes':
          description = isValid 
              ? 'Aucun litige en cours identifié'
              : 'Recherche de litiges potentiels recommandée';
          break;
        case 'boundaries_valid':
          description = isValid 
              ? 'Délimitations cadastrales correctement établies'
              : 'Clarification des limites du terrain nécessaire';
          break;
        case 'usage_rights':
          description = isValid 
              ? 'Droits d\'usage conformes à la réglementation en vigueur'
              : 'Vérification des droits d\'usage recommandée';
          break;
        default:
          description = 'Point de vérification non spécifié';
      }
      
      StringBuilder.writeln('$prefix $description');
    }
    
    StringBuilder.writeln();

    // Informations sur le propriétaire
    StringBuilder.writeln('INFORMATIONS DE PROPRIÉTÉ:');
    StringBuilder.writeln('- Adresse du propriétaire: ${land.ownerAddress}');
    StringBuilder.writeln('- Surface déclarée: ${land.surface} m²');
    StringBuilder.writeln();

    // Information sur la signature électronique
    if (_envelopeId != null) {
      StringBuilder.writeln('SIGNATURE ÉLECTRONIQUE:');
      StringBuilder.writeln('✓ Document envoyé pour signature électronique via DocuSign');
      StringBuilder.writeln('- ID de l\'enveloppe: $_envelopeId');
      StringBuilder.writeln('- Statut actuel: $_signatureStatus');
      StringBuilder.writeln();
    }

    // Conclusion générale
    final allVerificationsComplete = _legalVerifications.values.every((v) => v);
    
    StringBuilder.writeln('CONCLUSION:');
    if (allVerificationsComplete && _documentsAreValid) {
      StringBuilder.writeln('✓ Le terrain a été examiné du point de vue juridique et ne présente aucun obstacle légal à sa tokenisation.');
      StringBuilder.writeln('✓ Les documents sont juridiquement valides et conformes à la réglementation en vigueur.');
    } else {
      StringBuilder.writeln('⚠ Des vérifications juridiques supplémentaires sont nécessaires avant de procéder à la tokenisation.');
      StringBuilder.writeln('⚠ Points spécifiques nécessitant une attention particulière: ${_getIncompleteVerifications()}');
    }

    // Mettre à jour le contrôleur de texte
    setState(() {
      _commentsController.text = StringBuilder.toString();
    });

    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commentaire juridique généré avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Obtenir la liste des vérifications incomplètes
  String _getIncompleteVerifications() {
    List<String> incomplete = [];
    
    if (!(_legalVerifications['title_valid'] ?? false)) {
      incomplete.add('titres de propriété');
    }
    if (!(_legalVerifications['no_disputes'] ?? false)) {
      incomplete.add('litiges potentiels');
    }
    if (!(_legalVerifications['boundaries_valid'] ?? false)) {
      incomplete.add('délimitations cadastrales');
    }
    if (!(_legalVerifications['usage_rights'] ?? false)) {
      incomplete.add('droits d\'usage');
    }
    
    if (incomplete.isEmpty) return 'aucun';
    
    return incomplete.join(', ');
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

      // Vérifier si des documents sont disponibles et si la case de validation est cochée
      final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;
      if (hasDocuments && !_documentsAreValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez confirmer que les documents juridiques sont valides'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Vérifier si toutes les vérifications juridiques sont complètes
      if (!_legalVerificationsComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez compléter toutes les vérifications juridiques'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Si DocuSign est prêt mais qu'aucun document n'a été envoyé pour signature,
      // demander à l'utilisateur s'il souhaite continuer sans signature
      if (hasDocuments && _isDocuSignReady && _envelopeId == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Signature électronique'),
            content: const Text(
                'Les documents n\'ont pas encore été envoyés pour signature électronique. '
                'Voulez-vous continuer la validation sans signature électronique?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _completeSubmission(context, land);
                },
                child: const Text('Continuer sans signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        _completeSubmission(context, land);
      }
    }
  }

  void _completeSubmission(BuildContext context, Land land) {
    // Inclure l'information sur la validation des documents et la signature dans les commentaires
    final timestamp = "2025-04-26 22:08:23"; // Date actualisée (UTC)
    final signatureInfo = _envelopeId != null
        ? "- Signature électronique: OUI (ID: $_envelopeId, Statut: $_signatureStatus)"
        : "- Signature électronique: NON";

    final commentsWithDetails = '''
${_commentsController.text}

RÉSUMÉ DE VALIDATION:
- Expert juridique: nesssim
- Date de validation: $timestamp
- Documents validés: ${_documentsAreValid ? "OUI" : "NON"}
- Titres de propriété vérifiés: ${_legalVerifications['title_valid']! ? "OUI" : "NON"}
- Absence de litiges confirmée: ${_legalVerifications['no_disputes']! ? "OUI" : "NON"}
- Limites du terrain validées: ${_legalVerifications['boundaries_valid']! ? "OUI" : "NON"}
- Droits d'usage conformes: ${_legalVerifications['usage_rights']! ? "OUI" : "NON"}
$signatureInfo
''';

    // Soumettre le formulaire
    context.read<ExpertJuridiqueBloc>().add(ValidateLand(
          landId: land.blockchainLandId,
          isValid: _isValid,
          comment: commentsWithDetails,
        ));
  }
}