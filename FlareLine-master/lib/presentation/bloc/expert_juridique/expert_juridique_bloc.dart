
import 'package:flareline/domain/use_cases/expert_juridique/get_pending_lands.dart';
import 'package:flareline/domain/use_cases/expert_juridique/validate_land.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_event.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class ExpertJuridiqueBloc extends Bloc<ExpertJuridiqueEvent, ExpertJuridiqueState> {
  final GetPendingLandsExpertJuridique getPendingLands;
  final ValidateLandUseCaseExpertJuridique validateLand;
  final Logger logger;

  ExpertJuridiqueBloc({
    required this.getPendingLands,
    required this.validateLand,
    required this.logger,
  }) : super(ExpertJuridiqueInitial()) {
    on<LoadPendingLands>(_onLoadPendingLands);
    on<RefreshLands>(_onRefreshLands);
    on<SearchLands>(_onSearchLands);
    on<SelectLand>(_onSelectLand);
    on<ClearSelectedLand>(_onClearSelectedLand);
    on<ValidateLand>(_onValidateLand);
  }

  Future<void> _onLoadPendingLands(
    LoadPendingLands event,
    Emitter<ExpertJuridiqueState> emit,
  ) async {
    try {
      emit(ExpertJuridiqueLoading());

      // Log de début
      logger.log(
        Level.info,
        'Chargement des terrains en attente de validation de l\'expert juridique',
      );

      final lands = await getPendingLands();

      // Log de succès
      logger.log(
        Level.info,
        ' ${lands.length} terrains chargés avec succès',
        error: {'count': lands.length, },
      );

      emit(ExpertJuridiqueLoaded(lands: lands));
    } catch (e) {
      // Log d'erreur détaillé
      logger.log(
        Level.error,
        'Erreur lors du chargement des terrains',
        error: {'error': e.toString(), 'userLogin': 'nesssim'},
      );

      emit(ExpertJuridiqueError(
          message: 'Erreur lors du chargement des terrains: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLands(
    RefreshLands event,
    Emitter<ExpertJuridiqueState> emit,
  ) async {
    if (state is ExpertJuridiqueLoaded) {
      final currentState = state as ExpertJuridiqueLoaded;
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
    Emitter<ExpertJuridiqueState> emit,
  ) async {
    if (state is ExpertJuridiqueLoaded) {
      final currentState = state as ExpertJuridiqueLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  void _onSelectLand(SelectLand event, Emitter<ExpertJuridiqueState> emit) {
    if (state is ExpertJuridiqueLoaded) {
      final currentState = state as ExpertJuridiqueLoaded;

      logger.log(
        Level.info,
        'Land selected in bloc',
        error: {
          'landId': event.land.id,
        },
      );

      emit(ExpertJuridiqueLoaded(
        lands: currentState.lands,
        selectedLand: event.land,
      ));
    }
  }

  void _onClearSelectedLand(
    ClearSelectedLand event,
    Emitter<ExpertJuridiqueState> emit,
  ) {
    if (state is ExpertJuridiqueLoaded) {
      final currentState = state as ExpertJuridiqueLoaded;
      emit(currentState.copyWith(selectedLand: null));
    }
  }

  Future<void> _onValidateLand(
    ValidateLand event,
    Emitter<ExpertJuridiqueState> emit,
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

      if (state is ExpertJuridiqueLoaded) {
        // Rafraîchir la liste des terrains après validation
        add(LoadPendingLands());
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