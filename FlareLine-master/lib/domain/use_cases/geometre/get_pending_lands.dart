import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';

class GetPendingLands {
  final GeometreRepository _repository;

  GetPendingLands({required GeometreRepository repository}) : _repository = repository;

  Future<List<Land>> call() {
    return _repository.getPendingLands();
  }
}