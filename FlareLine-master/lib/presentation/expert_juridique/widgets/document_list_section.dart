import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';

class DocumentListSection extends StatefulWidget {
  final Land land;
  final Function(bool) onDocumentsValidated;

  const DocumentListSection({
    super.key,
    required this.land,
    required this.onDocumentsValidated,
  });

  @override
  State<DocumentListSection> createState() => _DocumentListSectionState();
}

class _DocumentListSectionState extends State<DocumentListSection> {
  bool _documentsAreValid = false;

  @override
  Widget build(BuildContext context) {
    // Vérifier si des documents sont disponibles
    final hasDocuments =
        widget.land.documentUrls.isNotEmpty || widget.land.ipfsCIDs.isNotEmpty;

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
          _buildDocumentsList(),
      ],
    );
  }

  Widget _buildDocumentsList() {
    return Container(
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
          ...widget.land.documentUrls.asMap().entries.map((entry) {
            final int index = entry.key;
            final String url = entry.value;
            final fileName = url.split('/').last;

            return _buildDocumentItem(
              context: context,
              fileName: fileName,
              url: url,
              index: index,
              totalCount: widget.land.documentUrls.length,
            );
          }).toList(),

          // Vérification des documents
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValidationCheckbox(
              value: _documentsAreValid,
              label:
                  "Je confirme avoir vérifié et validé tous les documents juridiques ci-dessus",
              checkColor: GlobalColors.primary,
              onChanged: (value) {
                setState(() {
                  _documentsAreValid = value ?? false;
                  widget.onDocumentsValidated(_documentsAreValid);
                });
              },
            ),
          ),
        ],
      ),
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
        if (index < totalCount - 1) const Divider(height: 1, indent: 70),
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
}