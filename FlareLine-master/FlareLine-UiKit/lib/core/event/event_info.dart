// FlareLine-UiKit/lib/core/event/event_info.dart
class EventInfo {
  final String eventName;
  final String eventType; // Ajouté cette propriété
  final dynamic data;
  
  const EventInfo({
    required this.eventName,
    required this.eventType, // Rendez-la obligatoire
    this.data,
  });
  
  @override
  String toString() => 'EventInfo(eventName: $eventName, eventType: $eventType, data: $data)';
}