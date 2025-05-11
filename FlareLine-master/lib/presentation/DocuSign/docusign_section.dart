import 'dart:math';

import 'package:flareline/core/services/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:http/http.dart' as http;
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
  // Remplacer DocuSignService par DocuSignRemoteDataSource
  final DocuSignRemoteDataSource _docuSignDataSource =
      getIt<DocuSignRemoteDataSource>();
  final SecureStorageService _secureStorage = getIt<SecureStorageService>();

  @override
  void initState() {
    super.initState();

    // Configurer l'écouteur de messages pour les tokens DocuSign
    _setupMessageListener();

    // Vérifier l'authentification existante de façon asynchrone
    _checkExistingAuth();
  }

  // Méthode séparée pour vérifier l'authentification existante
  void _checkExistingAuth() {
    // Utiliser then() au lieu de await pour gérer le résultat asynchrone
    _docuSignDataSource.isAuthenticated().then((isAuthenticated) {
      if (isAuthenticated && mounted) {
        // Utiliser cette technique pour reporter l'exécution après la construction
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDocuSignStatusChanged(true);
        });
      }
    });
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
            final jwt = data['jwt'];
            final expiresIn = data['expiresIn'];
            final accountId = data['accountId'];
            final expiry = data['expiry'];

            if (token != null && token is String) {
              _logger.i('🔑 Token DocuSign et JWT reçus via postMessage');

              // Traiter et stocker les tokens reçus
              _docuSignDataSource.processReceivedToken(token, jwt,
                  accountId: accountId?.toString(),
                  expiresIn: expiresIn,
                  expiryValue: expiry?.toString());

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

  // Méthode pour gérer l'authentification DocuSign
  void _initiateDocuSignAuth() {
    // Notifier le bloc pour commencer le processus d'authentification
    context.read<DocuSignBloc>().add(InitiateDocuSignAuthenticationEvent());

    // Utiliser la méthode de DocuSignRemoteDataSource au lieu de DocuSignService
    _docuSignDataSource.initiateAuthentication();

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
      _docuSignDataSource.isAuthenticated().then((isAuthenticated) {
        if (isAuthenticated && !widget.isDocuSignReady && mounted) {
          setState(() {
            widget.onDocuSignStatusChanged(true);
          });
        }
      });
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
    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chargement du document en cours...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Récupérer l'URL du premier document
    final documentUrl = widget.land.documentUrls.first;
    
    _logger.i('📄 URL du document: $documentUrl');
    
    // MODIFICATION: Détecter si c'est un fichier IPFS
    final isIpfsUrl = documentUrl.contains('ipfs') || documentUrl.contains('Qm');
    
    // Pour les URL IPFS, on ne peut pas vérifier l'extension, donc on les accepte conditionnellement
    if (!isIpfsUrl) {
      // Uniquement pour les URLs non-IPFS, vérifier l'extension
      final extension = documentUrl.split('.').last.toLowerCase();
      if (!['pdf', 'doc', 'docx', 'txt'].contains(extension)) {
        _logger.e('📄 Format de document non pris en charge: $extension');
        throw Exception('Format de document non pris en charge: $extension. Utilisez PDF, DOC, DOCX ou TXT.');
      }
    }
    
    // Télécharger le document depuis l'URL
    final response = await http.get(Uri.parse(documentUrl));
    
    if (response.statusCode != 200) {
      throw Exception('Échec du téléchargement du document: ${response.statusCode}');
    }
    
    // IMPORTANT: Vérifier le type de contenu
    final contentType = response.headers['content-type'];
    _logger.i('📄 Type de contenu: $contentType');
    
    // Pour les documents IPFS, nous devons déterminer le type en fonction du contenu
    String documentType = 'pdf';  // Par défaut on suppose que c'est un PDF
    
    if (isIpfsUrl) {
      _logger.i('📄 Document IPFS détecté, détermination du type...');
      
      // Vérifier quelques signatures communes pour déterminer le type
      final bytes = response.bodyBytes;
      if (bytes.length > 4) {
        // Signature PDF: '%PDF'
        if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
          documentType = 'pdf';
          _logger.i('📄 Signature PDF détectée');
        } 
        // Signature DOCX/ZIP: 'PK'
        else if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
          documentType = 'docx';
          _logger.i('📄 Signature DOCX/ZIP détectée');
        }
        // Pour d'autres types, on pourrait ajouter plus de vérifications
        else {
          // Si on ne peut pas déterminer, on suppose que c'est un PDF
          _logger.w('📄 Type de document inconnu, traitement par défaut comme PDF');
        }
      }
      
      _logger.i('📄 Type de document IPFS déterminé: $documentType');
    }
    
    // Convertir le document en base64
    final documentBase64 = base64Encode(response.bodyBytes);
    
    // IMPORTANT: Vérifier que le document est valide
    _logger.i('📄 Taille du document en octets: ${response.bodyBytes.length}');
    _logger.i('📄 Taille du document en Base64: ${documentBase64.length}');
    
    // Vérifier que nous n'ajoutons pas de caractères indésirables
    if (documentBase64.contains(' ') || 
        documentBase64.contains('\n') || 
        documentBase64.contains('\r') || 
        documentBase64.contains('\t')) {
      _logger.e('📄 Le Base64 contient des caractères indésirables, nettoyage nécessaire');
      
      // Nettoyer le Base64
      final cleanBase64 = documentBase64
          .replaceAll(RegExp(r'\s+'), '')  // Supprimer les espaces, sauts de ligne
          .replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');  // Garder uniquement les caractères Base64 valides
      
      _logger.i('📄 Base64 nettoyé, nouvelle taille: ${cleanBase64.length}');
      
      // Utiliser la version nettoyée
      context.read<DocuSignBloc>().add(CreateEnvelopeEvent(
        documentBase64: cleanBase64,
        documentName: isIpfsUrl ? 'document.$documentType' : null, // Ajouter le nom avec extension pour IPFS
        documentType: documentType, // Ajouter le type détecté
        signerEmail: 'mohamedali.khouaja@esprit.tn',
        signerName: 'Nessim',
        title: 'Validation juridique - ${widget.land.title}',
      ));
    } else {
      // Utiliser directement le Base64
      context.read<DocuSignBloc>().add(CreateEnvelopeEvent(
        documentBase64: documentBase64,
        documentName: isIpfsUrl ? 'document.$documentType' : null, // Ajouter le nom avec extension pour IPFS
        documentType: documentType, 
        signerEmail: 'mohamedali.khouaja@esprit.tn',
        signerName: 'Nessim',
        title: 'Validation juridique - ${widget.land.title}',
      ));
    }
  } catch (e) {
    _logger.e('❌ Erreur lors de la préparation du document: $e');
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
