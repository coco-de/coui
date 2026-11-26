/// Tone of a loading indicator — which ink it is drawn in.
library;

import 'package:coui_core/src/component/contracts/loading/loading_variant.dart';

/// The ink of a `Loading`.
///
/// Orthogonal to [CoreLoadingVariant] (the shape) and to the size: a spinner,
/// dots, bar or pulse can be drawn in any of the three.
enum CoreLoadingTone {
  /// The brand ink on the neutral track (default).
  primary,

  /// A quiet ink for loading that should not draw the eye — the muted
  /// foreground on the neutral track.
  neutral,

  /// A light ink for loading drawn on a filled surface — the on-primary
  /// ink, with the track the same ink faded. Needed where the indicator sits
  /// inside a primary button.
  inverse;

  /// Tone used when none is stated.
  static const CoreLoadingTone defaultTone = primary;
}
