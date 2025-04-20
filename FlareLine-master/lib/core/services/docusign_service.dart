import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flareline/core/config/api_config.dart';
import 'package:flareline/domain/entities/land_entity.dart';

class DocuSignService {
  String? accessToken;

  // Méthode pour initialiser l'authentification OAuth
  void initiateAuthentication() {
    final authUrl =
        Uri.parse('${ApiConfig.docuSignAuthUrl}/oauth/auth').replace(
      queryParameters: {
        'response_type': 'token', // Utiliser token au lieu de code
        'scope': 'signature',
        'client_id': ApiConfig.docuSignClientId,
        'redirect_uri':
            'https://localhost:8080', // Une URL locale que vous contrôlez
        'prompt': 'login',
      },
    );

    // Ouvrir l'URL d'authentification
    html.window.open(authUrl.toString(), 'DocuSign Authentication');
  }

  // Méthode pour traiter le code d'autorisation après redirection
  Future<bool> processAuthCode(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse(ApiConfig.docuSignTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': ApiConfig.docuSignClientId,
          'client_secret': ApiConfig.docuSignClientSecret,
          'redirect_uri': ApiConfig.docuSignRedirectUri
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
        html.window.localStorage['docusign_token'] = accessToken!;
        html.window.localStorage['docusign_token_expiry'] =
            expiryTime.toString();

        print('Authentification DocuSign réussie');
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

  // Vérifier si nous avons un token dans le stockage local et s'il est valide
  bool checkExistingAuth() {
    final storedToken = html.window.localStorage['docusign_token'];
    final expiryTimeStr = html.window.localStorage['docusign_token_expiry'];

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
          html.window.localStorage.remove('docusign_token');
          html.window.localStorage.remove('docusign_token_expiry');
        }
      } catch (e) {
        print('Erreur lors de la vérification du token: $e');
      }
    }
    return false;
  }

  // Déconnexion - effacer les tokens
  void logout() {
    accessToken = null;
    html.window.localStorage.remove('docusign_token');
    html.window.localStorage.remove('docusign_token_expiry');
  }

  // Vérification du statut d'une enveloppe
  Future<Map<String, dynamic>?> checkEnvelopeStatus(String envelopeId) async {
    if (accessToken == null) {
      final hasToken = checkExistingAuth();
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
      final hasToken = checkExistingAuth();
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

  // Création d'une URL d'envoi pour signature en ligne
  Future<String?> createEmbeddedSigningUrl(
      String envelopeId, String recipientId, String returnUrl) async {
    if (accessToken == null) {
      final hasToken = checkExistingAuth();
      if (!hasToken) return null;
    }

    try {
      final viewUrl =
          '${ApiConfig.docuSignBaseUrl}/v2.1/accounts/${ApiConfig.docuSignAccountId}/envelopes/$envelopeId/views/recipient';

      final viewRequest = {
        'authenticationMethod': 'None',
        'email':
            'signer@example.com', // L'email doit correspondre à un signataire existant
        'returnUrl': returnUrl, // URL où rediriger après la signature
        'userName':
            'Signataire', // Le nom doit correspondre à un signataire existant
        'clientUserId': recipientId // Identifiant pour la signature embarquée
      };

      final response = await http
          .post(Uri.parse(viewUrl),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'
              },
              body: json.encode(viewRequest))
          .timeout(Duration(seconds: ApiConfig.apiTimeout));

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['url']; // URL pour la signature embarquée
      } else {
        print(
            'Erreur lors de la création de l\'URL de signature: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la création de l\'URL de signature: $e');
      return null;
    }
  }

  // Ajout d'un document à une enveloppe existante
  Future<bool> addDocumentToEnvelope(String envelopeId, String documentBase64,
      String documentName, String documentId) async {
    if (accessToken == null) {
      final hasToken = checkExistingAuth();
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
      final hasToken = checkExistingAuth();
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

  // Récupération de la liste des enveloppes
  Future<List<Map<String, dynamic>>?> listEnvelopes(
      {String fromDate = '',
      String toDate = '',
      String status = '',
      int count = 100}) async {
    if (accessToken == null) {
      final hasToken = checkExistingAuth();
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
  bool get isAuthenticated {
    return accessToken != null || checkExistingAuth();
  }

  Future<String?> createSignatureRequest({
    required Land land,
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    String? secondarySignerEmail, // Paramètre optionnel
    String? secondarySignerName, // Paramètre optionnel
  }) async {
    if (accessToken == null) {
      final hasToken = checkExistingAuth();
      if (!hasToken) {
        print('Pas de token disponible');
        return null;
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
          'signers': <Map<String, dynamic>>[
            {
              'email': signerEmail,
              'name': signerName,
              'recipientId': '1',
              'routingOrder': '1',
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
        'status': 'sent'
      };

      // Ajouter un second signataire UNIQUEMENT si les deux paramètres secondaires sont fournis
      if (secondarySignerEmail != null && secondarySignerName != null) {
        (envelopeDefinition['recipients']['signers']
                as List<Map<String, dynamic>>)
            .add({
          'email': secondarySignerEmail,
          'name': secondarySignerName,
          'recipientId': '2',
          'routingOrder': '2',
          'tabs': {
            'signHereTabs': [
              {
                'documentId': '1',
                'pageNumber': '1',
                'xPosition': '400',
                'yPosition': '400'
              }
            ],
            'dateSignedTabs': [
              {
                'documentId': '1',
                'pageNumber': '1',
                'xPosition': '400',
                'yPosition': '450'
              }
            ]
          }
        });
      }

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
        print('Enveloppe créée avec succès. ID: $envelopeId');
        return envelopeId;
      } else {
        print(
            'Erreur lors de la création de l\'enveloppe: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la création de l\'enveloppe: $e');
      return null;
    }
  }
}
