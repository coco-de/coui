import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:universal_web/web.dart';

/// Shared Web-chrome passthrough for `coui_web` component bases.
///
/// Holds the single source of truth for turning caller-supplied chrome
/// (id / classes / inline css / attributes / event handlers) into the
/// `attributes` + `events` maps a Jaspr element needs — plus the
/// [configureAttributes] hook and the [mergeClasses] helper.
///
/// A mixin cannot declare a constructor, so the **data** (the chrome
/// fields) is left abstract here and stored by each base via its own
/// `final` fields: [UiComponent] (stateless) and `UiStatefulComponent`
/// both `with WebChrome`, mirroring Flutter's `StatelessWidget` /
/// `StatefulWidget` split. This makes the same passthrough available to
/// stateful components, not only stateless ones — the previous gap.
///
/// Styling lives nowhere here: chrome flows through `CoreXxxStyle`
/// slots + resolvers; this mixin only forwards identity (id / aria /
/// attributes), behaviour (events) and caller-provided layout
/// classes/css.
mixin WebChrome on Component {
  // ── Chrome data — supplied by the host base's fields ──────────────

  /// The HTML `id` for the root element.
  String? get id;

  /// Caller-supplied space-separated CSS classes for the root element.
  String? get classes;

  /// Caller-supplied inline CSS styles for the root element.
  Styles? get css;

  /// Raw caller-provided HTML attributes (merged over
  /// [configureAttributes], taking precedence). Null when none given.
  Map<String, String>? get userAttributes;

  /// Custom / less-common event handlers keyed by DOM event name.
  Map<String, List<UiEventHandler>> get eventHandlers;

  /// Callback for the `mouseenter` DOM event.
  UiMouseEventHandler? get onMouseEnter;

  /// Callback for the `mouseleave` DOM event.
  UiMouseEventHandler? get onMouseLeave;

  /// Callback for the `keydown` DOM event.
  UiKeyboardEventHandler? get onKeyDown;

  /// Callback for the `keyup` DOM event.
  UiKeyboardEventHandler? get onKeyUp;

  /// Callback for the `click` DOM event.
  UiMouseEventHandler? get onClick;

  /// Callback for the `input` DOM event.
  UiInputEventHandler? get onInput;

  /// Callback for the `change` DOM event.
  UiInputEventHandler? get onChange;

  // ── Chrome logic — single source ──────────────────────────────────

  /// Merges two CSS class strings, safely handling null / empty inputs.
  ///
  /// Used by components (e.g. in `copyWith`, or by a parent like `Join`)
  /// to add programmatic classes without overwriting caller classes.
  @protected
  String? mergeClasses(String? newClasses, String? originalClasses) {
    if (originalClasses == null || originalClasses.isEmpty) {
      return newClasses;
    }

    return newClasses == null || newClasses.isEmpty
        ? originalClasses
        : '$originalClasses $newClasses';
  }

  /// Configures component-specific HTML attributes.
  ///
  /// Subclasses override this to add their default / computed attributes
  /// (`role`, `type`, `aria-*`, `data-*`) via the [attributes] builder.
  /// Called from [componentAttributes]; caller attributes override these.
  ///
  /// ```dart
  /// @override
  /// void configureAttributes(UiComponentAttributes attributes) {
  ///   super.configureAttributes(attributes);
  ///   attributes.addRole('button');
  /// }
  /// ```
  @protected
  void configureAttributes(UiComponentAttributes attributes) {
    // Base implementation intentionally no-op.
    // Subclasses override to add their specific attributes.
    // Ensure block is not empty for linters without changing behavior.
    attributes.merge(const {});
  }

  /// Caller-provided attributes, or an empty map when none were given.
  @protected
  Map<String, String> get userProvidedAttributes => userAttributes ?? const {};

  /// Composes a root element's class string: [base] (the component's own
  /// resolved classes) followed by any caller-supplied [classes].
  ///
  /// Public so a `State.build` — which is not itself a [WebChrome]
  /// subclass — can compose its root classes via the owning
  /// `component.rootClasses(resolved.root.className)`.
  String? rootClasses(String? base) => mergeClasses(classes, base);

  /// Builds the event-handler map for the root Jaspr element from the
  /// typed callbacks ([onClick] / [onInput] / …) plus [eventHandlers].
  Map<String, EventCallback> get events {
    final eventMap = <String, EventCallback>{};

    // Standard mouse events
    final mouseEnterHandler = onMouseEnter;
    if (mouseEnterHandler != null) {
      eventMap['mouseenter'] = EventHandlers.createMouseEventHandler(
        mouseEnterHandler,
      );
    }
    final mouseLeaveHandler = onMouseLeave;
    if (mouseLeaveHandler != null) {
      eventMap['mouseleave'] = EventHandlers.createMouseEventHandler(
        mouseLeaveHandler,
      );
    }
    final clickHandler = onClick;
    if (clickHandler != null) {
      eventMap['click'] = EventHandlers.createMouseEventHandler(clickHandler);
    }

    // Standard keyboard events
    final keyDownHandler = onKeyDown;
    if (keyDownHandler != null) {
      eventMap['keydown'] = EventHandlers.createKeyboardEventHandler(
        keyDownHandler,
      );
    }
    final keyUpHandler = onKeyUp;
    if (keyUpHandler != null) {
      eventMap['keyup'] = EventHandlers.createKeyboardEventHandler(
        keyUpHandler,
      );
    }

    // Standard input/change events (Jaspr passes a String value)
    final inputHandler = onInput;
    if (inputHandler != null) {
      eventMap['input'] = (Object rawEvent) {
        if (rawEvent is String) {
          inputHandler(rawEvent);
        }
      };
    }
    final changeHandler = onChange;
    if (changeHandler != null) {
      eventMap['change'] = (Object rawEvent) {
        if (rawEvent is String) {
          changeHandler(rawEvent);
        }
      };
    }

    // Custom event handlers
    for (final entry in eventHandlers.entries) {
      final eventName = entry.key;
      final handlers = entry.value;

      eventMap[eventName] = (Event rawEvent) {
        for (final handler in handlers) {
          handler(rawEvent);
        }
      };
    }

    return eventMap;
  }

  /// The merged HTML attribute map (component-defined via
  /// [configureAttributes], then caller [userAttributes] which win).
  /// `id` is passed to the element separately.
  Map<String, String> get componentAttributes {
    final builder = UiComponentAttributes();
    configureAttributes(builder);
    final caller = userAttributes;
    if (caller != null) {
      builder.merge(caller);
    }

    return builder.build;
  }
}
