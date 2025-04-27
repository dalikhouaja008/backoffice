import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:logger/logger.dart';
import 'package:flareline/core/services/docusign_service.dart';

class DocuSignErrorHandler extends StatefulWidget {
  const DocuSignErrorHandler({super.key});

  @override
  _DocuSignErrorHandlerState createState() => _DocuSignErrorHandlerState();
}

class _DocuSignErrorHandlerState extends State<DocuSignErrorHandler> {
  String _errorMessage = "Une erreur s'est produite";
  String _details = "";
  final Logger _logger = getIt<Logger>();

  @override
  void initState() {
    super.initState();
    _processErrorParameters();
  }

  void _processErrorParameters() {
    final timestamp = '2025-04-27 09:39:18';
    final currentUser = 'nesssim';
    
    try {
      // Obtenir l'URL actuelle et ses paramètres
      final uri = Uri.parse(html.window.location.href);
      final params = uri.queryParameters;

      // Afficher les paramètres reçus dans la console pour débogage
      _logger.e('[$timestamp] [$currentUser] ❌ Erreur DocuSign - Paramètres reçus: $params');

      // Obtenir les détails de l'erreur
      final error = params['error'] ?? "Erreur inconnue";
      final code = params['code'] ?? "Code non disponible";
      final state = params['state'] ?? "État non disponible";

      setState(() {
        _errorMessage = "Erreur d'authentification DocuSign";
        _details = "Message: $error\nCode: $code\nÉtat: $state";
      });

      // Stocker l'erreur dans localStorage pour référence
      html.window.localStorage['docusign_last_error'] = 
          'Erreur: $error, Code: $code, État: $state, Timestamp: $timestamp, User: $currentUser';
          
    } catch (e) {
      _logger.e('[$timestamp] [$currentUser] ❌ Erreur lors du traitement des paramètres d\'erreur: $e');
      setState(() {
        _errorMessage = "Erreur lors du traitement des paramètres";
        _details = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur d\'authentification DocuSign'),
        backgroundColor: Colors.red[800],
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
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _details,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: () {
                      getIt<DocuSignService>().initiateAuthentication();
                    },
                    child: const Text('Réessayer', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlobalColors.primary,
                      side: BorderSide(color: GlobalColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/expert_juridique');
                    },
                    child: const Text('Retour', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}