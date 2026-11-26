import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/display/loading_region/loading_region.dart';

/// Unified cross-platform skeleton with token-based rendering.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [skeletonStyle] slot. Sizing fields
/// (`width` / `height`) plus semantic `variant` stay flat on the widget.
///
/// Uses [CoreSkeletonVariantStyle] from `coui_core` for consistent
/// cross-platform styling.
///
/// Animates a pulse effect by oscillating the fill's alpha between its
/// own alpha times [CoreSkeletonStyle.fromOpacity] and times
/// [CoreSkeletonStyle.toOpacity] — a transparent fill stays transparent.
/// Under reduced motion the pulse stops and the fill rests at the
/// [CoreSkeletonStyle.fromOpacity] end
/// (`CoreReducedMotion.runsPlaceholderPulse`).
///
/// Whether a skeleton is drawn is the caller's condition — render it
/// conditionally at the call site (`if (loading) Skeleton(...)`).
///
/// Example:
/// ```dart
/// Skeleton(width: 200, height: 20)
/// Skeleton(
///   width: 200,
///   height: 20,
///   skeletonStyle: CoreSkeletonStyle(backgroundColor: Colors.grey),
/// )
/// ```
class Skeleton extends StatefulWidget implements CoreSkeletonContract {
  /// Creates a [Skeleton].
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.variant = CoreSkeletonVariant.defaultVariant,
    this.skeletonStyle,
  });

  /// Creates a circular skeleton (for avatars, icons).
  const Skeleton.circle({required double size, super.key, this.skeletonStyle})
    : width = size,
      height = size,
      variant = CoreSkeletonVariant.circular;

  /// Creates a multi-line text skeleton.
  const Skeleton.text({super.key, this.skeletonStyle})
    : width = null,
      height = null,
      variant = CoreSkeletonVariant.text;

  /// Width of the skeleton placeholder in logical pixels. Flat,
  /// platform-typed sizing knob — not a contract member.
  final double? width;

  /// Height of the skeleton placeholder in logical pixels. Flat,
  /// platform-typed sizing knob — not a contract member.
  final double? height;

  @override
  final CoreSkeletonVariant variant;

  @override
  final CoreSkeletonStyle? skeletonStyle;

  /// Returns a copy of this [Skeleton] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Skeleton copyWith({
    Key? key,
    double? width,
    double? height,
    CoreSkeletonVariant? variant,
    CoreSkeletonStyle? skeletonStyle,
  }) {
    return Skeleton(
      key: key ?? this.key,
      width: width ?? this.width,
      height: height ?? this.height,
      variant: variant ?? this.variant,
      skeletonStyle: skeletonStyle ?? this.skeletonStyle,
    );
  }

  @override
  State<Skeleton> createState() => _SkeletonState();
}

/// Whether two resolved curves are the same cubic.
///
/// `Curve` has no value equality — every resolve builds a fresh `Cubic` —
/// so comparing the objects says "changed" on every rebuild and the guard
/// that skips re-tuning the controller could never fire.
bool _sameCurve(Curve a, Curve b) {
  if (a is Cubic && b is Cubic) {
    return a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d;
  }

  return a == b;
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _alphaAnimation;
  ResolvedSkeleton? _resolved;

  void _applyResolved(ResolvedSkeleton resolved) {
    final previous = _resolved;
    final needsRebuild =
        previous == null ||
        previous.duration != resolved.duration ||
        !_sameCurve(previous.curve, resolved.curve) ||
        previous.pulses != resolved.pulses ||
        previous.pulseFromColor != resolved.pulseFromColor ||
        previous.pulseToColor != resolved.pulseToColor;
    _resolved = resolved;
    if (!needsRebuild) return;

    // One controller for the life of the state: re-resolving (a theme or
    // style change) only retunes it. Replacing it would ask the
    // single-ticker vsync for a second ticker, which asserts.
    final existing = _controller;
    final controller =
        existing ??
        AnimationController(duration: resolved.duration, vsync: this);
    _controller = controller;
    final periodMoved = controller.duration != resolved.duration;
    controller.duration = resolved.duration;
    // One period is one full pulse, in two halves that each ease FORWARD —
    // rest → peak, then peak → rest — which is what Web's keyframes do
    // (`0%,100%` → `50%`, the timing function applied per interval).
    // `repeat(reverse: true)` would play the second half as the first one
    // backwards: the same only while the curve happens to be symmetric, and
    // a period of half the duration besides.
    //
    // An `Animatable` chain: nothing to dispose, so rebuilding it on a
    // re-resolve strands no listener on the controller.
    final from = resolved.pulseFromColor.a;
    final to = resolved.pulseToColor.a;
    final ease = CurveTween(curve: resolved.curve);
    _alphaAnimation = controller.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: from, end: to).chain(ease),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: to, end: from).chain(ease),
          weight: 1,
        ),
      ]),
    );
    if (!resolved.pulses) {
      // Reduced motion: hold the resting end. Value 0 is `from` in the
      // sequence above; the period is left alone rather than collapsed to
      // zero, which `repeat` asserts against.
      controller
        ..stop()
        ..value = 0;
      return;
    }
    // `repeat` captures the period when it starts, so a new duration only
    // lands once the pulse is restarted — and a pulse held under reduced
    // motion restarts when the setting is turned off.
    if (existing == null || periodMoved || !controller.isAnimating) {
      controller.repeat();
    }
  }

  Widget _buildTextSkeleton(
    BuildContext context, {
    required ResolvedSkeleton resolved,
    required Color bgColor,
  }) {
    final lines = resolved.lines;
    final lastLine = resolved.lastLineWidth;

    final children = <Widget>[
      for (var i = 0; i < lines; i++)
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: i == lines - 1 ? lastLine : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: resolved.borderRadius,
              border: resolved.border,
            ),
            height: resolved.lineHeight,
          ),
        ),
    ];

    // Native `Column.spacing` paint-API consumes the pre-scaled
    // `lineSpacing` directly — no `Gap` interleave (Epic #1659
    // D-cat — N-sibling uniform distribution pattern).
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: resolved.lineSpacing,
      children: children,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolved = resolveSkeleton(
      context,
      variant: widget.variant,
      skeletonStyle: widget.skeletonStyle,
      width: widget.width,
      height: widget.height,
    );
    _applyResolved(resolved);
  }

  @override
  void didUpdateWidget(covariant Skeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final resolved = resolveSkeleton(
      context,
      variant: widget.variant,
      skeletonStyle: widget.skeletonStyle,
      width: widget.width,
      height: widget.height,
    );
    _applyResolved(resolved);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolved!;
    final alphaAnim = _alphaAnimation;

    final pulse = AnimatedBuilder(
      animation: alphaAnim,
      builder: (context, child) {
        // Both pulse ends carry the fill's rgb — `scaleAlpha` moves alpha
        // only — so a frame is that colour at the tweened alpha: the same
        // straight alpha interpolation CSS keyframes run between Web's
        // `--pulse-from` and `--pulse-to`.
        final pulsedColor = resolved.pulseFromColor.withValues(
          alpha: alphaAnim.value,
        );

        if (widget.variant == .text) {
          return _buildTextSkeleton(
            context,
            resolved: resolved,
            bgColor: pulsedColor,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: pulsedColor,
            borderRadius: resolved.borderRadius,
            border: resolved.border,
          ),
          width: resolved.scaledWidth,
          height: resolved.scaledHeight,
        );
      },
    );

    // Inside a `LoadingRegion` the region announces once for the whole
    // area; a skeleton announcing too would make ten placeholders ten
    // announcements.
    if (LoadingRegionScope.existsAbove(context)) return pulse;

    // Web twin: role="status" + aria-label + text — a skeleton is a "still
    // loading" message, and silence reads as a finished but empty screen.
    return Semantics(
      liveRegion: true,
      label: CoUILocalizations.of(context).loadingLabel,
      child: pulse,
    );
  }
}

/// Chain sugar for merging a [CoreSkeletonStyle] patch into
/// [Skeleton.skeletonStyle] without hand-reconstructing every field.
/// Mirrors the Web `Skeleton.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSkeletonStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Skeleton(width: 200, height: 20).withStyle(
///   CoreSkeletonStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// )
/// ```
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreSkeletonStyle.borderRadius] and `.primary` sets
/// [CoreSkeletonStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Skeleton(width: 200, height: 20).radius4.primary
/// ```
extension SkeletonStyleChain on Skeleton {
  /// Returns a copy of this [Skeleton] with [patch] merged into
  /// [skeletonStyle] (patch fields win on conflict).
  Skeleton withStyle(CoreSkeletonStyle patch) => copyWith(
    skeletonStyle: (skeletonStyle ?? const CoreSkeletonStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Skeleton get radius0 =>
      withStyle(const CoreSkeletonStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Skeleton get radius2 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Skeleton get radius4 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Skeleton get radius6 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Skeleton get radius8 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Skeleton get radius10 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Skeleton get radius12 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Skeleton get radius14 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Skeleton get radius16 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Skeleton get radius20 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Skeleton get radius24 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Skeleton get radius28 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Skeleton get radius32 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Skeleton get radius36 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Skeleton get radius40 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Skeleton get radius48 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Skeleton get radius56 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Skeleton get radius64 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Skeleton get radius9999 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Skeleton get primary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Skeleton get secondary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Skeleton get tertiary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Skeleton get surface => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Skeleton get surfaceContainer => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Skeleton get error => withStyle(
    const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Skeleton get success => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Skeleton get warning => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Skeleton get info => withStyle(
    const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Skeleton get outline => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Skeleton get transparent =>
      withStyle(const CoreSkeletonStyle(backgroundColor: .transparent));
}
