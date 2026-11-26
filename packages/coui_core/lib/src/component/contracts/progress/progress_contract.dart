/// Platform-independent contract for unified progress components.
///
/// Defines the interface that all Progress implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/progress/progress_size.dart';
import 'package:coui_core/src/component/contracts/progress/progress_style.dart';
import 'package:coui_core/src/component/contracts/progress/progress_tone.dart';

/// How close `(value − min) / (max − min) × segments` has to be to a whole
/// step to count as that step — absorbs the floating-point error of the
/// product (`0.29 × 100` is `28.999…`).
const double _kSegmentEpsilon = 1e-9;

/// Contract for a unified linear progress component.
///
/// Displays a horizontal bar indicating task completion.
/// When [value] is null, an indeterminate animation is shown.
///
/// Three optional cells can sit around the bar: [label] above it on the
/// left, [valueLabel] above it on the right, [caption] below it. With none
/// of them the component is the bar alone.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [progressStyle] field — see [CoreProgressStyle] for
/// the merge chain. Behaviour defaults (range bounds) live as
/// `static const` here so Flutter and Web widgets share a single
/// source ([defaultMin] / [defaultMax]). [size] and [tone] are semantic
/// identifiers — their widget defaults live on each platform's `Progress`
/// constructor (`= CoreProgressSize.defaultSize` /
/// `= CoreProgressTone.defaultTone`), mirroring `CoreFabContract.size`.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreProgressContract<W> {
  /// Default lower bound of [value] when omitted. Shared by Flutter
  /// and Web widgets to avoid silent divergence.
  static const double defaultMin = 0;

  /// Default upper bound of [value] when omitted. Shared by Flutter
  /// and Web widgets to avoid silent divergence.
  static const double defaultMax = 1;

  /// The widest text a value label can show — the cell is sized to it, so a
  /// value that grows from `9%` to `10%` to `100%` does not change the bar's
  /// length. The label is drawn right-aligned in the reserved width.
  static const String defaultValueLabelReserve = '100%';

  /// How many of [segments] cells a determinate bar fills — the steps
  /// passed: `⌊(value − min) / (max − min) × segments⌋`, clamped to
  /// `0 … segments`.
  ///
  /// A step counts once it is reached, so `value: 1, max: 3, segments: 3`
  /// fills one cell even though `1 / 3 × 3` lands a hair under 1 in floating
  /// point — the product is taken to the nearest whole step when it is
  /// within a hair (1e-9) of one. Both widgets call this, so the two cannot
  /// fill a different number of cells for the same value.
  static int filledSegmentsOf({
    required double value,
    required double min,
    required double max,
    required int segments,
  }) {
    final range = max - min;
    if (segments <= 0 || !range.isFinite || range <= 0) return 0;
    final steps = (value - min) / range * segments;
    if (!steps.isFinite) return 0;
    final nearest = steps.roundToDouble();
    final whole = (steps - nearest).abs() <= _kSegmentEpsilon
        ? nearest
        : steps.floorToDouble();
    return whole.clamp(0, segments.toDouble()).toInt();
  }

  /// Progress value from 0.0 to 1.0. Null for indeterminate.
  double? get value;

  /// Minimum progress value.
  double get min;

  /// Maximum progress value.
  double get max;

  /// Whether to disable smooth animation.
  bool get disableAnimation;

  /// Splits the bar into this many cells — a stepped bar for onboarding and
  /// sign-up flows ("STEP 1 / 2"). The cells for the steps passed
  /// ([filledSegmentsOf]) take the fill colour, the rest the track colour,
  /// and [CoreProgressStyle.segmentSpacing] sits between them.
  ///
  /// `null` (default) is the continuous bar. An indeterminate bar ([value]
  /// `null`) has no step to show and stays continuous. Must be at least 1.
  int? get segments;

  /// Size of the track / indicator (Epic K axis 8-1).
  CoreProgressSize get size;

  /// What the fill colour means — selects the fill from
  /// [CoreProgressStyle.defaultsByTone]. The track does not follow it.
  CoreProgressTone get tone;

  /// What is being measured, above the bar on the left. Drawn in
  /// [CoreProgressStyle.defaultLabelStyle]; it also names the bar for
  /// assistive technology. `null` → no label.
  W? get label;

  /// The amount, above the bar on the right. Drawn in
  /// [CoreProgressStyle.defaultValueLabelStyle]. It repeats what the bar
  /// already reports as its value, so assistive technology does not read
  /// it a second time. `null` → no value label.
  W? get valueLabel;

  /// A note below the bar. Drawn in
  /// [CoreProgressStyle.defaultCaptionStyle]; it also describes the bar
  /// for assistive technology. `null` → no caption.
  W? get caption;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreProgressStyle.defaultX / defaultsBySize /
  /// defaultsByTone)
  ///   → CoreProgressTheme.style
  ///   → CoreProgressTheme.toneStyles[tone]
  ///   → parent component slot override
  ///   → widget.progressStyle
  /// ```
  CoreProgressStyle? get progressStyle;
}

/// Contract for a unified radial progress component.
///
/// Displays a circular ring indicating task completion.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [radialProgressStyle] field — see
/// [CoreRadialProgressStyle] for the merge chain. Behaviour
/// constants ([defaultMaxValue]) live here so Flutter and Web share
/// a single source.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget?`, Web `Component?`).
abstract interface class CoreRadialProgressContract<W> {
  /// Maximum percentage represented by [value]. Clamps the input range
  /// to `0..defaultMaxValue` before geometry calculations. Shared by
  /// Flutter and Web widgets.
  static const double defaultMaxValue = 100;

  /// Default ring size — `lg`, the single 80 px ring this component drew
  /// before it had sizes.
  static const CoreProgressSize defaultSize = CoreProgressSize.lg;

  /// Default arc tone.
  static const CoreProgressTone defaultTone = CoreProgressTone.primary;

  /// Progress value from 0 to [defaultMaxValue].
  double get value;

  /// Whether to show percentage text in center.
  bool get showValueText;

  /// Ring size — `sm`, `md`, `lg` or `xl` (the bar's `xs2` and `xs` are
  /// drawn as `sm`). Defaults to [defaultSize].
  CoreProgressSize get size;

  /// Arc tone — the same tones as the bar. Defaults to [defaultTone].
  CoreProgressTone get tone;

  /// Custom content to display in center.
  W get child;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreRadialProgressTheme.style
  ///   → parent component slot override
  ///   → widget.radialProgressStyle
  /// ```
  CoreRadialProgressStyle? get radialProgressStyle;
}
