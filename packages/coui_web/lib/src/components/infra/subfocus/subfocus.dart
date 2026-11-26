import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/infra/subfocus/subfocus_dom.dart';
import 'package:coui_web/src/components/infra/subfocus/subfocus_style.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Monotonic id source so every `SubfocusScope` owns a unique
/// element id for DOM-driven arrow-key traversal.
int _coSubfocusScopeIdCounter = 0;

/// A unified subfocus scope for CoUI Web.
///
/// Hosts a group of [Subfocus] items and manages arrow-key traversal
/// between them. The scope element listens for keydown events and
/// moves DOM focus to the nearest item along [orientation] — the same
/// spatial algorithm the Flutter `SubfocusScope` runs.
///
/// ```dart
/// SubfocusScope(
///   autofocus: true,
///   child: div([
///     Subfocus(focusId: 'a', child: text('A')),
///     Subfocus(focusId: 'b', child: text('B')),
///   ]),
/// )
/// ```
class SubfocusScope extends UiStatefulComponent
    implements CoreSubfocusScopeContract<Component> {
  /// Creates a [SubfocusScope].
  const SubfocusScope({
    required this.child,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.autofocus = false,
    this.orientation = CoreSubfocusOrientation.defaultOrientation,
  });

  @override
  final Component? child;

  @override
  final bool autofocus;

  @override
  final CoreSubfocusOrientation orientation;

  @override
  State<SubfocusScope> createState() => _SubfocusScopeState();
}

class _SubfocusScopeState extends State<SubfocusScope> {
  late final String _scopeId;

  /// Root element id — a caller-supplied id wins (passthrough) and is
  /// the element `moveSubfocus` traverses within; else the generated
  /// scope id.
  String get _effectiveScopeId => component.id ?? _scopeId;

  @override
  void initState() {
    super.initState();
    final id = _coSubfocusScopeIdCounter++;
    _scopeId = 'co-subfocus-scope-$id';
  }

  bool _isAllowed(SubfocusMoveDirection direction) {
    return switch (component.orientation) {
      .vertical => direction == .up || direction == .down,
      .horizontal => direction == .left || direction == .right,
      .both => true,
    };
  }

  void handleKeyDown(web.KeyboardEvent event) {
    final direction = switch (event.key) {
      'ArrowUp' => SubfocusMoveDirection.up,
      'ArrowDown' => SubfocusMoveDirection.down,
      'ArrowLeft' => SubfocusMoveDirection.left,
      'ArrowRight' => SubfocusMoveDirection.right,
      _ => null,
    };
    if (direction == null || !_isAllowed(direction)) return;
    event.preventDefault();
    moveSubfocus(_effectiveScopeId, direction);
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — scope is state-independent, just outline
    // suppression.
    final resolved = resolveSubfocusScope();

    return Component.element(
      tag: 'div',
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': 'group',
        'tabindex': '0',
        if (component.autofocus) 'autofocus': '',
      },
      events: {
        ...component.events,
        'keydown': EventHandlers.createKeyboardEventHandler(handleKeyDown),
      },
      children: [?component.child],
    );
  }
}

/// A unified focusable subfocus item for CoUI Web.
///
/// Makes its [child] focusable inside a [SubfocusScope]. While the
/// item holds keyboard focus it draws a design-system focus ring via
/// the unified [FocusOutline]; the ring's corner radius comes from
/// [subfocusStyle].
///
/// ```dart
/// Subfocus(
///   focusId: 'menu-item-1',
///   child: text('Menu item 1'),
/// )
/// ```
class Subfocus extends UiStatefulComponent
    implements CoreSubfocusContract<Component> {
  /// Creates a [Subfocus].
  const Subfocus({
    required this.child,
    required this.focusId,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.enabled = true,
    this.subfocusStyle,
  });

  @override
  final Component? child;

  @override
  final String focusId;

  @override
  final bool enabled;

  @override
  final CoreSubfocusStyle? subfocusStyle;

  /// Returns a copy of this [Subfocus] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Subfocus copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    String? focusId,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    bool? enabled,
    CoreSubfocusStyle? subfocusStyle,
    Component? child,
  }) {
    return Subfocus(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      focusId: focusId ?? this.focusId,
      attributes: attributes ?? this.userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      enabled: enabled ?? this.enabled,
      subfocusStyle: subfocusStyle ?? this.subfocusStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Subfocus> createState() => _SubfocusState();
}

/// Chain sugar mirroring the Flutter `Subfocus.withStyle` extension —
/// merges a [CoreSubfocusStyle] patch into [Subfocus.subfocusStyle] via
/// the existing [Subfocus.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSubfocusStyle.merge` right-side-wins semantics).
extension SubfocusStyleChain on Subfocus {
  /// Returns a copy of this [Subfocus] with [patch] merged into
  /// [subfocusStyle] (patch fields win on conflict).
  Subfocus withStyle(CoreSubfocusStyle patch) => copyWith(
    subfocusStyle: (subfocusStyle ?? const CoreSubfocusStyle()).merge(patch),
  );
}

class _SubfocusState extends State<Subfocus> {
  bool _focused = false;

  void handleFocus(web.Event event, web.Element target) {
    if (!component.enabled) return;
    // Only paint the ring for keyboard focus, mirroring `:focus-visible`
    // — pointer clicks should not flash the ring.
    final visible = target.matches(':focus-visible');
    if (visible != _focused) {
      setState(() => _focused = visible);
    }
  }

  void handleBlur(web.Event event) {
    if (_focused) {
      setState(() => _focused = false);
    }
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback resolved in
    // `subfocus_style.dart`. Item is state-independent so `co_subfocus`
    // reads `resolved.root.className / inlineStyles` straight.
    final resolved = resolveSubfocus(
      context: context,
      subfocusStyle: component.subfocusStyle,
    );

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': 'option',
        'tabindex': component.enabled ? '0' : '-1',
        'data-co-subfocus-id': component.focusId,
        'data-co-subfocus-enabled': component.enabled ? 'true' : 'false',
        if (!component.enabled) 'aria-disabled': 'true',
      },
      events: {
        ...component.events,
        'focus': EventHandlers.createElementTargetEventHandler(handleFocus),
        'blur': EventHandlers.createEventHandler(handleBlur),
      },
      children: [
        FocusOutline(
          focused: _focused && component.enabled,
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderRadius:
                component.subfocusStyle?.focusRingRadius ??
                CoreSubfocusStyle.defaultFocusRingRadius,
          ),
          child: component.child,
        ),
      ],
    );
  }
}
