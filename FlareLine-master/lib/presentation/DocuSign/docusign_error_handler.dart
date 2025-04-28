// lib/presentation/DocuSign/docusign_auth_handler.dart
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/core/services/docusign_service.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:logger/logger.dart';

class DocuSignAuthHandler extends StatefulWidget {
  const DocuSignAuthHandler({super.key});

  @override
  State<DocuSignAuthHandler> createState() => _DocuSignAuthHandlerState();
}

class _DocuSignAuthHandlerState extends State<DocuSignAuthHandler> {
  bool _processing = true;
  bool _success = false;
  String _message = "Traitement de l'authentification DocuSign...";
  String _details = "";
  String _token = ""; // Pour stocker le token
  
  // Utiliser getIt.get pour éviter les instances potentiellement dupliquées
  Logger get _logger => getIt.get<Logger>();
  DocuSignService get _docuSignService => getIt.get<DocuSignService>();
  DocuSignRemoteDataSource get _dataSource => getIt.get<DocuSignRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    // Important: utiliser addPostFrameCallback pour éviter les problèmes de setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processAuthParameters();
    });
  }

  Future<void> _processAuthParameters() async {
    final timestamp = '2025-04-27 23:51:44';
    final currentUser = 'nesssim';
    
    try {
      _logger.i('[$timestamp] [$currentUser] 🔍 Traitement des paramètres DocuSign');
      
      // Obtenir l'URL actuelle et ses paramètres
      final uri = Uri.parse(html.window.location.href);
      final params = uri.queryParameters;

      _logger.i('[$timestamp] [$currentUser] 📝 Paramètres reçus: $params');
      setState(() {
        final urlString = uri.toString();
        _details = "URL: ${urlString.substring(0, math.min(100, urlString.length))}...\nParams: $params";
      });

      // Vérifier s'il s'agit d'une erreur
      if (params.containsKey('error')) {
        _handleErrorParameters(params, timestamp, currentUser);
        return;
      }

      // Obtenir le token et autres paramètres
      final token = params['token'];
      final jwt = params['jwt'];
      final code = params['code']; 
      final expiresIn = int.tryParse(params['expires_in'] ?? '3600') ?? 3600;
      final accountId = params['account_id'];

      // Cas 1: Token direct
      if (token != null && token.isNotEmpty) {
        _logger.i('[$timestamp] [$currentUser] ✅ Token reçu: ${token.substring(0, math.min(10, token.length))}...');
        
        // Stocker le token dans le service
        _docuSignService.setAccessToken(token, expiresIn: expiresIn);
        
        // Stocker les données supplémentaires dans localStorage
        if (jwt != null) html.window.localStorage['docusign_jwt'] = jwt;
        if (accountId != null) html.window.localStorage['docusign_account_id'] = accountId;
        
        // Sauvegarder aussi via le datasource
        await _dataSource.saveTokenFromLocalStorage();
        
        setState(() {
          _processing = false;
          _success = true;
          _message = "Authentification DocuSign réussie!";
          _details += "\nToken stocké avec succès";
          // Stocker une version tronquée du token pour l'affichage
          _token = token.substring(0, math.min(20, token.length)) + "...";
        });
      } 
      // Cas 2: Code d'autorisation
      else if (code != null && code.isNotEmpty) {
        _logger.i('[$timestamp] [$currentUser] 🔄 Traitement du code d\'autorisation');
        
        setState(() {
          _message = "Échange du code d'autorisation...";
        });
        
        final success = await _docuSignService.processAuthCode(code);
        
        if (success) {
          _logger.i('[$timestamp] [$currentUser] ✅ Code échangé avec succès');
          
          // Sauvegarder les tokens
          await _dataSource.saveTokenFromLocalStorage();
          
          // Récupérer le token pour l'afficher
          final storedToken = html.window.localStorage['docusign_token'] ?? "Token non disponible";
          
          setState(() {
            _processing = false;
            _success = true;
            _message = "Authentification DocuSign réussie!";
            _details += "\nCode échangé avec succès";
            _token = storedToken.length > 20 
                ? storedToken.substring(0, 20) + "..." 
                : storedToken;
          });
        } else {
          throw Exception('Échec de l\'échange du code d\'autorisation');
        }
      } 
      // Cas 3: Aucun paramètre valide
      else {
        throw Exception('Aucun token ou code d\'autorisation trouvé dans l\'URL');
      }
      
    } catch (e) {
      _logger.e('[$timestamp] [$currentUser] ❌ Erreur: $e');
      if (mounted) {
        setState(() {
          _processing = false;
          _success = false;
          _message = "Erreur d'authentification DocuSign";
          _details += "\nErreur: $e";
        });
      }
    }
  }
  
  void _handleErrorParameters(Map<String, String> params, String timestamp, String currentUser) {
    final error = params['error'] ?? "Erreur inconnue";
    final code = params['code'] ?? "Non disponible";
    final state = params['state'] ?? "Non disponible";
    
    _logger.e('[$timestamp] [$currentUser] ❌ Erreur DocuSign: $error');
    
    setState(() {
      _processing = false;
      _success = false;
      _message = "Erreur d'authentification DocuSign";
      _details = "Message: $error\nCode: $code\nÉtat: $state";
    });
    
    html.window.localStorage['docusign_last_error'] = 
        'Erreur: $error, Code: $code, État: $state, Timestamp: $timestamp, User: $currentUser';
  }

  // Ferme la fenêtre actuelle et notifie la fenêtre parent si elle existe
  void _closeAndNotifyParent() {
    try {
      // Essayer de notifier la fenêtre parente (si elle existe)
      if (html.window.opener != null) {
        // Envoyer un message à la fenêtre parente avec le token
        html.window.opener!.postMessage({
          'type': 'docusign_auth_success',
          'token': html.window.localStorage['docusign_token'] ?? '',
          'jwt': html.window.localStorage['docusign_jwt'] ?? '',
          'accountId': html.window.localStorage['docusign_account_id'] ?? '',
        }, '*');
        
        _logger.i('[2025-04-27 23:51:44] [nesssim] 📤 Message envoyé à la fenêtre parente');
        
        // Fermer cette fenêtre après un court délai
        Future.delayed(const Duration(seconds: 1), () {
          html.window.close();
        });
      } else {
        _logger.w('[2025-04-27 23:51:44] [nesssim] ⚠️ Pas de fenêtre parente détectée');
      }
    } catch (e) {
      _logger.e('[2025-04-27 23:51:44] [nesssim] ❌ Erreur lors de la communication avec la fenêtre parente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_success 
            ? 'Authentification DocuSign' 
            : _processing 
                ? 'Traitement en cours' 
                : 'Erreur DocuSign'),
        backgroundColor: _success 
            ? GlobalColors.primary 
            : _processing 
                ? GlobalColors.primary 
                : Colors.red[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Pas de bouton retour
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_processing)
                  CircularProgressIndicator(color: GlobalColors.primary)
                else
                  Icon(
                    _success ? Icons.check_circle_outline : Icons.error_outline,
                    color: _success ? Colors.green : Colors.red,
                    size: 80,
                  ),
                const SizedBox(height: 24),
                Text(
                  _message,
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w500,
                    color: _success ? Colors.green[700] : _processing ? Colors.black : Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Affichage du token tronqué pour débogage
                if (_success && _token.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Token DocuSign:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _token,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_details.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _details,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (!_processing)
                  _success
                    ? Column(
                        children: [
                          Text(
                            "Vous pouvez maintenant fermer cette fenêtre et retourner à l'application principale.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              minimumSize: const Size(200, 50),
                            ),
                            onPressed: _closeAndNotifyParent,
                            child: const Text(
                              'Fermer et retourner',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onPressed: () => _docuSignService.initiateAuthentication(),
                            child: const Text('Réessayer', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GlobalColors.primary,
                              side: BorderSide(color: GlobalColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onPressed: _closeAndNotifyParent,
                            child: const Text('Fermer', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}