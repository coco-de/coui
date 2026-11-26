/// Per-instance style for `ThemeController`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/theme_controller/theme_controller_size.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ThemeController` should render.
///
/// Carries every chrome / dimensional override for the theme-swatch
/// grid and its buttons. Platform-neutral (Epic #1415 option D).
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreThemeControllerStyle implements CoreStyle<CoreThemeControllerStyle> {
  /// Creates a [CoreThemeControllerStyle].
  const CoreThemeControllerStyle({
    this.buttonSize,
    this.previewSize,
    this.buttonSpacing,
    this.swatchMinWidth,
    this.buttonRadius,
    this.previewBorderRadius,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedBorderWidth,
    this.unselectedBorderWidth,
    this.hoverBorderColor,
    this.hoverBorderWidth,
    this.buttonBackgroundColor,
    this.pressedPreviewShrink,
    this.labelStyle,
    this.labelColor,
    this.selectedLabelColor,
    this.labelGapStyle,
    this.disabledBorderColor,
    this.disabledPreviewColor,
    this.disabledLabelColor,
    this.clickableStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default size of each theme button (logical px).
  static const double defaultButtonSize = CoreSize.size40;

  /// Default size of each colour-preview circle (logical px).
  static const double defaultPreviewSize = CoreSize.size32;

  /// Default spacing between adjacent theme buttons (logical px),
  /// consumed as native `Wrap.spacing` / `Wrap.runSpacing` on Flutter
  /// and as the flex container `gap` CSS property on Web.
  static const double defaultButtonSpacing = CoreSpace.space12;

  /// Default minimum width of one swatch cell (logical px) — the column
  /// that holds a button, its gap and its label.
  ///
  /// A floor, not a fixed width: a theme name longer than the button
  /// widens its own cell (the name is always shown whole, never
  /// ellipsised), and every cell at least this wide keeps the buttons of a
  /// row on an even beat whatever the names' lengths are.
  static const double defaultSwatchMinWidth = CoreSize.size48;

  /// Default corner radius of a theme button — half the md button, so
  /// the ring around the palette is a circle.
  static const CoreBorderRadius defaultButtonRadius = CoreBorderRadius.all(
    CoreRadius.radius20,
  );

  /// Default corner radius of the colour-preview circle inside a swatch
  /// button — always fully round (radius 9999) so the preview reads as
  /// a circular dot whatever its [previewSize] is, pressed or not.
  static const CoreBorderRadius defaultPreviewBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default border colour of the selected theme button — the ring that
  /// marks the selection. It is the strong ink (`onSurface`), not the
  /// brand colour: the ring is the only selection mark the swatch has
  /// (there is no badge), so it has to read against any palette inside.
  static const CoreColor defaultSelectedBorderColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default border colour of an unselected theme button. Never painted
  /// at rest — [defaultUnselectedBorderWidth] is 0 — and kept as the
  /// field a caller restates together with a width of their own.
  static const CoreColor defaultUnselectedBorderColor = CoreColor.token(
    CoreColors.outline,
    fallbacks: [CoreColors.outlineVariant],
  );

  /// Default border thickness of the selected theme button (logical
  /// px).
  static const double defaultSelectedBorderWidth = CoreStrokeWidth.stroke2;

  /// Default border thickness of an unselected theme button (logical
  /// px). Zero: an unselected swatch at rest is the bare palette circle,
  /// with no ring until the pointer reaches it.
  static const double defaultUnselectedBorderWidth = CoreStrokeWidth.stroke0;

  /// Default ring colour of an unselected, enabled swatch while it is
  /// hovered or pressed. Lighter than [defaultSelectedBorderColor] on
  /// purpose: the hover ring is a hint ("this one can be picked"), the
  /// selected ring is a state.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default ring thickness of an unselected, enabled swatch while it is
  /// hovered or pressed (logical px) — the selected ring's width, so
  /// hovering a swatch never reads as a weaker version of selecting it.
  static const double defaultHoverBorderWidth = CoreStrokeWidth.stroke2;

  /// Default nested [CoreClickableStyle] slot for the composed
  /// per-swatch `Clickable` — press / focus / cursor chrome stays the
  /// Clickable's own, and the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward gives
  /// it a single-source default.
  ///
  /// `disabledOpacity` is pinned at 100% on purpose: this control
  /// states its off state with dedicated colour tokens
  /// ([defaultDisabledBorderColor] and the three beside it), and a fade
  /// laid over an already-chosen colour makes the resulting contrast
  /// depend on whatever surface happens to be underneath. Same shape
  /// `Checkbox` / `Chip` / `Toggle` use.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default background of a swatch button — none. The button is a ring
  /// around the palette, not a box with the palette in it, so the page
  /// shows through (and a surface material has no fill to restate).
  static const CoreColor defaultButtonBackgroundColor = CoreColor.transparent;

  /// Default amount the palette circle's diameter shrinks by while its
  /// swatch is pressed (logical px). The circle gives up one pixel on
  /// every side, which is what makes the press read as a press when the
  /// ring appears around it at the same moment.
  static const double defaultPressedPreviewShrink = CoreSpace.space2;

  /// Default typography of the swatch label — the theme's own name. The
  /// per-size ladder ([defaultsBySize]) states the role each size wears.
  ///
  /// Carries no colour on purpose. The label's colour is state-resolved
  /// (enabled / selected / disabled) by [defaultLabelColor],
  /// [defaultSelectedLabelColor] and [defaultDisabledLabelColor], and a
  /// colour inside this slot would be a second source for the same
  /// pixel — on Web literally so, since the typography emit turns a
  /// token colour into its own `text-*` class and the state colour emits
  /// another. Same split `Chip` uses.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
  );

  /// Default colour of the swatch label.
  static const CoreColor defaultLabelColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default colour of the label of the **selected** swatch — the strong
  /// ink, the same one its ring wears ([defaultSelectedBorderColor]), so
  /// the name and the ring say "this one" together.
  static const CoreColor defaultSelectedLabelColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default gap between a swatch button and its label.
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default border colour of a **disabled** swatch button. The
  /// selected swatch keeps [defaultSelectedBorderWidth] so the
  /// selection survives the greying — only the colour drops.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default fill of every palette segment on a **disabled** swatch.
  ///
  /// The palette is the one place this control paints caller data
  /// rather than chrome, and disabled is the one state where it stops:
  /// a locked theme discards its colours the way a disabled `Chip`
  /// discards its variant. Keeping them would say "you can still pick
  /// this one".
  static const CoreColor defaultDisabledPreviewColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default label colour on a **disabled** swatch.
  static const CoreColor defaultDisabledLabelColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Per-size chrome — the ladder, single-sourced for both platforms.
  ///
  /// `md` restates the flat defaults, so the default tier is the one the
  /// flat fields describe. The button is a circle on every rung (its
  /// radius is half its size) and the palette inside it sits 4 inside the
  /// ring on every rung — a 32 / 40 / 48 button around a 24 / 32 / 40
  /// palette. The label wears the role of its rung.
  static const Map<CoreThemeControllerSize, CoreThemeControllerStyle>
  defaultsBySize = {
    CoreThemeControllerSize.sm: CoreThemeControllerStyle(
      buttonSize: CoreSize.size32,
      previewSize: CoreSize.size24,
      buttonRadius: CoreBorderRadius.all(CoreRadius.radius16),
      buttonSpacing: CoreSpace.space12,
      labelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
    ),
    CoreThemeControllerSize.md: CoreThemeControllerStyle(
      buttonSize: CoreSize.size40,
      previewSize: CoreSize.size32,
      buttonRadius: CoreBorderRadius.all(CoreRadius.radius20),
      buttonSpacing: CoreSpace.space12,
      labelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
    ),
    CoreThemeControllerSize.lg: CoreThemeControllerStyle(
      buttonSize: CoreSize.size48,
      previewSize: CoreSize.size40,
      buttonRadius: CoreBorderRadius.all(CoreRadius.radius24),
      buttonSpacing: CoreSpace.space12,
      labelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Size of each theme button (logical px).
  final double? buttonSize;

  /// Size of each colour-preview circle (logical px).
  final double? previewSize;

  /// Spacing between adjacent theme buttons (logical px) — consumed as
  /// native `Wrap.spacing` / `Wrap.runSpacing` on Flutter and as the
  /// flex container `gap` CSS property on Web.
  final double? buttonSpacing;

  /// Minimum width of one swatch cell (logical px) — the cell grows past
  /// it when the theme name is wider; see [defaultSwatchMinWidth].
  final double? swatchMinWidth;

  /// Corner radius of a theme button.
  final CoreBorderRadius? buttonRadius;

  /// Corner radius of the colour-preview circle inside a swatch button.
  /// Defaults to a fully round dot — see [defaultPreviewBorderRadius].
  final CoreBorderRadius? previewBorderRadius;

  /// Border colour of the selected theme button.
  final CoreColor? selectedBorderColor;

  /// Border colour of an unselected theme button.
  final CoreColor? unselectedBorderColor;

  /// Border thickness of the selected theme button (logical px).
  final double? selectedBorderWidth;

  /// Border thickness of an unselected theme button (logical px).
  final double? unselectedBorderWidth;

  /// Ring colour of an unselected, enabled swatch while it is hovered or
  /// pressed. The selected swatch keeps [selectedBorderColor] in those
  /// states; a disabled one reacts to neither.
  final CoreColor? hoverBorderColor;

  /// Ring thickness of an unselected, enabled swatch while it is hovered
  /// or pressed (logical px).
  final double? hoverBorderWidth;

  /// Background of a swatch button.
  final CoreColor? buttonBackgroundColor;

  /// How much the palette circle's diameter shrinks while its swatch is
  /// pressed (logical px). The corner radius is [previewBorderRadius] —
  /// fully round — so the circle stays a circle at the smaller size.
  final double? pressedPreviewShrink;

  /// Border colour of a **disabled** swatch button.
  final CoreColor? disabledBorderColor;

  /// Fill of every palette segment on a **disabled** swatch.
  final CoreColor? disabledPreviewColor;

  /// Label colour on a **disabled** swatch.
  final CoreColor? disabledLabelColor;

  // ─── Slot Styles (nested) ─────────────────────

  /// Text style of the swatch label — typography only; the colour comes
  /// from [labelColor] / [selectedLabelColor] / [disabledLabelColor].
  final CoreTextStyle? labelStyle;

  /// Colour of the swatch label while the swatch is interactive and not
  /// selected.
  final CoreColor? labelColor;

  /// Colour of the label of the selected, interactive swatch.
  final CoreColor? selectedLabelColor;

  /// Gap between a swatch button and its label.
  final CoreGapStyle? labelGapStyle;

  /// Style for each swatch's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is; the `Clickable` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreThemeControllerStyle merge(CoreThemeControllerStyle? other) {
    if (other == null) return this;
    return CoreThemeControllerStyle(
      buttonSize: other.buttonSize ?? buttonSize,
      previewSize: other.previewSize ?? previewSize,
      buttonSpacing: other.buttonSpacing ?? buttonSpacing,
      swatchMinWidth: other.swatchMinWidth ?? swatchMinWidth,
      buttonRadius: other.buttonRadius ?? buttonRadius,
      previewBorderRadius: other.previewBorderRadius ?? previewBorderRadius,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      unselectedBorderColor:
          other.unselectedBorderColor ?? unselectedBorderColor,
      selectedBorderWidth: other.selectedBorderWidth ?? selectedBorderWidth,
      unselectedBorderWidth:
          other.unselectedBorderWidth ?? unselectedBorderWidth,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      hoverBorderWidth: other.hoverBorderWidth ?? hoverBorderWidth,
      buttonBackgroundColor:
          other.buttonBackgroundColor ?? buttonBackgroundColor,
      pressedPreviewShrink: other.pressedPreviewShrink ?? pressedPreviewShrink,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      labelColor: other.labelColor ?? labelColor,
      selectedLabelColor: other.selectedLabelColor ?? selectedLabelColor,
      labelGapStyle:
          labelGapStyle?.merge(other.labelGapStyle) ?? other.labelGapStyle,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledPreviewColor: other.disabledPreviewColor ?? disabledPreviewColor,
      disabledLabelColor: other.disabledLabelColor ?? disabledLabelColor,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreThemeControllerStyle copyWith({
    double? buttonSize,
    double? previewSize,
    double? buttonSpacing,
    double? swatchMinWidth,
    CoreBorderRadius? buttonRadius,
    CoreBorderRadius? previewBorderRadius,
    CoreColor? selectedBorderColor,
    CoreColor? unselectedBorderColor,
    double? selectedBorderWidth,
    double? unselectedBorderWidth,
    CoreColor? hoverBorderColor,
    double? hoverBorderWidth,
    CoreColor? buttonBackgroundColor,
    double? pressedPreviewShrink,
    CoreTextStyle? labelStyle,
    CoreColor? labelColor,
    CoreColor? selectedLabelColor,
    CoreGapStyle? labelGapStyle,
    CoreColor? disabledBorderColor,
    CoreColor? disabledPreviewColor,
    CoreColor? disabledLabelColor,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreThemeControllerStyle(
      buttonSize: buttonSize ?? this.buttonSize,
      previewSize: previewSize ?? this.previewSize,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      swatchMinWidth: swatchMinWidth ?? this.swatchMinWidth,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      previewBorderRadius: previewBorderRadius ?? this.previewBorderRadius,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      unselectedBorderColor:
          unselectedBorderColor ?? this.unselectedBorderColor,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      unselectedBorderWidth:
          unselectedBorderWidth ?? this.unselectedBorderWidth,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
      buttonBackgroundColor:
          buttonBackgroundColor ?? this.buttonBackgroundColor,
      pressedPreviewShrink: pressedPreviewShrink ?? this.pressedPreviewShrink,
      labelStyle: labelStyle ?? this.labelStyle,
      labelColor: labelColor ?? this.labelColor,
      selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledPreviewColor: disabledPreviewColor ?? this.disabledPreviewColor,
      disabledLabelColor: disabledLabelColor ?? this.disabledLabelColor,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreThemeControllerStyle &&
          runtimeType == other.runtimeType &&
          buttonSize == other.buttonSize &&
          previewSize == other.previewSize &&
          buttonSpacing == other.buttonSpacing &&
          swatchMinWidth == other.swatchMinWidth &&
          buttonRadius == other.buttonRadius &&
          previewBorderRadius == other.previewBorderRadius &&
          selectedBorderColor == other.selectedBorderColor &&
          unselectedBorderColor == other.unselectedBorderColor &&
          selectedBorderWidth == other.selectedBorderWidth &&
          unselectedBorderWidth == other.unselectedBorderWidth &&
          hoverBorderColor == other.hoverBorderColor &&
          hoverBorderWidth == other.hoverBorderWidth &&
          buttonBackgroundColor == other.buttonBackgroundColor &&
          pressedPreviewShrink == other.pressedPreviewShrink &&
          labelStyle == other.labelStyle &&
          labelColor == other.labelColor &&
          selectedLabelColor == other.selectedLabelColor &&
          labelGapStyle == other.labelGapStyle &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledPreviewColor == other.disabledPreviewColor &&
          disabledLabelColor == other.disabledLabelColor &&
          clickableStyle == other.clickableStyle;

  @override
  // `hashAll`, not `hash` — the field count passed the 20-argument cap
  // that `Object.hash` takes, and a truncated hash would make two styles
  // that differ only in a dropped field compare as one.
  int get hashCode => Object.hashAll([
    buttonSize,
    previewSize,
    buttonSpacing,
    swatchMinWidth,
    buttonRadius,
    previewBorderRadius,
    selectedBorderColor,
    unselectedBorderColor,
    selectedBorderWidth,
    unselectedBorderWidth,
    hoverBorderColor,
    hoverBorderWidth,
    buttonBackgroundColor,
    pressedPreviewShrink,
    labelStyle,
    labelColor,
    selectedLabelColor,
    labelGapStyle,
    disabledBorderColor,
    disabledPreviewColor,
    disabledLabelColor,
    clickableStyle,
  ]);
}
