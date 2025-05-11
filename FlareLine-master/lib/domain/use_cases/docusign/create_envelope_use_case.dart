import 'package:flareline/domain/entities/docusign_entity.dart';
import 'package:flareline/domain/repositories/docusign_repository.dart';

class CreateEnvelopeUseCase {
  final DocuSignRepository repository;

  CreateEnvelopeUseCase(this.repository);

  Future<DocuSignEntity> call({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
    String? documentName,
    String? documentType,
  }) async {
    return await repository.createEnvelope(
      documentBase64: documentBase64,
      signerEmail: signerEmail,
      signerName: signerName,
      title: title,
      documentName: documentName,
      documentType: documentType,
    );
  }
}