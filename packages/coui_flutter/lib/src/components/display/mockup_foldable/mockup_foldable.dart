import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart'
    show PaintingContextCallback, RenderProxyBox;

/// Unified cross-platform folding-device mockup.
///
/// Draws a device that folds down its middle around the caller's screen
/// content. Open, the content is on the inner screen, which spans both
/// halves; shut, it is on the cover screen on the back of the half that folds
/// over. How far the device is folded is the one value [foldAngle] — `180` is
/// open, `0` is shut, and [CoreMockupFold.halfOpen] holds it like a book — and
/// a change moves the device to the new angle.
///
/// The body is not drawn here. Open it is a [MockupDevice] tablet on its
/// side and its cover is a [MockupDevice] phone, both styled through the
/// nested slots of the single [mockupFoldableStyle]. The component keeps the
/// open body's size at every angle; shut, the device stands in its middle.
///
/// What the device adds to its two faces is its status island: where a slab
/// phone has a status bar across the top of its screen, this device keeps a
/// column at the screen's right edge — the cover's camera at its top
/// ([showCamera]), the clock and the status indicator under it
/// ([showStatus]). The content is laid out clear of that column, as it is
/// clear of the gesture bar ([showGestureBar]).
///
/// The content keeps its state when it moves between the two screens. On the
/// inner screen it reads the fold through `FoldScope.of(context)` — one fold
/// down the middle, flat or half opened.
///
/// While the inner screen is bent, at any angle short of flat, its content is
/// drawn from a picture of itself: it takes no input and no focus, and
/// assistive technology does not read it. The picture is taken again
/// whenever the content repaints. A repaint behind a repaint boundary of the
/// content's own — inside a scroll view, say — is not heard of here; such
/// content is caught up with when the device comes to rest and when this
/// widget is rebuilt.
///
/// Example:
/// ```dart
/// MockupFoldable(
///   foldAngle: CoreMockupFold.halfOpen,
///   child: Image.asset('screenshot.png'),
/// )
/// ```
class MockupFoldable extends StatefulWidget
    implements CoreMockupFoldableContract<Widget> {
  /// Creates a [MockupFoldable].
  const MockupFoldable({
    required this.child,
    super.key,
    this.foldAngle = CoreMockupFoldableContract.defaultFoldAngle,
    this.width,
    this.showCamera = CoreMockupFoldableContract.defaultShowCamera,
    this.showStatus = CoreMockupFoldableContract.defaultShowStatus,
    this.showGestureBar = CoreMockupFoldableContract.defaultShowGestureBar,
    this.screenBrightness,
    this.mockupFoldableStyle,
  });

  @override
  final Widget child;

  @override
  final double foldAngle;

  @override
  final double? width;

  @override
  final bool showCamera;

  @override
  final bool showStatus;

  @override
  final bool showGestureBar;

  @override
  final CoreBrightness? screenBrightness;

  @override
  final CoreMockupFoldableStyle? mockupFoldableStyle;

  /// Returns a copy of this [MockupFoldable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MockupFoldable copyWith({
    Key? key,
    double? foldAngle,
    double? width,
    bool? showCamera,
    bool? showStatus,
    bool? showGestureBar,
    CoreBrightness? screenBrightness,
    CoreMockupFoldableStyle? mockupFoldableStyle,
    Widget? child,
  }) {
    return MockupFoldable(
      key: key ?? this.key,
      foldAngle: foldAngle ?? this.foldAngle,
      width: width ?? this.width,
      showCamera: showCamera ?? this.showCamera,
      showStatus: showStatus ?? this.showStatus,
      showGestureBar: showGestureBar ?? this.showGestureBar,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      mockupFoldableStyle: mockupFoldableStyle ?? this.mockupFoldableStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<MockupFoldable> createState() => _MockupFoldableState();
}

class _MockupFoldableState extends State<MockupFoldable>
    with SingleTickerProviderStateMixin {
  /// Carries the content from one screen to the other with its state.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'MockupFoldable content');

  /// Holds the picture the bent inner screen is drawn from.
  final SnapshotController _snapshot = SnapshotController();

  /// Runs one move, 0 to 1, between [_from] and [_to].
  late final AnimationController _controller;

  late double _from;
  late double _to;
  Curve _curve = Curves.linear;

  /// The screen the content is on, and what it is told about the fold —
  /// the two things the angle decides that the faces are rebuilt for.
  late CoreMockupFoldScreen _activeScreen;
  late CoreFoldState _foldState;

  /// The angle the device is drawn at right now.
  double get _angle => CoreMockupFold.clampAngle(
    _from + (_to - _from) * _curve.transform(_controller.value),
  );

  bool get _isBent => !CoreMockupFold.innerIsFlat(_angle);

  /// Semantic layout knob — the widget supplies the design-system
  /// `CoreMockupFoldableStyle.defaultWidth` fallback so the resolvers consume
  /// an already resolved value (the theme cannot override `width`). Single
  /// source of truth shared with the Web resolver.
  double get _width => widget.width ?? CoreMockupFoldableStyle.defaultWidth;

  ResolvedMockupFoldable _resolve() => resolveMockupFoldable(
    context,
    widgetWidth: _width,
    mockupFoldableStyle: widget.mockupFoldableStyle,
  );

  @override
  void initState() {
    super.initState();
    final angle = CoreMockupFold.clampAngle(widget.foldAngle);
    _from = angle;
    _to = angle;
    _activeScreen = CoreMockupFold.activeScreen(angle);
    _foldState = CoreMockupFold.foldState(angle);
    _snapshot.allowSnapshotting = !CoreMockupFold.innerIsFlat(angle);
    _controller = AnimationController(vsync: this, value: 1)
      ..addListener(_handleTick)
      ..addStatusListener(_handleStatus);
  }

  /// Follows the angle: which screen is live, whether the inner screen is
  /// drawn from a picture, and — when the content changes screen — a fresh
  /// picture, since the old one shows a screen the content has left or not
  /// yet reached.
  void _sync() {
    final angle = _angle;
    final screen = CoreMockupFold.activeScreen(angle);
    final state = CoreMockupFold.foldState(angle);
    _snapshot.allowSnapshotting = !CoreMockupFold.innerIsFlat(angle);
    if (screen == _activeScreen && state == _foldState) return;

    final moved = screen != _activeScreen;
    setState(() {
      _activeScreen = screen;
      _foldState = state;
    });
    if (moved) _snapshot.clear();
  }

  void _handleTick() => _sync();

  /// The device has come to rest. A bent screen is drawn again from how its
  /// content looks now: a change that asked for no repaint of its own on the
  /// way — one behind a repaint boundary — is caught up with here.
  void _handleStatus(AnimationStatus status) {
    if (status != .completed) return;

    _from = _to;
    _sync();
    if (_isBent) _snapshot.clear();
  }

  /// Something in the open body asked to be painted again, so a picture of
  /// it is out of date: an image that finished loading, a label rewritten.
  void _handleRepaint() {
    if (mounted && _snapshot.allowSnapshotting) _snapshot.clear();
  }

  void _moveTo(double target) {
    final resolved = _resolve();
    // Read where the device is before the move is redefined.
    final shown = _angle;
    if (resolved.duration == Duration.zero) {
      // No move: the device is at the angle at once. The picture is not of
      // the angle, so a caller stepping the angle itself — a slider — does
      // not have it taken again at every step.
      _controller.stop();
      _from = target;
      _to = target;
      _sync();

      return;
    }

    _from = shown;
    _to = target;
    _curve = resolved.curve;
    _controller.duration = resolved.duration;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(MockupFoldable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = CoreMockupFold.clampAngle(widget.foldAngle);
    if (target != _to) {
      _moveTo(target);
    } else if (_isBent) {
      // Rebuilt for something other than the angle: a picture of the open
      // body is of the old build. What repaints says so itself; this also
      // reaches what repaints behind a repaint boundary, which says so to
      // nobody above it.
      _snapshot.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isBent) _snapshot.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    final onCover = _activeScreen == CoreMockupFoldScreen.cover;
    final content = KeyedSubtree(key: _contentKey, child: widget.child);

    // Both faces are built here, outside the animation, so a move redraws
    // where they stand without rebuilding what they are.
    //
    // Neither face draws a camera or a status bar of its own: this device's
    // are its status island, which each screen draws over its content
    // (`_Screen`) whether or not the content is on it.
    final innerFace = MockupDevice(
      device: CoreMockupFoldableLayout.innerDevice,
      orientation: CoreMockupFoldableLayout.innerOrientation,
      width: resolved.innerDeviceWidth,
      showCamera: false,
      showStatusBar: false,
      showGestureBar: widget.showGestureBar,
      screenBrightness: widget.screenBrightness,
      mockupDeviceStyle: resolved.innerDeviceStyle,
      child: _Screen(
        screen: CoreMockupFoldScreen.inner,
        foldState: _foldState,
        widgetWidth: _width,
        showCamera: widget.showCamera,
        showStatus: widget.showStatus,
        mockupFoldableStyle: widget.mockupFoldableStyle,
        child: onCover ? const SizedBox.shrink() : content,
      ),
    );
    final coverFace = MockupDevice(
      // Stated rather than left to the defaults they happen to equal: which
      // device the cover is, and how it is held, is the shared layout's
      // statement (`CoreMockupFoldableLayout`), the one the Web twin reads.
      // ignore: avoid_redundant_argument_values
      device: CoreMockupFoldableLayout.coverDevice,
      // The same statement, for the way the cover is held.
      // ignore: avoid_redundant_argument_values
      orientation: CoreMockupFoldableLayout.coverOrientation,
      width: resolved.coverDeviceWidth,
      showCamera: false,
      showStatusBar: false,
      showGestureBar: widget.showGestureBar,
      screenBrightness: widget.screenBrightness,
      mockupDeviceStyle: resolved.coverDeviceStyle,
      child: _Screen(
        screen: CoreMockupFoldScreen.cover,
        widgetWidth: _width,
        showCamera: widget.showCamera,
        showStatus: widget.showStatus,
        mockupFoldableStyle: widget.mockupFoldableStyle,
        child: onCover ? content : const SizedBox.shrink(),
      ),
    );

    final stage = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _stage(
        resolved,
        CoreMockupFoldPose.compute(
          angle: _angle,
          width: resolved.width,
          height: resolved.height,
          thickness: resolved.thickness,
          perspective: resolved.perspective,
        ),
        innerFace: innerFace,
        coverFace: coverFace,
      ),
    );
    final view = View.maybeOf(context);

    return Align(
      alignment: Alignment.topCenter,
      // The stage — the open body's box, whatever the angle.
      child: SizedBox(
        width: resolved.width,
        height: resolved.height,
        // A picture is taken at the view's pixel ratio, which is read from a
        // `MediaQuery`. A `MockupDevice` draws without one above it, so this
        // does too.
        child: MediaQuery.maybeDevicePixelRatioOf(context) != null
            ? stage
            : MediaQuery(
                data: view == null
                    ? const MediaQueryData()
                    : MediaQueryData.fromView(view),
                child: stage,
              ),
      ),
    );
  }

  /// The parts at [pose], back to front. The order holds at every angle: the
  /// only parts that ever overlap are the cover and what lies under it. Both
  /// halves of the open body are one painter's work, so the right slab's edge
  /// is painted after the left half rather than before it — two parts that
  /// never meet.
  Widget _stage(
    ResolvedMockupFoldable resolved,
    CoreMockupFoldPose pose, {
    required Widget innerFace,
    required Widget coverFace,
  }) {
    final overflow = resolved.innerOverflow;
    final coverShade = pose.cover.shade * resolved.shadeOpacity;

    return Stacks(
      // A half turned towards the viewer is drawn larger than the stage.
      clipBehavior: .none,
      children: [
        // The open body. Flat, it is painted as it is; bent, both halves are
        // painted from one picture of it, so the picture's box takes in what
        // the body paints outside its own.
        Position(
          key: const ValueKey('inner'),
          top: -overflow.top,
          left: -overflow.left,
          width: resolved.width + overflow.horizontal,
          height: resolved.height + overflow.vertical,
          child: IgnorePointer(
            ignoring: !pose.isFlat,
            child: ExcludeFocus(
              excluding: !pose.isFlat,
              // Bent, the body under the picture is still laid out flat, so
              // what it would tell assistive technology is where nothing is
              // painted. The Web twin hides its bent screen for the reason
              // it has (a subtree cannot be left readable and unfocusable
              // there), and the two say the same: the content is exposed on
              // a flat inner screen and on the cover, and not in between.
              child: ExcludeSemantics(
                excluding: !pose.isFlat,
                child: SnapshotWidget(
                  controller: _snapshot,
                  // A platform view under the screen is left out of the
                  // picture rather than stopping it from being taken.
                  mode: .forced,
                  painter: _InnerFacePainter(pose: pose, resolved: resolved),
                  autoresize: true,
                  child: _RepaintListener(
                    onRepaint: _handleRepaint,
                    child: Padding(padding: overflow, child: innerFace),
                  ),
                ),
              ),
            ),
          ),
        ),
        // How each edge ends is the shared rule's (`CoreMockupFoldEdgeCut`),
        // read with the corners the two faces are drawn with here.
        if (pose.edgeRight.visible)
          _edge(
            const ValueKey('edgeRight'),
            resolved,
            pose.edgeRight,
            pose.rightEdgeCut(
              top: _cornerOf(resolved.innerBorderRadius.topRight),
              bottom: _cornerOf(resolved.innerBorderRadius.bottomRight),
            ),
          ),
        if (pose.edgeLeft.visible)
          _edge(
            const ValueKey('edgeLeft'),
            resolved,
            pose.edgeLeft,
            pose.leftEdgeCut(
              innerTop: _cornerOf(resolved.innerBorderRadius.topLeft),
              innerBottom: _cornerOf(resolved.innerBorderRadius.bottomLeft),
              coverTop: _cornerOf(resolved.coverBorderRadius.topRight),
              coverBottom: _cornerOf(resolved.coverBorderRadius.bottomRight),
            ),
          ),
        if (pose.cover.visible)
          Position(
            key: const ValueKey('cover'),
            top: 0,
            left: 0,
            width: resolved.coverWidth,
            height: resolved.height,
            child: Transform(
              transform: Matrix4.fromList(pose.cover.matrix),
              child: Stacks(
                clipBehavior: .none,
                children: [
                  coverFace,
                  if (pose.coverScreenDim > 0)
                    _veil(
                      resolved.coverScreenRect,
                      resolved.coverScreenBorderRadius,
                      _faded(resolved.screenOffColor, pose.coverScreenDim),
                    ),
                  if (coverShade > 0)
                    _veil(
                      Offset.zero & Size(resolved.coverWidth, resolved.height),
                      resolved.coverBorderRadius,
                      // The shade's strength rides its own colour: the veil
                      // holds nothing else to dim.
                      resolved.shadeColor.withValues(
                        alpha: resolved.shadeColor.a * coverShade,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// A slab's outer edge: a strip as wide as the slab is deep, in the box
  /// and under the matrix the pose states for it, ending as [cut] says.
  static Widget _edge(
    Key key,
    ResolvedMockupFoldable resolved,
    CoreMockupFoldPart part,
    CoreMockupFoldEdgeCut cut,
  ) => Position(
    key: key,
    top: 0,
    left: 0,
    width: resolved.thickness,
    height: resolved.height,
    child: Transform(
      transform: Matrix4.fromList(part.matrix),
      child: CustomPaint(
        painter: _EdgePainter(
          color: resolved.edgeColor,
          outlineAtEnd: cut.outlineAtEnd,
          ends: (
            top: Radius.elliptical(cut.top.x, cut.top.y),
            bottom: Radius.elliptical(cut.bottom.x, cut.bottom.y),
          ),
        ),
      ),
    ),
  );

  /// A colour laid over [rect] that lets input through to what is under it.
  static Widget _veil(Rect rect, BorderRadius borderRadius, Color color) =>
      Position(
        top: rect.top,
        left: rect.left,
        width: rect.width,
        height: rect.height,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: borderRadius),
          ),
        ),
      );
}

/// How the outline side of a slab's edge is rounded at its two ends.
typedef _EdgeEnds = ({Radius top, Radius bottom});

/// A drawn corner as the shared fold rules read one.
CoreMockupFoldCorner _cornerOf(Radius radius) => (x: radius.x, y: radius.y);

/// [color] at [share] of its own opacity.
Color _faded(Color color, double share) =>
    color.withValues(alpha: color.a * share);

/// What this device puts on a face's screen, inside the face's `MockupDevice`:
/// the content — clear of the status island, and told what the device's fold
/// is — and the island over it.
///
/// Sits inside the device's own `MediaQuery`, so the screen it measures is
/// the mockup's.
///
/// - **The fold.** On the inner screen one fold down its middle at
///   [foldState]; on the cover (a null [foldState]) none. It replaces
///   whatever folds the host device reports — they are folds of the page, not
///   of this screen.
/// - **The island.** The column at the screen's right edge is stated as the
///   screen's padding and consumed by a `SafeArea`, the way `MockupDevice`
///   keeps its child clear of its own bars — so content with a `SafeArea` of
///   its own does not keep clear of it twice. The island is resolved here,
///   from this screen's context: the screen may run in a brightness of its
///   own, and the island is drawn in the screen's colours.
///
/// The island is a picture of an operating system caught at one moment — it
/// carries no information of its own — so, like the device's status bar, it
/// takes no input, stays out of the semantics tree, keeps a fixed
/// left-to-right layout, and its clock does not follow the host's text scale.
class _Screen extends StatelessWidget {
  const _Screen({
    required this.screen,
    required this.widgetWidth,
    required this.showCamera,
    required this.showStatus,
    required this.child,
    this.foldState,
    this.mockupFoldableStyle,
  });

  final CoreMockupFoldScreen screen;
  final CoreFoldState? foldState;
  final double widgetWidth;
  final bool showCamera;
  final bool showStatus;
  final CoreMockupFoldableStyle? mockupFoldableStyle;
  final Widget child;

  /// A part of the island in its box.
  static Widget _part(Key key, Rect rect, Widget child) => Position(
    key: key,
    top: rect.top,
    left: rect.left,
    width: rect.width,
    height: rect.height,
    child: child,
  );

  static Widget _island(ResolvedMockupFoldableIsland island) {
    final cameraRect = island.cameraRect;
    final clockRect = island.clockRect;
    final indicatorRect = island.indicatorRect;
    final ringPath = island.ringPath;
    final dotsPath = island.dotsPath;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: .ltr,
          child: Stacks(
            children: [
              if (cameraRect != null)
                _part(
                  const ValueKey('islandCamera'),
                  cameraRect,
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: island.cameraColor,
                      shape: .circle,
                    ),
                  ),
                ),
              if (clockRect != null)
                _part(
                  const ValueKey('islandClock'),
                  clockRect,
                  // The words are centred on the box whatever size they
                  // come out at: one line, never wrapped and never cut.
                  OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Text(
                      island.clockText,
                      style: island.clockTextStyle,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: .noScaling,
                    ),
                  ),
                ),
              if (indicatorRect != null && ringPath != null && dotsPath != null)
                _part(
                  const ValueKey('islandIndicator'),
                  indicatorRect,
                  CustomPaint(
                    painter: _IndicatorPainter(
                      ringPath: ringPath,
                      ringColor: island.ringColor,
                      dotsPath: dotsPath,
                      dotsColor: island.dotsColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final island = resolveMockupFoldableIsland(
      context,
      screen: screen,
      widgetWidth: widgetWidth,
      showCamera: showCamera,
      showStatus: showStatus,
      mockupFoldableStyle: mockupFoldableStyle,
    );
    final media = MediaQuery.of(context);
    final foldState = this.foldState;
    final padding = island?.contentPadding ?? EdgeInsets.zero;

    return MediaQuery(
      data: media.copyWith(
        padding: padding,
        viewPadding: padding,
        displayFeatures: [
          if (foldState != null)
            ui.DisplayFeature(
              // A screen that bends: a line with no width, the whole height.
              bounds: Rect.fromLTWH(
                media.size.width / 2,
                0,
                0,
                media.size.height,
              ),
              type: ui.DisplayFeatureType.fold,
              state: switch (foldState) {
                .flat => ui.DisplayFeatureState.postureFlat,
                .halfOpened => ui.DisplayFeatureState.postureHalfOpened,
                .unknown => ui.DisplayFeatureState.unknown,
              },
            ),
        ],
      ),
      child: Stacks(
        children: [
          Position.fill(child: SafeArea(child: child)),
          if (island != null) Position.fill(child: _island(island)),
        ],
      ),
    );
  }
}

/// Says so whenever something under it asks to be painted again.
///
/// A picture does not notice that what it is of has changed. Every change
/// that needs paint walks up the render tree as a repaint request, and this
/// box stands in its way and passes the word on. A request stops at the first
/// repaint boundary it meets, so one made behind a boundary of its own — in a
/// scroll view — does not come this far.
class _RepaintListener extends SingleChildRenderObjectWidget {
  const _RepaintListener({required this.onRepaint, super.child});

  final VoidCallback onRepaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRepaintListener(onRepaint);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRepaintListener renderObject,
  ) => renderObject.onRepaint = onRepaint;
}

class _RenderRepaintListener extends RenderProxyBox {
  _RenderRepaintListener(this.onRepaint);

  VoidCallback onRepaint;

  @override
  void markNeedsPaint() {
    onRepaint();
    super.markNeedsPaint();
  }
}

/// Paints the open body: as it is while it lies flat, and as two halves of
/// one picture — each under its own matrix — while it is bent.
class _InnerFacePainter extends SnapshotPainter {
  _InnerFacePainter({required this.pose, required this.resolved});

  final CoreMockupFoldPose pose;
  final ResolvedMockupFoldable resolved;

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) => painter(context, offset);

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final overflow = resolved.innerOverflow;
    // The picture's box in the stage's space, whose origin is the body's
    // top-left corner.
    final picture = Offset(-overflow.left, -overflow.top) & size;
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx + overflow.left, offset.dy + overflow.top);
    _paintHalf(
      canvas,
      image,
      sourceSize,
      picture,
      pose.innerRight,
      Rect.fromLTRB(
        resolved.hingeX,
        picture.top,
        picture.right,
        picture.bottom,
      ),
    );
    _paintHalf(
      canvas,
      image,
      sourceSize,
      picture,
      pose.innerLeft,
      Rect.fromLTRB(picture.left, picture.top, resolved.hingeX, picture.bottom),
    );
    canvas.restore();
  }

  void _paintHalf(
    Canvas canvas,
    ui.Image image,
    Size sourceSize,
    Rect picture,
    CoreMockupFoldPart part,
    Rect half,
  ) {
    if (!part.visible) return;

    final shade = part.shade * resolved.shadeOpacity;
    canvas
      ..save()
      ..transform(Float64List.fromList(part.matrix))
      // Not anti-aliased: the two halves meet on the hinge, and a soft edge
      // on each would let the page show through the seam.
      ..clipRect(half, doAntiAlias: false)
      ..drawImageRect(
        image,
        Offset.zero & sourceSize,
        picture,
        Paint()..filterQuality = .medium,
      );
    if (pose.innerScreenDim > 0) {
      canvas.drawRRect(
        resolved.innerScreenBorderRadius.toRRect(resolved.innerScreenRect),
        Paint()..color = _faded(resolved.screenOffColor, pose.innerScreenDim),
      );
    }
    if (shade > 0) {
      canvas.drawRRect(
        resolved.innerBorderRadius.toRRect(
          Offset.zero & Size(resolved.width, resolved.height),
        ),
        Paint()
          ..color = resolved.shadeColor.withValues(
            alpha: resolved.shadeColor.a * shade,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InnerFacePainter oldPainter) =>
      oldPainter.pose != pose || !identical(oldPainter.resolved, resolved);
}

/// Fills the status indicator's two drawings — the ring with the glyph inside
/// it, then the dots that close the ring — each in its own colour. Both paths
/// are already sized to the box.
class _IndicatorPainter extends CustomPainter {
  const _IndicatorPainter({
    required this.ringPath,
    required this.ringColor,
    required this.dotsPath,
    required this.dotsColor,
  });

  final Path ringPath;
  final Color ringColor;
  final Path dotsPath;
  final Color dotsColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(ringPath, Paint()..color = ringColor)
      ..drawPath(dotsPath, Paint()..color = dotsColor);
  }

  @override
  bool shouldRepaint(_IndicatorPainter oldDelegate) =>
      oldDelegate.ringPath != ringPath ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.dotsPath != dotsPath ||
      oldDelegate.dotsColor != dotsColor;
}

/// Paints a slab's edge: its strip, cut at both ends by the corners of the
/// face behind it (`CoreMockupFoldEdgeCut`).
class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.color,
    required this.outlineAtEnd,
    required this.ends,
  });

  final Color color;

  /// Whether the device's outline is the side the box ends on, or the side
  /// it starts on.
  final bool outlineAtEnd;

  final _EdgeEnds ends;

  @override
  void paint(Canvas canvas, Size size) {
    // A corner is as wide as the face draws it, which can be many times the
    // strip. The shape is the strip's box reaching as far towards the face
    // as its corners take, and the strip is what shows of it.
    final reach = math.max(size.width, math.max(ends.top.x, ends.bottom.x));
    final shape = outlineAtEnd
        ? RRect.fromLTRBAndCorners(
            size.width - reach,
            0,
            size.width,
            size.height,
            topRight: ends.top,
            bottomRight: ends.bottom,
          )
        : RRect.fromLTRBAndCorners(
            0,
            0,
            reach,
            size.height,
            topLeft: ends.top,
            bottomLeft: ends.bottom,
          );
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRRect(shape, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.outlineAtEnd != outlineAtEnd ||
      oldDelegate.ends != ends;
}

/// Chain sugar for merging a [CoreMockupFoldableStyle] patch into
/// [MockupFoldable.mockupFoldableStyle] without hand-reconstructing every
/// field. Mirrors the Web `MockupFoldable.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMockupFoldableStyle.merge` right-side-wins semantics).
///
/// ```dart
/// MockupFoldable(child: screenshot).withStyle(
///   const CoreMockupFoldableStyle(duration: Duration.zero),
/// )
/// ```
extension MockupFoldableStyleChain on MockupFoldable {
  /// Returns a copy of this [MockupFoldable] with [patch] merged into
  /// [MockupFoldable.mockupFoldableStyle] (patch fields win on conflict).
  MockupFoldable withStyle(CoreMockupFoldableStyle patch) => copyWith(
    mockupFoldableStyle:
        (mockupFoldableStyle ?? const CoreMockupFoldableStyle()).merge(patch),
  );
}
