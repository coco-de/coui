import 'package:coui_core/src/size/size.dart';

/// Semantic size constraint — accessibility sizes for interactive
/// targets.
///
/// Two different kinds of value live here, and they are not
/// interchangeable:
///
/// - [minPointerTarget] (24) is the **guaranteed floor** for the area
///   that accepts a pointer. It is the one the kit enforces:
///   `CoreTouchTarget.minimum` reads it, and the platform pointer-target
///   mechanisms extend where a pointer is accepted up to it without
///   changing what is drawn — a 12px checkbox stays 12px and accepts a
///   pointer across 24.
/// - [touchTarget] (48) and [minTouchTarget] (44) are **recommended drawn
///   sizes** for screens whose primary input is touch. Nothing enforces
///   them: a control drawn at 24 or 32 (`CoreControlSize.heightXs` ·
///   `heightSm`) keeps that size and gets the 24 floor, not 48. Reaching
///   them on a touch screen is a choice of size step, not something the
///   kit does on its own.
///
/// Like `CoreControlSize` this is a constraint layer, not a scale — the
/// members are unrelated values that individual components cannot each
/// be trusted to re-derive.
abstract final class CoreA11ySize {
  const CoreA11ySize._();

  /// 24px — WCAG 2.2 AA (2.5.8) floor for pointer targets, and the floor
  /// the kit guarantees on both platforms.
  static const double minPointerTarget = CoreSize.size24;

  /// 44px — Apple HIG · WCAG 2.2 AAA (2.5.5) recommended drawn size on
  /// touch screens. Not enforced.
  static const double minTouchTarget = CoreSize.size44;

  /// 48px — recommended drawn size for a target on a screen whose
  /// primary input is touch (Material 3 · Flutter
  /// `kMinInteractiveDimension`). Not enforced — the guaranteed floor is
  /// [minPointerTarget].
  static const double touchTarget = CoreSize.size48;
}
