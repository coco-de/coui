/// Web overlay host — root-level mount point for floating panels.
///
/// Mirrors Flutter `Overlay` / `OverlayManagerLayer` semantics for
/// the Jaspr Web target. Floating components (popover, tooltip,
/// hover-card, dropdown menu, dialog) call
/// `OverlayPortal.of(context).controller.mount(layer: ...,
/// panel: ...)` to portal their panel up to this host's overlay
/// layer instead of rendering it inline as a sibling of the trigger
/// — that way the panel is no longer affected by the `overflow: hidden`
/// or `transform` of the **trigger's** ancestors.
///
/// The host's own ancestors are a different matter: the layers live
/// where the host is rooted, and a client island roots its host where it
/// hydrates. A `position: fixed` panel under an ancestor that is a
/// containing block (`transform`, `filter`, `backdrop-filter`,
/// `contain` …) is placed against that ancestor instead of the viewport.
/// So every panel's outermost wrapper also carries the top-layer
/// attributes (`TopLayer.attributesFor`), and this host promotes them
/// into the browser top layer as they are inserted (see `top_layer.dart`)
/// — the panel is then viewport-relative whatever it is nested under.
///
/// `CoUIWeb` automatically wraps its child with a [OverlayHost],
/// so any descendant has portal access via `context`.
///
/// **Strategy note** — Flutter `CoUIApp` exposes
/// `popoverHandler` / `menuHandler` / `tooltipHandler` props that
/// auto-switch between popover and bottom-sheet rendering based on
/// `mobileMode` (touch / narrow viewport). CoUI Web does *not*
/// follow that pattern: rendering shape is the designer's call, not
/// a hardware-driven implicit branch. Components that need both
/// shapes expose explicit `variant` props (e.g.
/// `Select(variant: .popover | .sheet)`) so the same call site
/// produces the same rendering on Flutter and Web. The host here is
/// therefore deliberately a single fixed dispatch — no strategy
/// injection.
library;

import 'package:coui_web/src/overlay/overlay_motion.dart'
    show kLiftDimAttribute;
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:coui_web/src/overlay/top_layer_dom.dart';
import 'package:coui_web/src/util/web_constants.dart'
    show
        kFadeBoxClass,
        kFadeDurationVar,
        kFadeEasingVar,
        kFadeFillVar,
        kFadeLayerAnimationVar,
        kFadeNoAnimation,
        kFadeOpacityAnimationVar,
        kFadeOpacityNameVar,
        kFadePaintAnimationVar,
        kFadePanelClass,
        kFadeProgressAnimationVar,
        kFadeProgressVar;
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

import 'overlay_controller.dart';
import 'overlay_portal.dart';

/// The four layers are layout-neutral carriers (`display: contents`).
///
/// Stacking between panels is the top layer's: a panel promoted later
/// paints above one promoted earlier, whichever layer it was mounted in
/// (the order Flutter's `Overlay` gives its entries). The per-panel
/// `z-{N}` classes still order panels that were not promoted — a
/// browser without the Popover API.
const String _kPopoverLayerClasses = 'contents';
const String _kMenuLayerClasses = 'contents';
const String _kTooltipLayerClasses = 'contents';
const String _kDialogLayerClasses = 'contents';

/// Global `@keyframes` for the portal-mounted overlay enter / exit motion
/// (scale + fade, mirroring Flutter `_kScaleAnimationMin/Max`).
///
/// Overlays animate with a CSS **animation** (these keyframes), not a
/// transition: jaspr re-creates the portaled panel's DOM node on every
/// render, and a `transition` needs the *same* node to persist across the
/// closed→open style change, so it never fires. A keyframes animation
/// instead plays whenever the element is (re)inserted, so it survives the
/// portal node-recreation — the same technique Radix / `shadcn_jaspr` use
/// (`animate-in fade-in zoom-in`). Injected here (not via the Tailwind CDN,
/// which omits the `tailwindcss-animate` plugin) so it ships with the
/// library and is present once wherever overlays render.
const String _kOverlayKeyframes =
    // The motion box's own pair: a scale and nothing else. The fade is not
    // here. A box that fades by its opacity puts everything in it into one
    // layer, and a glass panel in that layer has no page to blur (see
    // [_kFadeCss]); the panel inside the box plays the fade itself.
    '@keyframes co-overlay-enter{from{transform:scale(0.9)}'
    'to{transform:scale(1)}}'
    '@keyframes co-overlay-exit{from{transform:scale(1)}'
    'to{transform:scale(0.9)}}'
    // Fade-only pair — for overlay chrome that has no transform of its
    // own to preserve through the animation (e.g. a full-bleed modal
    // backdrop, where a scale would peel back from the viewport edges).
    '@keyframes co-overlay-fade-enter{from{opacity:0}to{opacity:1}}'
    '@keyframes co-overlay-fade-exit{from{opacity:1}to{opacity:0}}'
    // Dialog panel pair — composites the fixed-position centering
    // translate with the scale so the keyframe doesn't clobber it (a
    // bare `transform:scale()` would reset the translate to 0 for the
    // animation's duration and the panel would jump to the top-left
    // corner). The scale endpoints are read from `--coui-dialog-scale-
    // from/to` custom properties so per-instance `CoreDialogStyle`
    // overrides still reach the shared keyframe (`dialog_style.dart`). The
    // panel is its own motion box, so the progress it fades by
    // (`--coui-fade`) is walked in the same keyframe as its scale.
    '@keyframes co-dialog-panel-enter{'
    'from{$kFadeProgressVar:0;transform:translate(-50%,-50%) '
    'scale(var(--coui-dialog-scale-from))}'
    'to{$kFadeProgressVar:1;transform:translate(-50%,-50%) '
    'scale(var(--coui-dialog-scale-to))}}'
    '@keyframes co-dialog-panel-exit{'
    'from{$kFadeProgressVar:1;transform:translate(-50%,-50%) '
    'scale(var(--coui-dialog-scale-to))}'
    'to{$kFadeProgressVar:0;transform:translate(-50%,-50%) '
    'scale(var(--coui-dialog-scale-from))}}'
    // Travel pair — for a panel that stays open while its anchor moves
    // (`NavigationMenu` hovering a sibling trigger). The panel must not
    // replay the enter pop for that: it is already on screen, so it
    // slides. The node is re-created at its *new* origin, so the keyframe
    // starts it back at the old one (the delta, in
    // `--coui-overlay-switch-x/y`) and relaxes to none. No opacity — the
    // panel never leaves the screen.
    '@keyframes co-overlay-switch{'
    'from{transform:translate(var(--coui-overlay-switch-x),'
    'var(--coui-overlay-switch-y))}'
    'to{transform:none}}'
    // Content cross-fade for a panel whose content is swapped in place.
    // `--coui-overlay-swap-x` carries the direction as a percentage of
    // the content's own width, so the incoming half enters from the side
    // the pointer moved toward and the outgoing half leaves opposite it.
    '@keyframes co-overlay-swap-enter{'
    'from{opacity:0;transform:translateX(var(--coui-overlay-swap-x))}'
    'to{opacity:1;transform:none}}'
    '@keyframes co-overlay-swap-exit{'
    'from{opacity:1;transform:none}'
    'to{opacity:0;transform:translateX(calc(-1 * '
    'var(--coui-overlay-swap-x)))}}';

/// Stylesheet for panels promoted into the top layer (`top_layer.dart`).
///
/// A `popover` element gets UA defaults that a floating panel must not
/// inherit: `inset: 0` + `margin: auto` (centres it and pins the right /
/// bottom edges, stretching an auto-sized panel), `fit-content` size, a
/// border, padding, canvas colours and `overflow: auto` (which would clip
/// the shadows its descendants paint). Both rules sit in `:where()` — zero
/// specificity — so the panel's own utility classes and inline styles
/// (`inset-0` on a scrim, `left`/`top` from the positioner) still win. An
/// author rule beats the UA sheet whatever its specificity.
///
/// The second rule keeps a panel that no host has promoted yet visible
/// (server-rendered markup before any host exists in the browser): the UA
/// hides every `[popover]:not(:popover-open)`. A promotion that is rejected
/// does not need it — the promoter removes `popover` then. It is its own
/// rule so a browser that does not know `:popover-open` drops only this one.
const String _kTopLayerCss =
    ':where([$kTopLayerPanelAttribute]){margin:0;padding:0;border:0;'
    'background:transparent;color:inherit;overflow:visible;inset:auto;'
    'width:auto;height:auto}'
    ':where([$kTopLayerPanelAttribute][popover]:not(:popover-open)){'
    'display:block}';

/// A panel (or a preview) folding back into the source it opened from
/// (`ContextMenu(liftChild:)`). The end scale is read from
/// `--coui-overlay-retract-scale` on the animated box, and the point it folds
/// toward is that box's `transform-origin`, so one definition serves every
/// menu.
const String _kRetractFrom = 'opacity:1;transform:scale(1)';
const String _kRetractTo =
    'opacity:0;transform:scale(var(--coui-overlay-retract-scale))';
const String _kRetractKeyframes =
    '@keyframes co-overlay-retract{from{$_kRetractFrom}to{$_kRetractTo}}';

/// The dim that a lifted context menu's source stands over is a translucent
/// fill; a forced-colours page replaces every fill with an opaque system
/// colour, which would hide the page the dim is meant to tint. It is left out
/// there — the lifted copy and the menu still show, and the page is not
/// dimmed.
const String _kLiftCss =
    '@media (forced-colors:active){[$kLiftDimAttribute]{display:none}}';

/// How a panel fades in and out.
///
/// A panel that fades by its opacity is one layer: everything in it is drawn
/// into a buffer that is then made translucent. A glass panel's blur reads the
/// page behind it, and the buffer holds only the panel, so under an opacity
/// the blur has nothing to read. The glass goes plain for the whole fade and
/// comes back in the last frame, the page behind it sharp all the while. The
/// browser does the same whether the opacity is on the panel (the filter is
/// applied first, and the sharp page shows through the translucent result) or
/// on a box around it (the filter reads nothing at all).
///
/// So a panel does not carry the opacity of its own fade when it draws a pass.
/// It walks [kFadeProgressVar] from `0` to `1` instead, and the stylesheet
/// states each term of the glass as a function of that number: the blur, the
/// chroma lift and the dimming by `CoreSurfaceDissolve.share` of it, the fill
/// by the number itself (`surfaceFadeTargetBlock` in `theme_config.dart`).
/// The terms that have no number to scale — the shadow and the edge a panel
/// draws on its own box, its content, the layers it draws on its pseudo
/// elements — are faded by keyframes that name only where they start (or end)
/// and leave the other end to what the stylesheet states, so each ends at its
/// own value.
///
/// Which of the two a panel does is a name, not a length: every panel plays
/// the progress and then three animations that its rules name (the opacity,
/// the paint, the layers). A fade root names the opacity and no paint or
/// layers, which is what a panel with no pass plays. The rule that gives a
/// surface its pass names the other two and takes the opacity away, and every
/// rule that drops the pass names the first answer again.
///
/// The progress is **not inherited** (`inherits:false`), so only the element
/// that walks it sees it. A surface inside a fading panel reads `1`.
const String _kFadeCss =
    '@property $kFadeProgressVar{syntax:"<number>";inherits:false; '
    'initial-value:1} '
    '@keyframes co-fade-in{from{$kFadeProgressVar:0}to{$kFadeProgressVar:1}} '
    '@keyframes co-fade-out{from{$kFadeProgressVar:1}to{$kFadeProgressVar:0}} '
    '@keyframes co-fade-opacity-in{from{opacity:0}} '
    '@keyframes co-fade-opacity-out{to{opacity:0}} '
    '@keyframes co-fade-paint-in{from{box-shadow:none; '
    'border-color:transparent}} '
    '@keyframes co-fade-paint-out{to{box-shadow:none; '
    'border-color:transparent}} '
    '@keyframes co-fade-layer-in{from{opacity:0}} '
    '@keyframes co-fade-layer-out{to{opacity:0}} '
    // A fade root starts every subtree at "no pass": the panel fades by its
    // opacity and plays nothing else. The panel that has a pass says so
    // after, in a rule that outranks this.
    '.$kFadeBoxClass,.$kFadePanelClass{'
    '$kFadeOpacityAnimationVar:var($kFadeOpacityNameVar);'
    '$kFadePaintAnimationVar:$kFadeNoAnimation;'
    '$kFadeLayerAnimationVar:$kFadeNoAnimation} '
    // The panel in a motion box: the progress, then the three the rules name.
    '.$kFadeBoxClass>*{animation:'
    'var($kFadeProgressAnimationVar) var($kFadeDurationVar) '
    'var($kFadeEasingVar) both, '
    'var($kFadeOpacityAnimationVar) var($kFadeDurationVar) '
    'var($kFadeEasingVar) both, '
    'var($kFadePaintAnimationVar) var($kFadeDurationVar) '
    'var($kFadeEasingVar) var($kFadeFillVar)} '
    // The layers of a panel with a pass: its content (what is directly in
    // it) and what it draws on its own pseudo-elements.
    '.$kFadePanelClass>*,.$kFadeBoxClass>*>*,'
    '.$kFadePanelClass::before,.$kFadePanelClass::after,'
    '.$kFadeBoxClass>*::before,.$kFadeBoxClass>*::after{animation:'
    'var($kFadeLayerAnimationVar) var($kFadeDurationVar) '
    'var($kFadeEasingVar) var($kFadeFillVar)} ';

/// Everything the host's single `<style>` carries.
const String _kHostCss =
    _kOverlayKeyframes +
    _kFadeCss +
    _kRetractKeyframes +
    _kTopLayerCss +
    _kLiftCss;

/// Root-level overlay host. Mount once near the top of the tree
/// (typically inside [CoUIWeb]); descendants portal their floating
/// panels into its overlay layer via [OverlayPortal].
///
/// The host renders [child] and three sibling `<div>` overlay layers
/// (popover / menu / tooltip) carrying the active entries from
/// [OverlayController]. Each overlay-layer `<div>` uses
/// `display: contents` so it has no painting box of its own —
/// children own their own positioning (typically `position: fixed`)
/// so they sit above all surrounding content regardless of ancestor
/// `overflow` or `transform`.
class OverlayHost extends StatefulComponent {
  /// Creates an overlay host. [child] is the rest of the
  /// application tree.
  const OverlayHost({required this.child, super.key});

  /// The application tree rendered next to (and below in z-order)
  /// the overlay layers.
  final Component child;

  @override
  State<OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<OverlayHost> {
  final _controller = OverlayController();

  /// Stops promoting marked panels into the top layer (no-op on the server).
  void Function()? _releaseTopLayerPromoter;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    // Every host installs it; the browser side shares one observer.
    _releaseTopLayerPromoter = installTopLayerPromoter();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _releaseTopLayerPromoter?.call();
    _releaseTopLayerPromoter = null;
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      // The host root is a DOM-less fragment, NOT a wrapper element —
      // even a `display: contents` carrier is not layout-neutral here:
      // with the backdrop wrapper below it the app content ends up
      // under TWO nested `contents` boxes, and Chromium's shrink-to-fit
      // intrinsic sizing collapses `w-full` descendants through nested
      // `contents` chains (fit-content ancestors measured the content
      // at word width — arbitrary components rendered shrunk inside
      // preview panes). One `contents` layer is fine; two are not.
      child: Component.fragment([
        // Global overlay enter/exit keyframes and the top-layer panel
        // reset (see `_kHostCss`). A `<style>` anywhere in the document
        // defines `@keyframes` globally. Raw, not text: the server escapes
        // text (`>` becomes `&gt;`) and a style element is not decoded, so
        // the child combinators in the fade rules would reach the browser
        // as `&gt;` and be dropped.
        const Component.element(
          tag: 'style',
          children: [RawText(_kHostCss)],
        ),
        // Backdrop wrapper — the drawer's backdrop transform (shadcn
        // zoom-out) styles the FIRST `data-coui-backdrop` element in
        // the document directly (Vaul-style): in an SSR'd app the
        // root host's wrapper is static server HTML that client
        // islands never re-render, so imperative styles survive; in
        // a client-rooted app this host's own wrapper is the target.
        // `display: contents` — the wrapper must never be a LAYOUT
        // box: a plain block `<div>` here becomes the flex item in
        // whatever context hosts this subtree and breaks the child's
        // centering/width (nested preview-pane hosts hit this as
        // arbitrary component regressions). The drawer flips the
        // styled target to `display: block` imperatively for the
        // duration of the backdrop transform (a contents box cannot
        // be transformed) and restores it on teardown.
        div(
          [component.child],
          classes: 'contents',
          // `inert` is the whole of modal containment in one attribute:
          // it removes the subtree from the accessibility tree, from
          // the tab order, and from hit-testing. That is the three
          // things Flutter needs `BlockSemantics` + a focus scope + a
          // barrier to say separately.
          //
          // Deliberately not `aria-hidden` — putting that on a subtree
          // that still holds focusable content is an ARIA violation and
          // is worse than nothing. `inert` subsumes it correctly.
          //
          // Deliberately no JS focus cycle either: with the background
          // inert, Tab runs panel → browser chrome → panel on its own.
          // That is the correct behaviour and it does not trap the user
          // inside the page.
          attributes: _controller.hasModalEntry
              ? const {'data-coui-backdrop': '', 'inert': ''}
              : const {'data-coui-backdrop': ''},
        ),
        div(
          _controller.popoverEntries.toList(),
          id: 'coui-overlay-popover',
          classes: _kPopoverLayerClasses,
        ),
        div(
          _controller.menuEntries.toList(),
          id: 'coui-overlay-menu',
          classes: _kMenuLayerClasses,
        ),
        div(
          _controller.tooltipEntries.toList(),
          id: 'coui-overlay-tooltip',
          classes: _kTooltipLayerClasses,
        ),
        div(
          _controller.dialogEntries.toList(),
          id: 'coui-overlay-dialog',
          classes: _kDialogLayerClasses,
        ),
      ]),
    );
  }
}
