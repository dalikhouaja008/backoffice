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

      // Log de début
      logger.log(
        Level.info,
        'Chargement des terrains en attente de validation du géomètre',

      );

      final lands = await getPendingLands();

      // Log de succès
      logger.log(
        Level.info,
        ' ${lands.length} terrains chargés avec succès',
        error: {'count': lands.length, },
      );

      emit(GeometreLoaded(lands: lands));
    } catch (e) {
      // Log d'erreur détaillé
      logger.log(
        Level.error,
        '[2025-04-13 19:52:08] Erreur lors du chargement des terrains',
        error: {'error': e.toString(), 'userLogin': 'nesssim'},
      );

      emit(GeometreError(
          message: 'Erreur lors du chargement des terrains: ${e.toString()}'));
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
      comments: event.comment, 
    );

    logger.log(
      Level.info,
      'Land validation successful',
      error: {
        'landId': event.landId,
        'timestamp': DateTime.now().toString(),
        'userLogin': 'nesssim',
      },
    );

    if (state is GeometreLoaded) {
      // Suite du code...
    }
  } catch (e) {
    logger.log(
      Level.error,
      'Error validating land',
      error: {
        'landId': event.landId,
        'error': e.toString(),
      },
    );

    emit(ValidationFailure(
      message: 'Erreur lors de la validation: ${e.toString()}',
      landId: event.landId,
    ));
  }
}
}
