/// Visual variant for unified command components.
library;

import 'package:coui_core/src/component/behaviour_only.dart';

/// The visual variant of a `Command` palette.
///
/// The command palette currently has a single canonical look; the
/// enum exists so the widget signature and the resolver merge chain
/// stay structurally identical to every other unified component.
enum CoreCommandVariant {
  /// The standard surface palette — outlined container on a surface
  /// background.
  ///
  /// Behaviour-only on the canvas: an axis with one member separates
  /// nothing, and a `Variant=standard` on every Figma member presented a
  /// generator artefact as a designer's choice. The Figma set carries
  /// `Presentation` and `Size` instead; this enum stays for the merge chain
  /// (`variantStyles[variant]`) both platforms share.
  @behaviourOnly
  standard;

  /// Widget default variant. The Flutter / Web `Command`
  /// constructor default references this value so the two platforms
  /// cannot silently diverge.
  static const CoreCommandVariant defaultVariant = standard;
}
