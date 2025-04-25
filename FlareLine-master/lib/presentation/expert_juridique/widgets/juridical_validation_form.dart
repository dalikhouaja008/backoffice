// lib/presentation/expert_juridique/widgets/juridical_validation_form.dart
import 'dart:async';
import 'dart:html' as html;
import 'package:flareline/presentation/DocuSign/docusign_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/services/docusign_service.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flareline/presentation/expert_juridique/widgets/land_info_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/legal_header.dart';
import 'package:flareline/presentation/expert_juridique/widgets/document_list_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/legal_verification_section.dart';
import 'package:flareline/presentation/expert_juridique/widgets/comments_field.dart';
import 'package:flareline/presentation/geometre/widgets/land_images_gallery.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/core/injection/injection.dart';

class JuridicalValidationForm extends StatefulWidget {
  final Land land;

  const JuridicalValidationForm({
    super.key,
    required this.land,
  });

  @override
  State<JuridicalValidationForm> createState() =>
      _JuridicalValidationFormState();
}

class _JuridicalValidationFormState extends State<JuridicalValidationForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  bool _isValid = false;
  bool _documentsAreValid = false;
  bool _legalVerificationsComplete = false;

  // DocuSign fields
  String? _envelopeId;
  String? _signatureStatus;
  bool _isDocuSignReady = false;
  Timer? _tokenCheckTimer;
  Timer? _signatureCheckTimer;

  // Maps pour les vérifications juridiques
  final Map<String, bool> _legalVerifications = {
    'title_valid': false,
    'no_disputes': false,
    'boundaries_valid': false,
    'usage_rights': false,
  };

  @override
  void initState() {
    super.initState();

    context.read<DocuSignBloc>().add(CheckDocuSignAuthenticationEvent());
    _checkIfReturningFromSigning();
    html.window.addEventListener('message', _handleWindowMessage);
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _tokenCheckTimer?.cancel();
    _signatureCheckTimer?.cancel();
    html.window.removeEventListener('message', _handleWindowMessage);
    super.dispose();
  }

  void _checkIfReturningFromSigning() {
    final uri = Uri.parse(html.window.location.href);
    final params = uri.queryParameters;

    if (params['signing_complete'] == 'true' && params['envelopeId'] != null) {
      final envelopeId = params['envelopeId'];

      setState(() {
        _envelopeId = envelopeId;
      });

      context
          .read<DocuSignBloc>()
          .add(CheckEnvelopeStatusEvent(envelopeId: envelopeId!));
      html.window.history.pushState({}, '', html.window.location.pathname);
    }
  }

  void _handleWindowMessage(event) {
    html.MessageEvent e = event as html.MessageEvent;

    if (e.data == 'signing_complete' && _envelopeId != null) {
      context
          .read<DocuSignBloc>()
          .add(CheckEnvelopeStatusEvent(envelopeId: _envelopeId!));
    }
  }

  // On utilise cette méthode dans le BlocListener pour DocuSign
  void _listenToDocuSignState(BuildContext context, DocuSignState state) {
    if (state is DocuSignAuthenticated) {
      setState(() {
        _isDocuSignReady = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecté à DocuSign'),
          backgroundColor: Colors.green,
        ),
      );

      // Ici on appelle potentiellement _startTokenCheckTimer() si nécessaire
    } else if (state is DocuSignAuthenticationInitiated) {
      // Lors de l'initiation de l'authentification, on peut démarrer le timer
      _startTokenCheckTimer();
    }
  }

  // Implémentation de _startTokenCheckTimer pour qu'elle soit utilisée
  void _startTokenCheckTimer() {
    _tokenCheckTimer?.cancel();

    int attemptCount = 0;
    const maxAttempts = 60;

    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      attemptCount++;

      // Vérification périodique de l'authentification via le BLoC
      context.read<DocuSignBloc>().add(CheckDocuSignAuthenticationEvent());

      // Arrêter après le nombre maximum de tentatives
      if (attemptCount >= maxAttempts) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
      builder: (context, state) {
        return _buildForm(context, widget.land);
      },
    );
  }

  Widget _buildForm(BuildContext context, Land land) {
    return SingleChildScrollView (
      child: CommonCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LandImagesGallery(land: land),
              const SizedBox(height: 16),
              const LegalHeader(),
              const SizedBox(height: 16),
              LandInfoSection(land: land),
              const SizedBox(height: 16),
              DocumentListSection(
                land: land,
                onDocumentsValidated: (isValid) {
                  setState(() {
                    _documentsAreValid = isValid;
                  });
                },
              ),
              const SizedBox(height: 16),
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
              CommentsField(
                controller: _commentsController,
                land: land,
                onGenerateComment: () {
                  _generateComment(land);
                },
              ),
              const SizedBox(height: 16),
              BlocConsumer<DocuSignBloc, DocuSignState>(
                listener: (context, state) {
                  // Ce listener n'a plus besoin de faire grand-chose car la logique est dans DocuSignSection
                  if (state is DocuSignAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connecté à DocuSign'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is EnvelopeCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enveloppe créée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is EnvelopeStatusLoaded) {
                    if (state.envelope.status == 'completed' ||
                        state.envelope.status == 'signed') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document signé avec succès!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  // Autres états à gérer si nécessaire
                },
                builder: (context, state) {
                  return DocuSignSection(
                    land: land,
                    state: state,
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
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildValidationCheckbox(),
              const SizedBox(height: 24),
              _buildSubmitButton(land),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationCheckbox() {
    return ValidationCheckbox(
      value: _isValid,
      label:
          "Je confirme que les informations juridiques saisies sont correctes",
      checkColor: GlobalColors.primary,
      onChanged: (value) {
        setState(() {
          _isValid = value ?? false;
        });
      },
    );
  }

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

  void _generateComment(Land land) {
    final hasDocuments =
        land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;
    final StringBuilder = StringBuffer();
    final timestamp = "2025-04-25 09:22:03"; // Date actuelle fournie

    StringBuilder.writeln('RAPPORT DE VALIDATION JURIDIQUE');
    StringBuilder.writeln('Terrain: "${land.title}" situé à ${land.location}');
    StringBuilder.writeln('ID Blockchain: ${land.blockchainLandId}');
    StringBuilder.writeln('Date de validation: $timestamp');
    StringBuilder.writeln();

    if (hasDocuments) {
      if (_documentsAreValid) {
        StringBuilder.writeln('DOCUMENTS JURIDIQUES EXAMINÉS:');
        StringBuilder.writeln('✓ Titres de propriété vérifiés et authentiques');
        StringBuilder.writeln('✓ Documentation cadastrale conforme');
        StringBuilder.writeln('✓ Absence de servitudes non déclarées');
        StringBuilder.writeln('✓ Conformité avec le plan local d\'urbanisme');
      } else {
        StringBuilder.writeln('DOCUMENTS JURIDIQUES - STATUT:');
        StringBuilder.writeln(
            '⚠ Vérification des titres de propriété nécessaire');
        StringBuilder.writeln('⚠ Statut des éventuels litiges à confirmer');
        StringBuilder.writeln(
            '⚠ Conformité aux règles d\'urbanisme à vérifier');
      }
      StringBuilder.writeln();
    } else {
      StringBuilder.writeln('ABSENCE DE DOCUMENTS:');
      StringBuilder.writeln(
          '⚠ Aucun document juridique n\'a été fourni pour ce terrain.');
      StringBuilder.writeln(
          '⚠ Une validation complète des titres de propriété et des droits associés est nécessaire avant toute tokenisation.');
      StringBuilder.writeln();
    }

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
    StringBuilder.writeln('INFORMATIONS DE PROPRIÉTÉ:');
    StringBuilder.writeln('- Adresse du propriétaire: ${land.ownerAddress}');
    StringBuilder.writeln('- Surface déclarée: ${land.surface} m²');
    StringBuilder.writeln();

    if (_envelopeId != null) {
      StringBuilder.writeln('SIGNATURE ÉLECTRONIQUE:');
      StringBuilder.writeln(
          '✓ Document envoyé pour signature électronique via DocuSign');
      StringBuilder.writeln('- ID de l\'enveloppe: $_envelopeId');
      StringBuilder.writeln('- Statut actuel: $_signatureStatus');
      StringBuilder.writeln();
    }

    final allVerificationsComplete = _legalVerifications.values.every((v) => v);

    StringBuilder.writeln('CONCLUSION:');
    if (allVerificationsComplete && _documentsAreValid) {
      StringBuilder.writeln(
          '✓ Le terrain a été examiné du point de vue juridique et ne présente aucun obstacle légal à sa tokenisation.');
      StringBuilder.writeln(
          '✓ Les documents sont juridiquement valides et conformes à la réglementation en vigueur.');
    } else {
      StringBuilder.writeln(
          '⚠ Des vérifications juridiques supplémentaires sont nécessaires avant de procéder à la tokenisation.');
      StringBuilder.writeln(
          '⚠ Points spécifiques nécessitant une attention particulière: ${_getIncompleteVerifications()}');
    }

    setState(() {
      _commentsController.text = StringBuilder.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commentaire juridique généré avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _submitForm(BuildContext context, Land land) {
    if (_formKey.currentState!.validate()) {
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

      final hasDocuments =
          land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;
      if (hasDocuments && !_documentsAreValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veuillez confirmer que les documents juridiques sont valides'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_legalVerificationsComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Veuillez compléter toutes les vérifications juridiques'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
    final timestamp = "2025-04-25 09:22:03"; // Date actuelle fournie
    final signatureInfo = _envelopeId != null
        ? "- Signature électronique: OUI (ID: $_envelopeId, Statut: $_signatureStatus)"
        : "- Signature électronique: NON";

    final commentsWithDetails = '''
${_commentsController.text}

RÉSUMÉ DE VALIDATION:
- Expert juridique: nessim
- Date de validation: $timestamp
- Documents validés: ${_documentsAreValid ? "OUI" : "NON"}
- Titres de propriété vérifiés: ${_legalVerifications['title_valid']! ? "OUI" : "NON"}
- Absence de litiges confirmée: ${_legalVerifications['no_disputes']! ? "OUI" : "NON"}
- Limites du terrain validées: ${_legalVerifications['boundaries_valid']! ? "OUI" : "NON"}
- Droits d'usage conformes: ${_legalVerifications['usage_rights']! ? "OUI" : "NON"}
$signatureInfo
''';

    context.read<ExpertJuridiqueBloc>().add(ValidateLand(
          landId: land.blockchainLandId,
          isValid: _isValid,
          comment: commentsWithDetails,
        ));
  }

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
}
