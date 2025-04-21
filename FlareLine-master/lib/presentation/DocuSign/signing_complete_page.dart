import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline_uikit/components/buttons/button_form.dart';

class SigningCompletePage extends StatefulWidget {
  const SigningCompletePage({Key? key}) : super(key: key);

  @override
  _SigningCompletePageState createState() => _SigningCompletePageState();
}

class _SigningCompletePageState extends State<SigningCompletePage> {
  @override
  void initState() {
    super.initState();
    // Essayer de fermer cette fenêtre et de communiquer avec la fenêtre parent
    _notifyParentAndClose();
  }

  void _notifyParentAndClose() {
    try {
      // Essayer d'envoyer un message à la fenêtre parent
      html.window.opener?.postMessage('signing_complete', '*');
      
      // Fermer cette fenêtre après un court délai
      Future.delayed(const Duration(seconds: 2), () {
        html.window.close();
      });
    } catch (e) {
      print('Erreur lors de la communication avec la fenêtre parent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: GlobalColors.success,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Signature terminée',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous pouvez maintenant fermer cette fenêtre et retourner à l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ButtonForm(
              btnText: 'Fermer cette fenêtre',
              type: ButtonType.primary.type,
              onPressed: () {
                html.window.close();
              },
            ),
          ],
        ),
      ),
    );
  }
}