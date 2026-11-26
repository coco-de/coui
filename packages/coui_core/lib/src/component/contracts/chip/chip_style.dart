/// Per-instance style for `Chip`.
library;

import 'package:coui_core/src/color/color_contrast.dart';
import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/cast_motion.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/chip/chip_shape.dart';
import 'package:coui_core/src/component/contracts/chip/chip_size.dart';
import 'package:coui_core/src/component/contracts/chip/chip_variant.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_color.dart';
import 'package:coui_core/src/component/contracts/frame/core_main_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_emphasis.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart' show CoreRadius;
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Chip` should render.
///
/// `CoreChipStyle` carries panel chrome / dimensional flat
/// fields plus nested label / leading-icon / trailing-icon /
/// close-button / clickable slot styles.
///
/// **Semantic enums (`chipColor` / `variant` / `emphasis` / `size` /
/// `shape` / `selected`) live on the widget, not on this style**. To change
/// what a chip looks like pass them as widget parameters; this style only
/// describes chrome micro-tweaks.
///
/// To change the **close button's variant** (e.g. ghost vs primary)
/// inject the widget directly via
/// `Chip(closeButton: Button(variant: ghost, ...))` rather than
/// packing variant into [closeButtonStyle]. [closeButtonStyle] is
/// for chrome-level tweaks.
///
/// ```text
/// defaultsBySize[size] → defaultsByShape[shape]  // design system default
///   → CoreChipTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.chipStyle                          // 인스턴스별
/// ```
@immutable
class CoreChipStyle implements CoreStyle<CoreChipStyle> {
  /// Creates a [CoreChipStyle].
  const CoreChipStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.contentAlignment,
    this.iconLabelGapStyle,
    this.closeIconStyle,
    this.transitionDuration,
    this.castHideDuration,
    this.castMotion,
    this.labelStyle,
    this.prefixLabelStyle,
    this.leadingIconStyle,
    this.trailingIconStyle,
    this.closeButtonStyle,
    this.clickableStyle,
    this.customDisabledBackgroundColor,
    this.customDisabledUnselectedBackgroundColor,
    this.customDisabledForegroundColor,
    this.customDisabledBorderColor,
    this.customSelectedForegroundColor,
    this.lowUnselectedForegroundColor,
    this.lowUnselectedBorderColor,
    this.filledUnselectedBackgroundColor,
    this.disabledSelectedBorderColor,
    this.customLowSelectedBackgroundColor,
    this.customLowSelectedForegroundColor,
    this.stateLayer,
  });

  // ── Design-system defaults (Phase 6f / Tokens 폐기) ────────────

  /// A size-independent chip corner (a pill, 9999), retired: the
  /// design-system corner is the size row's [borderRadius]
  /// (`defaultsBySize[size].borderRadius` — 6 · 8 · 10, the chip's own
  /// height ladder 28 · 32 · 40 × 0.25 snapped onto a `CoreRadius` rung).
  /// Both resolvers read the row, so a chip that states no corner of its
  /// own takes the corner of its size. A pill is a shape, not this value:
  /// `CoreChipShape.pill`, whose corner [defaultsByShape] states.
  @Deprecated(
    'Per-size now: read defaultsBySize[size].borderRadius instead (since '
    '0.162) — the chip corner is the height of the size × 0.25, so one '
    'value cannot answer for every size. A pill is a shape: '
    'Chip(shape: CoreChipShape.pill).',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default border stroke width (1px) for unselected chips.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default for [castMotion] — what the cast does when engaged.
  static const CoreCastMotion defaultCastMotion = .defaultMotion;

  /// Default label slot text style — the label role the size ladder
  /// starts from, matched 1:1 with the [labelStyle] nested slot. Each
  /// size row in [defaultsBySize] states its own label ROLE
  /// (`labelSmall` / `labelMedium` / `labelLarge` — 12 / 13 / 14), so this
  /// default is the row a caller who bypasses the ladder lands on — the
  /// default size's (`md`) row — not a base the rows overlay a bare
  /// `fontSize` onto. A size that states a role rather than a scalar keeps
  /// the role's own letter-spacing and line height, which a `fontSize`
  /// overlay on this role could not carry.
  ///
  /// The weight is the label role's own 500, as on the `Button` the chip
  /// sits beside — no row states a weight over its role. Selection is
  /// carried by the fill, and one weight in every state means a selection
  /// never reflows a row of chips.
  ///
  /// Colour is intentionally omitted — the chip's label colour is fully
  /// state-resolved (selected / unselected / disabled) by each platform's
  /// resolver.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
  );

  /// Default key text style — the role the key ladder starts from, matched
  /// 1:1 with the [prefixLabelStyle] nested slot, and the default size's
  /// (`md`) row: `labelSmall`, one role below that row's label.
  ///
  /// One step down from the label on every row (`labelXs` / `labelSmall` /
  /// `labelMedium` against the label's `labelSmall` / `labelMedium` /
  /// `labelLarge`), at the role's own 500 like the label: the key names
  /// what is filtered and the value is what the reader came for, so the key
  /// is the smaller half of the pair. Stated as roles, so the key takes each
  /// role's own tracking and line height.
  ///
  /// Colour is omitted for the same reason as [defaultLabelStyle] — each
  /// platform's resolver picks it by state
  /// ([CoreChipColorStyle.unselectedPrefixFg] at rest, the label's colour
  /// once selected or disabled).
  static const CoreTextStyle defaultPrefixLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
  );

  /// Disabled chrome comes from dedicated tokens
  /// ([CoreColors.disabledContainer] / [CoreColors.disabledOutline], with
  /// the label one step down at [CoreColors.onSurfaceVariant]), so nothing
  /// is dimmed on top of them — an opacity multiplier over an
  /// already-chosen colour is what makes the resulting contrast depend on
  /// the surface underneath.
  static const double defaultDisabledOpacity = CoreOpacity.opacity100;

  /// How strongly a chip lays its own foreground over its fill while
  /// hovered, focused or pressed.
  ///
  /// `subtle` — chips sit on light surfaces, and it is the tier the
  /// library canvas paints on them.
  ///
  /// This component is the reason the perceptibility check exists. It
  /// shipped a primary/selected hover and pressed that both landed on
  /// `on-surface` at an alpha that happened to equal the resting fill's
  /// own tone: the states measured 1.00 against rest — the literal
  /// absence of a state — and reading either one alone could not see it.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// Default neutral foreground raw ARGB value (legacy `Chip`
  /// fallback for `CoreChipColor.neutral`). Kept as `int` since
  /// the legacy resolver constructs `Color(value)` directly.
  static const int defaultNeutralFgValue = 0xFF374151;

  /// Default transition duration for hover / focus / state colour
  /// changes — emitted as an inline `transition` rule on Web and used
  /// by the `AnimatedContainer` on Flutter.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default for [castHideDuration] — the engage-squash pair's shared
  /// clock (the shadow hide and the travel move together, #4407),
  /// deliberately not [defaultTransitionDuration] — that one is the
  /// hover/selected speed, and hiding a shadow on it would lag the
  /// travel.
  static const Duration defaultCastHideDuration = Duration(
    milliseconds: CoreDuration.ms50,
  );

  /// Default nested [CoreClickableStyle] slot for the `Clickable` the
  /// widgets compose around a tappable (`onTap != null`) chip — a
  /// partial carrying only the diverging override: the Clickable's generic
  /// disabled fade stays off because the chip paints its own disabled
  /// state with dedicated tokens (`disabledBg` / `disabledFg` /
  /// `disabledBorderColor`) — otherwise the disabled chrome fades
  /// twice. Everything else stays null and resolves inside the
  /// Clickable's own resolver.
  ///
  /// No `borderRadius` here: the focus ring follows the chip's own corner,
  /// which is the size row's ([borderRadius]) and so differs per size. Both
  /// resolvers put the corner they draw the face with into this slot ahead
  /// of the caller's `clickableStyle`, so a corner the caller states on the
  /// chip moves the ring with it and a `clickableStyle.borderRadius` still
  /// wins over both.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default nested [CoreButtonStyle] slot for the close (`×`) affordance
  /// — a partial carrying only what diverges from `Button`'s own defaults
  /// and does not vary with the chip's size: the button sits flush inside
  /// the chip, so it keeps no padding of its own. The size-dependent half
  /// (`height` / `width`, and the corner on the row where `Button`'s own
  /// would be rounder than the chip's) stays in [defaultsBySize] and merges
  /// on top of this base; everything else resolves inside `Button`'s own
  /// resolver.
  ///
  /// The focus ring's gap band is on: the button sits inside the chip, so
  /// the colour next to its ring is the chip's own fill — which changes
  /// with the chip's colour and emphasis — not the page. The two-colour
  /// band (`CoreFocusRing.opaqueOffsetColor`) keeps the ring legible on
  /// every fill. `ChipInput` chips inherit it through this slot.
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    padding: .zero,
    focusOutlineStyle: CoreFocusOutlineStyle(
      offsetColor: CoreFocusRing.opaqueOffsetColor,
    ),
  );

  /// Default background fill for a **disabled custom-seed** chip — the
  /// `custom` colour variant has no per-variant table entry (its colours
  /// derive from `seedColor`), so the disabled fallback routes through
  /// this named default instead of a raw `cs.surfaceContainer`
  /// (layer-mapping.md "모든 디자인 값은 Core Style 단일 출처"). Matches
  /// the per-variant `disabledBg` token.
  static const CoreColor defaultCustomDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default foreground for a disabled custom-seed chip — matches the
  /// per-variant `disabledFg` token.
  ///
  /// These three said they matched the per-variant table and did not: they
  /// named surface tones, and `surfaceContainerHigh` on `surfaceContainer`
  /// is two adjacent steps of the same ramp — 1.15:1 light, 1.29:1 dark.
  /// A disabled label is exempt from the contrast floor, but exempt is not
  /// the same as legible, and a chip whose label has vanished does not
  /// read as disabled. It reads as broken.
  static const CoreColor defaultCustomDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default border colour for a disabled custom-seed chip — matches the
  /// per-variant `disabledBorderColor` token.
  static const CoreColor defaultCustomDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// The light label end for a selected **custom-seed** chip — what
  /// [defaultCustomSelectedForegroundColorFor] gives a seed the scheme does
  /// not pair with an on-colour, when white is the end that reads on it. A
  /// seed the scheme does pair takes that on-colour instead.
  ///
  /// A raw (non-token) [CoreColor] so it passes through `scheme.resolve`
  /// unchanged on Flutter and emits inline on Web.
  static const CoreColor defaultCustomSelectedForegroundColor = CoreColor(
    0xFFFFFFFF,
  );

  /// The dark label end for a selected **custom-seed** chip — what
  /// [defaultCustomSelectedForegroundColorFor] gives a raw seed light enough
  /// that black reads on it better than white
  /// ([defaultCustomSelectedForegroundColor]). Raw, like its light
  /// counterpart, for the same reason.
  static const CoreColor defaultCustomSelectedDarkForegroundColor = CoreColor(
    0xFF000000,
  );

  /// Label colour for a selected **custom-seed** chip at
  /// [CoreChipEmphasis.high], filled with [fill] — the fill's own
  /// on-colour (designer decision 2026-10-08), resolved here once so the
  /// two platforms cannot answer differently.
  ///
  /// - A seed the scheme pairs with an on-colour
  ///   ([CoreColors.onColorOf]) — `tertiary`, `success`, a container, a
  ///   surface tone — gets that on-colour as a token, so the label moves
  ///   with the mode, high contrast and a brand's mapping exactly as the
  ///   fill does.
  /// - A raw seed gets whichever of [defaultCustomSelectedForegroundColor]
  ///   (white) and [defaultCustomSelectedDarkForegroundColor] (black)
  ///   contrasts more with it, measured on its own channels. A raw colour is
  ///   the same colour in every mode, so the label that reads on it is too —
  ///   which is what lets the Web decide it without a resolved scheme (it
  ///   has none at build time: its scheme is CSS variables the browser
  ///   resolves, and switching modes does not rebuild). The seed's alpha is
  ///   left out of the measurement; the label is read against the hue.
  /// - A token the scheme does not pair — an ink or stroke tone used as a
  ///   fill — keeps [defaultCustomSelectedForegroundColor]. Its contrast
  ///   cannot be measured without a resolved scheme, which the Web does not
  ///   have; a caller filling with one states the label through
  ///   [customSelectedForegroundColor].
  static CoreColor defaultCustomSelectedForegroundColorFor(CoreColor fill) {
    final token = fill.token;
    if (token != null) {
      final on = CoreColors.onColorOf(token);

      return on == null
          ? defaultCustomSelectedForegroundColor
          : CoreColor.token(on);
    }
    final opaque = CoreColor.fromARGB(
      CoreColorConversion.alphaMax,
      fill.red,
      fill.green,
      fill.blue,
    );

    // A tie goes to white.
    return CoreContrast.ratio(
              defaultCustomSelectedDarkForegroundColor,
              opaque,
            ) >
            CoreContrast.ratio(defaultCustomSelectedForegroundColor, opaque)
        ? defaultCustomSelectedDarkForegroundColor
        : defaultCustomSelectedForegroundColor;
  }

  /// Border colour for an **unselected** chip at [CoreChipEmphasis.low].
  ///
  /// Colour-independent: a resting low chip states no colour at all (the
  /// label is the neutral `onSurfaceVariant` on every row), and the
  /// hairline is the quiet `outlineVariant` — a chip's label names it, so
  /// the stroke does not have to carry the contrast a bare control's does.
  static const CoreColor defaultLowUnselectedBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Fill of an **unselected, enabled** chip at [CoreChipVariant.filled] —
  /// `surfaceContainerHigh`, one step above [CoreColors.surfaceContainer].
  ///
  /// The step above rather than `surfaceContainer` because the lighter tone
  /// sits barely off a white page (about 1.09:1) and the chip would not read
  /// as a shape; the label names the chip, so the fill carries no contrast
  /// floor of its own, only enough presence to be seen.
  ///
  /// Colour-independent and emphasis-independent: a resting chip states no
  /// colour, so the fill is one grey for every [CoreChipColor] (the custom
  /// seed included). The border mirrors it — the way a selected chip's
  /// border mirrors its own fill — so the chip reads as one grey shape with
  /// no outline.
  static const CoreColor defaultFilledUnselectedBackgroundColor =
      CoreColor.token(CoreColors.surfaceContainerHigh);

  /// Border of a **selected disabled** chip — none.
  ///
  /// The designer's canvas draws the selected disabled chip as a filled
  /// shape with no stroke at all, while the unselected disabled chip keeps
  /// its `disabledOutline` hairline. Stating the fill colour as the border
  /// (what the enabled selected rows do) is not the same thing: Figma
  /// records a stroke property either way, and a stroke whose colour equals
  /// the fill still reads as "has a border" to anything that compares
  /// nodes rather than pixels. Shared across colours because disabled
  /// discards the colour entirely — the custom-seed branch reads it too.
  ///
  /// The transparent sentinel is what both platforms already treat as
  /// "no border": their outlined-container rule collapses a transparent
  /// border's width to 0 so it stays out of layout, and the Figma builder
  /// draws no stroke for an alpha-0 colour.
  static const CoreColor defaultDisabledSelectedBorderColor =
      CoreColor.transparent;

  /// Background of an **unselected disabled** chip — the page surface, so a
  /// disabled chip that was never selected reads as an outline that lost
  /// its ink rather than as a filled chip. The selected disabled chip keeps
  /// [CoreColors.disabledContainer] ([CoreChipColorStyle.disabledSelectedBg])
  /// so the selection survives the greying — the hole the old single
  /// `disabledBg` had, where a selected disabled chip fell back to the
  /// unselected look. Shared across colours because disabled discards the
  /// colour entirely; the custom-seed branch reads it directly.
  static const CoreColor defaultCustomDisabledUnselectedBackgroundColor =
      CoreColor.token(CoreColors.surface);

  /// Background fill for a **selected custom-seed** chip at
  /// [CoreChipEmphasis.low].
  ///
  /// The other colours derive their low-emphasis fill from their own
  /// `{color}Container` token, but a raw `seedColor` has no container to
  /// derive — producing one would be tonal-palette maths, and a second
  /// derivation path is exactly what diverges from the first. So a custom
  /// chip at low emphasis reads as a quiet neutral one unless the caller
  /// supplies its own tint here, which is the same escape hatch
  /// [customSelectedForegroundColor] already provides for the loud
  /// register.
  static const CoreColor defaultCustomLowSelectedBackgroundColor =
      CoreColor.token(CoreColors.surfaceContainer);

  /// Label colour for a **selected custom-seed** chip at
  /// [CoreChipEmphasis.low]. See
  /// [defaultCustomLowSelectedBackgroundColor].
  static const CoreColor defaultCustomLowSelectedForegroundColor =
      CoreColor.token(CoreColors.onSurface);

  /// Main-axis placement of the content row inside a chip wider than its
  /// content — centred, so a fixed-width chip does not read as weighted
  /// to its leading edge. See [contentAlignment].
  static const CoreMainAxisAlignment defaultContentAlignment = .center;

  /// Per-size default chrome — single source of truth shared by
  /// Flutter and Web.
  ///
  /// The map value is `CoreChipStyle` itself so the flat slot fields
  /// stay 1:1 with the per-size defaults — no separate typedef record
  /// holder (contract.md "defaultsBySize 값은 CoreXxxStyle 자체").
  ///
  /// Flutter consumes the raw `double` values directly (logical px);
  /// Web converts spacing to inline CSS via `rem` — both platforms
  /// read the same [CoreChipStyle] entries.
  ///
  /// Icon sizes are 12 / 14 / 14 for the leading and trailing slots — `md`
  /// and `lg` share the 14 step, and the 40px chip's glyph does not grow
  /// with its face. The close glyph is 12 / 14 / 16 inside its 16 / 18 / 20
  /// button — sized below the label so the remove affordance does not read
  /// larger than the text it removes.
  ///
  /// The corner is the chip's own height × 0.25, on its own ladder
  /// (28 · 32 · 40 — [CoreChipSize]), each a `CoreRadius` rung: md 8 and lg
  /// 10 are exactly the ratio, and sm's 28 × 0.25 = 7 is not a rung, so it
  /// snaps down to 6. The corner is stated on the row rather than computed
  /// (a resolver would invent a design value), and both resolvers read it
  /// through `merged.borderRadius`, so a caller's own corner still wins.
  ///
  /// The spec's height ladder (28/32/40) is stated as
  /// `minHeight`, not reached through padding: the label line is 140%,
  /// so padding + label alone lands under the ladder, and a
  /// chip beside a control of the same size tier has to match that
  /// control's height, not its own text. Vertical padding is the 2px the
  /// canvas states on every tier; it only matters when the
  /// content is taller than the floor.
  ///
  /// The close button sits inside the chip, so on a row where its own
  /// size's corner (`Button` `sm`, 8) would be rounder than the chip's it
  /// states the chip's corner instead — an inner face is never rounder than
  /// the face around it. Only `sm` (6) is in that position; `md` equals the
  /// button's 8 and `lg` is rounder than it.
  static final Map<CoreChipSize, CoreChipStyle> defaultsBySize = {
    CoreChipSize.sm: const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space10,
        vertical: CoreSpace.space2,
      ),
      minHeight: CoreSize.size28,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      closeIconStyle: CoreIconStyle(size: CoreIconSize.size12),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      prefixLabelStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size12),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size12),
      closeButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
        height: CoreSize.size16,
        width: CoreSize.size16,
      ),
    ),
    CoreChipSize.md: const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space2,
      ),
      minHeight: CoreSize.size32,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      closeIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      prefixLabelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      closeButtonStyle: CoreButtonStyle(
        height: CoreSize.size18,
        width: CoreSize.size18,
      ),
    ),
    CoreChipSize.lg: const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space14,
        vertical: CoreSpace.space2,
      ),
      minHeight: CoreSize.size40,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      closeIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
      prefixLabelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      closeButtonStyle: CoreButtonStyle(
        height: CoreSize.size20,
        width: CoreSize.size20,
      ),
    ),
  };

  /// What each [CoreChipShape] changes on top of its size row in
  /// [defaultsBySize] — single source of truth shared by Flutter and Web.
  ///
  /// Merged over the size row, so a field a shape leaves null keeps the
  /// row's value:
  ///
  /// - [CoreChipShape.rounded] states nothing and keeps the row's corner
  ///   (6 · 8 · 10).
  /// - [CoreChipShape.pill] states the full corner. On every size the
  ///   renderer clamps it to half the drawn height, so both ends are a half
  ///   circle — 28 · 32 · 40 tall, 14 · 16 · 20 round — and a chip that grows
  ///   past its floor stays a pill. The half-height is never computed by a
  ///   resolver, and the corner is the ladder's own full rung rather than a
  ///   new value.
  ///
  /// The close button keeps the corner its size row states: a pill is
  /// rounder than any of them, so none is rounder than the face around it.
  ///
  /// A corner stated on the theme or the instance (`borderRadius`) wins over
  /// both rows, so a project that sets `CoreChipTheme.style.borderRadius`
  /// draws every shape with that corner.
  static const Map<CoreChipShape, CoreChipStyle> defaultsByShape = {
    CoreChipShape.rounded: CoreChipStyle(),
    CoreChipShape.pill: CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  };

  /// Per-chip-color default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  ///
  /// Keyed by [CoreChipColor], not by [CoreChipVariant]: a row states the
  /// colour a chip *takes on when selected*. The unselected columns
  /// (`unselectedBg` / `unselectedFg` / `unselectedPrefixFg` / `borderColor` /
  /// `lowUnselectedFg`) are the same in every row — a resting chip is
  /// colourless — and are kept per row only so a reader finds a chip's whole
  /// palette in one place; a test pins that they agree. How an unselected
  /// chip is *drawn* (outlined or filled) is [CoreChipVariant], whose one
  /// fill lives in [defaultFilledUnselectedBackgroundColor].
  ///
  /// `CoreChipColor.custom` is excluded — its selected colours derive from
  /// the caller-supplied `seedColor` at use-site, and an enabled unselected
  /// custom chip wears the neutral row.
  // custom derives from seedColor
  static const Map<CoreChipColor, CoreChipColorStyle> defaultsByColor = {
    CoreChipColor.neutral: CoreChipColorStyle(
      lowUnselectedFg: CoreColor.token(CoreColors.onSurfaceVariant),
      disabledSelectedBg: CoreColor.token(CoreColors.disabledContainer),
      selectedBg: CoreColor.token(CoreColors.inverseSurface),
      selectedFg: CoreColor.token(CoreColors.inverseOnSurface),
      lowSelectedBg: CoreColor.token(CoreColors.surfaceContainerHighest),
      lowSelectedFg: CoreColor.token(CoreColors.onSurface),
      unselectedBg: .transparent,
      unselectedFg: CoreColor.token(CoreColors.onSurface),
      unselectedPrefixFg: CoreColor.token(CoreColors.onSurfaceVariant),
      borderColor: CoreColor.token(CoreColors.outlineVariant),
      disabledBg: CoreColor.token(CoreColors.surface),
      disabledFg: CoreColor.token(CoreColors.disabledContent),
      disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
    ),
    CoreChipColor.primary: CoreChipColorStyle(
      lowUnselectedFg: CoreColor.token(CoreColors.onSurfaceVariant),
      disabledSelectedBg: CoreColor.token(CoreColors.disabledContainer),
      selectedBg: CoreColor.token(CoreColors.primary),
      selectedFg: CoreColor.token(CoreColors.onPrimary),
      lowSelectedBg: CoreColor.token(CoreColors.primaryContainer),
      lowSelectedFg: CoreColor.token(CoreColors.onPrimaryContainer),
      unselectedBg: .transparent,
      unselectedFg: CoreColor.token(CoreColors.onSurface),
      unselectedPrefixFg: CoreColor.token(CoreColors.onSurfaceVariant),
      borderColor: CoreColor.token(CoreColors.outlineVariant),
      disabledBg: CoreColor.token(CoreColors.surface),
      disabledFg: CoreColor.token(CoreColors.disabledContent),
      disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  // Neither colour below has a `default*`, and neither can have one —
  // there is no single value to put there. Both resolvers pick a base
  // from [defaultsByColor] keyed on *state* before the override is
  // consulted:
  //
  //     selected  → variantStyle.selectedBg   / selectedFg
  //     enabled   → variantStyle.unselectedBg / unselectedFg
  //     disabled  → variantStyle.disabledBg   / disabledFg
  //     custom    → the caller's `seedColor`
  //
  // so the baseline for these two fields already lives in the table
  // under state-specific names — one row per [CoreChipColor], not one
  // value. The flat slot is the escape hatch that
  // wins across *every* state, and both platforms implement that by
  // asking whether it is absent: Flutter
  // `merged.backgroundColor != null ? … : bgBase`, Web
  // `emitColor(merged.backgroundColor, bgBase, .background)`. Pin
  // either one and the selected / unselected / disabled distinction
  // collapses to a single colour, `chipColor` stops changing anything,
  // and the `seedColor` path is dead — for every chip in the tree.
  //
  // (This is the shape `figma_orphan_fields.py` already excuses as the
  // `table` kind — `banner.foregroundColor` ↔ `…VariantStyle.textColor`.
  // It is not spotted here only because the state ternary and
  // `emitColor` are not the `merged.X ?? vs.Y` spelling the regex looks
  // for.)

  /// Panel background fill colour override — wins across every state.
  /// `null` defers to the state-keyed [defaultsByColor] base; see the
  /// note above for why there is no `default*`.
  final CoreColor? backgroundColor;

  /// Foreground (label) colour override — wins across every state, and
  /// is also the fallback the label / key / leading / trailing / close
  /// slots inherit when they carry no colour of their own. `null` defers to
  /// the state-keyed [defaultsByColor] base; see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Same
  /// state-keyed table (selectedFg / unselectedFg / disabledFg / seed)
  /// and the same absence test. Additionally it is the fallback the
  /// label, key, leading, trailing and close-button slots inherit when
  /// they carry no colour of their own, so pinning it silently freezes
  /// five nested slots as well — the key included, which at rest would
  /// otherwise take its own [CoreChipColorStyle.unselectedPrefixFg].
  final CoreColor? foregroundColor;

  /// Border stroke colour.
  final CoreColor? borderColor;

  /// Border stroke width (logical px).
  final double? borderWidth;

  /// Border radius. `null` defers to the shape's corner
  /// ([defaultsByShape] — the full corner for `CoreChipShape.pill`), and
  /// for `CoreChipShape.rounded` to the size row's,
  /// `CoreChipStyle.defaultsBySize[size]!.borderRadius` — 6 · 8 · 10, the
  /// chip's height × 0.25 on a `CoreRadius` rung. A value here wins over
  /// both shapes. It is also the corner the focus ring follows.
  final CoreBorderRadius? borderRadius;

  /// Padding.
  final CoreEdgeInsets? padding;

  /// Minimum chip height (logical px). Per-size default from
  /// [defaultsBySize] — the spec's height ladder, stated as a floor so the
  /// chip matches the control tier beside it rather than its own label.
  final double? minHeight;

  /// Where the content row (leading · key · label · trailing · close)
  /// sits along the chip's main axis when the chip is drawn wider than
  /// its content — a caller's fixed or stretched width. A chip that hugs
  /// its content has no free space, so the value changes nothing there.
  /// `null` defers to [defaultContentAlignment].
  final CoreMainAxisAlignment? contentAlignment;

  /// Gap between the parts of the content row — leading, key, label,
  /// trailing and close button. `null` uses the size row's gap,
  /// `CoreChipStyle.defaultsBySize[size]!.iconLabelGapStyle!`.
  ///
  /// Both platforms hand it to the `Gap(gapStyle: …)` widgets that
  /// separate the slots.
  final CoreGapStyle? iconLabelGapStyle;

  /// Style of the X icon inside the `onRemove` close button, passed to
  /// `Icon(iconStyle: …)` as is. Separate from [leadingIconStyle] /
  /// [trailingIconStyle], which style the leading / trailing content slots.
  final CoreIconStyle? closeIconStyle;

  /// Transition duration for hover / focus / state colour changes.
  /// When null falls back to [defaultTransitionDuration].
  final Duration? transitionDuration;

  /// The engage-squash pair's shared clock — how long the shadow takes
  /// to hide and the chip takes to travel into the space it vacated.
  /// `null` defers to [defaultCastHideDuration]. Reduced-motion collapses
  /// this to zero on both platforms — state (the hide, the travel) is
  /// unaffected.
  final Duration? castHideDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override.
  final CoreTextStyle? labelStyle;

  /// Text style of the key drawn in front of the label (the widget's
  /// `prefixLabel`). `null` uses the size row's role,
  /// `CoreChipStyle.defaultsBySize[size]!.prefixLabelStyle`, over
  /// [defaultPrefixLabelStyle]. A colour set here wins over the key colour
  /// for the chip's current state and over [foregroundColor], the way a
  /// [labelStyle] colour does for the label.
  final CoreTextStyle? prefixLabelStyle;

  /// Leading icon style override.
  final CoreIconStyle? leadingIconStyle;

  /// Trailing icon style override (does **not** affect the close
  /// button — [closeButtonStyle] does).
  final CoreIconStyle? trailingIconStyle;

  /// Style for the close (`onRemove`) button — its padding, corners and
  /// colours. Each close button is a `Button(variant: ghost)` inside; the
  /// X icon in it takes [closeIconStyle].
  final CoreButtonStyle? closeButtonStyle;

  /// Style for the `Clickable` around a tappable chip (`onTap != null`) —
  /// press scale, durations, focus ring, disabled opacity. Laid over
  /// [defaultClickableStyle] and passed to the `Clickable` as is; the
  /// `Clickable` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Disabled custom-seed chip background override.
  /// `null` → [defaultCustomDisabledBackgroundColor].
  final CoreColor? customDisabledBackgroundColor;

  /// Background of a **disabled, unselected** custom-seed chip — the
  /// surface behind a hairline, the row that keeps a never-selected chip
  /// from reading as a selected one. `null` →
  /// [defaultCustomDisabledUnselectedBackgroundColor].
  final CoreColor? customDisabledUnselectedBackgroundColor;

  /// Disabled custom-seed chip foreground override.
  /// `null` → [defaultCustomDisabledForegroundColor].
  final CoreColor? customDisabledForegroundColor;

  /// Disabled custom-seed chip border override.
  /// `null` → [defaultCustomDisabledBorderColor].
  final CoreColor? customDisabledBorderColor;

  /// Selected-state custom-seed chip label colour override.
  /// `null` → the seed's own on-colour, per
  /// [defaultCustomSelectedForegroundColorFor].
  final CoreColor? customSelectedForegroundColor;

  // Deliberately has no `default*`. The baseline is the per-colour table row
  // (neutral `onSurfaceVariant` on every one of them), and `custom` reads
  // the neutral row too — an unselected chip states no colour, and a raw
  // seed cannot promise contrast on the surface behind it. Both platforms
  // read that one baseline.
  /// Label colour override for an unselected chip at
  /// [CoreChipEmphasis.low]; `null` →
  /// [CoreChipColorStyle.lowUnselectedFg] from [defaultsByColor] — the
  /// neutral row for [CoreChipColor.custom].
  final CoreColor? lowUnselectedForegroundColor;

  /// Border colour override for an unselected chip at
  /// [CoreChipEmphasis.low]; falls back to
  /// [defaultLowUnselectedBorderColor].
  final CoreColor? lowUnselectedBorderColor;

  /// Fill override for an unselected, enabled chip at
  /// [CoreChipVariant.filled]; `null` →
  /// [defaultFilledUnselectedBackgroundColor]. The border follows it.
  final CoreColor? filledUnselectedBackgroundColor;

  /// Border colour override for a **selected disabled** chip (any
  /// colour, custom seed included); falls back to
  /// [defaultDisabledSelectedBorderColor] — none.
  final CoreColor? disabledSelectedBorderColor;

  /// Fill override for a selected custom-seed chip at
  /// [CoreChipEmphasis.low] — the tint a raw seed cannot derive on
  /// its own; falls back to [defaultCustomLowSelectedBackgroundColor].
  final CoreColor? customLowSelectedBackgroundColor;

  /// Label override for a selected custom-seed chip at
  /// [CoreChipEmphasis.low]; falls back to
  /// [defaultCustomLowSelectedForegroundColor].
  final CoreColor? customLowSelectedForegroundColor;

  /// Ramp laid over the chip's own fill while hovered, focused or
  /// pressed. Defaults to [defaultStateLayer].
  ///
  /// One ramp for every fill this chip can wear — the overlay is the
  /// chip's current foreground over its current background, so a selected
  /// chip and an unselected one wash from their own ground rather than
  /// from a shared one.
  final CoreStateLayer? stateLayer;

  /// What this chip's cast does when the chip is engaged.
  ///
  /// Null takes [defaultCastMotion]. See [CoreCastMotion] — the value
  /// says *when* the cast changes; what it is worth stays with the
  /// surface style.
  final CoreCastMotion? castMotion;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreChipStyle merge(CoreChipStyle? other) {
    if (other == null) return this;
    return CoreChipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      contentAlignment: other.contentAlignment ?? contentAlignment,
      iconLabelGapStyle: _mergeGapStyle(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
      closeIconStyle: _mergeIcon(closeIconStyle, other.closeIconStyle),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      castHideDuration: other.castHideDuration ?? castHideDuration,
      castMotion: other.castMotion ?? castMotion,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      prefixLabelStyle: _mergeText(prefixLabelStyle, other.prefixLabelStyle),
      leadingIconStyle: _mergeIcon(leadingIconStyle, other.leadingIconStyle),
      trailingIconStyle: _mergeIcon(trailingIconStyle, other.trailingIconStyle),
      closeButtonStyle: _mergeButton(closeButtonStyle, other.closeButtonStyle),
      clickableStyle: _mergeClickable(clickableStyle, other.clickableStyle),
      customDisabledBackgroundColor:
          other.customDisabledBackgroundColor ?? customDisabledBackgroundColor,
      customDisabledUnselectedBackgroundColor:
          other.customDisabledUnselectedBackgroundColor ??
          customDisabledUnselectedBackgroundColor,
      customDisabledForegroundColor:
          other.customDisabledForegroundColor ?? customDisabledForegroundColor,
      customDisabledBorderColor:
          other.customDisabledBorderColor ?? customDisabledBorderColor,
      customSelectedForegroundColor:
          other.customSelectedForegroundColor ?? customSelectedForegroundColor,
      lowUnselectedForegroundColor:
          other.lowUnselectedForegroundColor ?? lowUnselectedForegroundColor,
      lowUnselectedBorderColor:
          other.lowUnselectedBorderColor ?? lowUnselectedBorderColor,
      filledUnselectedBackgroundColor:
          other.filledUnselectedBackgroundColor ??
          filledUnselectedBackgroundColor,
      disabledSelectedBorderColor:
          other.disabledSelectedBorderColor ?? disabledSelectedBorderColor,
      customLowSelectedBackgroundColor:
          other.customLowSelectedBackgroundColor ??
          customLowSelectedBackgroundColor,
      customLowSelectedForegroundColor:
          other.customLowSelectedForegroundColor ??
          customLowSelectedForegroundColor,
      stateLayer: other.stateLayer ?? stateLayer,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreChipStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? minHeight,
    CoreMainAxisAlignment? contentAlignment,
    CoreGapStyle? iconLabelGapStyle,
    CoreIconStyle? closeIconStyle,
    Duration? transitionDuration,
    Duration? castHideDuration,
    CoreCastMotion? castMotion,
    CoreTextStyle? labelStyle,
    CoreTextStyle? prefixLabelStyle,
    CoreIconStyle? leadingIconStyle,
    CoreIconStyle? trailingIconStyle,
    CoreButtonStyle? closeButtonStyle,
    CoreClickableStyle? clickableStyle,
    CoreColor? customDisabledBackgroundColor,
    CoreColor? customDisabledUnselectedBackgroundColor,
    CoreColor? customDisabledForegroundColor,
    CoreColor? customDisabledBorderColor,
    CoreColor? customSelectedForegroundColor,
    CoreColor? lowUnselectedForegroundColor,
    CoreColor? lowUnselectedBorderColor,
    CoreColor? filledUnselectedBackgroundColor,
    CoreColor? disabledSelectedBorderColor,
    CoreColor? customLowSelectedBackgroundColor,
    CoreColor? customLowSelectedForegroundColor,
    CoreStateLayer? stateLayer,
  }) {
    return CoreChipStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
      contentAlignment: contentAlignment ?? this.contentAlignment,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      closeIconStyle: closeIconStyle ?? this.closeIconStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      castHideDuration: castHideDuration ?? this.castHideDuration,
      castMotion: castMotion ?? this.castMotion,
      labelStyle: labelStyle ?? this.labelStyle,
      prefixLabelStyle: prefixLabelStyle ?? this.prefixLabelStyle,
      leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      customDisabledBackgroundColor:
          customDisabledBackgroundColor ?? this.customDisabledBackgroundColor,
      customDisabledUnselectedBackgroundColor:
          customDisabledUnselectedBackgroundColor ??
          this.customDisabledUnselectedBackgroundColor,
      customDisabledForegroundColor:
          customDisabledForegroundColor ?? this.customDisabledForegroundColor,
      customDisabledBorderColor:
          customDisabledBorderColor ?? this.customDisabledBorderColor,
      customSelectedForegroundColor:
          customSelectedForegroundColor ?? this.customSelectedForegroundColor,
      lowUnselectedForegroundColor:
          lowUnselectedForegroundColor ?? this.lowUnselectedForegroundColor,
      lowUnselectedBorderColor:
          lowUnselectedBorderColor ?? this.lowUnselectedBorderColor,
      filledUnselectedBackgroundColor:
          filledUnselectedBackgroundColor ??
          this.filledUnselectedBackgroundColor,
      disabledSelectedBorderColor:
          disabledSelectedBorderColor ?? this.disabledSelectedBorderColor,
      customLowSelectedBackgroundColor:
          customLowSelectedBackgroundColor ??
          this.customLowSelectedBackgroundColor,
      customLowSelectedForegroundColor:
          customLowSelectedForegroundColor ??
          this.customLowSelectedForegroundColor,
      stateLayer: stateLayer ?? this.stateLayer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChipStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          minHeight == other.minHeight &&
          contentAlignment == other.contentAlignment &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          closeIconStyle == other.closeIconStyle &&
          transitionDuration == other.transitionDuration &&
          castHideDuration == other.castHideDuration &&
          castMotion == other.castMotion &&
          labelStyle == other.labelStyle &&
          prefixLabelStyle == other.prefixLabelStyle &&
          leadingIconStyle == other.leadingIconStyle &&
          trailingIconStyle == other.trailingIconStyle &&
          closeButtonStyle == other.closeButtonStyle &&
          clickableStyle == other.clickableStyle &&
          customDisabledBackgroundColor ==
              other.customDisabledBackgroundColor &&
          customDisabledUnselectedBackgroundColor ==
              other.customDisabledUnselectedBackgroundColor &&
          customDisabledForegroundColor ==
              other.customDisabledForegroundColor &&
          customDisabledBorderColor == other.customDisabledBorderColor &&
          customSelectedForegroundColor ==
              other.customSelectedForegroundColor &&
          lowUnselectedForegroundColor == other.lowUnselectedForegroundColor &&
          lowUnselectedBorderColor == other.lowUnselectedBorderColor &&
          filledUnselectedBackgroundColor ==
              other.filledUnselectedBackgroundColor &&
          disabledSelectedBorderColor == other.disabledSelectedBorderColor &&
          customLowSelectedBackgroundColor ==
              other.customLowSelectedBackgroundColor &&
          customLowSelectedForegroundColor ==
              other.customLowSelectedForegroundColor &&
          stateLayer == other.stateLayer;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    minHeight,
    contentAlignment,
    iconLabelGapStyle,
    closeIconStyle,
    transitionDuration,
    castHideDuration,
    castMotion,
    labelStyle,
    prefixLabelStyle,
    leadingIconStyle,
    trailingIconStyle,
    closeButtonStyle,
    clickableStyle,
    customDisabledBackgroundColor,
    customDisabledUnselectedBackgroundColor,
    customDisabledForegroundColor,
    customDisabledBorderColor,
    customSelectedForegroundColor,
    lowUnselectedForegroundColor,
    lowUnselectedBorderColor,
    filledUnselectedBackgroundColor,
    disabledSelectedBorderColor,
    customLowSelectedBackgroundColor,
    customLowSelectedForegroundColor,
    stateLayer,
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

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreClickableStyle? _mergeClickable(
    CoreClickableStyle? base,
    CoreClickableStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Visual style definition for a [CoreChipColor].
///
/// Defines colours for: selected background/foreground, unselected
/// background/foreground, border, and disabled background/foreground/
/// border. All values are platform-neutral ([CoreColor]); the
/// consuming renderer converts at use-site (Flutter via
/// `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
///
/// Only the *selected* rows vary with the colour. Every unselected column —
/// the label at either emphasis ([unselectedFg], [lowUnselectedFg]), the key
/// in front of it ([unselectedPrefixFg]), the high border ([borderColor]) and
/// the fill ([unselectedBg]) — is the same in every row: a resting chip
/// states no colour, and the colour first appears when the chip is selected.
/// The low unselected border is the same thing authored once on
/// `CoreChipStyle`.
///
/// The neutral row's selected fill is the inverse pair
/// ([selectedBg] / [selectedFg] = `inverseSurface` / `inverseOnSurface`), so a
/// chip left to its defaults reads as a dark chip with a light label when
/// selected and as a quiet outline when not.
///
/// Disabled is two rows, not one: [disabledBg] for the chip that was never
/// selected (surface, hairline kept) and [disabledSelectedBg] for the one
/// that was (a filled container, no border at all —
/// `CoreChipStyle.defaultDisabledSelectedBorderColor`). A single disabled
/// fill cannot tell the two apart, and a palette of disabled chips with one
/// of them selected is exactly where that showed.
@immutable
class CoreChipColorStyle {
  /// Creates a chip color style.
  const CoreChipColorStyle({
    required this.lowUnselectedFg,
    required this.disabledSelectedBg,
    required this.selectedBg,
    required this.selectedFg,
    required this.lowSelectedBg,
    required this.lowSelectedFg,
    required this.unselectedBg,
    required this.unselectedFg,
    required this.unselectedPrefixFg,
    required this.borderColor,
    required this.disabledBg,
    required this.disabledFg,
    required this.disabledBorderColor,
  });

  // === Selected (high emphasis) ===

  /// Background colour when selected at [CoreChipEmphasis.high].
  final CoreColor selectedBg;

  /// Foreground colour when selected at [CoreChipEmphasis.high].
  final CoreColor selectedFg;

  // === Selected (low emphasis) ===

  /// Background colour when selected at [CoreChipEmphasis.low].
  final CoreColor lowSelectedBg;

  /// Foreground colour when selected at [CoreChipEmphasis.low].
  final CoreColor lowSelectedFg;

  // === Unselected ===

  /// Background colour when unselected.
  final CoreColor unselectedBg;

  /// Foreground colour when unselected.
  final CoreColor unselectedFg;

  /// Colour of the key in front of the label (the widget's `prefixLabel`)
  /// when unselected, at either emphasis and either variant.
  ///
  /// One column for both emphases, so it sits below the high label
  /// ([unselectedFg]) but matches the low one ([lowUnselectedFg]): on a
  /// low-emphasis resting chip key and value share an ink and are told apart
  /// by role — one step smaller.
  ///
  /// Only the resting chip has a column of its own. A selected or disabled
  /// chip draws its key in that state's label colour ([selectedFg] /
  /// [lowSelectedFg] / [disabledFg], a custom seed's derived label), so no
  /// new slot is needed on an inverse or tinted fill, where a quieter second
  /// ink has no token to sit on.
  final CoreColor unselectedPrefixFg;

  /// Border colour when unselected at [CoreChipEmphasis.high] — the quiet
  /// `outlineVariant` in every row.
  final CoreColor borderColor;

  /// Label colour when unselected at [CoreChipEmphasis.low] — neutral
  /// `onSurfaceVariant` on every row, on the shared low hairline
  /// ([CoreChipStyle.defaultLowUnselectedBorderColor]).
  final CoreColor lowUnselectedFg;

  // === Disabled ===

  /// Background colour when disabled and **unselected** — the surface.
  final CoreColor disabledBg;

  /// Background colour when disabled and **selected** — a filled
  /// container, so the selection is still legible through the greying.
  final CoreColor disabledSelectedBg;

  /// Foreground colour when disabled, selected or not.
  final CoreColor disabledFg;

  /// Border colour when disabled and **unselected**. The selected disabled
  /// chip draws no border — that is
  /// `CoreChipStyle.defaultDisabledSelectedBorderColor`, shared across
  /// colours, not a row here.
  final CoreColor disabledBorderColor;
}
