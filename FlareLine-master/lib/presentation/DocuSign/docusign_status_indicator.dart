import 'package:flutter/material.dart';

class DocuSignStatusIndicator extends StatelessWidget {
  final bool isConnecting;
  final bool isDocuSignReady;
  
  const DocuSignStatusIndicator({
    super.key,
    required this.isConnecting,
    required this.isDocuSignReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDocuSignReady ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDocuSignReady ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            )
          else
            Icon(
              isDocuSignReady ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: isDocuSignReady ? Colors.green : Colors.grey,
            ),
          const SizedBox(width: 8),
          Text(
            isConnecting
                ? 'Vérification...'
                : (isDocuSignReady ? 'Connecté à DocuSign' : 'Non connecté à DocuSign'),
            style: TextStyle(
              color: isDocuSignReady ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}