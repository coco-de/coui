/// Platform-independent contract for navigation-menu components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/navigation_menu/navigation_menu_style.dart';
import 'package:meta/meta.dart';

/// A single top-level item within a navigation menu.
///
/// Each item shows its [label] in the horizontal trigger bar. An item is
/// one of three kinds:
///
/// * **Content trigger** — has [content]; hovering or clicking the
///   trigger reveals the content as a dropdown panel and a chevron is
///   shown.
/// * **Link** — has [href]; the trigger renders as a hyperlink and
///   navigates on activation.
/// * **Action** — has [onTap]; activating the trigger invokes the
///   callback without revealing a panel.
///
/// [content] carries the platform widget type (`Widget` on Flutter,
/// `Component` on Web) so the same item shape works on both platforms.
@immutable
class CoreNavigationMenuItem<W> {
  /// Creates a [CoreNavigationMenuItem].
  const CoreNavigationMenuItem({
    required this.label,
    this.content,
    this.href,
    this.onTap,
  });

  /// The text label displayed in the horizontal trigger bar.
  final String label;

  /// The dropdown content revealed when this item is activated.
  ///
  /// `null` for link-only or action-only items.
  final W? content;

  /// Direct link URL — when set the trigger renders as a hyperlink.
  ///
  /// `null` for content or action items.
  final String? href;

  /// Invoked when an action item's trigger is activated.
  ///
  /// `null` for content or link items.
  final CoreVoidCallback? onTap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationMenuItem<W> &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          content == other.content &&
          href == other.href &&
          onTap == other.onTap;

  @override
  int get hashCode => Object.hash(label, content, href, onTap);
}

/// Contract for a navigation-menu component.
///
/// Platform-neutral (Epic #1415 option D) — the only generic is the
/// widget type `<W>` carried by [items]' content slots.
///
/// Needs a container at least as wide as the trigger bar's intrinsic
/// width. Narrower containers are unsupported and fail differently per
/// platform — Flutter reports a row overflow, Web spills past the border
/// box without a signal. That divergence is intentionally left unresolved;
/// the width requirement is the contract.
abstract interface class CoreNavigationMenuContract<W> {
  /// The top-level items displayed horizontally in the trigger bar.
  List<CoreNavigationMenuItem<W>> get items;

  /// Index of the active item, or `null` when none is open.
  ///
  /// When non-null the component is controlled — the parent owns the
  /// open state. When `null` the component manages its own open state.
  int? get activeIndex;

  /// Invoked when the active item changes (open / close / switch).
  ///
  /// Receives the new active index, or `null` when the menu closes.
  void Function(int?)? get onActiveIndexChanged;

  /// Per-instance navigation-menu chrome / dimensional style.
  CoreNavigationMenuStyle? get navigationMenuStyle;
}
