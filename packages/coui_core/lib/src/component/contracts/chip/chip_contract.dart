/// Platform-independent contract for chip components.
///
/// Defines the interface that all chip implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/chip/chip_shape.dart';
import 'package:coui_core/src/component/contracts/chip/chip_size.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/contracts/chip/chip_variant.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_color.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_emphasis.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a chip component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [chipStyle] field — see [CoreChipStyle] for the merge
/// chain. Behaviour fields stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreChipContract<W> {
  /// The single-line clamp both platforms have always drawn on [label]
  /// when the caller states none — Flutter reads it into `Text.maxLines`,
  /// Web gets the same shape from the `truncate` utility its resolver
  /// keeps while both clamp parameters are `null`.
  static const int defaultLabelMaxLines = 1;

  /// The ellipsis both platforms have always drawn on an overflowing
  /// [label] when the caller states none.
  static const CoreTextOverflow defaultLabelOverflow =
      CoreTextOverflow.ellipsis;

  /// The debug-build report both platforms raise for the pair
  /// [CoreChipVariant.filled] + [CoreChipEmphasis.low] on a chip that can be
  /// selected.
  ///
  /// One string, so the two widgets cannot word the same misuse
  /// differently. It is raised from the widget inside an `assert` — never
  /// thrown, and absent from release builds — because the pair still
  /// renders; it is only a poor pair, not an illegal one.
  static const String filledLowEmphasisReport =
      'Chip(variant: CoreChipVariant.filled, emphasis: CoreChipEmphasis.low): '
      'a filled resting chip and a low-emphasis selected chip differ by a '
      'few percent of lightness, so the two states are told apart by hue '
      'alone — which a colour-blind reader and a forced-colors mode do not '
      'see (WCAG 1.4.1). Pair `filled` with CoreChipEmphasis.high, or use '
      'CoreChipVariant.outlined for a low-emphasis chip.';

  /// The chip's name as a reader hears it — the key, then the value
  /// ("필터 전체"), in the order both are drawn.
  ///
  /// One function so the two platforms name the chip the same way wherever
  /// they have to spell the name out (the remove button carries it, since
  /// its glyph has no text of its own). Either half may be absent.
  static String accessibleName({String? prefixLabel, String? label}) => [
    ?prefixLabel,
    ?label,
  ].join(' ');

  /// Whether the chip is selected.
  bool get selected;

  /// Whether the chip is enabled (interactive).
  bool get enabled;

  /// Tap callback.
  void Function()? get onTap;

  /// Remove callback (shows close button when non-null).
  void Function()? get onRemove;

  /// Key text drawn in front of [label] — what a filter chip filters by,
  /// ahead of the value it currently holds ("필터" before "전체").
  ///
  /// Its own field rather than a `Row` in [child], because a key and its
  /// value are two typographic roles with their own colour rule: on a
  /// resting chip the key reads a column of its own — quieter than a
  /// high-emphasis label, the same ink as a low-emphasis one, so there the
  /// pair is told apart by role alone — and it takes the label's colour once
  /// the chip is selected or disabled. Stated as data, both platforms and
  /// the canvas draw that pair from the same tokens; built inside [child],
  /// neither the colour rule nor the size ladder would reach it. Stays on one
  /// line and never shrinks — the value is the half that yields to a narrow
  /// row.
  /// `null` (default) draws no key.
  String? get prefixLabel;

  /// Text label displayed on the chip.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the single-line clamp this component has
  /// always drawn.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the ellipsis this component has always drawn.
  CoreTextOverflow? get labelOverflow;

  /// Custom child widget (alternative to label).
  W? get child;

  /// Widget displayed before the label.
  W? get leading;

  /// Widget displayed after the label.
  W? get trailing;

  /// The colour the chip takes on when it is selected.
  ///
  /// An unselected chip is colourless whatever this says.
  CoreChipColor get chipColor;

  /// How an unselected chip is drawn — [CoreChipVariant.outlined] (the
  /// default) or [CoreChipVariant.filled].
  ///
  /// Never touches a selected or a disabled chip. [CoreChipVariant.filled]
  /// belongs with [CoreChipEmphasis.high]; the pair `filled` + `low` is
  /// reported in debug builds — see [CoreChipVariant].
  CoreChipVariant get variant;

  /// How loudly the chip states [chipColor].
  ///
  /// Orthogonal to [selected] — together the two pick one of the four
  /// rows documented on [CoreChipEmphasis].
  CoreChipEmphasis get emphasis;

  /// The size of the chip — three tiers, see [CoreChipSize].
  CoreChipSize get size;

  /// The outline the chip is drawn in — [CoreChipShape.rounded] (the
  /// default, the size row's corner) or [CoreChipShape.pill] (half-circle
  /// ends on every size).
  ///
  /// A corner stated through [chipStyle] (`borderRadius`) wins over both
  /// shapes.
  CoreChipShape get shape;

  /// Override seed color for custom chip color.
  CoreColor? get seedColor;

  /// Max character length for label text.
  int? get maxLength;

  /// Per-instance chip chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreChipTheme.style
  ///   → parent component slot override
  ///   → widget.chipStyle
  /// ```
  CoreChipStyle? get chipStyle;
}
