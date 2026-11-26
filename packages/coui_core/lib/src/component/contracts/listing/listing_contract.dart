/// Platform-independent contract for a row-based Listing container.
library;

import 'package:coui_core/src/component/contracts/listing/listing_style.dart';

/// Contract for a vertical listing container that holds a sequence of rows.
///
/// Each row contains one or more column-like slots. The second column is
/// auto-grown when no column is explicitly marked to grow — matching the
/// CoUI "smart container" behaviour of DaisyUI's `list` component.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreListingContract<W> {
  /// Rows rendered inside the listing.
  List<W> get children;

  /// Whether to render a thin divider between adjacent rows.
  /// When null, falls back to `CoreListingStyle.itemBorder`, then to
  /// `CoreListingStyle.defaultItemBorder`.
  bool? get itemBorder;

  /// Accessible label announced by screen readers for the list landmark.
  String? get semanticLabel;

  /// Per-instance composite chrome / slot style.
  ///
  /// Row padding, column spacing, divider colour / thickness all flow
  /// through this single slot (Epic #1302 원칙 7).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreListingTheme.style
  ///   → parent component slot override
  ///   → widget.listingStyle
  /// ```
  CoreListingStyle? get listingStyle;
}

/// Contract for a single row inside `CoreListingContract`.
abstract interface class CoreListRowContract<W> {
  /// Columns rendered horizontally inside the row.
  List<W> get children;

  /// Per-row chrome / dimensional style override.
  ///
  /// Row padding flows through this single slot. When null, falls back to
  /// the listing theme then the design-system default.
  CoreListingStyle? get listingStyle;
}

/// Contract for a single column inside `CoreListRowContract`.
abstract interface class CoreListColContract<W> {
  /// The child rendered inside the column.
  W get child;

  /// When true, the column expands to fill the remaining horizontal space.
  bool get grow;

  /// When true, the column is allowed to wrap onto the next line. Useful
  /// for responsive rows that overflow on narrow viewports.
  bool get wrap;

  /// When true, the column refuses to shrink below its intrinsic size.
  bool get shrink;
}
