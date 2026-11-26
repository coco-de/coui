/// Platform-independent contract for pagination components.
///
/// Defines the interface that all pagination implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/pagination/pagination_style.dart';
import 'package:coui_core/src/surface/surface_role.dart';

/// Contract for a pagination component.
///
/// The behaviour fields (`maxPages` / `showSkipToFirstPage` /
/// `showSkipToLastPage` / `hidePreviousOnFirstPage` /
/// `hideNextOnLastPage` / `showLabel`) stay flat on the widget — they
/// change the *behaviour* of the control, not its visual chrome. All
/// chrome / dimensional overrides flow through [paginationStyle].
abstract interface class CorePaginationContract {
  /// The currently active page number.
  ///
  /// Uses one-based indexing, so the first page is 1.
  int get currentPage;

  /// The total number of pages available.
  int get totalPages;

  /// Called when the user navigates to a different page.
  ///
  /// Receives the one-based index of the newly selected page.
  CoreValueChanged<int>? get onPageChanged;

  /// Whether the control responds to the user.
  ///
  /// `null` derives from the handler (`enabled ?? (onPageChanged != null)`),
  /// the same rule every handler-driven control follows. A disabled
  /// pagination draws every number, the `…` and the chevrons in the disabled
  /// content colour (the current page on the disabled container fill) and
  /// makes no button interactive, whatever [onPageChanged] is.
  bool? get enabled;

  /// Which layer each page button sits on, and therefore which material
  /// it draws under a style that states two.
  ///
  /// Not a style choice. It answers the same question the component's
  /// own `surface:<role>` declaration answers — whether the code has
  /// evidence that this instance floats over content — and it exists
  /// because pagination *composes* the button box rather than drawing
  /// it, so it has no other way to say so.
  ///
  /// Defaults to [CoreSurfaceRole.defaultRole] (content): pagination is
  /// a nav control that sits in the page flow, not something mounted
  /// over it.
  CoreSurfaceRole get role;

  /// Per-instance pagination chrome / dimensional style.
  CorePaginationStyle? get paginationStyle;
}
