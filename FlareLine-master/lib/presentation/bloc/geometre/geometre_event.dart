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
  final bool isValid; // Utiliser isValid au lieu de isValidated
  final String comment; // Utiliser comment au lieu de comments

  const ValidateLand({
    required this.landId,
    required this.isValid,
    required this.comment,
  });

  @override
  List<Object> get props => [
    landId,
    isValid,
    comment,
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