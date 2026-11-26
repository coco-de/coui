/// Platform-independent contract for unified card components.
library;

import 'package:coui_core/src/component/contracts/card/card_style.dart';
import 'package:coui_core/src/component/contracts/card/card_variant.dart';
import 'package:coui_core/src/surface/surface_role.dart';

/// Contract for a unified card component.
///
/// Provides a slot-based layout with [media], [header], [body],
/// [footer], and [overlay] slots, controlled by [variant]. All
/// chrome / dimensional overrides flow through the single
/// [cardStyle] field — see [CoreCardStyle].
///
/// `CoreCardStyle` is platform-neutral (Epic #1415 option D), so only
/// the widget type [W] remains generic.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreCardContract<W> {
  /// The visual variant of the card.
  CoreCardVariant get variant;

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

  /// Media slot at the top (e.g. image). Renders without padding.
  W? get media;

  /// Header slot below media.
  W? get header;

  /// Body slot below header.
  W? get body;

  /// Footer slot at the bottom.
  W? get footer;

  /// Overlay positioned over the media area.
  W? get overlay;

  /// Custom child. When provided, all slots are ignored.
  W? get child;

  /// Tap callback. Enables click cursor and hover shadow.
  void Function()? get onTap;

  /// Per-instance card style covering chrome + dimensional overrides.
  /// Resolves through the nested-merge chain
  /// (`CoreCardStyle.defaultX` ← `theme.card.style` ←
  /// `theme.card.variantStyles[variant]` ← parent slot override ←
  /// `widget.cardStyle`).
  ///
  /// Named [cardStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without colliding.
  CoreCardStyle? get cardStyle;
}
