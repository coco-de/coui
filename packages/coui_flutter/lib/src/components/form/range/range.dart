import 'package:coui_flutter/coui_flutter.dart';

/// Arrow-key step fraction of the `[min, max]` range when neither `step`
/// nor `divisions` is set (ARIA APG "Slider" pattern default — matches
/// the Web twin's `_kDefaultArrowStepFraction` 1:1).
const _kDefaultArrowStepFraction = 0.01;

/// Page-key step multiplier over a single arrow-key step.
const _kPageStepMultiplier = 10.0;

/// Unified cross-platform dual-handle range slider.
///
/// Unlike [Slider] (single value), `Range` selects a `[minValue,
/// maxValue]` interval within the `[min, max]` bounds. Dragging a
/// handle moves the nearest bound; the active track segment fills
/// between the two handles.
///
/// Per Epic #1302 원칙 6/7, behaviour fields (`minValue` / `maxValue` /
/// `min` / `max` / `step` / `divisions` / `enabled` / `onChanged`) and
/// composition slots (`leading` / `trailing`) stay flat on the widget.
/// All chrome / dimensional overrides flow through the single
/// [rangeStyle] (a [CoreRangeStyle]). Range has no public variant enum.
///
/// Example:
/// ```dart
/// Range(
///   minValue: 20,
///   maxValue: 80,
///   onChanged: (min, max) => setState(() {
///     _min = min;
///     _max = max;
///   }),
/// )
/// ```
class Range extends StatefulWidget implements CoreRangeContract<Widget> {
  /// Creates a [Range].
  const Range({
    super.key,
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
  final Widget? leading;

  @override
  final Widget? trailing;

  // === Style (chrome / dimensional) ===

  @override
  final CoreRangeStyle? rangeStyle;

  /// Returns a copy of this [Range] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Range copyWith({
    Key? key,
    void Function(double, double)? onChanged,
    double? minValue,
    double? maxValue,
    double? min,
    double? max,
    double? step,
    int? divisions,
    bool? enabled,
    Widget? leading,
    Widget? trailing,
    CoreRangeStyle? rangeStyle,
  }) {
    return Range(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
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

/// Chain sugar for merging a [CoreRangeStyle] patch into
/// [Range.rangeStyle] without hand-reconstructing every field. Mirrors
/// the Web `Range.withStyle` extension so both platforms read
/// identically.
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
  Range withStyle(CoreRangeStyle patch) =>
      copyWith(rangeStyle: (rangeStyle ?? const CoreRangeStyle()).merge(patch));

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
  // Which handle is currently being dragged: 'min', 'max', or null.
  String? _activeHandle;
  bool _minFocused = false;
  bool _maxFocused = false;

  /// Whether the focused thumb was focused by a pointer rather than the
  /// keyboard. Flutter's focus highlight runs in `traditional` mode
  /// whenever the last input was a mouse, so it fires for pointer-
  /// initiated focus too — the Web twin's `focus-visible:` outline does
  /// not. Tracking the origin keeps the outline keyboard-only on both
  /// platforms while a drag still moves focus to the handle it grabbed,
  /// so arrow keys keep adjusting that same handle afterwards.
  bool _pointerFocus = false;

  final _minFocusNode = FocusNode(debugLabel: 'Range.min');
  final _maxFocusNode = FocusNode(debugLabel: 'Range.max');

  /// The thumb focus outlines show only for keyboard-originated focus —
  /// `:focus-visible` parity with the Web twin.
  bool get _showMinFocusOutline => _minFocused && !_pointerFocus;
  bool get _showMaxFocusOutline => _maxFocused && !_pointerFocus;

  /// Moves focus to the thumb a pointer grabbed without revealing its
  /// focus outline. The node still gets focus so the arrow / page / home
  /// / end shortcuts keep operating that same thumb after the drag.
  void _focusFromPointer(FocusNode node) {
    setState(() {
      _pointerFocus = true;
      // A thumb that already held keyboard focus keeps it here, so the
      // highlight callback would not fire — drop the outline directly.
      _minFocused = false;
      _maxFocused = false;
    });
    node.requestFocus();
  }

  /// Promotes pointer-originated focus to keyboard focus once a keyboard
  /// shortcut arrives, which is when the outline becomes meaningful.
  /// Mirrors the browser turning `:focus-visible` on after a key press.
  void _promotePointerFocus() {
    if (!_pointerFocus) return;
    setState(() {
      _pointerFocus = false;
      _minFocused = _minFocusNode.hasFocus;
      _maxFocused = _maxFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  /// Arrow-key step — the caller's `step`, else one `divisions` tick,
  /// else [_kDefaultArrowStepFraction] of the `[min, max]` range.
  double get _arrowStep {
    if (widget.step != null && widget.step! > 0) return widget.step!;
    if (widget.divisions != null && widget.divisions! > 0) {
      return (widget.max - widget.min) / widget.divisions!;
    }
    return (widget.max - widget.min) * _kDefaultArrowStepFraction;
  }

  /// ARIA APG "Slider (Multi-Thumb)" keyboard interaction for one thumb.
  /// [isMin] selects which value this thumb owns and which sibling
  /// value bounds it — mirrors `_handleUpdate`'s mutual clamp.
  void _adjustBy(double delta, {required bool isMin}) {
    final onChanged = widget.onChanged;
    if (!widget.enabled || onChanged == null) return;
    _promotePointerFocus();
    final lowerBound = isMin ? widget.min : widget.minValue;
    final upperBound = isMin ? widget.maxValue : widget.max;
    final current = isMin ? widget.minValue : widget.maxValue;
    final next = (current + delta).clamp(lowerBound, upperBound);
    if (isMin) {
      onChanged(next, widget.maxValue);
    } else {
      onChanged(widget.minValue, next);
    }
  }

  void _jumpTo(_RangeJumpTarget target, {required bool isMin}) {
    final onChanged = widget.onChanged;
    if (!widget.enabled || onChanged == null) return;
    _promotePointerFocus();
    final lowerBound = isMin ? widget.min : widget.minValue;
    final upperBound = isMin ? widget.maxValue : widget.max;
    final next = (target == .min ? lowerBound : upperBound).clamp(
      lowerBound,
      upperBound,
    );
    if (isMin) {
      onChanged(next, widget.maxValue);
    } else {
      onChanged(widget.minValue, next);
    }
  }

  double _ratioOf(double value) {
    final range = widget.max - widget.min;
    if (range <= 0) return 0;
    return ((value - widget.min) / range).clamp(0.0, 1.0);
  }

  double _ratioToValue(double ratio) {
    final range = widget.max - widget.min;
    var r = ratio.clamp(0.0, 1.0);

    final divisions = widget.divisions;
    if (divisions != null && divisions > 0) {
      r = (r * divisions).round() / divisions;
    }

    var newValue = widget.min + r * range;

    final step = widget.step;
    if (step != null && step > 0) {
      newValue = (newValue / step).round() * step;
    }

    return newValue.clamp(widget.min, widget.max);
  }

  /// Maps a pointer x to a value. A thumb travels `trackWidth -
  /// thumbSize` — its edges, not its centre, stop at the track ends — so
  /// the pointer maps over that same span, offset by half a thumb.
  /// Mapping over the full width instead would put the cursor up to
  /// `thumbSize / 2` away from the thumb centre it is dragging, worst at
  /// the ends.
  void _handleUpdate(double localX, double trackWidth, double thumbSize) {
    final onChanged = widget.onChanged;
    if (!widget.enabled || onChanged == null || trackWidth <= 0) return;

    final travel = trackWidth - thumbSize;
    final ratio = travel > 0
        ? ((localX - thumbSize / 2) / travel).clamp(0.0, 1.0)
        : 0.0;
    final value = _ratioToValue(ratio);

    // Decide which handle to move on the first move of a drag — pick the
    // nearer one. Subsequent moves keep the same handle. Shifting
    // keyboard focus to that same handle here means a pointer
    // interaction and a keyboard interaction agree on "which thumb am I
    // moving" — drag it near the max thumb, then keep adjusting it with
    // arrow keys without an extra Tab press.
    var handle = _activeHandle;
    if (handle == null) {
      final minDist = (ratio - _ratioOf(widget.minValue)).abs();
      final maxDist = (ratio - _ratioOf(widget.maxValue)).abs();
      handle = maxDist < minDist ? 'max' : 'min';
      _activeHandle = handle;
      _focusFromPointer(handle == 'min' ? _minFocusNode : _maxFocusNode);
    }

    if (handle == 'min') {
      onChanged(value.clamp(widget.min, widget.maxValue), widget.maxValue);
    } else {
      onChanged(widget.minValue, value.clamp(widget.minValue, widget.max));
    }
  }

  /// Builds one thumb — `Semantics(slider:)` for AT + `FocusableActionDetector`
  /// for hardware-keyboard arrow/page/home/end, wrapping the visual
  /// `_RangeThumb` (which paints its own focus outline when [focused]).
  Widget _buildThumb({
    required bool isMin,
    required bool focused,
    required String label,
    required double value,
    required Color thumbColor,
    required Color thumbBorderColor,
    required ResolvedRange resolved,
    required double thumbS,
  }) {
    final interactive = widget.enabled && widget.onChanged != null;
    return Semantics(
      slider: true,
      label: label,
      value: '$value',
      child: FocusableActionDetector(
        enabled: interactive,
        focusNode: isMin ? _minFocusNode : _maxFocusNode,
        shortcuts: const {
          SingleActivator(.arrowRight): _RangeDeltaIntent(1),
          SingleActivator(.arrowUp): _RangeDeltaIntent(1),
          SingleActivator(.arrowLeft): _RangeDeltaIntent(-1),
          SingleActivator(.arrowDown): _RangeDeltaIntent(-1),
          SingleActivator(.pageUp): _RangeDeltaIntent(_kPageStepMultiplier),
          SingleActivator(.pageDown): _RangeDeltaIntent(
            -_kPageStepMultiplier,
          ),
          SingleActivator(.home): _RangeJumpIntent(.min),
          SingleActivator(.end): _RangeJumpIntent(.max),
        },
        actions: {
          _RangeDeltaIntent: CallbackAction<_RangeDeltaIntent>(
            onInvoke: (intent) {
              _adjustBy(intent.stepMultiplier * _arrowStep, isMin: isMin);
              return null;
            },
          ),
          _RangeJumpIntent: CallbackAction<_RangeJumpIntent>(
            onInvoke: (intent) {
              _jumpTo(intent.target, isMin: isMin);
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() {
          if (isMin) {
            _minFocused = v;
          } else {
            _maxFocused = v;
          }
          // Focus leaving both thumbs ends the pointer-originated
          // episode, so the next Tab in shows the outline again. Checked
          // across both nodes because a drag that hands focus from one
          // thumb to the other fires this with `v == false` for the
          // thumb it left.
          if (!_minFocusNode.hasFocus && !_maxFocusNode.hasFocus) {
            _pointerFocus = false;
          }
        }),
        // The keyboard ring is `FocusOutline`'s job on both platforms —
        // drawing it on the thumb itself would be a second ring
        // implementation whose geometry only matches the Web twin's for
        // as long as someone keeps matching it by hand.
        child: FocusOutline(
          focused: focused,
          shape: .circle,
          focusOutlineStyle: resolved.focusOutlineStyle,
          child: _RangeThumb(
            color: thumbColor,
            borderColor: thumbBorderColor,
            borderWidth: resolved.thumbBorderWidth,
            borderRadius: resolved.borderRadius,
            size: thumbS,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveRange(
      context,
      enabled: widget.enabled && widget.onChanged != null,
      rangeStyle: widget.rangeStyle,
    );

    // Paint-ready chrome — the resolver already ran
    // `scheme.resolve(...).toValue()` (Epic #1603 C7), so the widget
    // reads the resolved `Color`s directly (render-only).
    final activeColor = resolved.activeTrackColor;
    final inactiveColor = resolved.inactiveTrackColor;
    final thumbColor = resolved.thumbColor;
    final thumbBorderColor = resolved.thumbBorderColor;

    final trackH = resolved.trackHeight;
    final thumbS = resolved.thumbSize;

    // Pointer target expansion (WCAG 2.5.8) — mirrors the single-thumb
    // `Slider`'s `TouchTarget` wrap. The track/thumbs draw at
    // `thumbSize` (20px, under the 24px floor); this only widens where a
    // pointer is accepted around them, on the axis that is short. Width
    // is already the full track and does not move.
    final slider = TouchTarget(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final minRatio = _ratioOf(widget.minValue);
          final maxRatio = _ratioOf(widget.maxValue);
          final minOffset = minRatio * (trackWidth - thumbS);
          final maxOffset = maxRatio * (trackWidth - thumbS);

          return GestureDetector(
            onTapDown: widget.enabled
                ? (d) {
                    _activeHandle = null;
                    _handleUpdate(d.localPosition.dx, trackWidth, thumbS);
                  }
                : null,
            onHorizontalDragStart: widget.enabled
                ? (d) {
                    _activeHandle = null;
                    _handleUpdate(d.localPosition.dx, trackWidth, thumbS);
                  }
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (d) => _handleUpdate(d.localPosition.dx, trackWidth, thumbS)
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) => _activeHandle = null
                : null,
            child: MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.grab
                  : SystemMouseCursors.forbidden,
              child: SizedBox(
                height: thumbS,
                child: Stacks(
                  alignment: .centerStart,
                  children: [
                    // Inactive track background.
                    Container(
                      decoration: BoxDecoration(
                        color: inactiveColor,
                        borderRadius: resolved.borderRadius,
                      ),
                      height: trackH,
                    ),
                    // Active (between-handles) track.
                    Position(
                      left: minOffset + thumbS / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: resolved.borderRadius,
                        ),
                        width: (maxOffset - minOffset).clamp(0.0, trackWidth),
                        height: trackH,
                      ),
                    ),
                    // Min thumb — independently focusable `role="slider"`
                    // (see class doc): a combined single tabstop can't
                    // report two independent values (WCAG 4.1.2) or be
                    // operated by arrow keys (there'd be no way to say
                    // "which edge am I moving").
                    Position(
                      left: minOffset,
                      child: _buildThumb(
                        isMin: true,
                        focused: _showMinFocusOutline,
                        label: CoUILocalizations.of(context).rangeMinValueLabel,
                        value: widget.minValue,
                        thumbColor: thumbColor,
                        thumbBorderColor: thumbBorderColor,
                        resolved: resolved,
                        thumbS: thumbS,
                      ),
                    ),
                    // Max thumb — same shape, upper bound.
                    Position(
                      left: maxOffset,
                      child: _buildThumb(
                        isMin: false,
                        focused: _showMaxFocusOutline,
                        label: CoUILocalizations.of(context).rangeMaxValueLabel,
                        value: widget.maxValue,
                        thumbColor: thumbColor,
                        thumbBorderColor: thumbBorderColor,
                        resolved: resolved,
                        thumbS: thumbS,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    final leading = widget.leading;
    final trailing = widget.trailing;
    if (leading == null && trailing == null) {
      return slider;
    }

    return Row(
      children: [
        if (leading != null) ...[
          leading,
          Gap(gapStyle: resolved.minMaxGapStyle),
        ],
        Expanded(child: slider),
        if (trailing != null) ...[
          Gap(gapStyle: resolved.minMaxGapStyle),
          trailing,
        ],
      ],
    );
  }
}

/// A single circular handle of [Range].
class _RangeThumb extends StatelessWidget {
  const _RangeThumb({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.size,
  });

  final Color color;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: borderRadius,
      ),
      width: size,
      height: size,
    );
  }
}

/// Which bound a [_RangeJumpIntent] (Home/End) jumps a thumb to.
enum _RangeJumpTarget { min, max }

/// Arrow/Page key intent for one thumb — `stepMultiplier` is `±1` for a
/// single arrow step or `±_kPageStepMultiplier` for Page Up/Down,
/// multiplied by `_RangeState._arrowStep` in the action.
class _RangeDeltaIntent extends Intent {
  const _RangeDeltaIntent(this.stepMultiplier);
  final double stepMultiplier;
}

/// Home/End intent for one thumb — jumps straight to [target]'s bound.
class _RangeJumpIntent extends Intent {
  const _RangeJumpIntent(this.target);
  final _RangeJumpTarget target;
}
