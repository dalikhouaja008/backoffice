// lib/features/geometre/domain/usecases/get_pending_lands.dart

import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';

class GetPendingLands {
  final GeometreRepository repository;

  GetPendingLands(this.repository);

  Future<List<Land>> call() async {
    return await repository.getPendingLands();
  }
}