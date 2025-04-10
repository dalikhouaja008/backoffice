import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';

class ValidateLandUseCase {
  final GeometreRepository repository;

  ValidateLandUseCase({required this.repository});

  Future<ValidationEntity> call({
    required String landId,
    required bool isValidated,
    String? comments,
  }) {
    return repository.validateLand(
      landId: landId,
      validation: ValidationEntity(
        isValidated: isValidated,
        comments: comments,
      ),
    );
  }
}