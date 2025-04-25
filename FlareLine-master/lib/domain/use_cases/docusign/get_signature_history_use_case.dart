import 'package:flareline/domain/entities/docusign_entity.dart';
import 'package:flareline/domain/repositories/docusign_repository.dart';

class GetSignatureHistoryUseCase {
  final DocuSignRepository repository;

  GetSignatureHistoryUseCase({required this.repository});

  Future<List<DocuSignEntity>> call() async {
    return await repository.getSignatureHistory();
  }
}