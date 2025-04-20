// lib/presentation/expert_juridique/widgets/juridical_validation_form.dart

import 'dart:convert';
import 'package:flareline/core/services/docusign_service.dart';
import 'package:http/http.dart' as http;
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/geometre/widgets/land_images_gallery.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:url_launcher/url_launcher.dart';

// Nouveaux imports pour DocuSign
import 'package:flareline/core/injection/injection.dart';


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

  // Variables pour DocuSign
  final DocuSignService _docuSignService = getIt<DocuSignService>();
  String? _envelopeId;
  String? _signatureStatus;
  bool _isDocuSignReady = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si DocuSign est authentifié
    _checkDocuSignAuth();
  }

  // Vérifier l'authentification DocuSign
  Future<void> _checkDocuSignAuth() async {
    final isAuthenticated = _docuSignService.checkExistingAuth();
    setState(() {
      _isDocuSignReady = isAuthenticated;
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
      builder: (context, state) {
        return _buildForm(context, widget.land);
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
            // Section galerie d'images
            LandImagesGallery(land: land),
            const SizedBox(height: 16),

            // Section titre juridique
            _buildLegalHeader(),
            const SizedBox(height: 16),

            // Section informations du terrain
            _buildLandInfoSection(land),
            const SizedBox(height: 16),

            // Section liste des documents
            _buildDocumentListSection(land),
            const SizedBox(height: 16),

            // Section de vérifications juridiques
            _buildLegalVerificationSection(),
            const SizedBox(height: 16),

            // Section commentaires
            _buildCommentsField(land),
            const SizedBox(height: 16),
            
            // Nouvelle section DocuSign
            _buildDocuSignSection(land),
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

  Widget _buildLegalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlobalColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GlobalColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel,
                color: GlobalColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Validation juridique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'En tant qu\'expert juridique, vous êtes chargé de vérifier la conformité légale du terrain et des documents associés.',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandInfoSection(Land land) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations du terrain',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Titre
        OutBorderTextFormField(
          labelText: "Titre",
          hintText: land.title,
          enabled: false,
        ),
        const SizedBox(height: 8),
        
        // Localisation
        OutBorderTextFormField(
          labelText: "Localisation",
          hintText: land.location,
          enabled: false,
        ),
        const SizedBox(height: 8),
        
        // Surface
        OutBorderTextFormField(
          labelText: "Surface déclarée",
          hintText: "${land.surface} m²",
          enabled: false,
        ),
        const SizedBox(height: 8),
        
        // Propriétaire
        OutBorderTextFormField(
          labelText: "Adresse du propriétaire",
          hintText: land.ownerAddress,
          enabled: false,
        ),
        
        // ID Blockchain
        const SizedBox(height: 8),
        OutBorderTextFormField(
          labelText: "ID Blockchain",
          hintText: land.blockchainLandId,
          enabled: false,
        ),
      ],
    );
  }

  /// Construit la section de liste des documents
  Widget _buildDocumentListSection(Land land) {
    // Vérifier si des documents sont disponibles
    final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Documents juridiques',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Message si aucun document n'est disponible
        if (!hasDocuments)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Aucun document juridique n\'est disponible pour ce terrain.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),

        // Liste des documents
        if (hasDocuments)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // En-tête de la liste
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: GlobalColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Documents à vérifier',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                const Divider(height: 1),
                
                // Liste des documents
                ...land.documentUrls.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final String url = entry.value;
                  final fileName = url.split('/').last;
                  
                  return _buildDocumentItem(
                    context: context,
                    fileName: fileName,
                    url: url,
                    index: index,
                    totalCount: land.documentUrls.length,
                  );
                }).toList(),

                // Vérification des documents
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ValidationCheckbox(
                    value: _documentsAreValid,
                    label: "Je confirme avoir vérifié et validé tous les documents juridiques ci-dessus",
                    checkColor: GlobalColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _documentsAreValid = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentItem({
    required BuildContext context,
    required String fileName,
    required String url,
    required int index,
    required int totalCount,
  }) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: GlobalColors.primary.withOpacity(0.1),
            foregroundColor: GlobalColors.primary,
            child: Text('${index + 1}'),
          ),
          title: Text(
            fileName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: const Text('IPFS Document', style: TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewDocument(url),
                tooltip: 'Visualiser',
                color: GlobalColors.info,
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                onPressed: () => _downloadDocument(url),
                tooltip: 'Télécharger',
                color: GlobalColors.primary,
              ),
            ],
          ),
        ),
        if (index < totalCount - 1)
          const Divider(height: 1, indent: 70),
      ],
    );
  }

  void _viewDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de télécharger le document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construit la section des vérifications juridiques
  Widget _buildLegalVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Vérifications juridiques',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Confirmez les points suivants après avoir vérifié les documents juridiques',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        
        // Liste des vérifications
        _buildLegalCheckbox(
          'title_valid',
          'Les titres de propriété sont authentiques et valides',
          'Vérifiez l\'authenticité et la validité des documents de propriété',
        ),
        
        _buildLegalCheckbox(
          'no_disputes',
          'Aucun litige en cours concernant ce terrain',
          'Vérifiez l\'absence de contestations ou réclamations',
        ),
        
        _buildLegalCheckbox(
          'boundaries_valid',
          'Les limites du terrain sont correctement définies',
          'Vérifiez la conformité des délimitations cadastrales',
        ),
        
        _buildLegalCheckbox(
          'usage_rights',
          'Les droits d\'usage sont conformes à la réglementation',
          'Vérifiez les droits et restrictions d\'utilisation du terrain',
        ),
        
        // Indication du statut global
        const SizedBox(height: 16),
        _buildVerificationStatus(),
      ],
    );
  }

  Widget _buildLegalCheckbox(String key, String label, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ValidationCheckbox(
        value: _legalVerifications[key] ?? false,
        label: label,
        checkColor: GlobalColors.primary,
        onChanged: (value) {
          setState(() {
            _legalVerifications[key] = value ?? false;
            _legalVerificationsComplete = _legalVerifications.values.every((v) => v);
          });
        },
      ),
    );
  }

  Widget _buildVerificationStatus() {
    // Calculer le nombre de vérifications effectuées
    final completedCount = _legalVerifications.values.where((v) => v).length;
    final totalCount = _legalVerifications.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    // Déterminer le statut
    Color statusColor;
    String statusText;
    
    if (progress == 0) {
      statusColor = Colors.grey;
      statusText = 'Aucune vérification effectuée';
    } else if (progress < 1) {
      statusColor = GlobalColors.warn;
      statusText = 'Vérification partielle ($completedCount/$totalCount)';
    } else {
      statusColor = GlobalColors.success;
      statusText = 'Toutes les vérifications sont complètes';
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
              Icon(progress == 1 ? Icons.check_circle : Icons.info_outline, 
                  color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'État des vérifications: $statusText',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  /// Champ pour les commentaires juridiques
  Widget _buildCommentsField(Land land) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section avec bouton de génération
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Commentaires juridiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Bouton pour générer un commentaire automatique
            ElevatedButton.icon(
              onPressed: () => _generateComment(land),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Générer un commentaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),

        // Champ de texte pour les commentaires
        OutBorderTextFormField(
          controller: _commentsController,
          labelText: "Commentaires juridiques",
          hintText: "Ajoutez vos observations juridiques sur le terrain et les documents",
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

        // Suggestions pour les commentaires
        const Padding(
          padding: EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            'Suggestions: conformité des titres de propriété, absence de litiges, droits d\'usage, restrictions légales, etc.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Section DocuSign pour la signature électronique
  Widget _buildDocuSignSection(Land land) {
    // Vérifier si des documents sont disponibles
    final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

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
            Container(
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
            ),
            
          // Statut de signature si applicable
          if (_envelopeId != null)
            _buildSignatureStatus(),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          if (hasDocuments) 
            Row(
              children: [
                if (!_isDocuSignReady)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _connectToDocuSign,
                      icon: const Icon(Icons.login),
                      label: const Text('Se connecter à DocuSign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (_isDocuSignReady && _envelopeId == null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _initiateSignatureProcess(land),
                      icon: const Icon(Icons.edit_document),
                      label: const Text('Envoyer pour signature'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (_envelopeId != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshSignatureStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser le statut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _downloadSignedDocument,
                    icon: const Icon(Icons.download),
                    tooltip: 'Télécharger le document signé',
                    color: GlobalColors.primary,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // Widget pour afficher le statut de la signature
  Widget _buildSignatureStatus() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_empty;
    
    switch (_signatureStatus?.toLowerCase()) {
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
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
                'Statut de la signature: ${_signatureStatus ?? "En attente"}',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (_envelopeId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'ID de l\'enveloppe: $_envelopeId',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // Connexion à DocuSign
  void _connectToDocuSign() {
    _docuSignService.initiateAuthentication();
  }

  // Méthode pour télécharger le document du terrain et l'envoyer pour signature
Future<void> _initiateSignatureProcess(Land land) async {
  // Vérifier si des documents sont disponibles
  if (land.documentUrls.isEmpty && land.ipfsCIDs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aucun document disponible pour signature'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );
  
  try {
    // Récupérer le premier document du terrain
    final documentUrl = land.documentUrls.isNotEmpty 
        ? land.documentUrls.first 
        : 'https://ipfs.io/ipfs/${land.ipfsCIDs.first}';
    
    // Télécharger le document
    final response = await http.get(Uri.parse(documentUrl));
    if (response.statusCode != 200) {
      throw Exception('Impossible de télécharger le document');
    }
    
    // Convertir le document en base64
    final documentBytes = response.bodyBytes;
    final documentBase64 = base64Encode(documentBytes);
    
    // Email de l'expert juridique actuel (à adapter selon votre système d'authentification)
    final expertEmail = 'expert@flareline.com'; 
    
    // Créer la demande de signature via DocuSign avec un seul signataire (l'expert juridique)
    _envelopeId = await _docuSignService.createSignatureRequest(
      land: land,
      documentBase64: documentBase64,
      signerEmail: expertEmail,
      signerName: 'Expert Juridique',
      // Ne pas inclure les paramètres secondarySignerEmail et secondarySignerName
    );
    
    // Fermer l'indicateur de chargement
    Navigator.of(context).pop();
    
    if (_envelopeId != null) {
      setState(() {
        _signatureStatus = 'Envoyé';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document envoyé pour signature avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'envoi du document pour signature'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Fermer l'indicateur de chargement
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Rafraîchir le statut de la signature
  Future<void> _refreshSignatureStatus() async {
    if (_envelopeId == null) return;
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(),
        ),
      ),
    );
    
    try {
      final statusData = await _docuSignService.checkEnvelopeStatus(_envelopeId!);
      
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      
      if (statusData != null) {
        setState(() {
          final status = statusData['status'];
          switch (status) {
            case 'sent': _signatureStatus = 'Envoyé'; break;
            case 'delivered': _signatureStatus = 'Remis'; break;
            case 'completed': _signatureStatus = 'Terminé'; break;
            case 'signed': _signatureStatus = 'Signé'; break;
            case 'declined': _signatureStatus = 'Refusé'; break;
            default: _signatureStatus = status;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut de signature actualisé'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer le statut de la signature'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Télécharger le document signé
  Future<void> _downloadSignedDocument() async {
    if (_envelopeId == null) return;
    
    try {
      await _docuSignService.getSignedDocument(_envelopeId!);
      // Le téléchargement est géré par le service DocuSign
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Génère un commentaire juridique basé sur les informations du terrain
  void _generateComment(Land land) {
    // Vérifier si des documents sont disponibles
    final hasDocuments = land.documentUrls.isNotEmpty || land.ipfsCIDs.isNotEmpty;

    // Construction du commentaire complet
    final StringBuilder = StringBuffer();

    StringBuilder.writeln(
        'RAPPORT DE VALIDATION JURIDIQUE');
    StringBuilder.writeln('Terrain: "${land.title}" situé à ${land.location}');
    StringBuilder.writeln('ID Blockchain: ${land.blockchainLandId}');
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

  /// Checkbox de validation
  Widget _buildValidationCheckbox() {
    return ValidationCheckbox(
      value: _isValid,
      label: "Je confirme que les informations juridiques saisies sont correctes",
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
      if (!_legalVerifications.values.every((v) => v)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez compléter toutes les vérifications juridiques'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Si DocuSign est prêt mais que le document n'a pas été envoyé pour signature,
      // demander à l'utilisateur s'il souhaite continuer sans signature
      if (hasDocuments && _isDocuSignReady && _envelopeId == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Signature électronique'),
            content: const Text(
              'Les documents n\'ont pas encore été envoyés pour signature électronique. '
              'Voulez-vous continuer la validation sans signature électronique?'
            ),
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
        // Si pas de documents ou si DocuSign n'est pas configuré, ou si la signature a déjà été demandée
        _completeSubmission(context, land);
      }
    }
  }

  void _completeSubmission(BuildContext context, Land land) {
    // Inclure l'information sur la validation des documents et la signature dans les commentaires
    final signatureInfo = _envelopeId != null 
        ? "- Signature électronique: OUI (ID: $_envelopeId, Statut: $_signatureStatus)" 
        : "- Signature électronique: NON";
        
    final commentsWithDetails = '''
${_commentsController.text}

RÉSUMÉ DE VALIDATION:
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