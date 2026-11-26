/// Platform-independent contracts for unified subfocus components.
///
/// Defines the interfaces that all `SubfocusScope` / `Subfocus`
/// implementations (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/subfocus/subfocus_orientation.dart';
import 'package:coui_core/src/component/contracts/subfocus/subfocus_style.dart';

/// Contract for a unified subfocus scope.
///
/// `SubfocusScope` hosts a group of [CoreSubfocusContract] items and
/// manages keyboard traversal (arrow keys) between them. Exactly one
/// item holds subfocus at a time; the scope routes navigation and
/// keeps the focused item visible inside scrollable ancestors.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSubfocusScopeContract<W> {
  /// Subtree containing the [CoreSubfocusContract] items.
  W? get child;

  /// Whether the scope focuses its first item automatically on mount.
  /// Defaults to `false`.
  bool get autofocus;

  /// Axis along which arrow-key traversal moves between items.
  /// Defaults to [CoreSubfocusOrientation.vertical].
  CoreSubfocusOrientation get orientation;
}

/// Contract for a unified focusable subfocus item.
///
/// `Subfocus` makes its [child] focusable inside a
/// [CoreSubfocusScopeContract]. While the item holds subfocus it
/// draws a focus ring whose corner radius comes from
/// [subfocusStyle].
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSubfocusContract<W> {
  /// Content made focusable by this item.
  W? get child;

  /// Stable identifier for this focusable item within its scope.
  String get focusId;

  /// Whether this item can receive subfocus. Defaults to `true`.
  bool get enabled;

  /// Per-instance focus-ring chrome (corner radius).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreSubfocusStyle.defaultX
  ///   → CoreSubfocusScopeTheme.style
  ///   → widget.subfocusStyle
  /// ```
  CoreSubfocusStyle? get subfocusStyle;
}
