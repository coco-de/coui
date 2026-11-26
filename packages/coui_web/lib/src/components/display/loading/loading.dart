import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/loading/loading_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

int _instanceCounter = 0;

/// `role="status"` plus its accessible name.
///
/// Built per render rather than held as a `const` because the name has to
/// follow the active locale — a screen reader announcing "Loading" to a
/// Korean user is the same defect as a visible English placeholder, just
/// harder to notice.
Map<String, String> _statusAttrs(BuildContext context) => {
  'role': 'status',
  'aria-label': CouiLocalizations.of(context).loadingLabel,
};

/// Unified loading indicator (Web).
///
/// Structurally mirrors Flutter `Loading`: a single render-only widget
/// that resolves chrome through [resolveLoading] and renders the
/// variant-appropriate DOM slots by reading the matching nullable slot
/// chromes on the returned [ResolvedLoading].
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [loadingStyle] slot. Semantic enums (`variant` /
/// `componentSize`) stay flat on the widget.
///
/// Four variants:
///   - `spinner` — 360 ° rotating ring (1 s linear infinite).
///   - `dots` — three dots, half a dot apart, in a wave: at the start of a
///     cycle they read `CoreLoadingStyle.dotWaveOpacities` (1 · 0.6 · 0.3)
///     left to right and each lags the previous one by
///     `CoreLoadingStyle.dotPhaseOffsetRatio` (a third) of the cycle.
///   - `bar` — single horizontal bar sliding left ↔ right (1.5 s ease-in-out).
///   - `pulse` — circle scaling 1.0 → 1.3 → 1.0 (1 s ease-in-out).
class Loading extends UiStatefulComponent implements CoreLoadingContract {
  /// Creates a [Loading].
  const Loading({
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
    this.variant = CoreLoadingVariant.spinner,
    this.componentSize,
    this.tone = CoreLoadingTone.defaultTone,
    this.loadingStyle,
  });

  @override
  final CoreLoadingVariant variant;

  @override
  final CoreComponentSize? componentSize;

  @override
  final CoreLoadingTone tone;

  @override
  final CoreLoadingStyle? loadingStyle;

  /// Returns a copy of this [Loading] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Loading copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreLoadingVariant? variant,
    CoreComponentSize? componentSize,
    CoreLoadingTone? tone,
    CoreLoadingStyle? loadingStyle,
  }) {
    return Loading(
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
      variant: variant ?? this.variant,
      componentSize: componentSize ?? this.componentSize,
      tone: tone ?? this.tone,
      loadingStyle: loadingStyle ?? this.loadingStyle,
    );
  }

  @override
  State<Loading> createState() => _LoadingState();
}

/// Chain sugar mirroring the Flutter `Loading.withStyle` extension —
/// merges a [CoreLoadingStyle] patch into [Loading.loadingStyle] via the
/// existing [Loading.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLoadingStyle.merge` right-side-wins semantics).
extension LoadingStyleChain on Loading {
  /// Returns a copy of this [Loading] with [patch] merged into
  /// [loadingStyle] (patch fields win on conflict).
  Loading withStyle(CoreLoadingStyle patch) => copyWith(
    loadingStyle: (loadingStyle ?? const CoreLoadingStyle()).merge(patch),
  );
}

class _LoadingState extends State<Loading> {
  late final String _scopeId;

  @override
  void initState() {
    super.initState();
    _scopeId = 'co-loading-${kIsWeb ? 'web' : 'ssr'}-${_instanceCounter++}';
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis + the
    // scoped-CSS rules template. `co_*` reads each slot directly — no
    // chrome composition in the widget body.
    final resolved = resolveLoading(
      context,
      variant: component.variant,
      tone: component.tone,
      componentSize: component.componentSize,
      loadingStyle: component.loadingStyle,
    );
    // A caller-supplied id wins (passthrough) and also scopes the
    // `<style>` selectors; otherwise the generated per-instance scope id
    // keeps the scoped CSS unique.
    final scopeId = component.id ?? _scopeId;
    final rulesCss = resolveLoadingCss(
      context,
      variant: component.variant,
      id: scopeId,
      loadingStyle: component.loadingStyle,
    );

    final styleNode = Component.element(
      tag: 'style',
      children: [RawText(rulesCss)],
    );

    final children = switch (component.variant) {
      .spinner => [
        styleNode,
        Component.element(
          tag: 'svg',
          classes: resolved.track!.className,
          attributes: const {
            'width': '100%',
            'height': '100%',
            'aria-hidden': 'true',
          },
          children: [
            Component.element(
              tag: 'circle',
              attributes: const {'cx': '50%', 'cy': '50%'},
              styles: resolved.track!.inlineStyles,
            ),
          ],
        ),
        Component.element(
          tag: 'svg',
          classes: resolved.sweep!.className,
          attributes: const {
            'width': '100%',
            'height': '100%',
            'aria-hidden': 'true',
          },
          children: [
            Component.element(
              tag: 'circle',
              attributes: const {'cx': '50%', 'cy': '50%', 'pathLength': '360'},
              styles: resolved.sweep!.inlineStyles,
            ),
          ],
        ),
      ],
      .dots => [
        styleNode,
        Component.element(
          tag: 'span',
          classes: resolved.dot0!.className,
          styles: resolved.dot0!.inlineStyles,
        ),
        Component.element(
          tag: 'span',
          classes: resolved.dot1!.className,
          styles: resolved.dot1!.inlineStyles,
        ),
        Component.element(
          tag: 'span',
          classes: resolved.dot2!.className,
          styles: resolved.dot2!.inlineStyles,
        ),
      ],
      .bar => [
        styleNode,
        Component.element(
          tag: 'span',
          classes: resolved.fill!.className,
          styles: resolved.fill!.inlineStyles,
        ),
      ],
      .pulse => [
        styleNode,
        Component.element(
          tag: 'span',
          classes: resolved.halo!.className,
          styles: resolved.halo!.inlineStyles,
        ),
        Component.element(
          tag: 'span',
          classes: resolved.dot!.className,
          styles: resolved.dot!.inlineStyles,
        ),
      ],
    };

    return Component.element(
      tag: 'span',
      id: scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {...component.componentAttributes, ..._statusAttrs(context)},
      events: component.events,
      children: children,
    );
  }
}
