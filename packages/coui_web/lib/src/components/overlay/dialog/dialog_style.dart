import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart'
    show overlayFadeProperties;
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Dialog`.
///
/// DOM shape (closed state renders only [hidden]):
///
/// ```text
/// root (<div coui-dialog>)                   // container wrapper
///   ├─ backdrop (<div fixed inset-0 z-40>)   // scrim (overlay-backdrop layer)
///   └─ panel (<div fixed centered z-50>)     // centered panel (modal/dialog layer)
///        ├─ header (<div flex items-center shrink-0>) // co_dialog renders only when title / leading / trailing present
///        │    ├─ leading?                    // optional caller component
///        │    ├─ Gap (sectionGapStyle)     // rendered only when leading != null
///        │    ├─ titleSlot (<div flex-1>)    // title text wrapper
///        │    ├─ Gap (sectionGapStyle)     // rendered only when trailing != null
///        │    └─ trailing?                   // optional caller component
///        ├─ Gap (sectionGapStyle)          // rendered only when content != null
///        ├─ content (<div min-h-0 overflow-y-auto>) // co_dialog renders only when `content` set;
///        │                                  // scrolls a body taller than the panel's max-height
///        ├─ Gap (actionsGapStyle)          // rendered only when actions present
///        └─ footer (<div flex flex-wrap shrink-0>) // co_dialog renders only when `actions` non-empty
///             └─ actionCell? (<div flex flex-col grow min-w-fit>) // one per action,
///                  │                         // only when the row stretches
///                  └─ action                 // otherwise a direct footer child
/// ```
///
/// Every slot chrome but [actionCell] is non-null — `co_dialog` decides
/// whether to render each optional slot based on instance state. The
/// [hidden] slot replaces the entire tree when the dialog is closed (or
/// when the overlay portal owns the visible tree). [actionCell] is the one
/// slot whose presence the resolver decides: it exists only when the
/// resolved actions layout stretches the row.
///
/// Per Epic #1603 (옵션 B 최종) every colour / typography value routes
/// through the emit family (`emitColor` / `emitTypography`): token-bound
/// panel colours and typography roles emit Tailwind classes (dark-mode
/// reactive), while raw overrides and the alpha-composited backdrop go
/// inline. Dimensional chrome (border width / radius / padding /
/// max-width / inter-slot gap) stays inline / structural. The className
/// surface carries structural (`fixed` / `flex` / `items-*`) and
/// emit-family colour / typography classes. Motion is a separate
/// `animation` merged in by `co_dialog` from [resolveDialogMotion] (not
/// this resolver — it needs the runtime `closing` flag) and is never a
/// className.
///
/// The resolver carries:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
/// * Cat 2 — the nested [actionButtonStyle] slot, forwarded straight to
///   a `Button` action by `co_dialog` (asChild pattern).
/// * Cat 2 — the nested [sectionGapStyle] slot, forwarded straight to
///   `Gap(gapStyle: …)` siblings interleaved between
///   leading/title/trailing and above the content (a nested
///   `CoreGapStyle` slot, parity with the Flutter widget).
/// * Cat 2 — the nested [actionsGapStyle] slot, forwarded straight to the
///   `Gap(gapStyle: …)` sibling above the footer.
class ResolvedDialog implements WebResolvedChrome {
  /// Creates a [ResolvedDialog].
  const ResolvedDialog({
    required this.root,
    required this.backdrop,
    required this.panel,
    required this.titleSlot,
    required this.header,
    required this.content,
    required this.footer,
    required this.actionCell,
    required this.hidden,
    required this.sectionGapStyle,
    required this.actionsGapStyle,
    required this.actionButtonStyle,
  });

  /// Paint-ready chrome for the outermost wrapper `<div>` — groups
  /// the backdrop + panel together. Carries the `coui-dialog` marker
  /// class only.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the backdrop scrim `<div fixed inset-0
  /// z-40>` — sits behind the panel (one named `CoreZIndex` rung
  /// below the panel's `z50`) and catches outside clicks.
  final WebElementChrome backdrop;

  /// Paint-ready chrome for the centered panel `<div fixed centered>`
  /// — the dialog surface with chrome (background, border, padding,
  /// shadow).
  final WebElementChrome panel;

  /// Paint-ready chrome for the title text wrapper `<div flex-1>` —
  /// surfaces the typography class so the user-supplied `title`
  /// component inherits the right font role.
  final WebElementChrome titleSlot;

  /// Paint-ready chrome for the header row `<div flex items-center>`
  /// — `co_dialog` skips this element when there is no title /
  /// leading / trailing component.
  final WebElementChrome header;

  /// Paint-ready chrome for the content (body) wrapper — the scroll
  /// container a body taller than the panel's `max-height` scrolls in,
  /// while the header and footer stay put. `co_dialog` skips this element
  /// when `content` is null.
  final WebElementChrome content;

  /// Paint-ready chrome for the footer (actions) row — a wrapping flex
  /// row at the end; `co_dialog` skips this element when no actions are
  /// supplied.
  final WebElementChrome footer;

  /// Paint-ready chrome for the cell `<div>` each action sits in when the
  /// row stretches ([CoreDialogActionsLayout.stretch]) — a flex column, so
  /// the action inside takes the cell's width; it starts at an equal share
  /// of the row, never goes narrower than its action and grows into what
  /// the line leaves. `null` when the actions keep their own width
  /// ([CoreDialogActionsLayout.end]) or there are none: `co_dialog` then
  /// renders each action straight into the footer.
  final WebElementChrome? actionCell;

  /// Paint-ready chrome for the closed-state placeholder `<div
  /// hidden>` — emitted in place of the entire tree when the dialog
  /// is closed (or when the overlay portal renders the visible tree
  /// elsewhere).
  final WebElementChrome hidden;

  /// Nested `CoreGapStyle` slot — forwarded straight to
  /// `Gap(gapStyle: …)` by `co_dialog` between
  /// leading/title/trailing on the header row and before the
  /// content. Carries the merged design-system
  /// default + per-instance override (raw, pre-scaling — the receiving
  /// `Gap` runs its own resolve step).
  final CoreGapStyle sectionGapStyle;

  /// Nested `CoreGapStyle` slot — forwarded straight to
  /// `Gap(gapStyle: …)` by `co_dialog` before the footer (the actions
  /// row); the header sits this far from the footer when the dialog has
  /// no content. Merged design-system default + per-instance override,
  /// raw and pre-scaling like [sectionGapStyle].
  final CoreGapStyle actionsGapStyle;

  /// Nested `CoreButtonStyle` slot — forwarded to a `Button` action
  /// by `co_dialog` (asChild pattern). `null` when the caller supplied
  /// no action-button chrome override.
  final CoreButtonStyle? actionButtonStyle;
}

/// Resolved behavior timings for `Dialog`. No DOM chrome — widget
/// behavior helper only: the exit-unmount timer runs *between* builds
/// (armed from `didUpdateComponent`, which has no chance to resolve
/// again), so it cannot ride the paint-ready chrome bundle.
class ResolvedDialogTiming {
  /// Creates a [ResolvedDialogTiming].
  const ResolvedDialogTiming({required this.transitionDurationMs});

  /// Open/close transition duration in milliseconds. `Dialog` sizes its
  /// exit-unmount timer with this, and [resolveDialogMotion] sizes the
  /// CSS `animation-duration` from the same merged value — so the DOM
  /// stays mounted for exactly as long as the exit keyframe plays.
  final int transitionDurationMs;
}

/// Resolves the open/close transition duration for `Dialog` — walks the
/// same nested-merge chain as [resolveDialog] but yields only the
/// behaviour timing.
///
/// Separate from [ResolvedDialog] because that bundle is paint-ready
/// chrome (`WebElementChrome` slots + nested `CoreXxxStyle` slots); a
/// raw `Duration` there is a category-C violation the web-resolver
/// guard rejects. `Drawer` splits its slide durations the same way.
ResolvedDialogTiming resolveDialogTiming(
  BuildContext context, {
  CoreDialogStyle? dialogStyle,
}) {
  final dialogTheme = context.theme.coreComponentTheme?.dialog;
  final merged = resolveStyleChain(const CoreDialogStyle(), [
    dialogTheme?.style,
    dialogStyle,
  ]);
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreDialogStyle.defaultTransitionDuration)
          .inMilliseconds;

  return ResolvedDialogTiming(transitionDurationMs: transitionDurationMs);
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDialog] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.dialog.style
///   → widget.dialogStyle
/// ```
///
/// [actionCount] is how many actions the caller handed in — data, like the
/// actions themselves, not interaction state. A stretched row starts every
/// action at an equal share of the row, and CSS has no way to divide a
/// length by the number of siblings, so the share is stated from this count.
/// The Flutter twin needs no count: its render object places the actions it
/// lays out.
ResolvedDialog resolveDialog(
  BuildContext context, {
  int actionCount = 0,
  CoreDialogStyle? dialogStyle,
}) {
  final dialogTheme = context.theme.coreComponentTheme?.dialog;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDialogStyle(), [
    dialogTheme?.style,
    dialogStyle,
  ]);

  // ─── Token table ──────────────────────────────────────
  // Variant-independent design-system colour table — the resolver
  // reads `variantStyle.X` as the fallback source for the four panel /
  // backdrop colours (single source of truth, mirrors the Flutter
  // resolver).
  const variantStyle = CoreDialogStyle.defaultsByVariant;

  // ─── Resolved dimensional / motion values ─────────────
  // Each value finishes its merge + fallback so the local builders below
  // run from a single source of truth (closures capture these directly).
  final panelBorderWidth =
      merged.panelBorderWidth ?? CoreDialogStyle.defaultPanelBorderWidth;
  final panelBorderRadius =
      (merged.panelBorderRadius ?? CoreDialogStyle.defaultPanelBorderRadius)
          .toValue();
  final panelPadding =
      (merged.panelPadding ?? CoreDialogStyle.defaultPanelPadding).toValue();
  final panelMinWidth =
      merged.panelMinWidth ?? CoreDialogStyle.defaultPanelMinWidth;
  final panelMaxWidth =
      merged.panelMaxWidth ?? CoreDialogStyle.defaultPanelMaxWidth;
  final surfaceBlur = merged.surfaceBlur ?? context.theme.surfaceBlur;
  final surfaceOpacity = merged.surfaceOpacity ?? context.theme.surfaceOpacity;
  // Panel elevation shadow (#3777) — shadow base colour flows through
  // the single Core source (`defaultShadowBaseColor` = `shadow` token).
  // Web EMIT is theme-free — `.toValue()` emits `rgb(var(--coui-shadow))`
  // and the browser resolves it at runtime (no `scheme.resolve`, a
  // no-op on Web; mirrors the Flutter resolver).
  final panelShadowLayers =
      merged.panelBoxShadow ?? CoreDialogStyle.defaultPanelBoxShadow;
  final panelShadowBase =
      (merged.shadowBaseColor ?? CoreDialogStyle.defaultShadowBaseColor)
          .toValue();
  final panelBoxShadowCss = emitShadow(
    panelShadowLayers,
    base: panelShadowBase,
  );
  // The segment the panel keeps to. On a screen a fold splits, Flutter's
  // dialog route keeps its page to one segment (`DisplayFeatureSubScreen`),
  // the one at the top of the reading start; the fold rule names the same
  // one here, so a dialog opens on the same half on both platforms. Null
  // where nothing splits the viewport, and the panel centres on it as before.
  final fold = context.dependOnInheritedComponentOfExactType<FoldLayoutScope>();
  final foldLayout = fold?.layout;
  final segment = foldLayout != null && foldLayout.isSplit
      ? foldLayout.startSegmentIndex(fold!.direction)
      : null;
  // Inter-slot gap slot — merged design-system default + per-instance
  // override. Forwarded straight to `Gap(gapStyle: …)` siblings
  // interleaved between leading/title/trailing on the header row and
  // above the content by `co_dialog`. `Gap` runs its own resolve /
  // scaling step.
  final sectionGapStyle = CoreDialogStyle.defaultSectionGapStyle.merge(
    merged.sectionGapStyle,
  );
  // Actions gap slot — the spacer above the footer; same raw-forward
  // shape as the section gap.
  final actionsGapStyle = CoreDialogStyle.defaultActionsGapStyle.merge(
    merged.actionsGapStyle,
  );
  // Action spacing — raw double (logical px) → inline `gap` on the footer
  // row, through the spacing variable. Web ignores Flutter scaling.
  final actionSpacing =
      merged.actionSpacing ?? CoreDialogStyle.defaultActionSpacing;
  final actionGapCss = spaceCss(actionSpacing);
  // Wrapped-row gap — the footer's `row-gap`, through the spacing variable
  // like the gap beside it.
  final actionRunSpacing =
      merged.actionRunSpacing ?? CoreDialogStyle.defaultActionRunSpacing;
  // Actions layout — `end` leaves each action its own width at the row's
  // end; `stretch` seats each action in a cell that starts at an equal share
  // of the row. The cell exists only for a stretched row with actions to
  // place.
  final actionsLayout =
      merged.actionsLayout ?? CoreDialogStyle.defaultActionsLayout;
  final stretchesActions = switch (actionsLayout) {
    CoreDialogActionsLayout.end => false,
    CoreDialogActionsLayout.stretch => actionCount > 0,
  };
  // Body clip reach — how far past its box the scrolling body keeps
  // painting. The focus outline's geometry, not the layout's spacing.
  final contentClipMargin =
      merged.contentClipMargin ?? CoreDialogStyle.defaultContentClipMargin;
  // Route padding — the room around the panel, which caps its width on
  // both sides. Spacing, through the spacing variable a density moves.
  final routePadding =
      merged.routePadding ?? CoreDialogStyle.defaultRoutePadding;
  // Motion — panel scale animation. The transition *duration* is a
  // behaviour timing, not chrome, so it resolves in
  // [resolveDialogTiming] instead of riding this bundle.
  final scaleAnimationStart =
      merged.scaleAnimationStart ?? CoreDialogStyle.defaultScaleAnimationStart;
  final scaleAnimationEnd =
      merged.scaleAnimationEnd ?? CoreDialogStyle.defaultScaleAnimationEnd;
  // Action-button slot — forwarded straight to a `Button` action by
  // `co_dialog` (Epic #1603 옵션 B coverage gate).
  final actionButtonStyle = merged.actionButtonStyle;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound values
  // (the design-system colour table AND token overrides) emit Tailwind
  // classes so they stay dark-mode reactive; raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled typography role
  // class construction.
  //
  // `surfaceOpacity` is folded into the colour, not applied to the node.
  // Flutter does `baseBackgroundColor.withValues(alpha: surfaceOpacity)` — the
  // PANEL goes translucent and its title, body and buttons stay opaque. Web
  // emitted `opacity` on the panel, which dims the element and every child, so
  // a translucent-surface preset produced a dialog whose contents faded out on
  // Web and stayed readable on Flutter. Tailwind carries the alpha in the class
  // (`bg-{token}/{pct}`), so this stays on the class path and dark-mode
  // reactive.
  final backgroundEmit = emitColor(
    surfaceOpacity == null
        ? merged.panelBackgroundColor
        : (merged.panelBackgroundColor ?? variantStyle.backgroundColor)
              .scaleAlpha(surfaceOpacity),
    variantStyle.backgroundColor,
    .background,
  );
  final foregroundEmit = emitColor(null, variantStyle.foregroundColor, .text);
  final borderEmit = emitColor(
    merged.panelBorderColor,
    variantStyle.borderColor,
    .border,
  );
  // Title / content typography — `emitTypography` merges the design-system
  // role default with any per-instance overlay, emitting a `text-{role}`
  // (+ token colour) class for a pure role or an inline bundle for a
  // scalar / raw overlay.
  final titleEmit = emitTypography(
    merged.titleStyle,
    CoreDialogStyle.defaultTitleStyle,
  );
  final contentEmit = emitTypography(
    merged.contentStyle,
    CoreDialogStyle.defaultContentStyle,
  );
  // Backdrop colour — override wins, else the variant overlay colour —
  // scaled by `barrierOpacity` so the token emits as `rgb(var(--coui-X) /
  // NN%)` at the right alpha. `scaleAlpha` keeps the token, so `.toValue()`
  // emits the CSS-variable form directly (no `scheme.resolve` — a no-op on
  // Web). Always an arbitrary alpha composite, so it stays inline.
  final barrierOpacity =
      merged.barrierOpacity ?? CoreDialogStyle.defaultBarrierOpacity;
  final barrierColor = (merged.barrierColor ?? variantStyle.overlayColor)
      .scaleAlpha(barrierOpacity)
      .toValue();

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer wrapper `<div>` className.
  String buildRootClassName() => 'coui-dialog';

  /// Composes the backdrop scrim `<div>` Tailwind className —
  /// structural only; the fade motion is a separate `animation`
  /// (`resolveDialogMotion` below), not a `transition` — the portal
  /// re-creates this `<div>` on every render (`co_dialog` calls
  /// `_schedulePortalSync` on every build), and a `transition` needs
  /// the *same* node to persist across the style change to fire at
  /// all (`overlay_motion.dart` documents the same finding for
  /// `Popover`).
  String buildBackdropClassName() =>
      '${WebLayout.fixed} ${WebLayout.insetZero} z-${CoreZIndex.scale.z40}';

  /// Composes the backdrop inline-CSS bundle — scrim colour only; the
  /// `animation` property is merged in separately by `co_dialog` from
  /// `resolveDialogMotion` (which needs the runtime `closing` flag
  /// this resolver does not receive).
  Styles buildBackdropInlineStyles() => .new(
    raw: {'background-color': barrierColor},
  );

  /// Composes the centered panel `<div>` Tailwind className —
  /// structural classes plus the emit-family colour classes (background /
  /// foreground / border colour — token-bound, so they emit classes that
  /// stay dark-mode reactive). `border` keeps the `border-style: solid`
  /// that the inline `border-width` needs to render. Motion is a
  /// separate `animation` (`resolveDialogMotion` below), not a class
  /// here — see [buildBackdropClassName] for why.
  String buildPanelClassName() => <String>[
    // Surface hook — a style preset targets this to give the panel a
    // material, and forced colours to restore a shadow-drawn boundary.
    ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
    '${WebLayout.fixed} ${WebLayout.leftHalf} ${WebLayout.topHalf}',
    'z-${CoreZIndex.scale.z50}',
    '${WebLayout.negTranslateXHalf} ${WebLayout.negTranslateYHalf}',
    // Flex column — the header / content / footer stack interleaves
    // `Gap(sectionGapStyle)` spacers, which size via `flex-basis` and
    // need a flex container to take effect (mirrors the Flutter
    // `Column`; on a block panel the section gaps collapse to 0).
    '${WebLayout.flex} ${WebLayout.flexCol}',
    // The panel's sizes are its whole box, padding and border included, as
    // the Flutter panel's are: the kit turns Tailwind's preflight off, so
    // without this the width, the 640 cap and the height cap would size the
    // content alone and the panel would run 48 px wider than its twin — off
    // a narrow screen, and across the fold of one that folds.
    'box-border',
    'border',
    // No `hover:shadow-*` variant on the panel (it isn't a hover
    // surface), so — unlike `Card` — the base shadow is free to move
    // inline in `buildPanelInlineStyles` and carry the claymorphism rim
    // (#3463) beside it.
    backgroundEmit.className,
    foregroundEmit.className,
    borderEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the panel inline-CSS bundle — the dimensional chrome
  /// (border width / radius / padding / min- and max-width) and any raw colour
  /// overrides the emit family routed inline (token colours stay on
  /// classes). The open-animation scale range is exposed here as CSS
  /// custom properties for `resolveDialogMotion`'s keyframe to read;
  /// the `animation` property itself is merged in separately by
  /// `co_dialog` (see [buildBackdropClassName] for why motion isn't
  /// baked into this resolver).
  Styles buildPanelInlineStyles() {
    final raw = {
      // The route's padding on both sides — the Flutter twin pads the
      // route by the same `routePadding` through the theme geometry, so the
      // room a narrow viewport leaves the panel follows the density; the
      // spacing variable carries the same move here.
      'width': 'calc(100% - 2 * ${spaceCss(routePadding)})',
      // The same room above and below — the Flutter route pads all four
      // sides. A panel this tall stops here and its body scrolls.
      'max-height': 'calc(100% - 2 * ${spaceCss(routePadding)})',
      'border-width': strokeWidthCss(panelBorderWidth),
      'border-radius': panelBorderRadius,
      'padding': panelPadding,
      // A floor, but never past the room the route leaves — Flutter's
      // `ConstrainedBox` enforces its minimum inside the route's bounds, so
      // a viewport narrower than the floor plus the inset narrows the panel
      // there too instead of overflowing it.
      'min-width':
          'min(${panelMinWidth / kRemDivisor}rem, '
          'calc(100% - 2 * ${spaceCss(routePadding)}))',
      'max-width': '${panelMaxWidth / kRemDivisor}rem',
      // #3777: `panelBoxShadowCss` is Core-sourced (`CoreDialogStyle
      // .defaultPanelBoxShadow` = `CoreShadow.xl`, the canonical
      // Modal/Dialog rung — was `var(--shadow-lg)`, the popover/tooltip
      // rung, hardcoded with no Core declaration at all) plus the
      // claymorphism rim beside it — the same reference `popup`/
      // `draggable_panel`/`drawer` already carry, `_kNoRim` a no-op for
      // every other style.
      'box-shadow': '$panelBoxShadowCss, $kSurfaceRimVar',
      // Open/close-animation scale range — read by the `co-dialog-
      // panel-enter` / `co-dialog-panel-exit` `@keyframes`
      // (`overlay_host.dart`) so a per-instance `CoreDialogStyle`
      // override still reaches the shared keyframe.
      '--coui-dialog-scale-from': '$scaleAnimationStart',
      '--coui-dialog-scale-to': '$scaleAnimationEnd',
      // Emit-family inline fragments (raw colour overrides only — token
      // values stay on classes and contribute nothing here).
      ...?backgroundEmit.inline,
      ...?foregroundEmit.inline,
      ...?borderEmit.inline,
    };
    if (surfaceBlur != null) {
      raw['backdrop-filter'] = 'blur(${surfaceBlur / kRemDivisor}rem)';
    }
    if (segment != null) {
      // Centred on the segment and sized by it, with the route's padding on
      // every side — the room Flutter's route leaves inside its sub-screen.
      String edge(String name) => foldLayout!.segmentEnvCss(segment, name);
      final room = '2 * ${spaceCss(routePadding)}';
      raw
        ..['left'] = 'calc(${edge('left')} + ${edge('width')} / 2)'
        ..['top'] = 'calc(${edge('top')} + ${edge('height')} / 2)'
        ..['width'] = 'calc(${edge('width')} - $room)'
        ..['max-height'] = 'calc(${edge('height')} - $room)';
    }
    raw.addAll(
      surfaceFillVar(
        merged.panelBackgroundColor ?? variantStyle.backgroundColor,
      ),
    );
    return Styles(raw: raw);
  }

  /// Composes the header row `<div>` Tailwind className — structural
  /// only; the inter-slot gap is rendered as explicit `Gap` siblings
  /// by `co_dialog` (see [sectionGapStyle]).
  ///
  /// `shrink-0`: when the panel reaches its `max-height` the body gives
  /// up the room, never the header (Flutter's header is a non-flex child).
  String buildHeaderClassName() =>
      '${WebLayout.flexItemsCenter} ${WebLayout.shrinkZero}';

  /// Composes the title text wrapper `<div>` Tailwind className —
  /// structural `flex-1` plus the emit-family typography role / colour
  /// classes ([titleEmit]).
  String buildTitleSlotClassName() => <String>[
    WebLayout.flex1,
    titleEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the title text wrapper inline-CSS bundle — any raw scalar
  /// overlay / raw colour the emit family routed inline. Returns `null`
  /// when the title resolves to a pure role (class only).
  Styles? buildTitleSlotInlineStyles() {
    final inline = titleEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the content (body) wrapper `<div>` Tailwind className —
  /// the scroll container (`min-h-0` lets the flex column shrink it below
  /// its content once the panel reaches its `max-height`; it then scrolls
  /// vertically and clips sideways) plus the emit-family typography role /
  /// colour classes ([contentEmit]). The top gap is rendered as an
  /// explicit `Gap` sibling by `co_dialog`.
  String buildContentClassName() => <String>[
    WebLayout.minHZero,
    WebLayout.overflowYAuto,
    WebLayout.overflowXHidden,
    contentEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the content wrapper inline-CSS bundle — the clip reach plus
  /// any raw scalar overlay / raw colour the emit family routed inline.
  ///
  /// A scroll container clips even when it does not scroll, so the body
  /// is widened past its own box by [contentClipMargin] on every side and
  /// padded back in by the same length: the content sits exactly where it
  /// did, and what it paints within that reach (a focus ring around a
  /// field flush with the body's edge) is inside the clip. The Flutter
  /// twin inflates its body clip by the same reach. Pinned, not spacing —
  /// the margin cancels the padding's footprint, and a density moving one
  /// of the two would move the content.
  Styles buildContentInlineStyles() {
    final reach = pinnedLengthCss(contentClipMargin);
    return Styles(
      raw: {
        'margin': '-$reach',
        'padding': reach,
        ...?contentEmit.inline,
      },
    );
  }

  /// Composes the footer (actions) row `<div>` Tailwind className —
  /// structural only; the top gap is rendered as an explicit `Gap`
  /// sibling by `co_dialog`; the gaps live inline.
  ///
  /// Actions that do not fit on one line wrap onto the next, each row at
  /// the end and centred across — the Flutter twin's
  /// `Wrap(alignment: .end, crossAxisAlignment: .center)`. `shrink-0`
  /// keeps the footer whole when the panel reaches its `max-height`.
  String buildFooterClassName() => <String>[
    WebLayout.flex,
    WebLayout.flexWrap,
    WebLayout.justifyEnd,
    WebLayout.itemsCenter,
    WebLayout.shrinkZero,
  ].join(' ');

  /// Composes the footer row inline-CSS bundle — the gap between adjacent
  /// actions and the gap between wrapped rows (inline, through
  /// `spaceCss`).
  Styles buildFooterInlineStyles() => .new(
    raw: {
      'column-gap': actionGapCss,
      'row-gap': spaceCss(actionRunSpacing),
    },
  );

  /// Composes the action cell `<div>` Tailwind className — a flex column,
  /// so the action inside stretches to the cell's width; `grow` hands the
  /// cell what its line leaves and `min-w-fit` keeps it no narrower than
  /// its action.
  ///
  /// The browser lays the stretched row out: the footer stays the wrapping
  /// row it is at the end, a cell that does not fit its share starts the
  /// next line, and once the cells fill a line its `justify-end` has
  /// nothing left to place. That is the rule `CoreDialogActionsStretch`
  /// works out for the Flutter twin, and one shared vector table pins both.
  String buildActionCellClassName() => <String>[
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.grow,
    WebLayout.minWFit,
  ].join(' ');

  /// Composes the action cell inline-CSS bundle — the share every action
  /// starts at (`flex-basis`): the row less the gaps between the actions,
  /// split evenly. The gap is the footer's `column-gap` value, so a
  /// density that moves the gap moves the share with it.
  Styles buildActionCellInlineStyles() => .new(
    raw: {
      'flex-basis': actionCount == 1
          ? '100%'
          : 'calc((100% - ${actionCount - 1} * $actionGapCss) / '
                '$actionCount)',
    },
  );

  /// Composes the closed-state placeholder `<div>` Tailwind className.
  String buildHiddenClassName() => WebLayout.hidden;

  // ─── Compose paint-ready chrome ───────────────────────
  // The one slot whose presence a resolved value decides — a stretched row
  // with actions to place.
  final actionCell = stretchesActions
      ? WebElementChrome(
          className: buildActionCellClassName(),
          inlineStyles: buildActionCellInlineStyles(),
        )
      : null;

  return ResolvedDialog(
    root: WebElementChrome(className: buildRootClassName()),
    backdrop: WebElementChrome(
      className: buildBackdropClassName(),
      inlineStyles: buildBackdropInlineStyles(),
    ),
    panel: WebElementChrome(
      className: buildPanelClassName(),
      inlineStyles: buildPanelInlineStyles(),
    ),
    titleSlot: WebElementChrome(
      className: buildTitleSlotClassName(),
      inlineStyles: buildTitleSlotInlineStyles(),
    ),
    header: WebElementChrome(className: buildHeaderClassName()),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    footer: WebElementChrome(
      className: buildFooterClassName(),
      inlineStyles: buildFooterInlineStyles(),
    ),
    actionCell: actionCell,
    hidden: WebElementChrome(className: buildHiddenClassName()),
    sectionGapStyle: sectionGapStyle,
    actionsGapStyle: actionsGapStyle,
    actionButtonStyle: actionButtonStyle,
  );
}

// ═══════════════════════════════════════════════════
// Motion — separate from the resolver above
// ═══════════════════════════════════════════════════

/// Motion chrome for the Dialog backdrop + panel, driven by [closing].
///
/// Kept out of [resolveDialog] because it needs the *runtime* closing
/// flag that resolver has no input for (`co_dialog`'s exit timer, not
/// build-time chrome) — mirrors `resolveOverlayMotion`'s split from
/// `resolvePopover` (`overlay_motion.dart`).
///
/// Both keyframes are `@keyframes` **animations**, not CSS
/// `transition`s: the portal re-creates the backdrop/panel `<div>`s on
/// every render (`co_dialog` calls `_schedulePortalSync` on every
/// `build`), and a `transition` needs the *same* node to persist
/// across the style change to fire — an animation instead plays
/// whenever the element is (re)inserted, surviving that node
/// re-creation.
///
/// - [closing] `true` — play the exit keyframe (`CoreEasing.
///   accelerate` — starts at rest, accelerates away, mirroring
///   Flutter's `reverseCurve`). `co_dialog` keeps the panel mounted
///   for [transitionDuration] after this starts, then unmounts.
/// - [closing] `false` — play the enter keyframe (`CoreEasing.
///   decelerate`).
///
/// The panel keyframe (`co-dialog-panel-enter` / `co-dialog-panel-
/// exit`, `overlay_host.dart`) composites the fixed-position centering
/// translate with the scale so it doesn't clobber the panel's own
/// `-translate-x-1/2 -translate-y-1/2` (a bare `transform: scale()`
/// would reset that translate to 0 for the animation's duration and
/// the panel would jump to the top-left corner). The backdrop
/// keyframe (`co-overlay-fade-enter` / `co-overlay-fade-exit`) is
/// fade-only — the backdrop has no other transform to preserve, and a
/// scale on a full-bleed `inset-0` element would peel back from the
/// viewport edges.
({WebElementChrome backdrop, WebElementChrome panel}) resolveDialogMotion({
  required bool closing,
  required Duration transitionDuration,
}) {
  final easing = closing ? CoreEasing.exit : CoreEasing.enter;
  final duration = durationMsCss(transitionDuration.inMilliseconds);
  final curve = easing.toVarCss();
  final timing = '$duration $curve both';
  final backdropKeyframe = closing
      ? 'co-overlay-fade-exit'
      : 'co-overlay-fade-enter';
  final panelKeyframe = closing
      ? 'co-dialog-panel-exit'
      : 'co-dialog-panel-enter';
  final fade = overlayFadeProperties(
    closing: closing,
    duration: duration,
    easing: curve,
  );

  return (
    backdrop: WebElementChrome(
      className: '',
      inlineStyles: Styles(raw: {'animation': '$backdropKeyframe $timing'}),
    ),
    // The panel is its own motion box: it scales and it fades. Its keyframe
    // walks the progress (`kFadeProgressVar`) beside the scale. The two
    // animations after it are the ones a panel plays by what it is
    // (`_kFadeCss` in `overlay_host.dart`): its opacity, when it draws no
    // backdrop pass, and its shadow and edge, when it draws one. Each is named
    // by a property the panel's own rules set, and the one it does not play
    // is named `kFadeNoAnimation`, which no keyframes go by.
    panel: WebElementChrome(
      className: kFadePanelClass,
      inlineStyles: Styles(
        raw: {
          'animation':
              '$panelKeyframe $timing, '
              'var($kFadeOpacityAnimationVar) $duration $curve both, '
              'var($kFadePaintAnimationVar) $duration $curve '
              'var($kFadeFillVar)',
          ...fade,
        },
      ),
    ),
  );
}
