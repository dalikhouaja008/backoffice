import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/core/route_guard.dart';
import 'package:flareline/deferred_widget.dart';
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
//import 'package:flareline/presentation/pages/calendar/calendar_page.dart' deferred as calendar;
import 'package:flareline/presentation/pages/chart/chart_page.dart' deferred as chart;
import 'package:flareline/presentation/pages/dashboard/ecommerce_page.dart';
import 'package:flareline/presentation/pages/inbox/index.dart' deferred as inbox;
import 'package:flareline/presentation/pages/invoice/invoice_page.dart' deferred as invoice;
import 'package:flareline/presentation/pages/profile/profile_page.dart' deferred as profile;
import 'package:flareline/presentation/pages/resetpwd/reset_pwd_page.dart' deferred as resetPwd;
import 'package:flareline/presentation/pages/setting/settings_page.dart' deferred as settings;
import 'package:flareline/presentation/pages/table/tables_page.dart' deferred as tables;
import 'package:flareline/presentation/notaire/NotairePage.dart' as notaire;
import 'package:flareline/presentation/expert/ExpertPage.dart' as expert;

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
   {'routerPath': '/notaire', 'widget': notaire.NotairePage()},
  {'routerPath': '/expert', 'widget': expert.ExpertPage()},
];

class RouteConfiguration {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    String path = settings.name!;
    
    // Recherche de la page cible
    Map<String, Object>? map;
    try {
      map = MAIN_PAGES.firstWhere(
        (element) => element['routerPath'] == path,
        orElse: () => <String, Object>{},
      );
      
      if (map.isEmpty) {
        return null;
      }
    } catch (e) {
      return null;
    }
    
    Widget targetPage = map['widget'] as Widget;
    
    // Wrapper la page cible dans un widget qui vérifie les autorisations
    return NoAnimationMaterialPageRoute<void>(
      builder: (_) => AuthGuard(
        routeName: path,
        child: targetPage,
      ),
      settings: settings,
    );
  }
}

// Widget AuthGuard qui vérifie les autorisations lors de la construction
class AuthGuard extends StatefulWidget {
  final String routeName;
  final Widget child;
  
  const AuthGuard({Key? key, required this.routeName, required this.child}) : super(key: key);
  
  @override
  _AuthGuardState createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checking = true;
  bool _authorized = false;
  
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }
  
  Future<void> _checkAccess() async {
    final canAccess = await getIt<RouteGuard>().canActivate(widget.routeName);
    
    if (mounted) {
      setState(() {
        _checking = false;
        _authorized = canAccess;
      });
      
      if (!_authorized) {
        Future.microtask(() {
          Navigator.of(context).pushReplacementNamed('/signIn');
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return widget.child;
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
