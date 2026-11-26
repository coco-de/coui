import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/form/slider/slider_style.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

// Behaviour defaults (`value`, `min`, `max`) stay flat on the widget
// because they describe the slider's **range / state** (count /
// interval), not chrome — `CoreSliderStyle` is reserved for visual
// chrome only.

/// Default lower bound of the slider range.
const _kDefaultMin = 0.0;

/// Default upper bound of the slider range.
const _kDefaultMax = 100.0;

/// Unified cross-platform slider for CoUI Web.
///
/// Per Epic #1302 원칙 6/7, behaviour fields (value / range / step /
/// divisions / callbacks / enabled) stay flat on the widget because
/// they describe the slider's **state and interaction**. All chrome /
/// dimensional / nested-slot overrides flow through the single
/// [sliderStyle] (a [CoreSliderStyle]). Slider has no public variant
/// enum.
///
/// Example:
/// ```dart
/// Slider(
///   value: 50,
///   min: 0,
///   max: 100,
///   onChanged: (v) => print(v),
/// )
/// ```
class Slider extends UiStatefulComponent
    implements CoreSliderContract<Component> {
  /// Creates a [Slider].
  const Slider({
    super.key,
    this.value = _kDefaultMin,
    this.min = _kDefaultMin,
    this.max = _kDefaultMax,
    this.step,
    this.divisions,
    this.enabled = true,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.leading,
    this.trailing,
    this.sliderStyle,
    super.id,
  });

  @override
  final double value;

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
  final CoreValueChanged<double>? onChanged;

  @override
  final CoreValueChanged<double>? onChangeStart;

  @override
  final CoreValueChanged<double>? onChangeEnd;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreSliderStyle? sliderStyle;

  // === Internal ===

  static const _kDiv = 'div';
  static const _kTrackAttr = 'data-coui-slider-track';
  static const _kTrackSelector = '[data-coui-slider-track]';
  static const _kRoleAttr = 'role';
  static const _kRoleSlider = 'slider';
  static const _kAriaValueMinAttr = 'aria-valuemin';
  static const _kAriaValueMaxAttr = 'aria-valuemax';
  static const _kAriaValueNowAttr = 'aria-valuenow';
  static const _kAriaDisabledAttr = 'aria-disabled';
  static const _kTrue = 'true';
  // Trigger on pointerdown (not mousedown): the drag listeners are
  // pointer events, and on touch devices the compatibility mousedown
  // fires after the gesture's pointerup — registering from it would
  // leak the document listeners.
  static const _kPointerDownEvent = 'pointerdown';
  static const _kKeyDownEvent = 'keydown';
  static const _kTabIndexAttr = 'tabindex';
  static const _kFocusableTabIndex = '0';
  // Arrow-key step is the caller's `step`, else one `divisions` tick,
  // else 1% of the range (ARIA APG "Slider" pattern default — matches
  // the native `<input type=range>` implicit step when none is given).
  static const _kDefaultArrowStepFraction = 0.01;
  // Page keys move by a coarser jump than a single arrow press — 10×
  // the arrow step, the same ratio browsers use for native range
  // inputs' PageUp/PageDown.
  static const _kPageStepMultiplier = 10;

  /// Returns a copy of this [Slider] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Slider copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    double? value,
    double? min,
    double? max,
    double? step,
    int? divisions,
    bool? enabled,
    CoreValueChanged<double>? onChanged,
    CoreValueChanged<double>? onChangeStart,
    CoreValueChanged<double>? onChangeEnd,
    Component? leading,
    Component? trailing,
    CoreSliderStyle? sliderStyle,
  }) {
    return Slider(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      divisions: divisions ?? this.divisions,
      enabled: enabled ?? this.enabled,
      onChangeStart: onChangeStart ?? this.onChangeStart,
      onChangeEnd: onChangeEnd ?? this.onChangeEnd,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      sliderStyle: sliderStyle ?? this.sliderStyle,
      id: id ?? this.id,
    );
  }

  @override
  State<Slider> createState() => _SliderState();

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes
      ..add(_kRoleAttr, _kRoleSlider)
      ..add(_kAriaValueMinAttr, min.toString())
      ..add(_kAriaValueMaxAttr, max.toString())
      ..add(_kAriaValueNowAttr, value.toString());
    if (!enabled) {
      attributes.add(_kAriaDisabledAttr, _kTrue);
    }
    // Keyboard-focusable only when interactive (matches the Flutter
    // `FocusableActionDetector(enabled:)`), so the resolved
    // `focus-visible:` outline only ever appears on a control that can
    // actually take keyboard input.
    if (enabled && onChanged != null) {
      attributes.add(_kTabIndexAttr, _kFocusableTabIndex);
    }
  }
}

class _SliderState extends State<Slider> {
  /// Tracks `:focus-visible` on the root to drive [FocusOutline] — the
  /// browser only matches it for keyboard-originated focus, which is the
  /// same gate the Flutter twin applies to `FocusableActionDetector`'s
  /// highlight.
  bool _focused = false;

  /// The last value this gesture dispatched through `onChanged`.
  ///
  /// `onChangeEnd` reports it rather than `component.value`, which a
  /// controlled parent may not have echoed back yet when the pointer
  /// comes up. Null before any pointer movement in the current gesture.
  double? _dragValue;
  bool _dragging = false;
  void Function()? _detachDrag;

  @override
  void didUpdateComponent(Slider oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!component.enabled ||
        component.onChanged == null ||
        oldComponent.min != component.min ||
        oldComponent.max != component.max) {
      _detachDrag?.call();
      _detachDrag = null;
      _dragging = false;
      _dragValue = null;
    }
  }

  @override
  void dispose() {
    _detachDrag?.call();
    super.dispose();
  }

  // === Private helpers ===

  /// Promotes a pointer-focused slider back to a visible focus, which is
  /// when the ring becomes meaningful. Called only from the keys this
  /// component handles, matching the Flutter twin's promote points
  /// (`_promotePointerFocus`, reached from its shortcut actions).
  void _promotePointerFocus() {
    if (!_focused) setState(() => _focused = true);
  }

  double _ratioToValue(double ratio) {
    final range = component.max - component.min;
    var r = ratio;

    final div = component.divisions;
    if (div != null && div > 0) {
      r = (r * div).round() / div;
    }

    var newValue = component.min + r * range;

    final s = component.step;
    if (s != null && s > 0) {
      newValue = (newValue / s).round() * s;
    }

    return newValue.clamp(component.min, component.max);
  }

  /// Maps a pointer x to a value. The thumb travels `trackWidth -
  /// thumbSize` — its edges, not its centre, stop at the track ends — so
  /// the pointer maps over that same span. Mapping over the full width
  /// instead would put the cursor up to half a thumb away from the thumb
  /// centre it is dragging, worst at the ends.
  void _handleEvent(Object event, Object target, double thumbSize) {
    final cb = component.onChanged;
    if (!_dragging || !component.enabled || cb == null) return;
    final ratio = getMouseRatio(event, target, travelInset: thumbSize);
    if (ratio == null) return;
    final value = _ratioToValue(ratio);
    // Held so the gesture can report where it finished. A controlled
    // parent may not have echoed the last `onChanged` back into
    // `component.value` by the time the pointer comes up.
    setState(() => _dragValue = value);
    cb(value);
  }

  /// Closes a pointer gesture, reporting where it finished.
  ///
  /// Falls back to `component.value` when the press never moved the
  /// thumb, so `onChangeEnd` still reports a real value rather than
  /// staying silent.
  void _endDrag() {
    if (!_dragging) return;
    final value = _dragValue ?? component.value;
    _detachDrag?.call();
    _detachDrag = null;
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
    component.onChangeEnd?.call(value);
  }

  /// Arrow-key step — the caller's [step], else one [divisions] tick,
  /// else [_kDefaultArrowStepFraction] of the `[min, max]` range.
  double get _arrowStep {
    final step = component.step;
    if (step != null && step > 0) return step;
    final divisions = component.divisions;
    final range = component.max - component.min;
    if (divisions != null && divisions > 0) return range / divisions;
    return range * Slider._kDefaultArrowStepFraction;
  }

  /// ARIA APG "Slider" keyboard interaction — Right/Up increase,
  /// Left/Down decrease (one [_arrowStep]), PageUp/PageDown move by
  /// [_kPageStepMultiplier]× that, Home/End jump to [min]/[max].
  void _handleKeyDown(web.KeyboardEvent event) {
    final cb = component.onChanged;
    if (!component.enabled || cb == null) return;

    final delta = switch (event.key) {
      'ArrowRight' || 'ArrowUp' => _arrowStep,
      'ArrowLeft' || 'ArrowDown' => -_arrowStep,
      'PageUp' => _arrowStep * Slider._kPageStepMultiplier,
      'PageDown' => -_arrowStep * Slider._kPageStepMultiplier,
      _ => null,
    };
    if (delta != null) {
      preventDefault(event);
      _promotePointerFocus();
      cb((component.value + delta).clamp(component.min, component.max));
      return;
    }
    switch (event.key) {
      case 'Home':
        preventDefault(event);
        _promotePointerFocus();
        cb(component.min);
      case 'End':
        preventDefault(event);
        _promotePointerFocus();
        cb(component.max);
    }
  }

  @override
  Component build(BuildContext context) {
    final component = this.component;
    final range = component.max - component.min;
    final ratio = range > 0
        ? (((_dragValue ?? component.value) - component.min) / range).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolveSlider(
      context,
      enabled: component.enabled,
      ratio: ratio,
      sliderStyle: component.sliderStyle,
    );
    final runtime = resolveSliderRuntime(
      context,
      sliderStyle: component.sliderStyle,
    );

    final userClasses = component.classes;
    // Pointer target expansion (WCAG 2.5.8) — mirrors Flutter's
    // `TouchTarget` wrap. The track/thumb draw at their design height
    // (under the 24px floor); the marker only widens where a pointer is
    // accepted around the root, on the axis that is short.
    final baseClasses = '${resolved.root.className} $kWebTouchTargetMarker';
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? baseClasses
        : '$baseClasses $userClasses';

    return Component.element(
      tag: Slider._kDiv,
      id: component.id,
      classes: finalClasses,
      styles: resolved.root.inlineStyles == null
          ? component.css
          : Styles.combine([resolved.root.inlineStyles!, ?component.css]),
      attributes: component.componentAttributes,
      events: {
        ...component.events,
        // The ring is Dart-driven here because `FocusOutline` takes a
        // boolean, so the `:focus-visible` match the browser already
        // computed is read off the target and forwarded — same gate,
        // same source of truth as a CSS `focus-visible:` utility would
        // have used. Typed handler: dart2js release minifies dynamic
        // `event.target` dispatches into mangled names that compile-graph
        // changes can desync, which would strand the ring in its
        // unfocused state in production.
        'focus': EventHandlers.createElementTargetEventHandler(
          (_, target) =>
              setState(() => _focused = target.matches(':focus-visible')),
        ),
        'blur': (_) => setState(() => _focused = false),
        if (component.enabled && component.onChanged != null) ...{
          Slider._kPointerDownEvent: (event) {
            if (_dragging ||
                (event is web.PointerEvent &&
                    (!event.isPrimary || event.button != 0)))
              return;
            // The pointer maps over the track box, not the root — the root
            // also holds the leading / trailing slots — and a press on a
            // slot is not a press on the slider.
            final root = event.currentTarget;
            if (root == null) return;
            final target = (root as web.Element).querySelector(
              Slider._kTrackSelector,
            );
            if (target == null) return;
            final origin = event.target;
            if (origin != null && !target.contains(origin as web.Node)) {
              return;
            }
            // Grabbing the slider hides the ring even when it was
            // already showing. `:focus-visible` is only read on the
            // `focus` event, which does not re-fire for a pointer
            // press on an element that already holds focus — without
            // this the ring survives a mouse drag that started from a
            // keyboard-focused slider, while the Flutter twin drops
            // it (`_focusFromPointer`).
            if (_focused) setState(() => _focused = false);
            // Ahead of the first change, reporting the pre-press
            // value — same order and same value as the Flutter twin,
            // which fires this before its own first update.
            _dragging = true;
            _dragValue = null;
            component.onChangeStart?.call(component.value);
            _handleEvent(event, target, runtime.thumbSize);
            _detachDrag = registerDragListeners(
              onMove: (e) => _handleEvent(e, target, runtime.thumbSize),
              onUp: (_) => _endDrag(),
              // A gesture the browser aborts (touch turned scroll, OS
              // stole the pointer) still has to close the start / end
              // pair — a consumer that opened state on start would
              // otherwise never get to close it. The contract carries
              // no separate cancel signal, and adding one that only
              // Web could ever raise would plant exactly the kind of
              // never-read field this change set exists to remove.
              onCancel: (_) => _endDrag(),
              downEvent: event,
            );
          },
          Slider._kKeyDownEvent: EventHandlers.createKeyboardEventHandler(
            _handleKeyDown,
          ),
        },
      },
      children: [
        if (component.leading != null) ...[
          component.leading!,
          Gap(gapStyle: resolved.slotGapStyle),
        ],
        div(
          [
            div(
              [
                div(
                  [],
                  classes: resolved.fill.className,
                  styles: resolved.fill.inlineStyles,
                ),
              ],
              classes: resolved.track.className,
              styles: resolved.track.inlineStyles,
            ),
            // The ring is `FocusOutline`'s job on both platforms — it
            // wraps the thumb, which is where the keyboard focus sits.
            FocusOutline(
              focused: _focused,
              focusOutlineStyle: resolved.focusOutlineStyle,
              classes: resolved.thumbHost.className,
              css: resolved.thumbHost.inlineStyles,
              child: div(
                [],
                classes: resolved.thumb.className,
                styles: resolved.thumb.inlineStyles,
              ),
            ),
          ],
          classes: resolved.interior.className,
          styles: resolved.interior.inlineStyles,
          attributes: const {Slider._kTrackAttr: ''},
        ),
        if (component.trailing != null) ...[
          Gap(gapStyle: resolved.slotGapStyle),
          component.trailing!,
        ],
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Slider.withStyle` extension —
/// merges a [CoreSliderStyle] patch into [Slider.sliderStyle] via the
/// existing [Slider.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSliderStyle.merge` right-side-wins semantics).
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
/// sets [CoreSliderStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Slider(value: 50, onChanged: (v) {}).radius4
/// ```
extension SliderStyleChain on Slider {
  /// Returns a copy of this [Slider] with [patch] merged into
  /// [sliderStyle] (patch fields win on conflict).
  Slider withStyle(CoreSliderStyle patch) => copyWith(
    sliderStyle: (sliderStyle ?? const CoreSliderStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Slider get radius0 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Slider get radius2 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Slider get radius4 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Slider get radius6 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Slider get radius8 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Slider get radius10 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Slider get radius12 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Slider get radius14 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Slider get radius16 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Slider get radius20 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Slider get radius24 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Slider get radius28 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Slider get radius32 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Slider get radius36 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Slider get radius40 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Slider get radius48 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Slider get radius56 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Slider get radius64 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Slider get radius9999 => withStyle(
    const CoreSliderStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
