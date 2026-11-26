/// Per-instance style for `Checkbox`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/icon/icon_stroke.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_size.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Checkbox` should render.
///
/// `CoreCheckboxStyle` carries chrome / dimensional overrides for the box
/// itself as flat fields — resting, active (checked / indeterminate) and
/// disabled colours, the hover / pressed state layer, the focus ring — plus
/// nested `CoreIconStyle` / `CoreTextStyle` / `CoreGapStyle` /
/// `CoreClickableStyle` references for the checkmark, label, gaps and the
/// composed `Clickable`.
///
/// **The semantic `size` lives on the widget, not on this style.** It
/// identifies the checkbox instance and is passed as a widget parameter;
/// this style holds only chrome / dimensional / nested-slot overrides on top
/// of whichever size the widget was instantiated with. Per-size defaults
/// live in [defaultsBySize] — both Flutter and Web read the same table so
/// the two platforms cannot silently diverge.
///
/// Hover / focus / pressed are not fields here and not widget props: each
/// platform's native engine detects them (`Clickable` callbacks on
/// Flutter, CSS pseudo-classes on Web) and reads the matching chrome from
/// [stateLayer] / [focusOutlineStyle] — the same shape `Chip` and `Button`
/// have.
///
/// ```text
/// design system default (flat defaults + defaultsBySize)
///   → CoreCheckboxTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.checkboxStyle                          // 인스턴스별
/// ```
@immutable
class CoreCheckboxStyle implements CoreStyle<CoreCheckboxStyle> {
  /// Creates a [CoreCheckboxStyle].
  const CoreCheckboxStyle({
    this.boxBackgroundColor,
    this.boxActiveColor,
    this.boxBorderColor,
    this.boxBorderWidth,
    this.boxBorderRadius,
    this.boxSize,
    this.checkmarkSize,
    this.indeterminateLength,
    this.indeterminateBorderRadius,
    this.markThickness,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledForegroundColor,
    this.disabledCheckmarkColor,
    this.stateLayer,
    this.stateLayerColor,
    this.stateLayerSpread,
    this.stateLayerBorderRadius,
    this.indicatorLabelGapStyle,
    this.transitionDuration,
    this.checkmarkIconStyle,
    this.clickableStyle,
    this.focusOutlineStyle,
    this.labelStyle,
    this.descriptionStyle,
    this.labelDescriptionGapStyle,
    this.minHeight,
  });

  // ─── Design-system defaults ────────────────────────────────────
  /// No floor — the row is as tall as its content, which is what it has
  /// always been. The design decision on press areas keeps the 24 floor
  /// and does not widen them by default; an app that owes a touch target
  /// (e.g. 48 × scaling) states it through [minHeight].
  static const double defaultMinHeight = CoreSpace.space0;

  // Both Flutter and Web read these constants — Flutter resolves via
  // `scheme.resolve(...).toValue()` / `.toValue(theme:)`, Web via the
  // `core_to_css.dart` adapter extensions.

  /// Default resting (unchecked) box fill — none. The resting box is an
  /// outline on the page, and the checked fill is what reads as the
  /// change; a tinted resting fill made the two states differ by a shade
  /// instead of by presence.
  static const CoreColor defaultBoxBackgroundColor = CoreColor.transparent;

  /// Default box fill when checked or indeterminate.
  static const CoreColor defaultBoxActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default resting (unchecked) box stroke — `outline`. The box edge is
  /// the control's only boundary, so it has to clear the 3:1 non-text
  /// floor against the surface (`outlineVariant` does not); the same value
  /// `RadioGroup` draws its resting ring with.
  static const CoreColor defaultBoxBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default box stroke width — [CoreStrokeWidth.stroke1] at every size.
  /// The unchecked frame reads through its colour (`outline`, which clears
  /// 3:1), not its weight: at 1.5 the resting box read heavier than the
  /// labels beside it. RadioGroup draws its resting ring with the same line.
  /// Size-invariant on purpose: the stroke is a line, not a
  /// dimension, and a stroke that thickened with the box read as a
  /// different control at `xl`.
  static const double defaultBoxBorderWidth = CoreStrokeWidth.stroke1;

  /// Default box corner — `radius4` at every size, for the same reason the
  /// stroke is size-invariant: the corner is the box's shape, and a corner
  /// that grew with the box turned the `xl2` square into a tile.
  static const CoreBorderRadius defaultBoxBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius4,
  );

  /// Default thickness of the indeterminate dash only — the same height at
  /// every size, `xs` included; the dash's *length* follows the size ladder
  /// ([defaultsBySize]).
  ///
  /// The checkmark is an ordinary icon and follows the icon stroke rule, not
  /// this value. The value is taken from the rule's floor
  /// ([CoreIconStroke.minRenderedWidth]), which every checkmark glyph on the
  /// ladder (8 – 16) sits on, so the check and the dash read at the same
  /// weight at every size and cannot drift apart. Stated here as the single
  /// source the token export ships to the canvas as `checkbox/mark-thickness`.
  /// Not a `CoreStrokeWidth` member: that scale steps in whole pixels and has
  /// no rung at 1.25.
  static const double defaultMarkThickness = CoreIconStroke.minRenderedWidth;

  /// Default corner of the indeterminate dash — a pill. The dash is a
  /// glyph and takes no corner from the box (a square inheriting the box's
  /// corner is the shape this replaces).
  static const CoreBorderRadius defaultIndeterminateBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default box fill when disabled — the dedicated disabled container
  /// token, at every checked value.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default box stroke when disabled.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default label / description foreground when disabled — one dedicated
  /// token for both lines, so a disabled row dims as a block.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default checkmark / dash colour when disabled. Its own field because
  /// the resting mark colour is `onPrimary`, which over the disabled
  /// container is white on grey — a disabled *checked* box used to paint
  /// its mark invisibly. The disabled ramp owns the mark like it owns the
  /// label.
  static const CoreColor defaultDisabledCheckmarkColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default checkmark / dash colour — the colour half of the
  /// [checkmarkIconStyle] slot. Size is deliberately absent: it comes from
  /// [defaultsBySize] and is merged first, so this partial only ever states
  /// the ink.
  static const CoreIconStyle defaultCheckmarkIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onPrimary),
  );

  /// How strongly the halo lays [stateLayerColor] around the box while
  /// hovered or pressed.
  ///
  /// `standard` — 8 % hover / 16 % pressed is the ramp the canvas states
  /// for every selection control (Checkbox · RadioGroup · Toggle ·
  /// MenuItem), so the four share one constant. Its focus rung is not
  /// painted here: a focused checkbox shows the ring
  /// ([clickableStyle]`.focusOutlineStyle`), not a wash.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.standard;

  /// Default halo ink — `onSurface` at every checked value, so the halo
  /// reads as the page reacting rather than as the box growing.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default halo reach beyond the box on each side — `4`, so the halo is
  /// the box plus 8 and shares the focus ring's outer edge.
  static const double defaultStateLayerSpread = CoreSpace.space4;

  /// Default halo corner — `radius8`, the box corner plus the spread, so
  /// the halo is concentric with the box and the same silhouette as the
  /// focus ring (not a circle).
  static const CoreBorderRadius defaultStateLayerBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default label slot text style — the single source for the label's
  /// typography role (`bodySmall`: 13 / 150 % / regular) + colour
  /// (`onSurface`), matched 1:1 with the [labelStyle] nested slot. The
  /// per-size `fontSize` layers on top from [defaultsBySize].
  ///
  /// A body role, not a label one: selection-control labels are copy the
  /// user reads at rest (400 / 150 %), unlike a Button's label which is a
  /// verb (500). `Chip` and `Button` keep the label family.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default description slot text style — the supporting line under the
  /// label. Same role as [defaultLabelStyle] with the quieter foreground
  /// (`onSurfaceVariant`); the two texts sit in one vertical `content`
  /// frame and are told apart by colour and by the size ladder in
  /// [defaultsBySize] (one step under the label), not by role.
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default gap between the label and the description beneath it —
  /// the `content` column's own spacing, distinct from
  /// [defaultIndicatorLabelGapStyle] which separates the row's slots.
  /// Two different axes, so two different fields: this one is vertical.
  static const CoreGapStyle defaultLabelDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default state-change transition duration (box colour + glyph slot
  /// scale / opacity, halo fade), as a [Duration] for the
  /// [transitionDuration] override slot.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default gap style between the checkbox indicator (box) and the label
  /// / prefix / suffix slot — the `md` rung of the ladder in
  /// [defaultsBySize], which is the fallback when a custom theme strips the
  /// per-size entry. The whole nested [CoreGapStyle] slot is forwarded to
  /// the `Gap` widget that separates the slots.
  static const CoreGapStyle defaultIndicatorLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — a partial with only the diverging override: the
  /// checkbox paints its own disabled state with dedicated tokens
  /// ([defaultDisabledBackgroundColor] / [defaultDisabledForegroundColor]),
  /// so the Clickable's generic disabled fade must stay off or the disabled
  /// chrome fades twice. Everything else stays null and resolves inside the
  /// Clickable's own resolver.
  ///
  /// The Clickable does not draw the focus ring here — the ring stands
  /// around the box, not the row — so its `focusOutlineStyle` half is
  /// inert for a checkbox; the ring reads [focusOutlineStyle] below.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default ring the checkbox draws around its box while focused — the
  /// system focus recipe (`CoreFocusRing`: a 2 px transparent gap + a 2 px
  /// `focusRing` ring), stated here as a complete partial the same
  /// way `CoreClickableStyle.defaultFocusOutlineStyle` states it, so the
  /// checkbox's own slot is the single place a caller retunes the ring.
  /// The corner is deliberately absent: both resolvers derive it from the
  /// box's own corner (plus the ring's offset) so the ring stays
  /// concentric with a rounder box.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
        ringOpacity: CoreFocusOutlineStyle.defaultRingOpacity,
      );

  /// Per-[CoreComponentSize] dimensional defaults — shared single source
  /// of truth for Flutter (raw doubles) and Web (which fans them out via
  /// the Tailwind adapters in `core_to_css.dart`). Resolvers read
  /// `CoreCheckboxStyle.defaultsBySize[size]!` and use the entries as
  /// fallback when the per-instance `CoreCheckboxStyle` slot is null.
  ///
  /// Only what actually moves with the size is here — the box, the two
  /// glyph lengths, the row gap and the two font sizes. The stroke width
  /// and the corner are size-invariant and live as flat defaults above; a
  /// generator that puts them on the size axis is what let the `xl` rows
  /// drift to a 2 px stroke and an 8 px corner twice.
  ///
  /// Box sizes follow CoUI_Size_Token_Specification §3-4 (Checkbox ·
  /// Radio, v1.1) — 12/14/16/18/20/24 with md=16 as the default. The
  /// checkmark is ~65 % of the box; the dash is the box less 4 at the
  /// small sizes and less 8 at `md`+ (the canvas's own lengths). The gap
  /// ladder is `RadioGroup`'s (6/8/8/8/10/12) and the label ladder is
  /// `Button`'s (12/13/14/16/16/16), with the description under the label
  /// (11/12/13/14/14/14) — never larger than its label.
  static const Map<CoreComponentSize, CoreCheckboxStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreCheckboxStyle(
      boxSize: CoreSize.size12,
      checkmarkSize: CoreSize.size8,
      indeterminateLength: CoreSize.size6,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s11),
    ),
    CoreComponentSize.sm: CoreCheckboxStyle(
      boxSize: CoreSize.size14,
      checkmarkSize: CoreSize.size10,
      indeterminateLength: CoreSize.size6,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s13),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
    ),
    CoreComponentSize.md: CoreCheckboxStyle(
      boxSize: CoreSize.size16,
      checkmarkSize: CoreSize.size10,
      indeterminateLength: CoreSize.size8,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s13),
    ),
    CoreComponentSize.lg: CoreCheckboxStyle(
      boxSize: CoreSize.size18,
      checkmarkSize: CoreSize.size12,
      indeterminateLength: CoreSize.size8,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
    ),
    CoreComponentSize.xl: CoreCheckboxStyle(
      boxSize: CoreSize.size20,
      checkmarkSize: CoreSize.size14,
      indeterminateLength: CoreSize.size10,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space10),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
    ),
    CoreComponentSize.xl2: CoreCheckboxStyle(
      boxSize: CoreSize.size24,
      checkmarkSize: CoreSize.size16,
      indeterminateLength: CoreSize.size12,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
    ),
  };

  // ── Box chrome (flat) ────────────────────────

  /// Resting (unchecked) box fill colour override. `null` defers to
  /// [defaultBoxBackgroundColor].
  final CoreColor? boxBackgroundColor;

  /// Box fill colour when checked or indeterminate — the border takes the
  /// same colour, so the stroke blends into the fill. `null` defers to
  /// [defaultBoxActiveColor].
  final CoreColor? boxActiveColor;

  /// Resting (unchecked) box stroke colour override. `null` defers to
  /// [defaultBoxBorderColor].
  final CoreColor? boxBorderColor;

  /// Box stroke width override (logical px, pre-scaling). `null` defers to
  /// [defaultBoxBorderWidth].
  final double? boxBorderWidth;

  /// Box corner override. `null` defers to [defaultBoxBorderRadius]. The
  /// focus ring's corner derives from this one (plus its own offset), so
  /// the ring stays concentric with a rounder box.
  final CoreBorderRadius? boxBorderRadius;

  /// Box size (width = height) override (logical px). `null` defers to
  /// [defaultsBySize] for the widget's size.
  final double? boxSize;

  /// Checkmark glyph icon size override (logical px). `null` falls back
  /// to [defaultsBySize] for the widget's size, unless
  /// `checkmarkIconStyle.size` sets one.
  final double? checkmarkSize;

  /// Indeterminate dash *length* override (logical px) — the dash is a
  /// horizontal pill [markThickness] tall. `null` falls back to
  /// [defaultsBySize] for the widget's size.
  final double? indeterminateLength;

  /// Corner of the indeterminate dash. `null` →
  /// [defaultIndeterminateBorderRadius] (a pill).
  final CoreBorderRadius? indeterminateBorderRadius;

  /// Thickness of the indeterminate dash — one constant across sizes. The
  /// checkmark is an icon and follows the icon stroke rule, not this value.
  /// `null` defers to [defaultMarkThickness].
  final double? markThickness;

  // ── Disabled ───────────────────────────────

  /// Box fill when disabled. `null` → [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Box stroke when disabled. `null` → [defaultDisabledBorderColor].
  final CoreColor? disabledBorderColor;

  /// Label and description foreground when disabled. `null` →
  /// [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Checkmark / dash colour when disabled. `null` →
  /// [defaultDisabledCheckmarkColor].
  final CoreColor? disabledCheckmarkColor;

  // ── State layer (hover / pressed halo) ─────

  /// Ramp the halo is painted at while hovered or pressed. `null` →
  /// [defaultStateLayer]. The focus rung is unused — focus draws the ring.
  final CoreStateLayer? stateLayer;

  /// Halo ink. `null` → [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// How far the halo reaches beyond the box on each side (logical px,
  /// pre-scaling). `null` → [defaultStateLayerSpread].
  final double? stateLayerSpread;

  /// Halo corner. `null` → [defaultStateLayerBorderRadius].
  final CoreBorderRadius? stateLayerBorderRadius;

  // ── Layout / motion ─────────────────────────

  /// Gap between the checkbox box and the label / prefix / suffix slot,
  /// passed to the `Gap` between them as is. `null` defers to
  /// [defaultsBySize] for the widget's size, then to
  /// [defaultIndicatorLabelGapStyle].
  final CoreGapStyle? indicatorLabelGapStyle;

  /// State-change transition duration override (box colour fade + glyph
  /// slot scale / opacity + halo fade). `null` defers to
  /// [defaultTransitionDuration].
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Checkmark icon style override (size / colour). Merged on top of
  /// `CoreIconStyle(size: checkmarkSize)` and [defaultCheckmarkIconStyle],
  /// so a colour-only override keeps the size-ladder glyph and a size-only
  /// override keeps the `onPrimary` ink.
  final CoreIconStyle? checkmarkIconStyle;

  /// Style for the checkbox's `Clickable` — press scale, durations,
  /// disabled opacity. Laid over [defaultClickableStyle] and passed to the
  /// `Clickable` as is, which fills what is left unset with its own
  /// defaults. Its `focusOutlineStyle` has no effect here — see
  /// [focusOutlineStyle].
  final CoreClickableStyle? clickableStyle;

  /// Focus ring the checkbox draws around its box while focused. Laid
  /// over [defaultFocusOutlineStyle]; the corner comes from the box.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Label text style override.
  final CoreTextStyle? labelStyle;

  /// Description text style override — the supporting line under the
  /// label. `null` defers to [defaultsBySize] for the widget's size
  /// (which carries only the `fontSize` step), then to
  /// [defaultDescriptionStyle] for the role and colour.
  final CoreTextStyle? descriptionStyle;

  /// Vertical gap between the label and the description below it. `null`
  /// defers to [defaultLabelDescriptionGapStyle].
  final CoreGapStyle? labelDescriptionGapStyle;

  /// Minimum height of the pressable row — box, label and description
  /// together — before scaling. The row keeps its cross-axis alignment
  /// in the extra height and stays the press area as a whole, so a theme
  /// can give every checkbox a touch target (for example
  /// `CoreA11ySize.touchTarget`). Falls back to [defaultMinHeight].
  final double? minHeight;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively so partial overrides only touch the fields
  /// they specify.
  @override
  CoreCheckboxStyle merge(CoreCheckboxStyle? other) {
    if (other == null) return this;
    return CoreCheckboxStyle(
      boxBackgroundColor: other.boxBackgroundColor ?? boxBackgroundColor,
      boxActiveColor: other.boxActiveColor ?? boxActiveColor,
      boxBorderColor: other.boxBorderColor ?? boxBorderColor,
      boxBorderWidth: other.boxBorderWidth ?? boxBorderWidth,
      boxBorderRadius: other.boxBorderRadius ?? boxBorderRadius,
      boxSize: other.boxSize ?? boxSize,
      checkmarkSize: other.checkmarkSize ?? checkmarkSize,
      indeterminateLength: other.indeterminateLength ?? indeterminateLength,
      indeterminateBorderRadius:
          other.indeterminateBorderRadius ?? indeterminateBorderRadius,
      markThickness: other.markThickness ?? markThickness,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      disabledCheckmarkColor:
          other.disabledCheckmarkColor ?? disabledCheckmarkColor,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      stateLayerSpread: other.stateLayerSpread ?? stateLayerSpread,
      stateLayerBorderRadius:
          other.stateLayerBorderRadius ?? stateLayerBorderRadius,
      indicatorLabelGapStyle: _mergeGap(
        indicatorLabelGapStyle,
        other.indicatorLabelGapStyle,
      ),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      checkmarkIconStyle: _mergeIcon(
        checkmarkIconStyle,
        other.checkmarkIconStyle,
      ),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(
        descriptionStyle,
        other.descriptionStyle,
      ),
      labelDescriptionGapStyle: _mergeGap(
        labelDescriptionGapStyle,
        other.labelDescriptionGapStyle,
      ),
      minHeight: other.minHeight ?? minHeight,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCheckboxStyle copyWith({
    CoreColor? boxBackgroundColor,
    CoreColor? boxActiveColor,
    CoreColor? boxBorderColor,
    double? boxBorderWidth,
    CoreBorderRadius? boxBorderRadius,
    double? boxSize,
    double? checkmarkSize,
    double? indeterminateLength,
    CoreBorderRadius? indeterminateBorderRadius,
    double? markThickness,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    CoreColor? disabledForegroundColor,
    CoreColor? disabledCheckmarkColor,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    double? stateLayerSpread,
    CoreBorderRadius? stateLayerBorderRadius,
    CoreGapStyle? indicatorLabelGapStyle,
    Duration? transitionDuration,
    CoreIconStyle? checkmarkIconStyle,
    CoreClickableStyle? clickableStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreGapStyle? labelDescriptionGapStyle,
    double? minHeight,
  }) {
    return CoreCheckboxStyle(
      boxBackgroundColor: boxBackgroundColor ?? this.boxBackgroundColor,
      boxActiveColor: boxActiveColor ?? this.boxActiveColor,
      boxBorderColor: boxBorderColor ?? this.boxBorderColor,
      boxBorderWidth: boxBorderWidth ?? this.boxBorderWidth,
      boxBorderRadius: boxBorderRadius ?? this.boxBorderRadius,
      boxSize: boxSize ?? this.boxSize,
      checkmarkSize: checkmarkSize ?? this.checkmarkSize,
      indeterminateLength: indeterminateLength ?? this.indeterminateLength,
      indeterminateBorderRadius:
          indeterminateBorderRadius ?? this.indeterminateBorderRadius,
      markThickness: markThickness ?? this.markThickness,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      disabledCheckmarkColor:
          disabledCheckmarkColor ?? this.disabledCheckmarkColor,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      stateLayerSpread: stateLayerSpread ?? this.stateLayerSpread,
      stateLayerBorderRadius:
          stateLayerBorderRadius ?? this.stateLayerBorderRadius,
      indicatorLabelGapStyle:
          indicatorLabelGapStyle ?? this.indicatorLabelGapStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      checkmarkIconStyle: checkmarkIconStyle ?? this.checkmarkIconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      labelDescriptionGapStyle:
          labelDescriptionGapStyle ?? this.labelDescriptionGapStyle,
      minHeight: minHeight ?? this.minHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCheckboxStyle &&
          runtimeType == other.runtimeType &&
          boxBackgroundColor == other.boxBackgroundColor &&
          boxActiveColor == other.boxActiveColor &&
          boxBorderColor == other.boxBorderColor &&
          boxBorderWidth == other.boxBorderWidth &&
          boxBorderRadius == other.boxBorderRadius &&
          boxSize == other.boxSize &&
          checkmarkSize == other.checkmarkSize &&
          indeterminateLength == other.indeterminateLength &&
          indeterminateBorderRadius == other.indeterminateBorderRadius &&
          markThickness == other.markThickness &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          disabledCheckmarkColor == other.disabledCheckmarkColor &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          stateLayerSpread == other.stateLayerSpread &&
          stateLayerBorderRadius == other.stateLayerBorderRadius &&
          indicatorLabelGapStyle == other.indicatorLabelGapStyle &&
          transitionDuration == other.transitionDuration &&
          checkmarkIconStyle == other.checkmarkIconStyle &&
          clickableStyle == other.clickableStyle &&
          focusOutlineStyle == other.focusOutlineStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          labelDescriptionGapStyle == other.labelDescriptionGapStyle &&
          minHeight == other.minHeight;

  @override
  int get hashCode => Object.hashAll([
    boxBackgroundColor,
    boxActiveColor,
    boxBorderColor,
    boxBorderWidth,
    boxBorderRadius,
    boxSize,
    checkmarkSize,
    indeterminateLength,
    indeterminateBorderRadius,
    markThickness,
    disabledBackgroundColor,
    disabledBorderColor,
    disabledForegroundColor,
    disabledCheckmarkColor,
    stateLayer,
    stateLayerColor,
    stateLayerSpread,
    stateLayerBorderRadius,
    indicatorLabelGapStyle,
    transitionDuration,
    checkmarkIconStyle,
    clickableStyle,
    focusOutlineStyle,
    labelStyle,
    descriptionStyle,
    labelDescriptionGapStyle,
    minHeight,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
