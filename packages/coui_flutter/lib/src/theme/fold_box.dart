import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/fold_scope.dart';
import 'package:flutter/widgets.dart';

/// Builds a widget that lays its content out against the folds, from where
/// its own box lies in the viewport.
///
/// [layout] is what [FoldScope.of] answers at the builder's context. [box] is
/// this widget's box in the viewport's coordinates while a fold splits the
/// viewport, and null while none does: nothing is measured then.
typedef FoldBoxBuilder =
    Widget Function(BuildContext context, CoreFoldLayout layout, Rect? box);

/// Tells its [builder] where this widget's own box lies in the viewport, for
/// a layout that depends on which side of a fold it is on.
///
/// The segments [FoldScope.of] answers with are the viewport's. A widget
/// that is the viewport — a route's page, a layer over the app — can hold
/// them against its own box as they are. One that covers part of it — a
/// layer inside a frame that stops short of an edge, a page of a navigator
/// that fills one pane — has to know where it is first. The box is the first
/// render object the builder returns.
///
/// Where the box lies is read from its last layout ([FoldScope.rectOf]),
/// which a build can only know after the fact. A box of the viewport's size
/// is exact from its first frame. Any other is built against where the box
/// around it was, and built again in the next frame if that was not where it
/// came to lie — as it is whenever its media query or its own state rebuilds
/// it. A box that is only moved, by a sibling that grew, keeps what it was
/// built with until then.
///
/// Where nothing splits the viewport it measures nothing and asks for no
/// frame.
class FoldBox extends StatefulWidget {
  /// Builds [builder] with where this widget's box lies.
  const FoldBox({required this.builder, super.key});

  /// Builds the content, whose first render object is the box measured.
  final FoldBoxBuilder builder;

  @override
  State<FoldBox> createState() => _FoldBoxState();
}

class _FoldBoxState extends State<FoldBox> {
  /// How many frames in a row a box may be built again before it is left as
  /// it is. A box sized by its parent settles in one; one sized by its own
  /// content would follow what the builder adds to it without end.
  static const int _kMaxCorrections = 3;

  /// How far a box may lie from where it was taken to be and still be there:
  /// the rounding of a layout pass.
  static const double _kTolerance = 0.5;

  /// The box the content was last built against, in the viewport's
  /// coordinates. Null while nothing splits the viewport.
  Rect? _builtIn;
  Size _viewport = Size.zero;
  bool _checking = false;
  int _corrections = 0;

  /// This widget's box in the viewport's coordinates, as last laid out: its
  /// own once it has been, and before that — in its first build — the
  /// nearest box around it that has. Null where none has, in an app's first
  /// frame.
  Rect? _measure() {
    var box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      box = context.findAncestorRenderObjectOfType<RenderBox>();
      while (box != null && !(box is RenderBox && box.hasSize)) {
        box = box.parent;
      }
    }
    if (box is! RenderBox || !box.attached) return null;

    return FoldScope.rectOf(box, viewport: _viewport);
  }

  /// Builds again after this frame, if the box did not come to lie where
  /// the build took it to be.
  void _checkAfterLayout() {
    if (_checking) return;
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checking = false;
      final builtIn = _builtIn;
      if (!mounted || builtIn == null) return;
      final now = _measure();
      if (now == null || _near(now, builtIn)) {
        _corrections = 0;

        return;
      }
      if (_corrections >= _kMaxCorrections) return;
      _corrections += 1;
      setState(() {});
    });
  }

  static bool _near(Rect a, Rect b) =>
      (a.left - b.left).abs() < _kTolerance &&
      (a.top - b.top).abs() < _kTolerance &&
      (a.right - b.right).abs() < _kTolerance &&
      (a.bottom - b.bottom).abs() < _kTolerance;

  @override
  Widget build(BuildContext context) {
    final layout = FoldScope.of(context);
    Rect? box;
    if (layout.isSplit) {
      _viewport = MediaQuery.sizeOf(context);
      box = _measure() ?? Offset.zero & _viewport;
      _checkAfterLayout();
    }
    _builtIn = box;

    return widget.builder(context, layout, box);
  }
}
