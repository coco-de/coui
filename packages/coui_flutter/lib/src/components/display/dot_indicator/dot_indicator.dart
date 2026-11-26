import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

/// Hover scale factor for a clickable dot.
const _kHoverScale = 1.1;

/// Unified cross-platform dot indicator with token-based rendering.
///
/// Displays a series of dots representing items in a sequence,
/// with one dot highlighted to show the current position.
/// Commonly used with carousels, page views, and stepper interfaces.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [dotIndicatorStyle] slot. Behavioural fields (`index`,
/// `length`, `onChanged`, `direction`) and the semantic [size]
/// identifier stay flat on the widget.
///
/// Example:
/// ```dart
/// DotIndicator(
///   index: currentPage,
///   length: totalPages,
///   onChanged: (newIndex) => pageController.animateToPage(newIndex),
/// )
/// DotIndicator(index: 0, length: 3, size: CoreDotIndicatorSize.lg)
/// ```
class DotIndicator extends StatefulWidget
    implements CoreDotIndicatorContract<Widget> {
  /// Creates a [DotIndicator].
  const DotIndicator({
    required this.index,
    required this.length,
    super.key,
    this.onChanged,
    this.direction = CoreAxis.horizontal,
    this.size = CoreDotIndicatorSize.defaultSize,
    this.dotIndicatorStyle,
  });

  @override
  final int index;

  @override
  final int length;

  @override
  final CoreDotIndicatorOnChanged? onChanged;

  @override
  final CoreAxis direction;

  @override
  final CoreDotIndicatorSize size;

  @override
  final CoreDotIndicatorStyle? dotIndicatorStyle;

  /// Returns a copy of this [DotIndicator] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  DotIndicator copyWith({
    Key? key,
    CoreDotIndicatorOnChanged? onChanged,
    int? index,
    int? length,
    CoreAxis? direction,
    CoreDotIndicatorSize? size,
    CoreDotIndicatorStyle? dotIndicatorStyle,
  }) {
    return DotIndicator(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      index: index ?? this.index,
      length: length ?? this.length,
      direction: direction ?? this.direction,
      size: size ?? this.size,
      dotIndicatorStyle: dotIndicatorStyle ?? this.dotIndicatorStyle,
    );
  }

  @override
  State<DotIndicator> createState() => _DotIndicatorState();
}

/// Arrow-key intent moving the selection by [delta] (roving
/// radio-group model — the indicator is one tab stop and arrow keys
/// move both the selection and the focus ring).
class _MoveSelectionIntent extends Intent {
  const _MoveSelectionIntent(this.delta);

  final int delta;
}

class _DotIndicatorState extends State<DotIndicator> {
  /// Whether the indicator group currently shows its keyboard-focus
  /// highlight — the ring paints around the selected dot only.
  bool _groupFocused = false;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDotIndicator(
      context,
      size: widget.size,
      dotIndicatorStyle: widget.dotIndicatorStyle,
    );
    final interactive = widget.onChanged != null && widget.length > 0;
    final children = <Widget>[];
    for (var i = 0; i < widget.length; i += 1) {
      final horizontal = widget.direction == CoreAxis.horizontal;
      final topPadding = horizontal || i == 0
          ? resolved.padding.top
          : (resolved.spacing / 2);
      final bottomPadding = horizontal || i == widget.length - 1
          ? resolved.padding.bottom
          : (resolved.spacing / 2);
      final leftToRight = Directionality.of(context) == TextDirection.ltr;
      final leftEdge = leftToRight ? i == 0 : i == widget.length - 1;
      final rightEdge = leftToRight ? i == widget.length - 1 : i == 0;
      final leftPadding = !horizontal || leftEdge
          ? resolved.padding.left
          : (resolved.spacing / 2);
      final rightPadding = !horizontal || rightEdge
          ? resolved.padding.right
          : (resolved.spacing / 2);
      final itemPadding = EdgeInsets.only(
        left: leftPadding,
        top: topPadding,
        right: rightPadding,
        bottom: bottomPadding,
      );
      final dot = i == widget.index
          ? _ActiveDotItem(resolved: resolved, direction: widget.direction)
          : _InactiveDotItem(resolved: resolved, interactive: interactive);
      children.add(
        Flexible(
          // Mirrors the Web twin's `role="tab"` + `aria-label` +
          // `aria-current` on each dot (dot_indicator.dart:121-124) —
          // without this, Flutter's dots were unnamed and their
          // selection state invisible to assistive tech, worse than a
          // hardcoded label (there was nothing to read at all).
          child: MergeSemantics(
            child: Semantics(
              label: CoUILocalizations.of(context).dotIndicatorGoToItem(i + 1),
              button: interactive,
              selected: i == widget.index,
              // The group is the single tab stop (roving radio-group
              // model) — per-dot Clickables stay pointer targets but are
              // excluded from focus traversal, and their own hit-box-shaped
              // focus ring is disabled: the ring is the circular
              // `FocusOutline` around the selected dot below.
              child: ExcludeFocus(
                child: TouchTarget(
                  child: Clickable(
                    onPressed: interactive ? () => widget.onChanged!(i) : null,
                    focusOutline: false,
                    child: Padding(
                      padding: itemPadding,
                      child: i == widget.index
                          ? FocusOutline(
                              focused: _groupFocused,
                              shape: .circle,
                              focusOutlineStyle: resolved.focusOutlineStyle,
                              child: dot,
                            )
                          : dot,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final indicator = _NaturalDotFlex(
      direction: widget.direction.toValue(),
      child: Flex(
        direction: widget.direction.toValue(),
        mainAxisSize: .min,
        children: children,
      ),
    );

    // Mirrors the Web twin's `role="tablist"` + `aria-label` on the
    // group root (dot_indicator.dart:153-154).
    final containerLabel = CoUILocalizations.of(context).dotIndicatorLabel;

    if (!interactive) {
      if (widget.length == 0) return ExcludeSemantics(child: indicator);
      return Semantics(
        container: true,
        label: CoUILocalizations.of(context).dotIndicatorPosition(
          widget.index + 1,
          widget.length,
        ),
        excludeSemantics: true,
        child: indicator,
      );
    }

    final horizontal = widget.direction == .horizontal;
    return Semantics(
      container: true,
      label: containerLabel,
      child: FocusableActionDetector(
        shortcuts: {
          LogicalKeySet(horizontal ? .arrowRight : .arrowDown):
              const _MoveSelectionIntent(1),
          LogicalKeySet(horizontal ? .arrowLeft : .arrowUp):
              const _MoveSelectionIntent(-1),
        },
        actions: {
          _MoveSelectionIntent: CallbackAction<_MoveSelectionIntent>(
            onInvoke: (intent) {
              final next = (widget.index + intent.delta).clamp(
                0,
                widget.length - 1,
              );
              if (next != widget.index) widget.onChanged!(next);
              return null;
            },
          ),
        },
        onShowFocusHighlight: (focused) =>
            setState(() => _groupFocused = focused),
        child: indicator,
      ),
    );
  }
}

class _ActiveDotItem extends StatelessWidget {
  const _ActiveDotItem({required this.resolved, required this.direction});

  final ResolvedDotIndicator resolved;
  final CoreAxis direction;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      decoration: BoxDecoration(
        color: resolved.activeColor,
        borderRadius: resolved.borderRadius,
      ),
      width: direction == CoreAxis.vertical
          ? resolved.dotSize
          : resolved.activeLength,
      height: direction == CoreAxis.vertical
          ? resolved.activeLength
          : resolved.dotSize,
      duration: resolved.transitionDuration,
      curve: resolved.curve,
    );
  }
}

class _InactiveDotItem extends StatefulWidget {
  const _InactiveDotItem({required this.resolved, required this.interactive});

  final ResolvedDotIndicator resolved;
  final bool interactive;

  @override
  State<_InactiveDotItem> createState() => _InactiveDotItemState();
}

class _InactiveDotItemState extends State<_InactiveDotItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    final isClickable = widget.interactive;
    final isHovered = isClickable && _hovered;
    // The border pair still selects, for callers who state a width — the
    // shipped `inactiveBorderWidth` is zero, so by default what a hovered
    // dot shows is its scale step.
    final borderColor = isHovered
        ? resolved.hoverBorderColor
        : resolved.inactiveBorderColor;

    return MouseRegion(
      onEnter: isClickable ? (_) => setState(() => _hovered = true) : null,
      onExit: isClickable ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedScale(
        scale: isHovered ? _kHoverScale : 1.0,
        duration: resolved.transitionDuration,
        curve: resolved.curve,
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: resolved.inactiveColor,
            // A zero-width solid BorderSide is a device-pixel hairline,
            // unlike CSS border-width: 0. Omit the border for a filled dot.
            border: resolved.inactiveBorderWidth > 0
                ? Border.all(
                    color: borderColor,
                    width: resolved.inactiveBorderWidth,
                  )
                : null,
            borderRadius: resolved.borderRadius,
          ),
          width: resolved.dotSize,
          height: resolved.dotSize,
          duration: resolved.transitionDuration,
          curve: resolved.curve,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreDotIndicatorStyle] patch into
/// [DotIndicator.dotIndicatorStyle] without hand-reconstructing every
/// field. Mirrors the Web `DotIndicator.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDotIndicatorStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreDotIndicatorStyle.borderRadius]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// DotIndicator(index: 0, length: 3).radius4
/// ```
extension DotIndicatorStyleChain on DotIndicator {
  /// Returns a copy of this [DotIndicator] with [patch] merged into
  /// [dotIndicatorStyle] (patch fields win on conflict).
  DotIndicator withStyle(CoreDotIndicatorStyle patch) => copyWith(
    dotIndicatorStyle: (dotIndicatorStyle ?? const CoreDotIndicatorStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  DotIndicator get radius0 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  DotIndicator get radius2 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  DotIndicator get radius4 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  DotIndicator get radius6 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  DotIndicator get radius8 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  DotIndicator get radius10 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  DotIndicator get radius12 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  DotIndicator get radius14 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  DotIndicator get radius16 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  DotIndicator get radius20 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  DotIndicator get radius24 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  DotIndicator get radius28 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  DotIndicator get radius32 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  DotIndicator get radius36 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  DotIndicator get radius40 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  DotIndicator get radius48 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  DotIndicator get radius56 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  DotIndicator get radius64 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  DotIndicator get radius9999 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}

// A bounded Flex caps each loose child equally before summing its size.
// The outer padding can make edge slots larger than the interior ones,
// even when their natural sum fits. Let Flex use its non-flex pass in
// that case and preserve its existing bounded layout otherwise.
class _NaturalDotFlex extends SingleChildRenderObjectWidget {
  const _NaturalDotFlex({required this.direction, required super.child});

  final Axis direction;

  @override
  _RenderNaturalDotFlex createRenderObject(BuildContext context) =>
      _RenderNaturalDotFlex(direction);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNaturalDotFlex renderObject,
  ) {
    renderObject.direction = direction;
  }
}

class _RenderNaturalDotFlex extends RenderProxyBox {
  _RenderNaturalDotFlex(this._direction);

  Axis _direction;

  Axis get direction => _direction;

  set direction(Axis value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints incoming) {
    final relaxed = direction == Axis.horizontal
        ? incoming.copyWith(maxWidth: double.infinity)
        : incoming.copyWith(maxHeight: double.infinity);
    // Read the child's current animated dimensions rather than a resolved
    // target that may already fit while the old size is still shrinking.
    final natural = child!.getDryLayout(relaxed);
    final fits = direction == Axis.horizontal
        ? natural.width <= incoming.maxWidth
        : natural.height <= incoming.maxHeight;
    return fits ? relaxed : incoming;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child!.getDryLayout(_childConstraints(constraints));

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => child!.getDryBaseline(_childConstraints(constraints), baseline);

  @override
  void performLayout() {
    child!.layout(_childConstraints(constraints), parentUsesSize: true);
    assert(constraints.isSatisfiedBy(child!.size), 'The child must fit.');
    size = child!.size;
  }
}
