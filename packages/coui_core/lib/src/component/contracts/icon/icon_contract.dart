import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/icon/icon_name.dart';

/// Platform-independent contract for unified icon components.
///
/// `CoreIconContract` is intentionally tiny — it surfaces only the
/// **icon identity** and the reusable [iconStyle] object. Everything that
/// looks like a style override (size / color / weight / …) flows
/// exclusively through [iconStyle] so the contract grows in one direction
/// (richer `CoreIconStyle`) rather than by adding new flat fields.
abstract interface class CoreIconContract {
  /// The icon to render, referenced by its Iconify ID.
  IconName get icon;

  /// Per-instance icon style. Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → theme.icon.style
  ///   → parent component slot override
  ///       (e.g. CoreButtonStyle.leadingIconStyle)
  ///   → widget.iconStyle
  /// ```
  ///
  /// Named [iconStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works for raw Tailwind
  /// composition without colliding with the typed icon style API.
  CoreIconStyle? get iconStyle;
}
