// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:flareline/domain/entities/land_entity.dart';


abstract class GeometreEvent extends Equatable {
  const GeometreEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingLands extends GeometreEvent {}

class RefreshLands extends GeometreEvent {}

class SearchLands extends GeometreEvent {
  final String query;
  
  const SearchLands({required this.query});

  @override
  List<Object> get props => [query];
}

class SelectLand extends GeometreEvent {
  final Land land;
  
  const SelectLand({required this.land});

  @override
  List<Object> get props => [land];
}

class ClearSelectedLand extends GeometreEvent {}

class ValidateLand extends GeometreEvent {
  final String landId;
  final bool isValid;
  final String comments;
  final List<String> documents;
  final double measuredSurface;
  final DateTime visitDate;

  const ValidateLand({
    required this.landId,
    required this.isValid,
    required this.comments,
    required this.documents,
    required this.measuredSurface,
    required this.visitDate,
  });

  @override
  List<Object> get props => [
    landId,
    isValid,
    comments,
    documents,
    measuredSurface,
    visitDate,
  ];
}

class UploadValidationDocument extends GeometreEvent {
  final String landId;
  final List<String> files;

  const UploadValidationDocument({
    required this.landId,
    required this.files,
  });

  @override
  List<Object> get props => [landId, files];
}