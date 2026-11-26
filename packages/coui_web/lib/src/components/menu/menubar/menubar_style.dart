/// Style-slot single entry point for the Web `Menubar`.
///
/// Mirrors the Flutter `menubar_style.dart`: a `resolveMenubar` merge
/// function that walks the nested merge chain (`CoreMenubarStyle.defaultX`
/// / `defaultsByVariant` → `theme.menubar.style` →
/// `theme.menubar.variantStyles[variant]` → `widget.menubarStyle`) and
/// ships back a [ResolvedMenubar] paint-ready chrome bundle.
///
/// The dropdown panel composes the unified `Menu` (box + rows + dividers +
/// shortcuts resolve inside `Menu`), so the resolver carries only the bar
/// chrome, the trigger button slot, the panel positioning wrapper, and the
/// panel `Popup`'s animation durations + raw-forwarded [CorePopupStyle]
/// panel slot. Every remaining slot flows through the single
/// [resolveMenubar] entry point so `menubar.dart` only reads
/// `resolved.<slot>.className / inlineStyles`, never composing inline CSS
/// itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedMenubar
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Menubar`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="menubar">)                       // horizontal bar wrapper
///   ├─ Button(variant: menubar) × n                 // per-trigger, chrome via triggerButtonStyle
///   └─ panelPosition (<div fixed z-10>)             // floating wrapper, baked top/left
///        └─ Menu (<div role="menu">)               // composed Menu (box + rows)
/// ```
///
/// The dropdown panel is a composed `Menu` (it paints the box / rows /
/// dividers / shortcuts itself from [menuPanelStyle]). The triggers are
/// composed `Button`s (chrome via [triggerButtonStyle]). Every other slot
/// is a paint-ready [WebElementChrome] — `menubar.dart` reads
/// `resolved.<slot>.className` / `.inlineStyles` straight off. Runtime
/// state (`variant`, `border`, anchor rect) flows into [resolveMenubar] as
/// arguments; the widget re-invokes the resolver every build.
class ResolvedMenubar implements WebResolvedChrome {
  /// Creates a [ResolvedMenubar].
  const ResolvedMenubar({
    required this.root,
    required this.panelPosition,
    required this.menuPanelStyle,
    required this.triggerButtonStyle,
    required this.openTriggerButtonStyle,
    required this.runtime,
  });

  /// Paint-ready chrome for the outer `<div role="menubar">` bar
  /// container — horizontal flex row, padding always, full bar chrome
  /// (background / border / radius) only when `border` is set.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the floating `<div fixed z-10>` wrapper
  /// that hosts the open-menu panel — the flip/shift-resolved
  /// viewport-space `(left, top)` origin (reported by the unified
  /// `OverlayPositioner`) baked into `position: fixed` `top` / `left`.
  /// `inlineStyles` is `null` until the first frame resolves the position.
  final WebElementChrome panelPosition;

  /// Raw merged panel [CorePopupStyle] (menubar-divergent default ← theme /
  /// per-instance override) raw-forwarded to the composed `Menu`'s panel
  /// slot — the dropdown box is rendered by `Menu` (Epic #2676 L2-c), so the
  /// menubar carries the panel style as a nested slot rather than re-painting
  /// the box itself.
  final CorePopupStyle menuPanelStyle;

  /// Nested [CoreButtonStyle] raw-forwarded to the top-level trigger
  /// `Button(variant: menubar)` — `CoreMenubarStyle.defaultTriggerButtonStyle`
  /// merged with the per-instance override. The `.menubar` variant owns the
  /// resting / hover (CSS `:hover`) / open (`aria-selected`) fill, so this
  /// is the single source for the trigger's button chrome (no resolver-side
  /// assembly).
  final CoreButtonStyle triggerButtonStyle;

  /// Nested [CoreButtonStyle] raw-forwarded to the trigger whose menu is
  /// open — [triggerButtonStyle] with the open trigger's overlay (the
  /// heavier label weight) laid on top
  /// ([CoreMenubarStyle.defaultOpenTriggerButtonStyle], then the
  /// per-instance `openTriggerButtonStyle`). The open fill itself is the
  /// `menubar` `Button` variant's selected fill (`aria-selected`).
  final CoreButtonStyle openTriggerButtonStyle;

  /// Client-side runtime config — the dropdown panel's open / close motion
  /// durations (behaviour timings, not DOM chrome). Held in the separate
  /// [ResolvedMenubarRuntime] holder so this chrome bundle carries only
  /// paint-ready element slots.
  final ResolvedMenubarRuntime runtime;
}

/// Client-side runtime config for Web `Menubar`. Fed to the client-side
/// overlay animator — the dropdown panel's open / close motion durations.
/// No DOM chrome (does not implement `WebResolvedChrome`): these are
/// behaviour timings `menubar.dart` reads to drive the `co-overlay-enter` /
/// `co-overlay-exit` keyframes and to size the exit timer that keeps the
/// panel mounted through the close transition.
class ResolvedMenubarRuntime {
  /// Creates a [ResolvedMenubarRuntime].
  const ResolvedMenubarRuntime({
    required this.openAnimationDuration,
    required this.closeAnimationDuration,
  });

  /// Open (enter) animation duration of the dropdown panel — resolved
  /// from the panel `Popup`'s [CorePopupStyle] (single source for every
  /// menu's portal motion). Drives the `co-overlay-enter` keyframes.
  final Duration openAnimationDuration;

  /// Close (exit) animation duration of the dropdown panel — resolved
  /// from the panel `Popup`'s [CorePopupStyle]. The panel stays mounted
  /// for this long (playing `co-overlay-exit`) before unmounting.
  final Duration closeAnimationDuration;
}

// ════════════════════════════════════════════════════════════════
// resolveMenubar — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedMenubar] for the given [context].
///
/// Runtime state (`variant` / `border`) flows in as arguments. The triggers
/// are composed `Button`s (per-state chrome owned by the `.menubar`
/// variant) and the panel is a composed `Menu`, so the resolver ships only
/// the bar chrome, the trigger button slot, and the panel positioning /
/// durations. [left] / [top] are the flip/shift-resolved viewport-space
/// origin reported by the unified `OverlayPositioner` (`onPosition`); they
/// bake into [ResolvedMenubar.panelPosition].
ResolvedMenubar resolveMenubar(
  BuildContext context, {
  required CoreMenubarVariant variant,
  required bool border,
  double? left,
  double? top,
  CoreMenubarStyle? menubarStyle,
}) {
  final menubarTheme = context.theme.coreComponentTheme?.menubar;

  // Variant chrome — defaultsByVariant single source of truth.
  final chrome = CoreMenubarStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → component.menubarStyle.
  final merged = resolveStyleChain(const CoreMenubarStyle(), [
    menubarTheme?.style,
    menubarTheme?.variantStyles?[variant],
    menubarStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final barPadding = merged.barPadding ?? CoreMenubarStyle.defaultBarPadding;
  final barBorderRadius =
      merged.barBorderRadius ?? CoreMenubarStyle.defaultBarBorderRadius;
  final barBorderWidth =
      merged.barBorderWidth ?? CoreMenubarStyle.defaultBarBorderWidth;
  // Raw merged panel style (menubar-divergent `defaultMenuPanelStyle` ←
  // theme / per-instance override) — raw-forwarded to the composed `Menu`'s
  // panel slot (Epic #2676 L2-c). Also fed to `resolvePopup` for the
  // panel-motion durations.
  final menuPanelStyle = CoreMenubarStyle.defaultMenuPanelStyle
      .merge(CorePopupStyle(surfaceStyle: merged.surfaceStyle))
      .merge(merged.menuPanelStyle);
  final panelChrome = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: menuPanelStyle,
  );

  // Nested trigger Button style — raw-forward the Core slot (no
  // resolver-side assembly), with the resolved [labelTextStyle] (default
  // merged with the per-instance override) injected as an intermediate
  // layer so the caller's own `triggerButtonStyle.labelStyle` (if set)
  // still wins on top — mirrors the Banner dismiss-button colour
  // injection pattern. The dropdown entry chrome is owned by the
  // composed `Menu`.
  final labelTextStyle = CoreMenubarStyle.defaultLabelTextStyle.merge(
    merged.labelTextStyle,
  );
  final triggerButtonStyle = CoreMenubarStyle.defaultTriggerButtonStyle
      .merge(CoreButtonStyle(labelStyle: labelTextStyle))
      .merge(merged.triggerButtonStyle);
  // The open trigger adds its overlay (the heavier label weight) on top of
  // the resting style — the same shape `NavigationMenu` gives its open
  // trigger.
  final openTriggerButtonStyle = triggerButtonStyle
      .merge(CoreMenubarStyle.defaultOpenTriggerButtonStyle)
      .merge(merged.openTriggerButtonStyle);

  // ─── Colour EMIT (class XOR inline) — bar chrome only ───
  // `emitColor` routes a token colour to a Tailwind class (dark-mode
  // reactive) and a raw override to inline CSS. The trigger hover fill is
  // owned by the composed `Button`'s `.menubar` variant.
  final barBgEmit = emitColor(
    merged.barBackgroundColor,
    chrome.barBackgroundColor,
    .background,
  );
  final barBorderEmit = emitColor(
    merged.barBorderColor,
    chrome.barBorderColor,
    .border,
  );

  // Pre-converted CSS strings (radius / padding / dimension always inline).
  final barBorderRadiusValue = barBorderRadius.toValue();
  final barBorderWidthCss = strokeWidthCss(barBorderWidth);
  // A bordered bar's padding is measured from its outer edge, the border
  // included (Flutter's `DecoratedBox` paints the border over it), so the
  // border comes out of the padding rather than adding to the bar.
  final barPaddingDeclarations = border && barBorderWidth > 0
      ? barPadding.toDeclarationsWithinBorder('padding', barBorderWidthCss)
      : {'padding': barPadding.toValue()};

  // ─── Local builders ───────────────────────────────────

  /// Composes the bar `<div role="menubar">` Tailwind className —
  /// horizontal flex row; when bordered, the `border` utility plus the
  /// `emitColor` background / border colour classes (raw colours fall
  /// through to inline CSS).
  String buildRootClassName() {
    final classes = [WebLayout.flex, WebLayout.flexRow, WebLayout.itemsCenter];
    if (border) {
      // Inside the border branch, not before it: `border: false` draws no
      // box, and a cast thrown by a box that is not there is a floating
      // dark rectangle. Flutter gates the whole decoration the same way.
      classes.addAll([
        kControlShadowRestMarker,
        // surface:functional — the bar mounts its dropdown through
        // `OverlayPositioner`/`OverlayPortal`, floating chrome over the
        // page it sits on. Paired with the fill published below — the
        // marker alone resolves a preset's restated colour to nothing.
        ...webSurfaceMarkerFor(.functional, surfaceStyle: merged.surfaceStyle),
        'border',
        barBgEmit.className,
        barBorderEmit.className,
      ]);
    }
    return classes.where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the bar `<div role="menubar">` inline-CSS bundle —
  /// padding always; full chrome (`emitColor` raw fallbacks + border
  /// width / radius) only when bordered.
  Styles buildRootInlineStyles() {
    final raw = {...barPaddingDeclarations};
    if (border) {
      final bgInline = barBgEmit.inline;
      final borderInline = barBorderEmit.inline;
      if (bgInline != null) raw.addAll(bgInline);
      if (borderInline != null) raw.addAll(borderInline);
      raw['border-width'] = barBorderWidthCss;
      raw.addAll(surfaceBleedVar(barBorderWidthCss));
      raw['border-radius'] = barBorderRadiusValue;
      // The marker's other half — a preset restates this fill at a lower
      // alpha and cannot know which token the bar chose.
      raw.addAll(
        surfaceFillVar(merged.barBackgroundColor ?? chrome.barBackgroundColor),
      );
    }
    return Styles(raw: raw);
  }

  /// Composes the floating panel-wrapper `<div>` className —
  /// `fixed z-${CoreZIndex.scale.z10}` (dropdown-menu layer) stacks it
  /// above ordinary in-flow content. The mounted-but-unplaced
  /// flash is suppressed by the INNER motion box's closed-state
  /// `opacity-0` + `pointer-events-none`, so no `invisible` is needed here.
  String buildPanelPositionClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z10}';

  /// Composes the floating panel-wrapper inline-CSS bundle — the
  /// flip/shift-resolved viewport-space `(top, left)` origin (rem)
  /// reported by the unified `OverlayPositioner`. Returns `null` until the
  /// first frame resolves the position.
  Styles? buildPanelPositionInlineStyles() {
    if (left == null || top == null) return null;
    return Styles(
      raw: {
        'top': '${top / kRemDivisor}rem',
        'left': '${left / kRemDivisor}rem',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedMenubar(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    panelPosition: WebElementChrome(
      className: buildPanelPositionClassName(),
      inlineStyles: buildPanelPositionInlineStyles(),
    ),
    menuPanelStyle: menuPanelStyle,
    triggerButtonStyle: triggerButtonStyle,
    openTriggerButtonStyle: openTriggerButtonStyle,
    // Portal motion durations — resolved from the panel `Popup`'s
    // `CorePopupStyle` (single source for every menu), user-overridable via
    // `menubarStyle.menuPanelStyle.openAnimationDuration`. Nested in the
    // non-chrome `ResolvedMenubarRuntime` holder (category D) so the chrome
    // bundle stays paint-ready element slots only.
    runtime: ResolvedMenubarRuntime(
      openAnimationDuration: panelChrome.style.openAnimationDuration!,
      closeAnimationDuration: panelChrome.style.closeAnimationDuration!,
    ),
  );
}

/// Resolves the `OverlayPositioner` inputs for the menubar dropdown — the
/// fixed [CorePopoverPlacement.bottomStart] placement (the panel opens
/// below the trigger, start-aligned) and the trigger↔panel gap (the
/// merged `menuOffset` override, falling back to the design-system
/// default). The engine's default collision policy ({flip, shift}) keeps
/// the panel inside the viewport.
///
/// The gap carries the bar's bottom padding, which is spacing: the bar's
/// own CSS padding moves with the [density] through the spacing variable,
/// so the number handed to the engine is moved by the same density — the
/// one the document carries when the menu opens.
({CorePopoverPlacement placement, double gap}) resolveMenubarConfig(
  BuildContext context, {
  required bool border,
  CoreDensity density = CoreDensity.defaultDensity,
  CoreMenubarStyle? menubarStyle,
}) {
  final merged = resolveStyleChain(const CoreMenubarStyle(), [
    context.theme.coreComponentTheme?.menubar?.style,
    menubarStyle,
  ]);
  final menuOffset = merged.menuOffset ?? CoreMenubarStyle.defaultMenuOffset;
  // The positioner anchors the panel to the trigger BUTTON, which sits
  // inside the bar's bottom padding (+ border when shown). Extend the gap
  // by that below-button chrome so the panel clears the whole bar rather
  // than overlapping its bottom edge — parity with Flutter, whose panel
  // opens below the bar box, not the inset button.
  final barPadding = merged.barPadding ?? CoreMenubarStyle.defaultBarPadding;
  final barBorderWidth = border
      ? (merged.barBorderWidth ?? CoreMenubarStyle.defaultBarBorderWidth)
      : 0.0;
  final gap = menuOffset + density.space(barPadding.bottom) + barBorderWidth;
  return (placement: CorePopoverPlacement.bottomStart, gap: gap);
}
