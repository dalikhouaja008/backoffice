import '../../domain/entities/validation_entity.dart';
import '../models/validation_model.dart';

class ValidationMapper {
  static ValidationEntity toEntity(ValidationModel model) {
    return ValidationEntity(
      isValidated: model.isValidated,
      comments: model.comments,
    );
  }

  static ValidationModel toModel(ValidationEntity entity) {
    return ValidationModel(
      isValidated: entity.isValidated,
      comments: entity.comments,
    );
  }

  static List<ValidationEntity> toEntityList(List<ValidationModel> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  static List<ValidationModel> toModelList(List<ValidationEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}