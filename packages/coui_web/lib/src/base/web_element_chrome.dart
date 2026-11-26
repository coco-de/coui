/// Paint-ready chrome (className + optional inline CSS) for a single
/// Web DOM element.
///
/// A `ResolvedXxx` typically owns multiple `<element>` outputs — root
/// `<button>` + content wrapper `<span>`, or root `<div>` + media +
/// content + overlay for a card. Each element needs its own className
/// and inline-CSS bundle; collecting them in a small typed pair keeps
/// the `ResolvedXxx` class flat and avoids the explosion of
/// `xxxClassName` + `xxxInlineStyles` field pairs.
///
/// **Nullable policy.** `co_*` decides per-instance whether to actually
/// render a slot (e.g. button content wrapper only renders when
/// `leading` / `trailing` is present); the resolver always provides the
/// chrome non-null. Slots are `WebElementChrome?` (nullable) only when
/// the slot itself is **designed** to be optional across the component
/// (e.g. card's footer may or may not exist as a design choice).
///
/// ```dart
/// class ResolvedCard implements WebResolvedChrome {
///   const ResolvedCard({
///     required this.root,
///     required this.content,
///     this.footer,
///   });
///
///   @override
///   final WebElementChrome root;
///
///   final WebElementChrome content;
///
///   /// Footer is design-optional — null when card has no footer slot.
///   final WebElementChrome? footer;
/// }
///
/// // co_card.dart
/// Component build(BuildContext context) {
///   final resolved = resolveCard(...);
///   return Component.element(
///     tag: 'div',
///     classes: resolved.root.className,
///     styles: resolved.root.inlineStyles,
///     children: [
///       div([...], classes: resolved.content.className, styles: resolved.content.inlineStyles),
///       if (resolved.footer != null)
///         div([...], classes: resolved.footer!.className, styles: resolved.footer!.inlineStyles),
///     ],
///   );
/// }
/// ```
library;

import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:meta/meta.dart';

/// Paint-ready className + optional inline-CSS pair for one Web DOM
/// element.
@immutable
class WebElementChrome {
  /// Creates paint-ready chrome for a single DOM element.
  const WebElementChrome({required this.className, this.inlineStyles});

  /// Composed Tailwind className for this element.
  final String className;

  /// Inline-CSS bundle for chrome that flows outside Tailwind
  /// classes (token overrides, runtime rem dimensions). `null` when
  /// no inline rules apply.
  final Styles? inlineStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebElementChrome &&
          className == other.className &&
          inlineStyles == other.inlineStyles;

  @override
  int get hashCode => Object.hash(className, inlineStyles);

  @override
  String toString() =>
      'WebElementChrome(className: $className, '
      'hasInlineStyles: ${inlineStyles != null})';
}
