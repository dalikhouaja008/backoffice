import 'dart:html' as html; 
import 'package:dio/dio.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';
import 'package:flareline/core/services/secure_storage.dart'; 

class DocuSignInterceptor extends Interceptor {
  final Logger _logger;
  final SecureStorageService _secureStorage;
  
  // Clés pour le stockage sécurisé
  static const String _tokenKey = 'docusign_token';
  static const String _jwtKey = 'docusign_jwt';
  
  DocuSignInterceptor({
    Logger? logger,
    SecureStorageService? secureStorage,
  }) : 
    _logger = logger ?? getIt<Logger>(),
    _secureStorage = secureStorage ?? getIt<SecureStorageService>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Vérifier si c'est une requête vers un endpoint DocuSign
    if (options.path.contains('/docusign/')) {
      _logger.i('🔒 Ajout des tokens DocuSign pour ${options.path}');
      
      // Vérifier si nous avons un JWT dans le stockage sécurisé
      final jwt = await _secureStorage.read(key: _jwtKey);
      if (jwt != null && jwt.isNotEmpty) {
        _logger.i('🔑 Utilisation du JWT DocuSign');
        options.headers['X-DocuSign-Token'] = 'Bearer $jwt';
      } 
      // Sinon, utiliser le token standard s'il existe
      else {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          _logger.i('🔑 Utilisation du token DocuSign standard');
          options.headers['X-DocuSign-Token'] = 'Bearer $token';
        } else {
          _logger.w('⚠️ Aucun token DocuSign trouvé dans le stockage sécurisé');
        }
      }
    }
    
    // Continuer avec la requête
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Intercepter les erreurs 401/403 qui pourraient indiquer un token expiré
    if (err.response != null && 
        (err.response!.statusCode == 401 || err.response!.statusCode == 403) &&
        err.requestOptions.path.contains('/docusign/')) {
      
      _logger.e('🚫 Erreur d\'authentification DocuSign (${err.response!.statusCode})');
      
      // Nettoyer les tokens expirés
      await Future.wait([
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _jwtKey),
      ]);
      
    }
    
    handler.next(err);
  }
}