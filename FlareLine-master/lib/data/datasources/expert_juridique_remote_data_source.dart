import 'package:dio/dio.dart';
import 'package:flareline/data/models/land_model.dart';
import 'package:flareline/data/mappers/land_mapper.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:logger/logger.dart';

class ExpertJuridiqueRemoteDataSource {
  final Dio dio;
  final Logger logger;
  final String baseUrl;

  ExpertJuridiqueRemoteDataSource({
    required this.dio,
    required this.logger,
    this.baseUrl = 'http://localhost:5000', 
  });

  Future<List<Land>> getPendingLands() async {
    try {
      logger.i('ExpertJuridiqueRemoteDataSource: Récupération des terrains sans validation');

      // Appel API avec le nouveau endpoint
      final response = await dio.get('$baseUrl/lands/without-role-validation');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        logger.d(
          'ExpertJuridiqueRemoteDataSource: Réponse brute reçue'
        );
        
        // Adapter au format de réponse de votre API
        final List<dynamic> landsJson = responseData is List 
            ? responseData 
            : responseData is Map && responseData['data'] is List 
                ? responseData['data'] 
                : [];
        
        // Log du nombre de terrains récupérés
        logger.i(
          'ExpertJuridiqueRemoteDataSource: ${landsJson.length} terrains récupérés'
        );
        
        // Conversion en modèles
        final List<LandModel> landModels = landsJson
            .map((json) => LandModel.fromJson(json))
            .toList();
            
        // Conversion en entités
        final entities = LandMapper.toEntityList(landModels);
        
        logger.i(
          'ExpertJuridiqueRemoteDataSource: ${entities.length} entités de terrains créées - User: nesssim'
        );
        
        return entities;
      } else {
        logger.e(
          'ExpertJuridiqueRemoteDataSource: Erreur HTTP ${response.statusCode}',
          error: {
            'statusMessage': response.statusMessage,
            'responseData': response.data,
          }
        );
        throw Exception('Failed to fetch lands: ${response.statusCode} - ${response.statusMessage}');
      }
    } catch (e) {
      logger.e(
        'ExpertJuridiqueRemoteDataSource: Erreur lors de la récupération des terrains'
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
        'Validating land as expert juridique',
        error: {
          'landId': landId,
          'isValid': isValidated,
        },
      );

      final validationRequest = {
        'landId': landId.toString(),
        'isValid': isValidated,
        'comment': comments ?? '',
      };

      logger.d('Envoi de la requête avec: $validationRequest');

      final response = await dio.post(
        '$baseUrl/lands/validate',
        data: validationRequest,
      );

      if (response.statusCode == 200) {
        logger.log(
          Level.info,
          'Land validation successful',
          error: {
            'landId': landId,
            'response': response.data,
          },
        );
        
        return ValidationEntity(
          isValidated: isValidated,
          comments: comments,
        );
      } else {
        throw Exception('Failed to validate land: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e(
        'Dio Error validating land',
        error: {
          'statusCode': e.response?.statusCode,
          'responseData': e.response?.data,
          'requestData': e.requestOptions.data,
        }
      );
      rethrow;
    } catch (e) {
      logger.log(
        Level.error,
        'Error validating land',
        error: {
          'landId': landId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
}