// lib/presentation/expert_juridique/widgets/legal_header.dart
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';

class LegalHeader extends StatelessWidget {
  const LegalHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
}