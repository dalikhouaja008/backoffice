import 'package:flareline/domain/repositories/docusign_repository.dart';

class InitiateDocuSignAuthenticationUseCase {
  final DocuSignRepository repository;

  InitiateDocuSignAuthenticationUseCase({required this.repository});

  Future<bool> call() async {
    return await repository.initiateAuthentication();
  }
}