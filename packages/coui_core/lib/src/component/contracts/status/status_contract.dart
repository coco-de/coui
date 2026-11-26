/// Platform-independent contract for unified status components.
///
/// Defines the interface that all Status implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/status/status_style.dart';

/// Color variant for status dot indicators.
enum CoreStatusColor {
  /// Neutral color.
  neutral,

  /// Primary color.
  primary,

  /// Secondary color.
  secondary,

  /// Tertiary color.
  tertiary,

  /// Info color.
  info,

  /// Success color.
  success,

  /// Warning color.
  warning,

  /// Error color.
  error,
}

/// Presence variant a `Status` reports.
///
/// The variant picks both the colour and the shape of the dot, so a reader who
/// cannot tell colours apart still reads the four apart: `online` is a filled
/// dot, `busy` a filled dot with a bar across it, `away` and `offline` a ring
/// (told apart by colour, as the label beside them says).
enum CoreStatusVariant {
  /// Reachable — a filled dot in the success colour.
  online,

  /// Reachable but not to be disturbed — a filled dot in the destructive
  /// colour with a bar across it.
  busy,

  /// Stepped away — a ring in the warning colour.
  away,

  /// Not reachable — a ring in the neutral colour.
  offline;

  /// Whether the dot is drawn as a ring (stroke only) instead of a fill.
  bool get hollow => this == away || this == offline;

  /// Whether a bar is drawn across the dot.
  bool get hasBar => this == busy;
}

/// Size variant for status dot indicators.
enum CoreStatusSize {
  /// Extra-small (6px).
  xs,

  /// Small (8px).
  sm,

  /// Medium (10px, default).
  md,

  /// Large (12px).
  lg,

  /// Extra-large (14px).
  xl,
}

/// Contract for a unified status dot indicator component.
///
/// Displays a small colored dot to indicate current state.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [statusStyle] slot. Behavioural / semantic fields
/// (`color` variant, `size` variant, `semanticLabel`) stay flat on
/// the widget.
abstract interface class CoreStatusContract<W> {
  /// Status color variant. Ignored while [variant] is set — the variant picks
  /// the colour.
  CoreStatusColor get color;

  /// Presence variant. `null` keeps the plain coloured dot picked by [color].
  CoreStatusVariant? get variant;

  /// Visible text beside the dot. Distinct from [semanticLabel], which is
  /// the string a screen reader announces.
  W? get label;

  /// Status size variant.
  CoreStatusSize get size;

  /// Accessible label for screen readers.
  String? get semanticLabel;

  /// When true, the dot pulses. Default false. Honours reduced motion.
  bool get animated;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreStatusTheme.style
  ///   → parent component slot override
  ///   → widget.statusStyle
  /// ```
  CoreStatusStyle? get statusStyle;
}
