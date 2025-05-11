import 'package:flareline/presentation/DocuSign/docusign_document_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';

class DocuSignActionButtons extends StatelessWidget {
  final bool isDocuSignReady;
  final bool isConnecting;
  final bool isProcessing;
  final bool isRefreshingStatus;
  final bool isDownloading;
  final String? envelopeId;
  final String? signatureStatus;
  final Land land;
  
  const DocuSignActionButtons({
    super.key,
    required this.isDocuSignReady,
    required this.isConnecting,
    required this.isProcessing,
    required this.isRefreshingStatus,
    required this.isDownloading,
    required this.envelopeId,
    required this.signatureStatus,
    required this.land,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDocuSignReady)
          _buildConnectButton(context),
        
        if (isDocuSignReady && envelopeId == null)
          _buildCreateEnvelopeButton(context),
        
        if (envelopeId != null)
          Row(
            children: [
              Expanded(child: _buildRefreshStatusButton(context)),
              const SizedBox(width: 8),
              if (signatureStatus == 'Signé' || signatureStatus == 'Terminé')
                Expanded(child: _buildDownloadButton(context)),
            ],
          ),
      ],
    );
  }
  
  // Bouton de connexion à DocuSign
  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isConnecting 
          ? null 
          : () => context.read<DocuSignBloc>().add(InitiateDocuSignAuthenticationEvent()),
      icon: isConnecting
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login),
      label: Text(isConnecting ? 'Connexion en cours...' : 'Se connecter à DocuSign'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.blue.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Bouton de création d'enveloppe
  Widget _buildCreateEnvelopeButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isProcessing 
          ? null 
          : () async {
              if (await _confirmSignatureProcess(context)) {
                _initiateSigningProcess(context);
              }
            },
      icon: isProcessing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.edit_document),
      label: Text(isProcessing ? 'Préparation...' : 'Envoyer pour signature'),
      style: ElevatedButton.styleFrom(
        backgroundColor: GlobalColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: GlobalColors.primary.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Bouton d'actualisation du statut
  Widget _buildRefreshStatusButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isRefreshingStatus || envelopeId == null
          ? null 
          : () => context.read<DocuSignBloc>()
              .add(CheckEnvelopeStatusEvent(envelopeId: envelopeId!)),
      icon: isRefreshingStatus
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(isRefreshingStatus ? 'Actualisation...' : 'Actualiser le statut'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.blue.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Bouton de téléchargement
  Widget _buildDownloadButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isDownloading || envelopeId == null
          ? null 
          : () => context.read<DocuSignBloc>()
              .add(DownloadDocumentEvent(envelopeId: envelopeId!)),
      icon: isDownloading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download),
      label: Text(isDownloading ? 'Téléchargement...' : 'Télécharger'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.green.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Dialogue de confirmation de signature
  Future<bool> _confirmSignatureProcess(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la signature'),
        content: const Text(
          'Vous êtes sur le point de lancer le processus de signature électronique. '
          'Assurez-vous que tous les documents sont corrects avant de continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Initialiser le processus de signature
 void _initiateSigningProcess(BuildContext context) async {
  try {
    // Convertir le document en base64
    final documentService = DocuSignDocumentService();
    final documentBase64 = await documentService.prepareDocumentForSignature(land);
    

    context.read<DocuSignBloc>().add(CreateEnvelopeEvent(
      documentBase64: documentBase64,
      signerEmail: 'mohamedali.khouaja@esprit.tn', 
      signerName: 'Mohamed ali', 
      title: 'Validation du terrain: ${land.title}',
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
}