// lib/features/geometre/presentation/widgets/lands_list.dart
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flareline_uikit/components/forms/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/core/theme/global_colors.dart';


class LandsList extends StatelessWidget {
  LandsList({Key? key}) : super(key: key);

  // Données statiques pour le test
  final List<Map<String, dynamic>> _mockLands = [
    {
      'id': 'LAND001',
      'title': 'Terrain Agricole - Sousse',
      'location': 'Sousse Nord',
      'surface': 5000.0,
      'status': LandValidationStatus.PENDING_VALIDATION,
      'blockchainId': '0x1234567890abcdef',
      'lastUpdate': '2025-04-09',
    },
    {
      'id': 'LAND002',
      'title': 'Terrain Constructible - Sfax',
      'location': 'Sfax Centre',
      'surface': 2500.0,
      'status': LandValidationStatus.PARTIALLY_VALIDATED,
      'blockchainId': '0xabcdef1234567890',
      'lastUpdate': '2025-04-08',
    },
    {
      'id': 'LAND003',
      'title': 'Terrain Industrial - Tunis',
      'location': 'Zone Industrielle',
      'surface': 10000.0,
      'status': LandValidationStatus.PENDING_VALIDATION,
      'blockchainId': '0x9876543210fedcba',
      'lastUpdate': '2025-04-07',
    },
  ];

 @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeometreBloc, GeometreState>(
      builder: (context, state) {
        return CommonCard(
          child: Column(
            children: [
              SearchWidget(
                controller: TextEditingController(),
                onChanged: (value) {
                  context.read<GeometreBloc>().add(SearchLands(query: value));
                },
              ),
              const SizedBox(height: 16),
              
              if (state is GeometreLoading)
                const Center(child: CircularProgressIndicator())
              else if (state is GeometreError)
                Center(child: Text(state.message))
              else if (state is GeometreLoaded)
                Expanded(
                  child: _buildLandsList(state.lands),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandsList(List<Land> lands) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: lands.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final land = lands[index];
        return ListTile(
          leading: const Icon(Icons.landscape),
          title: Text(land.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(land.location),
              Text('Surface: ${land.surface} m²'),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(_getStatusText(land.status)),
                backgroundColor: _getStatusColor(land.status),
              ),
              Text('ID: ${land.blockchainLandId.substring(0, 8)}...'),
            ],
          ),
          onTap: () {
            context.read<GeometreBloc>().add(SelectLand(land: land));
          },
        );
      },
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
      default:
        return 'Inconnu';
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
      default:
        return Colors.grey;
    }
  }
}