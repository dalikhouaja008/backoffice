import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';

class MapControlButtons extends StatelessWidget {
  final VoidCallback onStartValidation;
  final VoidCallback onToggleRoute;
  final bool showRoute;
  final bool loadingRoute;

  const MapControlButtons({
    Key? key,
    required this.onStartValidation,
    required this.onToggleRoute,
    this.showRoute = false,
    this.loadingRoute = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Bouton pour commencer la validation
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartValidation,
              icon: const Icon(Icons.check_circle),
              label: const Text('Commencer la validation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Bouton pour afficher/masquer l'itinéraire
          Expanded(
            child: ElevatedButton.icon(
              onPressed: loadingRoute ? null : onToggleRoute,
              icon: loadingRoute
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(showRoute ? Icons.map : Icons.directions),
              label: Text(showRoute ? 'Masquer itinéraire' : 'Afficher itinéraire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.blue.withOpacity(0.6),
                disabledForegroundColor: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}