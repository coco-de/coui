import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Unified cross-platform join component for Flutter.
///
/// Groups children into a visually connected strip. Each item is
/// clipped with a position-aware radius, and an ambient [JoinItemData]
/// tells radius-bearing children (e.g. `Button`) to flatten their own
/// corners against the seams — the clip alone only crops outside the
/// wrapper, so a child's self-painted rounded corner would otherwise
/// remain as a notch (the Web twin overrides the child radius with a
/// scoped CSS rule the same way).
///
/// Uses [CoreJoinContract] from `coui_core` for consistent
/// cross-platform API. Chrome / dimensional overrides flow through
/// the single [joinStyle] slot per Epic #1302.
///
/// Example:
/// ```dart
/// Join(
///   children: [
///     Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('1')),
///     Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('2')),
///     Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('3')),
///   ],
/// )
/// ```
class Join extends StatelessWidget implements CoreJoinContract<Widget> {
  /// Creates a [Join].
  const Join({
    required this.children,
    this.vertical = false,
    this.joinStyle,
    super.key,
  });

  @override
  final List<Widget> children;

  @override
  final bool vertical;

  @override
  final CoreJoinStyle? joinStyle;

  /// Returns a copy of this [Join] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Join copyWith({
    Key? key,
    bool? vertical,
    CoreJoinStyle? joinStyle,
    List<Widget>? children,
  }) {
    return Join(
      key: key ?? this.key,
      vertical: vertical ?? this.vertical,
      joinStyle: joinStyle ?? this.joinStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveJoin(context, joinStyle: joinStyle);

    if (children.isEmpty) return const SizedBox.shrink();

    return _JoinStrip(
      borderRadius: resolved.borderRadius,
      coreBorderRadius: resolved.coreBorderRadius,
      itemOverlap: resolved.itemOverlap,
      vertical: vertical,
      children: children,
    );
  }
}

/// The strip itself — stateful so it can hold which item currently has
/// focus, which two separate things need:
///
/// - the focused item must stop clipping, or its focus ring (a band lying
///   entirely *outside* the item's box) is cropped away completely, and
/// - the focused item must paint last, or the next sibling paints over the
///   band on the shared seam.
///
/// Fixing only one of them leaves the ring half-visible.
class _JoinStrip extends StatefulWidget {
  const _JoinStrip({
    required this.borderRadius,
    required this.coreBorderRadius,
    required this.itemOverlap,
    required this.vertical,
    required this.children,
  });

  final BorderRadiusGeometry borderRadius;
  final CoreBorderRadius coreBorderRadius;
  final double itemOverlap;
  final bool vertical;
  final List<Widget> children;

  @override
  State<_JoinStrip> createState() => _JoinStripState();
}

class _JoinStripState extends State<_JoinStrip> {
  int? _focusedIndex;

  void _handleFocus(int index, {required bool focused}) {
    final next = focused
        ? index
        : (_focusedIndex == index ? null : _focusedIndex);
    if (next == _focusedIndex) return;
    setState(() => _focusedIndex = next);
  }

  /// Which corners of item [index] keep the join radius — the strip's
  /// outer end rounds, a side facing a neighbour squares.
  ///
  /// The choice is made once here and applied to both representations
  /// in [_itemData], so the paint-ready radius the child's chrome uses
  /// and the raw radius its focus ring scales can never disagree about
  /// which corner is square.
  ({bool topLeft, bool topRight, bool bottomLeft, bool bottomRight})
  _roundedCorners(int index) {
    // The strip's leading end (left, or top when vertical) rounds on the
    // first item, the trailing end on the last; a single item is both.
    final leading = index == 0;
    final trailing = index == widget.children.length - 1;
    final vertical = widget.vertical;

    return (
      topLeft: leading,
      topRight: vertical ? leading : trailing,
      bottomLeft: vertical ? trailing : leading,
      bottomRight: trailing,
    );
  }

  /// Position-aware [JoinItemData] for item [index] — the corner choice
  /// from [_roundedCorners] applied to the paint-ready [resolvedRadius]
  /// and to the raw join radius alike.
  JoinItemData _itemData(int index, BorderRadius resolvedRadius) {
    final rounded = _roundedCorners(index);
    final core = widget.coreBorderRadius;

    return JoinItemData(
      borderRadius: BorderRadius.only(
        topLeft: rounded.topLeft ? resolvedRadius.topLeft : Radius.zero,
        topRight: rounded.topRight ? resolvedRadius.topRight : Radius.zero,
        bottomLeft: rounded.bottomLeft
            ? resolvedRadius.bottomLeft
            : Radius.zero,
        bottomRight: rounded.bottomRight
            ? resolvedRadius.bottomRight
            : Radius.zero,
      ),
      coreBorderRadius: CoreBorderRadius.only(
        topLeft: rounded.topLeft ? core.topLeft : 0,
        topRight: rounded.topRight ? core.topRight : 0,
        bottomLeft: rounded.bottomLeft ? core.bottomLeft : 0,
        bottomRight: rounded.bottomRight ? core.bottomRight : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = widget.borderRadius.resolve(.ltr);

    final items = <Widget>[
      for (final (index, child) in widget.children.indexed)
        _JoinItem(
          data: _itemData(index, resolvedRadius),
          focused: _focusedIndex == index,
          onFocusChange: (focused) => _handleFocus(index, focused: focused),
          child: child,
        ),
    ];

    // Cross-axis stretch inside an intrinsic box equalises the item
    // widths (vertical) / heights (horizontal) — mirrors the Web
    // strip's flex default (align-items: stretch), so a strip like
    // A/B/C doesn't vary per-item with the label's glyph width.
    final flex = _JoinFlex(
      direction: widget.vertical ? Axis.vertical : Axis.horizontal,
      focusedIndex: _focusedIndex,
      itemOverlap: widget.itemOverlap,
      children: items,
    );

    final strip = _JoinOverlap(
      vertical: widget.vertical,
      total: widget.children.length < 2
          ? 0
          : widget.itemOverlap * (widget.children.length - 1),
      child: flex,
    );

    return widget.vertical
        ? IntrinsicWidth(child: strip)
        : IntrinsicHeight(child: strip);
  }
}

/// One strip member: ambient [JoinItemData] plus the clip, with the clip
/// *disabled* rather than removed while focused.
///
/// Swapping the `ClipRRect` out instead would change the child slot's
/// widget type, which fails `Widget.canUpdate` and remounts the subtree —
/// disposing the focus node the child just acquired, dropping focus to
/// null, and settling the ring at opacity 0. Toggling `clipBehavior` only
/// calls `markNeedsPaint`, so identity and focus survive.
class _JoinItem extends StatefulWidget {
  const _JoinItem({
    required this.data,
    required this.focused,
    required this.onFocusChange,
    required this.child,
  });

  final JoinItemData data;
  final bool focused;
  final ValueChanged<bool> onFocusChange;
  final Widget child;

  @override
  State<_JoinItem> createState() => _JoinItemState();
}

class _JoinItemState extends State<_JoinItem> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      // Watches its subtree without joining traversal itself. On a plain
      // `FocusNode` this does not stop descendants being focused — only
      // `FocusScope` would do that, which is why this must not be
      // "tidied" into one.
      canRequestFocus: false,
      // `onFocusChange` fires on every notify, not only on transitions, so
      // the parent compares before calling setState.
      onFocusChange: widget.onFocusChange,
      child: Data.inherit(
        data: widget.data,
        child: ClipRRect(
          borderRadius: widget.data.borderRadius,
          clipBehavior: widget.focused ? Clip.none : Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The strip as wide (tall) as what it paints: the flex inside lays its
/// children out edge to edge and pulls them back by the overlaps, so its
/// own box is [total] longer than its content.
///
/// The flex is given that much more room along the main axis, and this box
/// reports the size less [total] — to layout, to the dry layout and to the
/// intrinsic queries alike. A parent that sizes the strip by its intrinsic
/// width (the `IntrinsicHeight` around a horizontal strip, a centring
/// preview) then hands back exactly the room the children need; shrinking
/// the flex itself would have given the flex less room than its children
/// take, and it would report an overflow.
class _JoinOverlap extends SingleChildRenderObjectWidget {
  const _JoinOverlap({
    required this.vertical,
    required this.total,
    required super.child,
  });

  final bool vertical;
  final double total;

  @override
  _RenderJoinOverlap createRenderObject(BuildContext context) =>
      _RenderJoinOverlap(vertical: vertical, total: total);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderJoinOverlap renderObject,
  ) {
    renderObject
      ..vertical = vertical
      ..total = total;
  }
}

class _RenderJoinOverlap extends RenderProxyBox {
  _RenderJoinOverlap({required bool vertical, required double total})
    : _vertical = vertical,
      _total = total;

  bool _vertical;
  bool get vertical => _vertical;
  set vertical(bool value) {
    if (value == _vertical) return;
    _vertical = value;
    markNeedsLayout();
  }

  double _total;
  double get total => _total;
  set total(double value) {
    if (value == _total) return;
    _total = value;
    markNeedsLayout();
  }

  BoxConstraints _widened(BoxConstraints constraints) => _vertical
      ? constraints.copyWith(maxHeight: constraints.maxHeight + _total)
      : constraints.copyWith(maxWidth: constraints.maxWidth + _total);

  Size _shrunk(Size size) => _vertical
      ? Size(size.width, size.height - _total)
      : Size(size.width - _total, size.height);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_widened(constraints), parentUsesSize: true);
    size = constraints.constrain(_shrunk(child.size));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(
      _shrunk(child.getDryLayout(_widened(constraints))),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(height) - (_vertical ? 0 : _total);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) - (_vertical ? 0 : _total);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) - (_vertical ? _total : 0);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) - (_vertical ? _total : 0);
}

/// A [Flex] that overlaps its children by [itemOverlap] and paints one
/// child last without moving it in layout.
class _JoinFlex extends Flex {
  const _JoinFlex({
    required super.direction,
    required super.children,
    required this.focusedIndex,
    required this.itemOverlap,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.stretch,
       );

  final int? focusedIndex;
  final double itemOverlap;

  @override
  RenderFlex createRenderObject(BuildContext context) =>
      _JoinRenderFlex(
          direction: direction,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: getEffectiveTextDirection(context),
        )
        ..focusedIndex = focusedIndex
        ..itemOverlap = itemOverlap;

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _JoinRenderFlex renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..focusedIndex = focusedIndex
      ..itemOverlap = itemOverlap;
  }
}

/// Pulls each child back over the one before it by [itemOverlap], and
/// paints [focusedIndex] after its siblings.
///
/// The overlap is why two bordered children show one border at the seam:
/// the later child's border lands on the earlier one's. `RenderFlex`
/// rejects negative spacing, so the flex lays the children out edge to
/// edge and the overlap is taken out afterwards — each child moves back by
/// its index times the overlap. The flex keeps its edge-to-edge size; the
/// [_JoinOverlap] around it reports the shrunk one.
///
/// `defaultPaint` rather than `paint`: `RenderFlex.paint` reaches
/// `defaultPaint` by instance dispatch in both of its branches, so
/// overriding the inner one keeps the overflow clip and the debug
/// overflow stripes — a `Join` narrower than its content does overflow.
///
/// Reordering the children themselves would not work: `RenderFlex`
/// assigns offsets in traversal order, so moving the focused child to the
/// end would move it on screen too.
class _JoinRenderFlex extends RenderFlex {
  _JoinRenderFlex({
    required super.direction,
    required super.mainAxisSize,
    required super.crossAxisAlignment,
    super.textDirection,
  });

  int? _focusedIndex;

  int? get focusedIndex => _focusedIndex;

  set focusedIndex(int? value) {
    if (value == _focusedIndex) return;
    _focusedIndex = value;
    markNeedsPaint();
  }

  double _itemOverlap = 0;

  double get itemOverlap => _itemOverlap;

  set itemOverlap(double value) {
    if (value == _itemOverlap) return;
    _itemOverlap = value;
    markNeedsLayout();
  }

  bool get _horizontal => direction == Axis.horizontal;

  /// The length the overlaps take out of the main axis.
  double get _overlapTotal =>
      childCount < 2 ? 0 : _itemOverlap * (childCount - 1);

  @override
  void performLayout() {
    super.performLayout();
    final total = _overlapTotal;
    if (total == 0) return;

    // A right-to-left row places the first child at the right edge, so
    // the strip shrinks from the left: each child moves left by the part
    // of the total that has not been taken out before it.
    final flipped = _horizontal && textDirection == TextDirection.rtl;
    var child = firstChild;
    var index = 0;
    while (child != null) {
      final childParentData = child.parentData! as FlexParentData;
      final back = _itemOverlap * index;
      childParentData.offset = _horizontal
          ? childParentData.offset.translate(flipped ? back - total : -back, 0)
          : childParentData.offset.translate(0, -back);
      child = childParentData.nextSibling;
      index++;
    }
  }

  @override
  void defaultPaint(PaintingContext context, Offset offset) {
    final focused = _focusedIndex;
    if (focused == null) {
      super.defaultPaint(context, offset);

      return;
    }

    RenderBox? deferred;
    var child = firstChild;
    var index = 0;
    while (child != null) {
      final childParentData = child.parentData! as FlexParentData;
      if (index == focused) {
        deferred = child;
      } else {
        context.paintChild(child, childParentData.offset + offset);
      }
      child = childParentData.nextSibling;
      index++;
    }

    if (deferred != null) {
      final deferredParentData = deferred.parentData! as FlexParentData;
      context.paintChild(deferred, deferredParentData.offset + offset);
    }
  }
}

/// Chain sugar for merging a [CoreJoinStyle] patch into
/// [Join.joinStyle] without hand-reconstructing every field. Mirrors
/// the Web `Join.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreJoinStyle.merge` right-side-wins semantics).
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
/// sets [CoreJoinStyle.borderRadius]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Join(children: [...]).radius4
/// ```
extension JoinStyleChain on Join {
  /// Returns a copy of this [Join] with [patch] merged into
  /// [joinStyle] (patch fields win on conflict).
  Join withStyle(CoreJoinStyle patch) =>
      copyWith(joinStyle: (joinStyle ?? const CoreJoinStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Join get radius0 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Join get radius2 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Join get radius4 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Join get radius6 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Join get radius8 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Join get radius10 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Join get radius12 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Join get radius14 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Join get radius16 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Join get radius20 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Join get radius24 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Join get radius28 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Join get radius32 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Join get radius36 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Join get radius40 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Join get radius48 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Join get radius56 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Join get radius64 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Join get radius9999 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
