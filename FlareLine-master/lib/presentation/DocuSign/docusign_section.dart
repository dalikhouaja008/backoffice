import 'package:flareline/core/services/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'package:flareline/core/services/docusign_service.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';
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
    super.key,
    required this.land,
    required this.state,
    required this.envelopeId,
    required this.signatureStatus,
    required this.isDocuSignReady,
    required this.onDocuSignStatusChanged,
    required this.onEnvelopeIdChanged,
    required this.onStatusChanged,
  });

  @override
  State<DocuSignSection> createState() => _DocuSignSectionState();
}

class _DocuSignSectionState extends State<DocuSignSection> {
  html.WindowBase? _authWindow;
  final Logger _logger = getIt<Logger>();
  final DocuSignService _docuSignService = getIt<DocuSignService>();

@override
void initState() {
  super.initState();
  
  // Configurer l'écouteur de messages pour les tokens DocuSign
  _setupMessageListener();
  
  // Vérifier s'il y a déjà un token disponible, mais SANS appeler setState pendant le build
  if (_docuSignService.checkExistingAuth()) {
    // Utiliser cette technique pour reporter l'exécution après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDocuSignStatusChanged(true);
    });
  }
}

  @override
  void dispose() {
    // Fermer la fenêtre d'authentification si elle est encore ouverte
    _closeAuthWindowIfOpen();
    super.dispose();
  }
void _setupMessageListener() {
  _logger.i('🔒 Configuration de l\'écouteur de messages DocuSign');
  
  html.window.onMessage.listen((html.MessageEvent event) {
    try {
      _logger.i('📨 Message reçu: ${event.data.runtimeType}');
      
      // Vérifier si le message est une Map
      if (event.data is Map) {
        final data = event.data;
        
        // Vérifier si c'est un token DocuSign
        if (data['type'] == 'DOCUSIGN_TOKEN') {
          final token = data['token'];
          final expiresIn = data['expiresIn']; // Noter que le backend pourrait envoyer 'expiresIn'
          final accountId = data['accountId'];
          final expiry = data['expiry']; // Récupérer la valeur d'expiry envoyée par le backend
          
          if (token != null && token is String) {
            _logger.i('🔑 Token DocuSign reçu via postMessage');
            
            // Mettre à jour le token dans le service
            _docuSignService.setAccessToken(token, expiresIn: expiresIn);
            
            // Stocker le token dans le stockage sécurisé
            // Utiliser la valeur expiry si disponible, sinon calculer à partir de expiresIn
            final String? expiryValue = expiry != null ? expiry.toString() : null;
            _storeTokenInSecureStorage(token, accountId, expiresIn, expiryValue);
            
            // Utiliser WidgetsBinding pour sécuriser l'appel à setState
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Mettre à jour l'état dans l'interface
                setState(() {
                  widget.onDocuSignStatusChanged(true);
                });
                
                // Fermer la fenêtre d'authentification
                _closeAuthWindowIfOpen();
                
                // Afficher une notification de succès
                _showSuccessNotification();
              }
            });
          }
        }
      }
    } catch (e) {
      _logger.e('❌ Erreur lors du traitement du message: $e');
    }
  });
}

void _storeTokenInSecureStorage(String token, String? accountId, int? expiresIn, [String? expiry]) {
  try {
    // Récupérer le service de stockage sécurisé
    final secureStorage = getIt<SecureStorageService>();
    
    // Stocker le token
    secureStorage.write(key: 'docusign_token', value: token);
    
    // Stocker l'ID du compte si disponible
    if (accountId != null && accountId.isNotEmpty) {
      secureStorage.write(key: 'docusign_account_id', value: accountId);
    }
    
    // Utiliser l'expiration reçue ou en calculer une nouvelle
    final expiryValue = expiry ?? 
        DateTime.now().add(Duration(seconds: expiresIn ?? 3600)).millisecondsSinceEpoch.toString();
    
    secureStorage.write(key: 'docusign_expiry', value: expiryValue);
    
    _logger.i('🔒 Token DocuSign stocké dans le stockage sécurisé');
  } catch (e) {
    _logger.e('❌ Erreur lors du stockage du token dans le stockage sécurisé: $e');
  }
}
  void _closeAuthWindowIfOpen() {
    if (_authWindow != null && !_authWindow!.closed!) {
      _authWindow!.close();
      _authWindow = null;
    }
  }

  void _showSuccessNotification() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Authentification DocuSign réussie!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ));
  }

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
          if (!hasDocuments) _buildNoDocumentsWarning(),

          // Statut de signature si applicable
          if (widget.envelopeId != null) _buildSignatureStatus(),

          const SizedBox(height: 16),

          // Boutons d'action
          if (hasDocuments)
            _buildActionButtons(
                isConnecting, isProcessing, isRefreshingStatus, isDownloading),
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

  Widget _buildActionButtons(bool isConnecting, bool isProcessing,
      bool isRefreshingStatus, bool isDownloading) {
    if (!widget.isDocuSignReady) {
      return ElevatedButton.icon(
        onPressed: isConnecting ? null : () => _initiateDocuSignAuth(),
        icon: isConnecting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.login),
        label: Text(
            isConnecting ? "Connexion en cours..." : "Se connecter à DocuSign"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    if (widget.envelopeId == null) {
      return ElevatedButton.icon(
        onPressed: isProcessing ? null : () => _initiateSignatureProcess(),
        icon: isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
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
            onPressed:
                isRefreshingStatus ? null : () => _refreshSignatureStatus(),
            icon: isRefreshingStatus
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: Text(
                isRefreshingStatus ? "En cours..." : "Actualiser le statut"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isDownloading ? null : () => _downloadSignedDocument(),
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

  // Nouvelle méthode pour gérer l'authentification DocuSign
  void _initiateDocuSignAuth() {
    // Notifier le bloc pour commencer le processus d'authentification
    context.read<DocuSignBloc>().add(InitiateDocuSignAuthenticationEvent());

    // Ouvrir une nouvelle fenêtre pour l'authentification
    _authWindow = html.window.open('/docusign/login', 'DocuSignAuth',
        'width=800,height=600,resizable=yes,scrollbars=yes,status=yes');

    if (_authWindow == null || _authWindow!.closed == true) {
      _logger.e('❌ La fenêtre d\'authentification DocuSign a été bloquée');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez autoriser les fenêtres popup pour ce site'),
        backgroundColor: Colors.red,
      ));
    } else {
      _logger.i('✅ Fenêtre d\'authentification DocuSign ouverte');

      // Vérifier périodiquement si la fenêtre est fermée
      Future.delayed(const Duration(seconds: 1), () {
        _checkAuthWindowStatus();
      });
    }
  }

  void _checkAuthWindowStatus() {
    if (_authWindow != null && !_authWindow!.closed!) {
      // Continuer à vérifier si la fenêtre est ouverte
      Future.delayed(const Duration(seconds: 1), () {
        _checkAuthWindowStatus();
      });
    } else {
      // La fenêtre a été fermée, vérifier si nous avons un token
      if (_docuSignService.checkExistingAuth() && !widget.isDocuSignReady) {
        setState(() {
          widget.onDocuSignStatusChanged(true);
        });
      }
    }
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
      final documentBase64 =
          base64Encode(utf8.encode('Document simulé pour signature'));

      // Créer l'enveloppe DocuSign
      context.read<DocuSignBloc>().add(CreateEnvelopeEvent(
            documentBase64: documentBase64,
            signerEmail:
                'nesssim@example.com', // Utiliser une adresse email valide pour les tests
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
