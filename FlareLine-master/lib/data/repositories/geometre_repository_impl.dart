import 'package:dio/dio.dart';
import 'package:flareline/data/models/land_model.dart';
import 'package:flareline/data/models/validation_model.dart';
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

  Future<List<LandModel>> getPendingLands() async {
    try {
      logger.log(
        Level.info,
        'Fetching pending lands',
        error: {
          'timestamp': '2025-04-09 14:58:56',
          'userLogin': 'dalikhouaja008',
        },
      );

      final response = await dio.get('$baseUrl/lands/pending');

      if (response.statusCode == 200) {
        final List<dynamic> landsJson = response.data['data'];
        return landsJson.map((json) => LandModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch pending lands');
      }
    } catch (e) {
      logger.log(
        Level.error,
        'Error fetching pending lands',
        error: {
          'timestamp': '2025-04-09 14:58:56',
          'userLogin': 'dalikhouaja008',
        },
      );
      rethrow;
    }
  }

  Future<ValidationModel> validateLand({
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
          'timestamp': '2025-04-09 14:58:56',
          'userLogin': 'dalikhouaja008',
        },
      );

      final response = await dio.post(
        '$baseUrl/lands/$landId/validate',
        data: ValidationModel(
          isValidated: isValidated,
          comments: comments,
        ).toJson(),
      );

      if (response.statusCode == 200) {
        return ValidationModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to validate land');
      }
    } catch (e) {
      logger.log(
        Level.error,
        'Error validating land',
        error:  {
          'landId': landId,
          'timestamp': '2025-04-09 14:58:56',
          'userLogin': 'dalikhouaja008',
        },
      );
      rethrow;
    }
  }
}