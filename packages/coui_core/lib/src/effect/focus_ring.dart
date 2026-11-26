import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';

/// Platform-independent focus ring tokens.
///
/// The ring sits outside the control: a [ringOffset] gap next to the
/// control's edge, then a [ringWidth] stroke in [ringColor]. The gap is
/// see-through by default ([ringOffsetColor]) — the background behind
/// the control shows in it, so the ring reads as separate from the
/// control on whatever surface the control sits on. A component whose
/// background is not known (floating over scrolling content or photos,
/// or sitting on an inverse-surface fill) states [opaqueOffsetColor]
/// instead, so the ring always has a contrasting partner.
abstract final class CoreFocusRing {
  const CoreFocusRing._();

  // === Values (Flutter) ===

  /// Focus ring width (2px).
  static const double ringWidth = 2;

  /// Width of the gap between the control's edge and the ring's inner
  /// edge (matches [ringWidth]).
  static const double ringOffset = ringWidth;

  /// Focus ring opacity multiplier.
  ///
  /// `1` — the ring is drawn at the full alpha of [ringColor]. Hosts
  /// apply it on top of the ring colour (`CoreColor.scaleAlpha`), so an
  /// override dims the ring without touching its colour.
  static const double ringOpacity = 1;

  /// Focus ring colour — its own semantic slot, not `primary`.
  ///
  /// It was `primary` until this kit's mapping resolved that family to
  /// neutrals, at which point the ring came out the same colour as body
  /// text (1.00 contrast against `onSurface`, measured in all four
  /// modes). See `CoreColorScheme.focusRing` for what the slot does
  /// instead. Component styles can still override it per-instance.
  static const CoreColor ringColor = CoreColor.token(CoreColors.focusRing);

  /// Default colour of the gap band between the control's edge and the
  /// ring — transparent, so the gap shows whatever is behind the
  /// control.
  ///
  /// A painted band only helps where the ring would otherwise touch an
  /// unknown colour. On a known page or panel background an opaque band
  /// is a second outline around the control: it reads as a thick ring
  /// glued to the control instead of a ring with a gap, and it is the
  /// wrong colour on any container that is not `surface`. Components
  /// whose background is unknown opt in with [opaqueOffsetColor].
  static const CoreColor ringOffsetColor = CoreColor.transparent;

  /// The band a component states when the background behind it is not
  /// known — a control floating over scrolling content or a photo, or
  /// one sitting on an inverse-surface fill.
  ///
  /// There the ring alone cannot promise contrast against every colour
  /// it may land on, so the indicator becomes two colours: the ring plus
  /// a `surface` band between it and the control. One of the two always
  /// contrasts with the adjacent colour (W3C technique C40, two-colour
  /// focus indicator).
  static const CoreColor opaqueOffsetColor = CoreColor.token(
    CoreColors.surface,
  );
}
