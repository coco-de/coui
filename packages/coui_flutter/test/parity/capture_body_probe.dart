import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Geometry of the leading Align's own child, not a guessed descendant of
/// a similarly sized widget. An unexpected tree is a capture error.
({double left, double width, double height}) captureBodyGeometry(
  BuildContext rootContext,
  BuildContext boundaryContext,
) {
  final root = rootContext.findRenderObject();
  final boundary = boundaryContext.findRenderObject();
  if (root is! RenderPositionedBox || boundary is! RenderBox) {
    throw StateError('A body probe requires a leading Align render box');
  }
  if (root.alignment.resolve(TextDirection.ltr) != Alignment.topCenter) {
    throw StateError(
      'A framed body requires the declared top-centre alignment',
    );
  }
  final body = root.child;
  if (body == null || body.size.height != root.size.height) {
    throw StateError('The aligned body must span the stage height');
  }
  final offset = body.localToGlobal(Offset.zero, ancestor: boundary);
  if (offset.dy.abs() > precisionErrorTolerance) {
    throw StateError('The aligned body must start at the stage top');
  }
  if ((offset.dx - (root.size.width - body.size.width) / 2).abs() >
      precisionErrorTolerance) {
    throw StateError('The body is not centred in its captured stage');
  }
  return (left: offset.dx, width: body.size.width, height: body.size.height);
}
