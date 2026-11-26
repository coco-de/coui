import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';
import 'package:coui_core/src/component/contracts/stacks/core_stack_fit.dart';
import 'package:coui_core/src/component/contracts/stacks/core_text_direction.dart';

/// Platform-independent contract for a `Stacks`.
///
/// `Stacks` is the cross-platform z-stack primitive — it paints
/// [children] on top of one another so each child shares the same
/// position in the parent. Direct equivalent of Flutter's `Stack`
/// widget; the Web implementation reproduces the same semantics with
/// CSS Grid + absolute positioning.
///
/// Children that need explicit coordinates inside the stack are wrapped
/// in `Position` (see `CorePositionContract`). Non-positioned
/// children are laid out by [alignment] / [fit].
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreStacksContract<W> {
  /// Layered children. The **last** child is rendered on top —
  /// matching Flutter `Stack`'s default paint order.
  List<W> get children;

  /// Where to position non-positioned children inside the stack.
  /// Defaults to [CoreAlignment.topStart] for parity with Flutter
  /// `Stack`'s default `AlignmentDirectional.topStart`.
  CoreAlignment get alignment;

  /// How non-positioned children are sized relative to the parent.
  /// Defaults to [CoreStackFit.loose] for Flutter parity.
  CoreStackFit get fit;

  /// How overflowing content is clipped. Defaults to
  /// [CoreClipBehavior.hardEdge] for Flutter parity.
  CoreClipBehavior get clipBehavior;

  /// Reading direction used to resolve [alignment] for the
  /// `start`/`end` axes. When `null` the surrounding ambient
  /// direction is used (Flutter `Directionality.of(context)`, Web
  /// inherited `dir`). Mirrors Flutter `Stack.textDirection`.
  CoreTextDirection? get textDirection;
}
