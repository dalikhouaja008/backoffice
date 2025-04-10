import 'package:flareline/domain/use_cases/geometre/get_pending_lands.dart';
import 'package:flareline/domain/use_cases/geometre/validate_land.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_event.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class GeometreBloc extends Bloc<GeometreEvent, GeometreState> {
  final GetPendingLands getPendingLands;
  final ValidateLandUseCase validateLand;
  final Logger logger;

  GeometreBloc({
    required this.getPendingLands,
    required this.validateLand,
    required this.logger,
  }) : super(GeometreInitial()) {
    on<LoadPendingLands>(_onLoadPendingLands);
    on<RefreshLands>(_onRefreshLands);
    on<SearchLands>(_onSearchLands);
    on<SelectLand>(_onSelectLand);
    on<ClearSelectedLand>(_onClearSelectedLand);
    on<ValidateLand>(_onValidateLand);
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

 void _onSelectLand(SelectLand event, Emitter<GeometreState> emit) {
    if (state is GeometreLoaded) {
      final currentState = state as GeometreLoaded;
      
      logger.log(
        Level.info,
        'Land selected in bloc',
        error: {
          'landId': event.land.id,
        },
      );

      emit(GeometreLoaded(
        lands: currentState.lands,
        selectedLand: event.land,
      ));
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

 Future<void> _onValidateLand(
    ValidateLand event,
    Emitter<GeometreState> emit,
  ) async {
    try {
      emit(ValidationInProgress(landId: event.landId));

      final validation = await validateLand.call(
        landId: event.landId,
        isValidated: event.isValid,
        comments: event.comments,
      );

      logger.log(
        Level.info,
        'Land validation successful',
        error: {
          'landId': event.landId,
          'timestamp': '2025-04-09 21:06:25',
          'userLogin': 'dalikhouaja008'
        },
      );

      if (state is GeometreLoaded) {
        final currentState = state as GeometreLoaded;
        if (currentState.selectedLand != null) {
          final updatedLand = currentState.selectedLand!.copyWith(
            validations: [...currentState.selectedLand!.validations, validation],
          );

          emit(ValidationSuccess(
            land: updatedLand,
            message: 'Validation effectuée avec succès',
          ));

          add(RefreshLands());
        }
      }
    } catch (e) {
      logger.log(
        Level.error,
        'Error validating land',
        error: {
          'landId': event.landId,
          'timestamp': '2025-04-09 21:06:25',
          'userLogin': 'dalikhouaja008'
        },
      );

      emit(ValidationFailure(
        message: 'Erreur lors de la validation',
        landId: event.landId,
      ));
    }
  }
}
