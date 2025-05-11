import 'dart:convert';
import 'package:flutter/services.dart';

class MenuItem {
  final String menuName;
  final String icon;
  final String? path;
  final bool? blank;
  final List<String> allowedRoles;
  final List<MenuItem>? childList;

  MenuItem({
    required this.menuName,
    required this.icon,
    this.path,
    this.blank,
    required this.allowedRoles,
    this.childList,
  });
}

class MenuGroup {
  final String groupName;
  final List<MenuItem> menuList;
  final List<String> allowedRoles;

  MenuGroup({
    required this.groupName,
    required this.menuList,
    required this.allowedRoles,
  });
}

class SidebarService {
  // Méthode pour charger tout le menu sans filtrage par rôle
  static Future<List<MenuGroup>> loadMenu([String? assetPath]) async {
    try {
      // Charger le fichier JSON du menu
      final String menuJson = await rootBundle
          .loadString(assetPath ?? 'assets/routes/menu_route_en.json');
      final List<dynamic> menuData = json.decode(menuJson);

      // Convertir les données en objets MenuGroup sans filtrage
      return _convertToMenuGroups(menuData);
    } catch (e) {
      print('SidebarService: ❌ Error loading menu'
          '\n└─ Error: $e');
      return [];
    }
  }

  // Méthode statique pour charger le menu selon le rôle (pour compatibilité)
  static Future<List<MenuGroup>> getMenuForRole(String userRole) async {
    try {
      // Charger le fichier JSON du menu
      final String menuJson =
          await rootBundle.loadString('assets/routes/menu_route_en.json');
      final List<dynamic> menuData = json.decode(menuJson);

      // Filtrer le menu selon le rôle
      final List<dynamic> filteredData = _filterMenuByRole(menuData, userRole);

      // Convertir les données filtrées en objets MenuGroup
      return _convertToMenuGroups(filteredData);
    } catch (e) {
      print('SidebarService: ❌ Error getting menu for role $userRole'
          '\n└─ Error: $e');
      return [];
    }
  }

  // Méthode privée pour filtrer le menu selon le rôle
  static List<dynamic> _filterMenuByRole(
      List<dynamic> menuData, String userRole) {
    List<dynamic> filteredMenu = [];

    for (var group in menuData) {
      if (_hasAccess(group['roles'], userRole)) {
        Map<String, dynamic> filteredGroup = Map.from(group);
        List<dynamic> filteredMenuList = [];

        for (var menuItem in group['menuList']) {
          if (_hasAccess(menuItem['roles'], userRole)) {
            if (menuItem.containsKey('childList') &&
                menuItem['childList'] != null) {
              List<dynamic> filteredChildList = [];

              for (var childItem in menuItem['childList']) {
                if (_hasAccess(childItem['roles'], userRole)) {
                  filteredChildList.add(childItem);
                }
              }

              if (filteredChildList.isNotEmpty) {
                Map<String, dynamic> filteredMenuItem = Map.from(menuItem);
                filteredMenuItem['childList'] = filteredChildList;
                filteredMenuList.add(filteredMenuItem);
              }
            } else {
              filteredMenuList.add(menuItem);
            }
          }
        }

        if (filteredMenuList.isNotEmpty) {
          filteredGroup['menuList'] = filteredMenuList;
          filteredMenu.add(filteredGroup);
        }
      }
    }

    return filteredMenu;
  }

  // Vérifier si un utilisateur a accès selon son rôle
  static bool _hasAccess(List<dynamic>? roles, String userRole) {
    if (roles == null || roles.isEmpty) {
      return true; // Si aucun rôle n'est spécifié, accès pour tous
    }

    // Convertir le rôle utilisateur en minuscules pour la comparaison
    String lowerCaseUserRole = userRole.toLowerCase();

    return roles.any((role) =>
        role.toString().toLowerCase() == lowerCaseUserRole ||
        role.toString().toLowerCase() == 'all' ||
        lowerCaseUserRole == 'admin');
  }

  // Convertir les données filtrées en objets MenuGroup
  static List<MenuGroup> _convertToMenuGroups(List<dynamic> menuData) {
    return menuData.map<MenuGroup>((groupData) {
      List<MenuItem> menuItems = (groupData['menuList'] as List)
          .map<MenuItem>((itemData) => _createMenuItem(itemData))
          .toList();

      // Utiliser explicitement le paramètre allowedRoles avec la valeur de roles
      List<String> roles = _getRolesFromData(groupData['roles']);

      return MenuGroup(
        groupName: groupData['groupName'],
        menuList: menuItems,
        allowedRoles: roles, // Passage explicite du paramètre allowedRoles
      );
    }).toList();
  }

  // Créer un MenuItem à partir des données JSON
  static MenuItem _createMenuItem(dynamic itemData) {
    List<MenuItem>? childList;
    if (itemData.containsKey('childList') && itemData['childList'] != null) {
      childList = (itemData['childList'] as List)
          .map<MenuItem>((childData) => _createMenuItem(childData))
          .toList();
    }

    // Utiliser explicitement le paramètre allowedRoles avec la valeur de roles
    List<String> roles = _getRolesFromData(itemData['roles']);

    return MenuItem(
      menuName: itemData['menuName'],
      icon: itemData['icon'] ?? '',
      path: itemData['path'],
      blank: itemData['blank'],
      allowedRoles: roles, // Passage explicite du paramètre allowedRoles
      childList: childList,
    );
  }

  // Convertir les rôles des données JSON en List<String>
  static List<String> _getRolesFromData(dynamic roles) {
    if (roles == null) return ['all'];

    return (roles as List).map<String>((role) => role.toString()).toList();
  }

  // Méthode utilitaire pour vérifier si un utilisateur peut accéder à une route
  static bool canAccessRoute(
      String role, String route, List<MenuGroup> menuGroups) {
    // Un administrateur a accès à toutes les routes
    if (role == 'admin') return true;

    // Recherche de la route dans les menus
    for (var group in menuGroups) {
      for (var menuItem in group.menuList) {
        // Vérifier si cet élément correspond à la route
        if (menuItem.path == route) {
          return menuItem.allowedRoles.contains(role) ||
              menuItem.allowedRoles.contains('all');
        }

        // Vérifier dans les sous-éléments si nécessaire
        if (menuItem.childList != null) {
          for (var childItem in menuItem.childList!) {
            if (childItem.path == route) {
              return childItem.allowedRoles.contains(role) ||
                  childItem.allowedRoles.contains('all');
            }
          }
        }
      }
    }

    // Par défaut, si la route n'est pas trouvée dans le menu, autoriser l'accès
    // Vous pouvez modifier ce comportement selon vos besoins de sécurité
    return true;
  }
}
