import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/range/range_style.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

// Arrow-key step is the caller's `step`, else one `divisions` tick,
// else 1% of the `[min, max]` range (ARIA APG "Slider" pattern default
// — matches the native `<input type=range>` implicit step when none is
// given). Page keys move by `_kPageStepMultiplier`× that.
const _kDefaultArrowStepFraction = 0.01;
const _kPageStepMultiplier = 10;

/// Unified cross-platform dual-handle range slider for CoUI Web.
///
/// Unlike `Slider` (single value), `Range` selects a `[minValue,
/// maxValue]` interval within the `[min, max]` bounds. Uses custom
/// `<div>` rendering with drag handling for visual parity with
/// Flutter `Range` — no native `<input type="range">`.
///
/// Per Epic #1302 원칙 6/7, behaviour fields (`minValue` / `maxValue` /
/// `min` / `max` / `step` / `divisions` / `enabled` / `onChanged`) and
/// composition slots (`leading` / `trailing`) stay flat on the widget.
/// All chrome / dimensional overrides flow through the single
/// [rangeStyle] (a [CoreRangeStyle]).
///
/// Example:
/// ```dart
/// Range(
///   minValue: 20,
///   maxValue: 80,
///   onChanged: (min, max) => print('Range: $min - $max'),
/// )
/// ```
class Range extends UiStatefulComponent
    implements CoreRangeContract<Component> {
  /// Creates a [Range].
  const Range({
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
    this.minValue = CoreRangeContract.defaultMin,
    this.maxValue = CoreRangeContract.defaultMax,
    this.min = CoreRangeContract.defaultMin,
    this.max = CoreRangeContract.defaultMax,
    this.step,
    this.divisions,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.rangeStyle,
  });

  @override
  final double minValue;

  @override
  final double maxValue;

  @override
  final double min;

  @override
  final double max;

  @override
  final double? step;

  @override
  final int? divisions;

  @override
  final bool enabled;

  @override
  final void Function(double, double)? onChanged;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  // === Style (chrome / dimensional) ===

  @override
  final CoreRangeStyle? rangeStyle;

  /// Returns a copy of this [Range] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Range copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    void Function(double, double)? onChanged,
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
    double? minValue,
    double? maxValue,
    double? min,
    double? max,
    double? step,
    int? divisions,
    bool? enabled,
    Component? leading,
    Component? trailing,
    CoreRangeStyle? rangeStyle,
  }) {
    return Range(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
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
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      divisions: divisions ?? this.divisions,
      enabled: enabled ?? this.enabled,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      rangeStyle: rangeStyle ?? this.rangeStyle,
    );
  }

  @override
  State<Range> createState() => _RangeState();
}

/// Chain sugar mirroring the Flutter `Range.withStyle` extension —
/// merges a [CoreRangeStyle] patch into [Range.rangeStyle] via the
/// existing [Range.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreRangeStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` primitive — the
/// getter *name* is the token name, so `.radius4` always means
/// `CoreRadius.radius4`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreRangeStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Range(minValue: 20, maxValue: 80).radius4
/// ```
extension RangeStyleChain on Range {
  /// Returns a copy of this [Range] with [patch] merged into
  /// [rangeStyle] (patch fields win on conflict).
  Range withStyle(CoreRangeStyle patch) => copyWith(
    rangeStyle: (rangeStyle ?? const CoreRangeStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Range get radius0 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Range get radius2 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Range get radius4 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Range get radius6 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Range get radius8 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Range get radius10 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Range get radius12 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Range get radius14 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Range get radius16 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Range get radius20 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Range get radius24 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Range get radius28 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Range get radius32 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Range get radius36 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Range get radius40 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Range get radius48 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Range get radius56 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Range get radius64 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Range get radius9999 => withStyle(
    const CoreRangeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}

class _RangeState extends State<Range> {
  // Which handle the current drag is moving: 'min', 'max', or null.
  String? _activeHandle;

  /// Tracks `:focus-visible` per thumb to drive each one's
  /// [FocusOutline]. The browser only matches it for keyboard-originated
  /// focus, which is the gate the Flutter twin applies to
  /// `FocusableActionDetector`'s highlight.
  bool _minFocused = false;
  bool _maxFocused = false;

  /// Promotes a pointer-focused thumb back to a visible focus, which is
  /// when the ring becomes meaningful. Called only from the keys this
  /// component handles, matching the Flutter twin's promote points.
  void _promotePointerFocus({required bool isMin}) {
    if (isMin ? _minFocused : _maxFocused) return;
    setState(() {
      if (isMin) {
        _minFocused = true;
      } else {
        _maxFocused = true;
      }
    });
  }

  double _ratioOf(double value) {
    final range = component.max - component.min;
    if (range <= 0) return 0;
    return ((value - component.min) / range).clamp(0.0, 1.0);
  }

  double _ratioToValue(double ratio) {
    final range = component.max - component.min;
    var r = ratio.clamp(0.0, 1.0);

    final divisions = component.divisions;
    if (divisions != null && divisions > 0) {
      r = (r * divisions).round() / divisions;
    }

    var newValue = component.min + r * range;

    final step = component.step;
    if (step != null && step > 0) {
      newValue = (newValue / step).round() * step;
    }

    return newValue.clamp(component.min, component.max);
  }

  /// Maps a pointer x to a value. A thumb travels `trackWidth -
  /// thumbSize` — its edges, not its centre, stop at the track ends — so
  /// the pointer maps over that same span. Mapping over the full width
  /// instead would put the cursor up to half a thumb away from the thumb
  /// centre it is dragging, worst at the ends.
  void _handleEvent(Object event, Object target, double thumbSize) {
    final onChanged = component.onChanged;
    if (!component.enabled || onChanged == null) return;
    // Grabbing the track hides the ring even when it was already
    // showing — `:focus-visible` is only read on the `focus` event,
    // which does not re-fire for a pointer press on an element that
    // already holds focus (the Flutter twin drops it the same way).
    if (_minFocused || _maxFocused) {
      setState(() {
        _minFocused = false;
        _maxFocused = false;
      });
    }
    final ratio = getMouseRatio(event, target, travelInset: thumbSize);
    if (ratio == null) return;

    var handle = _activeHandle;
    if (handle == null) {
      final minDist = (ratio - _ratioOf(component.minValue)).abs();
      final maxDist = (ratio - _ratioOf(component.maxValue)).abs();
      handle = maxDist < minDist ? 'max' : 'min';
      _activeHandle = handle;
    }

    final value = _ratioToValue(ratio);
    if (handle == 'min') {
      onChanged(
        value.clamp(component.min, component.maxValue),
        component.maxValue,
      );
    } else {
      onChanged(
        component.minValue,
        value.clamp(component.minValue, component.max),
      );
    }
  }

  /// Arrow-key step — the caller's `step`, else one `divisions` tick,
  /// else [_kDefaultArrowStepFraction] of the `[min, max]` range.
  double get _arrowStep {
    final step = component.step;
    if (step != null && step > 0) return step;
    final divisions = component.divisions;
    if (divisions != null && divisions > 0) {
      return (component.max - component.min) / divisions;
    }
    return (component.max - component.min) * _kDefaultArrowStepFraction;
  }

  /// ARIA APG "Slider (Multi-Thumb)" keyboard interaction for one
  /// thumb — Right/Up increase, Left/Down decrease (one [_arrowStep]),
  /// PageUp/PageDown move by [_kPageStepMultiplier]× that, Home/End
  /// jump to this thumb's bound. [isMin] selects which value this
  /// thumb owns and which sibling value bounds it (mirrors
  /// `_handleEvent`'s mutual clamp).
  void _handleThumbKeyDown(web.KeyboardEvent event, {required bool isMin}) {
    final onChanged = component.onChanged;
    if (!component.enabled || onChanged == null) return;
    final lowerBound = isMin ? component.min : component.minValue;
    final upperBound = isMin ? component.maxValue : component.max;
    final current = isMin ? component.minValue : component.maxValue;

    double? next;
    switch (event.key) {
      case 'ArrowRight' || 'ArrowUp':
        next = current + _arrowStep;
      case 'ArrowLeft' || 'ArrowDown':
        next = current - _arrowStep;
      case 'PageUp':
        next = current + _arrowStep * _kPageStepMultiplier;
      case 'PageDown':
        next = current - _arrowStep * _kPageStepMultiplier;
      case 'Home':
        next = lowerBound;
      case 'End':
        next = upperBound;
    }
    if (next == null) return;
    preventDefault(event);
    final clamped = next.clamp(lowerBound, upperBound);
    if (isMin) {
      onChanged(clamped, component.maxValue);
    } else {
      onChanged(component.minValue, clamped);
    }
  }

  @override
  Component build(BuildContext context) {
    final leading = component.leading;
    final trailing = component.trailing;

    final range = component.max - component.min;
    final minRatio = range > 0
        ? ((component.minValue - component.min) / range).clamp(0.0, 1.0)
        : 0.0;
    final maxRatio = range > 0
        ? ((component.maxValue - component.min) / range).clamp(0.0, 1.0)
        : 0.0;
    final resolved = resolveRange(
      context,
      enabled: component.enabled,
      minRatio: minRatio,
      maxRatio: maxRatio,
      rangeStyle: component.rangeStyle,
    );
    final runtime = resolveRangeRuntime(
      context,
      rangeStyle: component.rangeStyle,
    );

    final interactive = component.enabled && component.onChanged != null;
    final locale = CouiLocalizations.of(context);

    final fill = div(
      const [],
      classes: resolved.fill.className,
      styles: resolved.fill.inlineStyles,
    );

    // Each thumb is its own `role="slider"` — a combined single tabstop
    // can't sensibly report *two* independent values (WCAG 4.1.2 needs
    // a single `aria-valuenow`), and can't be operated by arrow keys
    // either (there'd be no way to say "which edge am I moving"). Bounds
    // are mutually clamped — the min thumb's upper bound is the max
    // thumb's current value and vice versa — mirroring the drag
    // interaction's existing clamp (`_handleEvent` below).
    // `kWebTouchTargetMarker` on each thumb — pointer target expansion
    // (WCAG 2.5.8), mirrors Flutter's `TouchTarget` wrap. The thumb
    // draws at `thumbSize` (20px, under the 24px floor); the marker only
    // widens where a pointer is accepted around it.
    final minThumb = FocusOutline(
      focused: _minFocused,
      shape: .circle,
      focusOutlineStyle: resolved.focusOutlineStyle,
      classes: resolved.minThumbPositioner.className,
      css: resolved.minThumbPositioner.inlineStyles,
      child: div(
        const [],
        classes: '${resolved.minThumb.className} $kWebTouchTargetMarker',
        styles: resolved.minThumb.inlineStyles,
        attributes: {
          'role': 'slider',
          'aria-valuemin': component.min.toString(),
          'aria-valuemax': component.maxValue.toString(),
          'aria-valuenow': component.minValue.toString(),
          'aria-label': locale.rangeMinValueLabel,
          if (!component.enabled) 'aria-disabled': 'true',
          if (interactive) 'tabindex': '0',
        },
        events: interactive
            ? {
                'keydown': EventHandlers.createKeyboardEventHandler((event) {
                  _promotePointerFocus(isMin: true);
                  _handleThumbKeyDown(event, isMin: true);
                }),
                // Typed handler: dart2js release minifies dynamic
                // `event.target` dispatches into mangled names that
                // compile-graph changes can desync, which would strand the
                // ring in its unfocused state in production.
                'focus': EventHandlers.createElementTargetEventHandler(
                  (_, target) => setState(
                    () => _minFocused = target.matches(':focus-visible'),
                  ),
                ),
                'blur': (_) => setState(() => _minFocused = false),
              }
            : null,
      ),
    );

    final maxThumb = FocusOutline(
      focused: _maxFocused,
      shape: .circle,
      focusOutlineStyle: resolved.focusOutlineStyle,
      classes: resolved.maxThumbPositioner.className,
      css: resolved.maxThumbPositioner.inlineStyles,
      child: div(
        const [],
        classes: '${resolved.maxThumb.className} $kWebTouchTargetMarker',
        styles: resolved.maxThumb.inlineStyles,
        attributes: {
          'role': 'slider',
          'aria-valuemin': component.minValue.toString(),
          'aria-valuemax': component.max.toString(),
          'aria-valuenow': component.maxValue.toString(),
          'aria-label': locale.rangeMaxValueLabel,
          if (!component.enabled) 'aria-disabled': 'true',
          if (interactive) 'tabindex': '0',
        },
        events: interactive
            ? {
                'keydown': EventHandlers.createKeyboardEventHandler((event) {
                  _promotePointerFocus(isMin: false);
                  _handleThumbKeyDown(event, isMin: false);
                }),
                // Typed handler: dart2js release minifies dynamic
                // `event.target` dispatches into mangled names that
                // compile-graph changes can desync, which would strand the
                // ring in its unfocused state in production.
                'focus': EventHandlers.createElementTargetEventHandler(
                  (_, target) => setState(
                    () => _maxFocused = target.matches(':focus-visible'),
                  ),
                ),
                'blur': (_) => setState(() => _maxFocused = false),
              }
            : null,
      ),
    );

    final track = Component.element(
      tag: 'div',
      classes: resolved.track.className,
      styles: resolved.track.inlineStyles,
      events: interactive
          ? {
              // Trigger on pointerdown because the drag listeners are pointer
              // events — on touch devices the compatibility mousedown fires after
              // the gesture's pointerup and would leak them.
              'pointerdown': (event) {
                final target = event.currentTarget;
                if (target == null) return;
                _activeHandle = null;
                _handleEvent(event, target, runtime.thumbSize);
                registerDragListeners(
                  onMove: (e) => _handleEvent(e, target, runtime.thumbSize),
                  onUp: (_) => _activeHandle = null,
                  downEvent: event,
                );
              },
            }
          : null,
      children: [fill, minThumb, maxThumb],
    );

    // Explicit `Gap` on either side of the track owns the spacing
    // between the slider and its optional `leading` / `trailing` slots
    // — mirroring the Flutter widget. `Gap` runs its own resolve /
    // scaling step from the nested `minMaxGapStyle` slot.
    final gap = Gap(gapStyle: resolved.minMaxGapStyle);

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
        if (leading != null) ...[leading, gap],
        track,
        if (trailing != null) ...[gap, trailing],
      ],
    );
  }
}
