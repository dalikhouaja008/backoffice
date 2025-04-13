// lib/domain/repositories/geometre_repository.dart
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_entity.dart';

abstract class GeometreRepository {

  Future<List<Land>> getPendingLands();
  
  Future<ValidationEntity> validateLand({
    required String landId,
    required ValidationEntity validation,
  });
  

}