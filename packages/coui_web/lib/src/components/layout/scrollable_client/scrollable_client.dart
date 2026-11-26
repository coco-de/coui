import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/layout/scrollable_client/scrollable_client_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

int _coScrollableClientIdCounter = 0;

/// Offset record used by the Web builder (`Offset` on Flutter equivalent).
typedef ScrollableOffset = ({double dx, double dy});

/// Viewport size record used by the Web builder (`Size` on Flutter equivalent).
typedef ScrollableSize = ({double width, double height});

/// Web typedef for the cross-platform ScrollableClient builder.
typedef ScrollableBuilder =
    CoreScrollableBuilder<Component, ScrollableOffset, ScrollableSize>;

/// Unified 2D scrollable viewport for the Web.
///
/// Wraps its content in an `overflow: auto` `<div>` and forwards the current
/// `scrollLeft` / `scrollTop` / `clientWidth` / `clientHeight` to [builder]
/// on every scroll frame. Mirrors `ScrollableClient` on Flutter so callers
/// can share code.
///
/// Advanced Flutter `ScrollableDetails` knobs (controller, physics,
/// decorationClipBehavior) live on the Flutter-only `ScrollableDetails` type
/// and are naturally inaccessible from the Web contract.
class ScrollableClient extends UiStatefulComponent
    implements
        CoreScrollableClientContract<
          Component,
          ScrollableOffset,
          ScrollableSize,
          CoreClip
        > {
  /// Creates a [ScrollableClient].
  const ScrollableClient({
    required this.builder,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
  });

  @override
  final ScrollableBuilder builder;

  @override
  final Component? child;

  @override
  final CoreAxis mainAxis;

  @override
  final CoreDiagonalDragBehavior? diagonalDragBehavior;

  @override
  final bool? overscroll;

  @override
  final CoreClip? clipBehavior;

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

  @override
  State<ScrollableClient> createState() => _ScrollableClientState();
}

class _ScrollableClientState extends State<ScrollableClient> {
  late final _scopeId =
      'co-scrollable-client-${_coScrollableClientIdCounter++}';

  /// Root element id — a caller-supplied id wins (passthrough) and is the
  /// element measured / scrolled (`readScrollGeometry` / `scrollElementTo`)
  /// and scoped by the `<style>`; else the generated scope id.
  String get _effectiveScopeId => component.id ?? _scopeId;
  double _scrollLeft = 0;
  double _scrollTop = 0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  bool _initialOffsetApplied = false;

  // Axis lock state for `weightedEvent` / `weightedContinuous`. Set on the
  // first significant pointer-move of a drag and reset when the pointer is
  // released. `null` = no lock, else axis the drag is committed to.
  CoreAxis? _lockedAxis;
  double? _pointerDownX;
  double? _pointerDownY;
  bool _pointerIsDragging = false;

  /// Folds widget / theme / default values for the runtime behaviour
  /// scalars (Category D). Pointer / scroll handlers read this getter
  /// to drive axis-lock and keyboard dismissal; `build` re-resolves
  /// once per frame and passes the same record into
  /// [resolveScrollableClient] for the paint-ready chrome.
  ScrollableClientRuntime get _runtime => resolveScrollableClientRuntime(
    context,
    diagonalDragBehavior: component.diagonalDragBehavior,
    overscroll: component.overscroll,
    clipBehavior: component.clipBehavior,
    hitTestBehavior: component.hitTestBehavior,
    keyboardDismissBehavior: component.keyboardDismissBehavior,
    showScrollbar: component.showScrollbar,
  );

  @override
  void initState() {
    super.initState();
    // Capture the initial viewport size after the first paint so frozen
    // cells and offset-aware children don't render with size 0.
    unawaited(Future.microtask(_handleInitialMeasure));
  }

  void _handleInitialMeasure() {
    if (!mounted) return;
    final geom = readScrollGeometry(_effectiveScopeId);
    if (geom == null) return;
    _applyInitialOffsetIfNeeded();
    if (_viewportWidth == geom.width && _viewportHeight == geom.height) {
      return;
    }
    setState(() {
      _viewportWidth = geom.width;
      _viewportHeight = geom.height;
    });
  }

  void _applyInitialOffsetIfNeeded() {
    if (_initialOffsetApplied) return;
    _initialOffsetApplied = true;
    final hInit = component.horizontalDetails.initialOffset;
    final vInit = component.verticalDetails.initialOffset;
    if (hInit == 0 && vInit == 0) return;
    scrollElementTo(
      _effectiveScopeId,
      x: hInit == 0 ? null : hInit,
      y: vInit == 0 ? null : vInit,
    );
    _scrollLeft = hInit;
    _scrollTop = vInit;
  }

  void _handleScroll(Object event) {
    final geom = readScrollGeometry(_effectiveScopeId);
    if (geom == null) return;
    if (_runtime.keyboardDismissBehavior == .onDrag && _pointerIsDragging) {
      blurActiveElement();
    }
    if (_scrollLeft == geom.x &&
        _scrollTop == geom.y &&
        _viewportWidth == geom.width &&
        _viewportHeight == geom.height) {
      return;
    }
    setState(() {
      _scrollLeft = geom.x;
      _scrollTop = geom.y;
      _viewportWidth = geom.width;
      _viewportHeight = geom.height;
    });
  }

  void _handlePointerDown(Object event) {
    _pointerIsDragging = true;
    _pointerDownX = mouseClientX(event);
    _pointerDownY = mouseClientY(event);
    _lockedAxis = null;
  }

  void _handlePointerMove(Object event) {
    final diag = _runtime.diagonalDragBehavior;
    final isLockable = diag == .weightedEvent || diag == .weightedContinuous;
    if (!isLockable) return;
    if (_lockedAxis != null) return;
    final downX = _pointerDownX;
    final downY = _pointerDownY;
    if (downX == null || downY == null) return;
    final dx = (mouseClientX(event) ?? downX) - downX;
    final dy = (mouseClientY(event) ?? downY) - downY;
    // 6 px = standard Flutter tap-slop / Material drag threshold.
    const kDragLockThreshold = 6.0;
    if (dx.abs() < kDragLockThreshold && dy.abs() < kDragLockThreshold) {
      return;
    }
    _lockedAxis = dx.abs() >= dy.abs() ? .horizontal : .vertical;
  }

  void _handlePointerUp(Object event) {
    _pointerIsDragging = false;
    _pointerDownX = null;
    _pointerDownY = null;
    _lockedAxis = null;
  }

  /// Scrolls by `dx` or `dy`, clamped to that axis' own extent.
  ///
  /// Returns whether anything moved. A press that moved nothing is left
  /// unconsumed so it chains to the enclosing scroller — which is what a
  /// browser does for a native `overflow: auto` box at its edge, and
  /// what the Flutter twin expresses by returning `KeyEventResult
  /// .ignored`.
  bool _scrollAxisBy({double dx = 0, double dy = 0}) {
    final geom = readScrollGeometry(_effectiveScopeId);
    final bounds = readScrollBounds(_effectiveScopeId);
    if (geom == null || bounds == null) return false;
    // Only the axis that was asked for is written. Passing both would
    // carry this axis' clamped value onto the other one, so a vertical
    // key press could move the horizontal position.
    if (dx != 0) {
      final target = (geom.x + dx).clamp(bounds.minX, bounds.maxX);
      if (target == geom.x) return false;
      scrollElementTo(_effectiveScopeId, x: target);

      return true;
    }
    final target = (geom.y + dy).clamp(bounds.minY, bounds.maxY);
    if (target == geom.y) return false;
    scrollElementTo(_effectiveScopeId, y: target);

    return true;
  }

  /// Scrolls the vertical axis to one of its extents.
  bool _scrollVerticalTo({required bool toEnd}) {
    final geom = readScrollGeometry(_effectiveScopeId);
    final bounds = readScrollBounds(_effectiveScopeId);
    if (geom == null || bounds == null) return false;
    final target = toEnd ? bounds.maxY : bounds.minY;
    if (target == geom.y) return false;
    scrollElementTo(_effectiveScopeId, y: target);

    return true;
  }

  /// Keyboard scrolling — the Web half of the cross-platform key map.
  ///
  /// A `<div>` with `overflow: auto` is not reliably in the tab order
  /// across browsers, and even where it is the arrow keys only work
  /// because the browser chose to help. Both halves are stated here so
  /// the behaviour does not depend on which engine is running, and both
  /// platforms read the step sizes off the same Core constants.
  void _handleKeyDown(web.KeyboardEvent event) {
    // Only when the viewport itself is the focused element. `keydown`
    // bubbles, so this listener also sees every key pressed while an
    // `<input>` inside the content holds focus — acting on those would
    // take the arrows and Home/End away from its caret. The Flutter twin
    // states the same rule as `node.hasPrimaryFocus`.
    if (!eventTargetHasId(event, _effectiveScopeId)) return;
    // A caller's own `onKeyDown` ran first (see the `keydown` entry in
    // `build`) and may have claimed the key. Honouring `preventDefault`
    // is how the DOM already spells "handled" — scrolling anyway would
    // fight a caller whose content owns the arrow keys.
    if (event.defaultPrevented) return;
    // Modified combinations belong to the browser and the OS —
    // Alt+Arrow is history navigation, Ctrl/Cmd+Home jumps the page.
    // Consuming them would take a shortcut away and give back a
    // scroll nobody asked for.
    if (event.altKey || event.ctrlKey || event.metaKey) return;

    final intent = resolveScrollableKeyIntent(
      event.key,
      viewportHeight: _viewportHeight,
    );
    final moved = switch (intent.action) {
      .none => false,
      .jumpToStart => _scrollVerticalTo(toEnd: false),
      .jumpToEnd => _scrollVerticalTo(toEnd: true),
      .moveBy => _scrollAxisBy(dx: intent.dx, dy: intent.dy),
    };
    // Only a press that actually scrolled is consumed — see
    // [_scrollAxisBy]. Consuming unconditionally would trap the key at
    // the edge of the content instead of letting the page take over.
    if (moved) preventDefault(event);
  }

  @override
  Component build(BuildContext context) {
    // Runtime behaviour scalars (Category D) drive the chrome and the
    // pointer/scroll/keyboard logic below. Resolve once per build then
    // hand the folded struct to the chrome resolver (Category A).
    final runtime = _runtime;
    final chrome = resolveScrollableClient(context, runtime: runtime);

    // When `weightedEvent` / `weightedContinuous` is active and the drag is
    // committed to an axis, temporarily block the other axis by widening the
    // inline `touch-action`. Has no effect on `free`/`none`. The base
    // viewport chrome (`max-width:100%`, scrollbar tint, overscroll,
    // pointer-events) flows in from `chrome.root.inlineStyles`; the
    // axis-lock rule is per-frame state and composed on top here.
    final lock = _lockedAxis;
    final diag = runtime.diagonalDragBehavior;
    var effectiveRootStyles = chrome.root.inlineStyles;
    if ((diag == .weightedEvent || diag == .weightedContinuous) &&
        lock != null) {
      final axisLock = lock == .horizontal ? 'pan-x' : 'pan-y';
      effectiveRootStyles = Styles.combine([
        ?effectiveRootStyles,
        Styles(raw: {'touch-action': axisLock}),
      ]);
    }

    final child = component.builder(
      context,
      (dx: _scrollLeft, dy: _scrollTop),
      (width: _viewportWidth, height: _viewportHeight),
      component.child,
    );

    // Only wrap the child when a reverse axis direction needs a CSS
    // `transform` flip. Otherwise inject the builder output directly so the
    // child's intrinsic width/height controls whether the browser shows
    // horizontal/vertical scrollbars (a wrapper with `min-width/height: 100%`
    // would force the child to shrink-fit the viewport instead).
    final needsFlip =
        component.verticalDetails.direction == .up ||
        component.horizontalDetails.direction == .left;
    final Component contentNode;
    if (needsFlip) {
      final contentChrome = resolveScrollableClientContent(
        verticalDirection: component.verticalDetails.direction,
        horizontalDirection: component.horizontalDetails.direction,
      );
      contentNode = div(
        [child],
        classes: contentChrome.root.className,
        styles: contentChrome.root.inlineStyles,
      );
    } else {
      contentNode = child;
    }

    // Scoped WebKit scrollbar skin. Firefox + Chromium 121+ read
    // `scrollbar-color` / `scrollbar-width` off the inline style on the root,
    // but older Blink and WebKit still need the `::-webkit-scrollbar-*`
    // pseudo-element rules to match Flutter's `RawScrollbar` thickness,
    // radius, thumb, and track colours.
    final scrollbarCssText = resolveScrollableClientScrollbarCss(
      context,
      scopeId: _effectiveScopeId,
      showScrollbar: runtime.showScrollbar,
    );
    // The `:focus-visible` ring rides the same scoped `<style>` — the
    // viewport is focusable (`tabindex="0"` below), so WCAG 2.4.7 wants
    // the landing to be visible.
    final focusRingCssText = resolveScrollableClientFocusRingCss(
      context,
      scopeId: _effectiveScopeId,
    );
    final scrollbarCss = Component.element(
      tag: 'style',
      children: [RawText('$scrollbarCssText$focusRingCssText')],
    );

    // A pointer-only scroll surface is invisible to everyone else: a
    // reader is told nothing about the region and a keyboard user cannot
    // reach it at all. `role="group"` + `aria-label` name it,
    // `tabindex="0"` puts it in the tab order, and `_handleKeyDown`
    // gives the keys something to do. Flutter twin: `CoUISemantics(role:
    // group, label:)` + `FocusableActionDetector` + the same key map.
    //
    // Caller-supplied attributes are spread last so a caller that names
    // the region itself — or opts it out of the tab order — still wins,
    // which is the passthrough contract every other component honours.
    final callerEvents = component.events;
    final semantics = {
      'role': CoreScrollableClientContract.semanticRole.ariaRole,
      'aria-label':
          component.semanticLabel ??
          CouiLocalizations.of(context).scrollableClientLabel,
      'tabindex': '0',
    };

    return div(
      [scrollbarCss, contentNode],
      id: _effectiveScopeId,
      classes: component.rootClasses(chrome.root.className),
      styles: component.css != null
          ? Styles.combine([?effectiveRootStyles, component.css!])
          : effectiveRootStyles,
      attributes: {...semantics, ...component.componentAttributes},
      events: {
        ...callerEvents,
        'scroll': _handleScroll,
        // Composed, not replaced: `component.events` already carries a
        // caller's `onKeyDown` under this same key, and naming the key
        // again would drop it without any visible symptom.
        'keydown': EventHandlers.chain(
          callerEvents['keydown'],
          EventHandlers.createKeyboardEventHandler(_handleKeyDown),
        ),
        'pointerdown': _handlePointerDown,
        'pointermove': _handlePointerMove,
        'pointerup': _handlePointerUp,
        'pointercancel': _handlePointerUp,
      },
    );
  }
}
