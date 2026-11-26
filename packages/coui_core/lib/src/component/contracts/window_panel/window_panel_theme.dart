import 'package:coui_core/src/component/contracts/window_panel/window_panel_style.dart';
import 'package:meta/meta.dart';

/// Platform-independent theme defaults for `WindowPanel`.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot — see [CoreWindowPanelStyle] for the merge chain.
@immutable
class CoreWindowPanelTheme {
  /// Creates a [CoreWindowPanelTheme].
  const CoreWindowPanelTheme({this.style});

  /// Project-wide composite style applied to every `WindowPanel`.
  ///
  /// Resolved before any per-instance `widget.windowPanelStyle`.
  final CoreWindowPanelStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreWindowPanelTheme copyWith({CoreWindowPanelStyle? style}) {
    return CoreWindowPanelTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreWindowPanelTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}
