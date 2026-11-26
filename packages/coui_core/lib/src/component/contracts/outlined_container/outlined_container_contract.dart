/// Platform-independent contract for unified outlined-container components.
///
/// `OutlinedContainer` is an infrastructure primitive — a chrome
/// wrapper that draws a border + radius + optional padding / shadow /
/// blur around a single `child`. It's the building block behind
/// `Card`, `CardImage`, `Window`, `Alert`, and other
/// container-shaped components.
library;

import 'package:coui_core/src/component/contracts/outlined_container/outlined_container_style.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:coui_core/src/surface/surface_role.dart';

/// Contract for a unified outlined-container component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [containerStyle] field — see [CoreOutlinedContainerStyle]
/// for the merge chain.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreOutlinedContainerContract<W> {
  /// The child rendered inside the chrome.
  W? get child;

  /// Which layer this box sits on, and therefore which material it
  /// draws under a style that states two.
  ///
  /// Not a style choice. It answers the same question the component's
  /// own `surface:<role>` declaration answers — whether the code has
  /// evidence that this instance floats over content — and it exists
  /// because a floating component that *composes* this box has no other
  /// way to say so. Without it the alternative is hand-rolling a box,
  /// which is the re-implementation the composition rule forbids.
  ///
  /// Defaults to [CoreSurfaceRole.defaultRole], so every existing caller
  /// keeps the material it already had.
  CoreSurfaceRole get role;

  /// Per-instance container style covering chrome + dimensional
  /// overrides (background / border / radius / padding / shadow / blur
  /// / opacity / size / duration / clipBehavior).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → theme.outlinedContainer.style
  ///   → parent component slot override
  ///   → widget.containerStyle
  /// ```
  ///
  /// Named [containerStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without colliding.
  CoreOutlinedContainerStyle? get containerStyle;

  /// Edge bending this surface asks for, or null for none.
  ///
  /// Deliberately outside [containerStyle]. Every value in that slot is
  /// size-independent and reaches the surface through the theme; this one
  /// is computed from the element's own rectangle and has to be rebuilt
  /// whenever that changes. Putting it on the style path would make a
  /// size-dependent value look like an axis value, and the next surface to
  /// read it would need measuring code of its own.
  ///
  /// A request, not a guarantee — where the engine cannot draw it the
  /// surface keeps the rest of its material and bends nothing.
  CoreSurfaceRefraction? get refraction;
}
