import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/component/contracts/tag/tag_style.dart';

/// How loud a `Tag` is — a soft tint with a line, or the hue's solid fill.
///
/// Strength only. Which hue it is comes from [CoreCategoryColor]; the
/// colours each strength paints are picked once, in
/// [CoreTagStyle.resting], so every hue can be worn at either
/// strength.
///
/// Named `Emphasis` rather than `Variant` because the canvas names this
/// axis `Emphasis`, and `CoreBannerEmphasis` already uses the word for the
/// same idea — how much a part stands out, not a different kind of part.
enum CoreTagEmphasis {
  /// The hue's container behind its container text, with the hue's
  /// outline drawn inside the box. The default.
  ///
  /// In light mode the outline token reads the container tone, so the
  /// line does not show; it appears in dark and high-contrast modes. That
  /// is the palette's statement, not a case this component handles.
  subtle,

  /// The hue's solid fill behind its `on` colour, no line, the label set
  /// a step heavier. For the one tag that must stand out from its row.
  bold;

  /// Widget default emphasis — the Flutter / Web `Tag` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreTagEmphasis defaultEmphasis = subtle;
}
