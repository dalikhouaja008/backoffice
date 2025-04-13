// FlareLine-UiKit/lib/core/event/global_event.dart
import 'package:flareline_uikit/core/event/event_bus.dart';
import 'package:flareline_uikit/core/event/event_info.dart';

class GlobalEvent {
  static final EventBus eventBus = EventBus();
  
  // Méthodes standard avec eventType
  static void fireEvent(String eventName, [dynamic data]) {
    eventBus.fire(EventInfo(
      eventName: eventName,
      eventType: eventName, // Utiliser eventName comme eventType par défaut
      data: data,
    ));
  }
  
  // Méthodes avec eventType explicite
  static void fireEventWithType(String eventName, String eventType, [dynamic data]) {
    eventBus.fire(EventInfo(
      eventName: eventName,
      eventType: eventType,
      data: data,
    ));
  }
  
  // Méthodes pour les événements sticky
  static void fireStickyEvent(String eventName, [dynamic data]) {
    eventBus.fireSticky(EventInfo(
      eventName: eventName,
      eventType: eventName, // Utiliser eventName comme eventType par défaut
      data: data,
    ));
  }
  
  // Méthode pour rafraîchir une vue
  static void fireRefreshView() {
    eventBus.fire(EventInfo(
      eventName: 'RefreshView',
      eventType: 'RefreshView',
    ));
  }
  
  // Méthode pour rafraîchir une table spécifique
  static void fireRefreshTable(String tag) {
    eventBus.fire(EventInfo(
      eventName: 'RefreshTable',
      eventType: 'refresh_$tag',
    ));
  }
  
  // Méthode pour mettre à jour le thème
  static void fireUpdateTheme() {
    eventBus.fireSticky(EventInfo(
      eventName: 'UpdateTheme',
      eventType: 'UpdateTheme',
    ));
  }
}