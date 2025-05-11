import 'package:flareline/domain/repositories/docusign_repository.dart';

class GetSigningUrlUseCase {
  final DocuSignRepository repository;

  GetSigningUrlUseCase(this.repository);

  Future<String> call({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    String? returnUrl,
  }) async {
    return await repository.getSigningUrl(
      envelopeId: envelopeId,
      signerEmail: signerEmail,
      signerName: signerName,
      returnUrl: returnUrl,
    );
  }
}