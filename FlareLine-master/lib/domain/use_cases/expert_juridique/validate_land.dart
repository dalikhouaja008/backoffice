import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/domain/repositories/expert_juridique_repository.dart';

class ValidateLandUseCaseExpertJuridique {
  final ExpertJuridiqueRepository repository;

  ValidateLandUseCaseExpertJuridique({required this.repository});

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