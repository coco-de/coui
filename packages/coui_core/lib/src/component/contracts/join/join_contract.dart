/// Platform-independent contract for unified join components.
///
/// Defines the interface that all Join implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/join/join_style.dart';

/// Contract for a unified join component.
///
/// Groups children into a visually connected strip,
/// clipping first/last items with appropriate border radius.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [joinStyle] slot. Behavioural fields (`children`,
/// `vertical`) stay flat.
///
/// Type parameters:
/// - [W] — platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreJoinContract<W> {
  /// The items to join together.
  List<W> get children;

  /// Whether to arrange items vertically.
  ///
  /// When `false` (default), items are arranged horizontally.
  bool get vertical;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreJoinTheme.style
  ///   → parent component slot override
  ///   → widget.joinStyle
  /// ```
  CoreJoinStyle? get joinStyle;
}
