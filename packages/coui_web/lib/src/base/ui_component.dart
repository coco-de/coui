import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_chrome.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Base class for all stateless UI components in the `coui_web` library.
///
/// Single stateless base: provides the shared Web-chrome passthrough
/// (id / classes / inline css / attributes / event handlers via
/// [WebChrome]), the root [tag], and the [copyWith] contract that lets a
/// parent (e.g. `Join`) re-chrome a child. The stateful sibling is
/// `UiStatefulComponent`, which mixes in the same [WebChrome].
///
/// It deliberately reserves **no** `child` / `children` slot — components
/// compose their own root and declare any content fields themselves (most
/// already do). That keeps the base usable by components whose own contract
/// owns the `child` / `children` names (e.g. `Group`, `Listing`,
/// `HeroSection`).
///
/// Components extending [UiComponent] implement `build` (composing their
/// root element from `componentAttributes` / `events` / `css` / `classes`)
/// and `copyWith`, and can optionally override [configureAttributes] to
/// define component-specific HTML attributes.
@immutable
abstract class UiComponent extends StatelessComponent with WebChrome {
  /// Creates a [UiComponent].
  ///
  /// - [tag]: The HTML tag for the root element (e.g. "div", "button").
  /// - [id]: The HTML ID for the root element.
  /// - [classes]: Additional space-separated CSS classes for the root.
  /// - [css]: Inline CSS styles for the root element.
  /// - [attributes]: Caller HTML attributes, merged over and taking
  ///   precedence over the component's own [configureAttributes].
  /// - Event handlers ([onClick], [onInput], …) for common DOM events.
  /// - [eventHandlers]: Custom / less common event handlers.
  /// - [key]: A [Key] for Jaspr's reconciliation algorithm.
  const UiComponent({
    required this.tag,
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

  /// The HTML tag for the root element of this component.
  final String tag;

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

  /// Creates a copy of this component with the given fields replaced.
  ///
  /// Primarily used by container components (e.g. `Join`) to apply generic
  /// DOM attributes to their children. It intentionally omits
  /// component-specific properties (like content or `tag`) to preserve the
  /// child's original identity and type safety — a parent should only
  /// modify a child's outer attributes, not its content or behavior.
  UiComponent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
  });
}
