import 'package:flareline/domain/entities/docusign_entity.dart';

abstract class DocuSignRepository {
  Future<bool> isAuthenticated();
  Future<bool> initiateAuthentication();
  
  // Modification pour accepter documentName et documentType
  Future<DocuSignEntity> createEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
    String? documentName,
    String? documentType,
  });
  
  // Rendu returnUrl optionnel pour plus de flexibilité
  Future<String> getSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    String? returnUrl,
  });
  
  Future<DocuSignEntity> checkEnvelopeStatus(String envelopeId);
  Future<List<int>> downloadSignedDocument(String envelopeId);
  Future<List<DocuSignEntity>> getSignatureHistory();
  
  // Méthodes pour remplacer DocuSignService
  Future<void> updateToken(String token, {int? expiresIn});
  Future<void> logout();
}