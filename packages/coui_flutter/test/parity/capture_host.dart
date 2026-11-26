// The ancestor every Flutter parity capture lays an example out in — one
// definition, read by the matrix harness (`flutter_capture_matrix_test.dart`)
// and by the geometry pins that mirror it
// (`flutter_capture_matrix_overlay_pinning_test.dart`), so the two cannot
// describe different hosts.
//
// Why the height is unbounded. The Web capture wrapper
// (`tool/parity/src/web/web_capture_backend.dart`) gives its child a
// definite width and an `auto` height: a block flows to its content's height.
// The Flutter host used to hand the example `0..800 × 0..1200`. A widget that
// fills a *bounded* axis (`Column(mainAxisSize: max)`, `Center`, `Align`
// without a size factor, `Flex(max)`) then took all 1200 on the vertical axis
// while its Web twin took its content's height, so 31 components were
// measured 1200 tall against Web's 74–675. Hosting the example under an
// unbounded height removes that difference without touching a component or
// an example: a widget that does not need a height shrink-wraps, exactly as
// it does in a vertical flow.
//
// Why the width stays bounded. A container-driven root (`Divider`,
// `Progress`, `Slider`, anything declared `width: double.infinity`) must
// still fill the available width the way a Web `w-full` root does, and an
// unbounded width would make it throw. So only the vertical axis is released
// (`constrainedAxis: Axis.horizontal` keeps the incoming horizontal
// constraints).
//
// What this does not do. A widget that centres itself in the available width
// (`MockupDevice`, `ResponsiveContainer`: `Align` over a width-capped child)
// still fills the bounded width, so its captured box is the host's width
// while the Web root element is the device / capped box. That is a property
// of `Align` under a bounded width, not of the host's height.
import 'package:flutter/widgets.dart';

/// Wraps [child] in the host every parity capture uses: centred, width
/// bounded to the view (loose), height unbounded.
Widget captureHost({required Widget child}) {
  return Center(
    child: UnconstrainedBox(constrainedAxis: Axis.horizontal, child: child),
  );
}
