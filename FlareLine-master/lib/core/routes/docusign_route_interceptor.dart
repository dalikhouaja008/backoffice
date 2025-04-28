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
  
  // Pour stocker la page d'origine avant l'authentification DocuSign
  static String _originPage = '/expert_juridique'; // Page par défaut
  
  /// Mémoriser la page d'origine avant de lancer l'authentification
  static void setOriginPage(String path) {
    _logger.i('📌 Mémorisation de la page d\'origine: $path');
    _originPage = path;
    
    // Sauvegarder aussi dans localStorage pour persistance
    html.window.localStorage['docusign_origin_page'] = path;
  }
  
  /// Récupérer la page d'origine
  static String getOriginPage() {
    // D'abord essayer de récupérer depuis localStorage
    final storedPage = html.window.localStorage['docusign_origin_page'];
    if (storedPage != null && storedPage.isNotEmpty) {
      return storedPage;
    }
    return _originPage;
  }
  
  /// Vérifie si l'URL actuelle est une route DocuSign
  /// et redirige vers la page appropriée
  static void handleCurrentUrl(BuildContext? context) {
    // Obtenir l'URL actuelle
    final currentUrl = html.window.location.href;
    
    // Vérifier si nous sommes sur une route DocuSign
    if (currentUrl.contains('/docusign-auth') || 
        currentUrl.contains('/docusign-auth-error')) {
      
      _logger.i('🔀 URL DocuSign détectée: ${currentUrl.split('?')[0]}');
      
      // Ne rien faire, la route sera gérée normalement
      
    } else {
      // Vérifier si nous avons des paramètres DocuSign dans l'URL
      final uri = Uri.parse(currentUrl);
      final params = uri.queryParameters;
      
      if (params.containsKey('token') || params.containsKey('code') ||
          (params.containsKey('error') && params.containsKey('state'))) {
        
        _logger.i('🔄 Paramètres DocuSign détectés dans URL non-DocuSign');
        
        // Stocker la page actuelle comme origine
        if (!currentUrl.contains('/docusign')) {
          final currentPath = uri.path;
          if (currentPath.isNotEmpty) {
            setOriginPage(currentPath);
          }
        }
        
        // Rediriger vers la route appropriée
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (params.containsKey('error')) {
            html.window.location.replace('/#/docusign-auth-error${uri.query.isNotEmpty ? "?" + uri.query : ""}');
          } else {
            html.window.location.replace('/#/docusign-auth${uri.query.isNotEmpty ? "?" + uri.query : ""}');
          }
        });
      }
    }
  }
  
  /// Naviguer vers une page sans utiliser Navigator (pour éviter les problèmes de GlobalKey)
  static void navigateToPath(String path) {
    _logger.i(' 🔄 Navigation HTML vers: $path');
    html.window.location.replace('/#$path');
  }
  
  /// Retourne à la page d'origine après l'authentification
  static void returnToOriginPage() {
    final originPage = getOriginPage();
    _logger.i('🔙 Retour à la page d\'origine: $originPage');
    navigateToPath(originPage);
    
    // Nettoyage optionnel
    html.window.localStorage.remove('docusign_origin_page');
  }
}