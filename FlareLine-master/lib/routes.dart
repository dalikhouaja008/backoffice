import 'package:flareline/deferred_widget.dart';
import 'dart:html' as html;
import 'package:flareline/presentation/DocuSign/docusign_auth_handler.dart';
import 'package:flareline/presentation/DocuSign/docusign_error_handler.dart';
import 'package:flareline/presentation/expert_juridique/ExpertJuridiquePage.dart' as expert_juridique;
import 'package:flareline/presentation/expert_juridique/juridical_validation_page.dart';
import 'package:flareline/presentation/geometre/GeometrePage.dart' as geometre;
import 'package:flareline/presentation/pages/modal/modal_page.dart' deferred as modal;
import 'package:flareline/presentation/pages/table/contacts_page.dart' deferred as contacts;
import 'package:flareline/presentation/pages/toast/toast_page.dart' deferred as toast;
import 'package:flareline/presentation/pages/tools/tools_page.dart' deferred as tools;
import 'package:flutter/material.dart';
//import 'package:flareline/presentation/pages/alerts/alert_page.dart' deferred as alert;
import 'package:flareline/presentation/pages/button/button_page.dart' deferred as button;
import 'package:flareline/presentation/pages/form/form_elements_page.dart' deferred as formElements;
import 'package:flareline/presentation/pages/form/form_layout_page.dart' deferred as formLayout;
import 'package:flareline/presentation/pages/auth/sign_in/sign_in_page.dart' deferred as signIn;
import 'package:flareline/presentation/pages/auth/sign_up/sign_up_page.dart' deferred as signUp;
import 'package:flareline/presentation/pages/calendar/calendar_page.dart' deferred as calendar;
import 'package:flareline/presentation/pages/chart/chart_page.dart' deferred as chart;
import 'package:flareline/presentation/pages/dashboard/ecommerce_page.dart';
import 'package:flareline/presentation/pages/inbox/index.dart' deferred as inbox;
import 'package:flareline/presentation/pages/invoice/invoice_page.dart' deferred as invoice;
import 'package:flareline/presentation/pages/profile/profile_page.dart' deferred as profile;
import 'package:flareline/presentation/pages/resetpwd/reset_pwd_page.dart' deferred as resetPwd;
import 'package:flareline/presentation/pages/setting/settings_page.dart' deferred as settings;
import 'package:flareline/presentation/pages/table/tables_page.dart' deferred as tables;

typedef PathWidgetBuilder = Widget Function(BuildContext, String?);

final List<Map<String, Object>> MAIN_PAGES = [
  {'routerPath': '/', 'widget': const EcommercePage()},
  //{'routerPath': '/calendar', 'widget': DeferredWidget(calendar.loadLibrary, () => calendar.CalendarPage())},
  {'routerPath': '/profile', 'widget': DeferredWidget(profile.loadLibrary, () => profile.ProfilePage())},
  {
    'routerPath': '/formElements',
    'widget': DeferredWidget(formElements.loadLibrary, () => formElements.FormElementsPage()),
  },
  {'routerPath': '/formLayout', 'widget': DeferredWidget(formLayout.loadLibrary, () => formLayout.FormLayoutPage())},
  {'routerPath': '/signIn', 'widget': DeferredWidget(signIn.loadLibrary, () => signIn.SignInWidget())},
  {'routerPath': '/signUp', 'widget': DeferredWidget(signUp.loadLibrary, () => signUp.SignUpWidget())},
  {
    'routerPath': '/resetPwd',
    'widget': DeferredWidget(resetPwd.loadLibrary, () => resetPwd.ResetPwdWidget()),
  },
  {'routerPath': '/invoice', 'widget': DeferredWidget(invoice.loadLibrary, () => invoice.InvoicePage())},
  {'routerPath': '/inbox', 'widget': DeferredWidget(inbox.loadLibrary, () => inbox.InboxWidget())},
  {'routerPath': '/tables', 'widget': DeferredWidget(tables.loadLibrary, () => tables.TablesPage())},
  {'routerPath': '/settings', 'widget': DeferredWidget(settings.loadLibrary, () => settings.SettingsPage())},
  {'routerPath': '/basicChart', 'widget': DeferredWidget(chart.loadLibrary, () => chart.ChartPage())},
  {'routerPath': '/buttons', 'widget': DeferredWidget(button.loadLibrary, () => button.ButtonPage())},
  //{'routerPath': '/alerts', 'widget': DeferredWidget(alert.loadLibrary, () => alert.AlertPage())},
  {'routerPath': '/contacts', 'widget': DeferredWidget(contacts.loadLibrary, () => contacts.ContactsPage())},
  {'routerPath': '/tools', 'widget': DeferredWidget(tools.loadLibrary, () => tools.ToolsPage())},
  {'routerPath': '/toast', 'widget': DeferredWidget(toast.loadLibrary, () => toast.ToastPage())},
  {
    'routerPath': '/modal',
    'widget': DeferredWidget(modal.loadLibrary, () => modal.ModalPage())
  },
 {
    'routerPath': '/geometre',
    'widget': geometre.GeometrePage(),
  },
  {
    'routerPath': '/expert_juridique',
    'widget': expert_juridique.ExpertJuridiquePage(),
  },

];

class RouteConfiguration {
  // Utilisez un debugLabel unique
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'MainNavigator_2025-04-27');

  static BuildContext? get navigatorContext =>
      navigatorKey.currentState?.context;

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
  ) {
    String path = settings.name!;
    
    // IMPORTANT: Traiter les routes DocuSign séparément
    if (path == '/docusign-auth') {
      // Créer une nouvelle instance à chaque fois SANS RÉUTILISER DE CLÉ
      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => DocuSignAuthHandler(key: UniqueKey()),
        settings: settings,
      );
    }
    
    if (path == '/docusign-auth-error') {
      // Créer une nouvelle instance à chaque fois SANS RÉUTILISER DE CLÉ
      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => DocuSignErrorHandler(key: UniqueKey()),
        settings: settings,
      );
    }

    // Pour les autres routes, utiliser la méthode habituelle
    try {
      final map = MAIN_PAGES.firstWhere((element) => element['routerPath'] == path);
      final Widget targetPage = map['widget'] as Widget;

      builder(context, match) {
        return targetPage;
      }

      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => builder(context, null),
        settings: settings,
      );
    } catch (e) {
      // Route non trouvée
      print('Route non trouvée: $path');
      return null;
    }
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

// Ajout d'une fonction utilitaire pour la navigation DocuSign sans utiliser Navigator
// (utilisez cette fonction dans vos pages DocuSign au lieu de Navigator)
void navigateToPath(String path) {
  html.window.location.replace('/#$path');
}