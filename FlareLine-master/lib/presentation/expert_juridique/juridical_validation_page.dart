import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
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
    super.key,
    required this.land,
  });

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation Juridique de "${land.title}"';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExpertJuridiqueBloc>(
          create: (context) => getIt<ExpertJuridiqueBloc>(),
        ),
        BlocProvider<DocuSignBloc>(
          create: (context) => getIt<DocuSignBloc>(),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton retour
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Validation juridique du terrain',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              land.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            // Modification critique ici : Expanded pour donner une taille définie
            Expanded(
              child: SingleChildScrollView(
                // Donnez une largeur maximale pour éviter les débordements horizontaux
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width -
                        32, // Tenir compte du padding
                  ),
                  child: JuridicalValidationForm(land: land),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
