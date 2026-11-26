import 'package:coui_core/coui_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Accepts a pointer within [minimum] of the child's centre, without
/// changing what the child draws or how much room it takes.
///
/// WCAG 2.2 `2.5.8` is about where a pointer is accepted, not about how
/// large anything looks. A 12px checkbox is a legitimate design; a 12px
/// checkbox that can only be hit within those 12px is not.
///
/// ## Why this does not simply pad
///
/// Padding to the minimum is the obvious fix and the one Material takes.
/// It also moves everything: a checkbox beside a label, a row of chips,
/// a dense table of controls all get wider and taller, and the kit's
/// small sizes stop being small. Since the requirement is about hit
/// testing, this expands hit testing and nothing else — the render box
/// still lays out and paints at the child's size.
///
/// ## The cost, stated
///
/// Two of these placed closer together than the expansion will overlap,
/// and the one hit-tested first wins. Flutter hit-tests children in
/// reverse paint order, so that is the later sibling. This is the same
/// resolution Material's padded targets get when their parents are told
/// to overlap them, and it is why the expansion is a floor rather than
/// something generous: 24 leaves 6px of reach around a 12px control,
/// which is small enough that ordinary spacing keeps neighbours apart.
class TouchTarget extends SingleChildRenderObjectWidget {
  /// Creates a [TouchTarget].
  const TouchTarget({
    required Widget super.child,
    this.minimum = CoreTouchTarget.minimum,
    super.key,
  });

  /// The smallest region, on either axis, that accepts a pointer.
  final double minimum;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTarget(minimum: minimum);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTouchTarget renderObject,
  ) {
    renderObject.minimum = minimum;
  }
}

class _RenderTouchTarget extends RenderProxyBox {
  _RenderTouchTarget({required double minimum}) : _minimum = minimum;

  double get minimum => _minimum;
  double _minimum;

  set minimum(double value) {
    if (_minimum == value) return;
    _minimum = value;
    // Nothing is laid out or painted from this, so a repaint would be
    // wasted work — only hit testing reads it.
    markNeedsSemanticsUpdate();
  }

  /// How far outside the box a pointer is still accepted, per axis.
  Offset get _reach => .new(
    ((_minimum - size.width) / 2).clamp(0, double.infinity),
    ((_minimum - size.height) / 2).clamp(0, double.infinity),
  );

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = _reach;
    if (reach == .zero) {
      return super.hitTest(result, position: position);
    }

    final expanded = Rect.fromLTWH(
      -reach.dx,
      -reach.dy,
      size.width + reach.dx * 2,
      size.height + reach.dy * 2,
    );
    if (!expanded.contains(position)) return false;

    if (size.isEmpty) return false;

    // The child only accepts a position inside its own bounds, so a hit
    // in the margin is reported at the nearest point that is. Without
    // this the expansion would register on this box and stop, and the
    // control it exists for would never see the pointer.
    //
    // The nearest point is just *inside* the far edge, not on it:
    // `Size.contains` is exclusive there, so clamping to `size.width`
    // lands on a position the child rejects. That produced the worst
    // outcome available — the region accepted the pointer and nothing
    // happened, so the margin swallowed taps instead of extending the
    // control. Measured, not reasoned: the tap simply did not fire.
    const edge = 0.01;
    final inside = Offset(
      position.dx.clamp(0, size.width - edge),
      position.dy.clamp(0, size.height - edge),
    );

    // The margin behaves as part of the control, including when the
    // control is disabled: a pointer there stops at it rather than
    // reaching something painted behind. That is the same thing the
    // control's own box already does, so the expansion does not
    // introduce a new rule — it moves an existing edge.
    //
    // Measured, after a comment here claimed the opposite. A disabled
    // control's child still accepts the hit; it simply does nothing with
    // it, so declining on the child's behalf is not something this can
    // decide from here.
    return super.hitTest(result, position: inside);
  }
}
