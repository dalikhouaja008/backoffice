import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

/// Classe utilitaire pour détecter les plateformes de manière compatible avec le web
class PlatformUtils {
  /// Vérifie si l'application s'exécute sur le web
  static bool get isWeb => kIsWeb;

  /// Vérifie si l'application s'exécute sur mobile (Android ou iOS)
  static bool get isMobile => !kIsWeb && (GetPlatform.isAndroid || GetPlatform.isIOS);

  /// Vérifie si l'application s'exécute sur desktop (Windows, macOS, Linux)
  static bool get isDesktop => !kIsWeb && GetPlatform.isDesktop;

  /// Vérifie si l'application s'exécute sur Windows
  static bool get isWindows => !kIsWeb && GetPlatform.isWindows;

  /// Vérifie si l'application s'exécute sur macOS
  static bool get isMacOS => !kIsWeb && GetPlatform.isMacOS;

  /// Vérifie si l'application s'exécute sur Linux
  static bool get isLinux => !kIsWeb && GetPlatform.isLinux;

  /// Vérifie si l'application s'exécute sur Android
  static bool get isAndroid => !kIsWeb && GetPlatform.isAndroid;

  /// Vérifie si l'application s'exécute sur iOS
  static bool get isIOS => !kIsWeb && GetPlatform.isIOS;

  /// Vérifie si le code est exécuté dans un environnement sans accès au système de fichiers
  static bool get hasNoFileSystem => kIsWeb;
}