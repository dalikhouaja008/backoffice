import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';

class CommentsField extends StatelessWidget {
  final TextEditingController controller;
  final Land land;
  final VoidCallback onGenerateComment;

  const CommentsField({
    super.key,
    required this.controller,
    required this.land,
    required this.onGenerateComment,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed: onGenerateComment,
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
          controller: controller,
          labelText: "Commentaires juridiques",
          hintText:
              "Ajoutez vos observations juridiques sur le terrain et les documents",
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
}