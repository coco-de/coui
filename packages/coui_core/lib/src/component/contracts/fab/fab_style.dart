/// Per-instance style for `Fab`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/fab/fab_size.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Fab` should render.
///
/// `Fab` composes `Button` for the main circular surface, and its
/// expanded actions are a **menu**: a composed `Popup` panel
/// ([popupStyle]) holding one `MenuItem` row per action ([actionItemStyle]
/// — the row's leading icon, label typography, insets and corner are the
/// `MenuItem`'s own). The circle chrome (background / foreground / shadow
/// / radius / focus ring) flows through the nested [buttonStyle] slot and
/// is raw-forwarded to the composed `Button`. The dimensional fields that
/// are FAB-specific (`diameter` / `iconStyle` / `spacing`) stay flat here.
/// Semantic fields (`size` / `position` / `expandDirection`) live on the
/// widget, not on this style.
///
/// ```text
/// design system default (CoreFabStyle.defaultX / defaultsBySize)
///   → CoreFabTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.fabStyle                          // 인스턴스별
/// ```
@immutable
class CoreFabStyle implements CoreStyle<CoreFabStyle> {
  /// Creates a [CoreFabStyle].
  const CoreFabStyle({
    this.buttonStyle,
    this.actionItemStyle,
    @Deprecated(
      'Use actionItemStyle (since 0.164) — the rows are MenuItem rows.',
    )
    this.actionButtonStyle,
    @Deprecated('Use actionItemStyle.labelStyle (since 0.164).')
    this.actionLabelTextStyle,
    this.extendedButtonStyle,
    this.diameter,
    this.iconStyle,
    @Deprecated('Use actionItemStyle.leadingIconStyle (since 0.164).')
    this.actionIconStyle,
    this.spacing,
    this.duration,
    this.popoverStyle,
    this.popupStyle,
  });

  // ═══════════════════════════════════════════════════
  // 1. Defaults — composed Button chrome slots
  // ═══════════════════════════════════════════════════
  //
  // The main FAB is a `Button`: the surface chrome (background /
  // foreground / shadow / radius) lives in the nested `CoreButtonStyle`
  // slot and is raw-forwarded to the composed `Button`. The keyboard
  // activation + focus ring come from `Button` itself (its
  // `focusOutlineStyle`), so they are not re-spelt here. `resolveFab` does
  // `defaultButtonStyle.merge(merged.buttonStyle)`.

  /// Default main FAB circle chrome — only the FAB-specific shape
  /// overrides (full-circle radius, large drop shadow, zero padding).
  /// The colour / hover chrome comes from `Button(variant: primary)` as
  /// token **classes** (not inline), so the `:hover` state works on Web —
  /// composing onto `.plain` + an inline background override would let the
  /// inline colour beat the `hover:` class (the pseudo-state specificity
  /// trap). `Button`'s own `focusOutlineStyle` paints the focus ring.
  ///
  /// The ring's gap band is turned on here (the extended button derives
  /// from this slot, so it gets it too): a FAB floats over content that
  /// scrolls beneath it, so the colour next to the ring is unknown and
  /// the ring needs the two-colour band (`CoreFocusRing.opaqueOffsetColor`).
  static const CoreButtonStyle defaultButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    boxShadow: CoreShadow.lg,
    padding: .zero,
    focusOutlineStyle: CoreFocusOutlineStyle(
      offsetColor: CoreFocusRing.opaqueOffsetColor,
    ),
  );

  // ═══════════════════════════════════════════════════
  // 2. Defaults — action row (composed MenuItem)
  // ═══════════════════════════════════════════════════

  /// Default action-row chrome — a partial that diverges from the row's
  /// own defaults in one field, the corner; everything else is left `null`
  /// for the `MenuItem` resolver to fill from its size ladder at
  /// `CoreFabContract.actionItemSize` (`lg`: a 48 minimum height, 16 / 12
  /// insets, a 12 gap, a 24 icon, the `labelXl` label). A full copy of
  /// those here would be a second source of them.
  ///
  /// The corner is 8, not the `lg` row's own 12. The other rows a panel
  /// hosts (`ItemPicker`, `Autocomplete`, `PhoneInput`, `OptionItem`) all
  /// sit at 8, so the Fab's rows match them and the family reads as one
  /// system. The 8 is a decision about the whole list-row family, not a
  /// concentric derivation from the card: the card's 12 minus its list
  /// inset 6 ([defaultPopupStyle]) would be 6, and moving every list row to
  /// that is a separate change.
  static const CoreMenuItemStyle defaultActionItemStyle = CoreMenuItemStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  );

  /// The action-row chrome the rows used while they were composed as
  /// `Button(variant: .menu)`. Nothing reads it — the rows are `MenuItem`
  /// and take every value from [defaultActionItemStyle] and the `MenuItem`
  /// size ladder.
  @Deprecated(
    'Use defaultActionItemStyle (since 0.164) — the action rows are MenuItem '
    'rows now, so a Button style no longer describes them.',
  )
  static const CoreButtonStyle defaultActionButtonStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space16,
      vertical: CoreSpace.space10,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
  );

  /// The action-row label style of the `Button` rows. Nothing reads it —
  /// the label is the `MenuItem` row's own `labelStyle`.
  @Deprecated(
    'Use defaultActionItemStyle.labelStyle (since 0.164) — the label '
    'typography comes from the MenuItem row ladder, not a Fab-side copy.',
  )
  static const CoreTextStyle defaultActionLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The action-row leading icon style of the `Button` rows. Nothing reads
  /// it — the glyph is the `MenuItem` row's own `leadingIconStyle`.
  @Deprecated(
    'Use defaultActionItemStyle.leadingIconStyle (since 0.164) — the glyph '
    'size comes from the MenuItem row ladder, not a Fab-side copy.',
  )
  static const CoreIconStyle defaultActionIconStyle = CoreIconStyle(
    size: CoreIconSize.size24,
  );

  // ═══════════════════════════════════════════════════
  // 3. Defaults — single (FAB-specific chrome)
  // ═══════════════════════════════════════════════════

  /// Default gap between the main FAB and the menu panel (logical px).
  /// Pure placement-offset scalar — never consumed as a flex gap, so this
  /// stays a raw double rather than a `CoreGapStyle` slot.
  static const double defaultSpacing = CoreSpace.space16;

  /// Default menu open / close animation duration — applied to the panel's
  /// own open / close motion when the caller has not pinned one in
  /// [popupStyle].
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default menu panel chrome — the floating box is a `Popup`, so the
  /// Fab only states the fields that diverge from the popup's own
  /// defaults: the list inset, the width band and the small inter-row `space2`
  /// gap. The `surface-bright` fill, the `outline-subtle` stroke-1 border,
  /// the `panel` corner (12) and the `lg` elevation are the `Popup`'s own
  /// (raw-forward — the popup resolver fills them).
  ///
  /// The inset is the list inset ([CorePopupStyle.defaultListPadding], 6):
  /// what a Fab opens is a list of actions, the same card `Menu` draws.
  /// The hosted row corner is [defaultActionItemStyle]'s.
  ///
  /// Width is content-driven between a compact floor and the menu ceiling.
  /// The floor is `layout/160`, not `Menu`'s `layout/240`: a Fab menu is
  /// icon-and-short-label rows opened on a phone, while `Menu`'s 240 also
  /// has to hold shortcuts, submenu chevrons and description lines. The
  /// ceiling is the shared menu maximum, `layout/280`; a longer label ends
  /// in an ellipsis rather than widening the panel past it.
  static const CorePopupStyle defaultPopupStyle = CorePopupStyle(
    padding: CorePopupStyle.defaultListPadding,
    minWidth: CoreLayout.layout160,
    maxWidth: CoreLayout.layout280,
    spacing: CoreSpace.space2,
  );

  /// Default overlay host chrome — a deliberately chrome-less `Popover`,
  /// because the visible panel is the composed `Popup` inside it
  /// ([defaultPopupStyle]); a second box around it would draw the menu
  /// twice. So its `panelStyle` zeroes every `Popup` surface field —
  /// transparent fill / border, no shadow, no padding, no min-width.
  /// Raw-forwarded to `Popover(popoverStyle: …)`.
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    panelStyle: CorePopupStyle(
      padding: .zero,
      borderWidth: CoreStrokeWidth.stroke0,
      backgroundColor: .transparent,
      borderColor: .transparent,
      boxShadow: CoreShadow.none,
      minWidth: 0,
    ),
  );

  // ═══════════════════════════════════════════════════
  // 4. Defaults — size-keyed
  // ═══════════════════════════════════════════════════

  /// Per-size default chrome — single source of truth shared by Flutter
  /// and Web. The map value is `CoreFabStyle` itself so the flat slot
  /// fields stay 1:1 with the per-size defaults. Both resolvers read
  /// `CoreFabStyle.defaultsBySize[size]!` for `diameter` / `iconStyle`.
  static const Map<CoreFabSize, CoreFabStyle> defaultsBySize = {
    CoreFabSize.mini: CoreFabStyle(
      diameter: CoreSize.size48,
      // 24, not 20 — the Button · Menu redesign's `fab/icon-mini` token
      // (2026-09-08 §4: 24·24·28). At 48dp the 20 glyph sat in a ring
      // of empty fill; the icon ladder itself is unchanged (§8).
      iconStyle: CoreIconStyle(size: CoreIconSize.size24),
      extendedButtonStyle: CoreButtonStyle(
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space20),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    ),
    CoreFabSize.regular: CoreFabStyle(
      diameter: CoreSize.size56,
      iconStyle: CoreIconStyle(size: CoreIconSize.size24),
      extendedButtonStyle: CoreButtonStyle(
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space24),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    ),
    CoreFabSize.large: CoreFabStyle(
      diameter: CoreSize.size72,
      iconStyle: CoreIconStyle(size: CoreIconSize.size28),
      extendedButtonStyle: CoreButtonStyle(
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space28),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    ),
  };

  // ═══════════════════════════════════════════════════
  // 5. Props — composed Button chrome slots
  // ═══════════════════════════════════════════════════

  /// Look of the main FAB circle — background, foreground, shadow, radius,
  /// focus ring. Passed to the `Button` inside as is. `null` (or any unset
  /// field) defers to [defaultButtonStyle].
  ///
  /// Three fields are owned elsewhere and restated after this slot, so a
  /// value here does not reach the circle: `height` / `width` belong to
  /// [diameter] (the circle needs them equal), and the glyph size in
  /// `leadingIconStyle` belongs to [iconStyle]. Every other
  /// `leadingIconStyle` sub-field (a colour, say) is merged on top of
  /// [iconStyle] and reaches the glyph.
  final CoreButtonStyle? buttonStyle;

  /// **Extended** (라벨을 가진) FAB 의 버튼 모양 — 배경, 글자색, 그림자,
  /// 모서리 등. 안에 있는 `Button` 에 그대로 전달된다.
  ///
  /// Extended 는 원이 아니라 알약이라 폭이 라벨을 따라간다. 높이는 원형과
  /// 같은 [diameter] 이고, 좌우 패딩과 아이콘–라벨 간격만 사이즈별로
  /// 다르다([defaultsBySize]) — 라벨 크기는 `CoreFabSize.toExtendedButtonSize()`
  /// 가 고른 `Button` 사이즈에서 상속받으므로 여기서 다시 진술하지 않는다.
  ///
  /// `null`(또는 설정되지 않은 필드)이면 [defaultsBySize] 의 해당 사이즈
  /// 값으로, 그다음 [defaultButtonStyle] 로 내려간다.
  final CoreButtonStyle? extendedButtonStyle;

  // ═══════════════════════════════════════════════════
  // 6. Props — action row (composed MenuItem)
  // ═══════════════════════════════════════════════════

  /// Look of each action row, passed as is to the row's `MenuItem`. `null`
  /// (or any unset field) defers to [defaultActionItemStyle], which sets
  /// only the row corner (8): otherwise the row is the `MenuItem` at
  /// `CoreFabContract.actionItemSize` as it draws itself.
  ///
  /// The row's leading icon, label typography, insets, gap and corner are
  /// this slot's `leadingIconStyle` / `labelStyle` / `padding` /
  /// `contentGapStyle` / `borderRadius` — the `MenuItem`'s own fields, not
  /// a Fab-side restatement.
  final CoreMenuItemStyle? actionItemStyle;

  /// Look of the action rows, given as a `Button` style.
  ///
  /// Still honoured: [effectiveActionItemStyle] folds the fields a
  /// `MenuItem` row also has — `padding`, `borderRadius`,
  /// `iconLabelGapStyle` (→ `contentGapStyle`), `height` (→ `minHeight`),
  /// `leadingIconStyle`, `labelStyle`, `backgroundColor`,
  /// `foregroundColor`, `hoverBackgroundColor` — under [actionItemStyle],
  /// which wins field by field. Button-only fields (shadow, border, focus
  /// outline, …) have no row counterpart and are dropped.
  @Deprecated(
    'Use actionItemStyle (since 0.164) — the action rows are MenuItem rows '
    'now, so their look is a CoreMenuItemStyle.',
  )
  final CoreButtonStyle? actionButtonStyle;

  /// The action-row label style of the `Button` rows. Still honoured as
  /// the row's `labelStyle` under [actionItemStyle] (see
  /// [effectiveActionItemStyle]).
  @Deprecated(
    'Use actionItemStyle.labelStyle (since 0.164) — the label belongs to the '
    'composed MenuItem row.',
  )
  final CoreTextStyle? actionLabelTextStyle;

  /// The action-row leading icon style of the `Button` rows. Still
  /// honoured as the row's `leadingIconStyle` under [actionItemStyle] (see
  /// [effectiveActionItemStyle]).
  @Deprecated(
    'Use actionItemStyle.leadingIconStyle (since 0.164) — the glyph belongs '
    'to the composed MenuItem row.',
  )
  final CoreIconStyle? actionIconStyle;

  /// The action-row chrome both resolvers raw-forward to each `MenuItem`
  /// row: the deprecated [actionButtonStyle] / [actionLabelTextStyle] /
  /// [actionIconStyle] folded into a `CoreMenuItemStyle`, with
  /// [actionItemStyle] merged on top so the new slot wins field by field.
  /// `null` when none of the four is stated.
  ///
  /// The fold lives here, once, so the two platforms cannot read the
  /// deprecated fields differently.
  CoreMenuItemStyle? get effectiveActionItemStyle {
    if (actionButtonStyle == null &&
        actionLabelTextStyle == null &&
        actionIconStyle == null) {
      return actionItemStyle;
    }
    return _foldButtonRow(
      actionButtonStyle,
      actionLabelTextStyle,
      actionIconStyle,
    ).merge(actionItemStyle);
  }

  /// Folds the deprecated `Button`-row slots into the `MenuItem` row
  /// fields that answer the same question. The old rows let the icon slot
  /// own the glyph size and let a `leadingIconStyle` in the button slot win
  /// every other icon field; the fold keeps that order.
  static CoreMenuItemStyle _foldButtonRow(
    CoreButtonStyle? row,
    CoreTextStyle? label,
    CoreIconStyle? icon,
  ) {
    final mergedIcon = _mergeIcon(icon, row?.leadingIconStyle);
    final iconSize = icon?.size;
    return CoreMenuItemStyle(
      minHeight: row?.height,
      padding: row?.padding,
      contentGapStyle: row?.iconLabelGapStyle,
      borderRadius: row?.borderRadius,
      leadingIconStyle: iconSize == null
          ? mergedIcon
          : mergedIcon?.merge(CoreIconStyle(size: iconSize)),
      labelStyle: _mergeText(label, row?.labelStyle),
      backgroundColor: row?.backgroundColor,
      foregroundColor: row?.foregroundColor,
      hoverBackgroundColor: row?.hoverBackgroundColor,
    );
  }

  // ═══════════════════════════════════════════════════
  // 7. Props — dimensions
  // ═══════════════════════════════════════════════════

  /// Main FAB circular diameter override (logical px). `null` defers
  /// to [defaultsBySize] for the active size. Forwarded to the composed
  /// `Button`'s `width` / `height` — the single entry point for both, so a
  /// `height` / `width` in [buttonStyle] is overridden by this.
  final double? diameter;

  /// Main FAB icon style override — styles the icon glyph the FAB passes
  /// as the composed `Button`'s child (its `size` is the only source of
  /// the glyph size; a `color` pins the glyph colour). `null` defers to
  /// [defaultsBySize] for the active size. A `leadingIconStyle` stated in
  /// [buttonStyle] merges on top of this for every field except `size`.
  final CoreIconStyle? iconStyle;

  /// Gap between the main FAB and the menu panel (logical px) override.
  /// Pure placement-offset scalar — never consumed as a flex gap by `Gap`
  /// / CSS `gap`.
  final double? spacing;

  // ═══════════════════════════════════════════════════
  // 8. Props — behaviour
  // ═══════════════════════════════════════════════════

  /// Menu open / close animation duration override — the panel's own
  /// open / close motion, unless [popupStyle] pins one.
  final Duration? duration;

  // ═══════════════════════════════════════════════════
  // 9. Props — overlay host (composed Popover) + menu panel (Popup)
  // ═══════════════════════════════════════════════════

  /// Style of the `Popover` that hosts the menu, passed to it as is.
  /// `null` (or any unset field) defers to [defaultPopoverStyle], which
  /// draws no box, because the visible box is the `Popup` in [popupStyle].
  /// Override it e.g. to tune the placement offset.
  ///
  /// Composed per the child-component-composition rule.
  final CorePopoverStyle? popoverStyle;

  /// Look of the menu panel — the `Popup` that holds the action rows,
  /// passed to it as is. `null` (or any unset field) defers to
  /// [defaultPopupStyle] — the Fab's own card.
  final CorePopupStyle? popupStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested style slots are merged recursively so
  /// a partial override only affects the fields it specifies.
  @override
  CoreFabStyle merge(CoreFabStyle? other) {
    if (other == null) return this;
    return CoreFabStyle(
      buttonStyle: _mergeButton(buttonStyle, other.buttonStyle),
      actionItemStyle: _mergeItem(actionItemStyle, other.actionItemStyle),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
      actionLabelTextStyle: _mergeText(
        actionLabelTextStyle,
        other.actionLabelTextStyle,
      ),
      extendedButtonStyle: _mergeButton(
        extendedButtonStyle,
        other.extendedButtonStyle,
      ),
      diameter: other.diameter ?? diameter,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      actionIconStyle: _mergeIcon(actionIconStyle, other.actionIconStyle),
      spacing: other.spacing ?? spacing,
      duration: other.duration ?? duration,
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      popupStyle: _mergePopup(popupStyle, other.popupStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFabStyle copyWith({
    CoreButtonStyle? buttonStyle,
    CoreMenuItemStyle? actionItemStyle,
    CoreButtonStyle? actionButtonStyle,
    CoreTextStyle? actionLabelTextStyle,
    CoreButtonStyle? extendedButtonStyle,
    double? diameter,
    CoreIconStyle? iconStyle,
    CoreIconStyle? actionIconStyle,
    double? spacing,
    Duration? duration,
    CorePopoverStyle? popoverStyle,
    CorePopupStyle? popupStyle,
  }) {
    return CoreFabStyle(
      buttonStyle: buttonStyle ?? this.buttonStyle,
      extendedButtonStyle: extendedButtonStyle ?? this.extendedButtonStyle,
      actionItemStyle: actionItemStyle ?? this.actionItemStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      actionLabelTextStyle: actionLabelTextStyle ?? this.actionLabelTextStyle,
      diameter: diameter ?? this.diameter,
      iconStyle: iconStyle ?? this.iconStyle,
      actionIconStyle: actionIconStyle ?? this.actionIconStyle,
      spacing: spacing ?? this.spacing,
      duration: duration ?? this.duration,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      popupStyle: popupStyle ?? this.popupStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFabStyle &&
          runtimeType == other.runtimeType &&
          buttonStyle == other.buttonStyle &&
          extendedButtonStyle == other.extendedButtonStyle &&
          actionItemStyle == other.actionItemStyle &&
          actionButtonStyle == other.actionButtonStyle &&
          actionLabelTextStyle == other.actionLabelTextStyle &&
          diameter == other.diameter &&
          iconStyle == other.iconStyle &&
          actionIconStyle == other.actionIconStyle &&
          spacing == other.spacing &&
          duration == other.duration &&
          popoverStyle == other.popoverStyle &&
          popupStyle == other.popupStyle;

  @override
  int get hashCode => Object.hash(
    buttonStyle,
    extendedButtonStyle,
    actionItemStyle,
    actionButtonStyle,
    actionLabelTextStyle,
    diameter,
    iconStyle,
    actionIconStyle,
    spacing,
    duration,
    popoverStyle,
    popupStyle,
  );

  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
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

  static CoreMenuItemStyle? _mergeItem(
    CoreMenuItemStyle? base,
    CoreMenuItemStyle? other,
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

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
