import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/layout_gated_selection.dart';

/// `ScrollBehavior` override that suppresses the platform default scrollbar
/// when the host `FadeScroll` has `showScrollbar: false`.
///
/// It replaces the ambient behavior rather than deriving from it, so the
/// layout gate the ambient behavior puts in a scrollable's chrome is not
/// there — this one puts it back in the seat the scrollbar would take, so
/// text inside a fade that a covered page built is not sorted before it
/// has been laid out (#5361). Nothing about scrolling changes.
class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return LayoutGatedSelectionScope(child: child);
  }
}

/// Wraps any [child] in an automatic scrollable viewport with a soft fade
/// gradient on the scroll edges that toggles dynamically with scroll
/// position.
///
/// Mirrors the Web behaviour where a `<div style="overflow: auto">`
/// scrolls automatically without the caller wiring a `ListView` or a
/// `ScrollController`. The [child] can be any widget (e.g. a `Column`, a
/// `Row`, or a simple `Container`); `FadeScroll` wraps it in a
/// `SingleChildScrollView` that scrolls along [direction] when the
/// child overflows.
///
/// When [showScrollbar] is `true` the design-system [Scrollbar]
/// (the same `RawScrollbar`-based skin used by `ScrollableClient`)
/// is rendered alongside the fade so both Web and Flutter share the
/// same thumb appearance.
///
/// ```dart
/// FadeScroll(
///   child: Column(
///     children: [for (var i = 0; i < 20; i++) Text('Item $i')],
///   ),
/// )
/// ```
///
/// An external [controller] is optional — supply one when the caller
/// needs to drive the scroll position from elsewhere; otherwise
/// `FadeScroll` creates and owns its own `ScrollController`.
///
/// All chrome / dimensional overrides (start/end offsets, gradient
/// stops) flow through [fadeScrollStyle] — see [CoreFadeScrollStyle].
class FadeScroll extends StatefulWidget
    implements CoreFadeScrollContract<Widget> {
  /// Creates a [FadeScroll].
  const FadeScroll({
    required this.child,
    super.key,
    this.controller,
    this.direction = CoreFadeScrollDirection.defaultDirection,
    this.showScrollbar = false,
    this.fadeScrollStyle,
  });

  @override
  final Widget child;

  /// Flutter-only scroll controller. Web mirrors the scroll position
  /// natively via the inner `<div>` and has no equivalent.
  final ScrollController? controller;

  @override
  final CoreFadeScrollDirection direction;

  @override
  final bool showScrollbar;

  @override
  final CoreFadeScrollStyle? fadeScrollStyle;

  /// Returns a copy of this [FadeScroll] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FadeScroll copyWith({
    Key? key,
    ScrollController? controller,
    CoreFadeScrollDirection? direction,
    bool? showScrollbar,
    CoreFadeScrollStyle? fadeScrollStyle,
    Widget? child,
  }) {
    return FadeScroll(
      key: key ?? this.key,
      controller: controller ?? this.controller,
      direction: direction ?? this.direction,
      showScrollbar: showScrollbar ?? this.showScrollbar,
      fadeScrollStyle: fadeScrollStyle ?? this.fadeScrollStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<FadeScroll> createState() => _FadeScrollState();
}

class _FadeScrollState extends State<FadeScroll> {
  ScrollController? _ownedController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownedController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    // After the first frame the inner scrollable will have attached to
    // the controller; force one rebuild so the fade gradient picks up
    // the now-valid `position.maxScrollExtent` and `viewportDimension`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFadeScroll(
      context,
      fadeScrollStyle: widget.fadeScrollStyle,
    );
    final effectiveStart = resolved.startOffset;
    final effectiveEnd = resolved.endOffset;
    final gradient = resolved.gradient;

    final ctrl = _effectiveController;
    final axis = widget.direction == .horizontal
        ? Axis.horizontal
        : Axis.vertical;

    final scrollView = SingleChildScrollView(
      scrollDirection: axis,
      controller: ctrl,
      child: widget.child,
    );

    final scrollable = ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!ctrl.hasClients ||
            !ctrl.position.hasContentDimensions ||
            !ctrl.position.hasViewportDimension) {
          return scrollView;
        }
        final position = ctrl.position.pixels;
        final max = ctrl.position.maxScrollExtent;
        final min = ctrl.position.minScrollExtent;
        final size = ctrl.position.viewportDimension;
        final shouldFadeStart = position > min;
        final shouldFadeEnd = position < max;

        if (!shouldFadeStart && !shouldFadeEnd) return scrollView;

        // The mask composites the whole subtree, so under an app-wide
        // `SelectionArea` the selection highlight — painted by each
        // `RenderParagraph` in this subtree — fades with the glyphs it
        // sits behind. That is deliberate: the Web twin masks its viewport
        // with CSS `mask-image`, and browsers mask `::selection` with the
        // element the same way, so both platforms show the same ramp.
        //
        // Two alternatives were measured and rejected:
        // - `SelectionContainer.disabled` around the mask removes the
        //   artifact by removing selection — and only while the content
        //   overflows, so text would stop being copyable the moment it
        //   scrolls, and Web would still select it.
        // - Painting the highlight outside the mask (what
        //   flutter/flutter#183628 does inside `RenderParagraph` for
        //   `TextOverflow.fade`) is not needed here: that fix removes dark
        //   seams from a saveLayer that composited the highlight, and this
        //   `dstIn` mask produces none — it only scales alpha. Keeping the
        //   highlight unmasked would leave a solid bar over faded-out text
        //   and diverge from Web.
        // `fade_scroll_selection_test.dart` pins this against a masked solid
        // block, row by row.
        return ShaderMask(
          shaderCallback: (bounds) {
            final isHorizontal = widget.direction == .horizontal;
            final start = isHorizontal
                ? Alignment.centerLeft
                : Alignment.topCenter;
            final end = isHorizontal
                ? Alignment.centerRight
                : Alignment.bottomCenter;
            final relativeStart = effectiveStart / size;
            final relativeEnd = 1 - effectiveEnd / size;
            // Build a 4-stop mask. The mask is monochrome (only alpha
            // matters); `BlendMode.dstIn` keeps the child only where
            // the mask alpha is non-zero. Resolved gradient stops are
            // taken from [CoreFadeScrollStyle.defaultGradient] (or any
            // override) — for the default `[onSurface, transparent]`
            // ramp this means the visible edge is opaque (child shown)
            // and the outer edge is transparent (child masked away).
            final stops = [
              0.0,
              if (shouldFadeStart) relativeStart else 0.0,
              if (shouldFadeEnd) relativeEnd else 1.0,
              1.0,
            ];
            final opaqueEdge = gradient.first;
            final fadedEdge = gradient.last;
            final colors = [
              if (shouldFadeStart) fadedEdge else opaqueEdge,
              opaqueEdge,
              opaqueEdge,
              if (shouldFadeEnd) fadedEdge else opaqueEdge,
            ];
            return LinearGradient(
              begin: start,
              end: end,
              colors: colors,
              stops: stops,
            ).createShader(bounds);
          },
          // `BlendMode.dstIn` keeps the child only where the mask is
          // opaque. Transparent stops in the gradient → child is
          // hidden. Mirrors the Web `mask-image` semantics.
          blendMode: .dstIn,
          child: scrollView,
        );
      },
    );

    final Widget scrollableWithScrollbar;
    if (widget.showScrollbar) {
      // `CoreScrollbarVisibility.auto` (default) — the design-system
      // scrollbar appears while the user is scrolling and fades out
      // afterwards, matching the macOS overlay scrollbar UX and the
      // Web native `overflow: auto` behaviour.
      scrollableWithScrollbar = Scrollbar(
        controller: ctrl,
        child: scrollable,
      );
    } else {
      // Override the inherited ScrollBehavior so the platform default
      // Scrollbar is not auto-attached. The fade gradient itself
      // communicates overflow when `showScrollbar` is false.
      scrollableWithScrollbar = ScrollConfiguration(
        behavior: const _NoScrollbarBehavior(),
        child: scrollable,
      );
    }
    // Horizontal `SingleChildScrollView` expands its cross-axis (height)
    // to fill the parent constraints by default. The Web side
    // (`<div overflow-x: auto>`) lays out at the child's natural height
    // instead, so without an `IntrinsicHeight` wrap a horizontal
    // FadeScroll renders visibly taller in Flutter than on the Web.
    if (axis == .horizontal) {
      return IntrinsicHeight(child: scrollableWithScrollbar);
    }
    return scrollableWithScrollbar;
  }
}

/// Chain sugar for merging a [CoreFadeScrollStyle] patch into
/// [FadeScroll.fadeScrollStyle] without hand-reconstructing every field.
/// Mirrors the Web `FadeScroll.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFadeScrollStyle.merge` right-side-wins semantics).
extension FadeScrollStyleChain on FadeScroll {
  /// Returns a copy of this [FadeScroll] with [patch] merged into
  /// [fadeScrollStyle] (patch fields win on conflict).
  FadeScroll withStyle(CoreFadeScrollStyle patch) => copyWith(
    fadeScrollStyle: (fadeScrollStyle ?? const CoreFadeScrollStyle()).merge(
      patch,
    ),
  );
}
