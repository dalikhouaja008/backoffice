// lib/core/services/route_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';

class RouteService {
  // Obtenir la route initiale basée sur le rôle
  static String getInitialRouteForRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return '/'; // Dashboard admin
      case 'GEOMETRE':
        return '/geometre';
      case 'NOTAIRE':
        return '/notaire';
      case 'EXPERT_JURIDIQUE':
        return '/expert';
      default:
        return '/'; // Route par défaut
    }
  }

  // Vérifier si un rôle a accès à une route spécifique
  static bool canAccessRoute(String route, String role) {
    // Routes accessibles par tous les utilisateurs connectés
    final List<String> commonRoutes = ['/profile', '/settings'];
    
    // Routes accessibles seulement par certains rôles
    final Map<String, List<String>> roleRoutes = {
      'ADMIN': ['/', '/tools', '/contacts', '/invoice', '/tables', '/modal'],
      'GEOMETRE': ['/geometre', '/tools'],
      'NOTAIRE': ['/notaire', '/invoice'],
      'EXPERT_JURIDIQUE': ['/expert'],
    };

    // Routes publiques (non authentifiées)
    final List<String> publicRoutes = ['/signIn', '/signUp', '/resetPwd'];
    
    // Si c'est une route publique, autoriser l'accès
    if (publicRoutes.contains(route)) {
      return true;
    }
    
    // Si le rôle n'existe pas dans notre mapping
    if (!roleRoutes.containsKey(role.toUpperCase())) {
      return false;
    }
    
    // Vérifier si la route est accessible pour ce rôle ou si c'est une route commune
    return roleRoutes[role.toUpperCase()]!.contains(route) || commonRoutes.contains(route);
  }

  // Obtenir menu sidebar filtré par rôle
  static Future<List<dynamic>> getMenuItemsByRole(String role, BuildContext context) async {
    // Charger le fichier JSON du menu
    String jsonContent = await DefaultAssetBundle.of(context)
        .loadString('assets/routes/menu_route_en.json');
    
    List<dynamic> originalMenu = json.decode(jsonContent);
    
    // Si admin, retourner le menu complet
    if (role.toUpperCase() == 'ADMIN') {
      return originalMenu;
    }
    
    // Autrement, filtrer le menu selon le rôle
    List<dynamic> filteredMenu = [];
    
    for (var group in originalMenu) {
      List<dynamic> filteredMenuItems = [];
      
      for (var menuItem in group['menuList']) {
        String? path = menuItem['path'];
        
        // Si l'élément a un chemin et que l'utilisateur peut y accéder
        if (path != null && canAccessRoute(path, role)) {
          filteredMenuItems.add(menuItem);
        }
        // Si l'élément a des sous-éléments, les filtrer aussi
        else if (menuItem.containsKey('childList')) {
          List<dynamic> filteredChildItems = [];
          
          for (var childItem in menuItem['childList']) {
            if (canAccessRoute(childItem['path'], role)) {
              filteredChildItems.add(childItem);
            }
          }
          
          if (filteredChildItems.isNotEmpty) {
            var newMenuItem = Map<String, dynamic>.from(menuItem);
            newMenuItem['childList'] = filteredChildItems;
            filteredMenuItems.add(newMenuItem);
          }
        }
      }
      
      if (filteredMenuItems.isNotEmpty) {
        var newGroup = Map<String, dynamic>.from(group);
        newGroup['menuList'] = filteredMenuItems;
        filteredMenu.add(newGroup);
      }
    }
    
    return filteredMenu;
  }
}