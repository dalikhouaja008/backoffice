import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/geometre/land_map_view.dart';
import 'package:flareline/presentation/geometre/LandsList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';

import 'package:logger/logger.dart';

class GeometrePage extends StatelessWidget {
  const GeometrePage({super.key});

  @override
  Widget build(BuildContext context) {
    getIt<Logger>().log(
      Level.info,
      'Building GeometrePage',
    );

    return BlocProvider(
      create: (context) {
        final bloc = getIt<GeometreBloc>();
        bloc.add(LoadPendingLands());
        return bloc;
      },
      child: const GeometrePageContent(),
    );
  }
}

class GeometrePageContent extends StatelessWidget {
  const GeometrePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    getIt<Logger>().log(
      Level.info,
      'Building GeometrePageContent',
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<GeometreBloc, GeometreState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildContent(context, state),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.map_outlined,
          size: 32,
          color: GlobalColors.primary,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation des Terrains',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Text(
              'Sélectionnez un terrain pour commencer la validation',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, GeometreState state) {
    if (state is GeometreLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading lands...'),
          ],
        ),
      );
    }

    if (state is GeometreError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<GeometreBloc>().add(LoadPendingLands());
              },
              child: const Text('Try again...'),
            ),
          ],
        ),
      );
    }

    if (state is GeometreLoaded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
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
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Card(
              child: state.selectedLand != null
                  ? Column(
                      children: [
                        // Carte agrandie (85% de l'espace)
                        Expanded(
                          flex: 85,
                          child: LandMapView(
                            land: state.selectedLand!,
                            onStartValidation: () {
                              getIt<Logger>().log(
                                Level.info,
                                'Starting validation process',
                                error: {
                                  'landId': state.selectedLand!.id,
                                  'timestamp': '2025-04-10 19:32:00',
                                  'userLogin': 'dalikhouaja008'
                                },
                              );
                              // TODO: Implémenter la navigation vers le formulaire de validation
                            },
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sélectionnez un terrain pour voir sa localisation',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text('État inconnu'),
    );
  }
}
