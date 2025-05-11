import 'package:flareline/core/services/sidebar_service.dart';
import 'package:flutter/material.dart';

class RouteService {
  static Map<String, List<String>> _routePermissions = {};
  static bool _initialized = false;

  // Méthode pour initialiser les permissions des routes
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Charger tous les menus
      List<MenuGroup> allMenuGroups = await SidebarService.loadMenu();

      // Construire la map des permissions
      for (var group in allMenuGroups) {
        for (var menuItem in group.menuList) {
          _addRoutePermissions(menuItem);
        }
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing route permissions: $e');
    }
  }

  // Méthode récursive pour ajouter les permissions de routes
  static void _addRoutePermissions(MenuItem menuItem) {
    // Si cet élément a un chemin, ajouter ses permissions
    if (menuItem.path != null && menuItem.path!.isNotEmpty) {
      _routePermissions[menuItem.path!] = menuItem.allowedRoles;
    }

    // Si cet élément a des enfants, traiter chaque enfant
    if (menuItem.childList != null) {
      for (var child in menuItem.childList!) {
        _addRoutePermissions(child);
      }
    }
  }

  // Vérifier si un utilisateur a accès à une route spécifique
  static bool canAccessRoute(String role, String route) {
    // Si les routes n'ont pas été initialisées, essayer d'initialiser synchronement
    if (!_initialized) {
      // Attention : cette approche est moins fiable, il vaut mieux appeler initialize() au démarrage de l'app
      print(
          'Warning: RouteService not initialized, permission check may be inaccurate');
      return true; // Par défaut, autoriser l'accès si non initialisé
    }

    // Si la route n'existe pas dans les permissions, considérer qu'elle est accessible à tous
    if (!_routePermissions.containsKey(route)) return true;

    // Si c'est un admin, il a accès à tout
    if (role == 'admin') return true;

    // Vérifier si le rôle est dans la liste des rôles autorisés
    return _routePermissions[route]!.contains(role) ||
        _routePermissions[route]!.contains('all');
  }

  // Obtenir la route initiale en fonction du rôle
  static String getInitialRouteForRole(String role) {
    // Les administrateurs vont au dashboard
    if (role == 'admin') return '/';

    // Les géomètres vont à leur page spécifique
    if (role == 'geometre') return '/geometre';

    // Les experts juridiques vont à leur page spécifique
    if (role == 'expert_juridique') return '/expert_juridique';

    // Les chefs de projet vont à leur page spécifique
    if (role == 'project_manager') return '/project';

    // Par défaut, aller au dashboard
    return '/';
  }

  // Méthode utilitaire pour obtenir toutes les routes accessibles à un rôle
  static List<String> getAccessibleRoutesForRole(String role) {
    if (!_initialized) {
      // Si non initialisé, retourner une liste vide
      print(
          'Warning: RouteService not initialized, no accessible routes returned');
      return [];
    }

    // Si c'est un admin, il a accès à toutes les routes
    if (role == 'admin') {
      return _routePermissions.keys.toList();
    }

    // Filtrer les routes accessibles au rôle
    return _routePermissions.entries
        .where((entry) =>
            entry.value.contains(role) || entry.value.contains('all'))
        .map((entry) => entry.key)
        .toList();
  }

  // Méthode pour vérifier si une route est accessible et rediriger si nécessaire
  static String? getRedirectIfNotAccessible(String role, String route) {
    // Si les routes n'ont pas été initialisées ou si l'utilisateur a accès
    if (!_initialized || canAccessRoute(role, route)) {
      return null; // Pas besoin de redirection
    }

    // Sinon, rediriger vers la route initiale du rôle
    return getInitialRouteForRole(role);
  }

  // Méthode pour naviguer vers une route en vérifiant les permissions
  static Future<void> navigateIfAuthorized(
      BuildContext context, String role, String route) async {
    // Vérifier l'accès à la route
    if (canAccessRoute(role, route)) {
      // Naviguer vers la route demandée
      Navigator.of(context).pushNamed(route);
    } else {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous n\'avez pas accès à cette page.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
