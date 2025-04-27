import 'package:flutter/material.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/core/theme/global_colors.dart';

class SimpleJuridicalForm extends StatelessWidget {
  final Land land;

  const SimpleJuridicalForm({
    super.key,
    required this.land,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations du terrain',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Titre: ${land.title}'),
                const SizedBox(height: 8),
                Text('Surface: ${land.surface} m²'),
                const SizedBox(height: 8),
                Text('Localisation: ${land.location}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Validation juridique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Titres de propriété vérifiés'),
                  value: false,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Absence de litiges confirmée'),
                  value: false,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Limites cadastrales validées'),
                  value: false,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {},
                    child: const Text('Valider le terrain'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}