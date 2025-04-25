import 'package:flareline/domain/entities/docusign_entity.dart';

abstract class DocuSignRepository {
  Future<bool> isAuthenticated();
  Future<bool> initiateAuthentication();
  Future<DocuSignEntity> createEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
  });
  Future<String> getSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    required String returnUrl,
  });
  Future<DocuSignEntity> checkEnvelopeStatus(String envelopeId);
  Future<List<int>> downloadSignedDocument(String envelopeId);
  Future<List<DocuSignEntity>> getSignatureHistory();
}