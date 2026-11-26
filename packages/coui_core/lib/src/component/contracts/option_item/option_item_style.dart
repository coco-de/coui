/// Per-instance style for `OptionItem`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/option_item/option_item_selection.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how an `OptionItem` renders.
///
/// The row is a bordered card: a rounded box [minHeight] tall at least, drawn
/// in [borderColor] at rest with no fill of its own. A chosen row fills with
/// [selectedBackgroundColor] and draws [selectedBorderColor] at
/// [selectedBorderWidth]; a chosen row that is disabled fills with
/// [disabledSelectedBackgroundColor] and keeps the resting border. [padding]
/// is measured from the card's outer edge, border included, so the border
/// never moves the content.
///
/// While the row is pressed it paints a rounded face over its fill and under
/// its content. The face is measured from the inside of the border: it
/// reaches [pressedBackgroundOutset] past each side of that edge and stops
/// [pressedBackgroundInset] short of its top and bottom.
///
/// ```text
/// CoreOptionItemStyle.default*  (+ defaultsBySelection)
///   → CoreOptionItemTheme.style                      // project-wide
///   → widget.optionItemStyle                         // per-instance
/// ```
@immutable
class CoreOptionItemStyle implements CoreStyle<CoreOptionItemStyle> {
  /// Creates a [CoreOptionItemStyle].
  const CoreOptionItemStyle({
    this.padding,
    this.spacing,
    this.minHeight,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.selectedBackgroundColor,
    this.selectedBorderColor,
    this.selectedBorderWidth,
    this.disabledSelectedBackgroundColor,
    this.labelTextStyle,
    this.selectedLabelTextStyle,
    this.descriptionTextStyle,
    this.descriptionGapStyle,
    this.leadingIconStyle,
    this.checkIconStyle,
    this.disabledForegroundColor,
    this.pressedBackgroundColor,
    this.stateLayer,
    this.pressedBackgroundBorderRadius,
    this.pressedBackgroundOutset,
    this.pressedBackgroundInset,
    this.clickableStyle,
  });

  /// Inset of the row's content (pre-scaling). `null` → [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Space between the parts of the row — leading, text, mark (logical px,
  /// pre-scaling). `null` → [defaultSpacing].
  final double? spacing;

  /// The card's least height (logical px, pre-scaling) — a floor: a row with
  /// a description grows past it. `null` → [defaultMinHeight].
  final double? minHeight;

  /// Corner of the card. `null` → [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Colour of the card's border at rest — and of a chosen row that is
  /// disabled. `null` → [defaultBorderColor].
  final CoreColor? borderColor;

  /// Width of the card's border at rest (logical px). `null` →
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Fill of a chosen row. `null` → [defaultSelectedBackgroundColor].
  final CoreColor? selectedBackgroundColor;

  /// Colour of a chosen row's border. `null` → [defaultSelectedBorderColor].
  final CoreColor? selectedBorderColor;

  /// Width of a chosen row's border (logical px). `null` →
  /// [defaultSelectedBorderWidth].
  final double? selectedBorderWidth;

  /// Fill of a chosen row that is disabled. Its border stays the resting
  /// one. `null` → [defaultDisabledSelectedBackgroundColor].
  final CoreColor? disabledSelectedBackgroundColor;

  /// Text style of the label, merged on top of [defaultLabelTextStyle].
  final CoreTextStyle? labelTextStyle;

  /// What a chosen row's label states over [labelTextStyle] — its colour and
  /// weight. A chosen row that is disabled keeps this weight and takes
  /// [disabledForegroundColor] for its ink. `null` → the entry of
  /// [defaultsBySelection] for the row's selection.
  final CoreTextStyle? selectedLabelTextStyle;

  /// Text style of the description, merged on top of
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Space between the label and the description. `null` →
  /// [defaultDescriptionGapStyle].
  final CoreGapStyle? descriptionGapStyle;

  /// Size of the leading glyph. `null` → [defaultLeadingIconStyle].
  final CoreIconStyle? leadingIconStyle;

  /// Size and colour of the check mark of a chosen single-selection row.
  /// `null` → [defaultCheckIconStyle].
  final CoreIconStyle? checkIconStyle;

  /// Colour of the label, description, leading glyph and check mark of a
  /// disabled row. `null` → [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// The colour of the pressed face — shown at [stateLayer]'s pressed
  /// weight. `null` → [defaultPressedBackgroundColor].
  final CoreColor? pressedBackgroundColor;

  /// How strongly the pressed face shows. `null` → [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// Corner of the pressed face, measured at the card's outer edge like
  /// [borderRadius]. The face is drawn inside the border, so its own corner
  /// is this less the border width in effect (the resting or the chosen
  /// one) — concentric with the border's inner curve. `null` →
  /// [defaultPressedBackgroundBorderRadius].
  final CoreBorderRadius? pressedBackgroundBorderRadius;

  /// How far the pressed face reaches past each side of the inside of the
  /// card's border (logical px, pre-scaling). `null` →
  /// [defaultPressedBackgroundOutset].
  final double? pressedBackgroundOutset;

  /// How far the pressed face stops short of the top and bottom of the
  /// inside of the card's border (logical px, pre-scaling). `null` →
  /// [defaultPressedBackgroundInset].
  final double? pressedBackgroundInset;

  /// Style for the row's `Clickable` — focus ring, press feedback. `null` →
  /// [defaultClickableStyle]. Passed to the `Clickable` as is.
  final CoreClickableStyle? clickableStyle;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// `space12` above and below, `space16` at the sides — measured from the
  /// card's outer edge, border included.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space16,
    vertical: CoreSpace.space12,
  );

  /// Between the seats of the row — `space12`.
  static const double defaultSpacing = CoreSpace.space12;

  /// The card is at least 52 tall — one line of label sits on its centre.
  static const double defaultMinHeight = CoreSpace.space52;

  /// The card's corner — 12.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// The resting border — `outlineVariant`.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// The resting border is 1 wide.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// A chosen row's fill — `surfaceContainerLow`.
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// A chosen row's border — the accent, `primary`.
  static const CoreColor defaultSelectedBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// A chosen row's border is 1.5 wide.
  static const double defaultSelectedBorderWidth = CoreStrokeWidth.stroke1_5;

  /// A chosen, disabled row's fill — `surfaceContainer`. The fill and the
  /// mark say it is chosen; the border stays the resting one so the accent
  /// is not shown on a row that cannot be changed.
  static const CoreColor defaultDisabledSelectedBackgroundColor =
      CoreColor.token(CoreColors.surfaceContainer);

  /// The label — `bodyLarge` at Medium weight in `onSurface`. The line box
  /// stays the role's.
  static final CoreTextStyle defaultLabelTextStyle = const CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.medium);

  /// The description — `bodySmall` in `onSurfaceVariant`.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Between the label and the description — 4.
  static const CoreGapStyle defaultDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
    crossAxisExtent: 0,
  );

  /// The leading glyph — 20.
  static const CoreIconStyle defaultLeadingIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
  );

  /// The check mark — 20, in the accent colour.
  static const CoreIconStyle defaultCheckIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
    color: CoreColor.token(CoreColors.primary),
  );

  /// A disabled row's ink — `disabledContent`.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// The pressed face — `surfaceContainerHigh`, painted over the card's
  /// fill.
  static const CoreColor defaultPressedBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// The pressed face is opaque: it is a surface tone, not a wash of the
  /// row's ink, so it covers a chosen row's fill while held. The row reads
  /// only the pressed weight; hover and focus show no face (the focus ring
  /// is the focus indicator).
  static const CoreStateLayer defaultStateLayer = CoreStateLayer(
    hover: CoreOpacity.opacity0,
    focus: CoreOpacity.opacity0,
    pressed: CoreOpacity.opacity100,
  );

  /// The pressed face's corner — 12, the card's own, so inside the border
  /// it draws 11 at rest and 10.5 on a chosen row.
  static const CoreBorderRadius defaultPressedBackgroundBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius12);

  /// The pressed face fills the card to the inside of its border — no reach
  /// past the sides.
  static const double defaultPressedBackgroundOutset = CoreSpace.space0;

  /// The pressed face fills the card to the inside of its border — no gap
  /// at the top or bottom.
  static const double defaultPressedBackgroundInset = CoreSpace.space0;

  /// The composed `Clickable`'s chrome — no press scale (the pressed face is
  /// the row's feedback, and a row that shrinks under a face that does not
  /// would pull the two apart) and no dimming of a disabled row (its ink is
  /// already the disabled foreground; a dimming on top would count it
  /// twice).
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
    disabledOpacity: 1,
  );

  /// What a chosen row's label states over the label, per selection: the
  /// SemiBold weight of a chosen label, and the colour that says "chosen" —
  /// the accent for a single selection, the ordinary ink for multiple (the
  /// checkbox says it there).
  static const Map<CoreOptionItemSelection, CoreOptionItemStyle>
  defaultsBySelection = {
    CoreOptionItemSelection.single: CoreOptionItemStyle(
      selectedLabelTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.primary),
        fontWeight: CoreFontWeight.semiBold,
      ),
    ),
    CoreOptionItemSelection.multiple: CoreOptionItemStyle(
      selectedLabelTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurface),
        fontWeight: CoreFontWeight.semiBold,
      ),
    ),
  };

  /// Merges [other] on top of this style — every field [other] states wins;
  /// the text styles merge field by field.
  @override
  CoreOptionItemStyle merge(CoreOptionItemStyle? other) {
    if (other == null) return this;
    return CoreOptionItemStyle(
      padding: other.padding ?? padding,
      spacing: other.spacing ?? spacing,
      minHeight: other.minHeight ?? minHeight,
      borderRadius: other.borderRadius ?? borderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      selectedBorderWidth: other.selectedBorderWidth ?? selectedBorderWidth,
      disabledSelectedBackgroundColor:
          other.disabledSelectedBackgroundColor ??
          disabledSelectedBackgroundColor,
      labelTextStyle: labelTextStyle == null
          ? other.labelTextStyle
          : labelTextStyle!.merge(other.labelTextStyle),
      selectedLabelTextStyle: selectedLabelTextStyle == null
          ? other.selectedLabelTextStyle
          : selectedLabelTextStyle!.merge(other.selectedLabelTextStyle),
      descriptionTextStyle: descriptionTextStyle == null
          ? other.descriptionTextStyle
          : descriptionTextStyle!.merge(other.descriptionTextStyle),
      descriptionGapStyle: descriptionGapStyle == null
          ? other.descriptionGapStyle
          : descriptionGapStyle!.merge(other.descriptionGapStyle),
      leadingIconStyle: leadingIconStyle == null
          ? other.leadingIconStyle
          : leadingIconStyle!.merge(other.leadingIconStyle),
      checkIconStyle: checkIconStyle == null
          ? other.checkIconStyle
          : checkIconStyle!.merge(other.checkIconStyle),
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      pressedBackgroundColor:
          other.pressedBackgroundColor ?? pressedBackgroundColor,
      stateLayer: other.stateLayer ?? stateLayer,
      pressedBackgroundBorderRadius:
          other.pressedBackgroundBorderRadius ?? pressedBackgroundBorderRadius,
      pressedBackgroundOutset:
          other.pressedBackgroundOutset ?? pressedBackgroundOutset,
      pressedBackgroundInset:
          other.pressedBackgroundInset ?? pressedBackgroundInset,
      clickableStyle: clickableStyle == null
          ? other.clickableStyle
          : clickableStyle!.merge(other.clickableStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreOptionItemStyle copyWith({
    CoreEdgeInsets? padding,
    double? spacing,
    double? minHeight,
    CoreBorderRadius? borderRadius,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? selectedBackgroundColor,
    CoreColor? selectedBorderColor,
    double? selectedBorderWidth,
    CoreColor? disabledSelectedBackgroundColor,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? selectedLabelTextStyle,
    CoreTextStyle? descriptionTextStyle,
    CoreGapStyle? descriptionGapStyle,
    CoreIconStyle? leadingIconStyle,
    CoreIconStyle? checkIconStyle,
    CoreColor? disabledForegroundColor,
    CoreColor? pressedBackgroundColor,
    CoreStateLayer? stateLayer,
    CoreBorderRadius? pressedBackgroundBorderRadius,
    double? pressedBackgroundOutset,
    double? pressedBackgroundInset,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreOptionItemStyle(
      padding: padding ?? this.padding,
      spacing: spacing ?? this.spacing,
      minHeight: minHeight ?? this.minHeight,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      disabledSelectedBackgroundColor:
          disabledSelectedBackgroundColor ??
          this.disabledSelectedBackgroundColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectedLabelTextStyle:
          selectedLabelTextStyle ?? this.selectedLabelTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      descriptionGapStyle: descriptionGapStyle ?? this.descriptionGapStyle,
      leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
      checkIconStyle: checkIconStyle ?? this.checkIconStyle,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      pressedBackgroundColor:
          pressedBackgroundColor ?? this.pressedBackgroundColor,
      stateLayer: stateLayer ?? this.stateLayer,
      pressedBackgroundBorderRadius:
          pressedBackgroundBorderRadius ?? this.pressedBackgroundBorderRadius,
      pressedBackgroundOutset:
          pressedBackgroundOutset ?? this.pressedBackgroundOutset,
      pressedBackgroundInset:
          pressedBackgroundInset ?? this.pressedBackgroundInset,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOptionItemStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          spacing == other.spacing &&
          minHeight == other.minHeight &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          selectedBorderColor == other.selectedBorderColor &&
          selectedBorderWidth == other.selectedBorderWidth &&
          disabledSelectedBackgroundColor ==
              other.disabledSelectedBackgroundColor &&
          labelTextStyle == other.labelTextStyle &&
          selectedLabelTextStyle == other.selectedLabelTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          descriptionGapStyle == other.descriptionGapStyle &&
          leadingIconStyle == other.leadingIconStyle &&
          checkIconStyle == other.checkIconStyle &&
          disabledForegroundColor == other.disabledForegroundColor &&
          pressedBackgroundColor == other.pressedBackgroundColor &&
          stateLayer == other.stateLayer &&
          pressedBackgroundBorderRadius ==
              other.pressedBackgroundBorderRadius &&
          pressedBackgroundOutset == other.pressedBackgroundOutset &&
          pressedBackgroundInset == other.pressedBackgroundInset &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    padding,
    spacing,
    minHeight,
    borderRadius,
    borderColor,
    borderWidth,
    selectedBackgroundColor,
    selectedBorderColor,
    selectedBorderWidth,
    disabledSelectedBackgroundColor,
    labelTextStyle,
    selectedLabelTextStyle,
    descriptionTextStyle,
    descriptionGapStyle,
    leadingIconStyle,
    checkIconStyle,
    disabledForegroundColor,
    pressedBackgroundColor,
    stateLayer,
    pressedBackgroundBorderRadius,
    pressedBackgroundOutset,
    pressedBackgroundInset,
    clickableStyle,
  ]);
}
