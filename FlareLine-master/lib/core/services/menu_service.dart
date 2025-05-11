import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flareline/core/services/session_service.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

class MenuService {
  final SessionService _sessionService;
  final Logger _logger;

  MenuService({
    required SessionService sessionService,
    required Logger logger,
  })  : _sessionService = sessionService,
        _logger = logger;

  // Chargement et filtrage du menu selon le rôle de l'utilisateur et le chemin du fichier
  Future<List<dynamic>> getMenuForCurrentUser([String? assetPath]) async {
    try {
      // Obtenir la session actuelle
      final session = await _sessionService.getSession();

      if (session == null) {
        _logger.w('MenuService: Aucune session trouvée, menu vide retourné');
        return [];
      }

      final userRole = session.user.role;
      _logger.i('MenuService: Chargement du menu pour le rôle: $userRole');

      // Charger le fichier JSON du menu
      final String menuJson = await rootBundle
          .loadString(assetPath ?? 'assets/routes/menu_route_en.json');
      final List<dynamic> menuData = json.decode(menuJson);

      // Filtrer le menu selon le rôle
      return _filterMenuByRole(menuData, userRole);
    } catch (e) {
      _logger.e('MenuService: Erreur lors du chargement du menu', error: e);
      return [];
    }
  }

  // Méthode pour filtrer le menu selon le rôle
  List<dynamic> _filterMenuByRole(List<dynamic> menuData, String userRole) {
    List<dynamic> filteredMenu = [];

    for (var group in menuData) {
      // Vérifier si ce groupe est accessible au rôle de l'utilisateur
      if (_hasAccess(group['roles'], userRole)) {
        // Créer une copie du groupe pour le filtrage
        Map<String, dynamic> filteredGroup = Map.from(group);
        List<dynamic> filteredMenuList = [];

        // Filtrer les éléments du menu dans ce groupe
        for (var menuItem in group['menuList']) {
          if (_hasAccess(menuItem['roles'], userRole)) {
            // Si l'élément a des sous-éléments, les filtrer également
            if (menuItem.containsKey('childList')) {
              List<dynamic> filteredChildList = [];

              for (var childItem in menuItem['childList']) {
                if (_hasAccess(childItem['roles'], userRole)) {
                  filteredChildList.add(childItem);
                }
              }

              // N'ajouter l'élément parent que s'il reste des sous-éléments après filtrage
              if (filteredChildList.isNotEmpty) {
                Map<String, dynamic> filteredMenuItem = Map.from(menuItem);
                filteredMenuItem['childList'] = filteredChildList;
                filteredMenuList.add(filteredMenuItem);
              }
            } else {
              // Élément sans sous-éléments, l'ajouter directement
              filteredMenuList.add(menuItem);
            }
          }
        }

        // N'ajouter le groupe que s'il reste des éléments après filtrage
        if (filteredMenuList.isNotEmpty) {
          filteredGroup['menuList'] = filteredMenuList;
          filteredMenu.add(filteredGroup);
        }
      }
    }

    return filteredMenu;
  }

  // Vérifier si un utilisateur a accès selon son rôle
  bool _hasAccess(List<dynamic>? roles, String userRole) {
    if (roles == null || roles.isEmpty) {
      return true; // Si aucun rôle n'est spécifié, accès pour tous
    }

    // Convertir le rôle utilisateur en minuscules pour la comparaison
    String lowerCaseUserRole = userRole.toLowerCase();

    // Vérifier si le rôle existe en ignorant la casse
    return roles.any((role) =>
        role.toString().toLowerCase() == lowerCaseUserRole ||
        role.toString().toLowerCase() == 'all' ||
        lowerCaseUserRole == 'admin');
  }
}
