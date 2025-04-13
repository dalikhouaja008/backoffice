import 'dart:async';

class EventBus {
  final StreamController _streamController;
  final Map<Type, Object> _stickyEvents = <Type, Object>{};

  EventBus() : _streamController = StreamController.broadcast();

  Stream<T> on<T>() {
    if (_streamController.isClosed) return Stream.empty();
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  // Ajout de la méthode onSticky
  Stream<T> onSticky<T>() {
    if (_streamController.isClosed) return Stream.empty();
    
    // Créer un contrôleur pour pouvoir émettre l'événement sticky immédiatement
    final controller = StreamController<T>.broadcast();
    
    // Ajoute tous les événements futurs
    _streamController.stream
        .where((event) => event is T)
        .cast<T>()
        .pipe(controller);
    
    // Émettre l'événement sticky existant si disponible
    if (_stickyEvents.containsKey(T)) {
      final stickyEvent = _stickyEvents[T];
      if (stickyEvent is T) {
        scheduleMicrotask(() {
          if (!controller.isClosed) {
            controller.add(stickyEvent);
          }
        });
      }
    }
    
    return controller.stream;
  }

  void fire(event) {
    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }
  
  // Ajouter une méthode pour les événements sticky
  void fireSticky(event) {
    if (!_streamController.isClosed) {
      _stickyEvents[event.runtimeType] = event;
      _streamController.add(event);
    }
  }
  
  // Nettoyer un événement sticky spécifique
  void removeStickyEvent<T>() {
    _stickyEvents.remove(T);
  }
  
  // Nettoyer tous les événements sticky
  void removeAllStickyEvents() {
    _stickyEvents.clear();
  }

  void destroy() {
    _streamController.close();
  }
  
  bool get isClosed => _streamController.isClosed;
}