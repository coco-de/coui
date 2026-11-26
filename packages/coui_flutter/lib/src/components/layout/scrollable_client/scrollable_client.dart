import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey;

/// Platform-specific builder alias.
typedef ScrollableBuilder = CoreScrollableBuilder<Widget, Offset, Size>;

/// Unified 2D scrollable viewport that rebuilds a [builder] on every scroll
/// frame with the current offset and viewport size.
///
/// Implements the cross-platform [CoreScrollableClientContract] so
/// Web/Flutter callers can share code.
class ScrollableClient extends StatefulWidget
    implements CoreScrollableClientContract<Widget, Offset, Size, Clip> {
  /// Creates a [ScrollableClient].
  const ScrollableClient({
    required this.builder,
    super.key,
    this.child,
    this.mainAxis = CoreAxis.vertical,
    this.diagonalDragBehavior,
    this.overscroll,
    this.clipBehavior,
    this.verticalDetails = const CoreScrollableDetails.vertical(),
    this.horizontalDetails = const CoreScrollableDetails.horizontal(),
    this.hitTestBehavior,
    this.keyboardDismissBehavior,
    this.showScrollbar,
    this.semanticLabel,
    this.flutterVerticalDetails,
    this.flutterHorizontalDetails,
    this.primary,
    this.dragStartBehavior,
  });

  @override
  final ScrollableBuilder builder;

  @override
  final Widget? child;

  @override
  final CoreAxis mainAxis;

  @override
  final CoreDiagonalDragBehavior? diagonalDragBehavior;

  @override
  final bool? overscroll;

  @override
  final Clip? clipBehavior;

  @override
  final CoreScrollableDetails verticalDetails;

  @override
  final CoreScrollableDetails horizontalDetails;

  @override
  final CoreHitTestBehavior? hitTestBehavior;

  @override
  final CoreKeyboardDismissBehavior? keyboardDismissBehavior;

  @override
  final bool? showScrollbar;

  @override
  final String? semanticLabel;

  /// Flutter-only: per-axis scrollable details (controllers, physics, etc.).
  /// When non-null takes precedence over [verticalDetails] for Flutter-only
  /// knobs, while direction and initialOffset still come from [verticalDetails].
  final ScrollableDetails? flutterVerticalDetails;

  /// Flutter-only: per-axis scrollable details (horizontal counterpart of
  /// [flutterVerticalDetails]).
  final ScrollableDetails? flutterHorizontalDetails;

  /// Flutter-only: inherit the [PrimaryScrollController] for [mainAxis].
  final bool? primary;

  /// Flutter-only: drag start behaviour.
  final DragStartBehavior? dragStartBehavior;

  @override
  State<ScrollableClient> createState() => _ScrollableClientState();
}

class _ScrollableClientState extends State<ScrollableClient> {
  /// The DOM `KeyboardEvent.key` name for [key], or `null` when this key
  /// has no part in the scroll map.
  ///
  /// The one thing the two platforms cannot share: Flutter names keys
  /// with [LogicalKeyboardKey] and the browser names them with strings.
  /// Everything downstream of this switch — which axis, how far — comes
  /// from `resolveScrollableKeyIntent`, so the map itself cannot drift.
  static String? _domKeyName(LogicalKeyboardKey key) {
    if (key == .arrowDown) return 'ArrowDown';
    if (key == .arrowUp) return 'ArrowUp';
    if (key == .arrowRight) return 'ArrowRight';
    if (key == .arrowLeft) return 'ArrowLeft';
    if (key == .pageDown) return 'PageDown';
    if (key == .pageUp) return 'PageUp';
    if (key == .home) return 'Home';
    if (key == .end) return 'End';

    return null;
  }

  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;
  bool _initialOffsetApplied = false;
  // The live viewport size, published by the render object after a resize so
  // the builder re-runs with the current size. The ChildVicinity identity is
  // deliberately kept constant across layouts (see [layoutChildSequence]):
  // encoding the size into it minted a fresh child on every resize and orphaned
  // the previous one, whose paint extent/offset is never computed — so
  // isVisible / applyPaintTransform threw on paint and hitTest and the viewport
  // rendered blank. See #2136.
  final ValueNotifier<Size> _viewportSize = ValueNotifier(Size.zero);

  /// Keyboard entry point for the viewport.
  ///
  /// The viewport is a scroll surface with no focusable chrome of its
  /// own, so without a node of its own there is nothing for a keyboard
  /// user to land on and nothing to route arrow keys to — the Web twin's
  /// `tabindex="0"` says the same thing in that platform's vocabulary.
  late final FocusNode _focusNode;

  /// Whether the focus *highlight* is showing.
  ///
  /// Tracks `onShowFocusHighlight` rather than plain focus so a pointer
  /// press does not paint a ring — the Flutter equivalent of the Web
  /// side's `:focus-visible`, which is the pseudo the scoped ring rule
  /// is keyed on.
  bool _focused = false;

  Axis get _flutterMainAxis =>
      widget.mainAxis == .horizontal ? .horizontal : .vertical;

  @override
  void initState() {
    super.initState();
    _horizontalController =
        widget.flutterHorizontalDetails?.controller ?? ScrollController();
    _verticalController =
        widget.flutterVerticalDetails?.controller ?? ScrollController();
    _focusNode = FocusNode(
      debugLabel: 'ScrollableClient',
      onKeyEvent: _handleKeyEvent,
    );
  }

  /// Whether the main axis is driven by an inherited
  /// [PrimaryScrollController] rather than this state's own controller.
  ///
  /// Read by both `build` and the key handler so the two never disagree
  /// about which controller actually owns the axis.
  bool get _effectivePrimary =>
      widget.primary ??
      (widget.flutterVerticalDetails?.controller == null &&
          widget.flutterHorizontalDetails?.controller == null &&
          PrimaryScrollController.shouldInherit(context, _flutterMainAxis));

  /// The controller that actually drives [axis].
  ///
  /// Not always this state's own field: when the main axis inherits the
  /// [PrimaryScrollController], that controller is the one attached to a
  /// position, and the local fallback has no clients at all. A key
  /// handler reading the local field in that case would scroll nothing
  /// and report success.
  ScrollController _controllerFor(Axis axis) {
    final fallback = axis == .vertical
        ? _verticalController
        : _horizontalController;
    if (axis != _flutterMainAxis || !_effectivePrimary) return fallback;
    return PrimaryScrollController.maybeOf(context) ?? fallback;
  }

  /// Scrolls [axis] by [delta], clamped to the axis' own extents.
  ///
  /// Returns `ignored` when the axis cannot move any further so the key
  /// falls through to the enclosing scrollable — the same chaining a
  /// browser performs at the edge of an `overflow: auto` box, which is
  /// what the Web twin gets by *not* calling `preventDefault` there.
  KeyEventResult _scrollAxisBy(Axis axis, double delta) {
    final controller = _controllerFor(axis);
    if (!controller.hasClients || controller.positions.length != 1) {
      return .ignored;
    }
    final position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) return .ignored;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return .ignored;
    controller.jumpTo(target);

    return .handled;
  }

  /// Scrolls [axis] to one of its extents.
  KeyEventResult _scrollAxisTo(Axis axis, {required bool toEnd}) {
    final controller = _controllerFor(axis);
    if (!controller.hasClients || controller.positions.length != 1) {
      return .ignored;
    }
    final position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) return .ignored;
    final target = toEnd ? position.maxScrollExtent : position.minScrollExtent;
    if (target == position.pixels) return .ignored;
    controller.jumpTo(target);

    return .handled;
  }

  /// Keyboard scrolling — the Flutter half of the cross-platform key map.
  ///
  /// Flutter's own `ScrollAction` cannot serve this widget: it resolves
  /// the *nearest* `Scrollable`, which inside a `TwoDimensionalScrollable`
  /// is always the inner horizontal one, and then returns a zero
  /// increment for any intent on the other axis. Vertical arrow keys
  /// would move nothing, so both axes are routed explicitly here.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Repeats count: holding an arrow down has to keep scrolling, and a
    // held key arrives as its own event type, not as a second down.
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return .ignored;
    // Only when the viewport itself holds focus. Flutter walks a key up
    // the focused node's ancestors, and this node sits *below* the
    // app-level text-editing shortcuts — so without this guard a
    // `TextField` inside the content loses Home/End and the arrows to
    // the viewport, which scrolls instead of moving the caret. (`Table`
    // composes this widget, so that is not a hypothetical arrangement.)
    // The Web twin states the same rule as "the event targeted the
    // viewport, not something inside it".
    if (!node.hasPrimaryFocus) return .ignored;
    // Modified combinations belong to the platform, not to this
    // viewport — the Web twin says the same about Alt+Arrow and
    // Ctrl/Cmd+Home.
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed) {
      return .ignored;
    }

    final name = _domKeyName(event.logicalKey);
    if (name == null) return .ignored;

    final intent = resolveScrollableKeyIntent(
      name,
      viewportHeight: _viewportSize.value.height,
    );

    return switch (intent.action) {
      .none => .ignored,
      .jumpToStart => _scrollAxisTo(.vertical, toEnd: false),
      .jumpToEnd => _scrollAxisTo(.vertical, toEnd: true),
      .moveBy =>
        intent.dx != 0
            ? _scrollAxisBy(.horizontal, intent.dx)
            : _scrollAxisBy(.vertical, intent.dy),
    };
  }

  /// Takes focus when the viewport is pressed.
  ///
  /// Only when it does not already have it — re-requesting on every press
  /// would restart the traversal bookkeeping for no gain. The ring stays
  /// hidden regardless: `onShowFocusHighlight` reports the *highlight*,
  /// which pointer-initiated focus does not turn on.
  void handlePointerDown(PointerDownEvent event) {
    if (_focusNode.hasFocus) return;
    _focusNode.requestFocus();
  }

  void handleShowFocusHighlight(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  // Called from the render object's layoutChildSequence when the viewport size
  // changes. Defers the notifier mutation to after the frame because mutating
  // it synchronously would rebuild the builder subtree mid-layout.
  void _handleViewportResized(Size size) {
    if (_viewportSize.value == size) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewportSize.value = size;
    });
  }

  AxisDirection _toFlutterAxisDirection(CoreAxisDirection dir) {
    return switch (dir) {
      .up => .up,
      .right => .right,
      .down => .down,
      .left => .left,
    };
  }

  DiagonalDragBehavior _resolveDiagonal(CoreDiagonalDragBehavior core) {
    return switch (core) {
      .none => .none,
      .weightedEvent => .weightedEvent,
      .weightedContinuous => .weightedContinuous,
      .free => .free,
    };
  }

  HitTestBehavior _resolveHitTest(CoreHitTestBehavior core) {
    return switch (core) {
      .deferToChild => .deferToChild,
      .opaque => .opaque,
      .translucent => .translucent,
    };
  }

  ScrollViewKeyboardDismissBehavior _resolveKeyboardDismiss(
    CoreKeyboardDismissBehavior core,
  ) {
    return switch (core) {
      .onDrag => .onDrag,
      .manual => .manual,
    };
  }

  ScrollableDetails _flutterDetailsFor({
    required CoreScrollableDetails core,
    required ScrollableDetails? flutterOverride,
    required ScrollController controller,
  }) {
    final direction = _toFlutterAxisDirection(core.direction);
    if (flutterOverride == null) {
      return ScrollableDetails(
        direction: direction,
        controller: controller,
      );
    }
    return flutterOverride.copyWith(
      direction: direction,
      controller: flutterOverride.controller ?? controller,
    );
  }

  /// Builds the viewport child delegate. The delegate is a lightweight
  /// config object recreated per build and handed off to the viewport
  /// render object, which owns its listener lifecycle.
  TwoDimensionalChildBuilderDelegate _buildChildDelegate(
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return TwoDimensionalChildBuilderDelegate(
      builder: (context, vicinity) {
        // The size captured when this child was first built — correct on the
        // first frame, before the post-layout notifier has been seeded.
        final builtSize =
            (vicinity as _ScrollableClientChildVicinity).viewportSize;
        return ListenableBuilder(
          listenable: Listenable.merge([
            verticalOffset,
            horizontalOffset,
            _viewportSize,
          ]),
          builder: (context, inherited) {
            // Prefer the live size published after a resize; fall back to the
            // build-time size until the notifier is first seeded so the very
            // first frame never reports a zero viewport.
            final size = _viewportSize.value == .zero
                ? builtSize
                : _viewportSize.value;
            return widget.builder(
              context,
              Offset(horizontalOffset.pixels, verticalOffset.pixels),
              size,
              inherited,
            );
          },
          child: widget.child,
        );
      },
    );
  }

  Widget _buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
    bool overscroll,
    Clip clipBehavior,
  ) {
    return _ScrollableClientViewport(
      delegate: _buildChildDelegate(verticalOffset, horizontalOffset),
      onViewportResized: _handleViewportResized,
      horizontalAxisDirection: _toFlutterAxisDirection(
        widget.horizontalDetails.direction,
      ),
      horizontalOffset: horizontalOffset,
      mainAxis: _flutterMainAxis,
      overscroll: overscroll,
      verticalAxisDirection: _toFlutterAxisDirection(
        widget.verticalDetails.direction,
      ),
      verticalOffset: verticalOffset,
      clipBehavior: clipBehavior,
    );
  }

  void _applyInitialOffsetsIfNeeded() {
    if (_initialOffsetApplied) return;
    _initialOffsetApplied = true;
    final vInit = widget.verticalDetails.initialOffset;
    final hInit = widget.horizontalDetails.initialOffset;
    if (vInit == 0 && hInit == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (vInit != 0 && _verticalController.hasClients) {
        _verticalController.jumpTo(vInit);
      }
      if (hInit != 0 && _horizontalController.hasClients) {
        _horizontalController.jumpTo(hInit);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _viewportSize.dispose();
    if (widget.flutterHorizontalDetails?.controller == null) {
      _horizontalController.dispose();
    }
    if (widget.flutterVerticalDetails?.controller == null) {
      _verticalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _applyInitialOffsetsIfNeeded();

    final resolved = resolveScrollableClient(
      context,
      diagonalDragBehavior: widget.diagonalDragBehavior,
      overscroll: widget.overscroll,
      clipBehavior: widget.clipBehavior,
      hitTestBehavior: widget.hitTestBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      showScrollbar: widget.showScrollbar,
    );
    final diag = _resolveDiagonal(resolved.diagonalDragBehavior);
    final effectiveOverscroll = resolved.overscroll;
    final effectiveClip = resolved.clipBehavior;
    final effectiveHitTest = _resolveHitTest(resolved.hitTestBehavior);
    final effectiveKeyboard = _resolveKeyboardDismiss(
      resolved.keyboardDismissBehavior,
    );

    final horizontalDetails = _flutterDetailsFor(
      core: widget.horizontalDetails,
      flutterOverride: widget.flutterHorizontalDetails,
      controller: _horizontalController,
    );
    final verticalDetails = _flutterDetailsFor(
      core: widget.verticalDetails,
      flutterOverride: widget.flutterVerticalDetails,
      controller: _verticalController,
    );

    assert(
      axisDirectionToAxis(verticalDetails.direction) == .vertical,
      'ScrollableClient.verticalDetails must resolve to Axis.vertical.',
    );
    assert(
      axisDirectionToAxis(horizontalDetails.direction) == .horizontal,
      'ScrollableClient.horizontalDetails must resolve to Axis.horizontal.',
    );

    ScrollableDetails mainAxisDetails = switch (_flutterMainAxis) {
      .vertical => verticalDetails,
      .horizontal => horizontalDetails,
    };

    final effectivePrimary = _effectivePrimary;

    if (effectivePrimary) {
      mainAxisDetails = mainAxisDetails.copyWith(
        controller: PrimaryScrollController.of(context),
      );
    }

    final scrollable = TwoDimensionalScrollable(
      horizontalDetails: switch (_flutterMainAxis) {
        .horizontal => mainAxisDetails,
        .vertical => horizontalDetails,
      },
      verticalDetails: switch (_flutterMainAxis) {
        .vertical => mainAxisDetails,
        .horizontal => verticalDetails,
      },
      viewportBuilder: (context, vOffset, hOffset) => _buildViewport(
        context,
        vOffset,
        hOffset,
        effectiveOverscroll,
        effectiveClip,
      ),
      diagonalDragBehavior: diag,
      dragStartBehavior: widget.dragStartBehavior ?? .start,
      hitTestBehavior: effectiveHitTest,
    );

    // TwoDimensionalScrollable exposes two independent ScrollPositions but
    // doesn't surface them as separate nested Scrollable widgets the way
    // Material's Scrollbar expects, so a single scrollbar can't auto-detect
    // the horizontal axis. Use a `Scrollbar` per axis — each one only
    // listens to its own controller (via `axis`) so both tracks render
    // correctly.
    // Match Web's native scrollbar behaviour — visible only while scrolling
    // (`CoreScrollbarVisibility.auto`, the default) rather than the
    // persistent Material scrollbar Flutter renders by default.
    final CoreScrollbarStyle scrollbarStyle = CoreScrollbarStyle(
      thumbColor: resolved.scrollbarColor,
      thumbRadius: CoreBorderRadius.all(resolved.scrollbarRadius.x),
      thickness: resolved.scrollbarThickness,
      trackColor: resolved.scrollbarTrackColor,
    );
    final Widget scrollbarred = resolved.showScrollbar
        ? Scrollbar(
            axis: .vertical,
            controller: _verticalController,
            scrollbarStyle: scrollbarStyle,
            child: Scrollbar(
              axis: .horizontal,
              controller: _horizontalController,
              scrollbarStyle: scrollbarStyle,
              child: scrollable,
            ),
          )
        : scrollable;

    final scrollableResult = effectivePrimary
        ? PrimaryScrollController.none(child: scrollbarred)
        : scrollbarred;

    final Widget dismissable;
    if (effectiveKeyboard == .onDrag) {
      dismissable = NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          final currentScope = FocusScope.of(context);
          if (notification.dragDetails != null &&
              !currentScope.hasPrimaryFocus &&
              currentScope.hasFocus) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: scrollableResult,
      );
    } else {
      dismissable = scrollableResult;
    }

    // Two-dimensional drag-scroll surfaces are reachable by pointer only
    // until something says otherwise: `TwoDimensionalScrollable` already
    // publishes scroll position/extent and the scroll actions a reader
    // performs, but nothing names the region and nothing takes keyboard
    // focus. Web twin: `role="group"` + `aria-label` + `tabindex="0"` +
    // the same arrow / page / home / end key map.
    //
    // `FocusableActionDetector` is what carries the highlight signal —
    // `onShowFocusHighlight` fires for keyboard focus and not for a
    // pointer press, matching `:focus-visible` on the other platform.
    // The key handler itself lives on the node (`FocusNode.onKeyEvent`)
    // rather than in `shortcuts`/`actions`, so the two platforms read
    // the same key names off the same constants.
    return CoUISemantics(
      role: CoreScrollableClientContract.semanticRole,
      label:
          widget.semanticLabel ??
          CoUILocalizations.of(context).scrollableClientLabel,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        onShowFocusHighlight: handleShowFocusHighlight,
        // A browser focuses an element carrying an explicit `tabindex`
        // on mousedown, so on Web clicking the viewport and then pressing
        // an arrow scrolls it. `FocusableActionDetector` installs a focus
        // node but nothing that takes focus on a tap, so without this the
        // same gesture reaches the keyboard feature on one platform only.
        // `Listener` rather than a gesture recogniser: the viewport's own
        // drag-scroll gesture must keep winning the arena, and this only
        // needs to observe the press, not claim it.
        child: Listener(
          onPointerDown: handlePointerDown,
          child: FocusOutline(
            focused: _focused,
            focusOutlineStyle: resolved.focusOutlineStyle,
            child: dismissable,
          ),
        ),
      ),
    );
  }
}

/// Private viewport used by [ScrollableClient]. Identical behaviour to the
/// legacy [ScrollableClientViewport] but scoped to the new widget so the
/// deprecated class can be removed independently once migration completes.
class _ScrollableClientViewport extends TwoDimensionalViewport {
  const _ScrollableClientViewport({
    required super.delegate,
    required this.onViewportResized,
    required super.horizontalAxisDirection,
    required super.horizontalOffset,
    required super.mainAxis,
    required this.overscroll,
    required super.verticalAxisDirection,
    required super.verticalOffset,
    super.clipBehavior = Clip.hardEdge,
  });

  final bool overscroll;

  /// Notified after layout whenever the viewport size changes.
  final ValueChanged<Size> onViewportResized;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return _RenderScrollableClientViewport(
      childManager: context as TwoDimensionalChildManager,
      delegate: delegate,
      onViewportResized: onViewportResized,
      horizontalAxisDirection: horizontalAxisDirection,
      horizontalOffset: horizontalOffset,
      mainAxis: mainAxis,
      overscroll: overscroll,
      verticalAxisDirection: verticalAxisDirection,
      verticalOffset: verticalOffset,
      clipBehavior: clipBehavior,
    );
  }

  @override
  // childManager is bound to the Element once at creation and must not be
  // re-assigned on update (standard TwoDimensionalViewport pattern).
  void updateRenderObject(
    BuildContext context,
    RenderTwoDimensionalViewport renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    final render = renderObject as _RenderScrollableClientViewport;
    render
      ..overscroll = overscroll
      ..onViewportResized = onViewportResized
      ..delegate = delegate
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..clipBehavior = clipBehavior;
  }
}

class _RenderScrollableClientViewport extends RenderTwoDimensionalViewport {
  _RenderScrollableClientViewport({
    required super.childManager,
    required super.delegate,
    required ValueChanged<Size> onViewportResized,
    required super.horizontalAxisDirection,
    required super.horizontalOffset,
    required super.mainAxis,
    required bool overscroll,
    required super.verticalAxisDirection,
    required super.verticalOffset,
    super.clipBehavior = Clip.hardEdge,
  }) : _overscroll = overscroll,
       _onViewportResized = onViewportResized;

  bool _overscroll;
  bool get overscroll => _overscroll;
  set overscroll(bool value) {
    if (_overscroll == value) return;
    _overscroll = value;
    markNeedsLayout();
  }

  ValueChanged<Size> _onViewportResized;
  set onViewportResized(ValueChanged<Size> value) => _onViewportResized = value;

  // Last viewport size handed to [onViewportResized]; used to fire it only on
  // an actual change rather than every layout pass.
  Size? _lastViewport;

  @override
  void layoutChildSequence() {
    double horizontalPixels = horizontalOffset.pixels;
    double verticalPixels = verticalOffset.pixels;
    final viewport = viewportDimension;
    if (_lastViewport != viewport) {
      _lastViewport = viewport;
      _onViewportResized(viewport);
    }
    // The vicinity carries the current viewport size so the builder can read it
    // on the first frame, but its identity (==/hashCode) is xIndex/yIndex only.
    // A size-dependent identity would orphan the previous child on every resize
    // and crash on paint/hitTest (see #2136); the live size instead reaches the
    // builder through [_onViewportResized] -> the state's viewport notifier.
    final vicinity = _ScrollableClientChildVicinity(
      viewportSize: viewport,
      xIndex: 0,
      yIndex: 0,
    );
    final child = buildOrObtainChildFor(vicinity)!;
    child.layout(
      BoxConstraints(
        minWidth: constraints.maxWidth,
        minHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );
    if (!overscroll) {
      horizontalPixels = max(0, horizontalPixels);
      verticalPixels = max(0, verticalPixels);
      final maxH = child.size.width - viewport.width;
      final maxV = child.size.height - viewport.height;
      horizontalPixels = min(horizontalPixels, maxH);
      verticalPixels = min(verticalPixels, maxV);
    }
    parentDataOf(child).layoutOffset = Offset(
      -horizontalPixels,
      -verticalPixels,
    );
    horizontalOffset.applyContentDimensions(
      0,
      (child.size.width - viewport.width).clamp(0.0, double.infinity),
    );
    verticalOffset.applyContentDimensions(
      0,
      (child.size.height - viewport.height).clamp(0.0, double.infinity),
    );
    horizontalOffset.applyViewportDimension(viewport.width);
    verticalOffset.applyViewportDimension(viewport.height);
  }
}

/// A single-cell vicinity that carries the current viewport size as data only.
///
/// Identity (`==` / `hashCode`) intentionally delegates to [ChildVicinity] —
/// i.e. `xIndex` / `yIndex` only, excluding [viewportSize] — so it stays
/// constant across resizes and never orphans the previous child. The
/// [viewportSize] field is read by the builder purely for the first frame;
/// live updates arrive via the viewport notifier instead.
class _ScrollableClientChildVicinity extends ChildVicinity {
  const _ScrollableClientChildVicinity({
    required this.viewportSize,
    required super.xIndex,
    required super.yIndex,
  });

  final Size viewportSize;

  // viewportSize is deliberately excluded from identity — see the class doc.
}
