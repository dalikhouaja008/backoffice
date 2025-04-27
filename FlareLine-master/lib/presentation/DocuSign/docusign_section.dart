import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'dart:convert';
import 'dart:html' as html;

class DocuSignSection extends StatefulWidget {
  final Land land;
  final DocuSignState state;
  final String? envelopeId;
  final String? signatureStatus;
  final bool isDocuSignReady;
  final Function(bool) onDocuSignStatusChanged;
  final Function(String) onEnvelopeIdChanged;
  final Function(String) onStatusChanged;

  const DocuSignSection({
    Key? key,
    required this.land,
    required this.state,
    required this.envelopeId,
    required this.signatureStatus,
    required this.isDocuSignReady,
    required this.onDocuSignStatusChanged,
    required this.onEnvelopeIdChanged,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<DocuSignSection> createState() => _DocuSignSectionState();
}

class _DocuSignSectionState extends State<DocuSignSection> {
  @override
  Widget build(BuildContext context) {
    // Vérifier si des documents sont disponibles
    final hasDocuments =
        widget.land.documentUrls.isNotEmpty || widget.land.ipfsCIDs.isNotEmpty;

    final isConnecting = widget.state is DocuSignAuthCheckInProgress;
    final isProcessing = widget.state is EnvelopeCreationInProgress;
    final isRefreshingStatus = widget.state is EnvelopeStatusCheckInProgress;
    final isDownloading = widget.state is DocumentDownloadInProgress;

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
          if (widget.envelopeId != null)
            _buildSignatureStatus(),

          const SizedBox(height: 16),

          // Boutons d'action
          if (hasDocuments)
            _buildActionButtons(isConnecting, isProcessing, isRefreshingStatus, isDownloading),
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

  Widget _buildSignatureStatus() {
    Color statusColor;
    IconData statusIcon;

    switch (widget.signatureStatus?.toLowerCase()) {
      case 'envoyé':
        statusColor = Colors.orange;
        statusIcon = Icons.mark_email_read;
        break;
      case 'remis':
        statusColor = Colors.blue;
        statusIcon = Icons.inbox;
        break;
      case 'signé':
      case 'terminé':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'refusé':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'en cours de signature':
        statusColor = Colors.blue;
        statusIcon = Icons.edit_document;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Statut de la signature: ${widget.signatureStatus ?? "En attente"}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (widget.envelopeId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'ID de l\'enveloppe: ${widget.envelopeId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    bool isConnecting, 
    bool isProcessing, 
    bool isRefreshingStatus, 
    bool isDownloading
  ) {
    if (!widget.isDocuSignReady) {
      return ElevatedButton.icon(
        onPressed: isConnecting 
          ? null 
          : () => context.read<DocuSignBloc>().add(InitiateDocuSignAuthenticationEvent()),
        icon: isConnecting 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ) 
          : const Icon(Icons.login),
        label: Text(isConnecting ? "Connexion en cours..." : "Se connecter à DocuSign"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }
    
    if (widget.envelopeId == null) {
      return ElevatedButton.icon(
        onPressed: isProcessing
          ? null
          : () => _initiateSignatureProcess(),
        icon: isProcessing 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.edit_document),
        label: Text(isProcessing ? "En cours..." : "Envoyer pour signature"),
        style: ElevatedButton.styleFrom(
          backgroundColor: GlobalColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRefreshingStatus
              ? null
              : () => _refreshSignatureStatus(),
            icon: isRefreshingStatus
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh),
            label: Text(isRefreshingStatus ? "En cours..." : "Actualiser le statut"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isDownloading
            ? null
            : () => _downloadSignedDocument(),
          icon: isDownloading
            ? const SizedBox(
                width: 16, 
                height: 16, 
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
          tooltip: 'Télécharger le document signé',
          color: GlobalColors.primary,
        ),
      ],
    );
  }

  Future<void> _initiateSignatureProcess() async {
    if (widget.land.documentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun document disponible pour signature'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Récupérer le premier document
      final documentUrl = widget.land.documentUrls.first;

      // Simuler la récupération du document (dans un projet réel, vous téléchargeriez le document)
      // Pour cette démonstration, on utilise un document fictif
      final documentBase64 = base64Encode(utf8.encode('Document simulé pour signature'));

      // Créer l'enveloppe DocuSign
      context.read<DocuSignBloc>().add(CreateEnvelopeEvent(
        documentBase64: documentBase64,
        signerEmail: 'nesssim@example.com', // Utiliser une adresse email valide pour les tests
        signerName: 'nesssim',
        title: 'Validation juridique - ${widget.land.title}',
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshSignatureStatus() {
    if (widget.envelopeId == null) return;

    context.read<DocuSignBloc>().add(
      CheckEnvelopeStatusEvent(envelopeId: widget.envelopeId!),
    );
  }

  void _downloadSignedDocument() {
    if (widget.envelopeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun document signé disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<DocuSignBloc>().add(
      DownloadDocumentEvent(envelopeId: widget.envelopeId!),
    );
  }
}