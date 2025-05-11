import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flareline/core/config/api_config.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:logger/logger.dart';

class DocuSignRemoteDataSource {
  final Dio dio;
  final Logger logger;
  final SecureStorageService secureStorage;

  // Variable de token en mémoire
  String? accessToken;

  // Clés de stockage pour DocuSign
  static const String _docusignTokenKey = 'docusign_token';
  static const String _docusignAccountIdKey = 'docusign_account_id';
  static const String _docusignExpiryKey = 'docusign_expiry';
  static const String _docusignRefreshTokenKey = 'docusign_refresh_token';

  // Constructeur avec baseUrl corrigé
  DocuSignRemoteDataSource({
    required this.dio,
    required this.logger,
    required this.secureStorage,
  });

  // URL de base (récupérée dynamiquement de ApiConfig)
  String get baseUrl => ApiConfig.landServiceUrl;

  // Méthode pour vérifier si l'utilisateur est connecté à DocuSign
  Future<bool> isAuthenticated() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔍 Vérification d\'authentification DocuSign');

      // 1. Vérifier d'abord si on a un token en mémoire
      if (accessToken != null && accessToken!.isNotEmpty) {
        logger.i(
            '[$timestamp] ✓ Token DocuSign trouvé en mémoire: ${accessToken!.substring(0, min(10, accessToken!.length))}...');

        // Vérifier quand même l'expiration
        final expiryTimeStr = await secureStorage.read(key: _docusignExpiryKey);
        if (expiryTimeStr != null) {
          try {
            final expiryTime = int.parse(expiryTimeStr);
            final now = DateTime.now().millisecondsSinceEpoch;

            logger.i(
                '[$timestamp] 🕐 Expiration du token: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
            logger.i('[$timestamp] 🕐 Heure actuelle: ${DateTime.now()}');

            if (now >= expiryTime) {
              logger.w('[$timestamp] ⚠️ Token en mémoire expiré');
              accessToken = null;
              await _clearDocuSignTokens();
              return false;
            }

            return true;
          } catch (e) {
            logger
                .w('[$timestamp] ⚠️ Erreur de vérification d\'expiration: $e');
            // On continue car on a quand même un token
          }
        }

        return true;
      }

      // 2. Sinon, vérifier dans le stockage sécurisé
      final storedToken = await secureStorage.read(key: _docusignTokenKey);

      // AJOUT DE LOGS: Afficher le contenu du token stocké
      if (storedToken == null || storedToken.isEmpty) {
        logger.e(
            '[$timestamp] ❌ Aucun token DocuSign trouvé dans le stockage sécurisé');
        return false;
      } else {
        logger.i(
            '[$timestamp] ✓ Token DocuSign trouvé dans le stockage sécurisé: ${storedToken.substring(0, min(10, storedToken.length))}...');
        logger.i(
            '[$timestamp] 📋 Longueur du token: ${storedToken.length} caractères');
      }

      // 3. Vérifier l'expiration
      final expiryTimeStr = await secureStorage.read(key: _docusignExpiryKey);
      if (expiryTimeStr != null) {
        try {
          // AJOUT: Afficher la valeur brute
          logger.i(
              '[$timestamp] 📋 Valeur brute de l\'expiration: $expiryTimeStr');

          final expiryTime = int.parse(expiryTimeStr);
          final now = DateTime.now().millisecondsSinceEpoch;

          logger.i(
              '[$timestamp] 🕒 Expiration convertie: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
          logger.i('[$timestamp] 🕒 Maintenant: ${DateTime.now()}');

          if (now >= expiryTime) {
            logger.w('[$timestamp] ⚠️ Token expiré');
            await _clearDocuSignTokens();
            return false;
          }
        } catch (e) {
          logger
              .w('[$timestamp] ⚠️ Erreur lors du parsing de l\'expiration: $e');
          // Continuer malgré l'erreur car le token existe
        }
      } else {
        logger.w('[$timestamp] ⚠️ Pas de date d\'expiration trouvée');
      }

      // 4. Stocker le token en mémoire pour les utilisations futures
      accessToken = storedToken;

      // AJOUT: Récupérer l'ID du compte pour le log
      final accountId = await secureStorage.read(key: _docusignAccountIdKey);
      if (accountId != null) {
        logger.i('[$timestamp] 📋 ID de compte DocuSign: $accountId');
      } else {
        logger.w('[$timestamp] ⚠️ Pas d\'ID de compte DocuSign trouvé');
      }

      logger.i('[$timestamp] ✅ Authentification DocuSign valide');
      return true;
    } catch (e) {
      logger.e('❌ Exception lors de la vérification d\'authentification: $e');
      return false;
    }
  }

  // Méthode pour initialiser l'authentification DocuSign
  void initiateAuthentication() {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger
          .i('[$timestamp] 🚀 Initialisation de l\'authentification DocuSign');

      // AJOUT: Logger l'URL complète
      final authUrl = '$baseUrl/docusign/login';
      logger.i('[$timestamp] 🌐 URL d\'authentification: $authUrl');

      // Définir les dimensions pour la fenêtre popup
      final width = 800;
      final height = 600;
      final left = (html.window.screen!.width! - width) / 2;
      final top = (html.window.screen!.height! - height) / 4;

      // Ouvrir une fenêtre popup pour l'authentification
      html.window.open(authUrl, 'DocuSignAuth',
          'width=$width,height=$height,left=$left,top=$top,resizable,scrollbars,status');

      logger.i(
          '[$timestamp] 🌐 Fenêtre d\'authentification DocuSign ouverte avec succès');
    } catch (e) {
      logger.e(
          '❌ Erreur lors de l\'initialisation de l\'authentification DocuSign: $e');
    }
  }

  // Méthode pour définir le token d'accès
  Future<void> setAccessToken(String token,
      {int? expiresIn, String? accountId}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // Stocker le token dans la variable de classe
      accessToken = token;
      logger.i(
          '[$timestamp] 🔐 Token défini en mémoire: ${token.substring(0, min(10, token.length))}...');

      // Stocker dans le stockage sécurisé
      await secureStorage.write(key: _docusignTokenKey, value: token);
      logger.i(
          '[$timestamp] 🔐 Token stocké dans SecureStorage (longueur: ${token.length})');

      // Stocker l'ID du compte si fourni
      if (accountId != null && accountId.isNotEmpty) {
        await secureStorage.write(key: _docusignAccountIdKey, value: accountId);
        logger.i('[$timestamp] 🔐 ID de compte stocké: $accountId');
      }

      // Calculer et stocker la date d'expiration
      int expiryTime;
      if (expiresIn != null) {
        expiryTime = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      } else {
        // Valeur par défaut: 1 heure
        expiryTime = DateTime.now().millisecondsSinceEpoch + (3600 * 1000);
      }

      await secureStorage.write(
          key: _docusignExpiryKey, value: expiryTime.toString());
      logger.i(
          '[$timestamp] 🔐 Expiration stockée: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
      logger.i('[$timestamp] 🔐 Valeur brute d\'expiration: $expiryTime');

      // AJOUT: Vérifier immédiatement que le token a bien été stocké
      final storedToken = await secureStorage.read(key: _docusignTokenKey);
      if (storedToken == token) {
        logger
            .i('[$timestamp] ✅ Vérification réussie: le token est bien stocké');
      } else {
        logger.e(
            '[$timestamp] ❌ ERREUR: Le token n\'a pas été correctement stocké!');
        if (storedToken != null) {
          logger.e(
              '[$timestamp] ❌ Token stocké différent, longueur: ${storedToken.length}');
        } else {
          logger.e('[$timestamp] ❌ Aucun token n\'a été stocké!');
        }
      }
    } catch (e) {
      logger.e('❌ Erreur lors de la définition du token: $e');
    }
  }

  // Méthode pour effacer les tokens DocuSign
  Future<void> _clearDocuSignTokens() async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🧹 Suppression des tokens DocuSign');

    // Effacer la variable en mémoire
    accessToken = null;

    // Effacer le stockage sécurisé
    await Future.wait([
      secureStorage.delete(key: _docusignTokenKey),
      secureStorage.delete(key: _docusignAccountIdKey),
      secureStorage.delete(key: _docusignExpiryKey),
      secureStorage.delete(key: _docusignRefreshTokenKey)
    ]);

    logger.i('[$timestamp] ✅ Tokens DocuSign supprimés avec succès');

    // AJOUT: Vérification que les tokens ont bien été supprimés
    final tokenCheck = await secureStorage.read(key: _docusignTokenKey);
    if (tokenCheck == null) {
      logger.i(
          '[$timestamp] ✅ Vérification réussie: le token a bien été supprimé');
    } else {
      logger.e(
          '[$timestamp] ❌ ERREUR: Le token n\'a pas été correctement supprimé!');
    }
  }

  // Méthode de déconnexion
  Future<void> logout() async {
    await _clearDocuSignTokens();
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🚪 Déconnexion DocuSign effectuée');
  }

  // Méthode pour traiter le token reçu
  Future<bool> processReceivedToken(String token,
      {String? accountId, int? expiresIn, String? expiryValue}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔄 Traitement du token DocuSign reçu');

      // AJOUT: Loguer les paramètres reçus
      logger.i(
          '[$timestamp] 📋 Token reçu (début): ${token.substring(0, min(10, token.length))}...');
      logger.i(
          '[$timestamp] 📋 Token reçu (longueur): ${token.length} caractères');
      if (accountId != null)
        logger.i('[$timestamp] 📋 ID de compte: $accountId');
      if (expiresIn != null)
        logger.i('[$timestamp] 📋 Expire dans: $expiresIn secondes');
      if (expiryValue != null)
        logger
            .i('[$timestamp] 📋 Valeur d\'expiration explicite: $expiryValue');

      // Stocker le token
      await setAccessToken(token, expiresIn: expiresIn, accountId: accountId);

      // Vérifier que le token a bien été stocké
      final storedToken = await secureStorage.read(key: _docusignTokenKey);
      if (storedToken != token) {
        logger.e(
            '[$timestamp] ❌ ERREUR CRITIQUE: Token mal stocké après processReceivedToken');
        return false;
      }

      // Si une valeur d'expiration explicite est fournie
      if (expiryValue != null) {
        try {
          final expiryTime = int.parse(expiryValue);
          await secureStorage.write(
              key: _docusignExpiryKey, value: expiryValue);
          logger.i(
              '[$timestamp] ✅ Expiration explicite stockée: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
        } catch (e) {
          logger.w('[$timestamp] ⚠️ Erreur avec l\'expiration explicite: $e');
        }
      }

      logger.i('[$timestamp] ✅ Token traité et stocké avec succès');
      return true;
    } catch (e) {
      logger.e(' ❌ Erreur lors du traitement du token: $e');
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
      logger.i('[$timestamp] 📝 Création d\'une enveloppe DocuSign'
          '\n└─ Signataire: $signerName ($signerEmail)'
          '\n└─ Titre: $title'
          '\n└─ Taille du document: ${documentBase64.length} caractères');

      // 1. Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        logger.e('[$timestamp] ❌ Non authentifié à DocuSign');
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
      }

      // 2. Récupérer les tokens

      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      if (docusignToken == null || docusignToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token DocuSign introuvable dans le stockage');
        throw Exception('Token DocuSign introuvable');
      }

      final cleanToken = _cleanToken(docusignToken);
      logger.i(
          '[$timestamp] 🔧 Token DocuSign nettoyé, longueur: ${cleanToken.length}');

      // AJOUT: Logger le contenu réel du token
      logger.i(
          '[$timestamp] 📋 Token DocuSign récupéré (début): ${docusignToken.substring(0, min(20, docusignToken.length))}...');
      logger.i(
          '[$timestamp] 📋 Token DocuSign récupéré (longueur): ${docusignToken.length} caractères');
      logger.i(
          '[$timestamp] 📋 Token DocuSign récupéré (fin): ...${docusignToken.substring(max(0, docusignToken.length - 20))}');

      // Récupérer le token d'authentification de l'application
      final authToken = await secureStorage.getAccessToken();
      if (authToken == null || authToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token d\'authentification introuvable');
        throw Exception('Token d\'authentification introuvable');
      }

      logger.i(
          '[$timestamp] 📋 Token d\'authentification (début): ${authToken.substring(0, min(20, authToken.length))}...');

      // Configuration de la requête
      logger.i('[$timestamp] 🔧 Préparation des en-têtes pour la requête');
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $docusignToken',
        },
      );

      // AJOUT: Logger les en-têtes complets pour debugging
      logger.i('[$timestamp] 📋 En-têtes complets:');
      logger.i('[$timestamp] 📋   Content-Type: application/json');
      logger.i(
          '[$timestamp] 📋   Authorization: Bearer ${authToken.substring(0, min(10, authToken.length))}...');
      logger.i(
          '[$timestamp] 📋   X-DocuSign-Token: Bearer ${docusignToken.substring(0, min(10, docusignToken.length))}...');

      // Données à envoyer
      final data = {
        'documentBase64': documentBase64,
        'signerEmail': signerEmail,
        'signerName': signerName,
        'title': title,
      };

      logger.i(
          '[$timestamp] 📤 Envoi de la requête à $baseUrl/docusign/create-embedded-envelope');

      // Appel à l'API
      final response = await dio
          .post(
            '$baseUrl/docusign/create-embedded-envelope',
            options: options,
            data: data,
          )
          .timeout(const Duration(seconds: 30));

      logger.i('[$timestamp] 📥 Réponse reçue: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Vérifier le contenu de la réponse
        if (response.data is Map && response.data['success'] == true) {
          logger.i('[$timestamp] ✅ Enveloppe créée avec succès');
          return response.data;
        } else {
          logger.e(
              '[$timestamp] ❌ Format de réponse inattendu: ${response.data}');
          throw Exception('Format de réponse inattendu: ${response.data}');
        }
      } else {
        logger.e('[$timestamp] ❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();

      // Vérifier si l'erreur est liée à l'authentification
      if (e.response?.statusCode == 401) {
        logger.e('[$timestamp] 🔒 Erreur d\'authentification DocuSign (401)');
        logger.e('[$timestamp] 🔒 Réponse du serveur: ${e.response?.data}');

        // Nettoyage des tokens
        await _clearDocuSignTokens();

        throw Exception(
            'Token DocuSign expiré ou invalide. Veuillez vous reconnecter.');
      }

      logger.e('[$timestamp] ❌ Erreur Dio: ${e.message}'
          '\n└─ Statut: ${e.response?.statusCode}'
          '\n└─ Réponse: ${e.response?.data}');

      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Exception: $e');
      rethrow;
    }
  }

  String _cleanToken(String token) {
    return token
        .replaceAll(RegExp(r'\s+'), '') // Supprimer tous les espaces blancs
        .replaceAll(RegExp(r'[^\x20-\x7E]'),
            ''); // Garder uniquement les caractères ASCII imprimables
  }

  // Méthode pour obtenir l'URL de signature embarquée
  Future<Map<String, dynamic>> getEmbeddedSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    String? returnUrl,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔗 Obtention de l\'URL de signature DocuSign'
          '\n└─ Enveloppe: $envelopeId'
          '\n└─ Signataire: $signerName ($signerEmail)');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        logger.e('[$timestamp] ❌ Non authentifié à DocuSign');
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      if (docusignToken == null) {
        logger.e('[$timestamp] ❌ Token DocuSign introuvable');
        throw Exception('Token DocuSign introuvable');
      }

      // AJOUT: Logger le token pour debugging
      logger.i(
          '[$timestamp] 📋 Token DocuSign (début): ${docusignToken.substring(0, min(20, docusignToken.length))}...');

      final authToken = await secureStorage.getAccessToken();

      // URL de retour par défaut si non fournie
      final finalReturnUrl = returnUrl ??
          '${ApiConfig.docuSignSigningReturnUrl}?envelopeId=$envelopeId&signing_complete=true';

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
        'returnUrl': finalReturnUrl,
      };

      logger.i('[$timestamp] 📤 Envoi de la requête pour l\'URL de signature');

      // Appel à l'API
      final response = await dio
          .post(
            '$baseUrl/docusign/embedded-signing',
            options: options,
            data: data,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['success'] == true) {
          logger.i('[$timestamp] ✅ URL de signature obtenue avec succès');
          return response.data;
        } else {
          logger.e(
              '[$timestamp] ❌ Format de réponse inattendu: ${response.data}');
          throw Exception('Format de réponse inattendu: ${response.data}');
        }
      } else {
        logger.e('[$timestamp] ❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();

      // Vérifier si l'erreur est liée à l'authentification
      if (e.response?.statusCode == 401) {
        logger.e('[$timestamp] 🔒 Erreur d\'authentification DocuSign (401)');
        await _clearDocuSignTokens();
        throw Exception(
            'Token DocuSign expiré ou invalide. Veuillez vous reconnecter.');
      }

      logger.e('[$timestamp] ❌ Erreur Dio: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Exception: $e');
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
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
      }

      // Récupérer les tokens
      final docusignToken = await secureStorage.read(key: _docusignTokenKey);
      final authToken = await secureStorage.getAccessToken();

      // Configuration de la requête
      logger.i('🔧 Préparation des en-têtes pour la requête');
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $docusignToken',
          'X-DocuSign-Token': 'Bearer $authToken',
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
        logger.e('[$timestamp] ❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();

      // Vérifier si l'erreur est liée à l'authentification
      if (e.response?.statusCode == 401) {
        logger.e('[$timestamp] 🔒 Erreur d\'authentification DocuSign (401)');
        await _clearDocuSignTokens();
        throw Exception(
            'Token DocuSign expiré ou invalide. Veuillez vous reconnecter.');
      }

      logger.e('[$timestamp] ❌ Erreur Dio: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Exception: $e');
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
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
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
        logger.e('[$timestamp] ❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();

      // Vérifier si l'erreur est liée à l'authentification
      if (e.response?.statusCode == 401) {
        logger.e('[$timestamp] 🔒 Erreur d\'authentification DocuSign (401)');
        await _clearDocuSignTokens();
        throw Exception(
            'Token DocuSign expiré ou invalide. Veuillez vous reconnecter.');
      }

      logger.e('[$timestamp] ❌ Erreur Dio: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Exception: $e');
      rethrow;
    }
  }

  // Méthode pour récupérer l'historique des signatures
  Future<Map<String, dynamic>> getSignatureHistory() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i(
          '[$timestamp] 📚 Récupération de l\'historique des signatures DocuSign');

      // Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
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
        logger.e('[$timestamp] ❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final timestamp = DateTime.now().toIso8601String();

      // Vérifier si l'erreur est liée à l'authentification
      if (e.response?.statusCode == 401) {
        logger.e('[$timestamp] 🔒 Erreur d\'authentification DocuSign (401)');
        throw Exception(
            'Token DocuSign expiré ou invalide. Veuillez vous reconnecter.');
      }

      logger.e('[$timestamp] ❌ Erreur Dio: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      final timestamp = DateTime.now().toIso8601String();
      logger.e('[$timestamp] ❌ Exception: $e');
      rethrow;
    }
  }

  // Méthode pour créer une enveloppe pour signature embarquée (version compatible avec DocuSignService)
  Future<Map<String, dynamic>> createEnvelopeForEmbeddedSigning({
    required Land land,
    required String documentBase64,
    required String signerEmail,
    required String signerName,
  }) async {
    try {
      // Appeler la méthode principale de création d'enveloppe
      return await createEmbeddedEnvelope(
        documentBase64: documentBase64,
        signerEmail: signerEmail,
        signerName: signerName,
        title: 'Validation juridique du terrain: ${land.title}',
      );
    } catch (e) {
      logger.e(
          '❌ Exception lors de la création de l\'enveloppe pour signature embarquée: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Méthode pour ouvrir un document signé dans le navigateur
  Future<void> openSignedDocument(
      Uint8List documentData, String envelopeId) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger
          .i('[$timestamp] 📂 Ouverture du document signé dans le navigateur');

      // Créer un blob à partir des données du document
      final blob = html.Blob([documentData]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Ouvrir le document dans une nouvelle fenêtre
      html.window.open(url, 'DocuSignDocument');

      // Nettoyer l'URL de l'objet après un délai
      Future.delayed(const Duration(minutes: 5), () {
        html.Url.revokeObjectUrl(url);
      });

      logger.i('[$timestamp] ✅ Document ouvert avec succès');
    } catch (e) {
      logger.e(' ❌ Erreur lors de l\'ouverture du document: $e');
      throw Exception('Erreur lors de l\'ouverture du document: $e');
    }
  }
}
