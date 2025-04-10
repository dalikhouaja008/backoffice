// lib/presentation/pages/geometre/geometre_dashboard.dart
import 'package:flareline/presentation/pages/dashboard/grid_card.dart';
import 'package:flareline/presentation/pages/dashboard/stat_card.dart';
import 'package:flutter/material.dart';

class GeometreDashboard extends StatelessWidget {
  const GeometreDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridCard(
      children: [
        // Nombre total de terrains validés
        StatCard(
          icon: Icons.check_circle,
          title: "Terrains validés",
          value: "28",
          percentage: "23%",
          isGrow: true,
          color: Colors.green[300]
        ),
        // Terrains en cours de validation
        StatCard(
          icon: Icons.pending_actions,
          title: "En cours de validation",
          value: "3",
          percentage: "5%",
          isGrow: false,
          color: Colors.orange[300]  // Changé en orange pour indiquer l'état en attente
        ),
        // Temps moyen de validation (métrique importante pour l'efficacité)
        StatCard(
          icon: Icons.timer,
          title: "Temps moyen validation",
          value: "2.4j",
          percentage: "8%",
          isGrow: true,
          color: Colors.blue[300]  // Changé en bleu pour différencier
        ),
      ],
    );
  }
}