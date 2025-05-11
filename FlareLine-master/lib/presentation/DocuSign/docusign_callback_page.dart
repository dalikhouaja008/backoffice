import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:logger/logger.dart';

class DocuSignCallbackPage extends StatefulWidget {
  const DocuSignCallbackPage({super.key});

  @override
  _DocuSignCallbackPageState createState() => _DocuSignCallbackPageState();
}

class _DocuSignCallbackPageState extends State<DocuSignCallbackPage> {
  bool _processing = true;
  bool _success = false;
  String _message = "Traitement de l'authentification DocuSign...";
  String _details = "";
  final Logger _logger = getIt<Logger>();
  // Remplacer DocuSignService par DocuSignRemoteDataSource
  final DocuSignRemoteDataSource _docuSignDataSource = getIt<DocuSignRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _processAuthParameters();
  }

  Future<void> _processAuthParameters() async {
    final timestamp = '2025-04-27 20:25:29';
    final currentUser = 'nesssim';
    
    try {
      _logger.i('[$timestamp] [$currentUser] 🔍 Traitement des paramètres d\'authentification DocuSign');
      
      // Obtenir l'URL actuelle et ses paramètres
      final uri = Uri.parse(html.window.location.href);
      final params = uri.queryParameters;

      // Afficher les paramètres reçus pour le débogage
      _logger.i('[$timestamp] [$currentUser] 📝 Paramètres reçus: $params');
      setState(() {
        _details = "URL: ${uri.toString().substring(0, 100)}...\nParams: $params";
      });

      // Obtenir le token et autres paramètres
      final token = params['token'];
      final jwt = params['jwt'];
      final code = params['code']; // Certains flux utilisent un code au lieu d'un token
      final expiresIn = int.tryParse(params['expires_in'] ?? '3600') ?? 3600;
      final accountId = params['account_id'];

      // Stratégie 1: Utiliser le token directement s'il est disponible
      if (token != null && token.isNotEmpty) {
        _logger.i('[$timestamp] [$currentUser] ✅ Token reçu directement: ${token.substring(0, 10)}...');
        
        // Stocker le token et les autres informations
        await _docuSignDataSource.setAccessToken(token, expiresIn: expiresIn, accountId: accountId);
        
        // Traiter complètement le token reçu
        await _docuSignDataSource.processReceivedToken(
          token, 
          accountId: accountId, 
          expiresIn: expiresIn,
          expiryValue: (DateTime.now().millisecondsSinceEpoch + expiresIn * 1000).toString()
        );
        
        setState(() {
          _processing = false;
          _success = true;
          _message = "Authentification DocuSign réussie!";
          _details += "\nToken stocké avec succès";
        });
        
        // Attendre un peu avant de rediriger
        await Future.delayed(const Duration(seconds: 2));
        _redirectToMainPage();
        
      } 
      // Stratégie 2: Utiliser le code d'autorisation si disponible
      else if (code != null && code.isNotEmpty) {
        _logger.i('[$timestamp] [$currentUser] 🔄 Code d\'autorisation reçu, échange en cours...');
        
        setState(() {
          _message = "Échange du code d'autorisation...";
          _details += "\nRemarque: L'échange de code n'est pas implémenté dans DocuSignRemoteDataSource";
        });
        
        // Note: DocuSignRemoteDataSource n'a pas de méthode directe pour échanger un code
        // Pour cette démo, nous simulons un échec
        throw Exception("L'échange de code d'autorisation n'est pas pris en charge dans cette version");
      } 
      // Aucun paramètre valide trouvé
      else {
        throw Exception('Aucun token ou code d\'autorisation valide trouvé');
      }
    } catch (e) {
      // En cas d'erreur
      _logger.e('[$timestamp] [$currentUser] ❌ Erreur DocuSign Auth Handler: $e');
      setState(() {
        _processing = false;
        _success = false;
        _message = "Erreur d'authentification DocuSign";
        _details += "\nErreur: $e";
      });
    }
  }

  void _redirectToMainPage() {
    Navigator.of(context).pushReplacementNamed('/expert_juridique');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification DocuSign'),
        backgroundColor: GlobalColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
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
                  color: _success ? Colors.green[700] : Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: _redirectToMainPage,
                  child: Text(
                    _success ? 'Continuer' : 'Retour',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}