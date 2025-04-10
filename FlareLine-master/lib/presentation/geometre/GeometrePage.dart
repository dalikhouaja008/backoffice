import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline/presentation/geometre/land_map_view.dart';
import 'package:flareline/presentation/geometre/LandsList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/presentation/pages/layout.dart';
import 'package:logger/logger.dart';

class GeometrePage extends LayoutWidget {
  const GeometrePage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation des Terrains';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<GeometreBloc>();
        bloc.add(LoadPendingLands());
        return bloc;
      },
      child: const GeometreContent(),
    );
  }

}

class GeometreContent extends StatelessWidget {
  const GeometreContent({super.key});

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
                  child: BlocBuilder<GeometreBloc, GeometreState>(
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

  Widget _buildMainContent(BuildContext context, GeometreState state) {
    if (state is GeometreLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is GeometreError) {
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
                context.read<GeometreBloc>().add(LoadPendingLands());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is GeometreLoaded) {
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
                      ? LandMapView(
                          land: state.selectedLand!,
                          onStartValidation: () {
                            getIt<Logger>().log(
                              Level.info,
                              'Starting validation process',
                              error: {
                                'landId': state.selectedLand!.id,
                                'timestamp': '2025-04-10 20:27:09',
                                'userLogin': 'dalikhouaja008'
                              },
                            );
                          },
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('État inconnu'));
  }

}