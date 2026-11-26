/// Per-instance style for `Command`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/command/command_presentation.dart';
import 'package:coui_core/src/component/contracts/command/command_size.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/kbd/kbd_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Command` palette renders.
///
/// `CoreCommandStyle` carries panel / search / scope / list / row / footer
/// / empty-state chrome as platform-neutral domain-typed fields, plus
/// nested styles for the components a palette composes (`Chip` for the
/// scope row, `Kbd` for the footer, `EmptyState` for no results, and the
/// per-row `Clickable`).
///
/// Three default tables, one per axis, all on this class so Flutter and
/// Web read the same numbers:
///
/// - `static const default*` — axis-independent values.
/// - [defaultsBySize] — the density ladder: row / search height, paddings,
///   glyph and type steps.
/// - [defaultsByPresentation] — the shape: radius, border, shadow, list
///   inset, width floor / ceiling, list scroll ceiling.
///
/// The resolver falls through `merged.X ?? presentation.X ?? size.X ??
/// defaultX` for every field, so an instance override always wins and an
/// axis only fills what the caller left unset.
///
/// ```text
/// design system default (CoreCommandStyle.defaultX / defaultsBy*)
///   → CoreCommandTheme.style                       // 프로젝트 공통
///   → CoreCommandTheme.variantStyles[variant]
///   → widget.commandStyle                          // 인스턴스별
/// ```
@immutable
class CoreCommandStyle implements CoreStyle<CoreCommandStyle> {
  /// Creates a partial style; every field is optional and merges onto the
  /// design-system defaults.
  const CoreCommandStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.panelShadow,
    this.panelMinWidth,
    this.panelMaxWidth,
    this.searchPadding,
    this.searchGapStyle,
    this.searchIconStyle,
    this.backIconStyle,
    this.searchInputHeight,
    this.scopePadding,
    this.scopeSpacing,
    this.scopeChipStyle,
    this.searchFieldStyle,
    this.listPadding,
    this.listSpacing,
    this.listMinHeight,
    this.listMaxHeight,
    this.headingPadding,
    this.itemPadding,
    this.itemMinHeight,
    this.itemBorderRadius,
    this.itemGapStyle,
    this.itemIconStyle,
    this.itemActiveIconStyle,
    this.itemHighlightColor,
    this.itemHoverColor,
    this.itemPressedColor,
    this.itemTextStyle,
    this.itemForegroundColor,
    this.itemDisabledForegroundColor,
    this.itemClickableStyle,
    this.highlightDuration,
    this.footerPadding,
    this.footerSpacing,
    this.emptyPadding,
    this.emptyStateStyle,
    this.kbdStyle,
    this.footerKbdIconStyle,
    this.labelStyle,
    this.overlineStyle,
    this.itemTitleStyle,
    this.headingStyle,
    this.shortcutStyle,
    this.footerStyle,
    this.footerBackgroundColor,
    this.placeholderColor,
  });

  // ═══════════════════════════════════════════════════════════════════
  // Axis-independent defaults
  // ═══════════════════════════════════════════════════════════════════

  /// Panel fill — the raised floating face (`surfaceBright`), the same
  /// face every floating panel stands on. `fullscreen` reads this too, so
  /// a fullscreen palette fills with the raised face.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Panel border colour — also the header / footer divider
  /// (`outlineSubtle`, the quiet panel line).
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Panel radius when no presentation states one (`inline`).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Panel border width.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Panel cast when no presentation states one.
  static const List<CoreShadowLayer> defaultPanelShadow = CoreShadow.none;

  /// No floor unless a presentation states one (`inline` → 240).
  static const double defaultPanelMinWidth = 0;

  /// Unbounded unless a presentation states a ceiling (`dialog` → 640).
  static const double defaultPanelMaxWidth = double.infinity;

  /// Search row padding — 12 at every size.
  static const CoreEdgeInsets defaultSearchPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
  );

  /// Gap between the search glyph and the field — 10 at every size.
  static const CoreGapStyle defaultSearchGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
    crossAxisExtent: 0,
  );

  /// Search glyph (`md`). Its colour is [placeholderColor].
  static const CoreIconStyle defaultSearchIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
  );

  /// Back-affordance glyph in the `fullscreen` header. Size is inherited
  /// from the composed square Button.
  static const CoreIconStyle defaultBackIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Search glyph colour — `on-surface-variant`, a step stronger than the
  /// placeholder text beside it, so the glyph reads as the row's mark rather
  /// than as part of the hint. The placeholder text takes the composed
  /// `TextField`'s own placeholder colour.
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// The `md` step — `size/40`, the same rung `TextField(size: .md)` sits
  /// on, so composing the field and stating the row height agree.
  static const double defaultSearchInputHeight = CoreControlSize.heightMd;

  /// Scope chip row padding (`md`).
  static const CoreEdgeInsets defaultScopePadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
    vertical: CoreSpace.space8,
  );

  /// Gap between scope chips.
  static const double defaultScopeSpacing = CoreSpace.space8;

  /// Scope filters stay flat within the already elevated palette: no cast,
  /// no border (the selected chip's tint is what marks the scope) and an 8
  /// corner at every size — the corner the list rows below use.
  static const CoreChipStyle defaultScopeChipStyle = CoreChipStyle(
    borderWidth: 0,
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    castMotion: .noShadow,
  );

  /// The composite owns the chrome; focus is shown by the caret and result.
  static const CoreTextFieldStyle defaultSearchFieldStyle = CoreTextFieldStyle(
    focusBorderColor: CoreColor.transparent,
  );

  /// List inset when no presentation states one — 8 on every side.
  static const CoreEdgeInsets defaultListPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Gap between the list's children (headings, rows and group dividers) —
  /// 2, so neighbouring row fills (the active row and a hovered one) never
  /// touch.
  static const double defaultListSpacing = CoreSpace.space2;

  /// List height floor.
  static const double defaultListMinHeight = CoreLayout.layout240;

  /// List scroll ceiling when no presentation states one (`inline`).
  static const double defaultListMaxHeight = CoreLayout.layout320;

  /// Group heading padding (`md`) — 10 on the side the text starts, so the
  /// heading lines up with the row labels below it, and 6 above and below.
  static const CoreEdgeInsets defaultHeadingPadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space10,
        top: CoreSpace.space6,
        end: CoreSpace.space12,
        bottom: CoreSpace.space6,
      );

  /// Row padding (`md`).
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space10,
    vertical: CoreSpace.space8,
  );

  /// Row height floor (`md`).
  static const double defaultItemMinHeight = CoreControlSize.heightMd;

  /// `radius/8` on every size and every presentation — the one rule the
  /// three presentations share (the row inset comes from `listPadding`,
  /// not from the radius).
  ///
  /// A row is drawn inside the panel, so it does not take the control
  /// ladder the search field and the back button do (the control height
  /// × 0.25 for `sm` · `md` · `lg`): the highlight, hover and pressed fills
  /// are the same 8 regardless of size, the shape the designer's canvas
  /// states for a list row. That is why [defaultsBySize] states no
  /// `itemBorderRadius`.
  ///
  /// 8 is not the panel corner (12) minus the list padding (8), so the row
  /// is a little rounder than the concentric corner; the canvas states it
  /// that way on purpose.
  static const CoreBorderRadius defaultItemBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Gap between a row's icon, label and shortcut — 10 at every size.
  static const CoreGapStyle defaultItemGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
    crossAxisExtent: 0,
  );

  /// Row glyph (`md`) — `on-surface-variant`, a step quieter than the
  /// label, so the label stays the thing a row is read by. A disabled row's
  /// glyph takes [defaultItemDisabledForegroundColor] instead.
  static const CoreIconStyle defaultItemIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Active row glyph, merged over [defaultItemIconStyle] — the glyph rises
  /// to `on-surface` with the label on the keyboard cursor.
  static const CoreIconStyle defaultItemActiveIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The keyboard cursor: a container fill on the raised panel
  /// (`surfaceBright`), not the accent — the only fill the active row
  /// carries (no accent bar); its glyph rises to `on-surface` with it
  /// ([defaultItemActiveIconStyle]). The pressed wash (`on-surface` at
  /// `opacity/pressed`) lands on a different value than this fill, so a
  /// pressed active row stays distinguishable from the cursor.
  static const CoreColor defaultItemHighlightColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Hover wash — `on-surface` at `opacity/hover`.
  static const CoreColor defaultItemHoverColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.hover,
  );

  /// Pressed wash — `on-surface` at `opacity/pressed`.
  static const CoreColor defaultItemPressedColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.pressed,
  );

  /// `on-surface` — the same foreground the resting row has. This slot
  /// used to say `on-tertiary`, which is only legible on the old accent
  /// fill; the resting foreground had to be a second field overriding it.
  /// The two now agree.
  static const CoreTextStyle defaultItemTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Resting row foreground.
  static const CoreColor defaultItemForegroundColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// A token, not an alpha: `disabled-content` reads the same in every
  /// mode and survives forced colours, where an alpha over `on-surface`
  /// keeps the alpha and loses the colour.
  static const CoreColor defaultItemDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Rows are not focus targets (focus stays on the search field and the
  /// active row travels as `aria-activedescendant`), so the composed
  /// `Clickable` draws no ring and no press scale — press feedback is the
  /// pressed wash.
  static const CoreClickableStyle defaultItemClickableStyle =
      CoreClickableStyle(pressedScale: 1);

  /// Footer fill — follows the panel (`surfaceBright`).
  static const CoreColor defaultFooterBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// `labelXs` (11 Medium) in `on-surface-subtle` — the group heading.
  /// The weight and tracking are the role's own: the heading names a run of
  /// rows rather than being one, so it sits a step below the semibold a
  /// title would carry.
  static const CoreTextStyle defaultHeadingStyle = CoreTextStyle.token(
    CoreTextStyles.labelXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Row label role (`md`) — colour-free, the colour is per state.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Row overline role (`md`) — `bodyXs` (12 Regular), the quiet second line
  /// above the title, in `on-surface-variant`. A disabled row paints it in
  /// [defaultItemDisabledForegroundColor] instead.
  ///
  /// The description tone is shared by the resting row, the active fill and
  /// the hover / pressed washes, and clears 4.5:1 in each of them
  /// (`tool/check_contrast.dart`). `on-surface-subtle` does not: on the
  /// active fill and under the washes it measures 3.3 – 4.4:1.
  static const CoreTextStyle defaultOverlineStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Row label role when an overline is present (`md`) — `bodyMedium`
  /// (14 Regular), the same weight as the one-line label: the overline above
  /// already says which line is the title.
  static const CoreTextStyle defaultItemTitleStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Shortcut hint typography — the `bodyXs` role in the sans face, in
  /// `on-surface-variant`. The sans face carries the key symbols
  /// (⌘ ⌥ ⌃ ⇧ ↵ ⎋) that the bundled monospace face lacks, so every
  /// platform draws them from one family, as `Kbd` does.
  ///
  /// The shortcut tone is the overline's, for the reason given on
  /// [defaultOverlineStyle].
  static const CoreTextStyle defaultShortcutStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Footer hint typography — the `bodyXs` role (12 Regular), the same role
  /// as the shortcut hints, in `on-surface-subtle`: the footer sits on the
  /// panel fill alone, with no row fill or wash under it.
  static const CoreTextStyle defaultFooterStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Active-row fill transition.
  static const Duration defaultHighlightDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Footer padding (`md`).
  static const CoreEdgeInsets defaultFooterPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space20,
    vertical: CoreSpace.space8,
  );

  /// Footer hint spacing.
  static const double defaultFooterSpacing = CoreSpace.space8;

  /// Padding around the composed `EmptyState` — none; it insets itself.
  static const CoreEdgeInsets defaultEmptyPadding = CoreEdgeInsets.zero;

  /// Partial — the floor is the only thing stated here: the same 240 the
  /// list has, so a panel whose results vanish does not fold and unfold.
  /// `EmptyState`'s own resolver fills the rest.
  static const CoreEmptyStateStyle defaultEmptyStateStyle = CoreEmptyStateStyle(
    minHeight: CoreLayout.layout240,
  );

  /// Partial `Kbd` style — the key-cap resolver fills the rest.
  static const CoreKbdStyle defaultKbdStyle = CoreKbdStyle();

  /// Footer key-cap glyph.
  static const CoreIconStyle defaultFooterKbdIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
  );

  // ═══════════════════════════════════════════════════════════════════
  // Size ladder
  // ═══════════════════════════════════════════════════════════════════

  /// Density steps — row 32 / 40 / 48 (`CoreControlSize`, the same rungs
  /// form controls sit on; `lg`'s 48 is the touch target a fullscreen row
  /// needs). Keyed on [CoreCommandSize], which states exactly these three.
  ///
  /// Row and search heights are floors — a two-line row or a scaled font
  /// grows past them.
  static const Map<CoreCommandSize, CoreCommandStyle> defaultsBySize = {
    CoreCommandSize.sm: CoreCommandStyle(
      searchInputHeight: CoreControlSize.heightSm,
      searchPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      searchGapStyle: CoreGapStyle(size: CoreSpace.space10, crossAxisExtent: 0),
      searchIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      itemMinHeight: CoreControlSize.heightSm,
      itemPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space10,
        vertical: CoreSpace.space4,
      ),
      itemGapStyle: CoreGapStyle(size: CoreSpace.space10, crossAxisExtent: 0),
      itemIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      overlineStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
      itemTitleStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      headingPadding: CoreEdgeInsets.directional(
        start: CoreSpace.space10,
        top: CoreSpace.space6,
        end: CoreSpace.space8,
        bottom: CoreSpace.space6,
      ),
      scopePadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space6,
      ),
      footerPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space6,
      ),
    ),
    CoreCommandSize.md: CoreCommandStyle(
      searchInputHeight: CoreControlSize.heightMd,
      searchPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      searchGapStyle: CoreGapStyle(size: CoreSpace.space10, crossAxisExtent: 0),
      searchIconStyle: CoreIconStyle(size: CoreIconSize.size20),
      itemMinHeight: CoreControlSize.heightMd,
      itemPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space10,
        vertical: CoreSpace.space8,
      ),
      itemGapStyle: CoreGapStyle(size: CoreSpace.space10, crossAxisExtent: 0),
      itemIconStyle: CoreIconStyle(size: CoreIconSize.size20),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
      overlineStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
      itemTitleStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
      headingPadding: CoreEdgeInsets.directional(
        start: CoreSpace.space10,
        top: CoreSpace.space6,
        end: CoreSpace.space12,
        bottom: CoreSpace.space6,
      ),
      scopePadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space8,
      ),
      footerPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space20,
        vertical: CoreSpace.space8,
      ),
    ),
    CoreCommandSize.lg: CoreCommandStyle(
      searchInputHeight: CoreControlSize.heightLg,
      searchPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      searchGapStyle: CoreGapStyle(
        size: CoreSpace.space10,
        crossAxisExtent: 0,
      ),
      searchIconStyle: CoreIconStyle(size: CoreIconSize.size24),
      itemMinHeight: CoreControlSize.heightLg,
      itemPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space10,
      ),
      itemGapStyle: CoreGapStyle(size: CoreSpace.space10, crossAxisExtent: 0),
      itemIconStyle: CoreIconStyle(size: CoreIconSize.size24),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
      overlineStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
      itemTitleStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
      headingPadding: CoreEdgeInsets.directional(
        start: CoreSpace.space10,
        top: CoreSpace.space6,
        end: CoreSpace.space16,
        bottom: CoreSpace.space6,
      ),
      scopePadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space12,
      ),
      footerPadding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space24,
        vertical: CoreSpace.space12,
      ),
    ),
  };

  // ═══════════════════════════════════════════════════════════════════
  // Presentation table
  // ═══════════════════════════════════════════════════════════════════

  /// The shape. Everything a presentation decides is here and nothing
  /// else — scrim, modality and routing belong to the host.
  ///
  /// The row highlight is `radius/8` inset by `listPadding` — 8 on every
  /// shape; `fullscreen` has no panel corner, and the inset keeps the row
  /// fill (which IS the highlight) off the screen edge.
  static const Map<CoreCommandPresentation, CoreCommandStyle>
  defaultsByPresentation = {
    CoreCommandPresentation.inline: CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      borderWidth: CoreStrokeWidth.stroke1,
      borderColor: CoreColor.token(CoreColors.outlineVariant),
      panelShadow: CoreShadow.none,
      panelMinWidth: CoreLayout.layout240,
      panelMaxWidth: double.infinity,
      listPadding: CoreEdgeInsets.all(CoreSpace.space8),
      listMinHeight: CoreLayout.layout240,
      listMaxHeight: CoreLayout.layout320,
    ),
    CoreCommandPresentation.dialog: CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadiusRole.modal),
      borderWidth: CoreStrokeWidth.stroke1,
      borderColor: CoreColor.token(CoreColors.outlineSubtle),
      panelShadow: CoreShadow.lg,
      panelMinWidth: 0,
      panelMaxWidth: CoreLayout.layout640,
      listPadding: CoreEdgeInsets.all(CoreSpace.space8),
      listMinHeight: CoreLayout.layout240,
      listMaxHeight: CoreLayout.layout400,
    ),
    CoreCommandPresentation.fullscreen: CoreCommandStyle(
      borderRadius: CoreBorderRadius.zero,
      borderWidth: 0,
      borderColor: CoreColor.transparent,
      panelShadow: CoreShadow.none,
      panelMinWidth: 0,
      panelMaxWidth: double.infinity,
      listPadding: CoreEdgeInsets.all(CoreSpace.space8),
      listMinHeight: 0,
      listMaxHeight: double.infinity,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════
  // Fields
  // ═══════════════════════════════════════════════════════════════════

  /// Panel fill.
  final CoreColor? backgroundColor;

  /// Panel border colour. Also the header / footer divider.
  final CoreColor? borderColor;

  /// Panel corner radius — a presentation value (12 · 20 · 0).
  final CoreBorderRadius? borderRadius;

  /// Panel border width (logical px). `0` on `fullscreen`.
  final double? borderWidth;

  /// Panel cast — a presentation value (`none` · `lg` · `none`).
  final List<CoreShadowLayer>? panelShadow;

  /// Panel width floor — `inline` states 240 (`CoreLayout`); the other shapes
  /// state none (`0`).
  final double? panelMinWidth;

  /// Panel width ceiling — `dialog` states 640 (`CoreLayout`); the other shapes
  /// are unbounded (`double.infinity`).
  final double? panelMaxWidth;

  /// Search row padding.
  final CoreEdgeInsets? searchPadding;

  /// Gap between the search glyph and the field.
  final CoreGapStyle? searchGapStyle;

  /// Search glyph style — forwarded to `Icon(iconStyle:)`.
  final CoreIconStyle? searchIconStyle;

  /// Back-affordance glyph in the `fullscreen` header — forwarded to
  /// `Icon(iconStyle:)`.
  final CoreIconStyle? backIconStyle;

  /// Search row height — the size ladder (`CoreControlSize`).
  final double? searchInputHeight;

  /// Scope chip row padding.
  final CoreEdgeInsets? scopePadding;

  /// Gap between scope chips (N-sibling, `Wrap.spacing`).
  final double? scopeSpacing;

  /// Style for the scope chips, passed to each `Chip` as is.
  final CoreChipStyle? scopeChipStyle;

  /// Style of the embedded search field.
  final CoreTextFieldStyle? searchFieldStyle;

  /// Item-list outer padding — a presentation value (8 on every shape).
  final CoreEdgeInsets? listPadding;

  /// Gap between the list's children — headings, rows and group dividers
  /// (N-sibling, `Column.spacing` / flex `gap`).
  final double? listSpacing;

  /// List height floor so the panel does not jump when results vanish
  /// (`CoreLayout.layout240`; `0` on `fullscreen`).
  final double? listMinHeight;

  /// List scroll ceiling — a presentation value (`CoreLayout.layout320` ·
  /// `layout400` · `double.infinity`).
  final double? listMaxHeight;

  /// Group-heading padding — a size value.
  final CoreEdgeInsets? headingPadding;

  /// Row inner padding — a size value.
  final CoreEdgeInsets? itemPadding;

  /// Row height floor — the size ladder (`CoreControlSize`). Two-line rows grow
  /// past it.
  final double? itemMinHeight;

  /// Row highlight radius (8 on every size and presentation — a row the
  /// panel hosts, see [defaultItemBorderRadius]).
  final CoreBorderRadius? itemBorderRadius;

  /// Gap between a row's icon and label, and between its label and
  /// shortcut.
  final CoreGapStyle? itemGapStyle;

  /// Style of each row's icon at rest — the caller's `item.icon` inherits
  /// its size and colour. A disabled row's icon takes
  /// [itemDisabledForegroundColor].
  final CoreIconStyle? itemIconStyle;

  /// Icon style on the active row, merged over [itemIconStyle] — only what
  /// changes on the keyboard cursor (the colour, `on-surface`).
  final CoreIconStyle? itemActiveIconStyle;

  /// Active-row fill — the keyboard cursor (`surface-container`), the only
  /// fill the active row carries.
  final CoreColor? itemHighlightColor;

  /// Hover wash over the row — `on-surface` at `opacity/hover`.
  final CoreColor? itemHoverColor;

  /// Pressed wash over the row — `on-surface` at `opacity/pressed`.
  final CoreColor? itemPressedColor;

  /// Row label style carrying the row foreground colour.
  final CoreTextStyle? itemTextStyle;

  /// Resting row foreground — the label text. The row's icon takes
  /// [itemIconStyle]'s colour.
  final CoreColor? itemForegroundColor;

  /// Disabled row foreground — a colour token (`disabled-content`), not an
  /// alpha.
  final CoreColor? itemDisabledForegroundColor;

  /// Style for each row's `Clickable`.
  final CoreClickableStyle? itemClickableStyle;

  /// Active-row fill transition.
  final Duration? highlightDuration;

  /// Footer padding — a size value.
  final CoreEdgeInsets? footerPadding;

  /// Footer hint spacing.
  final double? footerSpacing;

  /// Padding around the composed `EmptyState`.
  final CoreEdgeInsets? emptyPadding;

  /// Style for the `EmptyState`, passed to it as is. Its default
  /// `minHeight` is `CoreLayout.layout240`, the same floor the list has.
  final CoreEmptyStateStyle? emptyStateStyle;

  /// Style for the footer key caps, passed to each `Kbd`.
  final CoreKbdStyle? kbdStyle;

  /// Footer key-cap glyph style.
  final CoreIconStyle? footerKbdIconStyle;

  /// Row label typography role (colour-free; the colour is per state) — a size
  /// value.
  final CoreTextStyle? labelStyle;

  /// Row overline (category above the label) — a size value. Its colour is
  /// the field-level default (`on-surface-variant`).
  final CoreTextStyle? overlineStyle;

  /// Row label when an overline is present — a body role at the same weight
  /// as the one-line label (the overline above is the quieter line) — a size
  /// value.
  final CoreTextStyle? itemTitleStyle;

  /// Group heading typography.
  final CoreTextStyle? headingStyle;

  /// Shortcut hint typography (sans, `bodyXs`, `on-surface-variant`).
  final CoreTextStyle? shortcutStyle;

  /// Footer hint typography.
  final CoreTextStyle? footerStyle;

  /// Footer fill.
  final CoreColor? footerBackgroundColor;

  /// Search glyph colour (`on-surface-variant`). The placeholder text itself
  /// is the composed `TextField`'s.
  final CoreColor? placeholderColor;

  /// Merges [other] on top of this style — non-null fields in [other]
  /// win; nested styles merge recursively.
  @override
  CoreCommandStyle merge(CoreCommandStyle? other) {
    if (other == null) return this;
    return CoreCommandStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      panelShadow: other.panelShadow ?? panelShadow,
      panelMinWidth: other.panelMinWidth ?? panelMinWidth,
      panelMaxWidth: other.panelMaxWidth ?? panelMaxWidth,
      searchPadding: other.searchPadding ?? searchPadding,
      searchGapStyle: _mergeGap(searchGapStyle, other.searchGapStyle),
      searchIconStyle: _mergeIcon(searchIconStyle, other.searchIconStyle),
      backIconStyle: _mergeIcon(backIconStyle, other.backIconStyle),
      searchInputHeight: other.searchInputHeight ?? searchInputHeight,
      scopePadding: other.scopePadding ?? scopePadding,
      scopeSpacing: other.scopeSpacing ?? scopeSpacing,
      scopeChipStyle: _mergeChip(scopeChipStyle, other.scopeChipStyle),
      searchFieldStyle: searchFieldStyle == null
          ? other.searchFieldStyle
          : searchFieldStyle!.merge(other.searchFieldStyle),
      listPadding: other.listPadding ?? listPadding,
      listSpacing: other.listSpacing ?? listSpacing,
      listMinHeight: other.listMinHeight ?? listMinHeight,
      listMaxHeight: other.listMaxHeight ?? listMaxHeight,
      headingPadding: other.headingPadding ?? headingPadding,
      itemPadding: other.itemPadding ?? itemPadding,
      itemMinHeight: other.itemMinHeight ?? itemMinHeight,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      itemGapStyle: _mergeGap(itemGapStyle, other.itemGapStyle),
      itemIconStyle: _mergeIcon(itemIconStyle, other.itemIconStyle),
      itemActiveIconStyle: _mergeIcon(
        itemActiveIconStyle,
        other.itemActiveIconStyle,
      ),
      itemHighlightColor: other.itemHighlightColor ?? itemHighlightColor,
      itemHoverColor: other.itemHoverColor ?? itemHoverColor,
      itemPressedColor: other.itemPressedColor ?? itemPressedColor,
      itemTextStyle: _mergeText(itemTextStyle, other.itemTextStyle),
      itemForegroundColor: other.itemForegroundColor ?? itemForegroundColor,
      itemDisabledForegroundColor:
          other.itemDisabledForegroundColor ?? itemDisabledForegroundColor,
      itemClickableStyle: _mergeClickable(
        itemClickableStyle,
        other.itemClickableStyle,
      ),
      highlightDuration: other.highlightDuration ?? highlightDuration,
      footerPadding: other.footerPadding ?? footerPadding,
      footerSpacing: other.footerSpacing ?? footerSpacing,
      emptyPadding: other.emptyPadding ?? emptyPadding,
      emptyStateStyle: _mergeEmptyState(emptyStateStyle, other.emptyStateStyle),
      kbdStyle: _mergeKbd(kbdStyle, other.kbdStyle),
      footerKbdIconStyle: _mergeIcon(
        footerKbdIconStyle,
        other.footerKbdIconStyle,
      ),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      overlineStyle: _mergeText(overlineStyle, other.overlineStyle),
      itemTitleStyle: _mergeText(itemTitleStyle, other.itemTitleStyle),
      headingStyle: _mergeText(headingStyle, other.headingStyle),
      shortcutStyle: _mergeText(shortcutStyle, other.shortcutStyle),
      footerStyle: _mergeText(footerStyle, other.footerStyle),
      footerBackgroundColor:
          other.footerBackgroundColor ?? footerBackgroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreCommandStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    List<CoreShadowLayer>? panelShadow,
    double? panelMinWidth,
    double? panelMaxWidth,
    CoreEdgeInsets? searchPadding,
    CoreGapStyle? searchGapStyle,
    CoreIconStyle? searchIconStyle,
    CoreIconStyle? backIconStyle,
    double? searchInputHeight,
    CoreEdgeInsets? scopePadding,
    double? scopeSpacing,
    CoreChipStyle? scopeChipStyle,
    CoreTextFieldStyle? searchFieldStyle,
    CoreEdgeInsets? listPadding,
    double? listSpacing,
    double? listMinHeight,
    double? listMaxHeight,
    CoreEdgeInsets? headingPadding,
    CoreEdgeInsets? itemPadding,
    double? itemMinHeight,
    CoreBorderRadius? itemBorderRadius,
    CoreGapStyle? itemGapStyle,
    CoreIconStyle? itemIconStyle,
    CoreIconStyle? itemActiveIconStyle,
    CoreColor? itemHighlightColor,
    CoreColor? itemHoverColor,
    CoreColor? itemPressedColor,
    CoreTextStyle? itemTextStyle,
    CoreColor? itemForegroundColor,
    CoreColor? itemDisabledForegroundColor,
    CoreClickableStyle? itemClickableStyle,
    Duration? highlightDuration,
    CoreEdgeInsets? footerPadding,
    double? footerSpacing,
    CoreEdgeInsets? emptyPadding,
    CoreEmptyStateStyle? emptyStateStyle,
    CoreKbdStyle? kbdStyle,
    CoreIconStyle? footerKbdIconStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? overlineStyle,
    CoreTextStyle? itemTitleStyle,
    CoreTextStyle? headingStyle,
    CoreTextStyle? shortcutStyle,
    CoreTextStyle? footerStyle,
    CoreColor? footerBackgroundColor,
    CoreColor? placeholderColor,
  }) {
    return CoreCommandStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      panelShadow: panelShadow ?? this.panelShadow,
      panelMinWidth: panelMinWidth ?? this.panelMinWidth,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      searchPadding: searchPadding ?? this.searchPadding,
      searchGapStyle: searchGapStyle ?? this.searchGapStyle,
      searchIconStyle: searchIconStyle ?? this.searchIconStyle,
      backIconStyle: backIconStyle ?? this.backIconStyle,
      searchInputHeight: searchInputHeight ?? this.searchInputHeight,
      scopePadding: scopePadding ?? this.scopePadding,
      scopeSpacing: scopeSpacing ?? this.scopeSpacing,
      scopeChipStyle: scopeChipStyle ?? this.scopeChipStyle,
      searchFieldStyle: searchFieldStyle ?? this.searchFieldStyle,
      listPadding: listPadding ?? this.listPadding,
      listSpacing: listSpacing ?? this.listSpacing,
      listMinHeight: listMinHeight ?? this.listMinHeight,
      listMaxHeight: listMaxHeight ?? this.listMaxHeight,
      headingPadding: headingPadding ?? this.headingPadding,
      itemPadding: itemPadding ?? this.itemPadding,
      itemMinHeight: itemMinHeight ?? this.itemMinHeight,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      itemGapStyle: itemGapStyle ?? this.itemGapStyle,
      itemIconStyle: itemIconStyle ?? this.itemIconStyle,
      itemActiveIconStyle: itemActiveIconStyle ?? this.itemActiveIconStyle,
      itemHighlightColor: itemHighlightColor ?? this.itemHighlightColor,
      itemHoverColor: itemHoverColor ?? this.itemHoverColor,
      itemPressedColor: itemPressedColor ?? this.itemPressedColor,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      itemForegroundColor: itemForegroundColor ?? this.itemForegroundColor,
      itemDisabledForegroundColor:
          itemDisabledForegroundColor ?? this.itemDisabledForegroundColor,
      itemClickableStyle: itemClickableStyle ?? this.itemClickableStyle,
      highlightDuration: highlightDuration ?? this.highlightDuration,
      footerPadding: footerPadding ?? this.footerPadding,
      footerSpacing: footerSpacing ?? this.footerSpacing,
      emptyPadding: emptyPadding ?? this.emptyPadding,
      emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
      kbdStyle: kbdStyle ?? this.kbdStyle,
      footerKbdIconStyle: footerKbdIconStyle ?? this.footerKbdIconStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      overlineStyle: overlineStyle ?? this.overlineStyle,
      itemTitleStyle: itemTitleStyle ?? this.itemTitleStyle,
      headingStyle: headingStyle ?? this.headingStyle,
      shortcutStyle: shortcutStyle ?? this.shortcutStyle,
      footerStyle: footerStyle ?? this.footerStyle,
      footerBackgroundColor:
          footerBackgroundColor ?? this.footerBackgroundColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCommandStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          _listEq(panelShadow, other.panelShadow) &&
          panelMinWidth == other.panelMinWidth &&
          panelMaxWidth == other.panelMaxWidth &&
          searchPadding == other.searchPadding &&
          searchGapStyle == other.searchGapStyle &&
          searchIconStyle == other.searchIconStyle &&
          backIconStyle == other.backIconStyle &&
          searchInputHeight == other.searchInputHeight &&
          scopePadding == other.scopePadding &&
          scopeSpacing == other.scopeSpacing &&
          scopeChipStyle == other.scopeChipStyle &&
          searchFieldStyle == other.searchFieldStyle &&
          listPadding == other.listPadding &&
          listSpacing == other.listSpacing &&
          listMinHeight == other.listMinHeight &&
          listMaxHeight == other.listMaxHeight &&
          headingPadding == other.headingPadding &&
          itemPadding == other.itemPadding &&
          itemMinHeight == other.itemMinHeight &&
          itemBorderRadius == other.itemBorderRadius &&
          itemGapStyle == other.itemGapStyle &&
          itemIconStyle == other.itemIconStyle &&
          itemActiveIconStyle == other.itemActiveIconStyle &&
          itemHighlightColor == other.itemHighlightColor &&
          itemHoverColor == other.itemHoverColor &&
          itemPressedColor == other.itemPressedColor &&
          itemTextStyle == other.itemTextStyle &&
          itemForegroundColor == other.itemForegroundColor &&
          itemDisabledForegroundColor == other.itemDisabledForegroundColor &&
          itemClickableStyle == other.itemClickableStyle &&
          highlightDuration == other.highlightDuration &&
          footerPadding == other.footerPadding &&
          footerSpacing == other.footerSpacing &&
          emptyPadding == other.emptyPadding &&
          emptyStateStyle == other.emptyStateStyle &&
          kbdStyle == other.kbdStyle &&
          footerKbdIconStyle == other.footerKbdIconStyle &&
          labelStyle == other.labelStyle &&
          overlineStyle == other.overlineStyle &&
          itemTitleStyle == other.itemTitleStyle &&
          headingStyle == other.headingStyle &&
          shortcutStyle == other.shortcutStyle &&
          footerStyle == other.footerStyle &&
          footerBackgroundColor == other.footerBackgroundColor &&
          placeholderColor == other.placeholderColor;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    borderRadius,
    borderWidth,
    if (panelShadow != null) Object.hashAll(panelShadow!),
    panelMinWidth,
    panelMaxWidth,
    searchPadding,
    searchGapStyle,
    searchIconStyle,
    backIconStyle,
    searchInputHeight,
    scopePadding,
    scopeSpacing,
    scopeChipStyle,
    searchFieldStyle,
    listPadding,
    listSpacing,
    listMinHeight,
    listMaxHeight,
    headingPadding,
    itemPadding,
    itemMinHeight,
    itemBorderRadius,
    itemGapStyle,
    itemIconStyle,
    itemActiveIconStyle,
    itemHighlightColor,
    itemHoverColor,
    itemPressedColor,
    itemTextStyle,
    itemForegroundColor,
    itemDisabledForegroundColor,
    itemClickableStyle,
    highlightDuration,
    footerPadding,
    footerSpacing,
    emptyPadding,
    emptyStateStyle,
    kbdStyle,
    footerKbdIconStyle,
    labelStyle,
    overlineStyle,
    itemTitleStyle,
    headingStyle,
    shortcutStyle,
    footerStyle,
    footerBackgroundColor,
    placeholderColor,
  ]);

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static CoreKbdStyle? _mergeKbd(CoreKbdStyle? base, CoreKbdStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreChipStyle? _mergeChip(CoreChipStyle? base, CoreChipStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreEmptyStateStyle? _mergeEmptyState(
    CoreEmptyStateStyle? base,
    CoreEmptyStateStyle? other,
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

  static CoreIconStyle? _mergeIcon(CoreIconStyle? base, CoreIconStyle? other) {
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
