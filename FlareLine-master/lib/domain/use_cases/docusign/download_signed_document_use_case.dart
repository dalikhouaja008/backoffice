import 'package:flareline/domain/repositories/docusign_repository.dart';

class DownloadSignedDocumentUseCase {
  final DocuSignRepository repository;

  DownloadSignedDocumentUseCase({required this.repository});

  Future<List<int>> call(String envelopeId) async {
    return await repository.downloadSignedDocument(envelopeId);
  }
}