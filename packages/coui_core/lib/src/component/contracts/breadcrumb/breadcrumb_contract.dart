/// Platform-independent contract for breadcrumb components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/breadcrumb/breadcrumb_style.dart';
import 'package:meta/meta.dart';

/// A single item within a breadcrumb trail.
@immutable
class CoreBreadcrumbItem {
  /// Creates a [CoreBreadcrumbItem] with the given [label] and optional
  /// [href].
  const CoreBreadcrumbItem({required this.label, this.href});

  /// The text label displayed for this breadcrumb step.
  final String label;

  /// The navigation destination for this breadcrumb item.
  ///
  /// Informational on both platforms — navigation is driven through the
  /// tap callback ([CoreBreadcrumbContract.onItemTap]), not this field.
  /// On the Web it is exposed as a `data-href` attribute on the
  /// interactive item for tooling; it is not rendered as a native
  /// `<a href>`.
  final String? href;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBreadcrumbItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          href == other.href;

  @override
  int get hashCode => Object.hash(label, href);
}

/// Contract for a breadcrumb component.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
abstract interface class CoreBreadcrumbContract {
  /// The list of breadcrumb items to display, from root to current.
  ///
  /// The last item is rendered as the current location and is not
  /// interactive.
  List<CoreBreadcrumbItem> get items;

  /// Called when an interactive (non-last) breadcrumb item is tapped.
  ///
  /// Receives the zero-based index of the tapped item.
  CoreValueChanged<int>? get onItemTap;

  /// Whether the trail responds to the user.
  ///
  /// `null` derives from the handler (`enabled ?? (onItemTap != null)`), the
  /// same rule every handler-driven control follows. A disabled trail draws
  /// every item and the separators in the disabled content colour and makes
  /// no item interactive, whatever [onItemTap] is.
  bool? get enabled;

  /// Per-instance breadcrumb chrome / dimensional / slot style.
  CoreBreadcrumbStyle? get breadcrumbStyle;
}
