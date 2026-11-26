/// Platform-independent contract for the Hero block.
library;

import 'package:coui_core/src/component/contracts/hero/hero_layout.dart';
import 'package:coui_core/src/component/contracts/hero/hero_style.dart';

/// Contract for the `Hero` marketing block.
///
/// A page-flow landing shell: background colour, optional background
/// image, optional overlay, and foreground content. [layout] chooses
/// how that foreground is arranged.
///
/// - [CoreHeroLayout.center] (default) centres [child]. [media] is not
///   rendered. Background [imageUrl] and `heroStyle.overlayColor` still
///   paint behind the copy.
/// - [CoreHeroLayout.split] places [child] (the copy) and [media] in a
///   responsive pair. [media] is trailing when the pair is a row, and
///   below the copy when the pair stacks. [media] is foreground
///   content — it does not replace [imageUrl]. A split with no [media]
///   renders the centred copy, the same picture as `center`.
///
/// [appear] is behaviour, not chrome: it decides whether the foreground
/// plays an entrance the first time the block meets the viewport. The
/// duration, distance, and easing live on [heroStyle].
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreHeroContract<W> {
  /// Arrangement of the foreground. `null` uses
  /// [CoreHeroStyle.defaultLayout] ([CoreHeroLayout.center]).
  CoreHeroLayout? get layout;

  /// Whether the foreground plays an entrance the first time the
  /// block intersects the viewport.
  ///
  /// `false` (see [defaultAppear]) leaves the hero static. `true` fades
  /// the foreground in and raises it once. The background and overlay
  /// stay put, and the entrance does not reverse when the block leaves
  /// the viewport.
  bool get appear;

  /// Background image URL. Rendered with `BoxFit.cover` on Flutter and
  /// `background-size: cover; background-position: center` on Web.
  ///
  /// Decorative. It is not the split [media] slot — information that
  /// needs an accessible name belongs in [child] or [media].
  String? get imageUrl;

  /// Accessible label announced by screen readers for the hero region.
  String? get semanticLabel;

  /// Foreground media beside the copy when [layout] resolves to
  /// [CoreHeroLayout.split]. Ignored for [CoreHeroLayout.center], and
  /// ignored when null (the copy centres instead).
  W? get media;

  /// The copy. Centred when [layout] is [CoreHeroLayout.center]; the
  /// leading (or upper) cell when [layout] is [CoreHeroLayout.split].
  W get child;

  /// Shared default for [appear].
  ///
  /// Opt-in on purpose: existing callers keep a static hero, and a
  /// landing page turns the entrance on per block.
  static const bool defaultAppear = false;

  /// Per-instance chrome / dimensional style.
  ///
  /// Carries background colour, overlay colour, minimum height, outer
  /// padding, the entrance recipe, the layout default, and the gutter
  /// between copy and media.
  CoreHeroStyle? get heroStyle;
}
