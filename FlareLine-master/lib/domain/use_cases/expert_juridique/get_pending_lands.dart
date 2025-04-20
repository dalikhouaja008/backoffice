import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/repositories/expert_juridique_repository.dart';

class GetPendingLandsExpertJuridique {
  final ExpertJuridiqueRepository repository;

  GetPendingLandsExpertJuridique({required this.repository});

  Future<List<Land>> call() async {
    return repository.getPendingLands();
  }
}