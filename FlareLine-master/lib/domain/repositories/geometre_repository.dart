import 'package:flareline/domain/entities/land_entity.dart';

abstract class GeometreRepository {

  Future<List<Land>> getPendingLands();
  
  Future<Land> validateLand({
    required String landId,
    required bool isValid,
    required String comments,
    required List<String> documents,
    required double measuredSurface,
    required DateTime visitDate,
  });
  

  
}