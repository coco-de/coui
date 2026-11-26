import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

// Event handler type definitions
// These type definitions ensure that we use the same types everywhere
typedef UiMouseEventHandler = void Function(web.MouseEvent event);
typedef UiKeyboardEventHandler = void Function(web.KeyboardEvent event);
typedef UiInputEventHandler = void Function(String value);
typedef UiEventHandler = void Function(web.Event event);
typedef UiDragEventHandler = void Function(web.DragEvent event);

/// Callback that receives a [web.MouseEvent] together with its
/// `currentTarget` narrowed to a [web.HTMLElement] — used by hover
/// handlers that mutate inline styles on the element the listener is
/// bound to.
typedef UiMouseCurrentTargetEventHandler =
    void Function(web.MouseEvent event, web.HTMLElement currentTarget);

/// Callback that receives a [web.PointerEvent] together with its
/// `currentTarget` narrowed to a [web.HTMLElement] — used by drag
/// gestures (pull-to-refresh) that need `pointerId` for pointer
/// capture and the host element for scroll-boundary reads.
typedef UiPointerCurrentTargetEventHandler =
    void Function(web.PointerEvent event, web.HTMLElement currentTarget);

/// Callback that receives an `<input>` event together with the
/// underlying [web.HTMLInputElement] target. Mirrors
/// [UiTextAreaTargetEventHandler] for `<textarea>`.
typedef UiInputTargetEventHandler =
    void Function(web.Event event, web.HTMLInputElement target);

/// Callback that receives a `<textarea>` event together with the
/// underlying [web.HTMLTextAreaElement] target.
typedef UiTextAreaTargetEventHandler =
    void Function(web.Event event, web.HTMLTextAreaElement target);

/// Callback that receives a generic [web.Event] together with the
/// underlying [web.Element] target — useful for focus/blur on `<div>`,
/// `<button>` and other non-input elements that still need to test
/// `:focus-visible` or read attributes from the target.
typedef UiElementTargetEventHandler =
    void Function(web.Event event, web.Element target);

/// Callback that receives a [web.ClipboardEvent] together with the
/// underlying [web.HTMLInputElement] target — used by paste handlers
/// that need both the clipboard payload and the originating input.
typedef UiClipboardInputEventHandler =
    void Function(web.ClipboardEvent event, web.HTMLInputElement target);

/// Base class for event data.
@immutable
class UiEventData {
  const UiEventData();
}

/// Utility class for creating event handlers.
///
/// Centralises the `case final T event` pattern so component code stays
/// free of extension-type cast lint noise and dart2js dynamic-dispatch
/// pitfalls. dart2js release minifies dynamic getter dispatches (e.g.
/// `event.target`) into mangled names — typed handlers built here keep
/// every call site mangling-resilient.
abstract final class EventHandlers {
  static EventCallback createMouseEventHandler(UiMouseEventHandler handler) {
    return (Object rawEvent) {
      if (rawEvent case final web.MouseEvent event) {
        handler(event);
      }
    };
  }

  static EventCallback createKeyboardEventHandler(
    UiKeyboardEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.KeyboardEvent event) {
        handler(event);
      }
    };
  }

  /// Creates a handler that receives any [web.Event] (e.g. `focus` / `blur`)
  /// whose target is an [web.HTMLInputElement] — silently drops the event
  /// if the target is something else or null.
  static EventCallback createInputTargetEventHandler(
    UiInputTargetEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.Event event) {
        if (event.target case final web.HTMLInputElement target) {
          handler(event, target);
        }
      }
    };
  }

  /// Creates a handler that receives any [web.Event] (e.g. `focus` / `blur`)
  /// whose target is an [web.HTMLTextAreaElement] — silently drops the event
  /// if the target is something else or null.
  static EventCallback createTextAreaTargetEventHandler(
    UiTextAreaTargetEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.Event event) {
        if (event.target case final web.HTMLTextAreaElement target) {
          handler(event, target);
        }
      }
    };
  }

  /// Creates a handler that receives any [web.Event] whose target is an
  /// [web.Element] — useful for focus/blur on non-input elements (e.g.
  /// `<div role="button">` triggers that need to test `:focus-visible`
  /// on the target itself).
  static EventCallback createElementTargetEventHandler(
    UiElementTargetEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.Event event) {
        if (event.target case final web.Element target) {
          handler(event, target);
        }
      }
    };
  }

  /// Creates a paste handler — receives a [web.ClipboardEvent] together
  /// with the underlying [web.HTMLInputElement] target. Silently drops
  /// non-clipboard events or targets that aren't an input element.
  static EventCallback createClipboardInputEventHandler(
    UiClipboardInputEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.ClipboardEvent event) {
        if (event.target case final web.HTMLInputElement target) {
          handler(event, target);
        }
      }
    };
  }

  /// Creates a generic event handler — preserves [web.Event] typing without
  /// requiring a specific target. Use for `blur` and similar events where
  /// the target may be null or unimportant.
  static EventCallback createEventHandler(UiEventHandler handler) {
    return (Object rawEvent) {
      if (rawEvent case final web.Event event) {
        handler(event);
      }
    };
  }

  /// Creates an HTML5 drag-and-drop event handler — preserves
  /// [web.DragEvent] typing (`dataTransfer`, `clientX`/`clientY`) without
  /// a `as` cast. Use for `dragstart` / `dragover` / `dragend` / `drop`.
  static EventCallback createDragEventHandler(UiDragEventHandler handler) {
    return (Object rawEvent) {
      if (rawEvent case final web.DragEvent event) {
        handler(event);
      }
    };
  }

  /// Creates a [web.MouseEvent] handler that also narrows the event's
  /// `currentTarget` to a [web.HTMLElement] — silently drops the event
  /// when the current target is not an HTML element.
  static EventCallback createMouseCurrentTargetEventHandler(
    UiMouseCurrentTargetEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.MouseEvent event) {
        if (event.currentTarget case final web.HTMLElement currentTarget) {
          handler(event, currentTarget);
        }
      }
    };
  }

  /// Creates a [web.PointerEvent] handler that also narrows the event's
  /// `currentTarget` to a [web.HTMLElement] — silently drops the event
  /// when the current target is not an HTML element. Pointer events
  /// unify mouse and touch input and expose `pointerId` for
  /// `setPointerCapture`, which drag gestures need so moves outside the
  /// element keep streaming to it.
  static EventCallback createPointerCurrentTargetEventHandler(
    UiPointerCurrentTargetEventHandler handler,
  ) {
    return (Object rawEvent) {
      if (rawEvent case final web.PointerEvent event) {
        if (event.currentTarget case final web.HTMLElement currentTarget) {
          handler(event, currentTarget);
        }
      }
    };
  }

  /// Runs [caller] and then [own] for the same event.
  ///
  /// A component that listens for an event the base already exposes as a
  /// passthrough prop (`onKeyDown` → `keydown`, `onClick` → `click`) has
  /// to say which one wins, and the obvious spelling picks wrong:
  ///
  /// ```dart
  /// events: {...component.events, 'keydown': myHandler}  // ❌
  /// ```
  ///
  /// The literal key replaces the entry the base put there, so the
  /// caller's handler is dropped — silently, because the component still
  /// renders and its own handler still works. Composing keeps both.
  ///
  /// [caller] runs first so it can claim the event with `preventDefault`,
  /// which [own] is then free to honour. `null` means the caller supplied
  /// nothing and [own] is used as-is.
  static EventCallback chain(EventCallback? caller, EventCallback own) {
    if (caller == null) return own;

    return (web.Event event) {
      caller(event);
      own(event);
    };
  }
}

/// Whether [key] names an attribute that describes a control's *semantics*
/// (its role in the accessibility tree) rather than its box.
///
/// A composite whose visible chrome is a wrapper around a native control
/// has to route these to the control itself: a `role` on the wrapper
/// describes the wrapper, and a screen reader lands on the `<input>`.
bool isSemanticHtmlAttribute(String key) =>
    key == 'role' || key.startsWith('aria-');
