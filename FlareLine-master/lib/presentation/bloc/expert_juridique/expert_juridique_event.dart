import 'package:equatable/equatable.dart';
import 'package:flareline/domain/entities/land_entity.dart';

abstract class ExpertJuridiqueEvent extends Equatable {
  const ExpertJuridiqueEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingLands extends ExpertJuridiqueEvent {}

class RefreshLands extends ExpertJuridiqueEvent {}

class SearchLands extends ExpertJuridiqueEvent {
  final String query;
  
  const SearchLands({required this.query});

  @override
  List<Object> get props => [query];
}

class SelectLand extends ExpertJuridiqueEvent {
  final Land land;
  
  const SelectLand({required this.land});

  @override
  List<Object> get props => [land];
}

class ClearSelectedLand extends ExpertJuridiqueEvent {}

class ValidateLand extends ExpertJuridiqueEvent {
  final String landId;
  final bool isValid;
  final String comment;

  const ValidateLand({
    required this.landId,
    required this.isValid,
    required this.comment,
  });

  @override
  List<Object> get props => [landId, isValid, comment];
}