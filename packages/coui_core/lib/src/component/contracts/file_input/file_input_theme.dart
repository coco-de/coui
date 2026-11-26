/// Theme data for `FileInput` customisation.
library;

import 'package:coui_core/src/component/contracts/file_input/file_input_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for file input components.
///
/// Per Epic #1302 the project-wide chrome / dimensional / nested-slot
/// styles flow through the single composite [style] field — see
/// [CoreFileInputStyle] for the merge chain.
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   fileInput: CoreFileInputTheme(
///     style: CoreFileInputStyle(
///       borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
///       padding: CoreEdgeInsets.all(CoreSpace.space32),
///     ),
///   ),
/// )
/// ```
@immutable
class CoreFileInputTheme {
  /// Creates a [CoreFileInputTheme].
  const CoreFileInputTheme({this.style});

  /// Project-wide composite style applied to every `FileInput`.
  ///
  /// Resolved before any per-instance `widget.fileInputStyle`.
  final CoreFileInputStyle? style;

  /// Returns a copy of this theme with the given fields replaced.
  CoreFileInputTheme copyWith({CoreFileInputStyle? style}) {
    return CoreFileInputTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFileInputTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
