/// Per-instance focus-ring style for `Subfocus`.
library;

import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:meta/meta.dart';

/// Immutable chrome style for a `Subfocus` focusable item.
///
/// `Subfocus` draws a focus ring around its child while the item
/// holds subfocus. The only chrome it owns is the ring's corner
/// radius — the ring colour / width / animation flow through the
/// already-unified [CoreFocusOutlineStyle]. Behavioural fields
/// (`focusId`, `enabled`, `child`) stay flat on the widget.
///
/// ```text
/// CoreSubfocusStyle.defaultX
///   → CoreSubfocusScopeTheme.style
///   → widget.subfocusStyle
/// ```
@immutable
class CoreSubfocusStyle implements CoreStyle<CoreSubfocusStyle> {
  /// Creates a [CoreSubfocusStyle].
  const CoreSubfocusStyle({this.focusRingRadius});

  /// Corner radius of the focus ring drawn around a focused item.
  final CoreBorderRadius? focusRingRadius;

  /// Default focus-ring corner radius — matches the field radius
  /// token (4px), the same value the legacy Web subfocus used.
  static const CoreBorderRadius defaultFocusRingRadius = CoreBorderRadius.all(
    CoreRadius.radius4,
  );

  /// Default focus-ring width — shared with [CoreFocusOutlineStyle]
  /// so a `Subfocus` ring is visually identical to every other CoUI
  /// focus ring.
  static const double defaultFocusRingWidth =
      CoreFocusOutlineStyle.defaultBorderWidth;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreSubfocusStyle merge(CoreSubfocusStyle? other) {
    if (other == null) return this;
    return CoreSubfocusStyle(
      focusRingRadius: other.focusRingRadius ?? focusRingRadius,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSubfocusStyle copyWith({CoreBorderRadius? focusRingRadius}) {
    return CoreSubfocusStyle(
      focusRingRadius: focusRingRadius ?? this.focusRingRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSubfocusStyle &&
          runtimeType == other.runtimeType &&
          focusRingRadius == other.focusRingRadius;

  @override
  int get hashCode => focusRingRadius.hashCode;
}
