import 'package:coui_core/src/component/contracts/kbd/kbd_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for keyboard key components.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreKbdStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreKbdTheme.style                             // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance kbdStyle
/// ```
@immutable
class CoreKbdTheme {
  /// Creates a [CoreKbdTheme].
  const CoreKbdTheme({this.style});

  /// Project-wide composite style applied to every `Kbd`.
  ///
  /// Resolved before any per-instance `widget.kbdStyle`.
  final CoreKbdStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreKbdTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
