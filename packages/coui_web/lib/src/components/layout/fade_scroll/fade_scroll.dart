import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/layout/fade_scroll/fade_scroll_measurer.dart';
import 'package:coui_web/src/components/layout/fade_scroll/fade_scroll_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

int _coFadeScrollIdCounter = 0;

/// Wraps a scrollable [child] and overlays a soft fade gradient on the
/// scroll edges. Mirrors Flutter `FadeScroll` — same direction enum,
/// same `startOffset` / `endOffset` resolution (via [fadeScrollStyle]),
/// same dynamic edge behaviour: the leading fade vanishes at the start
/// boundary, the trailing fade vanishes at the end boundary.
class FadeScroll extends UiStatefulComponent
    implements CoreFadeScrollContract<Component> {
  /// Creates a [FadeScroll].
  const FadeScroll({
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
    this.direction = CoreFadeScrollDirection.defaultDirection,
    this.showScrollbar = false,
    this.fadeScrollStyle,
  });

  @override
  final Component child;

  @override
  final CoreFadeScrollDirection direction;

  @override
  final bool showScrollbar;

  @override
  final CoreFadeScrollStyle? fadeScrollStyle;

  /// Returns a copy of this [FadeScroll] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FadeScroll copyWith({
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
    CoreFadeScrollDirection? direction,
    bool? showScrollbar,
    CoreFadeScrollStyle? fadeScrollStyle,
    Component? child,
  }) {
    return FadeScroll(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
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
      fadeScrollStyle: fadeScrollStyle ?? this.fadeScrollStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<FadeScroll> createState() => _FadeScrollState();
}

class _FadeScrollState extends State<FadeScroll> {
  late final String _scopeId;
  FadeScrollMeasurer? _measurer;
  CoreFadeScrollDirection? _attachedDirection;

  @override
  void initState() {
    super.initState();
    // Keys are local to a parent; viewport IDs must be unique across owners.
    // Server-only markup can coexist with independently mounted client roots.
    const platform = kIsWeb ? 'web' : 'ssr';
    _scopeId = 'co-fade-$platform-${_coFadeScrollIdCounter++}';
  }

  void _ensureMeasurer(CoreFadeScrollDirection direction) {
    if (!kIsWeb) return;
    if (_attachedDirection == direction) {
      // Reapply runtime carriers after a build replaces inline styles. The
      // measurer reuses its native effects; legacy attach remains a no-op.
      _measurer?.attach();
      return;
    }
    _measurer?.dispose();
    _attachedDirection = direction;
    _measurer = FadeScrollMeasurer(viewportId: _scopeId, direction: direction)
      ..attach();
  }

  @override
  void dispose() {
    _measurer?.dispose();
    _measurer = null;
    _attachedDirection = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveFadeScroll(
      context,
      direction: component.direction,
      showScrollbar: component.showScrollbar,
      fadeScrollStyle: component.fadeScrollStyle,
    );

    if (kIsWeb) {
      scheduleMicrotask(() {
        if (mounted) _ensureMeasurer(component.direction);
      });
    }

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: [
        if (!component.showScrollbar)
          Component.element(
            tag: 'style',
            children: [
              RawText('#$_scopeId::-webkit-scrollbar { display: none; }'),
            ],
          ),
        Component.element(
          tag: 'div',
          id: _scopeId,
          classes: resolved.viewport.className,
          styles: resolved.viewport.inlineStyles,
          children: [component.child],
        ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `FadeScroll.withStyle` extension —
/// merges a [CoreFadeScrollStyle] patch into [FadeScroll.fadeScrollStyle]
/// via the existing [FadeScroll.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFadeScrollStyle.merge` right-side-wins semantics).
extension FadeScrollStyleChain on FadeScroll {
  /// Returns a copy of this [FadeScroll] with [patch] merged into
  /// [fadeScrollStyle] (patch fields win on conflict).
  FadeScroll withStyle(CoreFadeScrollStyle patch) => copyWith(
    fadeScrollStyle: (fadeScrollStyle ?? const CoreFadeScrollStyle()).merge(
      patch,
    ),
  );
}
