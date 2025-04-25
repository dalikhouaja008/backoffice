import 'package:flareline/presentation/DocuSign/docusign_action_buttons.dart';
import 'package:flareline/presentation/DocuSign/docusign_help_dialog.dart';
import 'package:flareline/presentation/DocuSign/docusign_status_indicator.dart';
import 'package:flareline/presentation/DocuSign/signature_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';

class DocuSignSection extends StatelessWidget {
  final Land land;
  final DocuSignState state;
  final String? envelopeId;
  final String? signatureStatus;
  final bool isDocuSignReady;

  // Callbacks pour la communication avec le parent
  final Function(bool)? onDocuSignStatusChanged;
  final Function(String)? onEnvelopeIdChanged;
  final Function(String)? onStatusChanged;

  const DocuSignSection({
    super.key,
    required this.land,
    required this.state,
    required this.envelopeId,
    required this.signatureStatus,
    required this.isDocuSignReady,
    this.onDocuSignStatusChanged,
    this.onEnvelopeIdChanged,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

    // Déterminer si certaines actions sont en cours
    final bool isConnecting = state is DocuSignAuthCheckInProgress;
    final bool isProcessing = state is EnvelopeCreationInProgress;
    final bool isRefreshingStatus = state is EnvelopeStatusCheckInProgress;
    final bool isDownloading = state is DocumentDownloadInProgress;

    // Traitement des états DocuSign de façon sécurisée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pour authentification
      if (state is DocuSignAuthenticated && onDocuSignStatusChanged != null) {
        onDocuSignStatusChanged!(true);
      }

      // Pour création d'enveloppe
      if (state is EnvelopeCreated && onEnvelopeIdChanged != null) {
        onEnvelopeIdChanged!((state as EnvelopeCreated).envelopeId);
        if (onStatusChanged != null) {
          onStatusChanged!("Envoyé");
        }
      }

      // Pour chargement du statut de l'enveloppe
      if (state is EnvelopeStatusLoaded && onStatusChanged != null) {
        final status = (state as EnvelopeStatusLoaded).envelope.status;
        if (status != null) {
          onStatusChanged!(_mapStatusToDisplay(status));
        }
      }
    });

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
            blurRadius: 2
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Row(
            children: [
              Icon(Icons.verified, color: GlobalColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text('Signature Électronique',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Bouton d'aide
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const DocuSignHelpDialog(),
                ),
                tooltip: 'Comment fonctionne la signature électronique',
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

          // Indicateur d'état
          DocuSignStatusIndicator(
            isConnecting: isConnecting,
            isDocuSignReady: isDocuSignReady,
          ),
          const SizedBox(height: 16),

          // Messages conditionnels
          if (!hasDocuments) _buildNoDocumentsWarning(),

          // Affichage du statut si une enveloppe a été créée
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

  // Message d'avertissement si aucun document n'est disponible
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
  
  // Méthode pour mapper les statuts
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