import 'dart:html' as html;
import 'package:flareline/core/services/clipboard_service.dart';
import 'package:flutter/material.dart';

class SignatureStatusWidget extends StatelessWidget {
  final String envelopeId;
  final String? status;
  final bool isRefreshing;

  const SignatureStatusWidget({
    super.key,
    required this.envelopeId,
    required this.status,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText = status ?? "En attente";

    switch (statusText.toLowerCase()) {
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
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du statut
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Statut de la signature: $statusText',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (isRefreshing) ...[
                  const Spacer(),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Détails de l'enveloppe
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('ID de l\'enveloppe: ',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Expanded(
                  child: Text(
                    envelopeId,
                    style:
                        const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ClipboardService.copyToClipboard(envelopeId,
                      context: context),
                  tooltip: 'Copier l\'ID',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
