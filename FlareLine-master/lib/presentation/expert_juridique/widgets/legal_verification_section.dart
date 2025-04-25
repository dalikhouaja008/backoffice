// lib/presentation/expert_juridique/widgets/legal_verification_section.dart
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/presentation/pages/form/validation_checkbox.dart';

class LegalVerificationSection extends StatefulWidget {
  final Function(Map<String, bool>, bool) onVerificationsUpdated;
  
  const LegalVerificationSection({
    super.key,
    required this.onVerificationsUpdated,
  });

  @override
  State<LegalVerificationSection> createState() => _LegalVerificationSectionState();
}

class _LegalVerificationSectionState extends State<LegalVerificationSection> {
  final Map<String, bool> _legalVerifications = {
    'title_valid': false,
    'no_disputes': false,
    'boundaries_valid': false,
    'usage_rights': false,
  };

  @override
  Widget build(BuildContext context) {
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
            final bool allComplete = _legalVerifications.values.every((v) => v);
            widget.onVerificationsUpdated(_legalVerifications, allComplete);
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
}