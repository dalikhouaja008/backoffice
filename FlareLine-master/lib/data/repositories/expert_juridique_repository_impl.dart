
import 'package:flareline/data/datasources/expert_juridique_remote_data_source.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/domain/repositories/expert_juridique_repository.dart';

class ExpertJuridiqueRepositoryImpl implements ExpertJuridiqueRepository {
  final ExpertJuridiqueRemoteDataSource remoteDataSource;

  ExpertJuridiqueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Land>> getPendingLands() async {
    return remoteDataSource.getPendingLands();
  }

  @override
  Future<ValidationEntity> validateLand({
    required String landId,
    required ValidationEntity validation,
  }) async {
    return remoteDataSource.validateLand(
      landId: landId,
      isValidated: validation.isValidated,
      comments: validation.comments,
    );
  }
}