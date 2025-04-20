// lib/presentation/pages/docusign_callback_page.dart

import 'package:flareline/core/services/docusign_service.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class DocuSignCallbackPage extends StatefulWidget {
  const DocuSignCallbackPage({Key? key}) : super(key: key);

  @override
  _DocuSignCallbackPageState createState() => _DocuSignCallbackPageState();
}

class _DocuSignCallbackPageState extends State<DocuSignCallbackPage> {
  bool _processing = true;
  bool _success = false;
  String _message = 'Traitement de l\'authentification...';

  @override
  void initState() {
    super.initState();
    _processAuthCode();
  }

  Future<void> _processAuthCode() async {
    final uri = Uri.parse(Uri.base.toString());
    final code = uri.queryParameters['code'];

    if (code == null) {
      setState(() {
        _processing = false;
        _success = false;
        _message = 'Erreur: Code d\'autorisation manquant.';
      });
      return;
    }

    final docuSignService = DocuSignService(); // Ou injectez votre instance

    try {
      final success = await docuSignService.processAuthCode(code);

      setState(() {
        _processing = false;
        _success = success;
        _message = success
            ? 'Authentification réussie. Redirection...'
            : 'Échec de l\'authentification.';
      });

      if (success) {
        // Rediriger vers la page précédente après un court délai
        Future.delayed(Duration(seconds: 2), () {
          // Remplacez par votre navigation appropriée
          context.go('/validation-juridique');
        });
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _success = false;
        _message = 'Erreur: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authentification DocuSign')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_processing) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                fontSize: 18,
                color: _success ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            if (!_processing && !_success)
              ElevatedButton(
                onPressed: () {
                  // Remplacez par votre navigation appropriée
                  context.go('/validation-juridique');
                },
                child: Text('Retour'),
              ),
          ],
        ),
      ),
    );
  }
}
