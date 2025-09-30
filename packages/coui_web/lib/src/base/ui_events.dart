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
  const UiEventData();
}

/// Utility class for creating event handlers.
abstract final class EventHandlers {
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
