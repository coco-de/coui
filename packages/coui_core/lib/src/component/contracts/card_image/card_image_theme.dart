import 'package:coui_core/src/component/contracts/card_image/card_image_style.dart';
import 'package:meta/meta.dart';

/// Cross-platform theme overrides for the unified `CardImage`.
///
/// Per Epic #1302 / Phase 6f, all chrome (direction / colour / gap / hover
/// scale) lives inside [style] — no flat chrome fields remain on the theme.
@immutable
class CoreCardImageTheme {
  /// Creates a [CoreCardImageTheme].
  const CoreCardImageTheme({this.style});

  /// Project-wide composite style applied to every `CardImage`.
  ///
  /// Resolved before any per-instance `widget.cardImageStyle`.
  final CoreCardImageStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreCardImageTheme copyWith({CoreCardImageStyle? style}) {
    return CoreCardImageTheme(style: style ?? this.style);
  }

  /// Merges with [other]; values on this take priority.
  CoreCardImageTheme mergeWith(CoreCardImageTheme? other) {
    if (other == null) return this;
    return CoreCardImageTheme(style: style ?? other.style);
  }

  @override
  bool operator ==(Object other) =>
      other is CoreCardImageTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}
