import 'package:coui_core/src/component/contracts/window/window_style.dart';
import 'package:meta/meta.dart';

/// Cross-platform theme overrides for the unified `Window` component.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot — see [CoreWindowStyle] for the merge chain.
@immutable
class CoreWindowTheme {
  /// Creates a [CoreWindowTheme].
  const CoreWindowTheme({this.style});

  /// Project-wide composite style applied to every `Window`.
  ///
  /// Resolved before any per-instance `widget.windowStyle`.
  final CoreWindowStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreWindowTheme copyWith({CoreWindowStyle? style}) {
    return CoreWindowTheme(style: style ?? this.style);
  }

  /// Merges with [other]; values on this take priority.
  CoreWindowTheme mergeWith(CoreWindowTheme? other) {
    if (other == null) return this;
    return CoreWindowTheme(style: style ?? other.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreWindowTheme &&
          runtimeType == other.runtimeType &&
          other.style == style;

  @override
  int get hashCode => style.hashCode;
}
