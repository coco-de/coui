/// Platform-independent contract for unified tag components.
///
/// Defines the interface that all Tag implementations (Flutter, Web) must
/// satisfy.
library;

import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/component/contracts/tag/tag_emphasis.dart';
import 'package:coui_core/src/component/contracts/tag/tag_size.dart';
import 'package:coui_core/src/component/contracts/tag/tag_style.dart';

/// Contract for a unified tag — a short label that files something under
/// a category, coloured by one of the category hues.
///
/// Display only: a tag has no press, no hover or press state, and never
/// takes keyboard focus. Something a person acts on is a `Chip`.
///
/// Every chrome / dimensional override flows through the single
/// [tagStyle] field — see [CoreTagStyle] for the merge chain. The design
/// axes (`color` / `emphasis` / `size`) and the content (`child`) stay flat
/// on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreTagContract<W> {
  /// Widget default hue — the Flutter / Web `Tag` constructors reference
  /// this so the default cannot silently diverge.
  ///
  /// Gray: a tag a caller has not coloured should not claim a category.
  static const CoreCategoryColor defaultColor = CoreCategoryColor.gray;

  /// Which category hue the tag wears.
  CoreCategoryColor get color;

  /// How loud the tag is — a tint with a line, or the solid fill.
  ///
  /// Orthogonal to [color] — every hue has both strengths.
  CoreTagEmphasis get emphasis;

  /// Which of the two steps the tag is drawn at.
  CoreTagSize get size;

  /// The label — normally a `Text`. Set at the step's role in the hue's
  /// foreground colour.
  W get child;

  /// Per-instance tag chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (size row → emphasis row → hue × emphasis colours)
  ///   → CoreTagTheme.style
  ///   → CoreTagTheme.colorStyles[color]
  ///   → CoreTagTheme.emphasisStyles[emphasis]
  ///   → widget.tagStyle
  /// ```
  CoreTagStyle? get tagStyle;
}
