/// Per-instance style for `MultipleChoice`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MultipleChoice` should render.
///
/// Each option is a composed `Chip` (unselected = neutral · outlined · low,
/// selected = primary · outlined · low), so the option face is [chipStyle]'s —
/// a partial [CoreChipStyle] merged over [defaultChipStyle] and
/// raw-forwarded to the `Chip`. The group itself states only
/// [optionSpacing] (the gap between chips). The older flat option-box
/// fields ([optionPadding], [selectedBackgroundColor], …) are deprecated;
/// they still reach the chip — [chipStyleFor] folds them in under
/// [chipStyle] — so existing overrides keep working for one more version.
/// Behavioural / semantic fields (`options`, `value`, `enabled`,
/// `allowUnselect`, `onChanged`) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreMultipleChoiceTheme.style              // 프로젝트 공통
///   → parent component slot override
///   → widget.multipleChoiceStyle                 // 인스턴스별
/// ```
@immutable
class CoreMultipleChoiceStyle implements CoreStyle<CoreMultipleChoiceStyle> {
  /// Creates a [CoreMultipleChoiceStyle].
  const CoreMultipleChoiceStyle({
    this.optionSpacing,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.optionPadding,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.optionBorderRadius,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.optionBorderWidth,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.selectedBackgroundColor,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.selectedTextStyle,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.selectedBorderColor,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.unselectedBackgroundColor,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.unselectedTextStyle,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.unselectedBorderColor,
    @Deprecated(
      'Use chipStyle (since 0.173)',
    )
    this.disabledTextStyle,
    this.transitionDuration,
    this.clickableStyle,
    this.chipStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// Default selected option background colour token.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default selected option text colour token.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultSelectedTextColor = CoreColor.token(
    CoreColors.onPrimary,
  );

  /// Default selected option border colour token.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultSelectedBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default unselected option background colour token.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultUnselectedBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default unselected option border colour token — `outline`.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultUnselectedBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default selected option text style — `bodySmall` typography
  /// carrying the `onPrimary` text colour (sb8 — raw `selectedTextColor`
  /// field replaced by the nested [CoreTextStyle] slot, its colour
  /// inlined here).
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreTextStyle defaultSelectedTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onPrimary),
  );

  /// Default unselected option text style — `bodySmall` typography
  /// carrying the `onSurface` text colour (sb8 — raw `unselectedTextColor`
  /// field replaced by the nested [CoreTextStyle] slot, its colour
  /// inlined here).
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreTextStyle defaultUnselectedTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default disabled option text style — `bodySmall` typography
  /// carrying the `onSurfaceVariant` text colour (sb8 — raw
  /// `disabledTextColor` field replaced by the nested [CoreTextStyle] slot,
  /// its colour inlined here).
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreTextStyle defaultDisabledTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default nested [CoreGapStyle] slot forwarded to the inter-option
  /// Default inter-option spacing (logical px). N-sibling 균등 분포 —
  /// Flutter `Row.spacing` / Web flex container `gap` CSS.
  static const double defaultOptionSpacing = CoreSpace.space8;

  /// Default option padding.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreEdgeInsets defaultOptionPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
    vertical: CoreSpace.space8,
  );

  /// Default option corner radius — selector radius.
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreBorderRadius defaultOptionBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default option border width (logical px).
  @Deprecated(
    'The option face is the composed Chip now — set [chipStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const double defaultOptionBorderWidth = CoreStrokeWidth.stroke1;

  /// Default transition duration for selection colour changes.
  @Deprecated(
    'The composed Chip states its own transition — set '
    'chipStyle.transitionDuration instead; this default is no longer read '
    '(since 0.173)',
  )
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// per-option `Clickable` — a partial with the two diverging
  /// overrides: the option paints its own disabled state
  /// ([defaultDisabledTextStyle] + disabled variant colours), so the
  /// Clickable's generic disabled fade must stay off or the disabled
  /// chrome fades twice; and the focus ring follows the option's
  /// corner radius instead of the Clickable default. Everything else
  /// (press-scale 0.97 for the chip-shaped options) stays null and
  /// resolves inside the Clickable's own resolver.
  @Deprecated(
    'The composed Chip states its own Clickable defaults — this default '
    'is no longer read (since 0.173)',
  )
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    borderRadius: defaultOptionBorderRadius,
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default nested [CoreChipStyle] slot for the composed per-option
  /// `Chip` — a partial that states only what this component decides:
  /// the option row is 32 tall. The chip's own resolver fills everything
  /// else (outlined resting face, primary · low-emphasis selected face, corner,
  /// padding, label role), so the options track `Chip` instead of
  /// restating it.
  static const CoreChipStyle defaultChipStyle = CoreChipStyle(
    minHeight: CoreSize.size32,
  );

  /// Gap between consecutive options (logical px) — `Wrap.spacing` on
  /// Flutter, the root row `gap` on Web. Defaults to [defaultOptionSpacing].
  final double? optionSpacing;

  /// Option padding override.
  @Deprecated(
    'Use chipStyle.padding — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreEdgeInsets? optionPadding;

  /// Option corner radius override.
  @Deprecated(
    'Use chipStyle.borderRadius — the option is a composed Chip now; '
    'the value still reaches the chip until removed (since 0.173)',
  )
  final CoreBorderRadius? optionBorderRadius;

  /// Option border width override (logical px).
  @Deprecated(
    'Use chipStyle.borderWidth — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final double? optionBorderWidth;

  /// Selected option background colour override.
  @Deprecated(
    'Use chipStyle.backgroundColor on a selected Chip — the option is a '
    'composed Chip now; the value still reaches the chip until removed '
    '(since 0.173)',
  )
  final CoreColor? selectedBackgroundColor;

  /// Selected option text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `selectedTextColor` field removed). Defaults to
  /// [defaultSelectedTextStyle].
  @Deprecated(
    'Use chipStyle.labelStyle — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreTextStyle? selectedTextStyle;

  /// Selected option border colour override.
  @Deprecated(
    'Use chipStyle.borderColor — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreColor? selectedBorderColor;

  /// Unselected option background colour override.
  @Deprecated(
    'Use chipStyle.backgroundColor — the option is a composed Chip now; '
    'the value still reaches the chip until removed (since 0.173)',
  )
  final CoreColor? unselectedBackgroundColor;

  /// Unselected option text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `unselectedTextColor` field removed). Defaults to
  /// [defaultUnselectedTextStyle].
  @Deprecated(
    'Use chipStyle.labelStyle — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreTextStyle? unselectedTextStyle;

  /// Unselected option border colour override.
  @Deprecated(
    'Use chipStyle.borderColor — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreColor? unselectedBorderColor;

  /// Disabled option text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `disabledTextColor` field removed). Defaults to
  /// [defaultDisabledTextStyle].
  @Deprecated(
    'Use chipStyle.labelStyle — the option is a composed Chip now; the '
    'value still reaches the chip until removed (since 0.173)',
  )
  final CoreTextStyle? disabledTextStyle;

  /// Transition duration override for selection colour changes. Folded into
  /// the composed `Chip`'s `transitionDuration` by [chipStyleFor].
  final Duration? transitionDuration;

  /// Style for each option's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. [chipStyleFor] puts it into the option
  /// `Chip`'s own `clickableStyle`; the `Chip` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Style for each option's `Chip`. Laid over [defaultChipStyle] (and the
  /// deprecated flat option fields, see [chipStyleFor]) and passed as is to
  /// `Chip(chipStyle:)`; the `Chip` fills in the rest.
  final CoreChipStyle? chipStyle;

  /// The [CoreChipStyle] the option in the given state is drawn with:
  /// [defaultChipStyle], then the deprecated flat option fields that
  /// target the chip, then [chipStyle] (the new slot wins).
  ///
  /// A flat field that was never stated contributes nothing — the chip
  /// keeps its own default — so the fold only carries real overrides.
  /// The text slot follows the same precedence the option always had:
  /// disabled over selected over unselected.
  CoreChipStyle chipStyleFor({required bool selected, required bool enabled}) {
    final folded = CoreChipStyle(
      backgroundColor: selected
          ? selectedBackgroundColor
          : unselectedBackgroundColor,
      borderColor: selected ? selectedBorderColor : unselectedBorderColor,
      borderWidth: optionBorderWidth,
      borderRadius: optionBorderRadius,
      padding: optionPadding,
      transitionDuration: transitionDuration,
      clickableStyle: clickableStyle,
      labelStyle: !enabled
          ? disabledTextStyle
          : selected
          ? selectedTextStyle
          : unselectedTextStyle,
    );
    return defaultChipStyle.merge(folded).merge(chipStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreMultipleChoiceStyle merge(CoreMultipleChoiceStyle? other) {
    if (other == null) return this;
    return CoreMultipleChoiceStyle(
      optionSpacing: other.optionSpacing ?? optionSpacing,
      optionPadding: other.optionPadding ?? optionPadding,
      optionBorderRadius: other.optionBorderRadius ?? optionBorderRadius,
      optionBorderWidth: other.optionBorderWidth ?? optionBorderWidth,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      selectedTextStyle: _mergeText(selectedTextStyle, other.selectedTextStyle),
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      unselectedBackgroundColor:
          other.unselectedBackgroundColor ?? unselectedBackgroundColor,
      unselectedTextStyle: _mergeText(
        unselectedTextStyle,
        other.unselectedTextStyle,
      ),
      unselectedBorderColor:
          other.unselectedBorderColor ?? unselectedBorderColor,
      disabledTextStyle: _mergeText(disabledTextStyle, other.disabledTextStyle),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      chipStyle: chipStyle?.merge(other.chipStyle) ?? other.chipStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMultipleChoiceStyle copyWith({
    double? optionSpacing,
    CoreEdgeInsets? optionPadding,
    CoreBorderRadius? optionBorderRadius,
    double? optionBorderWidth,
    CoreColor? selectedBackgroundColor,
    CoreTextStyle? selectedTextStyle,
    CoreColor? selectedBorderColor,
    CoreColor? unselectedBackgroundColor,
    CoreTextStyle? unselectedTextStyle,
    CoreColor? unselectedBorderColor,
    CoreTextStyle? disabledTextStyle,
    Duration? transitionDuration,
    CoreClickableStyle? clickableStyle,
    CoreChipStyle? chipStyle,
  }) {
    return CoreMultipleChoiceStyle(
      optionSpacing: optionSpacing ?? this.optionSpacing,
      optionPadding: optionPadding ?? this.optionPadding,
      optionBorderRadius: optionBorderRadius ?? this.optionBorderRadius,
      optionBorderWidth: optionBorderWidth ?? this.optionBorderWidth,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      unselectedBackgroundColor:
          unselectedBackgroundColor ?? this.unselectedBackgroundColor,
      unselectedTextStyle: unselectedTextStyle ?? this.unselectedTextStyle,
      unselectedBorderColor:
          unselectedBorderColor ?? this.unselectedBorderColor,
      disabledTextStyle: disabledTextStyle ?? this.disabledTextStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      chipStyle: chipStyle ?? this.chipStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMultipleChoiceStyle &&
          runtimeType == other.runtimeType &&
          optionSpacing == other.optionSpacing &&
          optionPadding == other.optionPadding &&
          optionBorderRadius == other.optionBorderRadius &&
          optionBorderWidth == other.optionBorderWidth &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          selectedTextStyle == other.selectedTextStyle &&
          selectedBorderColor == other.selectedBorderColor &&
          unselectedBackgroundColor == other.unselectedBackgroundColor &&
          unselectedTextStyle == other.unselectedTextStyle &&
          unselectedBorderColor == other.unselectedBorderColor &&
          disabledTextStyle == other.disabledTextStyle &&
          transitionDuration == other.transitionDuration &&
          clickableStyle == other.clickableStyle &&
          chipStyle == other.chipStyle;

  @override
  int get hashCode => Object.hashAll([
    optionSpacing,
    optionPadding,
    optionBorderRadius,
    optionBorderWidth,
    selectedBackgroundColor,
    selectedTextStyle,
    selectedBorderColor,
    unselectedBackgroundColor,
    unselectedTextStyle,
    unselectedBorderColor,
    disabledTextStyle,
    transitionDuration,
    clickableStyle,
    chipStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
