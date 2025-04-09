import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';

class ValidateLand {
  final GeometreRepository repository;

  ValidateLand(this.repository);

  Future<Land> call({
    required String landId,
    required bool isValid,
    required String comments,
    required List<String> documents,
    required double measuredSurface,
    required DateTime visitDate,
  }) async {
    return await repository.validateLand(
      landId: landId,
      isValid: isValid,
      comments: comments,
      documents: documents,
      measuredSurface: measuredSurface,
      visitDate: visitDate,
    );
  }
}