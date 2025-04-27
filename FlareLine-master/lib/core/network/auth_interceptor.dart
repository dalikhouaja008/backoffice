// lib/core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:logger/logger.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  final Logger logger;
  
  AuthInterceptor({
    required this.secureStorage,
    required this.logger,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Récupérer le token JWT depuis le stockage sécurisé
      final token = await secureStorage.getAccessToken();
      
      if (token != null && token.isNotEmpty) {
        // Ajouter le token à l'en-tête Authorization
        options.headers['Authorization'] = 'Bearer $token';
        
        logger.i('Token ajouté à la requête: ${options.path}');
        logger.d('Token: ${token.substring(0, 10)}...');
      } else {
        logger.w('Aucun token trouvé pour la requête: ${options.path}');
      }
      
      return handler.next(options);
    } catch (e) {
      logger.e(' Erreur lors de l\'ajout du token', error: e.toString());
      return handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      logger.w('Réponse 401 Unauthorized reçue');
      logger.d('URL: ${err.requestOptions.path}');
      
      // Si un token expiré ou invalide: vous pouvez implémenter ici la logique
      // pour rediriger l'utilisateur vers l'écran de connexion
      // Pour l'instant, nous nous contentons de logger l'erreur
    }
    
    return handler.next(err);
  }
}