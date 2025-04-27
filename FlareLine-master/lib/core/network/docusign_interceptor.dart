import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';

class DocuSignInterceptor extends Interceptor {
  final Logger _logger;
  
  DocuSignInterceptor({Logger? logger}) : _logger = logger ?? getIt<Logger>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {

    
    // Vérifier si c'est une requête vers un endpoint DocuSign
    if (options.path.contains('/docusign/')) {
      _logger.i('🔒 Ajout des tokens DocuSign pour ${options.path}');
      
      // Vérifier si nous avons un JWT dans localStorage
      final jwt = html.window.localStorage['docusign_jwt'];
      if (jwt != null && jwt.isNotEmpty) {
        _logger.i('🔑 Utilisation du JWT DocuSign');
        options.headers['X-DocuSign-Token'] = 'Bearer $jwt';
      } 
      // Sinon, utiliser le token standard s'il existe
      else {
        final token = html.window.localStorage['docusign_token'];
        if (token != null && token.isNotEmpty) {
          _logger.i(' 🔑 Utilisation du token DocuSign standard');
          options.headers['X-DocuSign-Token'] = 'Bearer $token';
        } else {
          _logger.w('⚠️ Aucun token DocuSign trouvé dans localStorage');
        }
      }
    }
    
    // Continuer avec la requête
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {

    
    // Intercepter les erreurs 401/403 qui pourraient indiquer un token expiré
    if (err.response != null && 
        (err.response!.statusCode == 401 || err.response!.statusCode == 403) &&
        err.requestOptions.path.contains('/docusign/')) {
      
      _logger.e('🚫 Erreur d\'authentification DocuSign (${err.response!.statusCode})');
      
      // Nettoyer les tokens expirés
      html.window.localStorage.remove('docusign_token');
      html.window.localStorage.remove('docusign_jwt');
      
      // Vous pourriez ici déclencher une nouvelle tentative d'authentification
    }
    
    handler.next(err);
  }
}