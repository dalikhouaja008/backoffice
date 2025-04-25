// lib/data/datasources/docusign_remote_data_source.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:logger/logger.dart';

class DocuSignRemoteDataSource {
  final Dio dio;
  final Logger logger;
  final String baseUrl;
  final SecureStorageService secureStorage;
  
  // Clés de stockage spécifiques pour DocuSign
  static const String _docusignTokenKey = 'docusign_token';
  static const String _docusignAccountIdKey = 'docusign_account_id';
  static const String _docusignExpiryKey = 'docusign_expiry';

  DocuSignRemoteDataSource({
    required this.dio,
    required this.logger,
    required this.secureStorage,
    this.baseUrl = 'https://api.landservice.com', // Remplacez par votre URL d'API
  });

  // Méthode pour vérifier si l'utilisateur est connecté à DocuSign
  Future<bool> isAuthenticated() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔐 Vérification de l\'authentification DocuSign');
      
      // Vérifier si les tokens existent
      final token = await secureStorage.read(key: _docusignTokenKey);
      final accountId = await secureStorage.read(key: _docusignAccountIdKey);
      final expiryStr = await secureStorage.read(key: _docusignExpiryKey);

      // Si les tokens n'existent pas, l'utilisateur n'est pas authentifié
      if (token == null || accountId == null || expiryStr == null) {
        logger.i('[$timestamp] 🚫 Authentification DocuSign inactive: tokens manquants');
        return false;
      }

      // Convertir la date d'expiration
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();

      // Vérifier si le token est expiré
      if (now.isAfter(expiry)) {
        logger.i('[$timestamp] 🚫 Token DocuSign expiré le ${expiry.toIso8601String()}');
        
        // Supprimer les tokens expirés
        await _clearDocuSignTokens();
        return false;
      }

      logger.i(' ✅ Authentification DocuSign active et valide'
               '\n└─ Token: ${token.substring(0, 10)}...'
               '\n└─ Account ID: $accountId'
               '\n└─ Expiration: $expiryStr');
      return true;
    } catch (e) {
      logger.e(' ❌ Erreur lors de la vérification d\'authentification DocuSign'
               '\n└─ Error: $e');
      return false;
    }
  }

  // Méthode pour effacer les tokens DocuSign
  Future<void> _clearDocuSignTokens() async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🧹 Suppression des tokens DocuSign');
    
    await Future.wait([
      secureStorage.delete(key: _docusignTokenKey),
      secureStorage.delete(key: _docusignAccountIdKey),
      secureStorage.delete(key: _docusignExpiryKey)
    ]);
    
    logger.i('[$timestamp] ✅ Tokens DocuSign supprimés avec succès');
  }

  // Méthode pour initialiser l'authentification DocuSign
  Future<bool> initiateAuthentication() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🚀 Initialisation de l\'authentification DocuSign');

      // Créer l'URL de redirection
      final authUrl = '$baseUrl/docusign/login';
      
      // Définir les dimensions pour la fenêtre popup
      final width = 800;
      final height = 600;
      final left = (html.window.screen!.width! - width) / 2;
      final top = (html.window.screen!.height! - height) / 4;
      
      // Ouvrir une fenêtre popup pour l'authentification
      html.window.open(
        authUrl,
        'DocuSignAuth',
        'width=$width,height=$height,left=$left,top=$top,resizable,scrollbars,status'
      );
      
      logger.i('[$timestamp] 🌐 Fenêtre d\'authentification DocuSign ouverte avec succès');
      return true;
    } catch (e) {
      logger.e('❌ Erreur lors de l\'initialisation de l\'authentification DocuSign'
               '\n└─ Error: $e');
      return false;
    }
  }

  // Méthode pour créer une enveloppe pour signature embarquée
  Future<Map<String, dynamic>> createEmbeddedEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 📨 Création d\'une enveloppe DocuSign'
               '\n└─ Signataire: $signerName ($signerEmail)'
               '\n└─ Titre: $title'
               '\n└─ Taille du document: ${documentBase64.length} caractères');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception('Non authentifié à DocuSign. Veuillez vous connecter d\'abord.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $docusignToken',
        },
      );

      // Données à envoyer
      final data = {
        'documentBase64': documentBase64,
        'signerEmail': signerEmail,
        'signerName': signerName,
        'title': title,
      };

      // Appel à l'API
      final response = await dio.post(
        '$baseUrl/docusign/create-embedded-envelope',
        options: options,
        data: data,
      );

      if (response.statusCode == 200) {
        logger.i('[$timestamp] ✅ Enveloppe créée avec succès'
                 '\n└─ Réponse: ${response.data}');
                 
        return response.data;
      } else {
        logger.e('[$timestamp] ❌ Erreur lors de la création de l\'enveloppe'
                 '\n└─ Code HTTP: ${response.statusCode}'
                 '\n└─ Réponse: ${response.data}');
                 
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur Dio lors de la création de l\'enveloppe'
               '\n└─ Code: ${e.response?.statusCode}'
               '\n└─ Message: ${e.message}'
               '\n└─ Réponse: ${e.response?.data}');
               
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur générale lors de la création de l\'enveloppe'
               '\n└─ Error: $e');
               
      rethrow;
    }
  }

  // Méthode pour obtenir l'URL de signature embarquée
  Future<Map<String, dynamic>> getEmbeddedSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    required String returnUrl,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔗 Obtention de l\'URL de signature DocuSign'
               '\n└─ Enveloppe: $envelopeId'
               '\n└─ Signataire: $signerName ($signerEmail)');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception('Non authentifié à DocuSign. Veuillez vous connecter d\'abord.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $docusignToken',
        },
      );

      // Données à envoyer
      final data = {
        'envelopeId': envelopeId,
        'signerEmail': signerEmail,
        'signerName': signerName,
        'returnUrl': returnUrl,
      };

      // Appel à l'API
      final response = await dio.post(
        '$baseUrl/docusign/embedded-signing',
        options: options,
        data: data,
      );

      if (response.statusCode == 200) {
        logger.i('[$timestamp] ✅ URL de signature obtenue avec succès'
                 '\n└─ Réponse: ${response.data}');
                 
        return response.data;
      } else {
        logger.e('[$timestamp] ❌ Erreur lors de l\'obtention de l\'URL de signature'
                 '\n└─ Code HTTP: ${response.statusCode}'
                 '\n└─ Réponse: ${response.data}');
                 
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur Dio lors de l\'obtention de l\'URL de signature'
               '\n└─ Code: ${e.response?.statusCode}'
               '\n└─ Message: ${e.message}'
               '\n└─ Réponse: ${e.response?.data}');
               
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur générale lors de l\'obtention de l\'URL de signature'
               '\n└─ Error: $e');
               
      rethrow;
    }
  }

  // Méthode pour vérifier le statut d'une enveloppe
  Future<Map<String, dynamic>> checkEnvelopeStatus({
    required String envelopeId,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔍 Vérification du statut de l\'enveloppe DocuSign'
               '\n└─ Enveloppe: $envelopeId');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception('Non authentifié à DocuSign. Veuillez vous connecter d\'abord.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      final options = Options(
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $docusignToken',
        },
      );

      // Appel à l'API
      final response = await dio.get(
        '$baseUrl/docusign/envelope-status/$envelopeId',
        options: options,
      );

      if (response.statusCode == 200) {
        logger.i('[$timestamp] ✅ Statut de l\'enveloppe obtenu avec succès'
                 '\n└─ Statut: ${response.data['status']}');
                 
        return response.data;
      } else {
        logger.e('[$timestamp] ❌ Erreur lors de la vérification du statut'
                 '\n└─ Code HTTP: ${response.statusCode}'
                 '\n└─ Réponse: ${response.data}');
                 
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur Dio lors de la vérification du statut'
               '\n└─ Code: ${e.response?.statusCode}'
               '\n└─ Message: ${e.message}'
               '\n└─ Réponse: ${e.response?.data}');
               
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur générale lors de la vérification du statut'
               '\n└─ Error: $e');
               
      rethrow;
    }
  }

  // Méthode pour télécharger un document signé
  Future<Uint8List> downloadSignedDocument({
    required String envelopeId,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 📥 Téléchargement du document signé DocuSign'
               '\n└─ Enveloppe: $envelopeId');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception('Non authentifié à DocuSign. Veuillez vous connecter d\'abord.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      final options = Options(
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $docusignToken',
        },
        responseType: ResponseType.bytes,
      );

      // Appel à l'API
      final response = await dio.get(
        '$baseUrl/docusign/download-document/$envelopeId',
        options: options,
      );

      if (response.statusCode == 200) {
        logger.i('[$timestamp] ✅ Document téléchargé avec succès'
                 '\n└─ Taille: ${response.data.length} octets');
                 
        return response.data;
      } else {
        logger.e('[$timestamp] ❌ Erreur lors du téléchargement du document'
                 '\n└─ Code HTTP: ${response.statusCode}');
                 
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur Dio lors du téléchargement du document'
               '\n└─ Code: ${e.response?.statusCode}'
               '\n└─ Message: ${e.message}');
               
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur générale lors du téléchargement du document'
               '\n└─ Error: $e');
               
      rethrow;
    }
  }

  // Méthode pour récupérer l'historique des signatures
  Future<Map<String, dynamic>> getSignatureHistory() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 📚 Récupération de l\'historique des signatures DocuSign');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception('Non authentifié à DocuSign. Veuillez vous connecter d\'abord.');
      }

      // Récupérer les tokens
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      final options = Options(
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Appel à l'API
      final response = await dio.get(
        '$baseUrl/docusign/history',
        options: options,
      );

      if (response.statusCode == 200) {
        logger.i('[$timestamp] ✅ Historique des signatures récupéré avec succès'
                 '\n└─ Nombre d\'éléments: ${(response.data['signatures'] as List?)?.length ?? 0}');
                 
        return response.data;
      } else {
        logger.e('[$timestamp] ❌ Erreur lors de la récupération de l\'historique'
                 '\n└─ Code HTTP: ${response.statusCode}'
                 '\n└─ Réponse: ${response.data}');
                 
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur Dio lors de la récupération de l\'historique'
               '\n└─ Code: ${e.response?.statusCode}'
               '\n└─ Message: ${e.message}'
               '\n└─ Réponse: ${e.response?.data}');
               
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur générale lors de la récupération de l\'historique'
               '\n└─ Error: $e');
               
      rethrow;
    }
  }

  // Méthode pour sauvegarder les tokens DocuSign reçus depuis localStorage
  Future<bool> saveTokenFromLocalStorage() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 💾 Tentative de sauvegarde du token DocuSign depuis localStorage');
      
      // Récupérer le token depuis localStorage (HTML)
      final token = html.window.localStorage['docusign_token'];
      if (token == null || token.isEmpty) {
        logger.w('[$timestamp] ⚠️ Aucun token DocuSign trouvé dans localStorage');
        return false;
      }

      // Récupérer le JWT stocké dans localStorage
      final jwt = html.window.localStorage['docusign_jwt'];
      if (jwt == null || jwt.isEmpty) {
        logger.w('[$timestamp] ⚠️ Aucun JWT DocuSign trouvé dans localStorage');
        return false;
      }

      // Décoder le JWT pour extraire les informations
      try {
        // Diviser le JWT en parties
        final parts = jwt.split('.');
        if (parts.length != 3) {
          throw Exception('Format JWT invalide');
        }
        
        // Décoder la charge utile (payload)
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> jwtData = jsonDecode(decoded);
        
        // Extraire les données nécessaires
        final accountId = jwtData['docusignAccountId'] as String?;
        final expiryTimestamp = jwtData['docusignTokenExpiry'] as int?;
        
        if (accountId == null || expiryTimestamp == null) {
          throw Exception('Données JWT incomplètes');
        }
        
        // Convertir le timestamp en DateTime
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Sauvegarder dans le stockage sécurisé
        await Future.wait([
          secureStorage.write(key: _docusignTokenKey, value: token),
          secureStorage.write(key: _docusignAccountIdKey, value: accountId),
          secureStorage.write(key: _docusignExpiryKey, value: expiry.toIso8601String()),
        ]);
        
        logger.i('[$timestamp] ✅ Token DocuSign sauvegardé avec succès'
                 '\n└─ Token: ${token.substring(0, 10)}...'
                 '\n└─ Account ID: $accountId'
                 '\n└─ Expiration: ${expiry.toIso8601String()}');
                 
        return true;
      } catch (e) {
        logger.e('[$timestamp] ❌ Erreur lors du décodage du JWT'
                 '\n└─ Error: $e');
        return false;
      }
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Erreur lors de la sauvegarde du token DocuSign'
               '\n└─ Error: $e');
      return false;
    }
  }
}