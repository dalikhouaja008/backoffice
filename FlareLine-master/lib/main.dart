import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/core/theme/global_theme.dart';
import 'package:flareline_uikit/service/localization_provider.dart';
import 'package:flareline/routes.dart';
import 'package:flareline_uikit/service/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; 
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';


void main() async {
  //debugPaintSizeEnabled = true;
  // Assurez-vous que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser l'injection de dépendances
  setupInjection();
  
  // Initialiser le stockage
  await GetStorage.init();

  // Configuration pour les appareils mobiles
  if (GetPlatform.isMobile) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Configuration pour desktop
  if (GetPlatform.isDesktop && !GetPlatform.isWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1080, 720),
      minimumSize: Size(480, 360),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(_)),
        ChangeNotifierProvider(create: (_) => LocalizationProvider(_)),
      ],
      child: Builder(builder: (context) {
        context.read<LocalizationProvider>().supportedLocales =
            AppLocalizations.supportedLocales;
            
        return MaterialApp(
          navigatorKey: RouteConfiguration.navigatorKey,
          restorationScopeId: 'rootFlareLine',
          title: 'The boost',
          debugShowCheckedModeBanner: false,
          initialRoute: '/signIn',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: context.watch<LocalizationProvider>().locale,
          supportedLocales: AppLocalizations.supportedLocales,
          
          onGenerateRoute: (settings) =>
              RouteConfiguration.onGenerateRoute(settings),
          themeMode: context.watch<ThemeProvider>().isDark
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: GlobalTheme.lightThemeData,
          darkTheme: GlobalTheme.darkThemeData,
          builder: (context, widget) {
            // Utiliser un builder responsive amélioré
            final mediaQuery = MediaQuery.of(context);
            final isSmallScreen = mediaQuery.size.width < 600;
            
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.noScaling,
                // Ajuster le padding pour les petits écrans mobiles
                padding: isSmallScreen 
                  ? mediaQuery.padding.copyWith(
                      // Réduire le padding pour maximiser l'espace sur petit écran
                      left: mediaQuery.padding.left * 0.8,
                      right: mediaQuery.padding.right * 0.8,
                    ) 
                  : mediaQuery.padding,
              ),
              child: widget!,
            );
          },
        );
      }),
    );
  }
}