// lib/core/routes/docusign_route_interceptor.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:logger/logger.dart';

/// Cette classe intercepte les navigations vers les routes DocuSign
/// et gère la transition depuis/vers ces routes sans utiliser Navigator
class DocuSignRouteInterceptor {
  static final Logger _logger = getIt<Logger>();
  
  /// Vérifie si l'URL actuelle est une route DocuSign
  /// et redirige vers la page appropriée
  static void handleCurrentUrl(BuildContext? context) {

    
    // Obtenir l'URL actuelle
    final currentUrl = html.window.location.href;
    
    // Vérifier si nous sommes sur une route DocuSign
    if (currentUrl.contains('/docusign-auth') || 
        currentUrl.contains('/docusign-auth-error')) {
      
      _logger.i(' 🔀 URL DocuSign détectée: ${currentUrl.split('?')[0]}');
      
      // Ne rien faire, la route sera gérée normalement
      
    } else {
      // Vérifier si nous avons des paramètres DocuSign dans l'URL
      // Par exemple après une redirection
      final uri = Uri.parse(currentUrl);
      final params = uri.queryParameters;
      
      if (params.containsKey('token') || params.containsKey('code') ||
          (params.containsKey('error') && params.containsKey('state'))) {
        
        _logger.i('🔄 Paramètres DocuSign détectés dans URL non-DocuSign');
        
        // Rediriger vers la route appropriée
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (params.containsKey('error')) {
            html.window.location.replace('/#/docusign-auth-error${uri.query.isNotEmpty ? "?${uri.query}" : ""}');
          } else {
            html.window.location.replace('/#/docusign-auth${uri.query.isNotEmpty ? "?${uri.query}" : ""}');
          }
        });
      }
    }
  }
  
  /// Naviguer vers une page sans utiliser Navigator (pour éviter les problèmes de GlobalKey)
  static void navigateToPath(String path) {

    
    _logger.i('🔄 Navigation HTML vers: $path');
    html.window.location.replace('/#$path');
  }
}