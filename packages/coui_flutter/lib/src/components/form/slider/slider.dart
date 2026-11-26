import 'package:coui_flutter/coui_flutter.dart';

// Behaviour defaults (`value`, `min`, `max`) stay flat on the widget because
// they describe the slider's **range / state** (count / interval), not chrome
// — `CoreSliderStyle` is reserved for visual chrome only.

/// Default lower bound of the slider range.
const _kDefaultMin = 0.0;

/// Default upper bound of the slider range.
const _kDefaultMax = 100.0;

/// Arrow-key step fraction of the `[min, max]` range when neither `step`
/// nor `divisions` is set (ARIA APG "Slider" pattern default).
const _kDefaultArrowStepFraction = 0.01;

/// Page-key step multiplier over a single arrow-key step.
const _kPageStepMultiplier = 10.0;

/// Unified cross-platform slider with token-based rendering.
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
///   onChanged: (v) => setState(() => _value = v),
/// )
/// ```
class Slider extends StatefulWidget implements CoreSliderContract<Widget> {
  /// Creates a [Slider].
  const Slider({
    this.value = _kDefaultMin,
    super.key,
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
  final ValueChanged<double>? onChanged;

  @override
  final ValueChanged<double>? onChangeStart;

  @override
  final ValueChanged<double>? onChangeEnd;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreSliderStyle? sliderStyle;

  /// Returns a copy of this [Slider] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Slider copyWith({
    Key? key,
    ValueChanged<double>? onChanged,
    double? value,
    double? min,
    double? max,
    double? step,
    int? divisions,
    bool? enabled,
    ValueChanged<double>? onChangeStart,
    ValueChanged<double>? onChangeEnd,
    Widget? leading,
    Widget? trailing,
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
    );
  }

  @override
  State<Slider> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  double _dragValue = 0;
  bool _isDragging = false;
  bool _focused = false;

  /// Whether the current focus arrived from a pointer rather than the
  /// keyboard. Flutter's focus highlight runs in `traditional` mode
  /// whenever the last input was a mouse, so it fires for pointer-
  /// initiated focus too — the Web twin's `focus-visible:` outline does
  /// not. Tracking the origin keeps the outline keyboard-only on both
  /// platforms while a click / drag still takes focus, so arrow keys
  /// keep working right after a drag.
  bool _pointerFocus = false;

  final _focusNode = FocusNode(debugLabel: 'Slider');

  /// The focus outline shows only for keyboard-originated focus —
  /// `:focus-visible` parity with the Web twin.
  bool get _showFocusOutline => _focused && !_pointerFocus;

  /// Takes focus for a pointer interaction without revealing the focus
  /// outline. The node still gets focus so the arrow / page / home / end
  /// shortcuts work immediately after a click or drag.
  void _focusFromPointer() {
    setState(() {
      _pointerFocus = true;
      // A node that already held keyboard focus keeps it here, so the
      // highlight callback would not fire — drop the outline directly.
      _focused = false;
    });
    _focusNode.requestFocus();
  }

  /// Promotes pointer-originated focus to keyboard focus once a keyboard
  /// shortcut arrives, which is when the outline becomes meaningful.
  /// Mirrors the browser turning `:focus-visible` on after a key press.
  void _promotePointerFocus() {
    if (!_pointerFocus) return;
    setState(() {
      _pointerFocus = false;
      _focused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Slider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || widget.onChanged == null) _isDragging = false;
  }

  void _finishDrag() {
    if (!_isDragging) return;
    final value = _dragValue;
    setState(() => _isDragging = false);
    widget.onChangeEnd?.call(value);
  }

  /// Arrow-key step — the caller's `step`, else one `divisions` tick,
  /// else 1% of the `[min, max]` range (ARIA APG "Slider" pattern
  /// default — matches the Web twin's `_arrowStep` 1:1).
  double get _arrowStep {
    if (widget.step != null && widget.step! > 0) return widget.step!;
    if (widget.divisions != null && widget.divisions! > 0) {
      return (widget.max - widget.min) / widget.divisions!;
    }
    return (widget.max - widget.min) * _kDefaultArrowStepFraction;
  }

  void _adjustBy(double delta) {
    final cb = widget.onChanged;
    if (!widget.enabled || cb == null) return;
    _promotePointerFocus();
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    _dragValue = next;
    cb(next);
  }

  void _jumpTo(double value) {
    final cb = widget.onChanged;
    if (!widget.enabled || cb == null) return;
    _promotePointerFocus();
    final next = value.clamp(widget.min, widget.max);
    _dragValue = next;
    cb(next);
  }

  double get _normalizedValue {
    final range = widget.max - widget.min;
    if (range <= 0) return 0;
    return ((_isDragging ? _dragValue : widget.value) - widget.min) / range;
  }

  /// Maps a pointer x to a value. The thumb travels `trackWidth -
  /// thumbSize` — its left edge starts at 0 and its right edge stops at
  /// the track end — so the pointer maps over that same span, offset by
  /// half a thumb. Mapping over the full width instead would put the
  /// cursor up to `thumbSize / 2` away from the thumb centre it is
  /// dragging, worst at the ends.
  void _handleUpdate(double localX, double trackWidth, double thumbSize) {
    if (!widget.enabled || widget.onChanged == null) return;
    final range = widget.max - widget.min;
    final travel = trackWidth - thumbSize;
    var ratio = travel > 0
        ? ((localX - thumbSize / 2) / travel).clamp(0.0, 1.0)
        : 0.0;

    // Snap to divisions.
    if (widget.divisions != null && widget.divisions! > 0) {
      ratio = (ratio * widget.divisions!).round() / widget.divisions!;
    }

    var newValue = widget.min + ratio * range;

    // Snap to step.
    if (widget.step != null && widget.step! > 0) {
      newValue = (newValue / widget.step!).round() * widget.step!;
    }

    newValue = newValue.clamp(widget.min, widget.max);
    setState(() => _dragValue = newValue);
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    // All chrome / dimensional / typography resolution (merge chain,
    // token fallback, `scheme.resolve`, scaling, typography composition)
    // happens inside `resolveSlider`. This widget owns layout, geometry
    // (`_normalizedValue` / `thumbOffset`) and interaction only — it reads
    // paint-ready values off `resolved` and never touches `theme.scaling`,
    // `colorScheme`, or the merge chain itself (Epic #1603 C1/C7/C11).
    final resolved = resolveSlider(
      context,
      enabled: widget.enabled,
      sliderStyle: widget.sliderStyle,
    );

    final trackH = resolved.trackHeight;
    final thumbS = resolved.thumbSize;
    final ratio = _normalizedValue.clamp(0.0, 1.0);
    final interactive = widget.enabled && widget.onChanged != null;

    // Web twin: role="slider" with aria-valuemin/max/now.
    return Semantics(
      slider: true,
      value: '${widget.value}',
      child: DefaultTextStyle.merge(
        style: resolved.tickLabelTextStyle,
        child: _withSlots(
          resolved,
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbOffset = ratio * (trackWidth - thumbS);

              final slider = FocusableActionDetector(
                enabled: interactive,
                focusNode: _focusNode,
                shortcuts: const {
                  SingleActivator(.arrowRight): _SliderDeltaIntent(1),
                  SingleActivator(.arrowUp): _SliderDeltaIntent(1),
                  SingleActivator(.arrowLeft): _SliderDeltaIntent(-1),
                  SingleActivator(.arrowDown): _SliderDeltaIntent(-1),
                  SingleActivator(.pageUp): _SliderDeltaIntent(
                    _kPageStepMultiplier,
                  ),
                  SingleActivator(.pageDown): _SliderDeltaIntent(
                    -_kPageStepMultiplier,
                  ),
                  SingleActivator(.home): _SliderJumpIntent(.min),
                  SingleActivator(.end): _SliderJumpIntent(.max),
                },
                actions: {
                  _SliderDeltaIntent: CallbackAction<_SliderDeltaIntent>(
                    onInvoke: (intent) {
                      _adjustBy(intent.stepMultiplier * _arrowStep);
                      return null;
                    },
                  ),
                  _SliderJumpIntent: CallbackAction<_SliderJumpIntent>(
                    onInvoke: (intent) {
                      _jumpTo(intent.target == .min ? widget.min : widget.max);
                      return null;
                    },
                  ),
                },
                onShowFocusHighlight: (v) => setState(() {
                  _focused = v;
                  // Losing focus ends the pointer-originated episode, so the
                  // next Tab into the slider shows the outline again.
                  if (!v) _pointerFocus = false;
                }),
                child: GestureDetector(
                  onTapDown: interactive
                      ? (d) {
                          _focusFromPointer();
                          _handleUpdate(d.localPosition.dx, trackWidth, thumbS);
                        }
                      : null,
                  onHorizontalDragStart: interactive
                      ? (d) {
                          _focusFromPointer();
                          setState(() => _isDragging = true);
                          // Ahead of the first update, so a consumer sees
                          // start → changed → end. `widget.value` rather
                          // than `_dragValue`, which no drag has written
                          // yet and would report 0 from a cold start.
                          widget.onChangeStart?.call(widget.value);
                          _handleUpdate(d.localPosition.dx, trackWidth, thumbS);
                        }
                      : null,
                  onHorizontalDragUpdate: interactive
                      ? (d) => _handleUpdate(
                          d.localPosition.dx,
                          trackWidth,
                          thumbS,
                        )
                      : null,
                  onHorizontalDragEnd: interactive
                      ? (_) => _finishDrag()
                      : null,
                  onHorizontalDragCancel: interactive ? _finishDrag : null,
                  child: MouseRegion(
                    cursor: interactive
                        ? SystemMouseCursors.grab
                        : SystemMouseCursors.forbidden,
                    // The keyboard focus ring is `FocusOutline`'s job on
                    // both platforms — drawing it here instead would be a
                    // second ring implementation whose geometry only
                    // matches the Web twin's for as long as someone keeps
                    // matching it by hand.
                    child: SizedBox(
                      height: thumbS,
                      child: Stacks(
                        alignment: .centerStart,
                        // The focus ring around the thumb paints outside the
                        // row's box.
                        clipBehavior: .none,
                        children: [
                          // Track background.
                          Container(
                            decoration: BoxDecoration(
                              color: resolved.trackColor,
                              borderRadius: resolved.borderRadius,
                            ),
                            height: trackH,
                          ),
                          // Active track.
                          Position(
                            left: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: resolved.activeColor,
                                borderRadius: resolved.borderRadius,
                              ),
                              width: thumbOffset + thumbS / 2,
                              height: trackH,
                            ),
                          ),
                          // Thumb, with the keyboard focus ring around it —
                          // `FocusOutline`'s job on both platforms.
                          Position(
                            left: thumbOffset,
                            child: FocusOutline(
                              focused: _showFocusOutline,
                              focusOutlineStyle: resolved.focusOutlineStyle,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: resolved.thumbColor,
                                  border: Border.all(
                                    color: resolved.thumbBorderColor,
                                    width: resolved.thumbBorderWidth,
                                  ),
                                  borderRadius: resolved.borderRadius,
                                  boxShadow: resolved.thumbShadow,
                                ),
                                width: thumbS,
                                height: thumbS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              return Padding(
                padding: resolved.containerPadding,
                // Pointer target expansion (WCAG 2.5.8) — the track/thumb draw
                // at `thumbSize` (20px, under the 24px floor); this only
                // widens where a pointer is accepted around them, on the axis
                // that is short. Width is already the full track and does not
                // move.
                child: TouchTarget(child: slider),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Lays the optional `leading` / `trailing` slots around the track. With
  /// neither set the track is returned untouched, so a slot-less slider
  /// keeps its exact layout.
  Widget _withSlots(ResolvedSlider resolved, Widget track) {
    final leading = widget.leading;
    final trailing = widget.trailing;
    if (leading == null && trailing == null) return track;
    return Row(
      children: [
        if (leading != null) ...[
          leading,
          Gap(gapStyle: resolved.slotGapStyle),
        ],
        Expanded(child: track),
        if (trailing != null) ...[
          Gap(gapStyle: resolved.slotGapStyle),
          trailing,
        ],
      ],
    );
  }
}

/// Which bound a [_SliderJumpIntent] (Home/End) jumps the slider to.
enum _SliderJumpTarget { min, max }

/// Arrow/Page key intent — `stepMultiplier` is `±1` for a single arrow
/// step or `±_kPageStepMultiplier` for Page Up/Down, multiplied by
/// `_SliderState._arrowStep` in the action.
class _SliderDeltaIntent extends Intent {
  const _SliderDeltaIntent(this.stepMultiplier);
  final double stepMultiplier;
}

/// Home/End intent — jumps straight to [target]'s bound.
class _SliderJumpIntent extends Intent {
  const _SliderJumpIntent(this.target);
  final _SliderJumpTarget target;
}

/// Chain sugar for merging a [CoreSliderStyle] patch into
/// [Slider.sliderStyle] without hand-reconstructing every field. Mirrors
/// the Web `Slider.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSliderStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Slider(value: 50, onChanged: (v) {}).withStyle(
///   CoreSliderStyle(trackHeight: 8),
/// )
/// ```
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
