import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/enums/validation_enums.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flareline/presentation/geometre/widgets/land_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:logger/logger.dart';

class LandsList extends StatelessWidget {
  LandsList({super.key});

  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpertJuridiqueBloc, ExpertJuridiqueState>(
      builder: (context, state) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Terrains en attente de validation juridique',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _buildContent(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpertJuridiqueState state) {
    if (state is ExpertJuridiqueLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des terrains...'),
          ],
        ),
      );
    }

    if (state is ExpertJuridiqueError) {
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
                context.read<ExpertJuridiqueBloc>().add(LoadPendingLands());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is ExpertJuridiqueLoaded) {
      if (state.lands.isEmpty) {
        return const Center(
          child: Text('Aucun terrain en attente de validation juridique'),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.lands.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final land = state.lands[index];
          final isSelected = state.selectedLand?.id == land.id;

          return _buildLandItem(context, land, isSelected);
        },
      );
    }

    return const Center(
      child: Text('Chargez la liste des terrains'),
    );
  }

 Widget _buildLandItem(BuildContext context, Land land, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<ExpertJuridiqueBloc>().add(SelectLand(land: land));

          getIt<Logger>().log(
            Level.info,
            'Land item tapped',
            error: {
              'landId': land.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? GlobalColors.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? GlobalColors.primary
                  : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du terrain ou icône par défaut
              Container(
                width: 80,
                height: 80,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: land.coverImageUrl != null || (land.imageUrls.isNotEmpty)
                    ? LandImage(
                        imageUrl: land.coverImageUrl ?? land.imageUrls.first,
                        width: 80,
                        height: 80,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: GlobalColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.gavel, // Icône juridique
                          color: GlobalColors.primary,
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      land.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      land.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surface: ${land.surface} m²',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Status et ID
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(land.status),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${land.blockchainLandId.length > 8 ? "${land.blockchainLandId.substring(0, 8)}..." : land.blockchainLandId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(LandValidationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getStatusText(LandValidationStatus status) {
    switch (status) {
      case LandValidationStatus.PENDING_VALIDATION:
        return 'En attente';
      case LandValidationStatus.PARTIALLY_VALIDATED:
        return 'Partiel';
      case LandValidationStatus.VALIDATED:
        return 'Validé';
      case LandValidationStatus.REJECTED:
        return 'Rejeté';
      case LandValidationStatus.TOKENIZED:
        return 'Tokenisé';
    }
  }

  Color _getStatusColor(LandValidationStatus status) {
    switch (status) {
      case LandValidationStatus.PENDING_VALIDATION:
        return GlobalColors.warn;
      case LandValidationStatus.PARTIALLY_VALIDATED:
        return GlobalColors.info;
      case LandValidationStatus.VALIDATED:
        return GlobalColors.success;
      case LandValidationStatus.REJECTED:
        return GlobalColors.danger;
      case LandValidationStatus.TOKENIZED:
        return GlobalColors.primary;
    }
  }
}