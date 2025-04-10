import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveProvider extends ChangeNotifier {
  // Seuils de taille pour définir le type d'appareil
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  
  // Variables pour stocker l'état actuel
  DeviceType _currentDeviceType = DeviceType.desktop;
  Size _currentScreenSize = const Size(0, 0);
  
  // Getters
  DeviceType get currentDeviceType => _currentDeviceType;
  Size get currentScreenSize => _currentScreenSize;
  
  // Mettre à jour les données responsive en fonction du contexte
  void updateDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    
    // Mettre à jour la taille d'écran si changée
    if (screenSize != _currentScreenSize) {
      _currentScreenSize = screenSize;
      
      // Déterminer le type d'appareil
      if (screenSize.width <= mobileMaxWidth) {
        _currentDeviceType = DeviceType.mobile;
      } else if (screenSize.width <= tabletMaxWidth) {
        _currentDeviceType = DeviceType.tablet;
      } else {
        _currentDeviceType = DeviceType.desktop;
      }
      
      // Notifier les widgets qui écoutent
      notifyListeners();
    }
  }
  
  // Obtenir le type d'appareil actuel
  DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width <= mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width <= tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  // Vérifier si l'appareil est mobile
  bool isMobile(BuildContext context) => 
      getDeviceType(context) == DeviceType.mobile;
  
  // Vérifier si l'appareil est une tablette
  bool isTablet(BuildContext context) => 
      getDeviceType(context) == DeviceType.tablet;
  
  // Vérifier si l'appareil est un desktop
  bool isDesktop(BuildContext context) => 
      getDeviceType(context) == DeviceType.desktop;
  
  // Adapter une valeur en fonction du type d'appareil
  T adaptiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? desktop;
      case DeviceType.desktop:
        return desktop;
    }
  }
  
  // Obtenir une valeur mise à l'échelle en fonction de la taille de l'écran
  double getScaledValue(BuildContext context, double baseValue) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 1080; // Base de référence: 1080px
    
    // Limiter les valeurs extrêmes
    final limitedFactor = scaleFactor.clamp(0.7, 1.3);
    
    return baseValue * limitedFactor;
  }
  
  // Obtenir un padding adapté au type d'appareil
  EdgeInsets getAdaptivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(8.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(12.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(16.0);
    }
  }
}