/// Platform-independent contract for unified stat components.
///
/// Defines the interface that all Stat implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/stat/stat_style.dart';
import 'package:coui_core/src/component/contracts/stat/stat_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Change type for stat trend indicators.
enum CoreStatChangeType {
  /// Positive change.
  positive,

  /// Negative change.
  negative,

  /// Neutral/no significant change.
  neutral,
}

/// Contract for a unified stat/metric display component.
///
/// Displays a label, a value with an optional unit, an optional change
/// indicator and an optional description line in a card format. The rows
/// read top to bottom in that order: label → value (+ unit) → change →
/// description.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget?`, Web `Component?`).
abstract interface class CoreStatContract<W> {
  /// What the value row shows when [value] is `null` — an em dash, drawn
  /// in the value's role but the empty-value colour, so an absent figure
  /// reads as absent rather than as a figure.
  ///
  /// Shared by Flutter and Web so the two platforms cannot show different
  /// placeholders.
  static const String defaultEmptyValue = '\u{2014}';

  /// Visual variant of the stat card.
  CoreStatVariant get variant;

  /// Size of the stat card — `md` (default) or the compact `sm` for narrow
  /// dashboard cells.
  CoreComponentSize get size;

  /// Stat label text.
  String get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Stat value text.
  ///
  /// `null` renders [defaultEmptyValue] in the empty-value colour instead
  /// of a figure — the value is not known yet, or there is none.
  String? get value;

  /// Unit drawn after [value], baseline-aligned with it (`명`, `%`, `원`).
  ///
  /// Not drawn beside the empty value: a unit qualifies a figure, and the
  /// dash is not one.
  String? get unit;

  /// Change indicator text.
  String? get change;

  /// Change type for color and icon.
  CoreStatChangeType? get changeType;

  /// Footnote line under the change row — context for the figure (the
  /// period it covers, what it counts). Unlike [change] it carries no
  /// trend arrow and no trend colour.
  String? get description;

  /// Optional trailing icon widget.
  W get icon;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreStatStyle.defaults*
  ///   → CoreStatStyle.defaultsByVariant[variant]
  ///   → CoreStatTheme.style
  ///   → CoreStatTheme.variantStyles[variant]
  ///   → widget.statStyle
  /// ```
  CoreStatStyle? get statStyle;
}
