/// Speed-dial action descriptor for `Fab`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:meta/meta.dart';

/// A single action in the `Fab` speed dial.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
@immutable
class CoreFabAction<W> {
  /// Creates a [CoreFabAction].
  const CoreFabAction({
    required this.icon,
    this.label,
    this.onPressed,
    this.tooltip,
  });

  /// The icon rendered inside the circular action button.
  final W icon;

  /// Optional label displayed next to the action button.
  final W? label;

  /// Callback when the action is pressed.
  ///
  /// `CoreVoidCallback` is structurally identical to the Flutter
  /// `VoidCallback` (`void Function()`), so platform `Co*` wrappers
  /// can keep their native callback type when overriding.
  final CoreVoidCallback? onPressed;

  /// Tooltip text for the action.
  final String? tooltip;
}
