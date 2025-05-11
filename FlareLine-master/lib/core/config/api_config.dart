import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Configuration DocuSign (conservée telle quelle)
  static const String docuSignClientId = 'd956403b-d435-4cca-9763-53489f61dd6c';
  static const String docuSignClientSecret = '35df48ab-cf3e-4803-9da0-2b38435467e2';
  static const String docuSignAccountId = '223ae6ff-abea-4646-bf09-9a83a53432df';

  // URLs DocuSign (conservées telles quelles)
  static const String docuSignBaseUrl = 'https://demo.docusign.net/restapi';
  static const String docuSignAuthUrl = 'https://account-d.docusign.com';
  static const String docuSignTokenUrl = 'https://account-d.docusign.com/oauth/token';
  
  // URL de redirection pour environnement de développement local (conservée)
  static const String docuSignRedirectUri = 'http://localhost:8080/callback.html';
  
  // URL de retour après signature (conservée)
  static const String docuSignSigningReturnUrl = 'http://localhost:8080/signing-complete.html';

  // Autres configurations (conservées)
  static const int apiTimeout = 30;

  // Ports pour les services
  static const int landServicePort = 5000;
  static const int userManagementPort = 3000;
  
  // URL de base du service Land
  static String get landServiceUrl {
    return _getPlatformSpecificUrl(landServicePort);
  }
  
  // URL de base du service User Management (et GraphQL)
  static String get userManagementUrl {
    return _getPlatformSpecificUrl(userManagementPort);
  }
  
  // Endpoint GraphQL complet
  static String get graphqlEndpoint {
    return '$userManagementUrl/graphql';
  }
  
  // URL de base de l'API pour rétrocompatibilité
  static String get apiBaseUrl {
    return landServiceUrl;
  }
  
  // Méthode privée pour générer l'URL appropriée selon la plateforme
  static String _getPlatformSpecificUrl(int port) {
    if (kIsWeb) {
      return 'http://localhost:$port';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:$port';
    } else {
      return 'http://localhost:$port';
    }
  }
}