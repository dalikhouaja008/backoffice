import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';

class DocuSignHelpDialog extends StatelessWidget {
  const DocuSignHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: GlobalColors.primary),
          const SizedBox(width: 8),
          const Text('Comment fonctionne la signature électronique'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpStep(
              1,
              'Connexion à DocuSign',
              'Connectez-vous à votre compte DocuSign ou créez-en un nouveau si nécessaire.',
            ),
            _buildHelpStep(
              2,
              'Préparation du document',
              'Le système prépare automatiquement les documents juridiques pour la signature.',
            ),
            _buildHelpStep(
              3,
              'Signature du document',
              'Signez électroniquement le document dans la fenêtre qui s\'ouvrira.',
            ),
            _buildHelpStep(
              4,
              'Confirmation',
              'Une fois signé, le document est archivé et légalement valide.',
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Les signatures électroniques via DocuSign sont légalement reconnues et conformes aux lois en vigueur.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compris'),
        ),
      ],
    );
  }
  
  Widget _buildHelpStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlobalColors.primary,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}