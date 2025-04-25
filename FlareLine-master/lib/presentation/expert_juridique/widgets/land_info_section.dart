import 'package:flutter/material.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';

class LandInfoSection extends StatelessWidget {
  final Land land;

  const LandInfoSection({
    super.key,
    required this.land,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations du terrain',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Titre
        OutBorderTextFormField(
          labelText: "Titre",
          hintText: land.title,
          enabled: false,
        ),
        const SizedBox(height: 8),

        // Localisation
        OutBorderTextFormField(
          labelText: "Localisation",
          hintText: land.location,
          enabled: false,
        ),
        const SizedBox(height: 8),

        // Surface
        OutBorderTextFormField(
          labelText: "Surface déclarée",
          hintText: "${land.surface} m²",
          enabled: false,
        ),
        const SizedBox(height: 8),

        // Propriétaire
        OutBorderTextFormField(
          labelText: "Adresse du propriétaire",
          hintText: land.ownerAddress,
          enabled: false,
        ),

        // ID Blockchain
        const SizedBox(height: 8),
        OutBorderTextFormField(
          labelText: "ID Blockchain",
          hintText: land.blockchainLandId,
          enabled: false,
        ),
      ],
    );
  }
}