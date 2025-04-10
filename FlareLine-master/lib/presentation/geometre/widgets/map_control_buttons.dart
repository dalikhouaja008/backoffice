import 'package:flutter/material.dart';

class MapControlButtons extends StatelessWidget {
  final VoidCallback onStartValidation;
  final VoidCallback onToggleRoute;
  final bool showRoute;
  final bool loadingRoute;
  final bool isSmallScreen;

  const MapControlButtons({
    Key? key,
    required this.onStartValidation,
    required this.onToggleRoute,
    required this.showRoute,
    required this.loadingRoute,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ajuster les tailles en fonction de la taille d'écran
    final padding = isSmallScreen ? 8.0 : 16.0;
    final fontSize = isSmallScreen ? 13.0 : 15.0;
    final iconSize = isSmallScreen ? 18.0 : 24.0;
    final buttonHeight = isSmallScreen ? 40.0 : 50.0;
    
    // Utiliser un Row pour l'orientation paysage, sinon Column
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    final buttonsList = [
      // Bouton pour afficher/masquer l'itinéraire
      Expanded(
        flex: 1,
        child: Padding(
          padding: EdgeInsets.all(padding / 2),
          child: ElevatedButton.icon(
            onPressed: loadingRoute ? null : onToggleRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: showRoute ? Colors.blue : Colors.grey.shade200,
              foregroundColor: showRoute ? Colors.white : Colors.black,
              minimumSize: Size(0, buttonHeight),
            ),
            icon: loadingRoute
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: showRoute ? Colors.white : Colors.blue,
                    ),
                  )
                : Icon(
                    showRoute ? Icons.alt_route : Icons.directions,
                    size: iconSize,
                  ),
            label: Text(
              showRoute ? 'Masquer l\'itinéraire' : 'Afficher l\'itinéraire',
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      
      // Bouton pour commencer la validation
      Expanded(
        flex: 1,
        child: Padding(
          padding: EdgeInsets.all(padding / 2),
          child: ElevatedButton.icon(
            onPressed: onStartValidation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(0, buttonHeight),
            ),
            icon: Icon(Icons.check_circle, size: iconSize),
            label: Text(
              'Valider le terrain',
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
    
    // Retourner le layout approprié selon l'orientation
    return Container(
      padding: EdgeInsets.all(padding / 2),
      child: isPortrait
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buttonsList,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: buttonsList,
            ),
    );
  }
}