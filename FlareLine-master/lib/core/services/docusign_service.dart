import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flareline/core/config/api_config.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';

class DocuSignService {
  String? accessToken;
  final SecureStorageService _secureStorage;
  final Logger _logger;

  // Clés pour le stockage sécurisé
  static const String _tokenKey = 'docusign_token';
  static const String _tokenExpiryKey = 'docusign_token_expiry';
  static const String _codeVerifierKey = 'docusign_code_verifier';

  DocuSignService({SecureStorageService? secureStorage, Logger? logger})
      : _secureStorage = secureStorage ?? getIt<SecureStorageService>(),
        _logger = logger ?? getIt<Logger>();

  void initiateAuthentication() {
    try {
      final redirectUri = Uri.encodeComponent(ApiConfig.docuSignRedirectUri);

      print("=== DÉBUT AUTHENTIFICATION DOCUSIGN ===");
      print("Client ID: ${ApiConfig.docuSignClientId}");
      print("URI de redirection (brut): ${ApiConfig.docuSignRedirectUri}");
      print("URI de redirection (encodé): $redirectUri");

      // URL d'authentification simple sans PKCE (le proxy gèrera le PKCE)
      final authUrl = '${ApiConfig.docuSignAuthUrl}/oauth/auth'
          '?response_type=code'
          '&scope=signature%20extended'
          '&client_id=${ApiConfig.docuSignClientId}'
          '&redirect_uri=$redirectUri'
          '&prompt=consent';

      print("URL d'authentification complète: $authUrl");

      // Ouvrir la page dans une nouvelle fenêtre
      html.WindowBase? authWindow = html.window.open(authUrl, 'DocuSignAuth',
          'width=800,height=600,resizable=yes,scrollbars=yes,status=yes');

      if (authWindow == null || authWindow.closed == true) {
        print("ERREUR: La fenêtre d'authentification a été bloquée");
        html.window.location.href = authUrl;
      } else {
        print("Fenêtre d'authentification ouverte avec succès");
      }
    } catch (e) {
      print("ERREUR lors de l'authentification DocuSign: $e");
    }
  }

  Future<void> clearToken() async {
    accessToken = null;
    try {
      await Future.wait([
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _tokenExpiryKey),
        _secureStorage.delete(key: _codeVerifierKey),
      ]);
      print("Token DocuSign effacé");
    } catch (e) {
      print("Erreur lors de l'effacement du token: $e");
    }
  }

  // Méthode pour traiter le code d'autorisation après redirection
  Future<bool> processAuthCode(String code) async {
    try {
      // Récupérer le code_verifier stocké
      final codeVerifier = await _secureStorage.read(key: _codeVerifierKey);
      if (codeVerifier == null) {
        print("ERREUR: Code verifier non trouvé dans le stockage sécurisé");
        return false;
      }

      print("Code Verifier récupéré: ${codeVerifier.substring(0, 10)}...");

      final tokenResponse = await http.post(
        Uri.parse(ApiConfig.docuSignTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': ApiConfig.docuSignClientId,
          'client_secret': ApiConfig.docuSignClientSecret,
          'redirect_uri': ApiConfig.docuSignRedirectUri,
          'code_verifier': codeVerifier // Ajout du code_verifier pour PKCE
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        accessToken = tokenData['access_token'];
        final expiresIn = tokenData['expires_in'] as int? ?? 3600;
        final expiryTime = DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch;

        // Stocker le token et sa date d'expiration
        await Future.wait([
          _secureStorage.write(key: _tokenKey, value: accessToken!),
          _secureStorage.write(
              key: _tokenExpiryKey, value: expiryTime.toString()),
        ]);

        // Nettoyer le code_verifier une fois utilisé
        await _secureStorage.delete(key: _codeVerifierKey);

        print('Authentification DocuSign réussie avec PKCE');
        return true;
      } else {
        print('Erreur d\'authentification: ${tokenResponse.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'authentification DocuSign: $e');
      return false;
    }
  }

  // Le reste de la classe reste inchangé
  // Vérifier si nous avons un token dans le stockage sécurisé et s'il est valide
  Future<bool> checkExistingAuth() async {
    final storedToken = await _secureStorage.read(key: _tokenKey);
    final expiryTimeStr = await _secureStorage.read(key: _tokenExpiryKey);

    if (storedToken != null &&
        storedToken.isNotEmpty &&
        expiryTimeStr != null) {
      try {
        final expiryTime = int.parse(expiryTimeStr);
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now < expiryTime) {
          accessToken = storedToken;
          return true;
        } else {
          // Token expiré, supprimer
          await Future.wait([
            _secureStorage.delete(key: _tokenKey),
            _secureStorage.delete(key: _tokenExpiryKey),
          ]);
        }
      } catch (e) {
        print('Erreur lors de la vérification du token: $e');
      }
    }
    return false;
  }

  // Déconnexion - effacer les tokens
  Future<void> logout() async {
    accessToken = null;
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _tokenExpiryKey),
      _secureStorage.delete(key: _codeVerifierKey),
    ]);
  }

  // Vérification du statut d'une enveloppe
  Future<Map<String, dynamic>?> checkEnvelopeStatus(String envelopeId) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) return null;
    }

    try {
      final statusUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes/$envelopeId';

      final response = await http.get(Uri.parse(statusUrl), headers: {
        'Authorization': 'Bearer $accessToken'
      }).timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'status': responseData['status'],
          'created': responseData['createdDateTime'],
          'sent': responseData['sentDateTime'],
          'delivered': responseData['deliveredDateTime'],
          'completed': responseData['completedDateTime'],
          'declined': responseData['declinedDateTime'],
          'recipients': responseData['recipients'],
        };
      } else {
        print(
            'Erreur lors de la vérification du statut: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la vérification du statut: $e');
      return null;
    }
  }

  // Récupération du document signé
  Future<String?> getSignedDocument(String envelopeId) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) return null;
    }

    try {
      final documentUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes/$envelopeId/documents/combined';

      final response = await http.get(Uri.parse(documentUrl), headers: {
        'Authorization': 'Bearer $accessToken'
      }).timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        // Créer un blob à partir des données du document
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Déclencher le téléchargement du fichier
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'document_signe_$envelopeId.pdf')
          ..click();

        // Nettoyer l'URL de l'objet
        html.Url.revokeObjectUrl(url);

        print('Document signé téléchargé');
        return url; // Retourner l'URL du blob (temporaire)
      } else {
        print(
            'Erreur lors de la récupération du document: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération du document: $e');
      return null;
    }
  }

  // Ajout d'un document à une enveloppe existante
  Future<bool> addDocumentToEnvelope(String envelopeId, String documentBase64,
      String documentName, String documentId) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) return false;
    }

    try {
      final documentUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes/$envelopeId/documents';

      final document = {
        'documentBase64': documentBase64,
        'name': documentName,
        'fileExtension': 'pdf',
        'documentId': documentId,
      };

      final response = await http
          .put(Uri.parse(documentUrl),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'
              },
              body: json.encode(document))
          .timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        print('Document ajouté avec succès à l\'enveloppe: $envelopeId');
        return true;
      } else {
        print(
            'Erreur lors de l\'ajout du document: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'ajout du document: $e');
      return false;
    }
  }

  // Annulation d'une enveloppe
  Future<bool> voidEnvelope(String envelopeId, String voidReason) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) return false;
    }

    try {
      final voidUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes/$envelopeId';

      final voidRequest = {'status': 'voided', 'voidedReason': voidReason};

      final response = await http
          .put(Uri.parse(voidUrl),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'
              },
              body: json.encode(voidRequest))
          .timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        print('Enveloppe annulée avec succès: $envelopeId');
        return true;
      } else {
        print(
            'Erreur lors de l\'annulation de l\'enveloppe: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'annulation de l\'enveloppe: $e');
      return false;
    }
  }

  Future<void> setAccessToken(String token, {int? expiresIn}) async {
    try {
      // Assigner le token à la variable du service
      accessToken = token;
      print(
          "Token d'accès défini: ${token.substring(0, min(10, token.length))}...");

      // Stocker également dans le stockage sécurisé pour la persistance
      await _secureStorage.write(key: _tokenKey, value: token);

      // Gérer l'expiration
      int expiryTime;
      if (expiresIn != null) {
        expiryTime = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      } else {
        // Valeur par défaut: 1 heure
        expiryTime = DateTime.now().millisecondsSinceEpoch + (3600 * 1000);

        // Essayer de lire l'expiration existante
        final existingExpiry = await _secureStorage.read(key: _tokenExpiryKey);
        if (existingExpiry != null) {
          expiryTime = int.tryParse(existingExpiry) ?? expiryTime;
        }
      }

      await _secureStorage.write(
          key: _tokenExpiryKey, value: expiryTime.toString());

      print(
          "Token stocké avec expiration: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}");
    } catch (e) {
      print("Erreur lors de la définition du token: $e");
    }
  }

  // Récupération de la liste des enveloppes
  Future<List<Map<String, dynamic>>?> listEnvelopes(
      {String fromDate = '',
      String toDate = '',
      String status = '',
      int count = 100}) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) return null;
    }

    try {
      var queryParams = 'count=$count';
      if (fromDate.isNotEmpty) queryParams += '&from_date=$fromDate';
      if (toDate.isNotEmpty) queryParams += '&to_date=$toDate';
      if (status.isNotEmpty) queryParams += '&status=$status';

      final envelopesUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes?$queryParams';

      final response = await http.get(Uri.parse(envelopesUrl), headers: {
        'Authorization': 'Bearer $accessToken'
      }).timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['envelopes'] ?? []);
      } else {
        print(
            'Erreur lors de la récupération des enveloppes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération des enveloppes: $e');
      return null;
    }
  }

  // Vérification de l'état de l'authentification (utile pour l'UI)
  Future<bool> get isAuthenticated async {
    return accessToken != null || await checkExistingAuth();
  }

  Future<Map<String, dynamic>> createEnvelopeForEmbeddedSigning({
    required Land land,
    required String documentBase64,
    required String signerEmail,
    required String signerName,
  }) async {
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) {
        return {'success': false, 'error': 'Non authentifié'};
      }
    }

    try {
      // Préparer la définition de l'enveloppe
      final Map<String, dynamic> envelopeDefinition = {
        'emailSubject': 'Validation juridique du terrain: ${land.title}',
        'documents': [
          {
            'documentBase64': documentBase64,
            'name': 'Validation Juridique - ${land.title}',
            'fileExtension': 'pdf',
            'documentId': '1'
          }
        ],
        'recipients': {
          'signers': [
            {
              'email': signerEmail,
              'name': signerName,
              'recipientId': '1',
              'routingOrder': '1',
              'clientUserId': '1001', // Crucial pour la signature intégrée
              'tabs': {
                'signHereTabs': [
                  {
                    'documentId': '1',
                    'pageNumber': '1',
                    'xPosition': '200',
                    'yPosition': '400'
                  }
                ],
                'dateSignedTabs': [
                  {
                    'documentId': '1',
                    'pageNumber': '1',
                    'xPosition': '200',
                    'yPosition': '450'
                  }
                ]
              }
            }
          ]
        },
        'status': 'created' // Important: "created" et non "sent"
      };

      // Envoi de la requête à l'API DocuSign
      final envelopeUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes';

      final response = await http
          .post(Uri.parse(envelopeUrl),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'
              },
              body: json.encode(envelopeDefinition))
          .timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final envelopeId = responseData['envelopeId'];
        print(
            'Enveloppe créée pour signature intégrée avec succès. ID: $envelopeId');
        return {
          'success': true,
          'envelopeId': envelopeId,
        };
      }
      // Gérer spécifiquement les erreurs d'authentification
      else if (response.statusCode == 401 || response.statusCode == 403) {
        // Tenter de rafraîchir le token
        final tokenRefreshed = await handleExpiredToken();
        if (tokenRefreshed) {
          // Réessayer la requête avec le nouveau token
          return createEnvelopeForEmbeddedSigning(
            land: land,
            documentBase64: documentBase64,
            signerEmail: signerEmail,
            signerName: signerName,
          );
        } else {
          return {
            'success': false,
            'error': 'Token expiré, veuillez vous reconnecter à DocuSign'
          };
        }
      } else {
        print(
            'Erreur lors de la création de l\'enveloppe: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error':
              'Erreur lors de la création de l\'enveloppe: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Exception lors de la création de l\'enveloppe: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createEmbeddedSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
  }) async {
    // Vérifier si nous avons un token d'accès DocuSign valide
    if (accessToken == null) {
      final hasToken = await checkExistingAuth();
      if (!hasToken) {
        return {'success': false, 'error': 'Non authentifié à DocuSign'};
      }
    }

    try {
      // URL de l'API backend
      final url = '${ApiConfig.apiBaseUrl}/docusign/embedded-signing';

      // URL de retour après signature
      final returnUrl =
          '${ApiConfig.docuSignSigningReturnUrl}?envelopeId=$envelopeId&signing_complete=true';

      // Données à envoyer
      final Map<String, dynamic> data = {
        'envelopeId': envelopeId,
        'signerEmail': signerEmail,
        'signerName': signerName,
        'returnUrl': returnUrl,
      };

      // Récupération du token d'authentification général de l'application
      final appToken = await _secureStorage.getAccessToken();

      // En-têtes avec les tokens distincts
      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${appToken ?? ''}', // Token d'authentification général
        'X-DocuSign-Token': 'Bearer $accessToken', // Token DocuSign spécifique
      };

      print(
          'Envoi de la requête à $url avec token DocuSign: ${accessToken!.substring(0, min(10, accessToken!.length))}...');

      // Appel à l'API de votre backend
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final signingUrl = responseData['signingUrl'];
          print('URL de signature obtenue avec succès: $signingUrl...');

          return {
            'success': true,
            'signingUrl': signingUrl,
          };
        } else {
          print('Erreur retournée par l\'API: ${responseData['error']}');
          return {
            'success': false,
            'error': responseData['error'] ?? 'Erreur inconnue'
          };
        }
      } else {
        print('Erreur HTTP ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Exception lors de la création de l\'URL de signature: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> refreshToken() async {
    try {
      _logger.i('🔄 Tentative de rafraîchissement du token DocuSign');

      // Récupérer le refresh token s'il existe
      final refreshToken =
          await _secureStorage.read(key: 'docusign_refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('⚠️ Aucun refresh token disponible pour DocuSign');
        return false;
      }

      // Appel à l'API pour rafraîchir le token
      final tokenResponse = await http.post(
        Uri.parse(ApiConfig.docuSignTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': ApiConfig.docuSignClientId,
          'client_secret': ApiConfig.docuSignClientSecret,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        final newAccessToken = tokenData['access_token'];
        final newRefreshToken = tokenData['refresh_token'] ?? refreshToken;
        final expiresIn = tokenData['expires_in'] as int? ?? 3600;

        // Mettre à jour les tokens dans le stockage sécurisé
        await setAccessToken(newAccessToken, expiresIn: expiresIn);

        // Stocker également le nouveau refresh token
        await _secureStorage.write(
            key: 'docusign_refresh_token', value: newRefreshToken);

        _logger.i('✅ Token DocuSign rafraîchi avec succès');
        return true;
      } else {
        _logger.e(
            '❌ Échec du rafraîchissement du token: ${tokenResponse.statusCode} - ${tokenResponse.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Exception lors du rafraîchissement du token: $e');
      return false;
    }
  }

// Méthode pour gérer le token expiré lors des requêtes
  Future<bool> handleExpiredToken() async {
    _logger.w('⚠️ Token DocuSign expiré, tentative de rafraîchissement');

    // Effacer le token actuel
    accessToken = null;

    // Tenter de rafraîchir le token
    final refreshed = await refreshToken();

    if (!refreshed) {
      _logger.w(
          '🚫 Échec du rafraîchissement du token, redirection vers l\'authentification');
      // Nettoyer les informations d'authentification expirées
      await logout();
      return false;
    }

    return true;
  }
}
