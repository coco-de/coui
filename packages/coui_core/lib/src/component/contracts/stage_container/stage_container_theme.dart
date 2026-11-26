import 'package:coui_core/src/component/contracts/stage_container/stage_container_style.dart';
import 'package:meta/meta.dart';

/// Platform-independent theme defaults for `StageContainer`.
///
/// Chrome / dimensional defaults (breakpoint, per-axis padding) flow through
/// the single [style] slot (Epic #1415 option D — platform-neutral). The
/// theme no longer carries flat chrome fields of its own.
@immutable
class CoreStageContainerTheme {
  /// Creates a [CoreStageContainerTheme].
  const CoreStageContainerTheme({this.style});

  /// Project-wide composite style applied to every `StageContainer`.
  ///
  /// Resolved before any per-instance `widget.stageContainerStyle`.
  final CoreStageContainerStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreStageContainerTheme copyWith({CoreStageContainerStyle? style}) {
    return CoreStageContainerTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreStageContainerTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}
