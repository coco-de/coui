import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Layout vocabulary (pure structure — no chrome tokens)
// ═══════════════════════════════════════════════════

/// Root wrapper: a relatively-positioned full-size box the handle/panel
/// float over (mirrors Flutter's `Stack` + `Positioned.fill` child).
const String _kRootLayout = '${WebLayout.relative} w-full h-full';

/// Root wrapper for an `outside` dock: the handle rests partly past the
/// edge, so the part beyond it must be cut off rather than widening the
/// page (Flutter parity: `Stacks` clips its children to its bounds).
const String _kRootClippedLayout = '$_kRootLayout ${WebLayout.overflowHidden}';

/// Collapsed handle: absolutely-positioned centred box. Runtime `left`/
/// `top` are added by `co_draggable_panel.dart` from drag state.
const String _kHandleLayout =
    '${WebLayout.absolute} flex items-center justify-center';

/// Expanded panel surface: absolutely-positioned column; `left`/`top` added
/// by the widget from drag state. It does not scroll — the scroller is inside
/// it (see [_kPanelScrollLayout]) — so the surface's own edge band is not cut
/// off at its padding box.
const String _kPanelLayout =
    '${WebLayout.absolute} ${WebLayout.flex} ${WebLayout.flexCol}';

/// The panel's scroller: the room the surface's `max-height` leaves inside its
/// border and padding, scrolled when the content is taller. Flutter's panel is
/// built the same way — a `SingleChildScrollView` inside the `Padding` inside
/// the `DecoratedBox` that draws the border — so a scrollbar sits inside the
/// padding on both platforms. `min-h-0` lets a flex item shrink below its
/// content, which is what makes the `max-height` bite.
const String _kPanelScrollLayout =
    '${WebLayout.minHZero} ${WebLayout.overflowYAuto}';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DraggablePanel`.
///
/// DOM shape (`co_draggable_panel.dart` adds runtime `left`/`top` to the
/// handle / panel from drag state — those are behaviour, not chrome):
///
/// ```text
/// root (<div> relative, full-size; clips for an `outside` dock)
///   ├─ child                              // caller subtree, Positioned.fill
///   ├─ panel (<div>)                      // rendered only while open
///   │    └─ panelScroller (<div>)         // scrolls when taller than the room
///   │         └─ panel content            // caller-supplied Component
///   └─ handle (<div>)                     // drag affordance, snaps to edge
///        └─ handle content                // caller Component or default glyph
/// ```
///
/// `co_draggable_panel.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body (only runtime `left`/`top` and caller css are merged).
class ResolvedDraggablePanel implements WebResolvedChrome {
  /// Creates a [ResolvedDraggablePanel].
  const ResolvedDraggablePanel({
    required this.root,
    required this.handle,
    required this.handleIconStyle,
    required this.panel,
    required this.panelScroller,
  });

  /// Paint-ready chrome for the outer relative wrapper.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the collapsed handle (chrome only — the
  /// widget appends `left`/`top` from drag state). Carries the glyph
  /// `color` + `font-size` so the default glyph inherits them.
  final WebElementChrome handle;

  /// Nested icon chrome for the default handle icon — raw-forwarded to
  /// the unified `Icon` (which owns its own resolve step) so both
  /// platforms rasterise the same vector glyph.
  final CoreIconStyle handleIconStyle;

  /// Paint-ready chrome for the expanded panel surface (chrome only).
  final WebElementChrome panel;

  /// Paint-ready chrome for the scroller inside the panel — layout only, the
  /// surface (border, fill, shadow, padding) is [panel]'s.
  final WebElementChrome panelScroller;
}

// ═══════════════════════════════════════════════════
// Client runtime — dock geometry
// ═══════════════════════════════════════════════════

/// Client-side runtime config for `DraggablePanel`. Fed to the pointer /
/// resize handlers, which need *numbers* rather than chrome: the handle
/// is placed, clamped and snapped against a live container measurement,
/// and only Dart can do that arithmetic.
///
/// The sizes here run through the same merge chain as
/// [resolveDraggablePanel], so a theme `handleSize` override moves the
/// dock geometry by the same amount it moves the painted handle — the
/// Flutter twin reads `resolved.handleSize` for both, and a widget that
/// read its own style slot instead would hide a different width than it
/// draws.
///
/// Kept off [ResolvedDraggablePanel] on purpose — that carries chrome
/// slots only.
class ResolvedDraggablePanelRuntime {
  /// Creates a [ResolvedDraggablePanelRuntime].
  const ResolvedDraggablePanelRuntime({
    required this.dockType,
    required this.dockOffset,
    required this.handleSize,
    required this.panelWidth,
  });

  /// How the collapsed handle docks against the nearer edge.
  final CoreDraggablePanelDockType dockType;

  /// Gap between the logical dock slot and the edge, in CSS px.
  final double dockOffset;

  /// Resolved handle size (CSS px) — the width the handle is drawn at.
  final double handleSize;

  /// Resolved panel width (CSS px) — the span the panel needs beside the
  /// handle.
  final double panelWidth;

  /// Logical dock slot of the left (`left: true`) or right edge.
  double dockSlotX({required double containerWidth, required bool left}) =>
      left ? dockOffset : containerWidth - handleSize - dockOffset;

  /// Left-most x the handle may occupy while dragging.
  double get dragMinX =>
      dockType.minX(handleSize: handleSize, dockOffset: dockOffset);

  /// Right-most x the handle may occupy while dragging.
  double dragMaxX(double containerWidth) => dockType.maxX(
    viewWidth: containerWidth,
    handleSize: handleSize,
    dockOffset: dockOffset,
  );

  /// Whether a handle at logical [x] sits in the left half — the edge it
  /// snaps to and the side the panel opens away from.
  bool isLeftHalf({required double x, required double containerWidth}) =>
      x + handleSize / 2 < containerWidth / 2;

  /// Where the handle is painted for its logical position [x].
  ///
  /// A live drag paints at [x] so the handle tracks the pointer, and
  /// before the container is measured ([containerWidth] null) there is no
  /// frame to resolve a slot against. Otherwise the dock-type resting
  /// slot — a closed `outside` handle rests past the edge it is docked to
  /// (Flutter parity: `DraggablePanel._paintedX`).
  double paintedX({
    required double x,
    required bool open,
    required bool dragging,
    double? containerWidth,
  }) {
    if (dragging || containerWidth == null) return x;
    return dockType.restingX(
      x: x,
      open: open,
      viewWidth: containerWidth,
      handleSize: handleSize,
      dockOffset: dockOffset,
    );
  }

  /// Right inset of the handle while it is still docked in CSS only (SSR,
  /// before the first measurement). An open panel holds the handle at the
  /// logical slot; a closed one rests at the dock type's edge inset.
  double cssDockRightInset({required bool open}) => open
      ? dockOffset
      : dockType.restingEdgeInset(
          handleSize: handleSize,
          dockOffset: dockOffset,
        );
}

/// Resolves the client-side dock geometry for the given [context].
///
/// Runs the same merge chain as [resolveDraggablePanel] so the numbers
/// the handlers place and clamp against are the ones the handle and
/// panel are actually drawn at.
ResolvedDraggablePanelRuntime resolveDraggablePanelRuntime(
  BuildContext context, {
  CoreDraggablePanelDockType dockType =
      CoreDraggablePanelDockType.defaultDockType,
  double dockOffset = CoreDraggablePanelContract.defaultDockOffset,
  CoreDraggablePanelStyle? draggablePanelStyle,
}) {
  final merged = resolveStyleChain(const CoreDraggablePanelStyle(), [
    context.theme.coreComponentTheme?.draggablePanel?.style,
    draggablePanelStyle,
  ]);
  final handleSize =
      merged.handleSize ?? CoreDraggablePanelStyle.defaultHandleSize;
  final panelWidth =
      merged.panelWidth ?? CoreDraggablePanelStyle.defaultPanelWidth;
  return ResolvedDraggablePanelRuntime(
    dockType: dockType,
    dockOffset: dockOffset,
    handleSize: handleSize,
    panelWidth: panelWidth,
  );
}

/// Positions the handle inside the root: explicit container-local
/// `left` / `top` once [positioned] (measured or dragged), otherwise
/// docked to the right edge purely in CSS so SSR needs no measurement.
///
/// [x] / [y] are the handle's logical position (the controller's); the
/// painted `left` comes from [ResolvedDraggablePanelRuntime.paintedX], so
/// a closed `outside` handle rests past its edge, opening pulls it back
/// and a live drag tracks the pointer. [initialTop] is the CSS-docked
/// vertical slot before measurement. The handle's CSS transition
/// animates each move.
Styles buildDraggablePanelHandlePositionInlineStyles(
  ResolvedDraggablePanelRuntime runtime, {
  required bool positioned,
  required double x,
  required double y,
  required bool open,
  required bool dragging,
  required String initialTop,
  double? containerWidth,
}) {
  String remOf(double px) => '${px / kRemDivisor}rem';
  if (positioned) {
    final left = runtime.paintedX(
      x: x,
      open: open,
      dragging: dragging,
      containerWidth: containerWidth,
    );
    return Styles(raw: {'left': remOf(left), 'top': remOf(y)});
  }
  return Styles(
    raw: {
      'right': remOf(runtime.cssDockRightInset(open: open)),
      'top': initialTop,
    },
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDraggablePanel] for the given [context].
///
/// Merge chain (identical to Flutter):
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.draggablePanel.style
///   → widget.draggablePanelStyle
/// ```
///
/// Stage 2 EMIT is theme-FREE: colours emit Tailwind token classes (or
/// `rgb(var(--coui-X))` inline for raw overrides), the browser resolves
/// `--coui-*` at runtime. No `scheme.resolve` (a no-op on Web).
ResolvedDraggablePanel resolveDraggablePanel(
  BuildContext context, {
  CoreDraggablePanelDockType dockType =
      CoreDraggablePanelDockType.defaultDockType,
  bool dragging = false,
  CoreDraggablePanelStyle? draggablePanelStyle,
}) {
  final panelTheme = context.theme.coreComponentTheme?.draggablePanel;

  final merged = resolveStyleChain(const CoreDraggablePanelStyle(), [
    panelTheme?.style,
    draggablePanelStyle,
  ]);

  // Shadow tint as a CSS colour string (the token resolves at runtime).
  final shadowBase =
      (merged.shadowBaseColor ?? CoreDraggablePanelStyle.defaultShadowBaseColor)
          .toValue();

  // ─── Panel chrome ─────────────────────────────────────
  final panelBackgroundEmit = emitColor(
    merged.panelBackgroundColor,
    CoreDraggablePanelStyle.defaultPanelBackgroundColor,
    .background,
  );
  final panelBorderEmit = emitColor(
    merged.panelBorderColor,
    CoreDraggablePanelStyle.defaultPanelBorderColor,
    .border,
  );
  final panelBorderWidth =
      merged.panelBorderWidth ??
      CoreDraggablePanelStyle.defaultPanelBorderWidth;
  final panelBorderRadius =
      (merged.panelBorderRadius ??
              CoreDraggablePanelStyle.defaultPanelBorderRadius)
          .toValue();
  final panelPadding =
      (merged.panelPadding ?? CoreDraggablePanelStyle.defaultPanelPadding)
          .toValue();
  final panelWidth =
      merged.panelWidth ?? CoreDraggablePanelStyle.defaultPanelWidth;
  final panelShadow = emitShadow(
    merged.panelShadow ?? CoreDraggablePanelStyle.defaultPanelShadow,
    base: shadowBase,
  );

  // ─── Handle chrome ────────────────────────────────────
  final handleBackgroundEmit = emitColor(
    merged.handleBackgroundColor,
    CoreDraggablePanelStyle.defaultHandleBackgroundColor,
    .background,
  );
  final handleForegroundEmit = emitColor(
    merged.handleForegroundColor,
    CoreDraggablePanelStyle.defaultHandleForegroundColor,
    .text,
  );
  final handleSize =
      merged.handleSize ?? CoreDraggablePanelStyle.defaultHandleSize;
  final handleBorderRadius =
      (merged.handleBorderRadius ??
              CoreDraggablePanelStyle.defaultHandleBorderRadius)
          .toValue();
  final handleShadow = emitShadow(
    merged.handleShadow ?? CoreDraggablePanelStyle.defaultHandleShadow,
    base: shadowBase,
  );
  final transitionMs =
      (merged.animationDuration ??
              CoreDraggablePanelStyle.defaultAnimationDuration)
          .inMilliseconds;

  String remOf(double px) => '${px / kRemDivisor}rem';
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
  final transition =
      'all ${durationMsCss(transitionMs)} ${CoreEasing.move.toVarCss()}';
  // During an active drag the handle must track the pointer without lag —
  // suppress its transition and re-enable it for the release snap (Flutter
  // parity: `AnimatedPositioned.duration = .zero` while `_animate` is off).
  final handleTransition = dragging ? 'none' : transition;

  // ─── Local builders ───────────────────────────────────
  String buildHandleClassName() => [
    _kHandleLayout,
    handleBackgroundEmit.className,
    handleForegroundEmit.className,
    'cursor-pointer',
    'select-none',
    'z-${CoreZIndex.scale.z30}', // floating tool panel — sidebar-tier layer
  ].where((c) => c.isNotEmpty).join(' ');

  Styles buildHandleInlineStyles() => .new(
    raw: {
      'width': remOf(handleSize),
      'height': remOf(handleSize),
      'border-radius': handleBorderRadius,
      'box-shadow': handleShadow,
      'transition': handleTransition,
      // Pointer-drag on touch devices: without this the browser turns the
      // drag into a scroll and fires `pointercancel` (Flutter's pan
      // gesture needs no equivalent — behaviour, not chrome).
      'touch-action': 'none',
      ...?handleBackgroundEmit.inline,
      ...?handleForegroundEmit.inline,
    },
  );

  String buildPanelClassName() => [
    // A panel dragged around over the page: the page is behind it the
    // whole time. It already appends the rim to its shadow — this is
    // the half that was missing. Paired with the fill published below.
    ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
    _kPanelLayout,
    panelBackgroundEmit.className,
    panelBorderEmit.className,
    'z-${CoreZIndex.scale.z30}',
  ].where((c) => c.isNotEmpty).join(' ');

  Styles buildPanelInlineStyles() => .new(
    raw: {
      'width': remOf(panelWidth),
      'padding': panelPadding,
      'border-radius': panelBorderRadius,
      'border-width': strokeWidthCss(panelBorderWidth),
      // The panel does not clip, so the material's band reaches over its
      // border directly.
      if (panelBorderWidth > 0)
        ...surfaceBleedVar(strokeWidthCss(panelBorderWidth)),
      'border-style': 'solid',
      'box-shadow': '$panelShadow, $kSurfaceRimVar',
      'transition': transition,
      ...?panelBackgroundEmit.inline,
      ...?panelBorderEmit.inline,
      // The marker's other half — a preset restates this fill at a
      // lower alpha and cannot know which token the panel chose.
      ...surfaceFillVar(
        merged.panelBackgroundColor ??
            CoreDraggablePanelStyle.defaultPanelBackgroundColor,
      ),
    },
  );

  final handleIconStyle = CoreDraggablePanelStyle.defaultHandleIconStyle.merge(
    merged.handleIconStyle,
  );

  final rootClassName = switch (dockType) {
    .inside => _kRootLayout,
    .outside => _kRootClippedLayout,
  };

  return ResolvedDraggablePanel(
    root: WebElementChrome(className: rootClassName),
    handle: WebElementChrome(
      className: buildHandleClassName(),
      inlineStyles: buildHandleInlineStyles(),
    ),
    handleIconStyle: handleIconStyle,
    panel: WebElementChrome(
      className: buildPanelClassName(),
      inlineStyles: buildPanelInlineStyles(),
    ),
    panelScroller: const WebElementChrome(className: _kPanelScrollLayout),
  );
}
