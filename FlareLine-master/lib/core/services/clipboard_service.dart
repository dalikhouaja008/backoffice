import 'dart:html' as html;
import 'package:flutter/material.dart';

class ClipboardService {
  /// Copie le texte fourni dans le presse-papier et affiche un message si un BuildContext est fourni
  static void copyToClipboard(String text, {BuildContext? context}) {
    // Copier dans le presse-papier
    html.window.navigator.clipboard?.writeText(text);
    
    // Afficher un message si le contexte est fourni
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copié dans le presse-papier'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // Log de l'action
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ✅ Texte copié dans le presse-papier'
          '\n└─ User: nesssim'
          '\n└─ Content: ${text.length > 20 ? "${text.substring(0, 20)}..." : text}');
  }
}