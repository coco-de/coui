import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedFab
// ═══════════════════════════════════════════════════

/// Resolver output for [Fab].
///
/// `Fab` composes `Button` for the main circle, so the circle chrome is
/// raw-forwarded as the [buttonStyle] slot that the composed `Button`
/// resolves itself (focus ring + keyboard activation included). Its
/// actions are a menu: a composed `Popup` ([popupStyle]) holding one
/// `MenuItem` row per action ([actionItemStyle]), hosted in a composed
/// `Popover` (overlay layer — hit-testable, never clipped) whose
/// chrome-less panel is raw-forwarded as [popoverStyle].
///
/// ```text
/// Popover (popoverStyle — chrome-less host)
///   └─ Popup (popupStyle — the menu panel)
///        └─ MenuItem × actions                 // actionItemStyle
///             ├─ leading: action.icon
///             └─ label: action.label
/// ```
class ResolvedFab {
  /// Creates a [ResolvedFab].
  const ResolvedFab({
    required this.buttonStyle,
    required this.extendedButtonStyle,
    required this.actionItemStyle,
    required this.popupStyle,
    required this.popoverStyle,
  });

  /// Main FAB circle `Button` chrome — diameter baked into width/height
  /// (pre-scaled). Raw-forwarded to `Button(buttonStyle: …)`.
  final CoreButtonStyle buttonStyle;

  /// **Extended** FAB chrome — 라벨을 가진 알약. 높이만 지름으로 굳히고
  /// 폭은 라벨이 정하게 둔다(원형과 달리 `width` 를 굽지 않는다).
  ///
  /// 아이콘 크기는 여기서 진술하지 않는다 — Extended 의 글리프는 합성되는
  /// `Button` 의 `leading` 슬롯에 들어가고 그 크기는 Button 이 자기 사이즈로
  /// 정한다. 인스턴스에서 그것을 덮으면 다음 Button 개편에서 깨진다.
  final CoreButtonStyle extendedButtonStyle;

  /// Action-row `MenuItem` chrome — raw-forwarded to every row. The FAB's
  /// size row states the inset, icon, icon-label gap and label role (and,
  /// for `large`, the height floor); the rest, and the scaling, the row
  /// resolves itself at [CoreFabContract.actionItemSize].
  final CoreMenuItemStyle actionItemStyle;

  /// Menu panel chrome — raw-forwarded to the composed `Popup` that holds
  /// the rows (`Popup` runs its own resolve step).
  final CorePopupStyle popupStyle;

  /// Chrome-less overlay host style — raw-forwarded to the composed
  /// `Popover`. Its `panelStyle` zeroes the panel box (the `Popup` above
  /// is the visible one) and carries the open / close motion; its
  /// `placementOffset` is the FAB-to-menu gap.
  final CorePopoverStyle popoverStyle;
}

// ═══════════════════════════════════════════════════
// resolveFab — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFab] for the given [context].
///
/// ```text
/// CoreFabStyle.defaultX → CoreFabTheme.style → widget.fabStyle
/// ```
ResolvedFab resolveFab(
  BuildContext context, {
  required CoreFabSize size,
  CoreFabStyle? fabStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final fabTheme = theme.coreComponentTheme?.fab;

  // Merge chain — design default → theme → instance.
  final merged = resolveStyleChain(const CoreFabStyle(), [
    fabTheme?.style,
    fabStyle,
  ]);

  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (diameter / iconStyle).
  final ss = CoreFabStyle.defaultsBySize[size]!;

  // ─── Dimensions (pre-scaled) ──────────────────────────
  // `Button` does not self-scale its `width` / `height`, and the icon
  // `IconTheme` consumes logical px — so the circle diameter / icon sizes
  // are pre-scaled here once and baked into the composed Buttons.
  final diameter = (merged.diameter ?? ss.diameter!) * scaling;
  final iconStyle = ss.iconStyle!.merge(merged.iconStyle);
  final iconSize = (iconStyle.size ?? 0) * scaling;

  // ─── Composed Button chrome (raw-forward) ─────────────
  // Circle chrome flows through the nested `CoreButtonStyle` slot; the
  // diameter is baked into width/height (pre-scaled) so the composed
  // `Button` paints an exact circle. The trigger glyph is the composed
  // `Button`'s child; `Button` sizes and tints it through its icon theme,
  // so the FAB's icon style is baked into `leadingIconStyle` (single source
  // — no `IconTheme` wrapper in the widget).
  //
  // Three fields are restated after the caller's slot, and only three:
  // `height` / `width` belong to `diameter` (the circle invariant needs
  // them equal, so a slot-level height would break the circle), and the
  // glyph `size` belongs to `iconStyle`. Every other icon sub-field is
  // merged, not replaced — the flat `iconStyle` first, then the slot's own
  // `leadingIconStyle` on top (the more specific statement wins), so a
  // caller's icon colour reaches the glyph from either entry point.
  // guard-nested-override: height — owned by `diameter` (circle invariant).
  // guard-nested-override: width — owned by `diameter` (circle invariant).
  // guard-nested-override: size — owned by `iconStyle`.
  final mergedButtonStyle = CoreFabStyle.defaultButtonStyle.merge(
    merged.buttonStyle,
  );
  final buttonStyle = mergedButtonStyle.copyWith(
    height: diameter,
    width: diameter,
    leadingIconStyle: iconStyle
        .merge(mergedButtonStyle.leadingIconStyle)
        .merge(CoreIconStyle(size: iconSize)),
  );
  // Extended — 원형과 같은 높이, 폭은 라벨이 정한다. 사이즈별 좌우 패딩과
  // 아이콘–라벨 간격은 `defaultsBySize` 의 `extendedButtonStyle` 이 들고 있고,
  // 그 위에 caller 의 override 가 얹힌다.
  final extendedButtonStyle = CoreFabStyle.defaultButtonStyle
      .merge(ss.extendedButtonStyle)
      .merge(merged.extendedButtonStyle)
      .copyWith(height: diameter);

  // ─── Action rows (raw-forward to composed MenuItem) ──
  // The row is a `MenuItem`, which resolves its own insets, corner, icon
  // and label typography — and scales them — so the slot is forwarded
  // untouched: no pre-scaling here (scaling it twice would be the
  // double-scale), no restating of the icon size.
  // `effectiveActionItemStyle` folds the deprecated Button-row fields
  // (`actionButtonStyle` / `actionIconStyle` / `actionLabelTextStyle`)
  // under `actionItemStyle`, once in Core, so both platforms read them the
  // same way.
  // guard-nested-override: actionItemStyle — `merged.actionItemStyle` is
  // merged on top inside `effectiveActionItemStyle`, so it wins field by
  // field over the folded deprecated slots.
  final actionItemStyle = CoreFabStyle.defaultActionItemStyle
      .merge(ss.actionItemStyle)
      .merge(merged.effectiveActionItemStyle);

  // ─── Menu panel (raw-forward to composed Popup) ──────
  final popupStyle = CoreFabStyle.defaultPopupStyle
      .merge(ss.popupStyle)
      .merge(merged.popupStyle);

  // ─── Overlay host (raw-forward to composed Popover) ──
  // The chrome-less panel lets the `Popup` be the visible box. The
  // FAB-to-menu gap is the popover placement offset — the FAB `spacing`
  // token (unscaled — `Popover`'s resolver applies `theme.scaling`) unless
  // the caller pinned an offset in `popoverStyle`. `duration` is the
  // menu's open / close motion, so it lands on the host panel's own
  // animation fields unless the caller pinned those too.
  final spacing = merged.spacing ?? ss.spacing!;
  final duration = merged.duration ?? CoreFabStyle.defaultDuration;
  final mergedPopover = CoreFabStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  final hostPanel = mergedPopover.panelStyle ?? const CorePopupStyle();
  final popoverStyle = mergedPopover.copyWith(
    placementOffset: mergedPopover.placementOffset ?? spacing,
    panelStyle: hostPanel.copyWith(
      openAnimationDuration: hostPanel.openAnimationDuration ?? duration,
      closeAnimationDuration: hostPanel.closeAnimationDuration ?? duration,
    ),
  );

  return ResolvedFab(
    buttonStyle: buttonStyle,
    extendedButtonStyle: extendedButtonStyle,
    actionItemStyle: actionItemStyle,
    popupStyle: popupStyle,
    popoverStyle: popoverStyle,
  );
}
