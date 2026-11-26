/// Style-slot single entry point for the Web `ContextMenu`.
///
/// The context-menu panel composes the unified `Menu` (box + rows +
/// dividers + shortcuts all resolve inside `Menu`), so this resolver
/// produces the host-overlay chrome (scope wrapper + engine-positioned
/// panel wrapper) and raw-forwards the merged [CoreMenuStyle] to the inner
/// `Menu`. Reads `CoreContextMenuTheme` (independent from `DropdownMenu`).
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_lift.dart'
    show ContextMenuLiftBox;
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedContextMenu
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `ContextMenu`.
///
/// DOM shape:
///
/// ```text
/// root (<div relative inline-block>)            // scope wrapper hosting the child region
///   ├─ source (<div>)                           // wraps the child when it lifts — hidden while lifted
///   │    └─ child                               // caller-supplied trigger region
///   ├─ anchor (<div absolute 1×1>)              // virtual pointer anchor (when open) — id only
///   ├─ lift layer (<div fixed inset-0>)         // the lifted copy over a dim (when lifted)
///   ├─ positioner (<div fixed z-60>)            // engine-positioned panel wrapper (when open)
///   │    └─ Menu (<div role="menu">)          // composed Menu (box + rows + dividers)
///   └─ preview (<div fixed z-60>)               // beside the panel (when a preview is given)
///        └─ Popup (<div>)                       // the preview in the floating-panel chrome
/// ```
///
/// [root] / [positioner] / [preview] are paint-ready [WebElementChrome];
/// [panel] carries the composed `Menu`'s animation durations and [menuStyle]
/// is raw-forwarded to the inner `Menu` (which paints the box / rows itself).
/// The numbers of the lift are not DOM chrome, so they ride in [runtime].
class ResolvedContextMenu implements WebResolvedChrome {
  /// Creates a [ResolvedContextMenu].
  const ResolvedContextMenu({
    required this.root,
    required this.source,
    required this.positioner,
    required this.preview,
    required this.panel,
    required this.menuStyle,
    required this.runtime,
  });

  /// Paint-ready chrome for the outer `<div>` scope wrapper —
  /// `relative inline-block` so the (non-portalled) panel can be
  /// positioned relative to the child region without overflowing the
  /// surrounding layout.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the `<div>` that wraps the child of a menu that
  /// lifts it. The wrapper is there from the start so that lifting never
  /// re-creates the child; it hides the original (`opacity-0`, which leaves it
  /// in the accessibility tree and under the pointer) while the lifted copy
  /// stands in for it.
  final WebElementChrome source;

  /// Paint-ready chrome for the engine-positioned panel wrapper
  /// `<div fixed z-60>` that hosts the floating panel. The
  /// flip/shift-resolved viewport-space `top` / `left` origin computed
  /// by the `OverlayPositioner` is baked into `inlineStyles`; `null`
  /// until the first frame resolves it.
  final WebElementChrome positioner;

  /// Paint-ready chrome for the preview's fixed wrapper. It ignores the
  /// pointer. Until the preview has been placed around the menu it carries no
  /// offset, so it takes the room a preview of its natural size would; once
  /// placed it carries the corner and the largest size the room allows.
  final WebElementChrome preview;

  /// Resolved popup-panel chrome — read only for its open / close
  /// animation durations (the composed `Menu` paints the actual box).
  final ResolvedPopup panel;

  /// Merged [CoreMenuStyle] (`CoreMenuTheme.style` ←
  /// `CoreContextMenuTheme.style.menuStyle` ← `component.contextMenuStyle
  /// .menuStyle`) raw-forwarded to the composed `Menu`'s `menuStyle` slot;
  /// `null` leaves the inner `Menu` at its design-system defaults.
  final CoreMenuStyle? menuStyle;

  /// Client-side runtime config of the lift — the numbers the lift's clock, the
  /// lifted copy and the panel's fold are driven by. Held in the separate
  /// [ResolvedContextMenuRuntime] holder so this chrome bundle carries only
  /// paint-ready element slots.
  final ResolvedContextMenuRuntime runtime;
}

/// Client-side runtime config for Web `ContextMenu`. Fed to the lift's clock,
/// to the resolver of the lifted copy's frames, and to the panel's fold — the
/// settled numbers of the opt-in lift (`liftChild`), what the style and the
/// theme state or the design-system defaults. No DOM chrome (does not
/// implement `WebResolvedChrome`): these are the values `context_menu.dart`
/// reads to drive the rise and the fold, and none of them is written onto an
/// element as it stands — each frame scales them by the lift's progress first.
class ResolvedContextMenuRuntime {
  /// Creates a [ResolvedContextMenuRuntime].
  const ResolvedContextMenuRuntime({
    required this.liftDuration,
    required this.liftScale,
    required this.liftDimOpacity,
    required this.liftCast,
    required this.liftRadius,
    required this.retractScale,
  });

  /// How long the lift's rise (and its way back from a release) takes, as the
  /// style states it. The widget applies reduced motion to it (a transition is
  /// a jump for a person who asked for less motion) and the engine holds a held
  /// touch's rise to what the hold leaves (`CoreContextMenuLift.riseDuration`),
  /// so this is the ask, not always the run.
  final Duration liftDuration;

  /// The size the lifted copy reaches, as a multiple of the original's. The
  /// engine holds it to 1 or more.
  final double liftScale;

  /// How dark the page behind the lifted copy gets at full lift, as a share of
  /// the scrim colour. The engine holds it to 0..1.
  final double liftDimOpacity;

  /// The cast of the lifted copy at full lift, as Core layers: each frame
  /// scales them by the lift's progress before they are written as CSS.
  final List<CoreShadowLayer> liftCast;

  /// The corners of the box the cast is cast from.
  final CoreBorderRadius liftRadius;

  /// The size the folding panel (and the preview) reach, as a multiple of
  /// their own. The engine holds it to 0..1.
  final double retractScale;
}

// ════════════════════════════════════════════════════════════════
// resolveContextMenu — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedContextMenu] for the given [context].
///
/// Folds `CoreContextMenuTheme.style` over the design-system defaults and
/// the per-instance [contextMenuStyle]; the panel chrome delegates to
/// `resolvePopup` on the merged [CoreMenuStyle.popupStyle] (for the
/// animation durations). The lift's numbers come out of the same chain, so a
/// style states them per instance or through the theme, and the per-instance
/// value wins. [left] / [top] are the flip/shift-resolved
/// viewport-space origin reported by the `OverlayPositioner` engine; when
/// either is `null` the panel is not yet positioned, so the positioner
/// ships no inline offset. [previewPlacement] is where
/// `CoreContextMenuPreview.place` put the preview around the placed panel;
/// `null`, or a placement with no room, leaves the preview unplaced.
ResolvedContextMenu resolveContextMenu(
  BuildContext context, {
  double? left,
  double? top,
  CorePreviewPlacement? previewPlacement,
  CoreContextMenuStyle? contextMenuStyle,
  bool liftHidden = false,
}) {
  // ─── Merge chain ──────────────────────────────────────
  final menuTheme = context.theme.coreComponentTheme?.contextMenu;
  final merged = resolveStyleChain(const CoreContextMenuStyle(), [
    menuTheme?.style,
    contextMenuStyle,
  ]);

  // Nested slot — the context menu's (empty) partial with the
  // per-instance override merged on top, raw-forwarded so the inner
  // `Menu` resolver fills its own defaults (no field-by-field reach).
  final menuStyle = CoreContextMenuStyle.defaultMenuStyle.merge(
    merged.menuStyle,
  );

  // Panel durations come from the forwarded menu panel style (the inner
  // `Menu` paints the box; this only needs the open/close durations).
  final panel = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: menuStyle.popupStyle,
  );

  // ─── Stage 1 RESOLVE — the lift's numbers ─────────────
  final liftDuration =
      merged.liftDuration ?? CoreContextMenuStyle.defaultLiftDuration;
  final liftScale = merged.liftScale ?? CoreContextMenuStyle.defaultLiftScale;
  final liftDimOpacity =
      merged.liftDimOpacity ?? CoreContextMenuStyle.defaultLiftDimOpacity;
  final liftCast = merged.liftCast ?? CoreContextMenuStyle.defaultLiftCast;
  final liftRadius =
      merged.liftRadius ?? CoreContextMenuStyle.defaultLiftRadius;
  final retractScale =
      merged.retractScale ?? CoreContextMenuStyle.defaultRetractScale;

  /// Composes the outer `<div>` scope wrapper Tailwind className —
  /// `relative inline-block` so the panel can be positioned relative to
  /// the child region without overflowing the surrounding layout.
  String buildRootClassName() => WebLayout.relativeInlineBlock;

  /// Composes the className of the `<div>` around a lifted child: nothing
  /// while the original is shown, transparent while the lifted copy stands in.
  String buildSourceClassName() => liftHidden ? 'opacity-0' : '';

  /// Composes the panel wrapper `<div>` Tailwind className —
  /// `fixed z-${CoreZIndex.scale.z60}` (popover layer) so the
  /// engine-positioned panel floats above the page content. The
  /// mounted-but-unplaced flash is suppressed by the INNER motion box's
  /// closed-state `opacity-0` + `pointer-events-none`, so no `invisible`
  /// is needed here.
  String buildPositionerClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z60}';

  /// Composes the panel wrapper inline-CSS bundle — the flip/shift-
  /// resolved viewport-space `(left, top)` origin computed by the
  /// `OverlayPositioner`. Returns `null` until the first frame resolves
  /// the position.
  Styles? buildPositionerInlineStyles() {
    if (left == null || top == null) return null;
    return Styles(
      raw: {
        'top': '${top / kRemDivisor}rem',
        'left': '${left / kRemDivisor}rem',
      },
    );
  }

  /// Composes the preview wrapper `<div>` Tailwind className — the panel
  /// wrapper's layer, and the pointer passes through it: a tap on the preview
  /// is a tap outside the menu.
  String buildPreviewClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z60} '
      '${WebLayout.pointerEventsNone}';

  /// Composes the preview wrapper inline-CSS bundle — the corner and the
  /// largest size `CoreContextMenuPreview.place` allows. The values are read
  /// back from layout (the menu's box, the preview's measured size), so they
  /// go in as measured pixels. `overflow: hidden` holds a preview the room
  /// holds only in part to its box. `null` until the preview is placed.
  Styles? buildPreviewInlineStyles() {
    if (previewPlacement == null || !previewPlacement.visible) return null;
    final box = previewPlacement.box;
    return Styles(
      raw: {
        'left': measuredPxCss(box.left),
        'top': measuredPxCss(box.top),
        'max-width': measuredPxCss(box.width),
        'max-height': measuredPxCss(box.height),
        'overflow': 'hidden',
      },
    );
  }

  return ResolvedContextMenu(
    root: WebElementChrome(className: buildRootClassName()),
    source: WebElementChrome(className: buildSourceClassName()),
    positioner: WebElementChrome(
      className: buildPositionerClassName(),
      inlineStyles: buildPositionerInlineStyles(),
    ),
    preview: WebElementChrome(
      className: buildPreviewClassName(),
      inlineStyles: buildPreviewInlineStyles(),
    ),
    panel: panel,
    menuStyle: menuStyle,
    runtime: ResolvedContextMenuRuntime(
      liftDuration: liftDuration,
      liftScale: liftScale,
      liftDimOpacity: liftDimOpacity,
      liftCast: liftCast,
      liftRadius: liftRadius,
      retractScale: retractScale,
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// ResolvedContextMenuLift
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for one frame of the lift of a `ContextMenu`'s source.
///
/// DOM shape:
///
/// ```text
/// root (<div fixed inset-0>)                   // top layer, ignores the pointer
///   ├─ dim (<div absolute inset-0>)            // tints the page, scrim at the dim
///   └─ copy (<div absolute>)                   // at the source's box: scaled, casting
///        └─ child                              // a second build of the child
/// ```
class ResolvedContextMenuLift implements WebResolvedChrome {
  /// Creates a [ResolvedContextMenuLift].
  const ResolvedContextMenuLift({
    required this.root,
    required this.dim,
    required this.copy,
  });

  /// The wrapper that holds the dim and the copy over the whole viewport.
  @override
  final WebElementChrome root;

  /// The tint over the page, its alpha already the dim at this progress.
  final WebElementChrome dim;

  /// The copy of the source: placed at the box it was measured at, scaled
  /// about its middle, casting the shadow of this progress.
  final WebElementChrome copy;
}

/// Resolves [ResolvedContextMenuLift] for a lift that has come [progress] of
/// the way (0 at rest, 1 fully lifted), over a source measured at [source] —
/// what `CoreContextMenuLift` says that progress looks like for the numbers
/// [runtime] settled, as CSS.
///
/// A second entry point beside [resolveContextMenu], for the same reason the
/// per-item sub-widgets have one: it is resolved on every frame of an
/// animation, by a component that is not the menu. It takes the menu's own
/// settled numbers instead of merging a style again, so the numbers a frame
/// draws with are the ones the clock and the fold run on.
ResolvedContextMenuLift resolveContextMenuLift(
  BuildContext context, {
  required double progress,
  required ContextMenuLiftBox source,
  required ResolvedContextMenuRuntime runtime,
}) {
  // Stage 1 RESOLVE — the Core values at this progress.
  final scale = CoreContextMenuLift.scale(
    progress,
    liftScale: runtime.liftScale,
  );
  final dimAlpha = CoreContextMenuLift.dim(
    progress,
    opacity: runtime.liftDimOpacity,
  );
  final cast = CoreContextMenuLift.cast(progress, layers: runtime.liftCast);
  final radius = runtime.liftRadius;

  /// The layer sits over the page and under the menu's panel (z-60), and the
  /// pointer goes through it to the original that is being pressed.
  String buildLayerClassName() =>
      '${WebLayout.fixed} ${WebLayout.insetZero} '
      '${WebLayout.pointerEventsNone} z-${CoreZIndex.scale.z50}';

  /// The page's colour and shadow transitions (which smooth a theme switch)
  /// must not reach these two: the tint and the cast are the lift's value at
  /// this frame, not a value a transition is still on its way to.
  String buildDimClassName() => '${WebLayout.absoluteFull} transition-none';

  /// The scrim token at [alpha], on the colour and not on the node: the copy
  /// and the panel above it stay opaque. The alpha is written as a number, not
  /// a whole percent, so the tint grows smoothly with the lift.
  String scrimAt({required double alpha}) =>
      'rgb(var(--coui-${CoreColors.scrim.name}) / ${alpha.toStringAsFixed(4)})';

  Styles buildDimInlineStyles() =>
      Styles(raw: {'background-color': scrimAt(alpha: dimAlpha)});

  String buildCopyClassName() =>
      '${WebLayout.absolute} ${WebLayout.pointerEventsNone} transition-none';

  /// The copy is laid out in a box of the source's measured size, so the child
  /// is as big in it as it is in the page. The cast goes through `emitShadow`:
  /// a stack that is a scale step (the lift at full progress is the
  /// `CoreShadow.lg` step) is the `--shadow-*` variable a surface style bends,
  /// and any other stack — every progress short of full — is the literal
  /// layers, which the style does not reach. The corner is the scale step's
  /// variable, so the knocked-out box follows a style that re-points radii.
  Styles buildCopyInlineStyles() => Styles(
    raw: {
      'left': measuredPxCss(source.left),
      'top': measuredPxCss(source.top),
      'width': measuredPxCss(source.width),
      'height': measuredPxCss(source.height),
      'border-radius': radius.toValue(),
      'transform': 'scale(${scale.toStringAsFixed(6)})',
      'box-shadow': emitShadow(cast, base: kShadowVariableBase),
    },
  );

  return ResolvedContextMenuLift(
    root: WebElementChrome(className: buildLayerClassName()),
    dim: WebElementChrome(
      className: buildDimClassName(),
      inlineStyles: buildDimInlineStyles(),
    ),
    copy: WebElementChrome(
      className: buildCopyClassName(),
      inlineStyles: buildCopyInlineStyles(),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// Retract motion
// ════════════════════════════════════════════════════════════════

/// The motion of a panel (or a preview) folding back into the source it opened
/// from: `co-overlay-retract` over [closeDuration], along the exit easing,
/// scaled about the point ([originX], [originY]) of its own box.
///
/// The animation is the keyframes pair the host injects, not a transition, for
/// the reason `resolveOverlayMotion` gives: the portal re-creates the panel's
/// node on every render, and a keyframes animation plays whenever the node is
/// inserted. The end scale rides on a custom property so the keyframes stay
/// one definition for every menu.
///
/// The origin is where `CoreContextMenuRetract.pivot` puts the fold, in the
/// box's own coordinates — measured, so it goes in as pixels. The size it folds
/// to is [retractScale], the number `CoreContextMenuRetract.frame` draws with
/// (held to 0..1 by `CoreContextMenuRetract.endScaleOf`).
WebElementChrome resolveContextMenuRetractMotion({
  required Duration closeDuration,
  required double originX,
  required double originY,
  required double retractScale,
}) {
  return WebElementChrome(
    className: WebLayout.pointerEventsNone,
    inlineStyles: Styles(
      raw: {
        'transform-origin':
            '${measuredPxCss(originX)} ${measuredPxCss(originY)}',
        '--coui-overlay-retract-scale':
            '${CoreContextMenuRetract.endScaleOf(retractScale)}',
        'animation':
            'co-overlay-retract '
            '${durationMsCss(closeDuration.inMilliseconds)} '
            '${CoreEasing.exit.toVarCss()} both',
      },
    ),
  );
}
