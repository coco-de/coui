/// Per-instance style for `Popover`.
library;

import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/popover/core_popover_collision.dart';
import 'package:coui_core/src/component/contracts/popover/core_popover_placement.dart';
import 'package:coui_core/src/component/contracts/popover/popover_trigger_sizing.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/stacking/z_index_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Popover` should render.
///
/// Popover-specific layout and behaviour overrides live as flat fields.
/// Panel chrome flows through the nested [panelStyle] ([CorePopupStyle])
/// slot — the floating panel box (background, border, radius, shadow,
/// padding, min-width, content colour) is not re-declared here, since it
/// is a single source of truth in `Popup`. A popover composes `Popup`
/// for its panel and forwards this slot raw (child-component-composition
/// rule). [defaultPanelStyle] carries only the two deliberate
/// popover-specific overrides (content padding and content sizing);
/// every other field inherits `CorePopupStyle`'s default. The trigger
/// chrome flows through the nested [triggerStyle] ([CoreButtonStyle])
/// slot.
///
/// Semantic enums live on the widget, not on this style.
///
/// The merge chain runs design-system default, then
/// `CorePopoverTheme.style`, then any parent component slot override
/// (e.g. `CoreSelectStyle.popoverStyle` when the popover is the Select
/// dropdown panel chrome), then `widget.popoverStyle`.
@immutable
class CorePopoverStyle implements CoreStyle<CorePopoverStyle> {
  /// Creates a [CorePopoverStyle].
  const CorePopoverStyle({
    this.panelStyle,
    this.placementOffset,
    this.viewportPadding,
    this.triggerSizing,
    this.openAnimationDuration,
    this.closeAnimationDuration,
    this.triggerStyle,
  });

  // ── Design-system defaults ───────────────────
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers. Popover has no visual variant so
  // there is no `defaultsByVariant` map.

  /// Default panel chrome — composed `Popup`'s panel box is the single
  /// source of truth, so this carries only the two deliberate
  /// popover-specific overrides:
  ///
  /// * `padding` = 16 logical px on all sides (popovers wrap arbitrary
  ///   content that needs breathing room, unlike a dropdown panel whose
  ///   items carry their own padding).
  /// * `minWidth` = 0 (a popover sizes to its content; it is not
  ///   min-width-clamped like a dropdown panel's `CorePopupStyle`
  ///   default of 128).
  ///
  /// Every other panel field (background / border / radius / shadow /
  /// content colour / border width) is left `null` so `Popup`'s resolver
  /// fills it from [CorePopupStyle]'s own defaults — the single source.
  static const CorePopupStyle defaultPanelStyle = CorePopupStyle(
    padding: CoreEdgeInsets.all(CoreSpace.space16),
    minWidth: 0,
  );

  /// Default trigger-to-panel placement offset (4 logical px) — applied
  /// along the placement axis (top/bottom or left/right depending on
  /// `CorePopoverPlacement`) to push the floating panel away from the
  /// trigger edge. The same distance every floating panel keeps from its
  /// trigger (`NavigationMenu`, `HoverCard`, the drop-down Form popovers),
  /// so a panel never sits further off its trigger than another does.
  static const double defaultPlacementOffset = CoreSpace.space4;

  /// Default open (enter) animation duration (150 ms).
  static const Duration defaultOpenAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default close (exit) animation duration (100 ms — panel exits
  /// noticeably faster than it opens).
  static const Duration defaultCloseAnimationDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default viewport-collision resolution policy — flip to the opposite
  /// axis first, then shift along the placement axis.
  static const Set<CorePopoverCollision> defaultCollision = {
    CorePopoverCollision.flip,
    CorePopoverCollision.shift,
  };

  /// Default padding between the popover and the viewport edge when
  /// applying [CorePopoverCollision.shift] (8 logical px on all four
  /// sides — symmetric default; per-side overrides via
  /// `CoreEdgeInsets.only(...)` support sticky headers / banners /
  /// safe-area insets parity with the Floating UI reference).
  static const CoreEdgeInsets defaultViewportPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default trigger sizing — the wrapper hugs the trigger's intrinsic
  /// content. A popover anchors whatever it is given (icon button, colour
  /// swatch, inline word), so shrink-wrapping is the neutral choice;
  /// field-style triggers that must fill the inline axis (Select /
  /// DatePicker / TimePicker) opt into [CorePopoverTriggerSizing.expand]
  /// through their own `popoverStyle` default.
  static const CorePopoverTriggerSizing defaultTriggerSizing = .intrinsic;

  /// Default placement offset between the trigger and the panel for
  /// Form popovers (4 logical px). Form popovers (drop-downs, calendars)
  /// sit tight against their trigger — the same distance as
  /// [defaultPlacementOffset].
  static const double defaultFormPopoverPlacementOffset = CoreSpace.space4;

  /// Default max-height of a Form popover panel before internal
  /// scrolling kicks in (300 logical px).
  static const double defaultFormPopoverMaxHeight = 300;

  /// Default preferred placement for drop-down style popovers (Select,
  /// Autocomplete, DatePicker, TimePicker, ColorPicker).
  static const CorePopoverPlacement defaultDropdownPlacement = .bottomStart;

  /// Default behaviour — Form popovers close when the trigger scrolls
  /// so drop-downs don't visually detach from their trigger during
  /// scroll.
  static const bool defaultCloseOnScroll = true;

  /// Default z-index for non-modal popovers — the shared page-level
  /// `CoreZIndex.z60` (popovers) rung, so a popover always resolves
  /// above dropdowns/headers/sidebars/backdrops and below
  /// tooltips/toasts, regardless of which platform paints it.
  static const int defaultZIndex = CoreZIndex.z60;

  // ── Slot Styles (nested) ─────────────────────

  /// Look of the panel — background, border, radius, shadow, padding,
  /// min-width, content colour. The panel is a `Popup`, which gets this
  /// style as is. `null` → [defaultPanelStyle] (which itself defers most
  /// fields to `CorePopupStyle`'s defaults).
  ///
  /// Composed per the child-component-composition rule.
  final CorePopupStyle? panelStyle;

  // ── Layout / behaviour ───────────────────────

  /// Trigger-to-panel placement offset (logical px) — applied along the
  /// placement axis (top/bottom or left/right depending on
  /// `CorePopoverPlacement`) to push the floating panel away from the
  /// trigger edge. Maps to a Flutter `Offset` via
  /// `placement_ext.toPopoverOffset` and to the Web floating-controller
  /// placement-axis distance.
  final double? placementOffset;

  /// Viewport-edge padding enforced when applying
  /// [CorePopoverCollision.shift] — the panel won't paint within this
  /// much of the visible viewport edge regardless of placement. Per
  /// CLAUDE.md rule 2 (multi-side padding/margin → [CoreEdgeInsets]),
  /// each side accepts its own value so popovers can avoid colliding
  /// with fixed headers, banners, or safe-area insets
  /// (e.g. `CoreEdgeInsets.only(top: 64)` reserves a 64-px sticky-header
  /// strip). `null` → token default ([defaultViewportPadding]).
  final CoreEdgeInsets? viewportPadding;

  /// How the trigger wrapper is sized: `intrinsic` (fits the trigger's
  /// content) or `expand` (fills the parent's width).
  final CorePopoverTriggerSizing? triggerSizing;

  /// Open animation duration override.
  final Duration? openAnimationDuration;

  /// Close animation duration override.
  final Duration? closeAnimationDuration;

  /// Trigger button style override, as a `CoreButtonStyle`: change any
  /// part of the button's look — colours, size and spacing, the styles of
  /// its icons, label and focus ring — without touching the panel's look.
  ///
  /// To change the trigger's **variant** (e.g. outline vs primary),
  /// inject the trigger widget directly via `Popover(trigger: ...)`
  /// rather than packing variant into this style (asChild pattern).
  ///
  /// Carries no `defaultTriggerStyle`. A popover diverges from `Button`'s
  /// own chrome in *nothing* — it anchors whatever trigger it is handed —
  /// so the only fillable partial would restate the child's defaults, which
  /// `style-contract.md` forbids (the parent must not reach into the
  /// child's defaults) and which would silently stop tracking `Button` the
  /// next time those defaults move. Absence also keeps a live fallback
  /// reachable: DatePicker and TimePicker resolve their trailing icon as
  /// `merged.trailingIconStyle ?? popoverStyle.triggerStyle
  /// ?.trailingIconStyle ?? defaultTrailingIconStyle`, so a default carrying
  /// a `trailingIconStyle` would make that third rung dead on both
  /// platforms.
  final CoreButtonStyle? triggerStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested [panelStyle] /
  /// [triggerStyle] are merged recursively.
  @override
  CorePopoverStyle merge(CorePopoverStyle? other) {
    if (other == null) return this;
    return CorePopoverStyle(
      panelStyle: _mergePopup(panelStyle, other.panelStyle),
      placementOffset: other.placementOffset ?? placementOffset,
      viewportPadding: other.viewportPadding ?? viewportPadding,
      triggerSizing: other.triggerSizing ?? triggerSizing,
      openAnimationDuration:
          other.openAnimationDuration ?? openAnimationDuration,
      closeAnimationDuration:
          other.closeAnimationDuration ?? closeAnimationDuration,
      triggerStyle: _mergeButton(triggerStyle, other.triggerStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CorePopoverStyle copyWith({
    CorePopupStyle? panelStyle,
    double? placementOffset,
    CoreEdgeInsets? viewportPadding,
    CorePopoverTriggerSizing? triggerSizing,
    Duration? openAnimationDuration,
    Duration? closeAnimationDuration,
    CoreButtonStyle? triggerStyle,
  }) {
    return CorePopoverStyle(
      panelStyle: panelStyle ?? this.panelStyle,
      placementOffset: placementOffset ?? this.placementOffset,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      triggerSizing: triggerSizing ?? this.triggerSizing,
      openAnimationDuration:
          openAnimationDuration ?? this.openAnimationDuration,
      closeAnimationDuration:
          closeAnimationDuration ?? this.closeAnimationDuration,
      triggerStyle: triggerStyle ?? this.triggerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePopoverStyle &&
          runtimeType == other.runtimeType &&
          panelStyle == other.panelStyle &&
          placementOffset == other.placementOffset &&
          viewportPadding == other.viewportPadding &&
          triggerSizing == other.triggerSizing &&
          openAnimationDuration == other.openAnimationDuration &&
          closeAnimationDuration == other.closeAnimationDuration &&
          triggerStyle == other.triggerStyle;

  @override
  int get hashCode => Object.hash(
    panelStyle,
    placementOffset,
    viewportPadding,
    triggerSizing,
    openAnimationDuration,
    closeAnimationDuration,
    triggerStyle,
  );

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
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
}
