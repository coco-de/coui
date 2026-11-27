import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Fab`.
///
/// `Fab` composes a `Button` for the main circle, so the circle chrome is
/// raw-forwarded as the [buttonStyle] slot that the composed `Button`
/// resolves itself (colour / hover / focus ring / keyboard activation
/// included). Its actions are a menu: a composed `Popup` ([popupStyle])
/// holding one `MenuItem` row per action ([actionItemStyle]), hosted in a
/// composed `Popover` so the menu lives in the overlay layer
/// (hit-testable, never clipped). The chrome-less host panel is
/// raw-forwarded as [popoverStyle].
///
/// DOM shape (the menu is the `Popover` content):
///
/// ```text
/// root (empty)                                  // Popover is the outermost element; the no-action
///                                               // FAB returns the main Button wrapped in this slot
///   Button (main FAB, variant primary)          // uses buttonStyle (diameter + icon style baked;
///                                               // Button's IconTheme sizes / tints the glyph)
///   Popup (popupStyle)                          // Popover content — the menu panel
///     └─ MenuItem × actions                     // uses actionItemStyle (the row resolves itself)
///          ├─ leading: action.icon
///          └─ label: actionLabel (<div>)        // one-line truncate wrapper around action.label
/// ```
///
/// `fab.dart` reads each slot's `className` + `inlineStyles` straight from
/// `resolved.<slot>` — no merge / fallback / conversion in the widget body.
class ResolvedFab implements WebResolvedChrome {
  /// Creates a [ResolvedFab].
  const ResolvedFab({
    required this.root,
    required this.buttonStyle,
    required this.extendedButtonStyle,
    required this.actionItemStyle,
    required this.actionLabel,
    required this.popupStyle,
    required this.popoverStyle,
  });

  /// Paint-ready chrome for the outermost DOM element `Fab` emits. When
  /// the FAB has actions it returns the composed `Popover` directly (the
  /// popover owns its own root chrome), so this slot only drives the
  /// no-action fallback wrapper — an `inline-flex` shrink-wrap carrying the
  /// caller chrome around the single main `Button`.
  @override
  final WebElementChrome root;

  /// Nested [CoreButtonStyle] slot — raw-forwarded to the main FAB
  /// `Button` (variant `primary`). The circle diameter is baked into
  /// `width` / `height` and the icon style (size + any caller colour) into
  /// `leadingIconStyle`, which the composed `Button` hands to its content
  /// as an ambient `IconTheme`; it resolves its own colour / hover / focus
  /// ring.
  final CoreButtonStyle buttonStyle;

  /// **Extended** FAB chrome — 라벨을 가진 알약. 높이만 지름으로 굳히고
  /// 폭은 라벨이 정하게 둔다(원형과 달리 `width` 를 굽지 않는다).
  ///
  /// 아이콘 크기는 진술하지 않는다 — Extended 의 글리프는 합성되는 `Button`
  /// 의 `leading` 슬롯에 들어가고 그 크기는 Button 이 자기 사이즈로 정한다.
  final CoreButtonStyle extendedButtonStyle;

  /// Nested [CoreMenuItemStyle] slot — raw-forwarded to each action row
  /// `MenuItem`. The FAB's size row states the inset, icon, icon-label gap
  /// and label role (and, for `large`, the height floor); the rest the row
  /// resolves itself at [CoreFabContract.actionItemSize].
  final CoreMenuItemStyle actionItemStyle;

  /// Layout-only wrapper around an action's label inside the row's text
  /// seat: one line, ending in an ellipsis once the panel reaches its
  /// maximum width (the Flutter row's `maxLines: 1`). Carries no chrome —
  /// the label's typography and colour are the `MenuItem` row's own.
  final WebElementChrome actionLabel;

  /// Nested [CorePopupStyle] slot — raw-forwarded to the composed `Popup`
  /// that holds the rows (`Popup` runs its own resolve step).
  final CorePopupStyle popupStyle;

  /// Nested [CorePopoverStyle] slot — raw-forwarded to the composed
  /// `Popover` that hosts the menu. Chrome-less
  /// ([CoreFabStyle.defaultPopoverStyle]) because the `Popup` above is the
  /// visible box; its `panelStyle` carries the open / close motion and its
  /// `placementOffset` the FAB-to-menu gap.
  final CorePopoverStyle popoverStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFab] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreFabStyle.defaultX / defaultsBySize)
///   → theme.coreComponentTheme.fab.style
///   → widget.fabStyle
/// ```
///
/// The semantic [size] is a widget prop — it threads through to pick the
/// size token table here. The theme cannot override it (`CoreFabTheme`
/// carries the single [CoreFabStyle] `style` slot, no semantic
/// identifiers).
ResolvedFab resolveFab(
  BuildContext context, {
  required CoreFabSize size,
  CoreFabStyle? fabStyle,
}) {
  final fabTheme = context.theme.coreComponentTheme?.fab;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFabStyle(), [
    fabTheme?.style,
    fabStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (diameter / iconStyle).
  final sizeStyle = CoreFabStyle.defaultsBySize[size]!;

  // ─── Dimensions (raw — Web stores logical px and lets CSS rem track the
  // accessibility text scale; no `* scaling` here, unlike Flutter) ──────
  final diameter = merged.diameter ?? sizeStyle.diameter!;
  final iconStyle = sizeStyle.iconStyle!.merge(merged.iconStyle);
  final iconSize = iconStyle.size ?? 0;

  // ─── Composed Button chrome (raw-forward) ─────────────
  // Circle chrome flows through the nested `CoreButtonStyle` slot; the
  // diameter is baked into width/height and the icon style into
  // `leadingIconStyle` so the composed `Button` paints an exact circle and
  // sizes / tints the glyph through its ambient icon theme (single source
  // — no icon-theme wrapper in the widget). The composed `Button` resolves
  // its own colour / hover / focus ring.
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
      .merge(sizeStyle.extendedButtonStyle)
      .merge(merged.extendedButtonStyle)
      .copyWith(height: diameter);
  // ─── Action rows (raw-forward to composed MenuItem) ──
  // The row is a `MenuItem`, which resolves its own insets, corner, icon
  // and label typography, so the slot is forwarded untouched — no restating
  // of the icon size, no label class assembled here.
  // `effectiveActionItemStyle` folds the deprecated Button-row fields
  // (`actionButtonStyle` / `actionIconStyle` / `actionLabelTextStyle`)
  // under `actionItemStyle`, once in Core, so both platforms read them the
  // same way.
  // guard-nested-override: actionItemStyle — `merged.actionItemStyle` is
  // merged on top inside `effectiveActionItemStyle`, so it wins field by
  // field over the folded deprecated slots.
  final actionItemStyle = CoreFabStyle.defaultActionItemStyle
      .merge(sizeStyle.actionItemStyle)
      .merge(merged.effectiveActionItemStyle);

  // ─── Menu panel (raw-forward to composed Popup) ──────
  final popupStyle = CoreFabStyle.defaultPopupStyle
      .merge(sizeStyle.popupStyle)
      .merge(merged.popupStyle);

  // ─── Overlay host (raw-forward to composed Popover) ──
  // The chrome-less panel lets the `Popup` be the visible box. The
  // FAB-to-menu gap is the popover placement offset — the FAB `spacing`
  // token unless the caller pinned an offset. `duration` is the menu's
  // open / close motion, so it lands on the host panel's own animation
  // fields unless the caller pinned those too.
  final spacing = merged.spacing ?? sizeStyle.spacing!;
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

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedFab(
    // `inline-flex` so the no-action fallback wrapper shrink-wraps the
    // single main `Button` (the with-action FAB returns the `Popover`
    // directly and never reads this slot).
    root: const WebElementChrome(className: WebLayout.inlineFlex),
    buttonStyle: buttonStyle,
    extendedButtonStyle: extendedButtonStyle,
    actionItemStyle: actionItemStyle,
    actionLabel: const WebElementChrome(className: WebLayout.truncate),
    popupStyle: popupStyle,
    popoverStyle: popoverStyle,
  );
}
