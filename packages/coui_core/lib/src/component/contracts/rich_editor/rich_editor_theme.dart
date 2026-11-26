import 'package:coui_core/src/component/contracts/rich_editor/rich_editor_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `RichEditor`.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreRichEditorStyle] for the merge chain.
@immutable
class CoreRichEditorTheme {
  /// Creates a [CoreRichEditorTheme].
  const CoreRichEditorTheme({this.style});

  /// Project-wide style applied to every `RichEditor`, before any
  /// per-instance `widget.richEditorStyle`.
  final CoreRichEditorStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRichEditorTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
