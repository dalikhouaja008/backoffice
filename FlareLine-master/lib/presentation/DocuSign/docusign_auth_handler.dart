import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flareline/core/routes/docusign_route_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flareline/core/theme/global_colors.dart';
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

  // Utiliser getIt.get pour éviter les instances potentiellement dupliquées
  Logger get _logger => getIt.get<Logger>();
  // Remplacer DocuSignService par DocuSignRemoteDataSource
  DocuSignRemoteDataSource get _docuSignDataSource =>
      getIt.get<DocuSignRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    // Important: utiliser addPostFrameCallback pour éviter les problèmes de setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processAuthParameters();
    });
  }

  Future<void> _processAuthParameters() async {
    final timestamp = '2025-04-27 22:44:35';
    final currentUser = 'nesssim';

    try {
      _logger.i(
          '[$timestamp] [$currentUser] 🔍 Traitement des paramètres DocuSign');

      // Obtenir l'URL actuelle et ses paramètres
      final uri = Uri.parse(html.window.location.href);
      final params = uri.queryParameters;

      _logger.i('[$timestamp] [$currentUser] 📝 Paramètres reçus: $params');
      setState(() {
        final urlString = uri.toString();
        _details =
            "URL: ${urlString.substring(0, math.min(100, urlString.length))}...\nParams: $params";
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
        _logger.i(
            '[$timestamp] [$currentUser] ✅ Token reçu: ${token.substring(0, math.min(10, token.length))}...');

        // Stocker le token
        await _docuSignDataSource.setAccessToken(token,
            expiresIn: expiresIn, accountId: accountId);

        // Stocker les données supplémentaires pour la compatibilité
        await _docuSignDataSource.processReceivedToken(token,
            accountId: accountId,
            expiresIn: expiresIn,
            expiryValue:
                (DateTime.now().millisecondsSinceEpoch + expiresIn * 1000)
                    .toString());

        setState(() {
          _processing = false;
          _success = true;
          _message = "Authentification DocuSign réussie!";
          _details += "\nToken stocké avec succès";
        });
      }
      // Cas 2: Code d'autorisation
      else if (code != null && code.isNotEmpty) {
        _logger.i(
            '[$timestamp] [$currentUser] 🔄 Traitement du code d\'autorisation');

        setState(() {
          _message = "Échange du code d'autorisation...";
        });

        // Note: DocuSignRemoteDataSource n'a pas de méthode similaire à processAuthCode
        // Un processus alternatif serait nécessaire ici

        // Pour maintenir la compatibilité, on peut utiliser l'API pour échanger le code
        // Ceci nécessite une implémentation dans DocuSignRemoteDataSource
        throw Exception(
            'La fonctionnalité d\'échange de code d\'autorisation n\'est pas implémentée dans DocuSignRemoteDataSource');
      }
      // Cas 3: Aucun paramètre valide
      else {
        throw Exception(
            'Aucun token ou code d\'autorisation trouvé dans l\'URL');
      }

      // Attendre un peu avant de rediriger
      await Future.delayed(const Duration(seconds: 2));

      // IMPORTANT: Utiliser la navigation sans provoquer d'effets secondaires
      if (mounted) {
        _redirectToMainPage();
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

  void _handleErrorParameters(
      Map<String, String> params, String timestamp, String currentUser) {
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
  }

  void _redirectToMainPage() {
    // Au lieu d'aller directement à expert_juridique, retourner à la page d'origine
    DocuSignRouteInterceptor.returnToOriginPage();
  }

  void _retryAuthentication() {
    _docuSignDataSource.initiateAuthentication();
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
                    color: _success
                        ? Colors.green[700]
                        : _processing
                            ? Colors.black
                            : Colors.red[700],
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
                  _success
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            minimumSize: const Size(200, 50),
                          ),
                          onPressed: () =>
                              DocuSignRouteInterceptor.returnToOriginPage(),
                          child: const Text(
                            'Continuer',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GlobalColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                              ),
                              onPressed: _retryAuthentication,
                              child: const Text('Réessayer',
                                  style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GlobalColors.primary,
                                side: BorderSide(color: GlobalColors.primary),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                              ),
                              onPressed: () => html.window.location
                                  .replace('/#/expert_juridique'),
                              child: const Text('Retour',
                                  style: TextStyle(fontSize: 16)),
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
