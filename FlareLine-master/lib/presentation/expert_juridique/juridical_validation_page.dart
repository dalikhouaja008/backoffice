// lib/presentation/expert_juridique/juridical_validation_page.dart
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/expert_juridique/widgets/juridical_validation_form.dart';
import 'package:flareline/presentation/pages/layout.dart';

class JuridicalValidationPage extends LayoutWidget {
  final Land land;

  const JuridicalValidationPage({
    Key? key,
    required this.land,
  }) : super(key: key);

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation Juridique de "${land.title}"';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return BlocProvider<ExpertJuridiqueBloc>(
      create: (context) => getIt<ExpertJuridiqueBloc>(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la page
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Validation juridique du terrain',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Text(
                land.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 32),
            
            // Formulaire de validation
            Expanded(
              child: SingleChildScrollView(
                child: JuridicalValidationForm(land: land),
              ),
            ),
          ],
        ),
      ),
    );
  }
}