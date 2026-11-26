/// Cross-platform contract for overlay handlers — the strategy that
/// decides *how* a floating panel (popover / tooltip / menu) is
/// mounted on the host.
///
/// Mirrors Flutter's `OverlayHandler` interface (popover overlay,
/// sheet overlay, fixed tooltip overlay) so Web can ship matching
/// strategies — typically a default `OverlayPortalHandler` and a
/// drop-in `SheetOverlayHandler` for mobile screens.
///
/// Implementations are platform-specific (no shared mount logic in
/// core). Floating components consume only the contract.
library;

import 'package:coui_core/src/component/contracts/overlay/overlay_layer.dart';

/// Base contract — overlay handlers receive a panel-mount request and
/// return a handle that the requester can close.
///
/// Type parameters:
/// - [W]: Widget type (Flutter: `Widget`, Web: `Component`).
/// - [Token]: Handle type returned from `mount`. Flutter overlays use
///   `Popover` / `OverlayCompleter`; Web uses an `int` token.
///
/// `mount` is layered by [CoreOverlayLayer] so the host can route
/// popover requests to a different handler than tooltip / menu
/// (matches Flutter `CoUIApp.popoverHandler / tooltipHandler /
/// menuHandler` three-slot model).
abstract interface class CoreOverlayHandler<W, Token> {
  /// Inserts [panel] onto the overlay layer associated with [layer].
  /// Returns a token the caller can pass to [unmount] to remove the
  /// entry.
  ///
  /// [modal] states that the background must be unreachable while this
  /// panel is open — not to assistive technology, not by Tab, not by
  /// pointer. It travels with the mount request rather than being
  /// inferred from [layer] because modality is a property of the
  /// surface, not of where it stacks: a dialog and a non-modal popover
  /// can share a layer, and a menu is modal on one host and not on
  /// another. Flutter's overlay handler already takes the same flag.
  Token mount({
    required CoreOverlayLayer layer,
    required W panel,
    bool modal,
  });

  /// Removes the entry registered under [token]. No-op if [token]
  /// isn't recognised (already removed or never matched).
  void unmount(Token token);

  /// Replaces an existing entry's content in place — used by floating
  /// components that rebuild while open (anchor follow, content
  /// changes) without unmount/mount churn.
  void update(Token token, W panel);
}
