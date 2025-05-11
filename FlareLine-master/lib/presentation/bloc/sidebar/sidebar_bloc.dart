import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/services/menu_service.dart';
import 'package:flareline/core/services/session_service.dart';
import 'package:flareline/core/services/sidebar_service.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_event.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_state.dart';
import 'package:logger/logger.dart';

class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  final MenuService _menuService;
  final SessionService _sessionService;
  final Logger _logger;

  SidebarBloc({
    required MenuService menuService,
    required SessionService sessionService,
    required Logger logger,
  })  : _menuService = menuService,
        _sessionService = sessionService,
        _logger = logger,
        super(SidebarInitial()) {
    on<LoadSidebar>(_onLoadSidebar);
    on<RefreshSidebar>(_onRefreshSidebar);
    on<ToggleMenuItem>(_onToggleMenuItem);
  }

  Future<void> _onLoadSidebar(
    LoadSidebar event,
    Emitter<SidebarState> emit,
  ) async {
    emit(SidebarLoading());

    try {
      // IMPORTANT: Récupérer le rôle de l'utilisateur actuel
      final session = await _sessionService.getSession();
      final userRole = session?.user.role ?? 'guest'; // Par défaut "guest" si non connecté
      
      _logger.i('SidebarBloc: Chargement du menu pour le rôle: $userRole'
          '\n└─ Asset Path: ${event.assetPath}');
      
      // Utiliser votre MenuService pour filtrer le menu selon le rôle
      final menuData = await _menuService.getMenuForCurrentUser(event.assetPath);
      
      // Convertir les données brutes en objets MenuGroup
      final menuGroups = _convertToMenuGroups(menuData);
      
      _logger.i('SidebarBloc: Menu chargé avec succès'
          '\n└─ Groupes: ${menuGroups.length}'
          '\n└─ Rôle utilisateur: $userRole');
      
      emit(SidebarLoaded(menuGroups));
    } catch (e) {
      _logger.e('Erreur lors du chargement du sidebar', error: e);
      emit(SidebarError(e.toString()));
    }
  }

  Future<void> _onRefreshSidebar(
    RefreshSidebar event,
    Emitter<SidebarState> emit,
  ) async {
    // Si nous sommes déjà dans l'état chargé, récupérer le chemin du fichier
    final currentState = state;
    String? assetPath;
    
    if (currentState is SidebarLoaded) {
      // Réutiliser le même assetPath que lors du chargement initial
      // (Vous devriez stocker cette information dans le bloc ou l'état)
      assetPath = 'assets/routes/menu_route_en.json'; // Valeur par défaut
    }
    
    // Recharger le menu
    add(LoadSidebar(assetPath ?? 'assets/routes/menu_route_en.json'));
  }

  void _onToggleMenuItem(
    ToggleMenuItem event,
    Emitter<SidebarState> emit,
  ) {
    // Implémentation pour ouvrir/fermer un élément de menu (si nécessaire)
    // Cette méthode est facultative, selon vos besoins
  }

  // Méthode pour convertir les données du JSON en objets MenuGroup
  List<MenuGroup> _convertToMenuGroups(List<dynamic> menuData) {
    return menuData.map((groupData) {
      // Construire les éléments de menu pour ce groupe
      List<MenuItem> menuItems = (groupData['menuList'] as List)
          .map((itemData) => _createMenuItem(itemData))
          .toList();

      // Créer et retourner le groupe
      return MenuGroup(
        groupName: groupData['groupName'],
        menuList: menuItems,
        allowedRoles: _getRolesFromData(groupData['roles']),
      );
    }).toList();
  }

  // Créer un élément de menu à partir des données JSON
  MenuItem _createMenuItem(dynamic itemData) {
    // Traiter les sous-éléments s'ils existent
    List<MenuItem>? childList;
    if (itemData.containsKey('childList') && itemData['childList'] != null) {
      childList = (itemData['childList'] as List)
          .map((childData) => _createMenuItem(childData))
          .toList();
    }

    // Créer et retourner l'élément de menu
    return MenuItem(
      menuName: itemData['menuName'],
      icon: itemData['icon'] ?? '',
      path: itemData['path'],
      blank: itemData['blank'],
      allowedRoles: _getRolesFromData(itemData['roles']),
      childList: childList,
    );
  }

  // Convertir les rôles des données JSON en List<String>
  List<String> _getRolesFromData(dynamic roles) {
    if (roles == null) return ['all'];
    
    return (roles as List).map((role) => role.toString()).toList();
  }
}