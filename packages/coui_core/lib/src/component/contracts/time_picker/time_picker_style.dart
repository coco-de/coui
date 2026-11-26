/// Per-instance style for `TimePicker`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/dialog/dialog_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_style.dart';
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
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `TimePicker` should render.
///
/// `CoreTimePickerStyle` is a composite Style — sub-
/// component (popover / dialog / hour-minute-second segment input /
/// am-pm toggle button) Style nested + label / description / error
/// text styles. chrome flat 필드는 모두 sub-component Style 으로
/// 흡수.
///
/// **Semantic enums (`mode` / `use24HourFormat`) and behaviour
/// fields (placeholder / enabled / showSeconds / min / max /
/// onChanged) live on the widget, not on this style** (Epic #1302
/// 원칙 6/7).
///
/// To change the **trigger button's variant** or use a custom dialog
/// action button, inject the widget directly via the dedicated slot
/// (asChild pattern, Epic #1302 원칙 8).
///
/// ```text
/// design system default
///   → CoreTimePickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.timePickerStyle                          // 인스턴스별
/// ```
///
/// ### Type parameters
///
/// - `Clr` — colour type (Flutter `Color`, Web `String`).
/// - `Shadow` — shadow type
///   (Flutter `List<BoxShadow>`, Web `String`).
@immutable
class CoreTimePickerStyle implements CoreStyle<CoreTimePickerStyle> {
  /// Creates a [CoreTimePickerStyle].
  const CoreTimePickerStyle({
    this.triggerStyle,
    this.popoverStyle,
    this.dialogStyle,
    this.segmentInputStyle,
    this.amPmToggleStyle,
    @Deprecated('Use amPmToggleStyle: CoreToggleGroupStyle(…) (since 0.174).')
    this.amPmButtonStyle,
    @Deprecated(
      'Use amPmToggleStyle: CoreToggleGroupStyle(selectedColor: …) '
      '(since 0.174).',
    )
    this.amPmSelectedButtonStyle,
    this.actionButtonStyle,
    this.labelStyle,
    this.descriptionStyle,
    this.errorStyle,
    this.segmentBorderColor,
    @Deprecated(
      'Not read — a hovered segment wears a state layer, not a border '
      'step; use segmentStateLayerColor / segmentStateLayer (since 0.175).',
    )
    this.segmentHoverBorderColor,
    this.segmentStateLayerColor,
    this.segmentStateLayer,
    this.segmentSurfaceColor,
    this.segmentContentColor,
    @Deprecated(
      'Not read — the edited segment takes an inside border; use '
      'segmentFocusedBorderColor / segmentFocusedBorderWidth (since 0.174).',
    )
    this.segmentFocusOutlineStyle,
    this.labelColor,
    this.contentColor,
    this.valueTypography,
    this.helperTypography,
    this.segmentBorderRadius,
    this.triggerHeight,
    this.triggerBorderWidth,
    @Deprecated('No longer read (since 0.174) — the trigger is a TextField.')
    this.triggerContentGapStyle,
    this.segmentSize,
    this.segmentHeight,
    this.segmentFocusedSurfaceColor,
    this.segmentFocusedContentColor,
    this.segmentFocusedBorderColor,
    this.segmentFocusedBorderWidth,
    this.dialogLabelSpacing,
    this.dialogOuterGapStyle,
    this.actionRowGapStyle,
    this.separatorPadding,
    this.separatorTypography,
    this.separatorColor,
    this.trailingIconStyle,
    @Deprecated(
      'Use triggerStyle: CoreTextFieldStyle(errorBorderColor: …) '
      '(since 0.174).',
    )
    this.errorTriggerStyle,
  });

  // ─── Design-system defaults ───────────────────
  // Trigger / popover surface scheme + typography. Both Flutter and
  // Web read these constants.

  /// Default trigger field slot — the trigger is a read-only `TextField`
  /// (the DatePicker / Select input look: height 40, corner 10, an
  /// `outline-variant` edge that turns `primary` on focus, a Regular 14
  /// value and a trailing clock), so the field's own `md` row supplies all
  /// of that and this default states only the one thing the picker
  /// diverges in — `stateLayer`: pressed only. Hover is the border stepping
  /// to `outline` and focus is the ring; a fill under either would say the
  /// same thing twice (the same decision `CoreSelectStyle.defaultTriggerStyle`
  /// records). Raw-forwarded to the composed field.
  static const CoreTextFieldStyle defaultTriggerStyle = CoreTextFieldStyle(
    stateLayer: CoreStateLayer(
      hover: CoreOpacity.opacity0,
      focus: CoreOpacity.opacity0,
      pressed: CoreOpacity.pressed,
    ),
  );

  /// Default popover style — the popover-mode panel box flows through
  /// the nested `panelStyle` ([CorePopupStyle]), the single source of
  /// truth for the floating surface. Carries only the TimePicker-specific
  /// override that diverges from `CorePopupStyle`'s defaults: `space16`
  /// content padding (the corner 12 and the `outlineVariant` edge are the
  /// popup's own, so they are left unset and filled by `Popup`'s resolver).
  /// The resolver merges the per-instance [popoverStyle] on top. The
  /// dialog-mode surface is the `Dialog` component's own panel
  /// ([dialogStyle]), not this.
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    panelStyle: CorePopupStyle(padding: CoreEdgeInsets.all(CoreSpace.space16)),
    // Field-trigger convention — the wrapper (and the field inside it)
    // fills the available inline axis; the trigger takes the width its
    // parent gives it.
    triggerSizing: .expand,
  );

  /// Default nested [CoreToggleGroupStyle] slot for the am/pm toggle — a
  /// partial stating only the track. The toggle sits on the popover panel
  /// (`surfaceBright`), which in Dark equals the group's own
  /// `surfaceContainer` track, so the track goes one step higher
  /// (`surfaceContainerHigh`). Every other field is the shared
  /// `ToggleGroup`'s own chrome, which this partial leaves to it.
  static const CoreToggleGroupStyle defaultAmPmToggleStyle =
      CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
      );

  /// Default *selected* am/pm button overlay — a transparent border
  /// matching the unselected outline button's stroke so the selected
  /// (borderless `primary`) button keeps the same layout footprint and
  /// the toggle never resizes when selection moves. Partial on purpose
  /// (divergent fields only) — everything else flows from
  /// [amPmButtonStyle] / the Button's own resolver.
  ///
  /// Not read by `TimePicker`: the am/pm choice is a `ToggleGroup`.
  @Deprecated('Use the amPmToggleStyle defaults (since 0.174).')
  static const CoreButtonStyle defaultAmPmSelectedButtonStyle = CoreButtonStyle(
    borderColor: .transparent,
    borderWidth: CoreStrokeWidth.stroke1,
  );

  /// Segment input resting border colour — transparent: the tile is a
  /// filled face ([defaultSegmentSurfaceColor]) with no edge of its own.
  /// The transparent border keeps the layout footprint of a caller who
  /// states a `segmentBorderColor`.
  static const CoreColor defaultSegmentBorderColor = CoreColor.transparent;

  /// Not read by `TimePicker`: a hovered segment wears a state layer
  /// ([defaultSegmentStateLayerColor] at [defaultSegmentStateLayer]'s hover
  /// weight laid over the tile), not a border step.
  @Deprecated(
    'Not read — a hovered segment wears a state layer '
    '(since 0.175).',
  )
  static const CoreColor defaultSegmentHoverBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Colour of the state layer laid over a segment tile — `onSurface`, the
  /// ink every control's layer is made of. It is laid over the tile
  /// whichever face the tile wears, the edited segment's
  /// [defaultSegmentFocusedSurfaceColor] included.
  static const CoreColor defaultSegmentStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Weights of the segment tile's state layer. Only `hover` is read —
  /// a segment is typed into, so focus is marked by the focused face and
  /// there is no pressed pose. [CoreStateLayer.subtle] — the ramp the
  /// kit's other light, unfilled controls read (Chip, the ghost and
  /// outlined Button); both faces under it are light surfaces.
  static const CoreStateLayer defaultSegmentStateLayer = CoreStateLayer.subtle;

  /// Segment input fill / surface colour.
  static const CoreColor defaultSegmentSurfaceColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Segment input content text colour.
  static const CoreColor defaultSegmentContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Not read by `TimePicker`: the segment being edited is marked by an
  /// inside border ([defaultSegmentFocusedBorderColor]), not an outer ring.
  ///
  /// Default segment focus ring — the slice of `FocusOutline`'s style
  /// this component owns. Only the colour is stated: `align` /
  /// `borderWidth` / `duration` say nothing here so they defer to
  /// `FocusOutline`'s own defaults, and `borderRadius` is filled by the
  /// platform resolvers because it is not a constant — the ring follows
  /// [defaultSegmentBorderRadius] (or whatever `segmentBorderRadius`
  /// override is in effect). `offsetColor` is left to the default
  /// transparent band: the segment sits on the popover panel, a known
  /// background, so the gap simply shows the panel.
  @Deprecated(
    'Not read — the edited segment takes an inside border; use '
    'defaultSegmentFocusedBorderColor (since 0.174).',
  )
  static const CoreFocusOutlineStyle defaultSegmentFocusOutlineStyle =
      CoreFocusOutlineStyle(borderColor: CoreColor.token(CoreColors.primary));

  /// Segment label / description text colour (muted).
  static const CoreColor defaultLabelColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Trigger content (selected value) text colour.
  static const CoreColor defaultContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Trigger placeholder text colour.
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default trailing (clock) icon style — 16px to match the sibling
  /// field-trigger convention (`Select` / `DatePicker`). The clock is an
  /// affordance that opens the dial, so it takes the icon tone
  /// (`onSurfaceVariant`), not the placeholder text tone, and not the value
  /// colour ([defaultContentColor]). Without a size the glyph falls back to
  /// the 24px `Icon` default and renders oversized for the trigger.
  static const CoreIconStyle defaultTrailingIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Trigger chrome while the picker holds an error — an `outline` button
  /// whose edge and focus ring turn `error`, the way a text field's error
  /// look does. The fill, the label colour and the hover / pressed wash
  /// stay the outline variant's own, so an invalid field reads as the same
  /// field with an error edge rather than as an action button.
  ///
  /// The trigger is a composed `Button`, which owns the fill, the wash and
  /// the disabled look; this states only what the error changes — the
  /// edge (idle and hovered; a pressed button takes the hover edge) and the
  /// focus ring. The per-instance [errorTriggerStyle] merges on top, and
  /// `popoverStyle.triggerStyle` (the chrome shared by every state) sits
  /// under both. The widgets hand this bundle to the button only while the
  /// picker is enabled: per-instance chrome outranks a variant's disabled
  /// colours, so a disabled picker takes the button's own disabled row.
  ///
  /// Read for its `borderColor` only: the trigger is a `TextField`, and the
  /// error edge is the field's `errorBorderColor`.
  static const CoreButtonStyle defaultErrorTriggerStyle = CoreButtonStyle(
    borderColor: CoreColor.token(CoreColors.error),
    hoverBorderColor: CoreColor.token(CoreColors.error),
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// Default error text colour.
  static const CoreColor defaultErrorColor = CoreColor.token(CoreColors.error);

  /// Segment input border radius.
  static const CoreBorderRadius defaultSegmentBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius10);

  /// Trigger height — matches Web `h-${CoreSpace.scale.space40}`.
  static const double defaultTriggerHeight = CoreSpace.space40;

  /// Trigger / segment border width — matches Web `border` (1px).
  static const double defaultTriggerBorderWidth = CoreStrokeWidth.stroke1;

  /// Default nested [CoreGapStyle] slot for the gap between text and
  /// trailing icon inside the trigger — size matches the historical
  /// `CoreSpace.space8` scalar. Both Flutter and Web resolvers merge
  /// per-instance [triggerContentGapStyle] on top of this default and
  /// fold the resulting slot into the trigger `Button`'s nested
  /// `iconLabelGapStyle`.
  ///
  /// Not read by `TimePicker`: the trigger is a `TextField`.
  @Deprecated('Not read — the field owns the gap (since 0.174).')
  static const CoreGapStyle defaultTriggerContentGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Width of each numeric segment field inside the popover.
  static const double defaultSegmentSize = CoreSpace.space64;

  /// Height of each numeric segment field inside the popover. The AM/PM
  /// column beside it (a vertical `sm` ToggleGroup, top-aligned to the
  /// segments) is the same 60 by its own segments (3 + 26 + 2 + 26 + 3) —
  /// this value does not size it.
  static const double defaultSegmentHeight = CoreSpace.space60;

  /// Fill of the segment being edited. The face alone does not mark the
  /// segment — its contrast against the resting tile depends on the theme —
  /// so the edited segment also wears [defaultSegmentFocusedBorderColor].
  static const CoreColor defaultSegmentFocusedSurfaceColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Text colour on the edited segment's [defaultSegmentFocusedSurfaceColor].
  static const CoreColor defaultSegmentFocusedContentColor = CoreColor.token(
    CoreColors.onPrimaryContainer,
  );

  /// Border of the segment being edited — the segment's focus mark, drawn
  /// INSIDE the tile in place of its resting border, for a pointer focus as
  /// much as a keyboard one (the focused segment is where the next digit
  /// lands).
  ///
  /// Inside, not the kit's outer focus ring: the segments sit next to each
  /// other inside the popover, so a ring outside one would cover its
  /// neighbour or be clipped at the popover edge (the Material 3 time input
  /// marks its field the same way). This border is the segment's only focus
  /// mark; the trigger field's ring belongs to another element.
  ///
  /// `primaryText`, not `primary`: it holds 3:1 on the
  /// [defaultSegmentFocusedSurfaceColor] face in every brand and mode.
  static const CoreColor defaultSegmentFocusedBorderColor = CoreColor.token(
    CoreColors.primaryText,
  );

  /// Width of [defaultSegmentFocusedBorderColor]'s inside border. The tile
  /// keeps its size; the border eats into it.
  static const double defaultSegmentFocusedBorderWidth =
      CoreStrokeWidth.stroke2;

  /// Default uniform spacing between the segment field and its label
  /// (Flutter `Column.spacing` / Web inline `margin-top`). Used by both
  /// Flutter and Web resolvers.
  static const double defaultDialogLabelSpacing = CoreSpace.space4;

  /// Default nested [CoreGapStyle] slot for the horizontal gap between
  /// the time segment row and the AM/PM column — size matches the
  /// historical `CoreSpace.space16` scalar. Both Flutter and Web
  /// resolvers merge per-instance [dialogOuterGapStyle] on top of this
  /// default and forward the resulting slot (Flutter → `Gap` width,
  /// Web → inline spacer width derived from `size`).
  static const CoreGapStyle defaultDialogOuterGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default nested [CoreGapStyle] slot for the vertical gap between
  /// the segment row and the action button row (also used between the
  /// optional title and the segment row) — size matches the historical
  /// `CoreSpace.space16` scalar. Both Flutter and Web resolvers merge
  /// per-instance [actionRowGapStyle] on top of this default and
  /// forward the resulting slot (Flutter → `Gap` height, Web →
  /// inline `margin-top` derived from `size`).
  static const CoreGapStyle defaultActionRowGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Padding around the segment separator (`:`) glyph (symmetric
  /// horizontal — axis intent encoded inside the
  /// [CoreEdgeInsets.symmetric] constructor) and am/pm trailing row
  /// spacing.
  static const CoreEdgeInsets defaultSeparatorPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8);

  /// Segment separator (`:`) typography — the 24px `headlineSmall` role at
  /// `medium`. Its own field rather than [defaultValueTypography]: the colon
  /// is punctuation between the digits, so it reads lighter and smaller than
  /// the digits it separates. The role carries size, line height and
  /// tracking; only the weight is stated on top.
  static final CoreTextStyle defaultSeparatorTypography =
      const CoreTextStyle.token(
        CoreTextStyles.headlineSmall,
      ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Segment separator (`:`) colour — `onSurfaceSubtle`, a step quieter than
  /// the digits' [defaultSegmentContentColor].
  static const CoreColor defaultSeparatorColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Segment numeric typography role — `CoreTypography.coui.headlineMedium`
  /// (28 Bold, a 39 px line). The segment is a 64 × 60 cell whose edited pose
  /// draws a 2 px inside border, so the digits have to leave about 8 inside
  /// that border on every side: `displaySmall` (44, a 62 px line) overran the
  /// cell and the border touched "30" (#6201). It stays a step above the
  /// separator's `headlineSmall` (24), so the digits still lead.
  static final CoreTextStyle defaultValueTypography =
      CoreTypography.coui.headlineMedium;

  /// Trigger label typography role — `CoreTypography.coui.labelLarge`.
  static final CoreTextStyle defaultLabelTypography =
      CoreTypography.coui.labelLarge;

  /// Helper / description / error text typography role —
  /// `CoreTypography.coui.bodySmall`.
  static final CoreTextStyle defaultHelperTypography =
      CoreTypography.coui.bodySmall;

  /// AM/PM button label typography role —
  /// `CoreTypography.coui.titleMedium`.
  static final CoreTextStyle defaultAmPmTypography =
      CoreTypography.coui.titleMedium;

  // ── Slot Styles (nested) ─────────────────────

  /// Popover style for the popover-mode picker — the look of its dropdown
  /// (its trigger part is not read; see [triggerStyle]).
  final CorePopoverStyle? popoverStyle;

  /// Dialog style for the modal-mode picker — the look of its panel, title
  /// and action buttons.
  ///
  /// **No default, and must not have one.** Both platforms forward this
  /// slot to `Dialog(dialogStyle: …)` unchanged, so null is what lets
  /// `Dialog` resolve its own panel — the single source for that surface.
  /// A constant here would be a second copy of `Dialog`'s panel defaults,
  /// and because a slot override outranks the child's own baseline it
  /// would also win over them for every picker dialog.
  ///
  /// The asymmetry with [defaultPopoverStyle] is the point: popover mode
  /// *diverges* from `Popup` (radius16 / outlineVariant / padding16) and
  /// that divergence is what the default states. Dialog mode diverges in
  /// nothing, so it states nothing.
  final CoreDialogStyle? dialogStyle;

  /// Style applied to each hour / minute / second segment input
  /// (TextField inside the picker panel).
  ///
  /// **No default, and must not have one.** This slot is the top of two
  /// precedence chains that already end at named Core defaults:
  ///
  /// ```text
  /// …?.borderColor
  ///     ?? segmentBorderColor ?? defaultSegmentBorderColor
  /// …?.valueStyle
  ///     ?? valueTypography ?? defaultValueTypography
  /// ```
  ///
  /// The baseline exists — under those names. Giving this slot a
  /// non-null default would insert it *above* the flat overrides in both
  /// chains, so `segmentBorderColor` and
  /// `valueTypography` would stop being reachable: a caller setting either
  /// would see no change. That is a dead parameter, not a repaint.
  final CoreTextFieldStyle? segmentInputStyle;

  /// Style applied to the am/pm toggle button when
  /// `use24HourFormat: false`. `null` leaves the button at its variant's
  /// look.
  ///
  /// **No default, and must not have one.** Raw-forwarded to
  /// `Button(buttonStyle: …)` on both platforms, where null means the
  /// button paints its variant. A constant would outrank
  /// `CoreButtonStyle.defaultsByVariant` inside `Button`'s resolver and
  /// repaint the toggle.
  ///
  /// [defaultAmPmSelectedButtonStyle] exists for the sibling slot because
  /// the selected button genuinely diverges — it needs a transparent
  /// border so selection does not resize the toggle. This slot has no
  /// such divergence to state.
  @Deprecated('Use amPmToggleStyle — am/pm is a ToggleGroup (since 0.174).')
  final CoreButtonStyle? amPmButtonStyle;

  /// Style applied to the *selected* am/pm toggle button, layered on
  /// top of [amPmButtonStyle]. The default carries a transparent
  /// border matching the unselected outline button's stroke, so the
  /// selected (borderless `primary`) button occupies the same layout
  /// footprint and the toggle never resizes when selection moves.
  @Deprecated('Use amPmToggleStyle — am/pm is a ToggleGroup (since 0.174).')
  final CoreButtonStyle? amPmSelectedButtonStyle;

  /// Style of the am/pm `ToggleGroup` shown in the panel when
  /// `use24HourFormat: false` — the shared grouped toggle (a track with a
  /// raised chosen face), merged over [defaultAmPmToggleStyle] and passed
  /// to `ToggleGroup(toggleGroupStyle: …)` as is.
  final CoreToggleGroupStyle? amPmToggleStyle;

  /// Look of the trigger — the read-only `TextField` the picker shows. Laid
  /// over [defaultTriggerStyle] and passed to the field as is. The value
  /// colour ([contentColor]) and placeholder tone sit under it, so this
  /// style wins over them. The clock glyph is styled by
  /// [trailingIconStyle] alone. An explicit `popoverStyle.triggerStyle`
  /// styled the earlier button trigger and is not read.
  final CoreTextFieldStyle? triggerStyle;

  /// Style merged into the Cancel / Save action buttons of the
  /// popover / dialog panel — single shared slot, mirroring
  /// `CoreDialogStyle.actionButtonStyle`.
  ///
  /// **No default, and must not have one**, for the same reason as
  /// `CoreDialogStyle.actionButtonStyle`: one slot feeds both buttons,
  /// Cancel is `.ghost` and Save is the filled default, and a value named
  /// here outranks `CoreButtonStyle.defaultsByVariant` in `Button`'s
  /// resolver. A single constant would therefore paint the two buttons
  /// alike and erase the distinction they exist to draw.
  final CoreButtonStyle? actionButtonStyle;

  /// Label text style (text shown above the trigger).
  ///
  /// **Read by no resolver and no widget — wire it or remove it.** Left
  /// untouched (deleting a public field is breaking and not mine to
  /// decide). Nobody reads it on either platform: both resolvers only
  /// author it into `ResolvedTimePicker` (`labelStyle:
  /// merged.labelStyle`) and neither widget ever reads
  /// `resolved.labelStyle` — `grep -rn 'resolved.labelStyle'
  /// packages/coui_{web,flutter}/lib` over time_picker returns nothing.
  /// The root cause is that `TimePicker` has no `label` parameter on
  /// either platform, so there is no label element to style; the segment
  /// captions inside the panel are styled by `helperTypography` +
  /// `labelColor` instead. Either the component gains a `label` slot and
  /// this styles it, or the field is dropped at the next breaking release
  /// — a decision about the component's API, not about a default.
  final CoreTextStyle? labelStyle;

  /// Description / helper text style.
  ///
  /// **Read by no resolver and no widget — wire it or remove it.** Left
  /// untouched. Same as `labelStyle`: authored into both
  /// `ResolvedTimePicker`s, read by neither widget, and `TimePicker` has
  /// no `description` parameter on either platform, so no description
  /// text is rendered at all. Wire it (add the slot) or drop it in a
  /// breaking release.
  final CoreTextStyle? descriptionStyle;

  /// Error text style.
  ///
  /// **Read by no resolver and no widget — wire it or remove it.** Left
  /// untouched. Authored into both `ResolvedTimePicker`s and read by
  /// neither widget. `TimePicker` does take `errorText`, but it only
  /// drives the trigger's error border colour (`hasError` at
  /// time_picker.dart:320-321 Flutter / 622-623 Web) — no error *text* is
  /// ever rendered, so there is nothing for a text style to apply to.
  /// Either the component renders the message (then this styles it) or
  /// the field goes in a breaking release.
  final CoreTextStyle? errorStyle;

  /// Custom segment input border colour. Falls back to
  /// [defaultSegmentBorderColor] when null.
  final CoreColor? segmentBorderColor;

  /// Not read — a hovered segment wears a state layer, not a border step.
  /// Use [segmentStateLayerColor] / [segmentStateLayer].
  @Deprecated(
    'Not read — a hovered segment wears a state layer '
    '(since 0.175).',
  )
  final CoreColor? segmentHoverBorderColor;

  /// Custom colour of the state layer laid over a segment tile while the
  /// pointer is over it. Falls back to [defaultSegmentStateLayerColor]
  /// when null. The layer covers the tile's own shape (size and corner)
  /// over whichever face it wears and changes neither the face colour nor
  /// the border.
  final CoreColor? segmentStateLayerColor;

  /// Custom weights of the segment tile's state layer (only `hover` is
  /// read). Falls back to [defaultSegmentStateLayer] when null.
  final CoreStateLayer? segmentStateLayer;

  /// Custom segment input fill / surface colour. Falls back to
  /// [defaultSegmentSurfaceColor] when null.
  final CoreColor? segmentSurfaceColor;

  /// Custom segment input content text colour. Falls back to
  /// [defaultSegmentContentColor] when null.
  final CoreColor? segmentContentColor;

  /// Segment focus ring override. `null` defers to
  /// [defaultSegmentFocusOutlineStyle], and a field left null inside it
  /// defers to `CoreFocusOutlineStyle`'s own default.
  ///
  /// Geometry is stated as `borderWidth` plus `align` (the ring's total
  /// outset), not as a width/offset pair — the gap between the segment and
  /// the ring is `align - borderWidth`.
  ///
  /// Both platforms draw the ring the same way — a composed
  /// `FocusOutline` wrapping the segment box — so the slot reaches the
  /// same seven fields on each: `borderColor`, `borderWidth`, `align`,
  /// `offsetColor`, `ringOpacity`, `borderRadius`, `duration`.
  ///
  /// `circleBorderRadius` is the eighth and reaches neither. It is read
  /// only when the ring's shape is a circle, and a time segment is a
  /// rectangle — the two radius fields are mutually exclusive by shape,
  /// so no single instance can reach both. A rectangle taking a circle's
  /// radius would be the bug; this is the correct outcome, not a gap to
  /// close.
  @Deprecated(
    'Not read — the edited segment takes an inside border, not a ring; use '
    'segmentFocusedBorderColor / segmentFocusedBorderWidth (since 0.174).',
  )
  final CoreFocusOutlineStyle? segmentFocusOutlineStyle;

  /// Custom segment label / description text colour. Falls back to
  /// [defaultLabelColor] when null.
  final CoreColor? labelColor;

  /// Custom trigger content text colour. Falls back to
  /// [defaultContentColor] when null. The segment separator has its own
  /// [separatorColor].
  final CoreColor? contentColor;

  /// Custom trigger value / segment numeric typography role. Falls back
  /// to [defaultValueTypography] when null.
  final CoreTextStyle? valueTypography;

  /// Custom helper / segment-label typography role. Falls back to
  /// [defaultHelperTypography] when null.
  final CoreTextStyle? helperTypography;

  /// Custom segment input border radius (pre-scaling).
  final CoreBorderRadius? segmentBorderRadius;

  /// Custom trigger height (pre-scaling) — forwarded as the trigger field's
  /// `height`. `null` → the field's own `md` row (40).
  final double? triggerHeight;

  /// Custom trigger / segment border width (pre-scaling).
  final double? triggerBorderWidth;

  /// Style of the gap between the trigger text and the trailing icon, for
  /// the earlier `Button` trigger (its `iconLabelGapStyle`), merged on top
  /// of [defaultTriggerContentGapStyle].
  @Deprecated('Not read — the field owns the gap (since 0.174).')
  final CoreGapStyle? triggerContentGapStyle;

  /// Custom width of each numeric segment field (pre-scaling). Falls back
  /// to [defaultSegmentSize] when null.
  final double? segmentSize;

  /// Custom height of each numeric segment field (pre-scaling). The AM/PM
  /// column beside it keeps the ToggleGroup's own height. Falls back to
  /// [defaultSegmentHeight] when null.
  final double? segmentHeight;

  /// Custom fill of the segment being edited. Falls back to
  /// [defaultSegmentFocusedSurfaceColor] when null.
  final CoreColor? segmentFocusedSurfaceColor;

  /// Custom text colour of the segment being edited. Falls back to
  /// [defaultSegmentFocusedContentColor] when null.
  final CoreColor? segmentFocusedContentColor;

  /// Custom border colour of the segment being edited (drawn inside the
  /// tile). Falls back to [defaultSegmentFocusedBorderColor] when null.
  final CoreColor? segmentFocusedBorderColor;

  /// Custom width of the edited segment's inside border (pre-scaling,
  /// treated like the resting [triggerBorderWidth] stroke). Falls back to
  /// [defaultSegmentFocusedBorderWidth] when null.
  final double? segmentFocusedBorderWidth;

  /// Uniform spacing between the segment field and its label (Flutter
  /// `Column.spacing` / Web inline `margin-top`). Falls back to
  /// [defaultDialogLabelSpacing] when null.
  final double? dialogLabelSpacing;

  /// Style of the horizontal `Gap` between the segment row and the AM/PM
  /// column. Merged on top of [defaultDialogOuterGapStyle].
  final CoreGapStyle? dialogOuterGapStyle;

  /// Style of the vertical `Gap` between the segment row and the action
  /// button row (also used between the optional title and the segment
  /// row). Merged on top of [defaultActionRowGapStyle].
  final CoreGapStyle? actionRowGapStyle;

  /// Custom padding around the segment separator glyph (pre-scaling).
  final CoreEdgeInsets? separatorPadding;

  /// Custom segment separator (`:`) typography. Falls back to
  /// [defaultSeparatorTypography] when null.
  final CoreTextStyle? separatorTypography;

  /// Custom segment separator (`:`) colour. Falls back to
  /// [defaultSeparatorColor] when null.
  final CoreColor? separatorColor;

  /// Trigger trailing (clock) icon style override.
  /// `null` → [defaultTrailingIconStyle].
  final CoreIconStyle? trailingIconStyle;

  /// Trigger border colour while the picker holds an error (the rest of the
  /// button bundle is not read — the trigger is a `TextField`, whose error
  /// look is its own). Merged on top of [defaultErrorTriggerStyle] and
  /// folded in as the field's `errorBorderColor`; `triggerStyle` outranks it.
  @Deprecated('Use triggerStyle.errorBorderColor (since 0.174).')
  final CoreButtonStyle? errorTriggerStyle;

  /// The field chrome the picker forwards to its read-only trigger
  /// `TextField`: [triggerStyle] over [defaultTriggerStyle], with what is the
  /// picker's own decision folded in underneath — the explicit
  /// [triggerHeight], the value's [contentColor] and the placeholder tone (the
  /// clock takes the same one), and, from the deprecated [errorTriggerStyle],
  /// its border colour as the field's error edge. One function so both
  /// platforms fold identically; the field resolver fills what is still
  /// `null`.
  CoreTextFieldStyle get effectiveTriggerStyle => _foldTrigger(enabled: true);

  /// The same trigger chrome for a disabled picker — without the two text
  /// colours [effectiveTriggerStyle] folds in, so the field's own disabled tone
  /// applies (an explicit colour on `valueStyle` / `placeholderStyle` would win
  /// over it).
  CoreTextFieldStyle get effectiveDisabledTriggerStyle =>
      _foldTrigger(enabled: false);

  CoreTextFieldStyle _foldTrigger({required bool enabled}) {
    return defaultTriggerStyle
        .merge(
          CoreTextFieldStyle(
            height: triggerHeight,
            errorBorderColor: defaultErrorTriggerStyle
                .merge(errorTriggerStyle)
                .borderColor,
            valueStyle: enabled
                ? CoreTextStyle(color: contentColor ?? defaultContentColor)
                : null,
            placeholderStyle: enabled
                ? const CoreTextStyle(color: defaultPlaceholderColor)
                : null,
          ),
        )
        .merge(triggerStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreTimePickerStyle merge(CoreTimePickerStyle? other) {
    if (other == null) return this;
    return CoreTimePickerStyle(
      triggerStyle: _mergeTextField(triggerStyle, other.triggerStyle),
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      dialogStyle: _mergeDialog(dialogStyle, other.dialogStyle),
      segmentInputStyle: _mergeTextField(
        segmentInputStyle,
        other.segmentInputStyle,
      ),
      amPmToggleStyle: _mergeToggle(amPmToggleStyle, other.amPmToggleStyle),
      amPmButtonStyle: _mergeButton(amPmButtonStyle, other.amPmButtonStyle),
      amPmSelectedButtonStyle: _mergeButton(
        amPmSelectedButtonStyle,
        other.amPmSelectedButtonStyle,
      ),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      errorStyle: _mergeText(errorStyle, other.errorStyle),
      segmentBorderColor: other.segmentBorderColor ?? segmentBorderColor,
      segmentHoverBorderColor:
          other.segmentHoverBorderColor ?? segmentHoverBorderColor,
      segmentStateLayerColor:
          other.segmentStateLayerColor ?? segmentStateLayerColor,
      segmentStateLayer: other.segmentStateLayer ?? segmentStateLayer,
      segmentSurfaceColor: other.segmentSurfaceColor ?? segmentSurfaceColor,
      segmentContentColor: other.segmentContentColor ?? segmentContentColor,
      segmentFocusOutlineStyle: _mergeFocusOutline(
        segmentFocusOutlineStyle,
        other.segmentFocusOutlineStyle,
      ),
      labelColor: other.labelColor ?? labelColor,
      contentColor: other.contentColor ?? contentColor,
      valueTypography: _mergeText(valueTypography, other.valueTypography),
      helperTypography: _mergeText(helperTypography, other.helperTypography),
      segmentBorderRadius: other.segmentBorderRadius ?? segmentBorderRadius,
      triggerHeight: other.triggerHeight ?? triggerHeight,
      triggerBorderWidth: other.triggerBorderWidth ?? triggerBorderWidth,
      triggerContentGapStyle: _mergeGap(
        triggerContentGapStyle,
        other.triggerContentGapStyle,
      ),
      segmentSize: other.segmentSize ?? segmentSize,
      segmentHeight: other.segmentHeight ?? segmentHeight,
      segmentFocusedSurfaceColor:
          other.segmentFocusedSurfaceColor ?? segmentFocusedSurfaceColor,
      segmentFocusedContentColor:
          other.segmentFocusedContentColor ?? segmentFocusedContentColor,
      segmentFocusedBorderColor:
          other.segmentFocusedBorderColor ?? segmentFocusedBorderColor,
      segmentFocusedBorderWidth:
          other.segmentFocusedBorderWidth ?? segmentFocusedBorderWidth,
      dialogLabelSpacing: other.dialogLabelSpacing ?? dialogLabelSpacing,
      dialogOuterGapStyle: _mergeGap(
        dialogOuterGapStyle,
        other.dialogOuterGapStyle,
      ),
      actionRowGapStyle: _mergeGap(actionRowGapStyle, other.actionRowGapStyle),
      separatorPadding: other.separatorPadding ?? separatorPadding,
      separatorTypography: _mergeText(
        separatorTypography,
        other.separatorTypography,
      ),
      separatorColor: other.separatorColor ?? separatorColor,
      trailingIconStyle:
          trailingIconStyle?.merge(other.trailingIconStyle) ??
          other.trailingIconStyle,
      errorTriggerStyle: _mergeButton(
        errorTriggerStyle,
        other.errorTriggerStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTimePickerStyle copyWith({
    CoreTextFieldStyle? triggerStyle,
    CorePopoverStyle? popoverStyle,
    CoreDialogStyle? dialogStyle,
    CoreTextFieldStyle? segmentInputStyle,
    CoreToggleGroupStyle? amPmToggleStyle,
    CoreButtonStyle? amPmButtonStyle,
    CoreButtonStyle? amPmSelectedButtonStyle,
    CoreButtonStyle? actionButtonStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? errorStyle,
    CoreColor? segmentBorderColor,
    CoreColor? segmentHoverBorderColor,
    CoreColor? segmentStateLayerColor,
    CoreStateLayer? segmentStateLayer,
    CoreColor? segmentSurfaceColor,
    CoreColor? segmentContentColor,
    CoreFocusOutlineStyle? segmentFocusOutlineStyle,
    CoreColor? labelColor,
    CoreColor? contentColor,
    CoreTextStyle? valueTypography,
    CoreTextStyle? helperTypography,
    CoreBorderRadius? segmentBorderRadius,
    double? triggerHeight,
    double? triggerBorderWidth,
    CoreGapStyle? triggerContentGapStyle,
    double? segmentSize,
    double? segmentHeight,
    CoreColor? segmentFocusedSurfaceColor,
    CoreColor? segmentFocusedContentColor,
    CoreColor? segmentFocusedBorderColor,
    double? segmentFocusedBorderWidth,
    double? dialogLabelSpacing,
    CoreGapStyle? dialogOuterGapStyle,
    CoreGapStyle? actionRowGapStyle,
    CoreEdgeInsets? separatorPadding,
    CoreTextStyle? separatorTypography,
    CoreColor? separatorColor,
    CoreIconStyle? trailingIconStyle,
    CoreButtonStyle? errorTriggerStyle,
  }) {
    return CoreTimePickerStyle(
      triggerStyle: triggerStyle ?? this.triggerStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      segmentInputStyle: segmentInputStyle ?? this.segmentInputStyle,
      amPmToggleStyle: amPmToggleStyle ?? this.amPmToggleStyle,
      amPmButtonStyle: amPmButtonStyle ?? this.amPmButtonStyle,
      amPmSelectedButtonStyle:
          amPmSelectedButtonStyle ?? this.amPmSelectedButtonStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      segmentBorderColor: segmentBorderColor ?? this.segmentBorderColor,
      segmentHoverBorderColor:
          segmentHoverBorderColor ?? this.segmentHoverBorderColor,
      segmentStateLayerColor:
          segmentStateLayerColor ?? this.segmentStateLayerColor,
      segmentStateLayer: segmentStateLayer ?? this.segmentStateLayer,
      segmentSurfaceColor: segmentSurfaceColor ?? this.segmentSurfaceColor,
      segmentContentColor: segmentContentColor ?? this.segmentContentColor,
      segmentFocusOutlineStyle:
          segmentFocusOutlineStyle ?? this.segmentFocusOutlineStyle,
      labelColor: labelColor ?? this.labelColor,
      contentColor: contentColor ?? this.contentColor,
      valueTypography: valueTypography ?? this.valueTypography,
      helperTypography: helperTypography ?? this.helperTypography,
      segmentBorderRadius: segmentBorderRadius ?? this.segmentBorderRadius,
      triggerHeight: triggerHeight ?? this.triggerHeight,
      triggerBorderWidth: triggerBorderWidth ?? this.triggerBorderWidth,
      triggerContentGapStyle:
          triggerContentGapStyle ?? this.triggerContentGapStyle,
      segmentSize: segmentSize ?? this.segmentSize,
      segmentHeight: segmentHeight ?? this.segmentHeight,
      segmentFocusedSurfaceColor:
          segmentFocusedSurfaceColor ?? this.segmentFocusedSurfaceColor,
      segmentFocusedContentColor:
          segmentFocusedContentColor ?? this.segmentFocusedContentColor,
      segmentFocusedBorderColor:
          segmentFocusedBorderColor ?? this.segmentFocusedBorderColor,
      segmentFocusedBorderWidth:
          segmentFocusedBorderWidth ?? this.segmentFocusedBorderWidth,
      dialogLabelSpacing: dialogLabelSpacing ?? this.dialogLabelSpacing,
      dialogOuterGapStyle: dialogOuterGapStyle ?? this.dialogOuterGapStyle,
      actionRowGapStyle: actionRowGapStyle ?? this.actionRowGapStyle,
      separatorPadding: separatorPadding ?? this.separatorPadding,
      separatorTypography: separatorTypography ?? this.separatorTypography,
      separatorColor: separatorColor ?? this.separatorColor,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      errorTriggerStyle: errorTriggerStyle ?? this.errorTriggerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTimePickerStyle &&
          runtimeType == other.runtimeType &&
          triggerStyle == other.triggerStyle &&
          popoverStyle == other.popoverStyle &&
          dialogStyle == other.dialogStyle &&
          segmentInputStyle == other.segmentInputStyle &&
          amPmToggleStyle == other.amPmToggleStyle &&
          amPmButtonStyle == other.amPmButtonStyle &&
          amPmSelectedButtonStyle == other.amPmSelectedButtonStyle &&
          actionButtonStyle == other.actionButtonStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          errorStyle == other.errorStyle &&
          segmentBorderColor == other.segmentBorderColor &&
          segmentHoverBorderColor == other.segmentHoverBorderColor &&
          segmentStateLayerColor == other.segmentStateLayerColor &&
          segmentStateLayer == other.segmentStateLayer &&
          segmentSurfaceColor == other.segmentSurfaceColor &&
          segmentContentColor == other.segmentContentColor &&
          segmentFocusOutlineStyle == other.segmentFocusOutlineStyle &&
          labelColor == other.labelColor &&
          contentColor == other.contentColor &&
          valueTypography == other.valueTypography &&
          helperTypography == other.helperTypography &&
          segmentBorderRadius == other.segmentBorderRadius &&
          triggerHeight == other.triggerHeight &&
          triggerBorderWidth == other.triggerBorderWidth &&
          triggerContentGapStyle == other.triggerContentGapStyle &&
          segmentSize == other.segmentSize &&
          segmentHeight == other.segmentHeight &&
          segmentFocusedSurfaceColor == other.segmentFocusedSurfaceColor &&
          segmentFocusedContentColor == other.segmentFocusedContentColor &&
          segmentFocusedBorderColor == other.segmentFocusedBorderColor &&
          segmentFocusedBorderWidth == other.segmentFocusedBorderWidth &&
          dialogLabelSpacing == other.dialogLabelSpacing &&
          dialogOuterGapStyle == other.dialogOuterGapStyle &&
          actionRowGapStyle == other.actionRowGapStyle &&
          separatorPadding == other.separatorPadding &&
          separatorTypography == other.separatorTypography &&
          separatorColor == other.separatorColor &&
          trailingIconStyle == other.trailingIconStyle &&
          errorTriggerStyle == other.errorTriggerStyle;

  @override
  int get hashCode => Object.hashAll([
    triggerStyle,
    popoverStyle,
    dialogStyle,
    segmentInputStyle,
    amPmToggleStyle,
    amPmButtonStyle,
    amPmSelectedButtonStyle,
    actionButtonStyle,
    labelStyle,
    descriptionStyle,
    errorStyle,
    segmentBorderColor,
    segmentHoverBorderColor,
    segmentStateLayerColor,
    segmentStateLayer,
    segmentSurfaceColor,
    segmentContentColor,
    segmentFocusOutlineStyle,
    labelColor,
    contentColor,
    valueTypography,
    helperTypography,
    segmentBorderRadius,
    triggerHeight,
    triggerBorderWidth,
    triggerContentGapStyle,
    segmentSize,
    segmentHeight,
    segmentFocusedSurfaceColor,
    segmentFocusedContentColor,
    segmentFocusedBorderColor,
    segmentFocusedBorderWidth,
    dialogLabelSpacing,
    dialogOuterGapStyle,
    actionRowGapStyle,
    separatorPadding,
    separatorTypography,
    separatorColor,
    trailingIconStyle,
    errorTriggerStyle,
  ]);

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
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

  static CoreTextFieldStyle? _mergeTextField(
    CoreTextFieldStyle? base,
    CoreTextFieldStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreToggleGroupStyle? _mergeToggle(
    CoreToggleGroupStyle? base,
    CoreToggleGroupStyle? other,
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

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
