import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform countdown with token-based rendering.
///
/// Displays a numeric value (clamped to `[min, max]`) with a fade
/// transition animation when the value changes. The parent component
/// is responsible for updating the value over time (e.g. via a Timer).
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [countdownStyle] slot. Behavioural fields
/// (`value`, `min`, `max`) stay flat on the widget.
///
/// ```dart
/// Countdown(value: 42)
/// Countdown(
///   value: 42,
///   countdownStyle: CoreCountdownStyle(fontSize: 32, color: Colors.red),
/// )
/// ```
class Countdown extends StatelessWidget
    implements CoreCountdownContract<Widget> {
  /// Creates a [Countdown].
  const Countdown({
    super.key,
    required this.value,
    this.min = CoreCountdownContract.defaultMinValue,
    this.max = CoreCountdownContract.defaultMaxValue,
    this.countdownStyle,
  });

  @override
  final int value;

  @override
  final int min;

  @override
  final int max;

  @override
  final CoreCountdownStyle? countdownStyle;

  /// Returns a copy of this [Countdown] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Countdown copyWith({
    Key? key,
    int? value,
    int? min,
    int? max,
    CoreCountdownStyle? countdownStyle,
  }) {
    return Countdown(
      key: key ?? this.key,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      countdownStyle: countdownStyle ?? this.countdownStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max);

    final resolved = resolveCountdown(
      context,
      countdownStyle: countdownStyle,
    );

    // `resolved.textStyle` is paint-ready (typography slot materialised,
    // overrides merged, colour resolved). The widget only layers
    // `tabularFigures` on — a Flutter rendering detail with no
    // `CoreTextStyle` equivalent (Epic #1603 C11 — render-only).
    final effectiveStyle = resolved.textStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      liveRegion: true,
      label: clampedValue.toString(),
      child: AnimatedSwitcher(
        duration: resolved.animationDuration,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          clampedValue.toString(),
          key: ValueKey(clampedValue),
          style: effectiveStyle,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreCountdownStyle] patch into
/// [Countdown.countdownStyle] without hand-reconstructing every field.
/// Mirrors the Web `Countdown.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCountdownStyle.merge` right-side-wins semantics).
extension CountdownStyleChain on Countdown {
  /// Returns a copy of this [Countdown] with [patch] merged into
  /// [countdownStyle] (patch fields win on conflict).
  Countdown withStyle(CoreCountdownStyle patch) => copyWith(
    countdownStyle: (countdownStyle ?? const CoreCountdownStyle()).merge(patch),
  );
}
