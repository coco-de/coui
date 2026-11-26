import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/layout/overflow_marquee/overflow_marquee_measurer.dart';
import 'package:coui_web/src/components/layout/overflow_marquee/overflow_marquee_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

int _coOverflowMarqueeIdCounter = 0;

/// Unified marquee-style scrolling wrapper for CoUI Web.
///
/// Produces pixel-for-pixel the same bounce Flutter's
/// `OverflowMarquee` draws: content that overflows translates by
/// exactly `sizeDiff`, pauses for `delayDuration` at each end, and
/// reverses. Edge fades ramp in sync with the translation, matching
/// Flutter's progress-aware `ShaderMaskLayer`.
///
/// ## Architecture
///
/// Everything visual is driven from Dart on the client side:
///
///   1. `build` emits a static per-instance `<style>` block (container
///      clipping, track `max-content` sizing, and a `mask-image` whose
///      outer stops read `--co-om-fade-start-alpha` /
///      `--co-om-fade-end-alpha` via CSS `rgb(0 0 0 / var(...))`).
///   2. `initState` attaches an [OverflowMarqueeMeasurer] that installs
///      a `ResizeObserver` and runs a `requestAnimationFrame` loop —
///      on every frame it computes the same `offsetProgress` Flutter
///      computes and writes three things: the track's `transform`, the
///      start-edge alpha, and the end-edge alpha.
///
/// No `@keyframes`, no `@property`, no `<style>` text surgery — the
/// mask is a single static gradient, and the rAF loop simply writes
/// the values Flutter's `paint()` would write each frame.
///
/// ## Why a conditional-import helper instead of CSS animations?
///
/// Earlier revisions relied on animated CSS with runtime-generated
/// keyframes so CSS could interpolate the fade alphas through
/// `@property`-registered custom variables. Two problems:
///
///   - The `syntax: "<number>"` descriptor's angle brackets got
///     collapsed during jaspr's SSR rendering to `syntax: ""`, which
///     Chrome / Safari silently ignore ("Ignored @property rule ...").
///   - Keyframe percentages must be literal — they can't scale with a
///     measured `sizeDiff`. We worked around this by rewriting the
///     keyframes on every resize, but that turned the stylesheet into
///     moving ground and made DevTools inspection harder.
///
/// Driving the same math from a rAF tick (the project-wide pattern
/// for runtime DOM state — see `Select`'s
/// `OverlayScrollTracker` or `ScrollableClient`'s
/// `readScrollGeometry`) gives exact Flutter parity with less moving
/// parts.
class OverflowMarquee extends UiStatefulComponent
    implements CoreOverflowMarqueeContract<Component> {
  /// Creates a [OverflowMarquee].
  const OverflowMarquee({
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
    this.direction = .horizontal,
    this.curve,
    this.pauseOnHover = false,
    this.overflowMarqueeStyle,
  });

  @override
  final Component child;

  @override
  final CoreAxis direction;

  @override
  final CoreMarqueeCurve? curve;

  @override
  final bool pauseOnHover;

  @override
  final CoreOverflowMarqueeStyle? overflowMarqueeStyle;

  /// Returns a copy of this [OverflowMarquee] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  OverflowMarquee copyWith({
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
    CoreAxis? direction,
    CoreMarqueeCurve? curve,
    bool? pauseOnHover,
    CoreOverflowMarqueeStyle? overflowMarqueeStyle,
    Component? child,
  }) {
    return OverflowMarquee(
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
      curve: curve ?? this.curve,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      overflowMarqueeStyle: overflowMarqueeStyle ?? this.overflowMarqueeStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<OverflowMarquee> createState() => _OverflowMarqueeState();
}

/// Chain sugar mirroring the Flutter `OverflowMarquee.withStyle`
/// extension — merges a [CoreOverflowMarqueeStyle] patch into
/// [OverflowMarquee.overflowMarqueeStyle] via the existing
/// [OverflowMarquee.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOverflowMarqueeStyle.merge` right-side-wins semantics).
extension OverflowMarqueeStyleChain on OverflowMarquee {
  /// Returns a copy of this [OverflowMarquee] with [patch] merged into
  /// [overflowMarqueeStyle] (patch fields win on conflict).
  OverflowMarquee withStyle(CoreOverflowMarqueeStyle patch) => copyWith(
    overflowMarqueeStyle:
        (overflowMarqueeStyle ?? const CoreOverflowMarqueeStyle()).merge(patch),
  );
}

class _OverflowMarqueeState extends State<OverflowMarquee> {
  /// Private DOM id owned by this State, independent of parent-local keys.
  late final String _scopeId;
  OverflowMarqueeMeasurer? _measurer;
  OverflowMarqueeConfig? _attachedConfig;

  @override
  void initState() {
    super.initState();
    _scopeId =
        'co-om-${kIsWeb ? 'web' : 'ssr'}-${_coOverflowMarqueeIdCounter++}';
  }

  OverflowMarqueeConfig _resolveConfig(BuildContext context) {
    return resolveOverflowMarqueeConfig(
      context,
      direction: component.direction,
      curve: component.curve,
      pauseOnHover: component.pauseOnHover,
      overflowMarqueeStyle: component.overflowMarqueeStyle,
    );
  }

  /// (Re)attaches the measurer when the resolved config changes.
  ///
  /// Measurer instances hold their config as `final` fields (axis,
  /// duration, delay, step, fadePortion, curve, pauseOnHover). If any
  /// of those change we dispose and reconstruct — the pattern
  /// `Select` uses for its `OverlayPositioner`. The
  /// [OverflowMarqueeConfig] record (value-equal) is the single
  /// source for the measurer config.
  void _ensureMeasurer(OverflowMarqueeConfig config) {
    if (!kIsWeb) return;
    if (_attachedConfig == config) return;
    _measurer?.dispose();
    _attachedConfig = config;
    _measurer = OverflowMarqueeMeasurer(
      // Keep in sync with the root element's id (caller id wins, else
      // the generated scope id) so the measurer queries the right node.
      containerId: component.id ?? _scopeId,
      trackSelector: '.co-om-track',
      axis: config.direction,
      duration: config.duration,
      delayDuration: config.delayDuration,
      step: config.step,
      fadePortion: config.fadePortion,
      curve: config.curve,
      pauseOnHover: config.pauseOnHover,
    )..attach();
  }

  @override
  void dispose() {
    _measurer?.dispose();
    _measurer = null;
    _attachedConfig = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final config = _resolveConfig(context);
    final resolved = resolveOverflowMarquee(context);
    // Schedule (re-)attach as a microtask so the container and track
    // are committed to the DOM before the measurer queries them.
    // Same pattern used by `Select` / `ScrollableClient`.
    if (kIsWeb) {
      scheduleMicrotask(() {
        if (mounted) _ensureMeasurer(config);
      });
    }

    // Fold the runtime scope id into the Category C config record to
    // compose the per-instance scoped `<style>` text. Mirrors
    // `ScrollArea` / `Loading`.
    // Caller id wins (passthrough) and also scopes the `<style>` + the
    // measurer's container query; else the generated per-instance id.
    final scopeId = component.id ?? _scopeId;
    final rulesCss = composeOverflowMarqueeCss(config, scopeId);

    return Component.element(
      tag: 'div',
      id: scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: [
        // Static per-instance rules: container clipping + fade mask
        // (alphas driven by `--co-om-fade-*-alpha` CSS variables the
        // measurer writes each frame) + track intrinsic sizing. The
        // `var()` fallbacks make SSR snapshots render correctly even
        // before the measurer takes over.
        Component.element(
          tag: 'style',
          children: [RawText(rulesCss)],
        ),
        // Intrinsic-sized track. `white-space: nowrap` + `width:
        // max-content` (set via the static stylesheet) keep the child
        // on a single line at its natural width — the geometry the
        // measurer reads to compute the overflow amount.
        Component.element(
          tag: 'div',
          classes: resolved.track.className,
          styles: resolved.track.inlineStyles,
          children: [component.child],
        ),
      ],
    );
  }
}
