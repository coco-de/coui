/// Cross-platform contract for unified text-block components.
library;

import 'package:coui_core/coui_core.dart';

/// Contract for a unified text-block component.
///
/// A text block renders a semantic text element ([CoreTextBlockElement])
/// with a typography preset layered on that element's base role. Two of
/// the element roles also carry box chrome — `blockquote` draws a left
/// accent border with an indent, `pre` draws an inline-code surface box
/// — and that chrome enters through the single [textBlockStyle] slot,
/// whose design-system defaults live as `static const` on
/// [CoreTextBlockStyle] so both platforms resolve the same values. The
/// same slot states the text those two roles draw (typography role and
/// colour).
///
/// Type parameter:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreTextBlockContract<W> {
  /// Plain text content to display.
  ///
  /// Ignored when [children] is provided (rich-text composition wins).
  String? get text;

  /// The semantic element to render.
  CoreTextBlockElement get element;

  /// Per-instance override for the `blockquote` / `pre` box chrome —
  /// accent-border colour / width, indent padding, surface fill and
  /// corner radius — and for the text they draw. `null` defers to the
  /// `CoreTextBlockStyle.defaultX` design-system defaults.
  CoreTextBlockStyle? get textBlockStyle;

  /// Rich-text child nodes. When non-null, [text] is ignored.
  List<W>? get children;
}
