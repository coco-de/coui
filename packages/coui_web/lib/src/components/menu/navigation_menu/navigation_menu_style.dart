/// Style-slot single entry point for the Web `NavigationMenu`.
///
/// Mirrors the Flutter `navigation_menu_style.dart`: a
/// `resolveNavigationMenu` merge function that walks the nested
/// merge chain (`CoreNavigationMenuStyle.defaultX` /
/// `defaultsByVariant` → `theme.navigationMenu.style` →
/// `theme.navigationMenu.variantStyles[variant]` →
/// `widget.navigationMenuStyle`) and ships back a
/// [ResolvedNavigationMenu] paint-ready chrome bundle.
///
/// All slots — including the per-trigger chrome (its chrome depends
/// on the runtime `highlighted` flag) and the per-trigger chevron
/// chrome (its chrome depends on the runtime `open` flag) — flow
/// through the single [resolveNavigationMenu] entry point so
/// `navigation_menu.dart` only reads a slot's `className` and
/// `inlineStyles`, never composing inline CSS itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Per-trigger runtime state forwarded to [resolveNavigationMenu] so
/// the resolver can pre-compose each trigger `<a>` / `<div
/// role="menuitem">` plus its optional chevron `<span>` chrome.
class NavigationMenuTriggerState {
  /// Creates a [NavigationMenuTriggerState].
  const NavigationMenuTriggerState({
    required this.highlighted,
    required this.open,
    required this.hasContent,
  });

  /// Whether the trigger is hovered or has its panel open — paints
  /// the hover background fill.
  final bool highlighted;

  /// Whether the trigger's panel is currently open — drives the
  /// chevron rotation.
  final bool open;

  /// Whether the trigger has a content panel — drives whether a
  /// chevron `<span>` chrome slot is emitted.
  final bool hasContent;
}

/// Pre-composed [WebElementChrome] bundle for a single navigation
/// trigger — the trigger element plus its optional chevron.
class ResolvedNavigationMenuTrigger {
  /// Creates a [ResolvedNavigationMenuTrigger].
  const ResolvedNavigationMenuTrigger({
    required this.trigger,
    required this.buttonStyle,
    this.chevron,
  });

  /// Paint-ready chrome for the trigger element (`<a>` for links,
  /// `<div role="menuitem">` for content / action triggers).
  final WebElementChrome trigger;

  /// Nested [CoreButtonStyle] raw-forwarded to this trigger's
  /// `Button(variant: menubar)` — the plain trigger style for a trigger
  /// without a dropdown, the content-trigger style (directional inset) for
  /// one that owns a dropdown, and that plus the open fill while its
  /// dropdown is open. The runtime state selects among Core-defined
  /// partials; nothing is assembled here.
  final CoreButtonStyle buttonStyle;

  /// Paint-ready chrome for the chevron `<span>` — non-null when the
  /// trigger has a content panel, `null` otherwise.
  final WebElementChrome? chevron;
}

// ════════════════════════════════════════════════════════════════
// ResolvedNavigationMenu
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `NavigationMenu`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="menubar">)                                // horizontal bar wrapper, gap=triggerSpacing
///   ├─ trigger (<a> | <div role="menuitem"> × n)             // per-trigger via triggers[i].trigger
///   │    ├─ label text
///   │    └─ chevron <span> (only when has content)           // per-trigger via triggers[i].chevron
///   └─ <div fixed z-10 id=panel>                              // panel positioning wrapper (engine-measured)
///        └─ panel (<div role="menu">)                         // state-independent panel chrome
/// ```
///
/// Every slot is a paint-ready [WebElementChrome] —
/// `co_navigation_menu.dart` reads `resolved.<slot>.className` /
/// `resolved.<slot>.inlineStyles` straight off. Runtime per-trigger
/// state ([NavigationMenuTriggerState] list) flows into
/// [resolveNavigationMenu] as an argument; the widget re-invokes the
/// resolver every build.
///
/// The vertical bar → panel gap is *not* carried here — it feeds the
/// unified overlay positioning engine as the trigger↔panel gap, not
/// chrome of any element this resolver renders, so the widget reads it
/// (alongside the dropdown placement) from the merge chain via
/// [resolveNavigationMenuConfig] (the number_ticker separate-resolver
/// pattern).
class ResolvedNavigationMenu implements WebResolvedChrome {
  /// Creates a [ResolvedNavigationMenu].
  const ResolvedNavigationMenu({
    required this.root,
    required this.panel,
    required this.triggers,
    required this.chevronIconStyle,
    required this.triggerButtonStyle,
    required this.runtime,
  });

  /// Paint-ready chrome for the outer `<div role="menubar">` bar
  /// container — horizontal flex row hosting all top-level triggers.
  /// Inline styles include the inter-trigger `gap` CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the dropdown `<div role="menu">` panel
  /// container — flex column with the full inline panel chrome
  /// (background / border / radius / shadow / padding / min-width).
  final WebElementChrome panel;

  /// Paint-ready chrome for each top-level trigger (one entry per
  /// [NavigationMenuTriggerState]).
  final List<ResolvedNavigationMenuTrigger> triggers;

  /// Chevron disclosure icon style of a content trigger — raw-forwarded
  /// to `Icon`, which runs its own resolver (size / colour resolution
  /// are `Icon`'s responsibility, so this slot is not pre-resolved
  /// here).
  final CoreIconStyle chevronIconStyle;

  /// Nested [CoreButtonStyle] raw-forwarded to a top-level trigger without
  /// a dropdown — `CoreNavigationMenuStyle.defaultTriggerButtonStyle` merged
  /// with the per-instance override. Kept for readers that want the plain
  /// style; each trigger's own style is
  /// [ResolvedNavigationMenuTrigger.buttonStyle].
  final CoreButtonStyle triggerButtonStyle;

  /// Client-side runtime config — the dropdown panel's open / close motion
  /// durations (behaviour timings, not DOM chrome). Held in the separate
  /// [ResolvedNavigationMenuRuntime] holder so this chrome bundle carries
  /// only paint-ready element slots.
  final ResolvedNavigationMenuRuntime runtime;
}

/// Client-side runtime config for Web `NavigationMenu`. Fed to the
/// client-side overlay animator — the dropdown panel's open / close motion
/// durations. No DOM chrome (does not implement `WebResolvedChrome`): these
/// are behaviour timings `navigation_menu.dart` reads to drive the
/// `co-overlay-enter` / `co-overlay-exit` keyframes and to size the exit
/// timer that keeps the panel mounted through the close transition.
class ResolvedNavigationMenuRuntime {
  /// Creates a [ResolvedNavigationMenuRuntime].
  const ResolvedNavigationMenuRuntime({
    required this.openAnimationDuration,
    required this.closeAnimationDuration,
    required this.closeDelay,
    required this.panelSwitchDuration,
  });

  /// Open (enter) animation duration of the dropdown panel — resolved
  /// from the panel `Popup`'s [CorePopupStyle] (single source for every
  /// menu's portal motion). Drives the `co-overlay-enter` keyframes.
  final Duration openAnimationDuration;

  /// Close (exit) animation duration of the dropdown panel — resolved
  /// from the panel `Popup`'s [CorePopupStyle]. The panel stays mounted
  /// for this long (playing `co-overlay-exit`) before unmounting.
  final Duration closeAnimationDuration;

  /// Grace period between the pointer leaving the menu (a trigger or the
  /// open panel) and the close being committed. Sizes the pointer-intent
  /// timer in `navigation_menu.dart`, which any re-entry cancels.
  final Duration closeDelay;

  /// Duration of the panel's travel when the open menu moves from one
  /// trigger to another — drives the `co-overlay-switch` and
  /// `co-overlay-swap-*` keyframes and sizes the timer that keeps the
  /// outgoing content mounted through the cross-fade.
  final Duration panelSwitchDuration;
}

// ════════════════════════════════════════════════════════════════
// resolveNavigationMenu — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedNavigationMenu] for the given [context].
///
/// Runtime per-trigger state ([triggers]) flows in as an argument so
/// the resolver can pre-compose each trigger / chevron slot.
ResolvedNavigationMenu resolveNavigationMenu(
  BuildContext context, {
  required CoreNavigationMenuVariant variant,
  required List<NavigationMenuTriggerState> triggers,
  CoreNavigationMenuStyle? navigationMenuStyle,
}) {
  final menuTheme = context.theme.coreComponentTheme?.navigationMenu;

  // Per-variant panel colours — defaultsByVariant single source of truth.
  final variantPanel = CoreNavigationMenuStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → component.navigationMenuStyle.
  final merged = resolveStyleChain(const CoreNavigationMenuStyle(), [
    menuTheme?.style,
    menuTheme?.variantStyles?[variant],
    navigationMenuStyle,
  ]);

  // ─── Panel box chrome — composed `Popup` (single source) ──
  // The dropdown panel is a `Popup`: run its resolver on the merged panel
  // style (variant-independent `defaultPanelStyle` ← variant background /
  // border ← per-instance override) so the box background / border /
  // radius / padding / shadow / min-width emit lives in one place, not
  // re-implemented here.
  final panelChrome = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: CoreNavigationMenuStyle.defaultPanelStyle
        .merge(variantPanel)
        .merge(merged.panelStyle),
  );

  // ─── Resolved trigger chrome values ───────────────────
  final triggerSpacing =
      merged.triggerSpacing ?? CoreNavigationMenuStyle.defaultTriggerSpacing;
  final triggerSpacingCss = spaceCss(triggerSpacing);

  final triggerPadding =
      (merged.triggerPadding ?? CoreNavigationMenuStyle.defaultTriggerPadding)
          .toValue();
  final triggerBorderRadius =
      (merged.triggerBorderRadius ??
              CoreNavigationMenuStyle.defaultTriggerBorderRadius)
          .toValue();
  final chevronIconStyle =
      merged.chevronIconStyle ??
      CoreNavigationMenuStyle.defaultChevronIconStyle;
  final duration = (merged.duration ?? CoreNavigationMenuStyle.defaultDuration)
      .inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
  final chevronTransitionTiming =
      '${durationMsCss(duration)} ${CoreEasing.move.toVarCss()}';

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Colours route through the emit family — a single class-XOR-inline
  // decision per design value. Token-bound values (variant / design-system
  // defaults AND token overrides) emit a Tailwind class so they stay
  // dark-mode reactive; a raw override goes inline. No `cs.resolve`
  // (a no-op on Web; CSS resolves `--coui-*` at runtime).
  // Hover / active background — the `highlighted` flag is a Dart runtime
  // state (hovered OR panel-open), not the pure CSS `:hover` pseudo-class,
  // so the fill is applied as a runtime-conditional inline value rather
  // than a `hover:bg-*` class. `.toValue()` (theme-free) emits the token's
  // `rgb(var(--coui-X))` so the inline fill stays dark-mode reactive.
  final triggerHoverColor =
      (merged.triggerHoverColor ??
              CoreNavigationMenuStyle.defaultTriggerHoverColor)
          .toValue();

  // ─── Trigger label typography (sb-text-style-repackage) ─
  // `emitTypography` merges the design-system default (`labelLarge` role +
  // medium weight + `onSurface` colour) with the per-instance
  // `triggerTextStyle` overlay, emitting the `text-{role}` + `text-{colour}`
  // role / colour classes and any explicit scalar overlay (font weight)
  // inline — single canonical typography entry point.
  final triggerTextEmit = emitTypography(
    merged.triggerTextStyle,
    CoreNavigationMenuStyle.defaultTriggerTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the bar `<div role="menubar">` Tailwind className —
  /// horizontal flex row hosting all top-level triggers. The
  /// inter-trigger `gap` is set via inline CSS so it tracks the
  /// runtime [triggerSpacing] value.
  String buildRootClassName() => WebLayout.flexRowItemsCenter;

  /// Composes the bar `<div role="menubar">` inline-CSS bundle —
  /// inter-trigger flex `gap` only.
  Styles buildRootInlineStyles() {
    return Styles(raw: {'gap': triggerSpacingCss});
  }

  /// Composes a single trigger Tailwind className — flex row, cursor +
  /// select chrome, no-underline (for the `<a>` variant), and the
  /// trigger label typography role / colour classes from the
  /// `emitTypography` result (sb-text-style-repackage).
  String buildTriggerClassName() {
    final classList = [
      WebLayout.flexRowItemsCenter,
      'cursor-pointer select-none ${WebLayout.whitespaceNowrap} no-underline',
      'transition-colors',
      triggerTextEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes a single trigger inline-CSS bundle — padding + radius +
  /// hover transition duration always; the typography overlay (font
  /// weight) inline; hover background only when [highlighted]. Only a link
  /// trigger paints this box (a `Button` trigger carries its chrome through
  /// its own style), and a link shows no chevron.
  Styles buildTriggerInlineStyles({required bool highlighted}) {
    final raw = {
      'padding': triggerPadding,
      'border-radius': triggerBorderRadius,
      'transition-duration': '${duration}ms',
      ...?triggerTextEmit.inline,
    };
    if (highlighted) {
      raw['background-color'] = triggerHoverColor;
    }
    return Styles(raw: raw);
  }

  /// Composes the chevron `<span>` inline-CSS bundle — inline-flex
  /// alignment + transform transition + rotation when open.
  Styles buildChevronInlineStyles({required bool open}) {
    return Styles(
      raw: {
        'display': 'inline-flex',
        'transition': 'transform $chevronTransitionTiming',
        'transform': open ? 'rotate(180deg)' : 'rotate(0deg)',
      },
    );
  }

  // Nested Button styles — raw-forward the Core slots (no assembly): the
  // composed `Button` owns the resting fill and the resolution of every
  // colour. A trigger that owns a dropdown starts from the same defaults
  // plus its own inset; the per-instance `triggerButtonStyle` still reaches
  // it, then the content-specific override wins. The open one adds its fill
  // last. Which of the three a trigger takes is its runtime state, picked
  // per trigger below.
  final triggerButtonStyle = CoreNavigationMenuStyle.defaultTriggerButtonStyle
      .merge(merged.triggerButtonStyle);
  final contentTriggerButtonStyle = CoreNavigationMenuStyle
      .defaultTriggerButtonStyle
      .merge(CoreNavigationMenuStyle.defaultContentTriggerButtonStyle)
      .merge(merged.triggerButtonStyle)
      .merge(merged.contentTriggerButtonStyle);
  final openTriggerButtonStyle = contentTriggerButtonStyle
      .merge(CoreNavigationMenuStyle.defaultOpenTriggerButtonStyle)
      .merge(merged.openTriggerButtonStyle);

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedNavigationMenu(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    panel: panelChrome.root,
    triggers: [
      for (final state in triggers)
        ResolvedNavigationMenuTrigger(
          trigger: WebElementChrome(
            className: buildTriggerClassName(),
            inlineStyles: buildTriggerInlineStyles(
              highlighted: state.highlighted,
            ),
          ),
          buttonStyle: !state.hasContent
              ? triggerButtonStyle
              : state.open
              ? openTriggerButtonStyle
              : contentTriggerButtonStyle,
          chevron: state.hasContent
              ? WebElementChrome(
                  className: '',
                  inlineStyles: buildChevronInlineStyles(open: state.open),
                )
              : null,
        ),
    ],
    chevronIconStyle: chevronIconStyle,
    triggerButtonStyle: triggerButtonStyle,
    // Portal motion durations — resolved from the panel `Popup`'s
    // `CorePopupStyle` (single source for every menu), user-overridable via
    // `navigationMenuStyle.panelStyle.openAnimationDuration`. Nested in the
    // non-chrome `ResolvedNavigationMenuRuntime` holder (category D) so the
    // chrome bundle stays paint-ready element slots only.
    runtime: ResolvedNavigationMenuRuntime(
      openAnimationDuration: panelChrome.style.openAnimationDuration!,
      closeAnimationDuration: panelChrome.style.closeAnimationDuration!,
      closeDelay:
          merged.closeDelay ?? CoreNavigationMenuStyle.defaultCloseDelay,
      panelSwitchDuration:
          merged.panelSwitchDuration ??
          CoreNavigationMenuStyle.defaultPanelSwitchDuration,
    ),
  );
}

/// Resolves the unified `OverlayPositioner` inputs for `NavigationMenu`
/// — the dropdown [CorePopoverPlacement] (anchored to the active
/// trigger's bottom-start corner) and the bar↔panel gap (the merged
/// `menuOffset` override, falling back to the design-system default). The
/// engine's default collision policy ({flip, shift}) keeps the dropdown
/// inside the viewport.
///
/// Walks the same merge chain as [resolveNavigationMenu]
/// (design-system default → `theme.navigationMenu.style` →
/// `theme.navigationMenu.variantStyles[variant]` →
/// `widget.navigationMenuStyle`). Kept as a separate `resolveCo*` entry
/// point so [ResolvedNavigationMenu] stays pure paint-ready chrome
/// (number_ticker separate-resolver pattern).
({CorePopoverPlacement placement, double gap}) resolveNavigationMenuConfig(
  BuildContext context, {
  required CoreNavigationMenuVariant variant,
  CoreNavigationMenuStyle? navigationMenuStyle,
}) {
  final menuTheme = context.theme.coreComponentTheme?.navigationMenu;
  final merged = resolveStyleChain(const CoreNavigationMenuStyle(), [
    menuTheme?.style,
    menuTheme?.variantStyles?[variant],
    navigationMenuStyle,
  ]);
  final gap = merged.menuOffset ?? CoreNavigationMenuStyle.defaultMenuOffset;
  return (placement: CorePopoverPlacement.bottomStart, gap: gap);
}
