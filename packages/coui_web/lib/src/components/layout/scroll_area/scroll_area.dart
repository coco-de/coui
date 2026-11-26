import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar.dart';
import 'package:coui_web/src/components/layout/scroll_area/scroll_area_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Wraps a scrollable [child] in a viewport with a design-system styled
/// scrollbar. Mirrors Flutter `ScrollArea` — same direction enum,
/// same `height` / `maxHeight` / nested `scrollbarStyle` resolution
/// (via [scrollAreaStyle]), same `showScrollbar` toggle.
///
/// The scroll container and its scrollbar skin are drawn by the
/// composed unified `Scrollbar` (child component composition — the
/// same structure as the Flutter twin); `ScrollArea` contributes the
/// size constraints, the `relative` positioning context, and the
/// resolved nested [CoreScrollbarStyle].
///
/// Unlike `FadeScroll` (which masks the edges with a gradient),
/// `ScrollArea` keeps the content fully visible and lets the slim
/// scrollbar communicate the overflow.
class ScrollArea extends UiStatefulComponent
    implements CoreScrollAreaContract<Component> {
  /// Creates a [ScrollArea].
  const ScrollArea({
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
    this.direction = CoreScrollAreaDirection.defaultDirection,
    this.showScrollbar = true,
    this.scrollAreaStyle,
  });

  @override
  final Component child;

  @override
  final CoreScrollAreaDirection direction;

  @override
  final bool showScrollbar;

  @override
  final CoreScrollAreaStyle? scrollAreaStyle;

  /// Returns a copy of this [ScrollArea] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ScrollArea copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
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
    CoreScrollAreaDirection? direction,
    bool? showScrollbar,
    CoreScrollAreaStyle? scrollAreaStyle,
    Component? child,
  }) {
    return ScrollArea(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
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
      direction: direction ?? this.direction,
      showScrollbar: showScrollbar ?? this.showScrollbar,
      scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<ScrollArea> createState() => _ScrollAreaState();
}

class _ScrollAreaState extends State<ScrollArea> {
  @override
  Component build(BuildContext context) {
    // Resolver finishes the size-constraint chrome and the nested
    // scrollbar Style slot. The scroll container + scrollbar skin are
    // owned by the composed `Scrollbar` — ScrollArea forwards its own
    // chrome contribution (relative + height / max-height) together
    // with the caller passthrough into the scrollbar's caller-chrome
    // params, so the composed root stays the single DOM root.
    final resolved = resolveScrollArea(
      context,
      scrollAreaStyle: component.scrollAreaStyle,
    );

    // The always visibility mirrors the persistent classic scrollbar of
    // the Flutter twin; hidden keeps the area scrollable without a
    // visible thumb.
    return Scrollbar(
      onClick: component.onClick,
      attributes: component.componentAttributes,
      classes: component.rootClasses(resolved.root.className),
      css: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      axis: component.direction == .horizontal ? .horizontal : .vertical,
      visibility: component.showScrollbar ? .always : .hidden,
      scrollbarStyle: resolved.scrollbarStyle,
      child: component.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `ScrollArea.withStyle` extension —
/// merges a [CoreScrollAreaStyle] patch into [ScrollArea.scrollAreaStyle]
/// via the existing [ScrollArea.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreScrollAreaStyle.merge` right-side-wins semantics).
extension ScrollAreaStyleChain on ScrollArea {
  /// Returns a copy of this [ScrollArea] with [patch] merged into
  /// [scrollAreaStyle] (patch fields win on conflict).
  ScrollArea withStyle(CoreScrollAreaStyle patch) => copyWith(
    scrollAreaStyle: (scrollAreaStyle ?? const CoreScrollAreaStyle()).merge(
      patch,
    ),
  );
}
