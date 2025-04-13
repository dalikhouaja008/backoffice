// lib/data/repositories/geometre_repository_impl.dart
import 'package:flareline/data/datasources/geometre_remote_data_source.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';
import 'package:logger/logger.dart';

class GeometreRepositoryImpl implements GeometreRepository {
  final GeometreRemoteDataSource _remoteDataSource;
  final Logger _logger;

  GeometreRepositoryImpl({
    required GeometreRemoteDataSource remoteDataSource,
    required Logger logger,
  }) : 
    _remoteDataSource = remoteDataSource,
    _logger = logger;

  @override
  Future<List<Land>> getPendingLands() async {
    try {
      _logger.i('[2025-04-13 19:35:21] GeometreRepositoryImpl: Récupération des terrains à valider - User: nesssim');
      
      final lands = await _remoteDataSource.getPendingLands();
      
      _logger.i(
        '[2025-04-13 19:35:21] GeometreRepositoryImpl: ${lands.length} terrains récupérés - User: nesssim',
      );
      
      return lands;
    } catch (e) {
      _logger.e(
        '[2025-04-13 19:35:21] GeometreRepositoryImpl: Erreur lors de la récupération des terrains',
        error: e.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<ValidationEntity> validateLand({
    required String landId,
    required ValidationEntity validation,
  }) async {
    try {
      _logger.i(
        'GeometreRepositoryImpl: Validation du terrain $landId ',
        error: {
          'isValid': validation.isValidated,
          'comments': validation.comments,
        },
      );
      
      // Appel au data source avec la structure requise par l'API
      return await _remoteDataSource.validateLand(
        landId: landId,
        isValidated: validation.isValidated, 
        comments: validation.comments ?? "",
      );
    } catch (e) {
      _logger.e(
        ' GeometreRepositoryImpl: Erreur lors de la validation du terrain $landId',
        error: e.toString(),
      );
      rethrow;
    }
  }


}