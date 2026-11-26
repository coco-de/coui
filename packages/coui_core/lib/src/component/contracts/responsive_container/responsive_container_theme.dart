import 'package:coui_core/src/component/contracts/responsive_container/responsive_container_style.dart';
import 'package:meta/meta.dart';

/// Theme-level overrides for `ResponsiveContainer` shared across
/// platforms.
///
/// Chrome / layout defaults (max-width, centring, horizontal padding) flow
/// through the single [style] slot (Epic #1415 option D — platform-neutral).
/// The theme no longer carries flat chrome fields of its own.
@immutable
class CoreResponsiveContainerTheme {
  /// Creates a [CoreResponsiveContainerTheme].
  const CoreResponsiveContainerTheme({this.style});

  /// Project-wide composite style applied to every `ResponsiveContainer`.
  ///
  /// Resolved before any per-instance `widget.responsiveContainerStyle`.
  final CoreResponsiveContainerStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreResponsiveContainerTheme copyWith({CoreResponsiveContainerStyle? style}) {
    return CoreResponsiveContainerTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreResponsiveContainerTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
