import 'package:coui_flutter/coui_flutter.dart';

/// Wraps any [child] in a scrollable viewport with a design-system
/// styled scrollbar.
///
/// Mirrors the Web `ScrollArea` 1:1: same `direction` enum, same
/// `height` / `maxHeight` / nested `scrollbarStyle` resolution (via
/// [scrollAreaStyle]), and the same `showScrollbar` toggle. The child can be any widget (e.g. a
/// `Column`, a `Row`, or a `Text`); `ScrollArea` wraps it in a
/// `SingleChildScrollView` that scrolls along [direction] when the
/// child overflows.
///
/// Unlike `FadeScroll` (which masks the edges with a gradient),
/// `ScrollArea` keeps the content fully visible and lets the slim
/// scrollbar communicate the overflow.
///
/// ```dart
/// ScrollArea(
///   scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 400),
///   child: Column(
///     children: [for (var i = 0; i < 20; i++) Text('Item $i')],
///   ),
/// )
/// ```
///
/// An external [controller] is optional — supply one when the caller
/// needs to drive the scroll position from elsewhere; otherwise
/// `ScrollArea` creates and owns its own `ScrollController`.
///
/// All chrome / dimensional overrides (height / maxHeight, plus the
/// composed scrollbar's chrome through the nested `scrollbarStyle`
/// slot) flow through [scrollAreaStyle] — see [CoreScrollAreaStyle].
class ScrollArea extends StatefulWidget
    implements CoreScrollAreaContract<Widget> {
  /// Creates a [ScrollArea].
  const ScrollArea({
    required this.child,
    super.key,
    this.controller,
    this.direction = CoreScrollAreaDirection.defaultDirection,
    this.showScrollbar = true,
    this.scrollAreaStyle,
  });

  @override
  final Widget child;

  /// Flutter-only scroll controller. Web mirrors the scroll position
  /// natively via the inner `<div>` and has no equivalent.
  final ScrollController? controller;

  @override
  final CoreScrollAreaDirection direction;

  @override
  final bool showScrollbar;

  @override
  final CoreScrollAreaStyle? scrollAreaStyle;

  /// Returns a copy of this [ScrollArea] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ScrollArea copyWith({
    Key? key,
    ScrollController? controller,
    CoreScrollAreaDirection? direction,
    bool? showScrollbar,
    CoreScrollAreaStyle? scrollAreaStyle,
    Widget? child,
  }) {
    return ScrollArea(
      key: key ?? this.key,
      controller: controller ?? this.controller,
      direction: direction ?? this.direction,
      showScrollbar: showScrollbar ?? this.showScrollbar,
      scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<ScrollArea> createState() => _ScrollAreaState();
}

class _ScrollAreaState extends State<ScrollArea> {
  ScrollController? _ownedController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownedController ??= ScrollController());

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveScrollArea(
      context,
      scrollAreaStyle: widget.scrollAreaStyle,
    );

    final controller = _effectiveController;
    final axis = widget.direction == .horizontal
        ? Axis.horizontal
        : Axis.vertical;

    final Widget scrollView = SingleChildScrollView(
      scrollDirection: axis,
      controller: controller,
      child: widget.child,
    );

    // Composes the unified `Scrollbar` — its chrome flows through the
    // resolved nested `scrollbarStyle` slot (raw-forward; the
    // scrollbar's own resolver applies scaling / token resolution),
    // mirroring the Web twin which composes the same component.
    // `always` keeps the thumb persistently visible, matching the Web
    // classic scrollbar that shows whenever content overflows; `hidden`
    // keeps the area scrollable without a thumb (the composed scrollbar
    // also strips the ambient platform-default scrollbar either way).
    final Widget scrolled = Scrollbar(
      axis: widget.direction == .horizontal ? .horizontal : .vertical,
      visibility: widget.showScrollbar ? .always : .hidden,
      controller: controller,
      scrollbarStyle: resolved.scrollbarStyle,
      child: scrollView,
    );

    // Apply height / maxHeight constraints. `tightFor` produces a fixed
    // dimension when `height` is set; `maxHeight` adds an upper bound
    // when both are unset / partially set. Mirrors the Web semantics
    // (`height: ${px}px` + `max-height: ${px}px`).
    final BoxConstraints? constraints;
    if (resolved.height != null || resolved.maxHeight != null) {
      constraints = BoxConstraints(
        minHeight: 0,
        maxHeight: resolved.height ?? resolved.maxHeight ?? .infinity,
      );
    } else {
      constraints = null;
    }

    if (constraints == null) {
      return scrolled;
    }
    return ConstrainedBox(
      constraints: constraints,
      child: scrolled,
    );
  }
}

/// Chain sugar for merging a [CoreScrollAreaStyle] patch into
/// [ScrollArea.scrollAreaStyle] without hand-reconstructing every field.
/// Mirrors the Web `ScrollArea.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreScrollAreaStyle.merge` right-side-wins semantics).
extension ScrollAreaStyleChain on ScrollArea {
  /// Returns a copy of this [ScrollArea] with [patch] merged into
  /// [scrollAreaStyle] (patch fields win on conflict).
  ScrollArea withStyle(CoreScrollAreaStyle patch) => copyWith(
    scrollAreaStyle: (scrollAreaStyle ?? const CoreScrollAreaStyle()).merge(
      patch,
    ),
  );
}
