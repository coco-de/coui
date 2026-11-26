import 'package:coui_core/src/size/a11y_size.dart';

/// Platform-independent minimum pointer target.
///
/// WCAG 2.2 `2.5.8 Target Size (Minimum)` asks that a target be at least
/// 24 by 24 CSS pixels. The reason it is a floor rather than a size is
/// that it says nothing about what is *drawn* — a 12px checkbox that
/// accepts a pointer 6px outside its box satisfies it, and looks
/// identical.
///
/// That separation is the whole point. Raising the drawn size of every
/// small control to 24 would redesign the kit; raising only what accepts
/// a pointer changes nothing anyone can see and fixes the failure for
/// everyone who does not point precisely.
abstract final class CoreTouchTarget {
  const CoreTouchTarget._();

  /// The smallest a pointer target may be, on either axis.
  ///
  /// 24 is the WCAG 2.2 AA minimum. Platform guidance asks for more —
  /// 44 on iOS, 48 on Android — and a control is free to be larger; this
  /// is the line below which one is wrong rather than merely small.
  ///
  /// The value is [CoreA11ySize.minPointerTarget], read rather than
  /// restated, so the floor the platforms enforce and the
  /// `a11y/pointer-target-min` token on the canvas are one number.
  static const double minimum = CoreA11ySize.minPointerTarget;
}
