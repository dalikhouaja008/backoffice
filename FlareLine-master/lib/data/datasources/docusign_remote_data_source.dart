import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flareline/core/config/api_config.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:logger/logger.dart';

class DocuSignRemoteDataSource {
  final Dio dio;
  final Logger logger;

  // Variable de token en mémoire
  String? accessToken;

  // Clés de stockage pour DocuSign
  static const String _docusignTokenKey = 'docusign_token';
  static const String _docusignJwtKey = 'docusign_jwt';
  static const String _docusignAccountIdKey = 'docusign_account_id';
  static const String _docusignExpiryKey = 'docusign_expiry';

  // Constructeur avec baseUrl corrigé
  DocuSignRemoteDataSource({
    required this.dio,
    required this.logger,
  });

  // URL de base (récupérée dynamiquement de ApiConfig)
  String get baseUrl => ApiConfig.landServiceUrl;

  Future<bool> isAuthenticated() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔍 Vérification d\'authentification DocuSign');

      // 1. Vérifier si on a un JWT dans localStorage
      final jwt = html.window.localStorage[_docusignJwtKey];
      if (jwt != null && jwt.isNotEmpty) {
        logger.i('[$timestamp] ✓ JWT DocuSign trouvé dans localStorage');

        // Vérifier l'expiration
        final expiryTimeStr = html.window.localStorage[_docusignExpiryKey];
        if (expiryTimeStr != null) {
          try {
            final expiryTime = int.parse(expiryTimeStr);
            final now = DateTime.now().millisecondsSinceEpoch;

            if (now >= expiryTime) {
              logger.w('[$timestamp] ⚠️ Token expiré');
              await logout(); // Nettoyer les tokens expirés
              return false;
            }
          } catch (e) {
            logger.w(
                '[$timestamp] ⚠️ Erreur lors du parsing de l\'expiration: $e');
            // Continuer malgré l'erreur car le token existe
          }
        }

        // Mettre à jour le token en mémoire pour les utilisations futures
        if (accessToken == null) {
          final token = html.window.localStorage[_docusignTokenKey];
          if (token != null && token.isNotEmpty) {
            accessToken = token;
          }
        }

        logger.i('[$timestamp] ✅ Authentification DocuSign valide');
        return true;
      }

      // 2. Vérifier aussi le token brut (pour compatibilité)
      final token = html.window.localStorage[_docusignTokenKey];
      if (token != null && token.isNotEmpty) {
        logger.i('[$timestamp] ✓ Token DocuSign brut trouvé dans localStorage');

        // Mettre à jour le token en mémoire
        accessToken = token;

        // Vérifier l'expiration comme ci-dessus
        final expiryTimeStr = html.window.localStorage[_docusignExpiryKey];
        if (expiryTimeStr != null) {
          try {
            final expiryTime = int.parse(expiryTimeStr);
            final now = DateTime.now().millisecondsSinceEpoch;

            if (now >= expiryTime) {
              logger.w('[$timestamp] ⚠️ Token expiré');
              await logout();
              return false;
            }
          } catch (e) {
            logger.w(
                '[$timestamp] ⚠️ Erreur lors du parsing de l\'expiration: $e');
          }
        }

        logger.i(
            '[$timestamp] ✅ Authentification DocuSign valide (via token brut)');
        return true;
      }

      logger.e('[$timestamp] ❌ Aucun token DocuSign trouvé');
      return false;
    } catch (e) {
      logger.e('❌ Exception lors de la vérification d\'authentification: $e');
      return false;
    }
  }

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

      // Stocker le token en mémoire pour performance
      accessToken = token;
      logger.i(
          '[$timestamp] 🔐 Token défini en mémoire: ${token.substring(0, min(10, token.length))}...');

      // Stocker dans localStorage
      html.window.localStorage[_docusignTokenKey] = token;
      logger.i(
          '[$timestamp] 🔐 Token stocké dans localStorage (longueur: ${token.length})');

      // Stocker l'ID du compte si fourni
      if (accountId != null && accountId.isNotEmpty) {
        html.window.localStorage[_docusignAccountIdKey] = accountId;
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

      html.window.localStorage[_docusignExpiryKey] = expiryTime.toString();
      logger.i(
          '[$timestamp] 🔐 Expiration stockée: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
      logger.i('[$timestamp] 🔐 Valeur brute d\'expiration: $expiryTime');

      // Vérifier que le token a bien été stocké
      final storedToken = html.window.localStorage[_docusignTokenKey];
      if (storedToken == token) {
        logger
            .i('[$timestamp] ✅ Vérification réussie: le token est bien stocké');
      } else {
        logger.e(
            '[$timestamp] ❌ ERREUR: Le token n\'a pas été correctement stocké!');
      }
    } catch (e) {
      logger.e('❌ Erreur lors de la définition du token: $e');
    }
  }

  // Méthode de déconnexion
  Future<void> logout() async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🧹 Suppression des tokens DocuSign');

    // Effacer la variable en mémoire
    accessToken = null;

    // Effacer localStorage
    html.window.localStorage.remove(_docusignTokenKey);
    html.window.localStorage.remove(_docusignJwtKey);
    html.window.localStorage.remove(_docusignAccountIdKey);
    html.window.localStorage.remove(_docusignExpiryKey);

    logger.i('[$timestamp] ✅ Tokens DocuSign supprimés avec succès');

    // Vérification que les tokens ont bien été supprimés
    final tokenCheck = html.window.localStorage[_docusignTokenKey];
    if (tokenCheck == null) {
      logger.i(
          '[$timestamp] ✅ Vérification réussie: le token a bien été supprimé');
    } else {
      logger.e(
          '[$timestamp] ❌ ERREUR: Le token n\'a pas été correctement supprimé!');
    }
  }

  // Méthode pour traiter le token reçu
  Future<bool> processReceivedToken(String token, String? jwt,
      {String? accountId, int? expiresIn, String? expiryValue}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 🔄 Traitement des tokens DocuSign reçus');

      // Logger les paramètres reçus
      logger.i(
          '[$timestamp] 📋 Token brut reçu (début): ${token.substring(0, min(10, token.length))}...');
      logger.i(
          '[$timestamp] 📋 Token brut reçu (longueur): ${token.length} caractères');
      if (jwt != null) {
        logger.i(
            '[$timestamp] 📋 JWT reçu (début): ${jwt.substring(0, min(10, jwt.length))}...');
        logger
            .i('[$timestamp] 📋 JWT reçu (longueur): ${jwt.length} caractères');
      }
      if (accountId != null) {
        logger.i('[$timestamp] 📋 ID de compte: $accountId');
      }
      if (expiresIn != null) {
        logger.i('[$timestamp] 📋 Expire dans: $expiresIn secondes');
      }
      if (expiryValue != null) {
        logger
            .i('[$timestamp] 📋 Valeur d\'expiration explicite: $expiryValue');
      }

      // IMPORTANT: Nettoyer le token et le JWT
      final cleanToken = _cleanToken(token);
      String? cleanJwt = jwt != null ? _cleanToken(jwt) : null;

      // Stocker le token brut
      html.window.localStorage[_docusignTokenKey] = cleanToken;
      accessToken = cleanToken; // Mettre à jour aussi en mémoire
      logger.i('[$timestamp] ✅ Token brut stocké dans localStorage');

      // Stocker le JWT si disponible
      if (cleanJwt != null && cleanJwt.isNotEmpty) {
        html.window.localStorage[_docusignJwtKey] = cleanJwt;
        logger.i('[$timestamp] ✅ JWT stocké dans localStorage');
      }

      // Stocker l'ID du compte si disponible
      if (accountId != null && accountId.isNotEmpty) {
        html.window.localStorage[_docusignAccountIdKey] = accountId;
        logger.i('[$timestamp] ✅ ID de compte stocké dans localStorage');
      }

      // Gérer l'expiration
      if (expiryValue != null) {
        try {
          html.window.localStorage[_docusignExpiryKey] = expiryValue;
          logger.i(
              '[$timestamp] ✅ Expiration explicite stockée dans localStorage');
        } catch (e) {
          logger.w('[$timestamp] ⚠️ Erreur avec l\'expiration explicite: $e');
        }
      } else if (expiresIn != null) {
        final expiryTime =
            DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
        html.window.localStorage[_docusignExpiryKey] = expiryTime.toString();
        logger
            .i('[$timestamp] ✅ Expiration calculée stockée dans localStorage');
      }

      // Vérifier que les données ont bien été stockées
      logger.i('[$timestamp] ✅ Vérification des données stockées:');
      logger.i(
          '[$timestamp] ✅ - Token brut: ${html.window.localStorage[_docusignTokenKey] != null ? "OK" : "Manquant"}');
      logger.i(
          '[$timestamp] ✅ - JWT: ${html.window.localStorage[_docusignJwtKey] != null ? "OK" : "Manquant"}');
      logger.i(
          '[$timestamp] ✅ - ID de compte: ${html.window.localStorage[_docusignAccountIdKey] != null ? "OK" : "Manquant"}');
      logger.i(
          '[$timestamp] ✅ - Expiration: ${html.window.localStorage[_docusignExpiryKey] != null ? "OK" : "Manquant"}');

      logger.i('[$timestamp] ✅ Tokens traités et stockés avec succès');
      return true;
    } catch (e) {
      logger.e('❌ Erreur lors du traitement du token: $e');
      return false;
    }
  }

  // Méthode pour créer une enveloppe pour signature embarquée

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
      String? tokenToUse;
      final jwt = html.window.localStorage[_docusignJwtKey];
      if (jwt != null && jwt.isNotEmpty) {
        logger.i('[$timestamp] 🔑 Utilisation du JWT depuis localStorage');
        tokenToUse = jwt;
      } else {
        final docusignToken = html.window.localStorage[_docusignTokenKey];
        if (docusignToken == null || docusignToken.isEmpty) {
          logger.e('[$timestamp] ❌ Token DocuSign introuvable');
          throw Exception('Token DocuSign introuvable');
        }
        logger
            .i('[$timestamp] 🔑 Utilisation du token brut depuis localStorage');
        tokenToUse = docusignToken;
      }

      // AJOUT: Logger le token pour debugging
      logger.i(
          '[$timestamp] 📋 Token DocuSign (début): ${tokenToUse.substring(0, min(20, tokenToUse.length))}...');

      final authToken = await getAccessToken();

      // URL de retour par défaut si non fournie
      final finalReturnUrl = returnUrl ??
          '${ApiConfig.docuSignSigningReturnUrl}?envelopeId=$envelopeId&signing_complete=true';

      // Configuration de la requête
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer ${_cleanToken(tokenToUse)}',
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
        await logout();
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
      String? tokenToUse;
      final jwt = html.window.localStorage[_docusignJwtKey];
      if (jwt != null && jwt.isNotEmpty) {
        tokenToUse = jwt;
      } else {
        tokenToUse = html.window.localStorage[_docusignTokenKey];
      }

      if (tokenToUse == null || tokenToUse.isEmpty) {
        logger.e('[$timestamp] ❌ Token DocuSign introuvable');
        throw Exception('Token DocuSign introuvable');
      }

      final authToken = await getAccessToken();
      if (authToken == null || authToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token d\'authentification introuvable');
        throw Exception('Token d\'authentification introuvable');
      }

      // Configuration de la requête
      logger.i('🔧 Préparation des en-têtes pour la requête');
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer ${_cleanToken(tokenToUse)}',
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
        await logout();
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
      String? tokenToUse;
      final jwt = html.window.localStorage[_docusignJwtKey];
      if (jwt != null && jwt.isNotEmpty) {
        tokenToUse = jwt;
      } else {
        tokenToUse = html.window.localStorage[_docusignTokenKey];
      }

      if (tokenToUse == null || tokenToUse.isEmpty) {
        logger.e('[$timestamp] ❌ Token DocuSign introuvable');
        throw Exception('Token DocuSign introuvable');
      }

      final authToken = await getAccessToken();
      if (authToken == null || authToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token d\'authentification introuvable');
        throw Exception('Token d\'authentification introuvable');
      }

      // Configuration de la requête
      final options = Options(
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer ${_cleanToken(tokenToUse)}',
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
        await logout();
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

      // Récupérer le token d'authentification
      final authToken = await getAccessToken();
      if (authToken == null || authToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token d\'authentification introuvable');
        throw Exception('Token d\'authentification introuvable');
      }

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

  Future<Map<String, dynamic>> createEmbeddedEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
    String? documentName,
    String? documentType,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      logger.i('[$timestamp] 📝 Création d\'une enveloppe DocuSign'
          '\n└─ Signataire: $signerName ($signerEmail)'
          '\n└─ Titre: $title'
          '\n└─ Taille du document: ${documentBase64.length} caractères'
          '\n└─ Nom du document: ${documentName ?? "Auto-détecté"}'
          '\n└─ Type du document: ${documentType ?? "Auto-détecté"}');

      // 1. Vérifier si l'authentification est valide
      if (!await isAuthenticated()) {
        logger.e('[$timestamp] ❌ Non authentifié à DocuSign');
        throw Exception(
            'Non authentifié à DocuSign. Veuillez vous reconnecter.');
      }

      // 2. Récupérer les tokens
      // Priorité au JWT
      String? tokenToUse;

      final jwt = html.window.localStorage[_docusignJwtKey];
      if (jwt != null && jwt.isNotEmpty) {
        logger.i('[$timestamp] 🔑 Utilisation du JWT depuis localStorage');
        tokenToUse = jwt;
      } else {
        final docusignToken = html.window.localStorage[_docusignTokenKey];
        if (docusignToken == null || docusignToken.isEmpty) {
          logger
              .e('[$timestamp] ❌ Token DocuSign introuvable dans localStorage');
          throw Exception('Token DocuSign introuvable');
        }
        logger
            .i('[$timestamp] 🔑 Utilisation du token brut depuis localStorage');
        tokenToUse = docusignToken;
      }

      final cleanToken = _cleanToken(tokenToUse);
      logger.i('[$timestamp] 🔧 Token nettoyé, longueur: ${cleanToken.length}');

      // Récupérer le token d'authentification de l'application
      final authToken = await getAccessToken();
      if (authToken == null || authToken.isEmpty) {
        logger.e('[$timestamp] ❌ Token d\'authentification introuvable');
        throw Exception('Token d\'authentification introuvable');
      }

      // Configuration de la requête
      logger.i('[$timestamp] 🔧 Préparation des en-têtes pour la requête');
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-DocuSign-Token': 'Bearer $cleanToken',
        },
      );

      // Données à envoyer
      final data = {
        'documentBase64': documentBase64,
        'signerEmail': signerEmail,
        'signerName': signerName,
        'title': title,
      };

      // NOUVEAU: Ajouter le nom du document si fourni
      if (documentName != null && documentName.isNotEmpty) {
        data['documentName'] = documentName;
      }

      // NOUVEAU: Ajouter le type du document si fourni
      if (documentType != null && documentType.isNotEmpty) {
        data['documentType'] = documentType;
      }

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
        await logout();

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

  // Méthode pour récupérer un token d'authentification
  Future<String?> getAccessToken() async {
    try {
      // Vérifier d'abord dans localStorage
      final token = html.window.localStorage['auth_token'];

      if (token != null && token.isNotEmpty) {
        final timestamp = DateTime.now().toIso8601String();
        logger.i(
            '[$timestamp] ✅ Token d\'authentification récupéré depuis localStorage');
        return token;
      }

      logger.w(
          '⚠️ Aucun token d\'authentification trouvé, utilisation d\'un token temporaire pour le développement');
      return 'temp_dev_token_for_testing';
    } catch (e) {
      logger.e(
          '❌ Erreur lors de la récupération du token d\'authentification: $e');
      return null;
    }
  }
}
