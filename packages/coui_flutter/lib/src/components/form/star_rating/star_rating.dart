import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// ─── Behaviour / star-geometry defaults ───────────────────────────────
// Widget-flat behaviour defaults (verify.md rule (u-2): behaviour 값은
// Style 슬롯이 아니라 widget 평면). 같은 값을 Web 측 `co_star_rating.dart`
// 도 file-local 로 들고 있어 silent divergence 위험은 없음 — Flutter / Web
// 양쪽 모두 `StarRating` widget API 의 default 자리.

const double _kDefaultMax = 5;
const double _kDefaultStep = 0.5;
const double _kDefaultStarPoints = 5;
const double _kDefaultStarPointRounding = 0.15;
const double _kDefaultStarValleyRounding = 0;
const double _kDefaultStarSquash = 0;
const double _kDefaultStarInnerRadiusRatio = 0.4;
const double _kDefaultStarRotation = 0;

/// Unified cross-platform star rating — direct rendering.
///
/// Displays interactive star-based rating with fractional support.
/// No legacy [StarRating] delegation.
///
/// Example:
/// ```dart
/// StarRating(
///   value: 3.5,
///   onChanged: (v) => print(v),
/// )
/// ```
class StarRating extends StatefulWidget implements CoreStarRatingContract {
  /// Creates a [StarRating].
  const StarRating({
    super.key,
    required this.value,
    this.max = _kDefaultMax,
    this.step = _kDefaultStep,
    this.enabled = true,
    this.onChanged,
    this.direction = CoreAxis.horizontal,
    this.size = CoreStarRatingStyle.defaultSize,
    this.showValue = CoreStarRatingContract.defaultShowValue,
    this.showCount = CoreStarRatingContract.defaultShowCount,
    this.count,
    this.starPoints,
    this.starPointRounding,
    this.starValleyRounding,
    this.starSquash,
    this.starInnerRadiusRatio,
    this.starRotation,
    this.starRatingStyle,
  });

  @override
  final double value;

  @override
  final double max;

  @override
  final double step;

  @override
  final bool enabled;

  /// Rating change callback.
  final ValueChanged<double>? onChanged;

  /// Axis the stars are laid out along. Also decides which way an
  /// individual star fills — along the axis when horizontal, bottom-up
  /// when vertical. The Web twin reads the same parameter.
  @override
  final CoreAxis direction;

  @override
  final CoreComponentSize size;

  @override
  final bool showValue;

  @override
  final bool showCount;

  @override
  final int? count;

  /// Number of points per star.
  final double? starPoints;

  @override
  final CoreStarRatingStyle? starRatingStyle;

  /// Rounding radius for star points.
  final double? starPointRounding;

  /// Rounding radius for star valleys.
  final double? starValleyRounding;

  /// Vertical compression factor.
  final double? starSquash;

  /// Inner to outer radius ratio.
  final double? starInnerRadiusRatio;

  /// Rotation angle in radians.
  final double? starRotation;

  /// Returns a copy of this [StarRating] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  StarRating copyWith({
    Key? key,
    ValueChanged<double>? onChanged,
    double? value,
    double? max,
    double? step,
    bool? enabled,
    CoreAxis? direction,
    CoreComponentSize? size,
    bool? showValue,
    bool? showCount,
    int? count,
    double? starPoints,
    double? starPointRounding,
    double? starValleyRounding,
    double? starSquash,
    double? starInnerRadiusRatio,
    double? starRotation,
    CoreStarRatingStyle? starRatingStyle,
  }) {
    return StarRating(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      max: max ?? this.max,
      step: step ?? this.step,
      enabled: enabled ?? this.enabled,
      direction: direction ?? this.direction,
      size: size ?? this.size,
      showValue: showValue ?? this.showValue,
      showCount: showCount ?? this.showCount,
      count: count ?? this.count,
      starPoints: starPoints ?? this.starPoints,
      starPointRounding: starPointRounding ?? this.starPointRounding,
      starValleyRounding: starValleyRounding ?? this.starValleyRounding,
      starSquash: starSquash ?? this.starSquash,
      starInnerRadiusRatio: starInnerRadiusRatio ?? this.starInnerRadiusRatio,
      starRotation: starRotation ?? this.starRotation,
      starRatingStyle: starRatingStyle ?? this.starRatingStyle,
    );
  }

  @override
  State<StarRating> createState() => _StarRatingState();
}

/// Chain sugar for merging a [CoreStarRatingStyle] patch into
/// [StarRating.starRatingStyle] without hand-reconstructing every field.
/// Mirrors the Web `StarRating.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStarRatingStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreStarRatingStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// StarRating(value: 3).primary
/// ```
extension StarRatingStyleChain on StarRating {
  /// Returns a copy of this [StarRating] with [patch] merged into
  /// [starRatingStyle] (patch fields win on conflict).
  StarRating withStyle(CoreStarRatingStyle patch) => copyWith(
    starRatingStyle: (starRatingStyle ?? const CoreStarRatingStyle()).merge(
      patch,
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  StarRating get primary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  StarRating get secondary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  StarRating get tertiary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  StarRating get surface => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  StarRating get surfaceContainer => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  StarRating get error => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  StarRating get success => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  StarRating get warning => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  StarRating get info => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  StarRating get outline => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  StarRating get transparent => withStyle(
    const CoreStarRatingStyle(backgroundColor: .transparent),
  );
}

class _StarRatingState extends State<StarRating> {
  double? _changingValue;
  bool _focused = false;

  bool get _enabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    final roundedValue =
        ((_changingValue ?? widget.value) / widget.step).round() * widget.step;

    final resolved = resolveStarRating(
      context,
      starRatingStyle: widget.starRatingStyle,
      size: widget.size,
      enabled: _enabled,
    );
    final localizations = CoUILocalizations.of(context);

    // Web twin: role="slider" + aria-label + aria-valuenow.
    return Semantics(
      slider: true,
      label: localizations.ratingLabel,
      value: '${widget.value} / ${widget.max}',
      child: AnimatedValueBuilder(
        value: roundedValue,
        duration: resolved.animationDuration,
        builder: (context, animValue, child) {
          final effectiveStarSize = resolved.starSize;
          final effectiveStarSpacing = resolved.starSpacing;

          // Pointer → value along the *main axis*, one definition for every
          // gesture path.
          //
          // The three paths used to compute this separately and disagreed: tap
          // divided by `starSize + spacing * (n - 1)` (missing the `* n`), drag
          // divided by the full run, and hover by the rendered width — and all
          // three read `dx`, so a vertical rating could not be dragged past a
          // fraction of its range while its own tap path saturated early.
          double progressAt(Offset local) {
            final stars = widget.max.ceil();
            final extent =
                effectiveStarSize * stars + effectiveStarSpacing * (stars - 1);
            if (extent <= 0) return 0;
            final along = widget.direction == CoreAxis.horizontal
                ? local.dx
                : local.dy;
            return (along / extent).clamp(0.0, 1.0);
          }

          final stars = FocusableActionDetector(
            enabled: _enabled,
            shortcuts: {
              LogicalKeySet(.arrowRight): _IncreaseIntent(widget.step),
              LogicalKeySet(.arrowLeft): _DecreaseIntent(widget.step),
            },
            actions: {
              _IncreaseIntent: CallbackAction<_IncreaseIntent>(
                onInvoke: (intent) {
                  widget.onChanged?.call(
                    (animValue + intent.step).clamp(0.0, widget.max),
                  );
                  return null;
                },
              ),
              _DecreaseIntent: CallbackAction<_DecreaseIntent>(
                onInvoke: (intent) {
                  widget.onChanged?.call(
                    (animValue - intent.step).clamp(0.0, widget.max),
                  );
                  return null;
                },
              ),
            },
            onShowFocusHighlight: (v) => setState(() => _focused = v),
            onShowHoverHighlight: (v) {
              if (!v) setState(() => _changingValue = null);
            },
            mouseCursor: _enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: MouseRegion(
              onHover: (event) {
                if (!_enabled || widget.onChanged == null) return;
                final progress = progressAt(event.localPosition);
                setState(() {
                  _changingValue = (progress * widget.max).clamp(
                    0.0,
                    widget.max,
                  );
                });
              },
              child: GestureDetector(
                onTap: () {
                  if (widget.onChanged != null && animValue != widget.value) {
                    widget.onChanged!(animValue);
                  }
                },
                onTapDown: (details) {
                  if (!_enabled || widget.onChanged == null) return;
                  final progress = progressAt(details.localPosition);
                  widget.onChanged!(
                    (progress * widget.max).clamp(0.0, widget.max),
                  );
                },
                onPanUpdate: (details) {
                  if (!_enabled || widget.onChanged == null) return;
                  final progress = progressAt(details.localPosition);
                  setState(() {
                    _changingValue = (progress * widget.max).clamp(
                      0.0,
                      widget.max,
                    );
                  });
                },
                onPanEnd: (_) {
                  if (!_enabled || widget.onChanged == null) return;
                  widget.onChanged!(_changingValue ?? animValue);
                  setState(() => _changingValue = null);
                },
                onPanCancel: () {
                  if (!_enabled || widget.onChanged == null) return;
                  widget.onChanged!(_changingValue ?? animValue);
                  setState(() => _changingValue = null);
                },
                behavior: .translucent,
                child: Flex(
                  direction: widget.direction.toValue(),
                  mainAxisSize: .min,
                  children: [
                    for (int i = 0; i < widget.max.ceil(); i++)
                      Star(
                        state: CoreStarState.forIndex(animValue, i),
                        size: widget.size,
                        enabled: _enabled,
                        direction: widget.direction,
                        starPoints: widget.starPoints,
                        starPointRounding: widget.starPointRounding,
                        starValleyRounding: widget.starValleyRounding,
                        starSquash: widget.starSquash,
                        starInnerRadiusRatio: widget.starInnerRadiusRatio,
                        starRotation: widget.starRotation,
                        starRatingStyle: widget.starRatingStyle,
                      ),
                  ],
                ).gap(effectiveStarSpacing),
              ),
            ),
          );

          final count = widget.count;
          final showCount = widget.showCount && count != null;
          // One ring around the whole group — stars and the text beside
          // them — not one per star.
          return FocusOutline(
            focused: _focused,
            focusOutlineStyle: resolved.focusOutlineStyle,
            child: widget.showValue || showCount
                ? Row(
                    mainAxisSize: .min,
                    children: [
                      stars,
                      if (widget.showValue) ...[
                        Gap(gapStyle: resolved.valueGapStyle),
                        Text(
                          widget.value.toStringAsFixed(1),
                          style: resolved.valueTextStyle,
                        ),
                      ],
                      if (showCount) ...[
                        Gap(gapStyle: resolved.valueGapStyle),
                        Text('($count)', style: resolved.countTextStyle),
                      ],
                    ],
                  )
                : stars,
          );
        },
      ),
    );
  }
}

/// One star, drawn in one of three fills: [CoreStarState.filled],
/// [CoreStarState.half] or [CoreStarState.empty].
///
/// `StarRating` draws one per index; it is also usable on its own (a
/// read-only badge, a legend). The size, colours and enabled look come
/// from the same `resolveStarRating` the rating uses, so a lone `Star`
/// and the stars inside a `StarRating` cannot drift apart.
class Star extends StatelessWidget {
  /// Creates a [Star].
  const Star({
    super.key,
    this.state = CoreStarState.defaultState,
    this.size = CoreStarRatingStyle.defaultSize,
    this.enabled = true,
    this.direction = CoreAxis.horizontal,
    this.starPoints,
    this.starPointRounding,
    this.starValleyRounding,
    this.starSquash,
    this.starInnerRadiusRatio,
    this.starRotation,
    this.starRatingStyle,
  });

  /// How much of the star is filled.
  final CoreStarState state;

  /// Size step — `sm` 16 · `md` 20 · `lg` 24 · `xl` 32.
  final CoreComponentSize size;

  /// Whether the disabled colours are used when `false`.
  final bool enabled;

  /// Axis the half fill runs along — left half when horizontal, lower
  /// half when vertical.
  final CoreAxis direction;

  /// Number of points per star.
  final double? starPoints;

  /// Rounding radius for star points.
  final double? starPointRounding;

  /// Rounding radius for star valleys.
  final double? starValleyRounding;

  /// Vertical compression factor.
  final double? starSquash;

  /// Inner to outer radius ratio.
  final double? starInnerRadiusRatio;

  /// Rotation angle in radians.
  final double? starRotation;

  /// Per-instance chrome / dimensional style.
  final CoreStarRatingStyle? starRatingStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStarRating(
      context,
      starRatingStyle: starRatingStyle,
      size: size,
      enabled: enabled,
    );
    final shape = StarBorder(
      points: starPoints ?? _kDefaultStarPoints,
      innerRadiusRatio: starInnerRadiusRatio ?? _kDefaultStarInnerRadiusRatio,
      pointRounding: starPointRounding ?? _kDefaultStarPointRounding,
      valleyRounding: starValleyRounding ?? _kDefaultStarValleyRounding,
      // The public Star API uses radians; Flutter's shape uses degrees.
      rotation: (starRotation ?? _kDefaultStarRotation) * 180 / math.pi,
      squash: starSquash ?? _kDefaultStarSquash,
    );

    Widget painted(Color color) => Container(
      decoration: ShapeDecoration(color: color, shape: shape),
      width: resolved.starSize,
      height: resolved.starSize,
    );

    return switch (state) {
      CoreStarState.filled => painted(resolved.activeColor),
      CoreStarState.empty => painted(resolved.backgroundColor),
      CoreStarState.half => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: direction == CoreAxis.horizontal
              ? Alignment.centerLeft
              : Alignment.bottomCenter,
          end: direction == CoreAxis.horizontal
              ? Alignment.centerRight
              : Alignment.topCenter,
          colors: [resolved.activeColor, resolved.backgroundColor],
          stops: const [0.5, 0.5],
        ).createShader(bounds),
        blendMode: .srcIn,
        child: painted(const Color(0xFFFFFFFF)),
      ),
    };
  }
}

class _IncreaseIntent extends Intent {
  const _IncreaseIntent(this.step);
  final double step;
}

class _DecreaseIntent extends Intent {
  const _DecreaseIntent(this.step);
  final double step;
}

/// Unified controlled star rating with automatic state management.
///
/// Example:
/// ```dart
/// ControlledStarRating(
///   initialValue: 3.0,
///   onChanged: (v) => print(v),
/// )
/// ```
class ControlledStarRating extends StatelessWidget
    with ControlledComponent<double> {
  /// Creates a [ControlledStarRating].
  const ControlledStarRating({
    super.key,
    this.controller,
    this.initialValue = 0.0,
    this.onChanged,
    this.enabled = true,
    this.max = _kDefaultMax,
    this.step = _kDefaultStep,
    this.direction = CoreAxis.horizontal,
    this.size = CoreStarRatingStyle.defaultSize,
    this.showValue = CoreStarRatingContract.defaultShowValue,
    this.showCount = CoreStarRatingContract.defaultShowCount,
    this.count,
    this.starPoints,
    this.starPointRounding,
    this.starValleyRounding,
    this.starSquash,
    this.starInnerRadiusRatio,
    this.starRotation,
    this.starRatingStyle,
  });

  @override
  final double initialValue;
  @override
  final ValueChanged<double>? onChanged;
  @override
  final bool enabled;
  @override
  final StarRatingController? controller;

  final double max;
  final double step;
  final CoreAxis direction;
  final CoreComponentSize size;
  final bool showValue;
  final bool showCount;
  final int? count;
  final double? starPoints;
  final double? starPointRounding;
  final double? starValleyRounding;
  final double? starSquash;
  final double? starInnerRadiusRatio;
  final double? starRotation;

  /// Per-instance chrome / dimensional style.
  final CoreStarRatingStyle? starRatingStyle;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      onChanged: onChanged,
      initialValue: initialValue,
      controller: controller,
      enabled: enabled,
      builder: (context, data) {
        return StarRating(
          onChanged: data.onChanged,
          value: data.value,
          max: max,
          step: step,
          enabled: data.enabled,
          direction: direction,
          size: size,
          showValue: showValue,
          showCount: showCount,
          count: count,
          starPoints: starPoints,
          starPointRounding: starPointRounding,
          starValleyRounding: starValleyRounding,
          starSquash: starSquash,
          starInnerRadiusRatio: starInnerRadiusRatio,
          starRotation: starRotation,
          starRatingStyle: starRatingStyle,
        );
      },
    );
  }
}

/// A controller for managing [StarRating] widget values programmatically.
///
/// This controller extends [ValueNotifier] and implements [ComponentController]
/// to provide a standardized way to control star rating values externally.
/// It allows programmatic manipulation of the rating value and provides.
/// Change notification capabilities.
///
/// The controller maintains a double value representing the current rating,.
/// Which is typically in the range of 0.0 to the maximum rating value.
///
/// Example:
/// ```dart
/// final controller = StarRatingController(3.5);
///
/// // Listen to changes.
/// Controller.addListener(() {
///   print('Rating changed to: ${controller.value}');
/// });
///
/// // Update the rating.
/// Controller.value = 4.0;
/// ```
class StarRatingController extends ValueNotifier<double>
    with ComponentController<double> {
  /// Creates a [StarRatingController] with the given initial [value].
  ///
  /// The [value] parameter sets the initial rating value. Defaults to 0.0.
  /// If not specified. The value should typically be within the range.
  /// Supported by the star rating widget (0.0 to max value).
  ///
  /// Parameters:
  /// - [value] (double, default: 0.0): Initial rating value.
  StarRatingController([super.value = 0.0]);
}

/// Chain sugar for merging a [CoreStarRatingStyle] patch into
/// [ControlledStarRating.starRatingStyle] without hand-reconstructing
/// every field. Mirrors the [StarRatingStyleChain] extension so both
/// the plain and controlled widgets read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStarRatingStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreStarRatingStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// ControlledStarRating(initialValue: 3).primary
/// ```
extension ControlledStarRatingStyleChain on ControlledStarRating {
  /// Returns a copy of this [ControlledStarRating] with [patch] merged
  /// into [starRatingStyle] (patch fields win on conflict).
  ControlledStarRating withStyle(CoreStarRatingStyle patch) => .new(
    key: key,
    onChanged: onChanged,
    initialValue: initialValue,
    controller: controller,
    enabled: enabled,
    max: max,
    step: step,
    direction: direction,
    size: size,
    showValue: showValue,
    showCount: showCount,
    count: count,
    starPoints: starPoints,
    starPointRounding: starPointRounding,
    starValleyRounding: starValleyRounding,
    starSquash: starSquash,
    starInnerRadiusRatio: starInnerRadiusRatio,
    starRotation: starRotation,
    starRatingStyle: (starRatingStyle ?? const CoreStarRatingStyle()).merge(
      patch,
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ControlledStarRating get primary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ControlledStarRating get secondary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ControlledStarRating get tertiary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ControlledStarRating get surface => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ControlledStarRating get surfaceContainer => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ControlledStarRating get error => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ControlledStarRating get success => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ControlledStarRating get warning => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ControlledStarRating get info => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ControlledStarRating get outline => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ControlledStarRating get transparent => withStyle(
    const CoreStarRatingStyle(backgroundColor: .transparent),
  );
}
