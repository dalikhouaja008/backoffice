import 'package:dio/dio.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:logger/logger.dart';
import 'dart:math';

class DocuSignInterceptor extends Interceptor {
  final Logger logger;
  final SecureStorageService secureStorage;

  DocuSignInterceptor({
    required this.logger, 
    required this.secureStorage,
  });

@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.path.contains('docusign')) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔒 Ajout des tokens DocuSign pour ${options.uri}');
      
      // Récupérer le token DocuSign
      final docusignToken = await secureStorage.read(key: 'docusign_token');
      
      if (docusignToken != null && docusignToken.isNotEmpty) {
        // IMPORTANT: Nettoyer le token pour éliminer les caractères non autorisés
        final cleanToken = _cleanToken(docusignToken);
        
        logger.i('[$timestamp] 🔑 Utilisation du token DocuSign nettoyé');
        
        // Ajouter le token nettoyé à l'en-tête
        options.headers['X-DocuSign-Token'] = 'Bearer $cleanToken';
        logger.i('[$timestamp] 📋 Token DocuSign nettoyé ajouté dans X-DocuSign-Token');
      } else {
        logger.w('[$timestamp] ⚠️ Aucun token DocuSign trouvé');
      }
    } catch (e) {
      logger.e('❌ Erreur lors de l\'ajout des tokens DocuSign: $e');
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