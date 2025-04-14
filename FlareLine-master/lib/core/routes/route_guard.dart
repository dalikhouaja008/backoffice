import 'package:flutter/material.dart';
import 'package:flareline/core/services/session_service.dart';
import 'package:flareline/core/services/route_service.dart';

class RouteGuard {
  final SessionService _sessionService;
  
  RouteGuard(this._sessionService);
  
  Future<bool> canActivate(String routeName) async {
    // Routes publiques toujours accessibles
    if (['/signIn', '/signUp', '/resetPwd'].contains(routeName)) {
      return true;
    }
    
    final session = await _sessionService.getSession();
    
    // Si pas de session, rediriger vers login
    if (session == null) {
      return false;
    }
    
    // Vérifier si l'utilisateur a accès à cette route
    return RouteService.canAccessRoute(routeName, session.user.role);
  }
}