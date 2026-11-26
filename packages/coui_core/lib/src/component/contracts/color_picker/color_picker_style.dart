/// Per-instance style for `ColorPicker`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/dialog/dialog_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/dashed_border.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ColorPicker` should render.
///
/// `CoreColorPickerStyle` is a composite Style — palette geometry
/// (swatch / hex-input / popover / slider / mode-input / action-row
/// / recent-swatch grid) plus nested sub-component styles (popover /
/// dialog / preset swatch button / hex input) and label / description
/// / error text styles. Every chrome value is platform-neutral
/// (domain-typed where applicable — `CoreEdgeInsets`, raw single-axis
/// `double` for px lengths, `int` for the recent-colors column count)
/// and `override`-able per instance via the corresponding `final` slot.
///
/// **Semantic enums (`pickerMode` / `promptMode`) and behaviour
/// flags (`showAlpha` / `showLabel` / `showHexInput` /
/// `enableEyeDropper`) live on the widget, not on this style**
/// (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default (CoreColorPickerStyle.defaultX)
///   → CoreColorPickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.colorPickerStyle                          // 인스턴스별
/// ```
@immutable
class CoreColorPickerStyle implements CoreStyle<CoreColorPickerStyle> {
  /// Creates a [CoreColorPickerStyle].
  const CoreColorPickerStyle({
    this.swatchSize,
    this.hexInputWidth,
    this.swatchGapStyle,
    this.popoverWidth,
    this.popoverSpacing,
    this.sliderHeight,
    this.modeInputSpacing,
    this.modeInputLabelGapStyle,
    this.actionRowGapStyle,
    this.eyeDropperIconStyle,
    this.recentSwatchSize,
    this.recentSwatchSpacing,
    this.recentColumns,
    this.swatchBorderRadius,
    this.sliderBorderRadius,
    this.recentSwatchBorderRadius,
    this.saturationValueBorderRadius,
    this.pickMarkerSize,
    this.pickMarkerBorderColor,
    this.pickMarkerBorderWidth,
    this.pickMarkerShadow,
    @Deprecated(
      'The hue-bar handle is filled with the current colour, like the '
      'saturation handle (since 0.190) — nothing reads this fill any more.',
    )
    this.hueMarkerFillColor,
    this.hueMarkerBorderColor,
    this.hueMarkerBorderWidth,
    this.emptySwatchDashLength,
    this.emptySwatchDashSpacing,
    this.borderColor,
    this.borderWidth,
    this.disabledBorderColor,
    this.selectedRingColor,
    this.recentSwatchBorderWidth,
    this.recentSwatchSelectedBorderWidth,
    this.transitionDuration,
    this.popoverStyle,
    this.dialogStyle,
    this.swatchButtonStyle,
    this.recentSwatchClickableStyle,
    this.hexInputStyle,
    this.modeTabsStyle,
    this.modeInputLabelStyle,
    this.triggerBackgroundColor,
    this.triggerBorderColor,
    this.triggerBorderWidth,
    this.triggerBorderRadius,
    this.triggerPadding,
    this.triggerSpacing,
    this.triggerMinWidth,
    this.triggerValueTextStyle,
    this.triggerPlaceholderTextStyle,
    this.triggerChevronIconStyle,
    this.recentTitleTextStyle,
    this.recentTitleGapStyle,
    this.modeHexInputFlex,
    this.compareSwatchSize,
    this.compareBorderRadius,
    this.compareBorderColor,
    this.compareBorderWidth,
    this.inlinePanelStyle,
    @Deprecated(
      'Wrap the picker in FormField(label: …) and style the label with its '
      'formFieldStyle.formLabelStyle instead (since 0.183) — ColorPicker '
      'draws no label, so this slot never had an effect.',
    )
    this.labelStyle,
    @Deprecated(
      'Wrap the picker in FormField(description: …) and style the text with '
      'its formFieldStyle.descriptionTextStyle instead (since 0.183) — '
      'ColorPicker draws no description, so this slot never had an effect.',
    )
    this.descriptionStyle,
    @Deprecated(
      'Wrap the picker in FormField(error: …) and style the message with its '
      'formFieldStyle.validatorHintStyle instead (since 0.183) — ColorPicker '
      'draws no error text, so this slot never had an effect.',
    )
    this.errorStyle,
  });

  // ── Design-system defaults (Epic #1415 Phase 6f) ──
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers. The color picker has no visual
  // variant fork so there is no `defaultsByVariant` map.

  /// Default trigger swatch width/height (32px) — the swatch sits inside
  /// the field-shaped trigger, 4px in from its edge.
  static const double defaultSwatchSize = CoreSpace.space32;

  /// Default hex input field width (96px).
  static const double defaultHexInputWidth = CoreSpace.space96;

  /// Default horizontal gap between swatch and hex input (8px).
  static const CoreGapStyle defaultSwatchGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default popover panel width (240px).
  static const double defaultPopoverWidth = CoreSpace.space240;

  /// Default vertical spacing between panel sections (16px). Raw
  /// double primitive — flows into `Column.spacing` (Flutter) and the
  /// `flex flex-col` parent's CSS `gap` (Web), not a `Gap` slot.
  static const double defaultPopoverSpacing = CoreSpace.space16;

  /// Default hue / alpha slider track height (8px). The 18px
  /// [defaultPickMarkerSize] handle rides over the bar and is taller than it,
  /// so the slider's hit box is the handle's height, not the bar's.
  static const double defaultSliderHeight = CoreSpace.space8;

  /// Default horizontal spacing between RGB / HSL / HSV mode input
  /// cells (8px). Raw double primitive — flows into `Row.spacing`
  /// (Flutter) and the `flex` parent's CSS `gap` (Web), not a `Gap`
  /// slot.
  static const double defaultModeInputSpacing = CoreSpace.space8;

  /// Default vertical 1-off gap (2px) between a mode input cell's label
  /// and its number field. Nested [CoreGapStyle] slot forwarded to
  /// `Gap(gapStyle: …)` — the label/field stacking is a single 1-off
  /// spacer inside the mode input cell on both platforms.
  static const CoreGapStyle defaultModeInputLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default horizontal gap between Cancel / Save buttons in the
  /// action row (8px).
  static const CoreGapStyle defaultActionRowGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default icon style (16px) for the eye-dropper button in the action
  /// row. Variant-independent, no colour / state — the resolver
  /// raw-forwards this nested [CoreIconStyle] slot straight to
  /// `Icon(iconStyle: …)`.
  static const CoreIconStyle defaultEyeDropperIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default side length of a recent-color swatch in the popover
  /// history grid (20px).
  static const double defaultRecentSwatchSize = CoreSpace.space20;

  /// Default gap between recent-color swatches in both axes (4px). Raw
  /// double primitive — driven by `Wrap.spacing/runSpacing` (Flutter)
  /// and CSS `gap` (Web), not a `Gap` slot.
  static const double defaultRecentSwatchSpacing = CoreSpace.space4;

  /// Default column count for the recent-colors grid.
  ///
  /// Drives both the fluid Flutter layout (`crossAxisCount`) and the
  /// Web fixed-grid fallback — single source for both platforms.
  static const int defaultRecentColumns = 10;

  /// Default corner radius (6px) for the trigger swatch.
  static const CoreBorderRadius defaultSwatchBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius6);

  /// Default corner radius (4px — half the bar, a pill) for the hue /
  /// alpha slider bars.
  static const CoreBorderRadius defaultSliderBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius4);

  /// Default corner radius (6px) for a recent-color swatch.
  static const CoreBorderRadius defaultRecentSwatchBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius6);

  /// Default side (18px) of the round handle that marks the picked point
  /// on the saturation/value area and on the hue bar.
  static const double defaultPickMarkerSize = CoreSpace.space18;

  /// Default handle ring colour — always white, in every brightness. The
  /// ring separates the handle from the colour it rides on, and a themed
  /// surface tone (dark `surfaceRaised` is a dark grey) vanishes against
  /// the gradient.
  static const CoreColor defaultPickMarkerBorderColor = CoreColor(0xFFFFFFFF);

  /// Default shadow under the picked-point handles — the weakest step of
  /// the shadow scale ([CoreShadow.xs]), shared by both handles.
  static const List<CoreShadowLayer> defaultPickMarkerShadow = CoreShadow.xs;

  /// Former default fill of the hue-bar handle — white.
  @Deprecated(
    'The hue-bar handle is filled with the current colour, like the '
    'saturation handle (since 0.190) — nothing reads this fill any more.',
  )
  static const CoreColor defaultHueMarkerFillColor = CoreColor(0xFFFFFFFF);

  /// Default ring colour of the hue-bar handle — always white, like the
  /// saturation handle's ring. Both handles are filled with the current
  /// colour, and the white ring separates it from the bar behind.
  static const CoreColor defaultHueMarkerBorderColor = CoreColor(0xFFFFFFFF);

  /// Default ring width (3px) of the hue-bar handle — the same ring as the
  /// saturation handle's.
  static const double defaultHueMarkerBorderWidth = CoreStrokeWidth.stroke3;

  /// Default dash length (3px) of the empty ("no colour") swatch's dashed
  /// outline — the shared [CoreDashedBorder] pattern.
  static const double defaultEmptySwatchDashLength =
      CoreDashedBorder.dashLength;

  /// Default gap (2px) between the empty swatch's dashes.
  static const double defaultEmptySwatchDashSpacing = CoreDashedBorder.dashGap;

  /// Default handle ring width (3px).
  static const double defaultPickMarkerBorderWidth = CoreStrokeWidth.stroke3;

  /// Default nested [CoreClickableStyle] slot for the composed
  /// recent-color swatch `Clickable` — an empty partial: the swatch
  /// takes the Clickable's own standard press / focus-ring / cursor
  /// chrome as-is (its `radius4` focus-ring radius already matches
  /// [defaultSwatchBorderRadius], so the ring hugs the square swatch).
  static const CoreClickableStyle defaultRecentSwatchClickableStyle =
      CoreClickableStyle();

  /// Default nested [CorePopoverStyle] slot for the popover-mode
  /// picker — a partial stating only the panel corner (14px), the one
  /// place the picker's panel diverges from `Popover`'s own panel. Every
  /// other panel / anchor / motion value is the popover's own; a partial
  /// that named them would be a second copy of them (`style-contract.md`:
  /// the parent must not reach into the child's defaults).
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    panelStyle: CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// Default nested [CoreTextFieldStyle] slot for the hex input field —
  /// an empty partial: the field takes `TextField`'s own chrome as-is.
  ///
  /// [dialogStyle] and [swatchButtonStyle] deliberately have no
  /// counterpart here: neither slot reaches a child today (no platform
  /// composes a `Dialog`, and the swatch's geometry comes from
  /// [defaultSwatchSize] / [defaultSwatchBorderRadius], not from a
  /// `Button`). A partial for either would publish the child's own
  /// defaults as this component's chrome — for the swatch that is
  /// contradicted by [defaultSwatchBorderRadius], which is the radius
  /// actually painted.
  static const CoreTextFieldStyle defaultHexInputStyle = CoreTextFieldStyle();

  /// Default corner radius (8px) for the 2D saturation/value area
  /// inside the popover. The area draws no border.
  static const CoreBorderRadius defaultSaturationValueBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default nested [CoreToggleGroupStyle] slot for the RGB / HSL / HSV
  /// mode tabs — a partial stating only the track: the tabs sit on the
  /// popover panel (`surfaceBright`), which in Dark equals the group's own
  /// `surfaceContainer` track, so the track goes one step higher
  /// (`surfaceContainerHigh`). Every other field is the shared
  /// `ToggleGroup`'s own chrome.
  static const CoreToggleGroupStyle defaultModeTabsStyle = CoreToggleGroupStyle(
    backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
  );

  /// Default text role for a mode input cell's channel caption
  /// (`R` / `G` / `B`): `bodySmall` in `onSurfaceSubtle`.
  static const CoreTextStyle defaultModeInputLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default border colour (`outline` token) for the trigger swatch and
  /// the recent-colour swatches. The hue / alpha bars draw no border.
  /// Single source of truth shared by both platforms — replaces the
  /// former per-platform `cs.outline` literal.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default border stroke width for the trigger swatch and the recent
  /// colour swatches — routed
  /// through `theme.geometry.stroke(...)` (Flutter) / the shared
  /// `--coui-stroke-width-1` variable (Web) so a surface style's
  /// `strokeFloor` (e.g. neo-brutalism) reaches these borders.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default disabled-trigger border colour (`disabledOutline` token,
  /// #3469) — the dedicated disabled tone, not the enabled `outline`
  /// border dimmed by an `opacity-50` multiplier. The swatch's own fill
  /// legitimately keeps its opacity-based dimming (it displays an
  /// arbitrary user-picked colour with no dedicated "disabled" version to
  /// substitute), but the border is chrome and gets the same treatment
  /// as `text_field` / `text_area`.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default ring colour (`primary` token) highlighting the currently
  /// selected recent-color swatch. Single source of truth shared by
  /// both platforms — replaces the former per-platform `cs.primary`
  /// literal.
  static const CoreColor defaultSelectedRingColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default border stroke width for an unselected recent-color swatch.
  static const double defaultRecentSwatchBorderWidth = CoreStrokeWidth.stroke1;

  /// Default border stroke width for the currently-selected recent-color
  /// swatch (thicker than [defaultRecentSwatchBorderWidth] so the
  /// selection reads clearly).
  static const double defaultRecentSwatchSelectedBorderWidth =
      CoreStrokeWidth.stroke2;

  /// Default transition duration for the swatch hover / focus colour
  /// transitions and the recent-swatch ring transition. Both Flutter and
  /// Web read this token — Flutter via `AnimatedContainer.duration`, Web
  /// via a CSS millisecond value.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  // ── Field-shaped trigger ──

  /// Default fill of the field-shaped trigger — the page face (`surface`),
  /// the same face every other input field sits on.
  static const CoreColor defaultTriggerBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default border colour of the field-shaped trigger (`outlineVariant`).
  static const CoreColor defaultTriggerBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default border width (1px) of the field-shaped trigger.
  static const double defaultTriggerBorderWidth = CoreStrokeWidth.stroke1;

  /// Default corner radius (10px) of the field-shaped trigger.
  static const CoreBorderRadius defaultTriggerBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius10);

  /// Default inner padding of the field-shaped trigger — 4px on the top,
  /// the bottom and the start (where the swatch sits), 12px on the end
  /// (after the chevron). A reading-direction statement: the start and end
  /// swap in a right-to-left locale.
  static const CoreEdgeInsets defaultTriggerPadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space4,
        top: CoreSpace.space4,
        end: CoreSpace.space12,
        bottom: CoreSpace.space4,
      );

  /// Default spacing (10px) between the trigger's swatch, text and chevron.
  static const double defaultTriggerSpacing = CoreSpace.space10;

  /// Default minimum width (184px) of the field-shaped trigger.
  static const double defaultTriggerMinWidth = CoreSpace.space184;

  /// Default text role of the trigger's hex value: `labelMedium` (13
  /// Medium) in `onSurface`.
  static const CoreTextStyle defaultTriggerValueTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default text role of the trigger's placeholder: `bodySmall` (13
  /// Regular) in `onSurfaceVariant`.
  static const CoreTextStyle defaultTriggerPlaceholderTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      );

  /// Default chevron at the end of the trigger — 16px in
  /// `onSurfaceVariant`.
  static const CoreIconStyle defaultTriggerChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  // ── Panel sections ──

  /// Default text role of the title above the recent colours: `labelXs`
  /// in `onSurfaceSubtle`.
  static const CoreTextStyle defaultRecentTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default gap (8px) between the recent-colours title and the swatches.
  static const CoreGapStyle defaultRecentTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default flex weight of the HEX input cell against each channel cell's
  /// `1` — a hex value needs about twice a channel's width.
  static const int defaultModeHexInputFlex = 2;

  /// Default side (24px) of each half of the inline comparison cell.
  static const double defaultCompareSwatchSize = CoreSpace.space24;

  /// Default corner radius (6px) of the inline comparison cell — the same
  /// step as the trigger swatch.
  static const CoreBorderRadius defaultCompareBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius6);

  /// Default border colour of the inline comparison cell
  /// (`outlineVariant`).
  static const CoreColor defaultCompareBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default border width (1px) of the inline comparison cell.
  static const double defaultCompareBorderWidth = CoreStrokeWidth.stroke1;

  /// Default nested [CorePopupStyle] slot for the inline presentation's
  /// panel box — a partial stating only where it diverges from `Popup`:
  /// the 14px corner the popover panel also states, and no shadow, since
  /// the inline panel sits in the page instead of floating over it.
  static const CorePopupStyle defaultInlinePanelStyle = CorePopupStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    boxShadow: CoreShadow.none,
  );

  // ── Geometry chrome (flat) ───────────────────

  /// Trigger swatch button width/height override (logical px).
  final double? swatchSize;

  /// Hex input field width override (logical px).
  final double? hexInputWidth;

  /// Horizontal gap between the swatch and the hex input, passed to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle? swatchGapStyle;

  /// Popover panel width override (logical px).
  final double? popoverWidth;

  /// Vertical spacing between popover sections override (logical px,
  /// pre-scaling). Raw primitive — flows directly into `Column.spacing`
  /// (Flutter) and the `flex flex-col` parent's CSS `gap` (Web), not a
  /// `Gap` slot. Falls back to [defaultPopoverSpacing] when null.
  final double? popoverSpacing;

  /// Hue / alpha slider track height override (logical px).
  final double? sliderHeight;

  /// Horizontal spacing between RGB / HSL / HSV mode input cells
  /// override (logical px, pre-scaling). Raw primitive — flows directly
  /// into `Row.spacing` (Flutter) and the `flex` parent's CSS `gap`
  /// (Web), not a `Gap` slot. Falls back to [defaultModeInputSpacing]
  /// when null.
  final double? modeInputSpacing;

  /// Vertical gap between a mode input cell's label and its number field,
  /// passed to `Gap(gapStyle: …)`.
  ///
  /// The label/field stacking is a single 1-off spacer internal to the
  /// mode input cell on both platforms.
  final CoreGapStyle? modeInputLabelGapStyle;

  /// Horizontal gap between the Cancel and Save buttons in the action row,
  /// passed to `Gap(gapStyle: …)`.
  final CoreGapStyle? actionRowGapStyle;

  /// Style of the eye-dropper button's icon, passed to
  /// `Icon(iconStyle: …)`. Falls back to [defaultEyeDropperIconStyle] when
  /// null.
  final CoreIconStyle? eyeDropperIconStyle;

  /// Recent-color swatch side length override (logical px).
  final double? recentSwatchSize;

  /// Spacing (logical px) between recent-color swatches override —
  /// raw primitive, drives `Wrap.spacing/runSpacing` (Flutter) and
  /// CSS `gap` (Web), not a `Gap` slot.
  final double? recentSwatchSpacing;

  /// Recent-colors grid column count override.
  final int? recentColumns;

  /// Corner radius override for the trigger swatch button.
  final CoreBorderRadius? swatchBorderRadius;

  /// Corner radius override for the hue / alpha slider bars. Falls back
  /// to [defaultSliderBorderRadius] when null.
  final CoreBorderRadius? sliderBorderRadius;

  /// Corner radius override for a recent-color swatch. Falls back to
  /// [defaultRecentSwatchBorderRadius] when null.
  final CoreBorderRadius? recentSwatchBorderRadius;

  /// Corner radius override for the 2D saturation/value area inside the
  /// popover.
  final CoreBorderRadius? saturationValueBorderRadius;

  /// Side override (logical px) of the round picked-point handle on the
  /// saturation/value area and the hue bar. Falls back to
  /// [defaultPickMarkerSize] when null.
  final double? pickMarkerSize;

  /// Handle ring colour override. Falls back to
  /// [defaultPickMarkerBorderColor] when null.
  final CoreColor? pickMarkerBorderColor;

  /// Handle ring width override (logical px). Falls back to
  /// [defaultPickMarkerBorderWidth] when null.
  final double? pickMarkerBorderWidth;

  /// Shadow layers under both picked-point handles. Falls back to
  /// [defaultPickMarkerShadow] when null.
  final List<CoreShadowLayer>? pickMarkerShadow;

  /// Former hue-bar handle fill. The handle is filled with the current
  /// colour now, so nothing reads it.
  @Deprecated(
    'The hue-bar handle is filled with the current colour, like the '
    'saturation handle (since 0.190) — nothing reads this fill any more.',
  )
  final CoreColor? hueMarkerFillColor;

  /// Hue-bar handle border colour override. Falls back to
  /// [defaultHueMarkerBorderColor] when null.
  final CoreColor? hueMarkerBorderColor;

  /// Hue-bar handle border width override (logical px). Falls back to
  /// [defaultHueMarkerBorderWidth] when null.
  final double? hueMarkerBorderWidth;

  /// Dash length override (logical px) of the empty swatch's dashed
  /// outline. Falls back to [defaultEmptySwatchDashLength] when null.
  final double? emptySwatchDashLength;

  /// Dash gap override (logical px) of the empty swatch's dashed outline.
  /// Falls back to [defaultEmptySwatchDashSpacing] when null.
  final double? emptySwatchDashSpacing;

  /// Border colour override for the trigger swatch and the recent-colour
  /// swatches. Falls back to [defaultBorderColor] when null.
  final CoreColor? borderColor;

  /// Border stroke width override (logical px) for the trigger swatch and
  /// the recent-colour swatches. Falls back to [defaultBorderWidth] when
  /// null.
  final double? borderWidth;

  /// Border colour override for the trigger swatch when disabled. Falls
  /// back to [defaultDisabledBorderColor] (`disabledOutline` token) when
  /// null.
  final CoreColor? disabledBorderColor;

  /// Ring colour override for the currently-selected recent-color
  /// swatch. Falls back to [defaultSelectedRingColor] (`primary` token)
  /// when null.
  final CoreColor? selectedRingColor;

  /// Border stroke width override (logical px) for an unselected
  /// recent-color swatch. Falls back to [defaultRecentSwatchBorderWidth]
  /// when null.
  final double? recentSwatchBorderWidth;

  /// Border stroke width override (logical px) for the currently-selected
  /// recent-color swatch. Falls back to
  /// [defaultRecentSwatchSelectedBorderWidth] when null.
  final double? recentSwatchSelectedBorderWidth;

  /// Transition duration override for the swatch hover / focus colour
  /// transitions and the recent-swatch ring transition. Falls back to
  /// [defaultTransitionDuration] when null.
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Popover style for the popover-mode picker — the look of its trigger
  /// and dropdown.
  final CorePopoverStyle? popoverStyle;

  /// Dialog style for the modal-mode picker.
  ///
  /// **Read by no resolver and no widget — wire it or remove it.** Wire
  /// it, don't default it. Both resolvers forward it (`dialogStyle:
  /// merged.dialogStyle`) into `ResolvedColorPicker.dialogStyle`, but no
  /// widget reads that field and neither platform composes a `Dialog`:
  /// `promptMode: .dialog` renders the same popover content column
  /// (Flutter `_buildPopoverContent`-equivalent SizedBox+Column, Web
  /// `_buildPopoverContent`), only with `dialogTitle` prepended. So the
  /// real defect is the missing `Dialog` composition for `promptMode:
  /// .dialog` (style-contract.md facet 4: modal centre surface must be
  /// `Dialog`, not a re-drawn panel) — fixing that makes the slot live
  /// and gives it a natural partial default. Until then it must NOT get a
  /// default: a value on a slot nothing reads is an orphan constant, the
  /// mirror violation. Deletion would also be viable but is a breaking
  /// public-field removal and not this PR's call. NOTE:
  /// `CoreColorPickerStyle.defaultHexInputStyle`'s doc comment already
  /// asserts 'no platform composes a Dialog' — that claim is correct and
  /// is corroborated here.
  final CoreDialogStyle? dialogStyle;

  /// Style applied to each preset / history color swatch button.
  ///
  /// Carries no `defaultSwatchButtonStyle`. No platform composes a `Button`
  /// for the swatch — both read exactly two sub-fields off this slot as the
  /// *first rung of a precedence chain* over the flat swatch geometry:
  /// `merged.swatchButtonStyle?.width ?? merged.swatchSize
  /// ?? defaultSwatchSize` and `merged.swatchButtonStyle?.borderRadius
  /// ?? merged.swatchBorderRadius ?? defaultSwatchBorderRadius`. A default
  /// setting either sub-field would outrank [defaultSwatchSize] /
  /// [defaultSwatchBorderRadius] and make those two named defaults — the
  /// values actually painted — unreachable.
  final CoreButtonStyle? swatchButtonStyle;

  /// Style for each recent-color swatch's `Clickable` — press, focus ring
  /// and cursor overrides for the swatch. Laid over
  /// [defaultRecentSwatchClickableStyle] and passed to
  /// `Clickable(clickableStyle:)` as is.
  final CoreClickableStyle? recentSwatchClickableStyle;

  /// Style applied to the hex input field (`showHexInput: true`).
  final CoreTextFieldStyle? hexInputStyle;

  /// Style for the mode tabs, passed to their
  /// `ToggleGroup(toggleGroupStyle: …)` as is.
  final CoreToggleGroupStyle? modeTabsStyle;

  /// Channel caption (`R` / `G` / `B`) text style override. Falls back to
  /// [defaultModeInputLabelStyle] when null.
  final CoreTextStyle? modeInputLabelStyle;

  /// Fill of the field-shaped trigger. Falls back to
  /// [defaultTriggerBackgroundColor] when null.
  final CoreColor? triggerBackgroundColor;

  /// Border colour of the field-shaped trigger. Falls back to
  /// [defaultTriggerBorderColor] when null.
  final CoreColor? triggerBorderColor;

  /// Border width (logical px) of the field-shaped trigger. Falls back to
  /// [defaultTriggerBorderWidth] when null.
  final double? triggerBorderWidth;

  /// Corner radius of the field-shaped trigger. Falls back to
  /// [defaultTriggerBorderRadius] when null.
  final CoreBorderRadius? triggerBorderRadius;

  /// Inner padding of the field-shaped trigger. Falls back to
  /// [defaultTriggerPadding] when null.
  final CoreEdgeInsets? triggerPadding;

  /// Spacing (logical px) between the trigger's swatch, text and chevron.
  /// Falls back to [defaultTriggerSpacing] when null.
  final double? triggerSpacing;

  /// Minimum width (logical px) of the field-shaped trigger. Falls back to
  /// [defaultTriggerMinWidth] when null.
  final double? triggerMinWidth;

  /// Text style of the trigger's hex value, shown when a colour is picked.
  /// Falls back to [defaultTriggerValueTextStyle] when null.
  final CoreTextStyle? triggerValueTextStyle;

  /// Text style of the trigger's placeholder, shown when no colour is
  /// picked. Falls back to [defaultTriggerPlaceholderTextStyle] when null.
  final CoreTextStyle? triggerPlaceholderTextStyle;

  /// Style of the chevron at the end of the trigger. Falls back to
  /// [defaultTriggerChevronIconStyle] when null.
  final CoreIconStyle? triggerChevronIconStyle;

  /// Text style of the title above the recent colours. Falls back to
  /// [defaultRecentTitleTextStyle] when null.
  final CoreTextStyle? recentTitleTextStyle;

  /// Gap between the recent-colours title and the swatches, passed to
  /// `Gap(gapStyle: …)`. Falls back to [defaultRecentTitleGapStyle] when
  /// null.
  final CoreGapStyle? recentTitleGapStyle;

  /// How much wider the HEX input cell grows than each channel cell — a
  /// flex weight against the channel cells' `1`. Falls back to
  /// [defaultModeHexInputFlex] when null.
  final int? modeHexInputFlex;

  /// Side (logical px) of each half of the inline panel's previous / current
  /// comparison cell. Falls back to [defaultCompareSwatchSize] when null.
  final double? compareSwatchSize;

  /// Corner radius of the inline panel's comparison cell. Falls back to
  /// [defaultCompareBorderRadius] when null.
  final CoreBorderRadius? compareBorderRadius;

  /// Border colour of the inline panel's comparison cell. Falls back to
  /// [defaultCompareBorderColor] when null.
  final CoreColor? compareBorderColor;

  /// Border width (logical px) of the inline panel's comparison cell.
  /// Falls back to [defaultCompareBorderWidth] when null.
  final double? compareBorderWidth;

  /// Style of the panel box the inline presentation draws in place, passed
  /// to `Popup(popupStyle: …)`. Falls back to [defaultInlinePanelStyle] when
  /// null.
  final CorePopupStyle? inlinePanelStyle;

  /// Label text style.
  ///
  /// `ColorPicker` draws no label, so this never had an effect; both
  /// platforms still carry it onto `ResolvedColorPicker`, where nothing
  /// reads it, until it is removed. The label belongs to `FormField`, which
  /// already owns the label, description and error together — a second
  /// label slot here would split them.
  @Deprecated(
    'Wrap the picker in FormField(label: …) and style the label with its '
    'formFieldStyle.formLabelStyle instead (since 0.183) — ColorPicker '
    'draws no label, so this slot never had an effect.',
  )
  final CoreTextStyle? labelStyle;

  /// Description / helper text style.
  ///
  /// Carried and unread the same way as [labelStyle].
  @Deprecated(
    'Wrap the picker in FormField(description: …) and style the text with '
    'its formFieldStyle.descriptionTextStyle instead (since 0.183) — '
    'ColorPicker draws no description, so this slot never had an effect.',
  )
  final CoreTextStyle? descriptionStyle;

  /// Error text style.
  ///
  /// Carried and unread the same way as [labelStyle].
  @Deprecated(
    'Wrap the picker in FormField(error: …) and style the message with its '
    'formFieldStyle.validatorHintStyle instead (since 0.183) — ColorPicker '
    'draws no error text, so this slot never had an effect.',
  )
  final CoreTextStyle? errorStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreColorPickerStyle merge(CoreColorPickerStyle? other) {
    if (other == null) return this;
    return CoreColorPickerStyle(
      swatchSize: other.swatchSize ?? swatchSize,
      hexInputWidth: other.hexInputWidth ?? hexInputWidth,
      swatchGapStyle: _mergeGap(swatchGapStyle, other.swatchGapStyle),
      popoverWidth: other.popoverWidth ?? popoverWidth,
      popoverSpacing: other.popoverSpacing ?? popoverSpacing,
      sliderHeight: other.sliderHeight ?? sliderHeight,
      modeInputSpacing: other.modeInputSpacing ?? modeInputSpacing,
      modeInputLabelGapStyle: _mergeGap(
        modeInputLabelGapStyle,
        other.modeInputLabelGapStyle,
      ),
      actionRowGapStyle: _mergeGap(actionRowGapStyle, other.actionRowGapStyle),
      eyeDropperIconStyle: _mergeIcon(
        eyeDropperIconStyle,
        other.eyeDropperIconStyle,
      ),
      recentSwatchSize: other.recentSwatchSize ?? recentSwatchSize,
      recentSwatchSpacing: other.recentSwatchSpacing ?? recentSwatchSpacing,
      recentColumns: other.recentColumns ?? recentColumns,
      swatchBorderRadius: other.swatchBorderRadius ?? swatchBorderRadius,
      sliderBorderRadius: other.sliderBorderRadius ?? sliderBorderRadius,
      recentSwatchBorderRadius:
          other.recentSwatchBorderRadius ?? recentSwatchBorderRadius,
      pickMarkerSize: other.pickMarkerSize ?? pickMarkerSize,
      pickMarkerBorderColor:
          other.pickMarkerBorderColor ?? pickMarkerBorderColor,
      pickMarkerBorderWidth:
          other.pickMarkerBorderWidth ?? pickMarkerBorderWidth,
      pickMarkerShadow: other.pickMarkerShadow ?? pickMarkerShadow,
      hueMarkerFillColor: other.hueMarkerFillColor ?? hueMarkerFillColor,
      hueMarkerBorderColor: other.hueMarkerBorderColor ?? hueMarkerBorderColor,
      hueMarkerBorderWidth: other.hueMarkerBorderWidth ?? hueMarkerBorderWidth,
      emptySwatchDashLength:
          other.emptySwatchDashLength ?? emptySwatchDashLength,
      emptySwatchDashSpacing:
          other.emptySwatchDashSpacing ?? emptySwatchDashSpacing,
      saturationValueBorderRadius:
          other.saturationValueBorderRadius ?? saturationValueBorderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      selectedRingColor: other.selectedRingColor ?? selectedRingColor,
      recentSwatchBorderWidth:
          other.recentSwatchBorderWidth ?? recentSwatchBorderWidth,
      recentSwatchSelectedBorderWidth:
          other.recentSwatchSelectedBorderWidth ??
          recentSwatchSelectedBorderWidth,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      dialogStyle: _mergeDialog(dialogStyle, other.dialogStyle),
      swatchButtonStyle: _mergeButton(
        swatchButtonStyle,
        other.swatchButtonStyle,
      ),
      recentSwatchClickableStyle: _mergeClickable(
        recentSwatchClickableStyle,
        other.recentSwatchClickableStyle,
      ),
      hexInputStyle: _mergeTextField(hexInputStyle, other.hexInputStyle),
      modeTabsStyle: _mergeToggleGroup(modeTabsStyle, other.modeTabsStyle),
      modeInputLabelStyle: _mergeText(
        modeInputLabelStyle,
        other.modeInputLabelStyle,
      ),
      triggerBackgroundColor:
          other.triggerBackgroundColor ?? triggerBackgroundColor,
      triggerBorderColor: other.triggerBorderColor ?? triggerBorderColor,
      triggerBorderWidth: other.triggerBorderWidth ?? triggerBorderWidth,
      triggerBorderRadius: other.triggerBorderRadius ?? triggerBorderRadius,
      triggerPadding: other.triggerPadding ?? triggerPadding,
      triggerSpacing: other.triggerSpacing ?? triggerSpacing,
      triggerMinWidth: other.triggerMinWidth ?? triggerMinWidth,
      triggerValueTextStyle: _mergeText(
        triggerValueTextStyle,
        other.triggerValueTextStyle,
      ),
      triggerPlaceholderTextStyle: _mergeText(
        triggerPlaceholderTextStyle,
        other.triggerPlaceholderTextStyle,
      ),
      triggerChevronIconStyle: _mergeIcon(
        triggerChevronIconStyle,
        other.triggerChevronIconStyle,
      ),
      recentTitleTextStyle: _mergeText(
        recentTitleTextStyle,
        other.recentTitleTextStyle,
      ),
      recentTitleGapStyle: _mergeGap(
        recentTitleGapStyle,
        other.recentTitleGapStyle,
      ),
      modeHexInputFlex: other.modeHexInputFlex ?? modeHexInputFlex,
      compareSwatchSize: other.compareSwatchSize ?? compareSwatchSize,
      compareBorderRadius: other.compareBorderRadius ?? compareBorderRadius,
      compareBorderColor: other.compareBorderColor ?? compareBorderColor,
      compareBorderWidth: other.compareBorderWidth ?? compareBorderWidth,
      inlinePanelStyle: _mergePopup(inlinePanelStyle, other.inlinePanelStyle),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      errorStyle: _mergeText(errorStyle, other.errorStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreColorPickerStyle copyWith({
    double? swatchSize,
    double? hexInputWidth,
    CoreGapStyle? swatchGapStyle,
    double? popoverWidth,
    double? popoverSpacing,
    double? sliderHeight,
    double? modeInputSpacing,
    CoreGapStyle? modeInputLabelGapStyle,
    CoreGapStyle? actionRowGapStyle,
    CoreIconStyle? eyeDropperIconStyle,
    double? recentSwatchSize,
    double? recentSwatchSpacing,
    int? recentColumns,
    CoreBorderRadius? swatchBorderRadius,
    CoreBorderRadius? sliderBorderRadius,
    CoreBorderRadius? recentSwatchBorderRadius,
    double? pickMarkerSize,
    CoreColor? pickMarkerBorderColor,
    double? pickMarkerBorderWidth,
    List<CoreShadowLayer>? pickMarkerShadow,
    CoreColor? hueMarkerFillColor,
    CoreColor? hueMarkerBorderColor,
    double? hueMarkerBorderWidth,
    double? emptySwatchDashLength,
    double? emptySwatchDashSpacing,
    CoreBorderRadius? saturationValueBorderRadius,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? disabledBorderColor,
    CoreColor? selectedRingColor,
    double? recentSwatchBorderWidth,
    double? recentSwatchSelectedBorderWidth,
    Duration? transitionDuration,
    CorePopoverStyle? popoverStyle,
    CoreDialogStyle? dialogStyle,
    CoreButtonStyle? swatchButtonStyle,
    CoreClickableStyle? recentSwatchClickableStyle,
    CoreTextFieldStyle? hexInputStyle,
    CoreToggleGroupStyle? modeTabsStyle,
    CoreTextStyle? modeInputLabelStyle,
    CoreColor? triggerBackgroundColor,
    CoreColor? triggerBorderColor,
    double? triggerBorderWidth,
    CoreBorderRadius? triggerBorderRadius,
    CoreEdgeInsets? triggerPadding,
    double? triggerSpacing,
    double? triggerMinWidth,
    CoreTextStyle? triggerValueTextStyle,
    CoreTextStyle? triggerPlaceholderTextStyle,
    CoreIconStyle? triggerChevronIconStyle,
    CoreTextStyle? recentTitleTextStyle,
    CoreGapStyle? recentTitleGapStyle,
    int? modeHexInputFlex,
    double? compareSwatchSize,
    CoreBorderRadius? compareBorderRadius,
    CoreColor? compareBorderColor,
    double? compareBorderWidth,
    CorePopupStyle? inlinePanelStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? errorStyle,
  }) {
    return CoreColorPickerStyle(
      swatchSize: swatchSize ?? this.swatchSize,
      hexInputWidth: hexInputWidth ?? this.hexInputWidth,
      swatchGapStyle: swatchGapStyle ?? this.swatchGapStyle,
      popoverWidth: popoverWidth ?? this.popoverWidth,
      popoverSpacing: popoverSpacing ?? this.popoverSpacing,
      sliderHeight: sliderHeight ?? this.sliderHeight,
      modeInputSpacing: modeInputSpacing ?? this.modeInputSpacing,
      modeInputLabelGapStyle:
          modeInputLabelGapStyle ?? this.modeInputLabelGapStyle,
      actionRowGapStyle: actionRowGapStyle ?? this.actionRowGapStyle,
      eyeDropperIconStyle: eyeDropperIconStyle ?? this.eyeDropperIconStyle,
      recentSwatchSize: recentSwatchSize ?? this.recentSwatchSize,
      recentSwatchSpacing: recentSwatchSpacing ?? this.recentSwatchSpacing,
      recentColumns: recentColumns ?? this.recentColumns,
      swatchBorderRadius: swatchBorderRadius ?? this.swatchBorderRadius,
      sliderBorderRadius: sliderBorderRadius ?? this.sliderBorderRadius,
      recentSwatchBorderRadius:
          recentSwatchBorderRadius ?? this.recentSwatchBorderRadius,
      pickMarkerSize: pickMarkerSize ?? this.pickMarkerSize,
      pickMarkerBorderColor:
          pickMarkerBorderColor ?? this.pickMarkerBorderColor,
      pickMarkerBorderWidth:
          pickMarkerBorderWidth ?? this.pickMarkerBorderWidth,
      pickMarkerShadow: pickMarkerShadow ?? this.pickMarkerShadow,
      hueMarkerFillColor: hueMarkerFillColor ?? this.hueMarkerFillColor,
      hueMarkerBorderColor: hueMarkerBorderColor ?? this.hueMarkerBorderColor,
      hueMarkerBorderWidth: hueMarkerBorderWidth ?? this.hueMarkerBorderWidth,
      emptySwatchDashLength:
          emptySwatchDashLength ?? this.emptySwatchDashLength,
      emptySwatchDashSpacing:
          emptySwatchDashSpacing ?? this.emptySwatchDashSpacing,
      saturationValueBorderRadius:
          saturationValueBorderRadius ?? this.saturationValueBorderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      selectedRingColor: selectedRingColor ?? this.selectedRingColor,
      recentSwatchBorderWidth:
          recentSwatchBorderWidth ?? this.recentSwatchBorderWidth,
      recentSwatchSelectedBorderWidth:
          recentSwatchSelectedBorderWidth ??
          this.recentSwatchSelectedBorderWidth,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      swatchButtonStyle: swatchButtonStyle ?? this.swatchButtonStyle,
      recentSwatchClickableStyle:
          recentSwatchClickableStyle ?? this.recentSwatchClickableStyle,
      hexInputStyle: hexInputStyle ?? this.hexInputStyle,
      modeTabsStyle: modeTabsStyle ?? this.modeTabsStyle,
      modeInputLabelStyle: modeInputLabelStyle ?? this.modeInputLabelStyle,
      triggerBackgroundColor:
          triggerBackgroundColor ?? this.triggerBackgroundColor,
      triggerBorderColor: triggerBorderColor ?? this.triggerBorderColor,
      triggerBorderWidth: triggerBorderWidth ?? this.triggerBorderWidth,
      triggerBorderRadius: triggerBorderRadius ?? this.triggerBorderRadius,
      triggerPadding: triggerPadding ?? this.triggerPadding,
      triggerSpacing: triggerSpacing ?? this.triggerSpacing,
      triggerMinWidth: triggerMinWidth ?? this.triggerMinWidth,
      triggerValueTextStyle:
          triggerValueTextStyle ?? this.triggerValueTextStyle,
      triggerPlaceholderTextStyle:
          triggerPlaceholderTextStyle ?? this.triggerPlaceholderTextStyle,
      triggerChevronIconStyle:
          triggerChevronIconStyle ?? this.triggerChevronIconStyle,
      recentTitleTextStyle: recentTitleTextStyle ?? this.recentTitleTextStyle,
      recentTitleGapStyle: recentTitleGapStyle ?? this.recentTitleGapStyle,
      modeHexInputFlex: modeHexInputFlex ?? this.modeHexInputFlex,
      compareSwatchSize: compareSwatchSize ?? this.compareSwatchSize,
      compareBorderRadius: compareBorderRadius ?? this.compareBorderRadius,
      compareBorderColor: compareBorderColor ?? this.compareBorderColor,
      compareBorderWidth: compareBorderWidth ?? this.compareBorderWidth,
      inlinePanelStyle: inlinePanelStyle ?? this.inlinePanelStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      errorStyle: errorStyle ?? this.errorStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreColorPickerStyle &&
          runtimeType == other.runtimeType &&
          swatchSize == other.swatchSize &&
          hexInputWidth == other.hexInputWidth &&
          swatchGapStyle == other.swatchGapStyle &&
          popoverWidth == other.popoverWidth &&
          popoverSpacing == other.popoverSpacing &&
          sliderHeight == other.sliderHeight &&
          modeInputSpacing == other.modeInputSpacing &&
          modeInputLabelGapStyle == other.modeInputLabelGapStyle &&
          actionRowGapStyle == other.actionRowGapStyle &&
          eyeDropperIconStyle == other.eyeDropperIconStyle &&
          recentSwatchSize == other.recentSwatchSize &&
          recentSwatchSpacing == other.recentSwatchSpacing &&
          recentColumns == other.recentColumns &&
          swatchBorderRadius == other.swatchBorderRadius &&
          sliderBorderRadius == other.sliderBorderRadius &&
          recentSwatchBorderRadius == other.recentSwatchBorderRadius &&
          pickMarkerSize == other.pickMarkerSize &&
          pickMarkerBorderColor == other.pickMarkerBorderColor &&
          pickMarkerBorderWidth == other.pickMarkerBorderWidth &&
          _shadowEq(pickMarkerShadow, other.pickMarkerShadow) &&
          hueMarkerFillColor == other.hueMarkerFillColor &&
          hueMarkerBorderColor == other.hueMarkerBorderColor &&
          hueMarkerBorderWidth == other.hueMarkerBorderWidth &&
          emptySwatchDashLength == other.emptySwatchDashLength &&
          emptySwatchDashSpacing == other.emptySwatchDashSpacing &&
          saturationValueBorderRadius == other.saturationValueBorderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          disabledBorderColor == other.disabledBorderColor &&
          selectedRingColor == other.selectedRingColor &&
          recentSwatchBorderWidth == other.recentSwatchBorderWidth &&
          recentSwatchSelectedBorderWidth ==
              other.recentSwatchSelectedBorderWidth &&
          transitionDuration == other.transitionDuration &&
          popoverStyle == other.popoverStyle &&
          dialogStyle == other.dialogStyle &&
          swatchButtonStyle == other.swatchButtonStyle &&
          recentSwatchClickableStyle == other.recentSwatchClickableStyle &&
          hexInputStyle == other.hexInputStyle &&
          modeTabsStyle == other.modeTabsStyle &&
          modeInputLabelStyle == other.modeInputLabelStyle &&
          triggerBackgroundColor == other.triggerBackgroundColor &&
          triggerBorderColor == other.triggerBorderColor &&
          triggerBorderWidth == other.triggerBorderWidth &&
          triggerBorderRadius == other.triggerBorderRadius &&
          triggerPadding == other.triggerPadding &&
          triggerSpacing == other.triggerSpacing &&
          triggerMinWidth == other.triggerMinWidth &&
          triggerValueTextStyle == other.triggerValueTextStyle &&
          triggerPlaceholderTextStyle == other.triggerPlaceholderTextStyle &&
          triggerChevronIconStyle == other.triggerChevronIconStyle &&
          recentTitleTextStyle == other.recentTitleTextStyle &&
          recentTitleGapStyle == other.recentTitleGapStyle &&
          modeHexInputFlex == other.modeHexInputFlex &&
          compareSwatchSize == other.compareSwatchSize &&
          compareBorderRadius == other.compareBorderRadius &&
          compareBorderColor == other.compareBorderColor &&
          compareBorderWidth == other.compareBorderWidth &&
          inlinePanelStyle == other.inlinePanelStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          errorStyle == other.errorStyle;

  @override
  int get hashCode => Object.hashAll([
    swatchSize,
    hexInputWidth,
    swatchGapStyle,
    popoverWidth,
    popoverSpacing,
    sliderHeight,
    modeInputSpacing,
    modeInputLabelGapStyle,
    actionRowGapStyle,
    eyeDropperIconStyle,
    recentSwatchSize,
    recentSwatchSpacing,
    recentColumns,
    swatchBorderRadius,
    sliderBorderRadius,
    recentSwatchBorderRadius,
    pickMarkerSize,
    pickMarkerBorderColor,
    pickMarkerBorderWidth,
    if (pickMarkerShadow == null) null else Object.hashAll(pickMarkerShadow!),
    hueMarkerFillColor,
    hueMarkerBorderColor,
    hueMarkerBorderWidth,
    emptySwatchDashLength,
    emptySwatchDashSpacing,
    saturationValueBorderRadius,
    borderColor,
    borderWidth,
    disabledBorderColor,
    selectedRingColor,
    recentSwatchBorderWidth,
    recentSwatchSelectedBorderWidth,
    transitionDuration,
    popoverStyle,
    dialogStyle,
    swatchButtonStyle,
    recentSwatchClickableStyle,
    hexInputStyle,
    modeTabsStyle,
    modeInputLabelStyle,
    triggerBackgroundColor,
    triggerBorderColor,
    triggerBorderWidth,
    triggerBorderRadius,
    triggerPadding,
    triggerSpacing,
    triggerMinWidth,
    triggerValueTextStyle,
    triggerPlaceholderTextStyle,
    triggerChevronIconStyle,
    recentTitleTextStyle,
    recentTitleGapStyle,
    modeHexInputFlex,
    compareSwatchSize,
    compareBorderRadius,
    compareBorderColor,
    compareBorderWidth,
    inlinePanelStyle,
    labelStyle,
    descriptionStyle,
    errorStyle,
  ]);

  static bool _shadowEq(List<CoreShadowLayer>? a, List<CoreShadowLayer>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreDialogStyle? _mergeDialog(
    CoreDialogStyle? base,
    CoreDialogStyle? other,
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

  static CoreClickableStyle? _mergeClickable(
    CoreClickableStyle? base,
    CoreClickableStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextFieldStyle? _mergeTextField(
    CoreTextFieldStyle? base,
    CoreTextFieldStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreToggleGroupStyle? _mergeToggleGroup(
    CoreToggleGroupStyle? base,
    CoreToggleGroupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
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
}
