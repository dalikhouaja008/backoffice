// lib/features/geometre/presentation/bloc/geometre_bloc.dart
import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flareline/domain/use_cases/geometre/get_pending_lands.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class GeometreBloc extends Bloc<GeometreEvent, GeometreState> {
  final GetPendingLands getPendingLands;
  final ValidateLand validateLand;
  final UploadValidationDocument uploadDocument;
  final Logger logger;

  GeometreBloc({
    required this.getPendingLands,
    required this.validateLand,
    required this.uploadDocument,
    required this.logger,
  }) : super(GeometreInitial()) {
    on<LoadPendingLands>(_onLoadPendingLands);
    on<RefreshLands>(_onRefreshLands);
    on<SearchLands>(_onSearchLands);
    on<SelectLand>(_onSelectLand);
    on<ClearSelectedLand>(_onClearSelectedLand);
    //on<ValidateLand>(_onValidateLand);
  }

  Future<void> _onLoadPendingLands(
    LoadPendingLands event,
    Emitter<GeometreState> emit,
  ) async {
    try {
      emit(GeometreLoading());
      final lands = await getPendingLands();
      emit(GeometreLoaded(lands: lands));

      logger.log(
        Level.info,
        'Lands loaded successfully',
        error: {
          'count': lands.length,
          'timestamp': DateTime.now().toIso8601String(),
          'userLogin': 'dalikhouaja008'
        },
      );
    } catch (e) {
      logger.log(
        Level.error,
        'Error loading lands',
        error: {
          'timestamp': DateTime.now().toIso8601String(),
          'userLogin': 'dalikhouaja008'
        },
      );
      emit(GeometreError(message: 'Erreur lors du chargement des terrains'));
    }
  }

  Future<void> _onRefreshLands(
    RefreshLands event,
    Emitter<GeometreState> emit,
  ) async {
    if (state is GeometreLoaded) {
      final currentState = state as GeometreLoaded;
      try {
        final lands = await getPendingLands();
        emit(currentState.copyWith(lands: lands));
      } catch (e) {
        emit(currentState.copyWith(
            errorMessage: 'Erreur lors du rafraîchissement'));
      }
    }
  }

  Future<void> _onSearchLands(
    SearchLands event,
    Emitter<GeometreState> emit,
  ) async {
    if (state is GeometreLoaded) {
      final currentState = state as GeometreLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  void _onSelectLand(
    SelectLand event,
    Emitter<GeometreState> emit,
  ) {
    if (state is GeometreLoaded) {
      final currentState = state as GeometreLoaded;
      emit(currentState.copyWith(selectedLand: event.land));
    }
  }

  void _onClearSelectedLand(
    ClearSelectedLand event,
    Emitter<GeometreState> emit,
  ) {
    if (state is GeometreLoaded) {
      final currentState = state as GeometreLoaded;
      emit(currentState.copyWith(selectedLand: null));
    }
  }

  /*Future<void> _onValidateLand(
    ValidateLand event,
    Emitter<GeometreState> emit,
  ) async {
    try {
      emit(ValidationInProgress(landId: event.landId));

      final result = await validateLand(
        ValidateLandParams(
          id: event.id,
          isValid: event.isValid,
          comments: event.comments,
          documents: event.documents,
          measuredSurface: event.measuredSurface,
          visitDate: event.visitDate,
        ),
      );

      logger.log(
        Level.info, // Utilisez un niveau valide ici
        'Land validation successful',
        error: {
          'landId': event.landId,
          'isValid': event.isValid,
          'timestamp': '2025-04-06 20:40:33',
          'userLogin': 'dalikhouaja008'
        },
      );

      emit(ValidationSuccess(
        land: result,
        message: 'Validation effectuée avec succès',
      ));

      add(RefreshLands());
    } catch (e) {
      logger.log(
        Level.error,
        'Error validating land',
        error: {
          'landId': event.landId,
          'timestamp': DateTime.now().toIso8601String(),
          'userLogin': 'dalikhouaja008'
        },
      );

      emit(ValidationFailure(
        message: 'Erreur lors de la validation',
        landId: event.landId,
      ));
    }
  }*/
}

class ValidateLandParams {
  final String id;
  final bool isValid;
  final String? comments;
  final List<String> documents;
  final double? measuredSurface;
  final DateTime visitDate;

  ValidateLandParams({
    required this.id,
    required this.isValid,
    this.comments,
    required this.documents,
    this.measuredSurface,
    required this.visitDate,
  });
}
