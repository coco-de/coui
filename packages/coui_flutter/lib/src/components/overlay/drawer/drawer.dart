import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

/// A drawer panel surface — the body that slides in.
///
/// `Drawer` is intentionally *just the panel*, not the open/close
/// machinery. Use [openDrawer] to actually present it (mirrors
/// shadcn_flutter / shadcn-ui's `openDrawer<T>(...)`):
///
/// ```dart
/// final result = await openDrawer<String>(
///   context: context,
///   side: CoreDrawerSide.right,
///   builder: (ctx) => Drawer(
///     content: ...,
///     title: 'Settings',
///   ),
/// );
/// ```
///
/// The drawer is dismissed by the user (barrier tap, drag-to-dismiss,
/// `closeDrawer` / `Navigator.pop` inside the panel) and the open
/// future completes with the popped result.
///
/// surface:functional — an edge-docked panel a popup route mounts over the
/// page.
class Drawer extends StatelessWidget implements CoreDrawerContract<Widget> {
  /// Creates a [Drawer].
  const Drawer({
    required this.content,
    this.side = CoreDrawerSide.defaultSide,
    this.title,
    this.description,
    this.footer,
    this.barrierDismissible = true,
    this.draggable = true,
    this.dragDismissThreshold = CoreDrawerContract.defaultDragDismissThreshold,
    this.rubberBand = CoreDrawerContract.defaultRubberBand,
    this.showDragHandle = CoreDrawerContract.defaultShowDragHandle,
    this.showCloseButton = CoreDrawerContract.defaultShowCloseButton,
    this.dismissOnEscape = true,
    this.transformBackdrop = true,
    this.fillSafeArea = CoreDrawerContract.defaultFillSafeArea,
    this.drawerStyle,
    super.key,
  });

  @override
  final Widget content;

  @override
  final CoreDrawerSide side;

  @override
  final String? title;

  @override
  final String? description;

  @override
  final Widget? footer;

  @override
  final bool barrierDismissible;

  @override
  final bool draggable;

  @override
  final double dragDismissThreshold;

  /// Declared for contract symmetry — the Web `Drawer` reads it off the
  /// panel. On Flutter the *route* owns the drag, so pass
  /// `openDrawer(rubberBand: …)`; this field on its own changes nothing (the
  /// same split as [draggable] and [dragDismissThreshold]).
  @override
  final bool rubberBand;

  @override
  final bool showDragHandle;

  @override
  final bool showCloseButton;

  @override
  final bool dismissOnEscape;

  @override
  final bool transformBackdrop;

  /// Declared for contract symmetry — the Web `Drawer` reads it off the
  /// panel. On Flutter the *route* decides whether the panel reaches the
  /// screen edge, so pass `openDrawer(fillSafeArea: …)`; this field on its
  /// own changes nothing (the same split as [transformBackdrop] and
  /// [draggable]). The panel needs no flag: it pads its docked edge by
  /// whatever system inset the route left unconsumed.
  @override
  final bool fillSafeArea;

  @override
  final CoreDrawerStyle? drawerStyle;

  /// Returns a copy of this [Drawer] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Drawer copyWith({
    Key? key,
    Widget? content,
    CoreDrawerSide? side,
    String? title,
    String? description,
    Widget? footer,
    bool? barrierDismissible,
    bool? draggable,
    double? dragDismissThreshold,
    bool? rubberBand,
    bool? showDragHandle,
    bool? showCloseButton,
    bool? dismissOnEscape,
    bool? transformBackdrop,
    bool? fillSafeArea,
    CoreDrawerStyle? drawerStyle,
  }) {
    return Drawer(
      key: key ?? this.key,
      content: content ?? this.content,
      side: side ?? this.side,
      title: title ?? this.title,
      description: description ?? this.description,
      footer: footer ?? this.footer,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      draggable: draggable ?? this.draggable,
      dragDismissThreshold: dragDismissThreshold ?? this.dragDismissThreshold,
      rubberBand: rubberBand ?? this.rubberBand,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      dismissOnEscape: dismissOnEscape ?? this.dismissOnEscape,
      transformBackdrop: transformBackdrop ?? this.transformBackdrop,
      fillSafeArea: fillSafeArea ?? this.fillSafeArea,
      drawerStyle: drawerStyle ?? this.drawerStyle,
    );
  }

  void _handleClose(BuildContext context) {
    closeDrawer<void>(context);
  }

  @override
  Widget build(BuildContext context) {
    // The route that opened this panel decided which edge it slides in from,
    // so that edge is the one the panel docks to — its flattened corners and
    // its handle follow it. The Web twin reads the same answer off its entry.
    // Outside a drawer route (a swiper's ghost panel) the panel's own `side`
    // is the only one there is.
    final routeScope = context
        .dependOnInheritedWidgetOfExactType<_DrawerRouteScope>();
    final side = routeScope?.side ?? this.side;
    final resolved = resolveDrawer(
      context,
      side: side,
      drawerStyle: drawerStyle,
    );

    final bgColor = resolved.panelBackgroundColor;
    final bdColor = resolved.panelBorderColor;
    final headerPadding = resolved.headerPadding;
    final contentPadding = resolved.panelPadding;

    final title = this.title;
    final description = this.description;
    final hasHeader = title != null || description != null;

    // The system inset the route left for this panel to absorb — non-zero
    // only under `openDrawer(fillSafeArea: true)`, and then only on the
    // docked edge. Absorbing it as padding *inside* the chrome is what lets
    // the surface reach the screen edge while the content stays clear.
    final dockedInset = routeScope?.dockedInset ?? EdgeInsets.zero;

    // The grab handle sits on the edge that faces the viewport centre —
    // above the header of a bottom sheet, below the content of a top
    // sheet, beside the body on a side drawer's inner edge.
    final handle = showDragHandle
        ? _DrawerHandle(
            vertical: side == .left || side == .right,
            resolved: resolved,
          )
        : null;

    final panelChildren = <Widget>[
      if (handle != null && side == .bottom) handle,
      if (hasHeader)
        Padding(
          padding: headerPadding,
          child: Row(
            crossAxisAlignment: .start,
            spacing: resolved.headerSpacing,
            children: [
              Expanded(
                child: description == null
                    ? DefaultTextStyle.merge(
                        style: resolved.titleStyle,
                        child: Text(title!),
                      )
                    : Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        children: [
                          if (title != null) ...[
                            DefaultTextStyle.merge(
                              style: resolved.titleStyle,
                              child: Text(title),
                            ),
                            Gap(gapStyle: resolved.titleDescriptionGapStyle),
                          ],
                          DefaultTextStyle.merge(
                            style: resolved.descriptionStyle,
                            child: Text(description),
                          ),
                        ],
                      ),
              ),
              // Close button — unified Button with the plain variant,
              // which owns the resting-opacity / hover-fade / foreground.
              // The raw-forwarded closeButtonStyle slot supplies the
              // tap-target padding, hit-area radius, close glyph, hover
              // transition, and focus-ring. The Icon glyph takes its
              // size from the slot's leadingIconStyle and leaves colour
              // null so it inherits the button foreground via the
              // ambient IconTheme.
              // The glyph is an icon, so the button has no text to name it —
              // without this the reader announces an unnamed "button". The
              // Web twin already emits the same string as `aria-label`.
              if (showCloseButton)
                Semantics(
                  button: true,
                  label: CoUILocalizations.of(context).buttonClose,
                  child: Button(
                    onPressed: () => _handleClose(context),
                    variant: .plain,
                    size: .sm,
                    shape: .square,
                    buttonStyle: resolved.closeButtonStyle,
                    child: Icon(
                      LucideIcons.x,
                      iconStyle: resolved.closeButtonStyle.leadingIconStyle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (hasHeader) Divider(dividerStyle: resolved.dividerStyle),
      // A left / right drawer spans the route's full height, so its content
      // fills what the header and footer leave. A top / bottom sheet keeps
      // the loose fit so a content-sized panel — the route hands it loose,
      // viewport-bounded constraints — wraps its content instead of
      // stretching (greedy children still fill the remaining space).
      Flexible(
        fit: side == .left || side == .right ? FlexFit.tight : FlexFit.loose,
        child: Padding(
          padding: contentPadding,
          child: content,
        ),
      ),
      if (footer case final footer?) ...[
        Divider(dividerStyle: resolved.dividerStyle),
        Padding(
          padding: resolved.footerPadding,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: footer,
          ),
        ),
      ],
      if (handle != null && side == .top) handle,
    ];

    Widget panelBody = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: panelChildren,
    );
    if (handle != null && (side == .left || side == .right)) {
      // A side drawer spans the route's full height, so the handle column
      // stretches beside the body and centres its pill on the inner edge.
      panelBody = Row(
        crossAxisAlignment: .stretch,
        children: side == .left
            ? [Expanded(child: panelBody), handle]
            : [handle, Expanded(child: panelBody)],
      );
    }
    if (routeScope != null && dockedInset != EdgeInsets.zero) {
      // The inset is consumed here, so the content — which may carry its
      // own `SafeArea`, or a `Drawer` of its own — must not see it a second
      // time. The scope is re-provided for the same navigator with nothing
      // left to absorb.
      panelBody = Padding(
        padding: dockedInset,
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: dockedInset.left > 0,
          removeTop: dockedInset.top > 0,
          removeRight: dockedInset.right > 0,
          removeBottom: dockedInset.bottom > 0,
          child: _DrawerRouteScope(
            navigator: routeScope.navigator,
            side: routeScope.side,
            dockedInset: EdgeInsets.zero,
            child: panelBody,
          ),
        ),
      );
    }

    Widget panel = InsetShadow(
      shadows: resolved.panelInsetBoxShadow,
      radius: resolved.panelBorderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          // The line sits on the inner edge only — the one facing the page.
          // A zero-width solid side is a hairline, which a rounded box may
          // not draw, so a panel with no line has no border at all.
          border: resolved.panelBorderWidth > 0
              ? _innerEdgeBorder(
                  side,
                  BorderSide(
                    color: bdColor,
                    width: resolved.panelBorderWidth,
                  ),
                )
              : null,
          borderRadius: resolved.panelBorderRadius,
          // Behind a translucent fill the cast is painted outside the box
          // instead (below).
          boxShadow: resolved.castOutsideBox ? null : resolved.panelBoxShadow,
        ),
        child: panelBody,
      ),
    );

    // The resolver hands these over only when the panel states a fill,
    // so a fill-less drawer never stacks a second backdrop pass. The
    // radius is load-bearing: the pass is bounded to the panel shape,
    // or it squares off the corners it blurs.
    final effectiveBlur = resolved.surfaceBlur;
    if ((effectiveBlur != null && effectiveBlur > 0) ||
        resolved.surfaceSheen != null) {
      panel = SurfaceBlur(
        borderRadius: resolved.panelBorderRadius,
        surfaceBlur: effectiveBlur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend. Every surface that draws the material
        // draws all of it — the frost and the chroma without the bend is a
        // blurred panel, not glass, and the bend is the term the material
        // is named for.
        //
        // Falls back rather than being required: a style that states no
        // refraction leaves this null and the surface simply does not
        // bend, which is how every preset but glass renders.
        refraction: Theme.of(context).surfaceRefraction,
        child: panel,
      );
    }

    // Behind a fill that is not opaque, the cast goes outside the box, around
    // the whole panel with its blur ([ResolvedDrawer.castOutsideBox]).
    if (resolved.castOutsideBox) {
      panel = InjectedCast(
        shadows: resolved.panelBoxShadow,
        borderRadius: resolved.panelBorderRadius,
        child: panel,
      );
    }

    return Semantics(
      container: true,
      label: title,
      child: panel,
    );
  }
}

/// A [Border] with [line] on the edge of a panel docked to [side] that faces
/// the page — the right of a left drawer, the top of a bottom sheet.
Border _innerEdgeBorder(CoreDrawerSide side, BorderSide line) {
  return switch (side) {
    .left => Border(right: line),
    .right => Border(left: line),
    .top => Border(bottom: line),
    .bottom => Border(top: line),
  };
}

/// The grab handle — a pill centred in its inset box, lying along the
/// edge it sits on ([vertical] for a side drawer's inner edge). It only
/// says the panel can be dragged; the drag itself is the route's
/// (`_DraggableDrawer`), so it carries no semantics of its own.
class _DrawerHandle extends StatelessWidget {
  const _DrawerHandle({required this.vertical, required this.resolved});

  final bool vertical;
  final ResolvedDrawer resolved;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: .all(resolved.dragHandleInset),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: resolved.dragHandleColor,
              borderRadius: resolved.dragHandleBorderRadius,
            ),
            width: vertical
                ? resolved.dragHandleThickness
                : resolved.dragHandleWidth,
            height: vertical
                ? resolved.dragHandleWidth
                : resolved.dragHandleThickness,
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreDrawerStyle] patch into
/// [Drawer.drawerStyle] without hand-reconstructing every field.
/// Mirrors the Web `Drawer.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDrawerStyle.merge` right-side-wins semantics).
extension DrawerStyleChain on Drawer {
  /// Returns a copy of this [Drawer] with [patch] merged into
  /// [drawerStyle] (patch fields win on conflict).
  Drawer withStyle(CoreDrawerStyle patch) => copyWith(
    drawerStyle: (drawerStyle ?? const CoreDrawerStyle()).merge(patch),
  );
}

/// Handle that exposes an open drawer route's animation to an
/// external drag driver (the `Swiper` gesture engine): setting
/// [controller]`.value` scrubs the slide/backdrop/scrim in lockstep
/// with the finger, and [panelKey] measures the mounted panel so drag
/// deltas can be normalised to open-progress. Pass one to
/// [openDrawer]; the route fills [controller] on install and clears
/// it on dispose.
class DrawerAnimationHandle {
  /// Creates a handle to pass to [openDrawer].
  DrawerAnimationHandle();

  /// Keyed onto the mounted panel subtree so the drag driver can read
  /// the panel's on-screen extent.
  final GlobalKey panelKey = GlobalKey();

  AnimationController? _controller;

  /// The presented route's animation controller (0 = closed,
  /// 1 = open), or null before install / after dispose.
  AnimationController? get controller => _controller;

  /// The mounted panel's extent along [horizontal] ? width : height,
  /// or null before the first layout.
  double? panelExtent({required bool horizontal}) {
    final size = panelKey.currentContext?.size;
    if (size == null) return null;
    return horizontal ? size.width : size.height;
  }
}

/// Imperatively presents a [Drawer] (or any custom panel widget)
/// from one of the four sides of the screen.
///
/// Mirrors `shadcn_flutter`'s `openDrawer<T>`. Returns a future that
/// completes with the value the panel pops (`Navigator.pop(ctx, v)`)
/// or `null` when dismissed via the barrier / drag-to-dismiss /
/// system back button.
///
/// ```dart
/// final result = await openDrawer<String>(
///   context: context,
///   side: CoreDrawerSide.right,
///   builder: (ctx) => Drawer(
///     title: 'Settings',
///     content: ...,
///   ),
/// );
/// ```
///
/// The wrapping behaviour (slide animation, barrier, drag-to-dismiss, rubber
/// band, safe-area inset) is set by this function's parameters, not read off
/// the panel widget — the Web `openDrawer` differs and reads it from the
/// `Drawer` it is handed.
///
/// [rubberBand] lets a draggable panel be pulled past its dock — further open
/// than fully open — instead of stopping dead: its far edge follows the finger
/// with less and less return, bounded by a fraction of the panel's own extent
/// (`CoreDrawerRubberBand`), while the docked edge stays on the screen edge,
/// and letting go pulls it back. It never changes what dismisses: a pull toward
/// the docked edge is judged by the same rule either way, and a panel let go of
/// while stretched has covered no distance, so it stays — a fling in the open
/// direction included. Reduced motion makes the return instant; the stretch
/// while the finger is down is the finger's own motion and stays. Off by
/// default ([CoreDrawerContract.defaultRubberBand]).
///
/// [useRootNavigator] picks which `Navigator` the drawer route is pushed
/// on. The default (`true`) is the root navigator, so the drawer covers
/// everything the root navigator draws. Pass `false` to push onto the
/// *nearest* navigator instead — the one `Navigator.of(context)` finds. In
/// an app that nests a navigator per tab, that keeps the sheet (and its
/// scrim) inside the tab body, so chrome that lives outside that navigator
/// (a bottom navigation bar) stays uncovered and reachable. The sheet is
/// then a route of that navigator, which is what a shell that routes the
/// system back button through the current tab's navigator can pop. When the
/// nearest navigator *is* the root one the two are the same.
/// Opening onto a non-root navigator disables [transformBackdrop]: that
/// transform scales the whole app shell, which a route scoped to one
/// navigator cannot own. Web has no counterpart — its `openDrawer` already
/// mounts on the nearest `OverlayHost` above the call site and has no
/// navigator stack to choose from.
///
/// [routeSettings] names the route the drawer is pushed as, so a
/// `NavigatorObserver` (analytics, a router that keys on route names) sees it
/// under that name and a `ModalRoute.of(context)` inside the panel carries it.
/// Null pushes an anonymous route, as before. Web has no counterpart — it has
/// no navigator stack to observe.
///
/// [fillSafeArea] lets the panel's surface reach the screen edge it is
/// docked to instead of stopping at the system safe area — see
/// [CoreDrawerContract.fillSafeArea]. The other three edges keep their
/// inset, and a [Drawer] panel pads its own content by the inset it absorbs.
/// A custom panel widget (anything but a [Drawer]) receives the inset
/// through `MediaQuery` unconsumed — wrap its content in a `SafeArea` to
/// stay clear of it.
Future<T?> openDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required CoreDrawerSide side,
  bool barrierDismissible = true,
  bool draggable = true,
  double dragDismissThreshold = CoreDrawerContract.defaultDragDismissThreshold,
  bool rubberBand = CoreDrawerContract.defaultRubberBand,
  bool transformBackdrop = true,
  bool fillSafeArea = CoreDrawerContract.defaultFillSafeArea,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  DrawerAnimationHandle? animationHandle,
  CoreDrawerStyle? drawerStyle,
}) {
  final resolved = resolveDrawer(
    context,
    side: side,
    drawerStyle: drawerStyle,
  );
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  // The backdrop transform needs the app-shell host above the
  // navigator (CoUILayer installs one) — and it scales the whole shell, so
  // only a route on the root navigator can own it. Without a host — plain
  // MaterialApp embeds, widget tests — or off the root navigator, the
  // transform silently no-ops.
  final backdropHost =
      transformBackdrop &&
          (useRootNavigator ||
              identical(navigator, Navigator.of(context, rootNavigator: true)))
      ? DrawerBackdropLayer.maybeOf(context)
      : null;

  return navigator.push<T>(
    _DrawerRoute<T>(
      side: side,
      draggable: draggable,
      fillSafeArea: fillSafeArea,
      dragDismissThreshold: dragDismissThreshold,
      rubberBand: rubberBand,
      openDuration: resolved.openAnimationDuration,
      closeDuration: resolved.closeAnimationDuration,
      barrierColor: resolved.barrierColor,
      barrierDismissible: barrierDismissible,
      backdropHost: backdropHost,
      backdropScale: resolved.backdropScale,
      backdropCornerRadius: resolved.backdropCornerRadius,
      animationHandle: animationHandle,
      drawerStyle: drawerStyle,
      routeSettings: routeSettings,
      builder: builder,
    ),
  );
}

/// Closes the topmost open `Drawer`, optionally completing its
/// future with [result]. Mirrors `Navigator.pop` shape.
///
/// Call it with a context *inside* the drawer panel. It reaches the
/// navigator the drawer route was pushed on — the root navigator, or the
/// nearer one when the drawer was opened with
/// `openDrawer(useRootNavigator: false)` — through the ambient
/// [_DrawerRouteScope], so it pops the drawer and not whatever else the
/// root navigator happens to be showing. A context outside any drawer
/// panel has no scope to read and falls back to the root navigator.
///
/// Prefer this over a raw `Navigator.pop(context)` inside a drawer
/// panel: in backdrop-transform mode the panel renders through the
/// app-shell host above the app navigator, and its nearest `Navigator`
/// is the *nested* one that hosts panel-opened dialogs (see
/// `_DrawerRoute._hostPanel`). `Navigator.pop(context)` there would
/// target that nested navigator (dismissing a dialog, not the drawer),
/// so `closeDrawer` reaches the *owning* route through the ambient
/// [_DrawerRouteScope] — do not "simplify" it to `Navigator.of(context)`.
void closeDrawer<T>(BuildContext context, [T? result]) {
  final scope = context.getInheritedWidgetOfExactType<_DrawerRouteScope>();
  if (scope != null) {
    scope.navigator.pop<T>(result);
    return;
  }
  Navigator.of(context, rootNavigator: true).pop<T>(result);
}

/// Ambient scope wrapped around every drawer panel so [closeDrawer] /
/// drag-to-dismiss reach the owning route's navigator — a host-rendered
/// panel paints above it, and a panel on a nested navigator is not on the
/// root one — and so the panel can read the system inset it is meant to
/// absorb.
class _DrawerRouteScope extends InheritedWidget {
  const _DrawerRouteScope({
    required this.navigator,
    required this.side,
    required this.dockedInset,
    required super.child,
  });

  final NavigatorState navigator;

  /// The edge the route slides the panel in from — `openDrawer(side:)`.
  final CoreDrawerSide side;

  /// The system inset the route left unconsumed on the panel's docked edge
  /// (`openDrawer(fillSafeArea: true)`); [EdgeInsets.zero] otherwise.
  final EdgeInsets dockedInset;

  @override
  bool updateShouldNotify(_DrawerRouteScope oldWidget) =>
      navigator != oldWidget.navigator ||
      side != oldWidget.side ||
      dockedInset != oldWidget.dockedInset;
}

/// Internal `PageRoute` that animates a drawer in / out from one of
/// the four sides. Routing through `Navigator` (rather than a raw
/// `OverlayEntry`) gets us back-button handling, focus management,
/// and `Navigator.pop` for free.
class _DrawerRoute<T> extends PopupRoute<T> {
  _DrawerRoute({
    required this.builder,
    required this.side,
    required this.draggable,
    required this.fillSafeArea,
    required this.dragDismissThreshold,
    required this.rubberBand,
    required this.openDuration,
    required this.closeDuration,
    required Color barrierColor,
    required bool barrierDismissible,
    required this.backdropHost,
    required this.backdropScale,
    required this.backdropCornerRadius,
    required this.animationHandle,
    required this.drawerStyle,
    RouteSettings? routeSettings,
  }) : _barrierColor = barrierColor,
       _barrierDismissible = barrierDismissible,
       super(settings: routeSettings);

  final WidgetBuilder builder;
  final CoreDrawerSide side;
  final bool draggable;

  /// Whether the panel's surface reaches the screen edge it is docked to
  /// (`openDrawer(fillSafeArea:)`) — the route then leaves that edge's
  /// system inset for the panel to absorb instead of insetting the panel.
  final bool fillSafeArea;

  /// Drag fraction past which release dismisses — a widget-plane
  /// behaviour value (`Drawer.dragDismissThreshold` /
  /// `openDrawer(dragDismissThreshold:)`), not resolved chrome.
  final double dragDismissThreshold;

  /// Whether the drag may pull the panel past its dock and stretch it
  /// (`Drawer.rubberBand` / `openDrawer(rubberBand:)`) — a widget-plane
  /// behaviour value, like [dragDismissThreshold].
  final bool rubberBand;
  final Duration openDuration;
  final Duration closeDuration;
  final CoreDrawerStyle? drawerStyle;

  /// The app-shell backdrop host, or null when the transform is off /
  /// unavailable. When set the route registers its animation so the
  /// app content scales down behind the panel.
  final DrawerBackdropLayerState? backdropHost;

  /// Backdrop scale when fully open (`CoreDrawerStyle.backdropScale`).
  final double backdropScale;

  /// Backdrop clip corner radius when fully open — full 4-corner
  /// [BorderRadius], so an asymmetric override survives to paint.
  final BorderRadius backdropCornerRadius;

  /// External drag-driver handle (the `Swiper` gesture engine) — the
  /// route fills its controller on install and clears it on dispose.
  final DrawerAnimationHandle? animationHandle;

  final Color _barrierColor;
  final bool _barrierDismissible;

  DrawerBackdropRegistration? _backdropRegistration;

  /// Keys the nested navigator that re-establishes a `Navigator` ancestor
  /// for the host-rendered panel (see [_hostPanel]).
  final GlobalKey<NavigatorState> _panelNavigatorKey =
      GlobalKey<NavigatorState>();

  bool get _transformActive => backdropHost != null;

  @override
  AnimationController createAnimationController() {
    final controller = super.createAnimationController();
    animationHandle?._controller = controller;
    return controller;
  }

  @override
  TickerFuture didPush() {
    final host = backdropHost;
    if (host != null && _backdropRegistration == null) {
      _backdropRegistration = host.register(
        animation: animation!,
        scale: backdropScale,
        cornerRadius: backdropCornerRadius,
        // The panel renders through the host, above the clipped
        // backdrop (a route-rendered panel would be cut by the host's
        // corner clip — no descendant can paint outside an ancestor
        // clip). Slide + layout resolve under the host's context.
        panel: _hostPanel(),
      );
    }
    return super.didPush();
  }

  @override
  void dispose() {
    animationHandle?._controller = null;
    final registration = _backdropRegistration;
    if (registration != null) {
      backdropHost?.unregister(registration);
      _backdropRegistration = null;
    }
    _slideCurve?.dispose();
    _slideCurve = null;
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Backdrop-transform mode: the route page carries only the scrim.
    // It lives inside the navigator, which the host scales and clips —
    // so it dims exactly the visible (clipped) backdrop. The panel
    // renders through the host, above the clip (see didPush).
    if (_transformActive) {
      return FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: _barrierDismissible ? () => navigator?.maybePop() : null,
          behavior: .opaque,
          child: ColoredBox(color: _barrierColor),
        ),
      );
    }

    return _buildPanelLayout(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Backdrop-transform mode: the page is the scrim (it fades via its
    // own FadeTransition) and the slide lives on the host-rendered
    // panel — wrapping here would slide the scrim.
    if (_transformActive) return child;
    return SlideTransition(
      position: _slideAnimation(animation),
      child: child,
    );
  }

  /// The drawer panel as rendered *through the app-shell host* in
  /// backdrop-transform mode.
  ///
  /// The host paints this above the app navigator (so the corner-clip
  /// doesn't cut the panel), which means the panel subtree has no
  /// `Navigator` ancestor. Consumer code inside the drawer that reaches
  /// for one — `showDialog` (both Flutter's and CoUI's), `Navigator.push`,
  /// `Navigator.of` — would otherwise throw the missing-Navigator error,
  /// which is how a re-confirmation dialog opened from inside a drawer
  /// can hard-fail on mobile while the desktop showDialog-on-root path
  /// stays green.
  ///
  /// We re-establish a real `Navigator` ancestor with a nested navigator
  /// whose single transparent route hosts the panel; any dialog/route the
  /// panel opens pushes onto it and paints (modal, full-screen) above the
  /// panel. Closing the drawer itself still flows through [closeDrawer] /
  /// the ambient [_DrawerRouteScope] — the *owning* navigator, kept below
  /// the nested one — so drag-to-dismiss, barrier tap, and the back button
  /// are unchanged. (`NavigatorPopHandler` is deliberately *not* used: its
  /// `PopScope` binds to the nearest `ModalRoute`, of which the panel —
  /// above the app navigator — has none, so it would be inert here).
  Widget _hostPanel() {
    // A second Navigator must not grab the app's ambient HeroController
    // (that would assert "each Navigator has its own HeroController"), and
    // panel-opened dialogs don't fly heroes — so scope it to none.
    return HeroControllerScope.none(
      child: Navigator(
        key: _panelNavigatorKey,
        // Purely imperative — the sole declarative route is the panel,
        // and everything the panel content opens is pushed onto it.
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, _, _) => Stacks(
            fit: .expand,
            children: [
              // The nested route installs its own (transparent) modal
              // barrier that would otherwise swallow a tap outside the
              // panel. This catcher sits above it and forwards an
              // outside tap to the owning drawer route (root navigator),
              // keeping barrier-tap-to-dismiss working. Static — it must
              // not ride the panel's SlideTransition.
              if (_barrierDismissible)
                GestureDetector(
                  onTap: () => navigator?.maybePop(),
                  behavior: .opaque,
                ),
              SlideTransition(
                position: _slideAnimation(animation!),
                child: Builder(builder: _buildPanelLayout),
              ),
            ],
          ),
          transitionDuration: .zero,
          reverseTransitionDuration: .zero,
          // Transparent + instant — the scaled backdrop shows through
          // around the panel, and the slide motion lives on the panel's
          // own SlideTransition below (not this route).
          opaque: false,
        ),
      ),
    );
  }

  /// The panel layout — side-docked, content-sized on vertical sides,
  /// drag-to-dismiss wrapper when [draggable]. Reused by the normal
  /// route page and (in backdrop-transform mode) by the host-rendered
  /// panel slot.
  ///
  /// On a viewport a fold splits, the panel keeps to one segment — the one
  /// its edge lies in, and where the fold meets that edge, the upper one or
  /// the one at the reading start ([FoldSegment]). A panel across a fold
  /// bends in the middle, and what lands on the fold is hard to read and to
  /// press. The scrim still covers the whole viewport.
  Widget _buildPanelLayout(BuildContext context) => FoldSegment(
    alignment: _panelAlignment(),
    child: Builder(builder: _buildPanelInSegment),
  );

  /// The panel inside the segment it keeps to, whose insets [context] reads.
  ///
  /// The panel sits inside a `SafeArea`. Under [fillSafeArea] that
  /// `SafeArea` skips the docked edge alone — the panel then reaches the
  /// screen edge — and the inset it skipped is handed to the panel through
  /// [_DrawerRouteScope.dockedInset] to absorb as padding. Every other
  /// edge keeps its inset either way.
  Widget _buildPanelInSegment(BuildContext context) {
    final resolved = resolveDrawer(
      context,
      side: side,
      drawerStyle: drawerStyle,
    );

    final isHorizontal = _isHorizontal();
    final panelWidth = resolved.panelWidth;
    final panelHeight = resolved.panelHeight;
    final dockedInset = fillSafeArea
        ? _dockedInsetOf(MediaQuery.paddingOf(context))
        : EdgeInsets.zero;

    return SafeArea(
      left: !(fillSafeArea && side == .left),
      top: !(fillSafeArea && side == .top),
      right: !(fillSafeArea && side == .right),
      bottom: !(fillSafeArea && side == .bottom),
      child: Align(
        alignment: _panelAlignment(),
        child: SizedBox(
          width: isHorizontal ? panelWidth : .infinity,
          // Null height = content-sized: the SizedBox adds no height
          // constraint, so the Align's loose viewport-bounded
          // constraints let the panel wrap its content (capped at the
          // screen). An explicit `panelHeight` fixes the extent.
          height: isHorizontal ? .infinity : panelHeight,
          child: KeyedSubtree(
            key: animationHandle?.panelKey,
            child: _DrawerRouteScope(
              // Non-null: the panel only builds while the route is
              // installed on a navigator.
              navigator: navigator!,
              side: side,
              dockedInset: dockedInset,
              child: draggable
                  ? _DraggableDrawer(
                      side: side,
                      animation: animation!,
                      dragDismissThreshold: dragDismissThreshold,
                      rubberBand: rubberBand,
                      child: Builder(builder: builder),
                    )
                  : Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
  }

  /// The slice of [padding] on the edge the panel is docked to — the only
  /// edge [fillSafeArea] hands to the panel.
  EdgeInsets _dockedInsetOf(EdgeInsets padding) {
    return switch (side) {
      .left => EdgeInsets.only(left: padding.left),
      .right => EdgeInsets.only(right: padding.right),
      .top => EdgeInsets.only(top: padding.top),
      .bottom => EdgeInsets.only(bottom: padding.bottom),
    };
  }

  /// The route owns the eased slide curve and disposes it with itself —
  /// the way `ModalRoute.createAnimation` owns its controller.
  ///
  /// The two alternatives were both worse: building a `CurvedAnimation` in
  /// [_slideAnimation] leaked one per rebuild (it is called from
  /// `buildTransitions` and from the host panel's build), and a
  /// `CurveTween` has no reverse direction, so it would silently drop the
  /// `reverseCurve` the close motion has always used. Owning it keeps the
  /// motion exactly as it was and gives the curve a place to be released.
  CurvedAnimation? _slideCurve;

  Animation<Offset> _slideAnimation(Animation<double> animation) {
    final curve = _slideCurve ??= CurvedAnimation(
      parent: animation,
      curve: CoreEasing.enter.toValue(),
      reverseCurve: CoreEasing.easeOutCubic.toValue(),
    );
    return curve.drive(Tween(begin: _slideOffset(), end: Offset.zero));
  }

  Offset _slideOffset() {
    return switch (side) {
      .left => const Offset(-1, 0),
      .right => const Offset(1, 0),
      .top => const Offset(0, -1),
      .bottom => const Offset(0, 1),
    };
  }

  Alignment _panelAlignment() {
    return switch (side) {
      .left => Alignment.centerLeft,
      .right => Alignment.centerRight,
      .top => Alignment.topCenter,
      .bottom => Alignment.bottomCenter,
    };
  }

  bool _isHorizontal() => side == .left || side == .right;

  @override
  // The scrim paints inside `buildPage` when the backdrop transform is
  // active — the route-level ModalBarrier lives in the (scaled)
  // navigator subtree, so a viewport-sized barrier would shrink with
  // the backdrop and leave an unscrimmed ring. The in-page barrier
  // sits under the counter-scale so it keeps exact viewport geometry.
  Color get barrierColor =>
      _transformActive ? const .fromARGB(0, 0, 0, 0) : _barrierColor;

  @override
  bool get barrierDismissible => _barrierDismissible;

  // Resolved in the getter (not passed at construction) for the same
  // reason as `DialogRoute.barrierLabel`: a localised name needs a
  // `BuildContext`, which does not exist until the route is installed.
  @override
  String get barrierLabel {
    final context = navigator?.context;
    if (context == null) return DefaultCoUILocalizations.instance.dismissLabel;

    return CoUILocalizations.of(context).dismissLabel;
  }

  @override
  Duration get transitionDuration => openDuration;

  @override
  Duration get reverseTransitionDuration => closeDuration;
}

/// Drag-to-dismiss wrapper. Listens to pan gestures along the
/// drawer's slide axis and translates the panel by the drag delta.
/// On release, snaps back to the open state when the drag was shorter
/// than [dragDismissThreshold] of the panel's extent and not a flick,
/// otherwise pops the route (`CoreDrawerContract.dismissesOnRelease`).
///
/// With [rubberBand] the drag does not stop at the dock. Pulled the other way —
/// further open than fully open — the panel's far edge follows the finger with
/// less and less return (`CoreDrawerRubberBand`) while the docked edge stays
/// where it is: the panel is scaled along its slide axis about that edge, so no
/// gap opens between it and the screen edge. Letting go returns it to the dock
/// on the rubber band's curve, or at once under reduced motion. The release
/// rule is untouched: only a pull toward the edge the panel hides behind
/// counts as a distance.
class _DraggableDrawer extends StatefulWidget {
  const _DraggableDrawer({
    required this.side,
    required this.animation,
    required this.dragDismissThreshold,
    required this.rubberBand,
    required this.child,
  });

  final CoreDrawerSide side;
  final Animation<double> animation;
  final double dragDismissThreshold;
  final bool rubberBand;
  final Widget child;

  @override
  State<_DraggableDrawer> createState() => _DraggableDrawerState();
}

class _DraggableDrawerState extends State<_DraggableDrawer>
    with SingleTickerProviderStateMixin {
  /// Pixel offset accumulated since drag start. Sign matches the
  /// drawer's slide-out direction (negative for `left`, positive
  /// for `right`, etc.). The drag of a panel without a rubber band.
  double _dragDelta = 0;

  /// With a rubber band: how far the finger has carried the panel along its
  /// slide axis, positive toward the edge it hides behind and negative the
  /// other way. Unlike [_dragDelta] it is not clamped at the dock — the
  /// stretch is a function of it, so a finger that comes back retraces the
  /// way it went.
  double _pull = 0;

  /// The panel's length on its slide axis when the finger last moved it —
  /// what the stretch is a fraction of.
  double _extent = 0;

  /// The return to the dock after a release: the share of the settle
  /// duration that has gone by, run through [_settleCurve].
  late final AnimationController _settle;

  /// The curve of the return — the same one the Web hands the browser.
  final Curve _settleCurve = CoreDrawerRubberBand.defaultSettleEasing.toValue();

  /// Whether the panel is on its way back to the dock.
  bool _settling = false;

  /// Where the panel was when the finger let go; the return starts here.
  CoreDrawerPose _settleFrom = CoreDrawerRubberBand.rest;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this)
      ..addStatusListener(_handleSettleStatus);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  bool _isHorizontal() => widget.side == .left || widget.side == .right;

  /// Returns 1 when drag direction matches dismiss direction,
  /// -1 otherwise — used to sign-correct `dragDelta` so the panel
  /// only follows the finger *outward*.
  double _dismissDirection() {
    return switch (widget.side) {
      .left || .top => -1,
      .right || .bottom => 1,
    };
  }

  /// The edge the panel is docked to — the fixed point of its stretch.
  Alignment _dock() {
    return switch (widget.side) {
      .left => Alignment.centerLeft,
      .right => Alignment.centerRight,
      .top => Alignment.topCenter,
      .bottom => Alignment.bottomCenter,
    };
  }

  /// The panel's laid-out length on its slide axis, or the last one measured
  /// before it has a size.
  double _measureExtent() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return _extent;

    return _isHorizontal() ? renderBox.size.width : renderBox.size.height;
  }

  /// Where the panel is drawn now: on its way back, or wherever the finger's
  /// pull has put it.
  CoreDrawerPose _poseNow() {
    if (_settling) {
      final left = 1 - _settleCurve.transform(_settle.value);

      return (
        slide: _settleFrom.slide * left,
        stretch: _settleFrom.stretch * left,
      );
    }

    return CoreDrawerRubberBand.poseOf(_pull, extent: _extent);
  }

  void _handleSettleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_settling) return;
    // The curve ends exactly at the dock; nothing is left to draw.
    setState(() {
      _settling = false;
      _settleFrom = CoreDrawerRubberBand.rest;
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _extent = _measureExtent();
    if (!_settling) return;
    // A panel still on its way back is taken hold of where it is: the finger
    // carries on from that pose, not from the dock it was heading for.
    final pose = _poseNow();
    _settle.stop();
    setState(() {
      _settling = false;
      _settleFrom = CoreDrawerRubberBand.rest;
      _pull = CoreDrawerRubberBand.pullOf(pose, extent: _extent);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final isHorizontal = _isHorizontal();
    final delta = isHorizontal ? details.delta.dx : details.delta.dy;
    final dir = _dismissDirection();
    if (widget.rubberBand) {
      setState(() {
        _extent = _measureExtent();
        _pull += delta * dir;
      });

      return;
    }
    setState(() {
      // Only accumulate motion in the dismiss direction; pulling the
      // drawer back open is clamped to 0 (the route's animation is
      // already at 1.0 / fully-open).
      _dragDelta = ((_dragDelta + delta) * dir).clamp(0, double.infinity) * dir;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final dismisses = CoreDrawerContract.dismissesOnRelease(
      // A stretched panel has covered no distance toward its edge.
      dragDistance: widget.rubberBand
          ? CoreDrawerRubberBand.dismissDistanceOf(_pull)
          : _dragDelta * _dismissDirection(),
      panelExtent: renderBox == null
          ? 0
          : (_isHorizontal() ? renderBox.size.width : renderBox.size.height),
      threshold: widget.dragDismissThreshold,
      // The recogniser's own reading of the release: logical px/s along the
      // drag axis, positive toward larger coordinates (down / right). The
      // rule wants it positive toward the edge the panel hides behind, which
      // is what `_dismissDirection` signs it to. A release the recogniser
      // does not call a fling reports 0 here, so only a real flick counts.
      velocity: (details.primaryVelocity ?? 0) * _dismissDirection(),
    );

    if (dismisses) {
      final scope = context.getInheritedWidgetOfExactType<_DrawerRouteScope>();
      unawaited(
        scope != null
            ? scope.navigator.maybePop()
            : Navigator.of(context, rootNavigator: true).maybePop(),
      );
    } else if (widget.rubberBand) {
      _settleBack();
    } else {
      // Snap back — clear the drag offset; the next paint puts the
      // drawer back at its docked position.
      setState(() => _dragDelta = 0);
    }
  }

  /// Returns the panel to its dock from wherever the finger left it, on the
  /// rubber band's curve — or at once when the user has asked for reduced
  /// motion, which the return is subject to as any transition is.
  void _settleBack() {
    final pose = CoreDrawerRubberBand.poseOf(_pull, extent: _extent);
    final duration = resolveMotionDuration(
      context,
      CoreDrawerRubberBand.defaultSettleDuration,
    );
    if (duration == Duration.zero || pose == CoreDrawerRubberBand.rest) {
      setState(() => _pull = 0);

      return;
    }
    setState(() {
      _pull = 0;
      _settling = true;
      _settleFrom = pose;
    });
    _settle.duration = duration;
    _settle.forward(from: 0);
  }

  /// The panel drawn at [pose]: slid toward the edge it hides behind, or
  /// scaled along its slide axis about the edge it is docked to — never both.
  Widget _buildPose(CoreDrawerPose pose, Widget child) {
    final isHorizontal = _isHorizontal();
    final Matrix4 matrix;
    if (pose.stretch > 0) {
      final scale = CoreDrawerRubberBand.scaleOf(pose.stretch, extent: _extent);
      matrix = isHorizontal
          ? Matrix4.diagonal3Values(scale, 1, 1)
          : Matrix4.diagonal3Values(1, scale, 1);
    } else {
      final offset = pose.slide * _dismissDirection();
      matrix = isHorizontal
          ? Matrix4.translationValues(offset, 0, 0)
          : Matrix4.translationValues(0, offset, 0);
    }

    return Transform(transform: matrix, alignment: _dock(), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = _isHorizontal();
    final Widget panel;
    if (widget.rubberBand) {
      panel = AnimatedBuilder(
        animation: _settle,
        builder: (context, child) => _buildPose(_poseNow(), child!),
        child: widget.child,
      );
    } else {
      final translation = isHorizontal
          ? Offset(_dragDelta, 0)
          : Offset(0, _dragDelta);
      panel = Transform.translate(offset: translation, child: widget.child);
    }

    return GestureDetector(
      onVerticalDragStart: isHorizontal || !widget.rubberBand
          ? null
          : _handleDragStart,
      onVerticalDragUpdate: isHorizontal ? null : _handleDragUpdate,
      onVerticalDragEnd: isHorizontal ? null : _handleDragEnd,
      onHorizontalDragStart: !isHorizontal || !widget.rubberBand
          ? null
          : _handleDragStart,
      onHorizontalDragUpdate: isHorizontal ? _handleDragUpdate : null,
      onHorizontalDragEnd: isHorizontal ? _handleDragEnd : null,
      behavior: .translucent,
      child: panel,
    );
  }
}
