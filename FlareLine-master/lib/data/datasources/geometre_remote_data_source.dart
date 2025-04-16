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
    this.baseUrl = 'http://localhost:5000', 
  });

  Future<List<Land>> getPendingLands() async {
  try {
    logger.i('GeometreRemoteDataSource: Récupération des terrains sans validation ');

    // Appel API existant...
    final response = await dio.get('$baseUrl/lands/without-geometer-validation');
    
    if (response.statusCode == 200) {
      final responseData = response.data;
      
      // Log de la réponse brute
      logger.d(
        ' GeometreRemoteDataSource: Réponse brute reçue'

      );
      
      // Adapter au format de réponse de votre API
      final List<dynamic> landsJson = responseData is List 
          ? responseData 
          : responseData is Map && responseData['data'] is List 
              ? responseData['data'] 
              : [];
      
      // Log du nombre de terrains récupérés
      logger.i(
        'GeometreRemoteDataSource: ${landsJson.length} terrains récupérés'
      );
      
      // Log détaillé de chaque terrain
      for (int i = 0; i < landsJson.length; i++) {
        logger.d(
          '[2025-04-13 22:12:39] GeometreRemoteDataSource: Détails du terrain #${i + 1}',
          error: {
            'id': landsJson[i]['_id'] ?? landsJson[i]['id'] ?? 'ID non disponible',
            'title': landsJson[i]['title'] ?? 'Titre non disponible',
            'location': landsJson[i]['location'] ?? 'Lieu non disponible',
            'status': landsJson[i]['status'] ?? 'Statut non disponible',
            'blockchainLandId': landsJson[i]['blockchainLandId'] ?? 'ID blockchain non disponible',
            'hasValidations': landsJson[i]['validations'] != null && landsJson[i]['validations'] is List,
            'validationsCount': landsJson[i]['validations'] is List ? landsJson[i]['validations'].length : 0,
          }
        );
      }
      
      // Conversion en modèles
      final List<LandModel> landModels = landsJson
          .map((json) => LandModel.fromJson(json))
          .toList();
          
      // Log des modèles créés
      logger.d(
        '[2025-04-13 22:12:39] GeometreRemoteDataSource: ${landModels.length} modèles de terrains créés',
        error: {
          'firstLandTitle': landModels.isNotEmpty ? landModels[0].title : 'Aucun terrain',
        }
      );
      
      // Conversion en entités
      final entities = LandMapper.toEntityList(landModels);
      
      // Log des entités créées
      logger.i(
        'GeometreRemoteDataSource: ${entities.length} entités de terrains créées - User: nesssim'
      );
      
      return entities;
    } else {
      // Log d'erreur HTTP
      logger.e(
        'GeometreRemoteDataSource: Erreur HTTP ${response.statusCode}',
        error: {
          'statusMessage': response.statusMessage,
          'responseData': response.data,
        }
      );
      throw Exception('Failed to fetch lands: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e) {
    // Log d'erreur avec stack trace
    logger.e(
      '[2025-04-13 22:12:39] GeometreRemoteDataSource: Erreur lors de la récupération des terrains'
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
      'Validating land as geometer',
      error: {
        'landId': landId,
        'isValid': isValidated, // Renommé pour correspondre au backend
      },
    );

    // Structure EXACTEMENT comme celle validée dans Postman
    final validationRequest = {
      'landId': landId.toString(), // Toujours en string
      'isValid': isValidated, // Utiliser isValid et non isValidated
      'comment': comments ?? '', // Utiliser comment (singulier) et non comments
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