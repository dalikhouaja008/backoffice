import 'package:flareline/presentation/pages/dashboard/grid_card.dart';
import 'package:flareline/presentation/pages/dashboard/stat_card.dart';
import 'package:flutter/material.dart';

class GeometreDashboard extends StatelessWidget {
  const GeometreDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridCard(
      children: [
        StatCard(
          icon: Icons.map,
          title: "Terrains en attente",
          value: "5",
          percentage: "12%",
          isGrow: true, 
          color: Colors.green[300]
        ),
        StatCard(
          icon: Icons.check_circle,
          title: "Validations effectuées",
          value: "28",
          percentage: "23%",
          isGrow: true,
          color: Colors.green[300]
        ),
        StatCard(
          icon: Icons.pending_actions,
          title: "En cours de validation",
          value: "3",
          percentage: "5%",
          isGrow: false,
          color: Colors.green[300]
        ),
        StatCard(
          icon: Icons.access_time,
          title: "Temps moyen validation",
          value: "2.4j",
          percentage: "8%",
          isGrow: true,
          color: Colors.green[300]
        ),
      ],
    );
  }
}