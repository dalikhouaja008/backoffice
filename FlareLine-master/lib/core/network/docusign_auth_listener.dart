import 'dart:html' as html;
import 'package:flareline/core/services/docusign_service.dart';
import 'package:logger/logger.dart';
import 'package:flareline/core/injection/injection.dart';

class DocuSignAuthListener {
  final DocuSignService _docuSignService;
  final Logger _logger;
  static DocuSignAuthListener? _instance;
  
  // Liste des callbacks à appeler lors de la réception d'un token
  final List<Function(String)> _authCallbacks = [];
  
  // Singleton
  static DocuSignAuthListener getInstance() {
    _instance ??= DocuSignAuthListener._();
    return _instance!;
  }
  
  DocuSignAuthListener._() 
    : _docuSignService = getIt<DocuSignService>(),
      _logger = getIt<Logger>() {
    _setupMessageListener();
  }
  
  void _setupMessageListener() {
    _logger.i('🔒 DocuSignAuthListener: Initialisation de l\'écouteur de messages');
    
    html.window.onMessage.listen((html.MessageEvent event) {
      _logger.i('📨 Message reçu: ${event.data.runtimeType}');
      
      try {
        // Vérifier si c'est un message de type Map
        if (event.data is Map) {
          final data = event.data;
          
          // Vérifier si c'est un message DocuSign
          if (data['type'] == 'DOCUSIGN_TOKEN') {
            final token = data['token'];
            final accountId = data['accountId'];
            final expiresIn = data['expiresIn'];
            
            if (token != null && token is String) {
              _logger.i('🔑 Token DocuSign reçu via postMessage');
              
              // Définir le token dans le service DocuSign
              _docuSignService.setAccessToken(token, expiresIn: expiresIn);
              
              // Notifier tous les callbacks enregistrés
              for (var callback in _authCallbacks) {
                callback(token);
              }
              
              _logger.i('✅ Token DocuSign traité avec succès');
            }
          }
        }
      } catch (e) {
        _logger.e('❌ Erreur lors du traitement du message: $e');
      }
    });
  }
  
  // Ajouter un callback à appeler lors de la réception d'un token
  void addAuthSuccessCallback(Function(String) callback) {
    _authCallbacks.add(callback);
    _logger.i('➕ Callback ajouté, total: ${_authCallbacks.length}');
  }
  
  // Supprimer un callback
  void removeAuthSuccessCallback(Function(String) callback) {
    _authCallbacks.remove(callback);
    _logger.i('➖ Callback retiré, total: ${_authCallbacks.length}');
  }
}