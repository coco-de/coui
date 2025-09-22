import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart';

// Event handler type definitions
// These type definitions ensure that we use the same types everywhere
typedef UiMouseEventHandler = void Function(MouseEvent event);
typedef UiKeyboardEventHandler = void Function(KeyboardEvent event);
typedef UiInputEventHandler = void Function(String value);
typedef UiEventHandler = void Function(Event event);

/// Base class for event data.
@immutable
class UiEventData {
  const UiEventData({
    this.detail = const <String, Object>{},
    required this.originalEvent,
    required this.target,
  });

  final Event originalEvent;
  final Object target;
  final Map<String, Object> detail;
}

@immutable
class UiMouseEventData extends UiEventData {
  const UiMouseEventData({
    required this.clientX,
    required this.clientY,
    required this.ctrlKey,
    super.detail,
    required super.originalEvent,
    required this.shiftKey,
    required super.target,
  });

  // Factory method with the proper property names
  factory UiMouseEventData.fromEvent(MouseEvent event, Object target) {
    return UiMouseEventData(
      clientX: event.clientX,
      clientY: event.clientY,
      ctrlKey: event.ctrlKey,
      originalEvent: event,
      shiftKey: event.shiftKey,
      target: target,
    );
  }

  final num clientX;
  final num clientY;
  final bool ctrlKey;
  final bool shiftKey;
}

@immutable
class UiKeyboardEventData extends UiEventData {
  const UiKeyboardEventData({
    required this.ctrlKey,
    super.detail,
    required this.key,
    required super.originalEvent,
    required this.shiftKey,
    required super.target,
  });

  // Factory method with the proper property names
  factory UiKeyboardEventData.fromEvent(KeyboardEvent event, Object target) {
    // Extract event properties for better readability
    final key = event.key;
    final ctrlKey = event.ctrlKey;
    final shiftKey = event.shiftKey;

    return UiKeyboardEventData(
      key: key,
      ctrlKey: ctrlKey,
      originalEvent: event,
      shiftKey: shiftKey,
      target: target,
    );
  }

  final String key;
  final bool ctrlKey;
  final bool shiftKey;
}

/// Utility class for creating event handlers.
abstract final class EventHandlers {
  static EventCallback createEventHandler(UiEventHandler handler) {
    return (Object rawEvent) {
      if (rawEvent case final Event event) {
        handler(event);
      }
    };
  }

  static EventCallback createMouseEventHandler(UiMouseEventHandler handler) {
    return (Object rawEvent) {
      if (rawEvent case final MouseEvent event) {
        handler(event);
      }
    };
  }

  static EventCallback createKeyboardEventHandler(
    UiKeyboardEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final KeyboardEvent event) {
        handler(event);
      }
    };
  }
}
