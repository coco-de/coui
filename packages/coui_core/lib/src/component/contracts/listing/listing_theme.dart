/// Theme overrides for the unified Listing component.
library;

import 'package:coui_core/src/component/contracts/listing/listing_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified Listing.
///
/// All chrome (row padding / column spacing / divider visibility, colour
/// and thickness) flows through the composite [style] field — no legacy
/// flat fields (Epic #1302 원칙 7).
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreListingTheme.style                         // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance listingStyle
/// ```
@immutable
class CoreListingTheme {
  /// Creates a [CoreListingTheme].
  const CoreListingTheme({this.style});

  /// Project-wide composite style applied to every `Listing`.
  ///
  /// Resolved before any per-instance `widget.listingStyle`.
  final CoreListingStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreListingTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
