class ApiConfig {
  // Configuration DocuSign
  static const String docuSignClientId = 'd956403b-d435-4cca-9763-53489f61dd6c'; 
  static const String docuSignClientSecret = '35df48ab-cf3e-4803-9da0-2b38435467e2';
  static const String docuSignAccountId = '223ae6ff-abea-4646-bf09-9a83a53432df';

  // URLs DocuSign
  static const String docuSignBaseUrl = 'https://demo.docusign.net/restapi';
  static const String docuSignAuthUrl = 'https://account-d.docusign.com';
  static const String docuSignTokenUrl = 'https://account-d.docusign.com/oauth/token';
  
  // URL de redirection pour environnement de développement local
  static const String docuSignRedirectUri = 'http://localhost:8080/callback.html';
  
  // URL de retour après signature (également pour environnement local)
  static const String docuSignSigningReturnUrl = 'http://localhost:8080/signing-complete.html';

  // Autres configurations
  static const int apiTimeout = 30;

  static var apiBaseUrl= "http://localhost:5000";


}