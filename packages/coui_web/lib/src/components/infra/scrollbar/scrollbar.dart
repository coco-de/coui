import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_geometry.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart'
    show scheduleNextFrame;
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

int _coScrollbarIdCounter = 0;

/// One frame of a paged scroll — about 60 per second.
const Duration _kPageScrollFrame = Duration(milliseconds: 16);

/// A unified cross-platform scrollbar wrapper for CoUI Web.
///
/// `Scrollbar` wraps a scrollable [child] inside a `<div>` that owns the
/// axis-specific `overflow` rules. The browser's own scrollbar is hidden and
/// the thumb is a `<div>` drawn over the content, the way the Flutter
/// `RawScrollbar` overlay is — so the bar takes none of the content's width.
/// The thumb colour / thickness / radius / inset flow through the single
/// [scrollbarStyle] slot; behavioural fields ([axis], [visibility],
/// [interactive]) stay flat on the widget.
///
/// Matches the Flutter `Scrollbar` contract one-to-one — the same
/// `axis` / `visibility` / `interactive` surface produces the same visible
/// result on both platforms. Where the thumb sits is the arithmetic
/// Flutter's painter is held to (`CoreScrollbarThumbLayout`).
///
/// Example:
/// ```dart
/// Scrollbar(
///   axis: CoreScrollbarAxis.vertical,
///   visibility: CoreScrollbarVisibility.thin,
///   child: div([...]),
/// )
/// ```
class Scrollbar extends UiStatefulComponent
    implements CoreScrollbarContract<Component> {
  /// Creates a [Scrollbar].
  const Scrollbar({
    required this.child,
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
    this.axis = CoreScrollbarAxis.defaultAxis,
    this.visibility = CoreScrollbarVisibility.defaultVisibility,
    this.interactive = true,
    this.scrollbarStyle,
  });

  @override
  final Component? child;

  @override
  final CoreScrollbarAxis axis;

  @override
  final CoreScrollbarVisibility visibility;

  @override
  final bool interactive;

  @override
  final CoreScrollbarStyle? scrollbarStyle;

  /// Returns a copy of this [Scrollbar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Scrollbar copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreScrollbarAxis? axis,
    CoreScrollbarVisibility? visibility,
    bool? interactive,
    CoreScrollbarStyle? scrollbarStyle,
    Component? child,
  }) {
    return Scrollbar(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      axis: axis ?? this.axis,
      visibility: visibility ?? this.visibility,
      interactive: interactive ?? this.interactive,
      scrollbarStyle: scrollbarStyle ?? this.scrollbarStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Scrollbar> createState() => _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> {
  late final String _scopeId;

  /// The scroller's geometry as last read — what the thumbs are placed from
  /// and what `aria-valuenow` on the phantom `role="scrollbar"` nodes
  /// reports. Null until the first read in a browser (a server render never
  /// has one), which draws no thumb.
  ScrollbarViewportGeometry? _viewport;

  /// Whether the thumb is shown because the area was just scrolled —
  /// `auto` / `thin` only. The idle timeout takes it away again.
  bool _shown = false;

  /// The axis whose thumb is held, if any.
  CoreScrollbarAxis? _draggingAxis;

  Timer? _idleTimer;
  Timer? _pageTimer;
  void Function()? _detachResize;
  void Function()? _detachDrag;

  bool get _fades =>
      component.visibility == .auto || component.visibility == .thin;

  /// The id the scrollable root renders with — a caller-supplied `id`
  /// wins (passthrough), else this instance's generated scope id.
  String get _rootId => component.id ?? _scopeId;

  @override
  void initState() {
    super.initState();
    _scopeId =
        'co-scrollbar-${kIsWeb ? 'web' : 'ssr'}-${_coScrollbarIdCounter++}';
    // Read the geometry once the hydrated root exists, because the box can
    // already be scrolled by the time this component first runs in a
    // browser: a reload or a back-forward navigation restores the previous
    // scroll offset, and a `#fragment` in the URL jumps to an anchor — both
    // before any `scroll` event this component could hear. Without this the
    // affordance would announce the start of the range until the user
    // scrolled, which is precisely when they would not. The same read is
    // what places the thumb, which has nothing to stand on before it.
    // No-op on the server (stub `scheduleNextFrame`), which is correct:
    // nothing has been scrolled or measured during a server render.
    scheduleNextFrame(_attach);
  }

  /// Reads the root once and starts following its size: the root's own box
  /// and the boxes of what it holds, since a capped root keeps its size
  /// while the content inside it grows, and it is the content that decides
  /// how long the thumb is.
  void _attach() {
    if (!mounted) return;
    _handleMeasure();
    _detachResize ??= observeScrollContentResize(_rootId, _handleMeasure);
  }

  /// Re-reads the root's scroll geometry by id and republishes it. Only the
  /// mount-time read and the resize observer need the lookup: a scroll
  /// event carries the element itself, and taking it from the event is
  /// exact where an id lookup would find the wrong node if a caller ever
  /// passed a duplicate [Scrollbar.id].
  void _handleMeasure() {
    if (!mounted) return;
    _publishViewport(readScrollbarViewport(_rootId));
  }

  /// Republishes [_viewport] from a reading of the root's live scroll
  /// geometry. A null [geometry] means the node could not be read at all,
  /// which is not the same as a position of zero — the last published value
  /// stands. An unchanged reading does not rebuild.
  void _publishViewport(ScrollbarViewportGeometry? geometry) {
    if (geometry == null || geometry == _viewport) return;
    setState(() => _viewport = geometry);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _pageTimer?.cancel();
    _detachResize?.call();
    _detachDrag?.call();
    super.dispose();
  }

  /// Shows the thumb on scroll activity and re-arms the idle timeout that
  /// hides it again (Flutter `RawScrollbar` timeToFade parity). The fade
  /// itself is a CSS transition over `CoreScrollbarContract.fadeDurationMs`.
  void handleScroll() {
    if (!_fades) return;
    _idleTimer?.cancel();
    if (!_shown) setState(() => _shown = true);
    _armIdleTimeout();
  }

  void _armIdleTimeout() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(milliseconds: CoreScrollbarContract.timeToFadeMs),
      () {
        // A held thumb stays shown; releasing it re-arms this.
        if (!mounted || _draggingAxis != null) return;
        setState(() => _shown = false);
      },
    );
  }

  // ─── Pointer: dragging the thumb ────────────────────────────────────

  /// The thumbs for a fresh reading of the scroller — the behaviour twin of
  /// what was drawn, derived from the same style and margins.
  ({CoreScrollbarThumbLayout? vertical, CoreScrollbarThumbLayout? horizontal})
  _thumbsNow(ScrollbarViewportGeometry viewport) {
    return resolveScrollbarThumbs(
      context,
      axis: component.axis,
      visibility: component.visibility,
      viewport: viewport,
      scrollbarStyle: component.scrollbarStyle,
    );
  }

  /// Presses [axis]'s thumb: from here until release, moving the pointer
  /// along the track moves the content in proportion.
  void _handleThumbDown(CoreScrollbarAxis axis, Object event, Object? target) {
    if (!component.interactive) return;
    final viewport = readScrollbarViewport(_rootId);
    if (viewport == null) return;
    final thumbs = _thumbsNow(viewport);
    final layout = axis == .vertical ? thumbs.vertical : thumbs.horizontal;
    final start = axis == .vertical ? mouseClientY(event) : mouseClientX(event);
    if (layout == null || start == null) return;

    // Without this the press starts a text selection under the pointer.
    preventDefault(event);

    // A horizontal box runs its pointer and its scroll position in opposite
    // senses when it lays out right to left.
    final rtl = axis == .horizontal && isElementRtl(target);
    final fromOffset = axis == .vertical
        ? viewport.scrollTop
        : viewport.scrollLeft.abs();

    _detachDrag?.call();
    _pageTimer?.cancel();
    _idleTimer?.cancel();
    setState(() {
      _draggingAxis = axis;
      _shown = true;
    });
    _detachDrag = registerDragListeners(
      downEvent: event,
      onMove: (move) {
        final now = axis == .vertical ? mouseClientY(move) : mouseClientX(move);
        if (now == null) return;
        final delta = (now - start) * (rtl ? -1 : 1);
        final offset = layout.scrollOffsetAfterDrag(
          fromScrollOffset: fromOffset,
          thumbDelta: delta,
        );
        _scrollAxisTo(axis, offset, rtl: rtl);
      },
      onUp: (_) => _endDrag(),
    );
  }

  void _endDrag() {
    _detachDrag = null;
    if (!mounted) return;
    setState(() => _draggingAxis = null);
    if (_fades) _armIdleTimeout();
  }

  /// Moves the content along [axis] to [offset] — a distance from the start
  /// edge, which is negative `scrollLeft` in a right-to-left box.
  void _scrollAxisTo(
    CoreScrollbarAxis axis,
    double offset, {
    bool rtl = false,
  }) {
    if (axis == .vertical) {
      scrollElementTo(_rootId, y: offset);
    } else {
      scrollElementTo(_rootId, x: rtl ? -offset : offset);
    }
  }

  // ─── Pointer: tapping the track ─────────────────────────────────────

  /// Pages the content toward a tap on [axis]'s track — Flutter's
  /// `RawScrollbar` does the same for a mouse (touch has no pointer to page
  /// with, so it leaves the track alone).
  void _handleTrackDown(CoreScrollbarAxis axis, Object event, Object? target) {
    if (!component.interactive || pointerTypeOf(event) == 'touch') return;
    final viewport = readScrollbarViewport(_rootId);
    final rect = elementRect(target);
    if (viewport == null || rect == null) return;
    final thumbs = _thumbsNow(viewport);
    final layout = axis == .vertical ? thumbs.vertical : thumbs.horizontal;
    final pointer = axis == .vertical
        ? mouseClientY(event)
        : mouseClientX(event);
    if (layout == null || pointer == null) return;

    final rtl = axis == .horizontal && isElementRtl(target);
    final along = axis == .vertical
        ? pointer - rect.top
        : (rtl ? rect.left + rect.width - pointer : pointer - rect.left);
    final from = axis == .vertical
        ? viewport.scrollTop
        : viewport.scrollLeft.abs();
    final to = layout.scrollOffsetAfterTrackTap(
      fromScrollOffset: from,
      trackOffset: along,
      viewportExtent: axis == .vertical
          ? viewport.clientHeight
          : viewport.clientWidth,
      pageFraction: CoreScrollbarContract.trackTapPageFraction,
    );

    preventDefault(event);
    _pageScroll(axis, from, to, rtl: rtl);
  }

  /// Eases the content from [from] to [to] over
  /// `CoreScrollbarContract.trackTapDurationMs`, the way the Flutter bar
  /// eases its page rather than jumping.
  void _pageScroll(
    CoreScrollbarAxis axis,
    double from,
    double to, {
    required bool rtl,
  }) {
    _pageTimer?.cancel();
    final steps =
        CoreScrollbarContract.trackTapDurationMs ~/
        _kPageScrollFrame.inMilliseconds;
    var step = 0;
    _pageTimer = Timer.periodic(_kPageScrollFrame, (timer) {
      step += 1;
      final t = (step / steps).clamp(0.0, 1.0);
      // Smoothstep: the ease-in-out the Flutter bar uses, to within a pixel
      // over a page.
      final eased = t * t * (3 - 2 * t);
      _scrollAxisTo(axis, from + (to - from) * eased, rtl: rtl);
      if (t >= 1) timer.cancel();
    });
  }

  // ─── Accessibility ──────────────────────────────────────────────────

  /// Builds the phantom `role="scrollbar"` node for one axis — visually
  /// hidden (`sr-only`) but present in the accessibility tree, since the
  /// drawn thumb is not a node a role can sit on (it is `aria-hidden`: the
  /// content it moves is the scroller itself, and reassigning the scroller's
  /// role would swallow its real content's semantics). `aria-controls`
  /// points back at the scrollable root so assistive tech can associate the
  /// two.
  ///
  /// A non-[Scrollbar.interactive] bar states `aria-disabled` — the Web
  /// spelling of the Flutter twin dropping `onIncrease` / `onDecrease`
  /// from its slider-shaped node. Both refuse to advertise an operation
  /// on the bar, though they refuse differently: Flutter removes actions
  /// it would otherwise perform, while this is an assertion about an
  /// affordance that carries no action either way.
  ///
  /// Neither disables *scrolling* — `interactive` has never meant that on
  /// either platform.
  ///
  /// This node carries no `tabindex` and no key handlers **and should
  /// not**: it is `sr-only`, so focusing it would land keyboard focus on
  /// a 1px clipped element with no visible indicator (WCAG 2.4.7). A tab
  /// stop nobody can see is not the Flutter twin's affordance ported —
  /// it is a second bug.
  ///
  /// That does leave a real asymmetry, and it is not this node's to
  /// close. Flutter's increase/decrease gives assistive tech a way to
  /// move the position; on Web the equivalent is the browser scrolling
  /// the `overflow: auto` root from the keyboard, which requires that
  /// root to be focusable. Chromium (focusable scrollers) and Firefox
  /// do that on their own; WebKit does not, and this component adds no
  /// `tabindex` of its own — so keyboard reach is engine-dependent for a
  /// region whose content holds nothing else focusable. That gap belongs
  /// to the scroll container, not to the phantom node, and is recorded
  /// where the container is documented rather than papered over here.
  Component _buildScrollbarRoleNode({
    required String orientation,
    required int percent,
    required String controlsId,
  }) {
    return Component.element(
      tag: 'div',
      classes: WebLayout.srOnly,
      attributes: {
        'role': CoreSemanticRole.scrollbar.ariaRole,
        'aria-orientation': orientation,
        'aria-valuenow': '$percent',
        'aria-valuemin': '$kScrollbarPercentMin',
        'aria-valuemax': '$kScrollbarPercentMax',
        'aria-controls': controlsId,
        if (!component.interactive) 'aria-disabled': 'true',
      },
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  /// One axis's drawn bar: the track strip a tap pages by, then the thumb
  /// (hit area + capsule) that follows it — in that order, because the
  /// scoped CSS reaches the thumb from a hovered track with `+`.
  List<Component> _buildAxis(
    CoreScrollbarAxis axis, {
    required WebElementChrome? track,
    required WebElementChrome? thumb,
    required WebElementChrome? capsule,
  }) {
    if (track == null || thumb == null || capsule == null) return const [];

    return [
      Component.element(
        tag: 'div',
        classes: track.className,
        styles: track.inlineStyles,
        attributes: const {'aria-hidden': 'true'},
        events: {
          'pointerdown': EventHandlers.createElementTargetEventHandler(
            (event, target) => _handleTrackDown(axis, event, target),
          ),
        },
      ),
      Component.element(
        tag: 'div',
        classes: thumb.className,
        styles: thumb.inlineStyles,
        attributes: const {'aria-hidden': 'true'},
        events: {
          'pointerdown': EventHandlers.createElementTargetEventHandler(
            (event, target) => _handleThumbDown(axis, event, target),
          ),
        },
        children: [
          Component.element(tag: 'div', classes: capsule.className),
        ],
      ),
    ];
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis
    // (`WebResolvedChrome` contract). The widget reads each slot directly —
    // no chrome composition in the widget body. The scoped `<style>`
    // payload is composed by the separate `resolveScrollbarCss` entry
    // point (Category C pattern): it walks the same merge chain and folds
    // in the runtime scope id so `ResolvedScrollbar` stays pure
    // paint-ready chrome.
    final viewport = _viewport;
    final resolved = resolveScrollbar(
      context,
      axis: component.axis,
      visibility: component.visibility,
      interactive: component.interactive,
      scrollbarStyle: component.scrollbarStyle,
      viewport: viewport,
      shown: _shown,
      draggingAxis: _draggingAxis,
    );
    // Caller id wins (passthrough) and also scopes the `<style>`
    // selectors; else the generated per-instance scope id keeps it unique.
    final scopeId = _rootId;
    final scopedStyle = resolveScrollbarCss(
      context,
      axis: component.axis,
      visibility: component.visibility,
      interactive: component.interactive,
      scopeId: scopeId,
      scrollbarStyle: component.scrollbarStyle,
    );

    // Scroll listener composes with (never replaces) a caller-supplied
    // one. The geometry re-read runs unconditionally so the thumb and
    // `aria-valuenow` on the phantom `role` node(s) below stay live
    // regardless of visibility.
    final events = Map<String, EventCallback>.of(component.events);
    final callerScroll = events['scroll'];
    events['scroll'] = EventHandlers.createElementTargetEventHandler((
      event,
      target,
    ) {
      _publishViewport(readScrollbarViewportOf(target));
      handleScroll();
      callerScroll?.call(event);
    });

    final percents = viewport == null
        ? (vertical: kScrollbarPercentMin, horizontal: kScrollbarPercentMin)
        : scrollbarPercentsOf(viewport);
    final layer = resolved.layer;

    return Component.element(
      tag: 'div',
      id: scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: events,
      children: [
        // The native scrollbar is hidden and the thumb is drawn over the
        // content, with rules a `<style>` tag has to carry: the pseudo
        // element that hides the native bar cannot be targeted by inline
        // style, and every rule pins to the unique scope id. The payload
        // itself is composed by `resolveScrollbarCss` so the widget stays
        // free of chrome composition.
        Component.element(
          tag: 'style',
          children: [RawText(scopedStyle)],
        ),
        // Phantom `role="scrollbar"` node(s) — one per axis this bar
        // actually reports on. `aria-controls` points back at this same
        // element's `scopeId`: the drawn thumb is a decorative box with no
        // role of its own, and reassigning the root's own role would
        // swallow its real content's semantics (matches the Flutter
        // twin's phantom slider-shaped `Semantics` sibling).
        //
        // Gated on `axis` and nothing else — `visibility` deliberately
        // does not reach here. `hidden` draws no thumb but keeps the
        // area scrolling, so the position stays real and stays the only
        // cue a screen-reader user has (there is no thumb to look at).
        // These nodes render no pixels in any mode, so there was never
        // anything for `hidden` to hide.
        if (component.axis == .vertical || component.axis == .both)
          _buildScrollbarRoleNode(
            orientation: 'vertical',
            percent: percents.vertical,
            controlsId: scopeId,
          ),
        if (component.axis == .horizontal || component.axis == .both)
          _buildScrollbarRoleNode(
            orientation: 'horizontal',
            percent: percents.horizontal,
            controlsId: scopeId,
          ),
        // The thumbs. A sticky, zero-height layer: it takes no space in the
        // content's layout, and sticks to the corner of the visible area as
        // the content scrolls under it.
        if (layer != null)
          Component.element(
            tag: 'div',
            classes: layer.className,
            attributes: const {'aria-hidden': 'true'},
            children: [
              ..._buildAxis(
                .vertical,
                track: resolved.verticalTrack,
                thumb: resolved.verticalThumb,
                capsule: resolved.verticalCapsule,
              ),
              ..._buildAxis(
                .horizontal,
                track: resolved.horizontalTrack,
                thumb: resolved.horizontalThumb,
                capsule: resolved.horizontalCapsule,
              ),
            ],
          ),
        ?component.child,
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Scrollbar.withStyle` extension —
/// merges a [CoreScrollbarStyle] patch into [Scrollbar.scrollbarStyle] via
/// the existing [Scrollbar.copyWith].
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
