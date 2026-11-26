/// Platform-independent contract for the unified validation badge component.
library;

import 'package:coui_core/src/component/contracts/validation_badge/validation_badge_size.dart';
import 'package:coui_core/src/component/contracts/validation_badge/validation_badge_style.dart';
import 'package:coui_core/src/component/contracts/validation_badge/validation_state.dart';
import 'package:coui_core/src/icon/icon_name.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a unified `ValidationBadge`.
abstract interface class CoreValidationBadgeContract {
  /// The single-line clamp both platforms have always drawn on [label]
  /// when the caller states none — Flutter reads it into `Text.maxLines`,
  /// Web gets the same shape from the `truncate` utility its resolver
  /// keeps while both clamp parameters are `null`.
  static const int defaultLabelMaxLines = 1;

  /// The ellipsis both platforms have always drawn on an overflowing
  /// [label] when the caller states none.
  static const CoreTextOverflow defaultLabelOverflow =
      CoreTextOverflow.ellipsis;

  /// Badge label text.
  String get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the single-line clamp this component has
  /// always drawn.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the ellipsis this component has always drawn.
  CoreTextOverflow? get labelOverflow;

  /// Current validation state.
  CoreValidationState get state;

  /// Optional icon for the pending state. When null, a default `dot`
  /// glyph (Lucide `dot`) is used.
  IconName? get pendingIcon;

  /// Optional icon for the valid state. When null, a default `check`
  /// glyph (Lucide `check`) is used.
  IconName? get validIcon;

  /// Optional icon for the invalid state. When null, a default `x`
  /// glyph (Lucide `x`) is used.
  IconName? get invalidIcon;

  /// Optional size preset override. When null the widget falls through to
  /// [CoreValidationBadgeStyle.defaultSize] (semantic identifier — the
  /// theme cannot override it).
  CoreValidationBadgeSize? get size;

  /// Optional per-state color override.
  CoreValidationBadgeStyle? get style;
}
