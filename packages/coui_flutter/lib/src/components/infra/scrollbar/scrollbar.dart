import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;

/// Fade-in / fade-out duration of the overlay thumb — shared with the
/// Web twin through the contract constant so both platforms fade in
/// sync.
const _kScrollbarFadeDuration = Duration(
  milliseconds: CoreScrollbarContract.fadeDurationMs,
);

/// Time the thumb stays visible after scrolling before fading out —
/// shared with the Web twin through the contract constant.
const _kScrollbarTimeToFade = Duration(
  milliseconds: CoreScrollbarContract.timeToFadeMs,
);

/// Fraction of the scrollable range moved by one accessibility
/// increase/decrease step on the slider-shaped scrollbar affordance —
/// 10% of the track per step, a coarse switch-control-sized jump.
const _kScrollbarValueStepFraction = 0.1;

/// `increasedValue` / `decreasedValue` step, in whole percent — the
/// same step as [_kScrollbarValueStepFraction] expressed the way
/// [_RawScrollbarState] reports it back to assistive tech.
const _kScrollbarValueStepPercent = 10;

/// Pixel-literal sentinel, not a design token: the non-visual semantics
/// affordance matches the Web twin's 1px `sr-only` box. Flutter Web turns
/// slider semantics into a DOM range input, so it must not cover the body.
const _kScrollbarSemanticsExtent = 1.0;

/// Duration of the animated move triggered by an accessibility
/// increase/decrease action.
const _kScrollbarAccessibilityStepDuration = Duration(milliseconds: 100);

/// A unified cross-platform scrollbar wrapper.
///
/// `Scrollbar` wraps a scrollable [child] and renders a
/// design-system scrollbar around it. The thumb colour, thickness and
/// corner radius flow through the single [scrollbarStyle] slot;
/// behavioural fields ([axis], [visibility], [interactive]) stay flat
/// on the widget.
///
/// On Flutter the thumb is overlay-painted (`RawScrollbar`); the Web
/// implementation reproduces the same surface with a `<div>` that owns
/// the `overflow` rules plus the `scrollbar-*` utility classes.
///
/// ```dart
/// Scrollbar(
///   axis: CoreScrollbarAxis.vertical,
///   child: ListView(children: [...]),
/// )
/// ```
///
/// [controller] is optional. The bar describes its position to assistive
/// technology and lets the user drag its thumb either way — both read the
/// wrapped scrollable's own scroll notifications rather than a
/// controller, so `Scrollbar(child: ListView(...))` behaves the same on
/// every platform. The Web twin needs no equivalent: the browser owns
/// its scrollbar outright.
///
/// [CoreScrollbarVisibility.always] does not need one either, but without
/// one it raises a single debug diagnostic on its first frame. Flutter's
/// `RawScrollbar` schedules that validation from `didChangeDependencies`,
/// so it runs in the post-frame queue of the first frame — before the
/// first `ScrollMetricsNotification`, which is the earliest moment this
/// bar can learn which scrollable it wraps. There is nothing to lend yet.
///
/// The whole call sits inside `assert(...)`, so nothing is scheduled in
/// release, and from the second frame the bar behaves exactly as `always`
/// should: the thumb stays visible at rest and drags the list. What it
/// does cost is a widget test — one that pumps this shape fails on the
/// untaken exception unless it passes a [controller] or takes it.
///
/// ```dart
/// Scrollbar(
///   visibility: CoreScrollbarVisibility.always,
///   controller: controller,
///   child: ListView(controller: controller, children: [...]),
/// )
/// ```
class Scrollbar extends StatefulWidget
    implements CoreScrollbarContract<Widget> {
  /// Creates a [Scrollbar].
  const Scrollbar({
    required this.child,
    this.axis = CoreScrollbarAxis.defaultAxis,
    this.visibility = CoreScrollbarVisibility.defaultVisibility,
    this.interactive = true,
    this.controller,
    this.scrollbarStyle,
    super.key,
  });

  @override
  final Widget child;

  @override
  final CoreScrollbarAxis axis;

  @override
  final CoreScrollbarVisibility visibility;

  @override
  final bool interactive;

  /// Scroll controller forwarded to the underlying scroll position.
  ///
  /// Flutter-framework-only — the Web implementation tracks scroll
  /// position natively and exposes no controller.
  ///
  /// Optional throughout — the accessibility affordance and thumb dragging
  /// both read the wrapped scrollable's notifications directly, and so does
  /// [CoreScrollbarVisibility.always] from its second frame onward. Passing
  /// one additionally silences the debug diagnostic `always` raises on its
  /// first frame — see the class dartdoc.
  final ScrollController? controller;

  @override
  final CoreScrollbarStyle? scrollbarStyle;

  /// Returns a copy of this [Scrollbar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Scrollbar copyWith({
    Key? key,
    CoreScrollbarAxis? axis,
    CoreScrollbarVisibility? visibility,
    bool? interactive,
    ScrollController? controller,
    CoreScrollbarStyle? scrollbarStyle,
    Widget? child,
  }) {
    return Scrollbar(
      key: key ?? this.key,
      axis: axis ?? this.axis,
      visibility: visibility ?? this.visibility,
      interactive: interactive ?? this.interactive,
      controller: controller ?? this.controller,
      scrollbarStyle: scrollbarStyle ?? this.scrollbarStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Scrollbar> createState() => _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> {
  /// What the accessibility layer currently announces, republished from
  /// every tracked scroll notification.
  ///
  /// A [ValueNotifier] rather than [setState] for two reasons: only the
  /// [Semantics] subtree rebuilds (never the painted bar), and a report
  /// that compares equal to the last one publishes nothing at all — a
  /// drag that moves fewer pixels than one reported percent costs no
  /// rebuild.
  final ValueNotifier<_ScrollbarPositionReport?> _positionReport =
      ValueNotifier(null);

  _ScrollbarPositionReport? _pendingPositionReport;
  bool _positionReportScheduled = false;

  /// [ScrollNotification.context] of the scrollable this bar last heard
  /// from — the handle every consumer below resolves a live
  /// [ScrollPosition] through.
  ///
  /// Kept as a context rather than as the [ScrollPosition] itself so the
  /// resolution can tell a live scrollable from a disposed one: a stored
  /// position gives no way to ask, while an unmounted context does.
  BuildContext? _scrollableContext;

  /// Lends whatever scrollable this bar is tracking to the painted bar's
  /// gesture machinery, which reaches a [ScrollPosition] only through a
  /// [ScrollController].
  late final _ScrollbarBorrowedController _borrowedController =
      _ScrollbarBorrowedController(this);

  /// Restricts the scrollbar to a single axis when [Scrollbar.axis]
  /// is not [CoreScrollbarAxis.both].
  ScrollNotificationPredicate get _axisPredicate {
    return switch (widget.axis) {
      .both => defaultScrollNotificationPredicate,
      .vertical =>
        (notification) =>
            defaultScrollNotificationPredicate(notification) &&
            notification.metrics.axis == .vertical,
      .horizontal =>
        (notification) =>
            defaultScrollNotificationPredicate(notification) &&
            notification.metrics.axis == .horizontal,
    };
  }

  /// The live [ScrollPosition] of the scrollable this bar last heard
  /// from, or null if there has been none or it is gone.
  ///
  /// Every consumer — the accessibility step actions and the borrowed
  /// controller the painted thumb drags through — goes through this one
  /// resolution, so the value the bar announces and the position its
  /// thumb moves cannot come from different scrollables.
  ///
  /// Drops the tracked element on the way out when it turns out to be
  /// unmounted, rather than holding it until some future notification
  /// replaces it. That write can land during a build (the borrowed
  /// controller is read while `RawScrollbar` builds its gesture map),
  /// which is why it is a plain field assignment and never a
  /// [setState] — nothing about this widget's own build depends on it.
  ScrollPosition? _resolveTrackedPosition() {
    final scrollableContext = _scrollableContext;
    if (scrollableContext == null) return null;
    if (!scrollableContext.mounted) {
      _scrollableContext = null;
      return null;
    }
    return Scrollable.maybeOf(scrollableContext)?.position;
  }

  /// Folds [metrics] into the value the accessibility node reports.
  ///
  /// The percent itself is [scrollbarPercentOfAxis] — the same function
  /// the Web twin runs on its DOM geometry, so the two platforms cannot
  /// round or clamp the same position differently. Flutter reaches it
  /// with `maxScrollExtent - minScrollExtent`, Web with
  /// `scrollHeight - clientHeight`; both are already the pair the
  /// function asks for.
  ///
  /// `canScroll` gates the increase/decrease actions on there being
  /// somewhere to go — a bar over content that fits advertises no action
  /// it would refuse to perform. The axis that fails that gate is
  /// exactly the axis the shared function refuses to divide by, so both
  /// branches below report the same floor it would.
  _ScrollbarPositionReport _reportFor(ScrollMetrics metrics) {
    if (!metrics.hasContentDimensions || !metrics.hasPixels) {
      return const _ScrollbarPositionReport(
        percent: kScrollbarPercentMin,
        canScroll: false,
      );
    }
    final scrollableExtent = metrics.maxScrollExtent - metrics.minScrollExtent;
    // Non-finite as well as non-positive: an unbounded or NaN extent is
    // not somewhere the increase/decrease actions can travel, and
    // dividing by it would reach `round()` as a NaN, which throws rather
    // than saturating.
    if (!scrollableExtent.isFinite || scrollableExtent <= 0) {
      return const _ScrollbarPositionReport(
        percent: kScrollbarPercentMin,
        canScroll: false,
      );
    }
    return _ScrollbarPositionReport(
      percent: scrollbarPercentOfAxis(
        offset: metrics.pixels - metrics.minScrollExtent,
        scrollableExtent: scrollableExtent,
      ),
      canScroll: true,
    );
  }

  /// Republishes what the node announces, and remembers which scrollable
  /// said it.
  ///
  /// Neither write goes through [setState], and the painted bar still
  /// picks both up. The report is a [ValueNotifier] that rebuilds only
  /// the [Semantics] subtree. The tracked scrollable is read back through
  /// [_borrowedController] while `RawScrollbar` decides its gesture map,
  /// and `RawScrollbar` rebuilds itself on the same notification that
  /// first names a scrollable — it learns its own axis from that
  /// notification and calls `setState` for it. Adding a second rebuild
  /// here would repaint the whole wrapped scrollable for a fact the bar
  /// has already acted on; a version that did was tried, and no test in
  /// this repo could tell the two apart.
  void _trackScrollable(
    ScrollMetrics metrics,
    BuildContext? scrollableContext,
  ) {
    if (scrollableContext != null) _scrollableContext = scrollableContext;
    final report = _reportFor(metrics);
    // Installing new viewport dimensions can start a ballistic activity and
    // dispatch ScrollStartNotification during layout. Its notifier rebuilds
    // the semantics subtree, so publish only after that frame has finished.
    // Coalesce layout reports and retain the most recent observed metrics.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _pendingPositionReport = report;
      if (!_positionReportScheduled) {
        _positionReportScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _positionReportScheduled = false;
          final pending = _pendingPositionReport;
          _pendingPositionReport = null;
          if (mounted && pending != null) _positionReport.value = pending;
        });
      }
      return;
    }
    // A newer pointer/metrics update supersedes any queued layout report.
    _pendingPositionReport = null;
    _positionReport.value = report;
  }

  /// Records the metrics that arrive when the scrollable first lays out
  /// (or re-lays out) — the only notification that fires before anything
  /// has scrolled, and therefore the one that gives the node its initial
  /// value and hands the thumb something to drag.
  ///
  /// Mirrors the framework's own filter, which converts the metrics
  /// notification before testing it, so this widget tracks exactly the
  /// scrollable(s) the painted thumb tracks.
  bool handleTrackedScrollMetrics(ScrollMetricsNotification notification) {
    if (_axisPredicate(notification.asScrollUpdate())) {
      _trackScrollable(notification.metrics, notification.context);
    }
    return false;
  }

  /// Records the metrics of every subsequent scroll so the reported
  /// value stays live.
  bool handleTrackedScrollNotification(ScrollNotification notification) {
    if (_axisPredicate(notification)) {
      _trackScrollable(notification.metrics, notification.context);
    }
    return false;
  }

  /// Moves the tracked scrollable by one accessibility step in
  /// [direction] (`1` for increase, `-1` for decrease) — the
  /// `Semantics.onIncrease` / `onDecrease` handler for the
  /// slider-shaped scrollbar affordance.
  void _handleAccessibilityStep(double direction) {
    final position = _resolveTrackedPosition();
    if (position == null ||
        !position.hasContentDimensions ||
        !position.hasPixels) {
      return;
    }
    final extent = position.maxScrollExtent - position.minScrollExtent;
    if (extent <= 0) return;
    final target =
        (position.pixels + direction * extent * _kScrollbarValueStepFraction)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    unawaited(
      position.moveTo(
        target,
        duration: _kScrollbarAccessibilityStepDuration,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _positionReport.dispose();
    _borrowedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveScrollbar(
      context,
      visibility: widget.visibility,
      scrollbarStyle: widget.scrollbarStyle,
    );

    // `Scrollbar` owns the scrollbar chrome, so the ambient
    // `ScrollBehavior`'s platform-default scrollbar is stripped from
    // the wrapped scrollable — on desktop it would otherwise paint a
    // second thumb on top of this one (two translucent thumbs stack
    // into a visibly darker capsule while scrolling).
    final Widget child = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: widget.child,
    );

    final isHidden = widget.visibility == .hidden;

    // `hidden` visibility keeps the area scrollable but draws no thumb,
    // so only the painted bar is conditional — the accessibility layer
    // wraps both branches. Dropping the node along with the thumb would
    // leave the one mode where a sighted user has no position cue as
    // the one mode where a screen-reader user has none either, which is
    // backwards: this is where the non-visual affordance carries the
    // most, not the least. Nothing about the node was ever tied to what
    // is painted — it reads scroll notifications and renders no pixels
    // on either platform (the Web twin's `role="scrollbar"` node is
    // `sr-only` and likewise survives `hidden`).
    // The tracked scrollable is read from the same notification stream
    // that drives the painted thumb, so anything that can paint a thumb
    // can also describe one and be dragged — and, sitting outside the bar
    // rather than inside it, so can `hidden`, which paints none. Sourcing
    // it from a `ScrollController` instead could not: `Scrollbar(child:
    // ListView(...))` passes no controller, and off mobile
    // `PrimaryScrollController.shouldInherit` is false, so the wrapped
    // scrollable attaches to no controller any ambient lookup could find
    // — the bar painted a thumb, announced nothing, and moved nothing
    // when that thumb was dragged.
    //
    // These listeners sit above the framework's own (which return false,
    // so every notification keeps bubbling) and likewise return false, so
    // nothing outside this widget sees a different notification stream
    // than before.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: handleTrackedScrollMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: handleTrackedScrollNotification,
        child: _ScrollbarAccessibilityLayer(
          interactive: widget.interactive,
          report: _positionReport,
          onStep: _handleAccessibilityStep,
          child: isHidden
              ? child
              : _RawScrollbar(
                  thumbColor: resolved.thumbColor,
                  hoverThumbColor: resolved.hoverThumbColor,
                  thumbRadius: resolved.thumbRadius,
                  trackColor: resolved.trackColor,
                  minThumbLength: resolved.minThumbLength,
                  hoverDuration: resolved.hoverDuration,
                  thickness: resolved.thickness,
                  hoverThickness: resolved.hoverThickness,
                  thumbInset: resolved.thumbInset,
                  hoverThumbInset: resolved.hoverThumbInset,
                  interactive: widget.interactive,
                  thumbVisibility: widget.visibility == .always,
                  // A caller-supplied controller wins outright: it is the
                  // one the caller also drives the scrollable with, and
                  // handing `RawScrollbar` anything else would make the
                  // bar and the caller disagree about which position they
                  // are moving.
                  controller: widget.controller ?? _borrowedController,
                  notificationPredicate: _axisPredicate,
                  child: child,
                ),
        ),
      ),
    );
  }
}

/// Lends the wrapped scrollable's live [ScrollPosition] to `RawScrollbar`,
/// which reaches a position only through a [ScrollController].
///
/// The bar has no controller of its own to offer — `Scrollbar(child:
/// ListView(...))` never sees one, and off mobile the list attaches to no
/// ambient one either. What it does have is the scrollable's own
/// notification stream, which names the very position a controller would
/// have handed over. This borrows that position instead of owning one:
/// [attach] is never called, no listener is registered on the borrowed
/// position, and nothing here participates in its lifecycle. The
/// scrollable creates, drives and disposes it exactly as it did before.
///
/// Every read goes back to [_bar], so a scrollable that has gone away
/// reports as no clients on the next question rather than leaving a dead
/// position behind — and the position lent here is by construction the
/// one the accessibility node describes, since both come from that same
/// resolution.
class _ScrollbarBorrowedController extends ScrollController {
  _ScrollbarBorrowedController(this._bar);

  /// The bar that knows which scrollable is being tracked. Held rather
  /// than copied from because the answer changes over the bar's life and
  /// a snapshot would lend a stale position.
  final _ScrollbarState _bar;

  @override
  Iterable<ScrollPosition> get positions {
    final position = _bar._resolveTrackedPosition();
    return position == null ? const [] : [position];
  }

  @override
  bool get hasClients => _bar._resolveTrackedPosition() != null;

  @override
  ScrollPosition get position {
    final position = _bar._resolveTrackedPosition();
    assert(
      position != null,
      'Scrollbar has not heard from a scrollable yet, so there is no '
      'position to lend.',
    );
    return position!;
  }
}

/// Direct `RawScrollbar` subclass that paints the design-system thumb.
///
/// `Scrollbar` renders through this class directly rather than
/// delegating to the legacy `Scrollbar` widget.
///
/// The thumb has two looks — resting and hovered / dragged — and moves
/// between them on [hoverDuration]. The resting look is `thumbColor`,
/// `thickness` and the inset it keeps from the edge (`RawScrollbar`'s
/// `mainAxisMargin` / `crossAxisMargin`); the hovered look is the matching
/// `hover*` values, where the hovered inset is what the grown thumb leaves
/// of the same footprint.
class _RawScrollbar extends RawScrollbar {
  const _RawScrollbar({
    required super.child,
    required Color thumbColor,
    required this.hoverThumbColor,
    required this.thumbRadius,
    required Color trackColor,
    required super.minThumbLength,
    required this.hoverDuration,
    required double thickness,
    required this.hoverThickness,
    required double thumbInset,
    required this.hoverThumbInset,
    required super.interactive,
    required super.thumbVisibility,
    super.controller,
    ScrollNotificationPredicate? notificationPredicate,
  }) : _thumbColor = thumbColor,
       _trackColor = trackColor,
       super(
         thickness: thickness,
         radius: thumbRadius,
         mainAxisMargin: thumbInset,
         crossAxisMargin: thumbInset,
         fadeDuration: _kScrollbarFadeDuration,
         timeToFade: _kScrollbarTimeToFade,
         pressDuration: .zero,
         notificationPredicate:
             notificationPredicate ?? defaultScrollNotificationPredicate,
       );

  final Color _thumbColor;
  @override
  Color get thumbColor => _thumbColor;

  /// Thumb colour while hovered or dragged.
  final Color hoverThumbColor;
  final Radius thumbRadius;
  final Color _trackColor;
  @override
  Color get trackColor => _trackColor;

  /// Thumb thickness while hovered or dragged.
  final double hoverThickness;

  /// Inset from the edge while hovered or dragged — the resting inset is
  /// `crossAxisMargin`.
  final double hoverThumbInset;

  /// How long the thumb takes to move between its two looks.
  final Duration hoverDuration;

  @override
  RawScrollbarState<_RawScrollbar> createState() => _RawScrollbarState();
}

class _RawScrollbarState extends RawScrollbarState<_RawScrollbar> {
  late AnimationController _hoverAnimationController;
  late CurvedAnimation _hoverAnimation;

  /// Whether the pointer is on the bar. Hover events arrive only while no
  /// button is pressed, so this cannot describe a drag.
  bool _pointerOverBar = false;

  /// Whether the thumb is being dragged. Kept apart from the pointer
  /// because a drag carries the pointer off the bar while the thumb is
  /// still the thing being held.
  bool _draggingThumb = false;

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      duration: widget.hoverDuration,
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverAnimationController,
      curve: CoreEasing.move.toValue(),
    );
    _hoverAnimationController.addListener(updateScrollbarPainter);
  }

  @override
  void didUpdateWidget(_RawScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reduced motion can be switched while the bar is mounted.
    if (widget.hoverDuration != oldWidget.hoverDuration) {
      _hoverAnimationController.duration = widget.hoverDuration;
    }
  }

  @override
  void updateScrollbarPainter() {
    final progress = _hoverAnimation.value;
    scrollbarPainter
      ..color = Color.lerp(widget.thumbColor, widget.hoverThumbColor, progress)!
      ..trackColor = widget.trackColor
      ..textDirection = Directionality.of(context)
      ..thickness = lerpDouble(
        widget.thickness,
        widget.hoverThickness,
        progress,
      )!
      ..crossAxisMargin = lerpDouble(
        widget.crossAxisMargin,
        widget.hoverThumbInset,
        progress,
      )!
      ..mainAxisMargin = widget.mainAxisMargin
      ..radius = widget.thumbRadius
      ..minLength = widget.minThumbLength
      ..padding = MediaQuery.paddingOf(context)
      ..ignorePointer = !enableGestures;
  }

  /// Moves the thumb toward the hovered look while the pointer is on the bar
  /// or the thumb is held, and back to rest otherwise.
  void _syncThumbLook() {
    if (_pointerOverBar || _draggingThumb) {
      _hoverAnimationController.forward();
    } else {
      _hoverAnimationController.reverse();
    }
  }

  @override
  void handleHover(PointerHoverEvent event) {
    _pointerOverBar = isPointerOverScrollbar(
      event.position,
      event.kind,
      forHover: true,
    );
    // A hover event means no button is down, so no drag can be in progress.
    // This also lets a drag that was cancelled without reaching
    // `handleThumbPressEnd` stop holding the thumb at its hovered look.
    _draggingThumb = false;
    _syncThumbLook();
    super.handleHover(event);
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    _pointerOverBar = false;
    _syncThumbLook();
  }

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    _draggingThumb = true;
    _syncThumbLook();
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    super.handleThumbPressEnd(localPosition, velocity);
    _draggingThumb = false;
    _syncThumbLook();
  }

  @override
  void dispose() {
    _hoverAnimation.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  bool get enableGestures => widget.interactive ?? true;
}

/// Describes the wrapped scrollable's position to assistive technology,
/// independently of whether a thumb is painted above it.
///
/// Lives outside the painted bar so
/// [CoreScrollbarVisibility.hidden] — which draws no thumb but keeps the
/// area scrollable — still reaches an accessibility node. The bar's own
/// `RawScrollbar` machinery is never built in that mode, so anything
/// hosted inside it disappeared with the thumb.
///
/// Renders [report] and nothing else: the enclosing [Scrollbar] does the
/// tracking, because the thumb's own gesture machinery needs the very
/// same answer and two trackers could drift into describing two
/// scrollables. So this takes what to announce and what an announced
/// action should move, and owns neither.
///
/// [interactive] gates the increase/decrease actions here, and the
/// painted bar gates thumb dragging from the same flag through its own
/// parameter — one value, two consumers, so a change to either has to
/// be a change to both. A bar the user may not operate advertises no
/// operation. The Web twin says as much with `aria-disabled` on its
/// phantom `role="scrollbar"` node, though it can only assert it: there
/// are no actions there to withhold.
class _ScrollbarAccessibilityLayer extends StatelessWidget {
  const _ScrollbarAccessibilityLayer({
    required this.interactive,
    required this.report,
    required this.onStep,
    required this.child,
  });

  /// Whether the scrollbar affordance itself may be operated — mirrors
  /// [Scrollbar.interactive].
  final bool interactive;

  /// What to announce, republished by the enclosing [Scrollbar] from the
  /// tracked scroll notifications. Listening to it rather than rebuilding
  /// with it keeps a moving scrollbar from rebuilding the painted bar.
  final ValueListenable<_ScrollbarPositionReport?> report;

  /// Moves the tracked scrollable by one step in the given direction
  /// (`1` for increase, `-1` for decrease).
  final void Function(double direction) onStep;

  /// The scrollable subtree (with or without a painted bar above it).
  final Widget child;

  /// Builds the phantom accessibility node describing the thumb's
  /// current position — a `slider`-shaped [Semantics] node (Flutter has
  /// no dedicated scrollbar role; `value` + increase/decrease actions
  /// is the closest built-in affordance, matching the Web twin's
  /// `role="scrollbar"` + `aria-valuenow`). Rebuilds whenever the
  /// reported value changes, so what assistive tech reads stays live.
  Widget _buildAccessibilityLayer() {
    return ValueListenableBuilder<_ScrollbarPositionReport?>(
      valueListenable: report,
      builder: (context, report, _) {
        // Nothing has laid out yet, so there is no thumb either. The
        // empty container keeps the node's place in the tree rather than
        // letting the subtree appear and disappear underneath assistive
        // tech.
        if (report == null) return Semantics(container: true);
        final percent = report.percent;
        final canStep = interactive && report.canScroll;
        final steppedUp = (percent + _kScrollbarValueStepPercent).clamp(
          kScrollbarPercentMin,
          kScrollbarPercentMax,
        );
        final steppedDown = (percent - _kScrollbarValueStepPercent).clamp(
          kScrollbarPercentMin,
          kScrollbarPercentMax,
        );
        return Semantics(
          container: true,
          slider: true,
          value: '$percent%',
          increasedValue: canStep && percent < kScrollbarPercentMax
              ? '$steppedUp%'
              : null,
          decreasedValue: canStep && percent > kScrollbarPercentMin
              ? '$steppedDown%'
              : null,
          onIncrease: canStep && percent < kScrollbarPercentMax
              ? () => onStep(1)
              : null,
          onDecrease: canStep && percent > kScrollbarPercentMin
              ? () => onStep(-1)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // A phantom sibling node, not a wrapper around the built bar — the
    // wrapped scrollable already contributes its own (correct) scroll
    // semantics, and merging `slider` chrome into that same node would
    // fight it. A screen-reader-only box keeps the phantom slider from
    // covering the content in Flutter Web's semantics DOM. Render-box
    // hitTest transparency alone does not affect that DOM range input.
    // `IgnorePointer`'s only way to
    // keep hit-testing off while leaving semantics untouched is its
    // deprecated `ignoringSemantics` param — left at its default, it sets
    // `isBlockingUserActions`, which silently strips the
    // `increase`/`decrease` actions this layer exists to add (`value` /
    // `slider` still pass through, so the omission never shows up as a
    // missing node — only as one whose actions never fire).
    // `_ScrollbarPointerTransparent` sidesteps that by only overriding
    // `hitTest`.
    // The stack hands [child] the constraints it was given, untouched. A
    // loose stack turns a tight width into "up to this much", and a
    // scrollable that shrink-wraps its cross axis (`SingleChildScrollView`)
    // then sizes to its widest line while the box around it stays the full
    // width — the thumb is painted against the narrow scrollable, a few
    // pixels from the text instead of at the edge of the box, and the
    // content is clipped to it. `RawScrollbar` is layout-transparent, so a
    // bar must not change what its scrollable is asked to be.
    return Stacks(
      fit: .passthrough,
      children: [
        child,
        Position(
          top: 0,
          left: 0,
          width: _kScrollbarSemanticsExtent,
          height: _kScrollbarSemanticsExtent,
          child: _ScrollbarPointerTransparent(
            child: _buildAccessibilityLayer(),
          ),
        ),
      ],
    );
  }
}

/// Everything the slider-shaped accessibility node announces, reduced to
/// the two values that actually change what assistive tech reads.
///
/// Equality is what makes the [ValueNotifier] in
/// [_ScrollbarAccessibilityLayer] quiet: two reports that would
/// read identically publish once.
@immutable
class _ScrollbarPositionReport {
  const _ScrollbarPositionReport({
    required this.percent,
    required this.canScroll,
  });

  /// Scroll offset as whole percent of the scrollable range.
  final int percent;

  /// Whether the tracked scrollable has any range to move through —
  /// `false` for content that fits, where an increase/decrease action
  /// would be advertised and then refused.
  final bool canScroll;

  @override
  bool operator ==(Object other) =>
      other is _ScrollbarPositionReport &&
      other.percent == percent &&
      other.canScroll == canScroll;

  @override
  int get hashCode => Object.hash(percent, canScroll);
}

/// Suppresses pointer hit-testing for [SingleChildRenderObjectWidget.child]
/// while leaving its semantics completely untouched.
///
/// `IgnorePointer` can do the same, but only through its deprecated
/// `ignoringSemantics` parameter — left at its default it sets
/// `SemanticsConfiguration.isBlockingUserActions`, silently dropping
/// interactive actions like `increase` / `decrease` from anything
/// beneath it (see [_ScrollbarAccessibilityLayer]).
/// Overriding only [RenderBox.hitTest] keeps the inherited
/// [RenderObject.describeSemanticsConfiguration] unchanged, so nothing
/// blocks the semantic actions.
class _ScrollbarPointerTransparent extends SingleChildRenderObjectWidget {
  const _ScrollbarPointerTransparent({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScrollbarPointerTransparent();
}

class _RenderScrollbarPointerTransparent extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}

/// Chain sugar for merging a [CoreScrollbarStyle] patch into
/// [Scrollbar.scrollbarStyle] without hand-reconstructing every field.
/// Mirrors the Web `Scrollbar.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreScrollbarStyle.merge` right-side-wins semantics).
extension ScrollbarStyleChain on Scrollbar {
  /// Returns a copy of this [Scrollbar] with [patch] merged into
  /// [scrollbarStyle] (patch fields win on conflict).
  Scrollbar withStyle(CoreScrollbarStyle patch) => copyWith(
    scrollbarStyle: (scrollbarStyle ?? const CoreScrollbarStyle()).merge(patch),
  );
}
