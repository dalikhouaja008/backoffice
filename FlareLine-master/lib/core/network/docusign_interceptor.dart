import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dart:html' as html;

class DocuSignInterceptor extends Interceptor {
  final Logger logger;

  DocuSignInterceptor({
    required this.logger,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('docusign')) {
      try {
        final timestamp = DateTime.now().toIso8601String();
        logger.i('[$timestamp] 🔒 Ajout des tokens DocuSign pour ${options.uri}');
        
        // Vérifier les en-têtes existants
        logger.i('[$timestamp] 📋 Headers existants: ${options.headers}');
        
        // Récupérer le token JWT DocuSign depuis localStorage
        final docusignJwt = html.window.localStorage['docusign_jwt'];
        
        // Si JWT est trouvé, l'utiliser prioritairement
        if (docusignJwt != null && docusignJwt.isNotEmpty) {
          // IMPORTANT: Nettoyer le JWT
          final cleanJwt = _cleanToken(docusignJwt);
          
          logger.i('[$timestamp] 🔑 Utilisation du JWT DocuSign depuis localStorage');
          
          // Ajouter le JWT nettoyé à l'en-tête
          options.headers['X-DocuSign-Token'] = 'Bearer $cleanJwt';
          logger.i('[$timestamp] 📋 JWT DocuSign ajouté dans X-DocuSign-Token');
        } 
        // Sinon, essayer avec le token brut
        else {
          final docusignToken = html.window.localStorage['docusign_token'];
          if (docusignToken != null && docusignToken.isNotEmpty) {
            // IMPORTANT: Nettoyer le token
            final cleanToken = _cleanToken(docusignToken);
            
            logger.i('[$timestamp] 🔑 Utilisation du token brut DocuSign depuis localStorage');
            
            // Ajouter le token nettoyé à l'en-tête
            options.headers['X-DocuSign-Token'] = 'Bearer $cleanToken';
            logger.i('[$timestamp] 📋 Token DocuSign brut ajouté dans X-DocuSign-Token');
          } else {
            logger.w('[$timestamp] ⚠️ Aucun token DocuSign trouvé dans localStorage - le backend va rejeter cette requête');
          }
        }
        
        // Vérifier les en-têtes finaux
        logger.i('[$timestamp] 📋 Headers finaux: ${options.headers}');
        
      } catch (e) {
        logger.e('Erreur lors de l\'ajout des tokens DocuSign: $e');
      }
    }
    handler.next(options);
  }

  // Méthode pour nettoyer le token
  String _cleanToken(String token) {
    // Retirer les espaces, les sauts de ligne et autres caractères non autorisés
    return token
        .replaceAll(RegExp(r'\s+'), '')  // Supprimer tous les espaces blancs (espaces, sauts de ligne, tabulations)
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');  // Garder uniquement les caractères ASCII imprimables
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    
    if (err.response?.statusCode == 401 && 
        err.requestOptions.path.contains('docusign')) {
      logger.e('[$timestamp] ⛔ ! Réponse 401 Unauthorized reçue');
      logger.e('[$timestamp] ⛔ 🐛 URL: ${err.requestOptions.uri}');
      
      // Loguer le contenu de la réponse pour comprendre l'erreur
      logger.e('[$timestamp] ⛔ 📋 Réponse d\'erreur complète:');
      logger.e('[$timestamp] ⛔ 📋 Status: ${err.response?.statusCode}');
      logger.e('[$timestamp] ⛔ 📋 Data: ${err.response?.data}');
      logger.e('[$timestamp] ⛔ 📋 Headers envoyés: ${err.requestOptions.headers}');
    }
    handler.next(err);
  }
}