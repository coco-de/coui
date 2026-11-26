import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_chrome.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart' show Styles;

/// Base class for stateful UI components in the `coui_web` library.
///
/// The stateful sibling of [UiComponent]: same caller-facing chrome
/// (id / classes / inline css / attributes / event handlers) via the
/// shared [WebChrome] mixin, so stateful components forward identity /
/// aria / attributes / events just like stateless ones. (A mixin cannot
/// hold a constructor, so the chrome fields live here; the passthrough
/// logic — `componentAttributes` / `events` / `configureAttributes` /
/// `mergeClasses` — comes from [WebChrome].)
///
/// The owning `State.build` composes its root element from
/// `component.componentAttributes` / `component.events` and merges
/// `component.classes` / `component.css` / `component.id`. Styling stays
/// in `CoreXxxStyle` slots + resolvers — this base only forwards chrome.
@immutable
abstract class UiStatefulComponent extends StatefulComponent with WebChrome {
  /// Creates a [UiStatefulComponent].
  const UiStatefulComponent({
    Map<String, String>? attributes,
    this.classes,
    this.css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    this.id,
    super.key,
    this.onChange,
    this.onClick,
    this.onInput,
    this.onKeyDown,
    this.onKeyUp,
    this.onMouseEnter,
    this.onMouseLeave,
  }) : _userAttributes = attributes,
       eventHandlers = eventHandlers ?? const <String, List<UiEventHandler>>{};

  @override
  final String? id;

  @override
  final String? classes;

  @override
  final Styles? css;

  @override
  final UiMouseEventHandler? onMouseEnter;

  @override
  final UiMouseEventHandler? onMouseLeave;

  @override
  final UiKeyboardEventHandler? onKeyDown;

  @override
  final UiKeyboardEventHandler? onKeyUp;

  @override
  final UiMouseEventHandler? onClick;

  @override
  final UiInputEventHandler? onInput;

  @override
  final UiInputEventHandler? onChange;

  @override
  final Map<String, List<UiEventHandler>> eventHandlers;

  final Map<String, String>? _userAttributes;

  @override
  Map<String, String>? get userAttributes => _userAttributes;
}
