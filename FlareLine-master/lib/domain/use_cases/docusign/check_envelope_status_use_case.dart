import 'package:flareline/domain/entities/docusign_entity.dart';
import 'package:flareline/domain/repositories/docusign_repository.dart';

class CheckEnvelopeStatusUseCase {
  final DocuSignRepository repository;

  CheckEnvelopeStatusUseCase({required this.repository});

  Future<DocuSignEntity> call(String envelopeId) async {
    return await repository.checkEnvelopeStatus(envelopeId);
  }
}