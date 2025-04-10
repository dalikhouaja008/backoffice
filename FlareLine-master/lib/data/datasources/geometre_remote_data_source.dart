import 'package:dio/dio.dart';
import 'package:flareline/data/models/land_model.dart';
import 'package:flareline/data/mappers/land_mapper.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:logger/logger.dart';

class GeometreRemoteDataSource {
  final Dio dio;
  final Logger logger;
  final String baseUrl;

  GeometreRemoteDataSource({
    required this.dio,
    required this.logger,
    required this.baseUrl,
  });

  Future<List<Land>> getPendingLands() async {
    try {
      logger.log(
        Level.info,
        'Fetching pending lands',
        error: {
          'timestamp': '2025-04-09 20:48:37',
          'userLogin': 'dalikhouaja008',
        },
      );

      final response = await dio.get('$baseUrl/lands/pending');

      if (response.statusCode == 200) {
        final List<dynamic> landsJson = response.data['data'];
        final List<LandModel> landModels = landsJson
            .map((json) => LandModel.fromJson(json))
            .toList();
        return LandMapper.toEntityList(landModels);
      } else {
        throw Exception('Failed to fetch pending lands');
      }
    } catch (e) {
      logger.log(
        Level.error,
        'Error fetching pending lands',
        error: {
          'timestamp': '2025-04-09 20:48:37',
          'userLogin': 'dalikhouaja008',
        },
      );
      rethrow;
    }
  }

  Future<ValidationEntity> validateLand({
    required String landId,
    required bool isValidated,
    String? comments,
  }) async {
    try {
      logger.log(
        Level.info,
        'Validating land',
        error: {
          'landId': landId,
          'isValidated': isValidated,
          'timestamp': '2025-04-09 20:48:37',
          'userLogin': 'dalikhouaja008',
        },
      );

      final response = await dio.post(
        '$baseUrl/lands/$landId/validate',
        data: {
          'isValidated': isValidated,
          'comments': comments,
        },
      );

      if (response.statusCode == 200) {
        return ValidationEntity(
          isValidated: response.data['data']['isValidated'],
          comments: response.data['data']['comments'],
        );
      } else {
        throw Exception('Failed to validate land');
      }
    } catch (e) {
      logger.log(
        Level.error,
        'Error validating land',
        error: {
          'landId': landId,
          'timestamp': '2025-04-09 20:48:37',
          'userLogin': 'dalikhouaja008',
        },
      );
      rethrow;
    }
  }
}