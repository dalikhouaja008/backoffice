// lib/presentation/expert_juridique/widgets/docusign/docusign_section.dart
import 'package:flareline/presentation/DocuSign/docusign_action_buttons.dart';
import 'package:flareline/presentation/DocuSign/signature_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';


class DocuSignSection extends StatelessWidget {
  final Land land;
  final String? envelopeId;
  final String? signatureStatus;
  final bool isDocuSignReady;
  final Function(bool) onDocuSignStatusChanged;
  final Function(String) onEnvelopeCreated;
  final Function(String) onStatusChanged;

  const DocuSignSection({
    super.key,
    required this.land,
    required this.envelopeId,
    required this.signatureStatus,
    required this.isDocuSignReady,
    required this.onDocuSignStatusChanged,
    required this.onEnvelopeCreated,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Vérifier si des documents sont disponibles
    final hasDocuments =
        land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

    return BlocConsumer<DocuSignBloc, DocuSignState>(
      listener: (context, state) {
        if (state is DocuSignAuthenticated) {
          onDocuSignStatusChanged(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connecté à DocuSign'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is DocuSignAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'authentification: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is EnvelopeCreated) {
          onEnvelopeCreated(state.envelopeId);
          onStatusChanged('Envoyé');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enveloppe créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is EnvelopeStatusLoaded) {
          final mappedStatus = _mapStatusToDisplay(state.envelope.status);
          onStatusChanged(mappedStatus);
          
          // Si le document est signé ou terminé, afficher un message
          if (state.envelope.status == 'completed' || state.envelope.status == 'signed') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document signé avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } 
      },
      builder: (context, state) {
        return _buildDocuSignSection(context, state, hasDocuments);
      },
    );
  }

  Widget _buildDocuSignSection(BuildContext context, DocuSignState state, bool hasDocuments) {
    bool isConnecting = state is DocuSignAuthCheckInProgress;
    bool isProcessing = state is EnvelopeCreationInProgress;
    bool isRefreshingStatus = state is EnvelopeStatusCheckInProgress;
    bool isDownloading = state is DocumentDownloadInProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Icon(
                Icons.verified,
                color: GlobalColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Signature Électronique',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          const Text(
            'Utilisez DocuSign pour faire signer électroniquement les documents juridiques du terrain.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Message si aucun document n'est disponible
          if (!hasDocuments)
            _buildNoDocumentsWarning(),

          // Statut de signature si applicable
          if (envelopeId != null) 
            SignatureStatusWidget(
              envelopeId: envelopeId!,
              status: signatureStatus,
              isRefreshing: isRefreshingStatus,
            ),

          const SizedBox(height: 16),

          // Boutons d'action
          if (hasDocuments)
            DocuSignActionButtons(
              isDocuSignReady: isDocuSignReady,
              isConnecting: isConnecting,
              isProcessing: isProcessing,
              isRefreshingStatus: isRefreshingStatus,
              isDownloading: isDownloading,
              envelopeId: envelopeId,
              signatureStatus: signatureStatus,
              land: land,
            ),
        ],
      ),
    );
  }

  Widget _buildNoDocumentsWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aucun document n\'est disponible pour signature. Ajoutez des documents au terrain avant de demander une signature.',
              style: TextStyle(color: Colors.amber, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _mapStatusToDisplay(String? status) {
    if (status == null) return 'Inconnu';
    
    switch (status.toLowerCase()) {
      case 'sent':
        return 'Envoyé';
      case 'delivered':
        return 'Remis';
      case 'completed':
      case 'signed':
        return 'Signé';
      case 'declined':
        return 'Refusé';
      default:
        return status;
    }
  }
}