import 'package:flareline/domain/repositories/docusign_repository.dart';

class CheckDocuSignAuthenticationUseCase {
  final DocuSignRepository repository;

  CheckDocuSignAuthenticationUseCase({required this.repository});

  Future<bool> call() async {
    return await repository.isAuthenticated();
  }
}
