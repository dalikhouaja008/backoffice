// lib/presentation/expert_juridique/ExpertJuridiquePage.dart
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flareline/presentation/expert_juridique/widgets/LandsList.dart';
import 'package:flareline/presentation/expert_juridique/widgets/land_detail_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/presentation/pages/layout.dart';
import 'package:logger/logger.dart';

class ExpertJuridiquePage extends LayoutWidget {
  const ExpertJuridiquePage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation Juridique des Terrains';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<ExpertJuridiqueBloc>();
        bloc.add(LoadPendingLands());
        return bloc;
      },
      child: const ExpertJuridiqueContent(),
    );
  }
}

class ExpertJuridiqueContent extends StatelessWidget {
  const ExpertJuridiqueContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    final screenSize = MediaQuery.of(context).size;
    
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width,
          maxHeight: screenSize.height,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenSize.height - 120, 
                  child: BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
                    builder: (context, state) {
                      return _buildMainContent(context, state);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ExpertJuridiqueState state) {
    if (state is ExpertJuridiqueLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ExpertJuridiqueError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ExpertJuridiqueBloc>().add(LoadPendingLands());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is ExpertJuridiqueLoaded) {
      return SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Liste des Terrains',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Divider(),
                      Expanded(child: LandsList()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: SizedBox(
                child: Card(
                  child: state.selectedLand != null
                      ? LandDetailView(
                          land: state.selectedLand!,
                          onStartValidation: () {
                            getIt<Logger>().log(
                              Level.info,
                              'Starting validation process',
                              error: {
                                'landId': state.selectedLand!.id,
                                'timestamp': DateTime.now().toString(),
                                'userLogin': 'nesssim'
                              },
                            );
                          },
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gavel_outlined, // Icône juridique
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sélectionnez un terrain pour commencer la validation juridique',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('État inconnu'));
  }
}