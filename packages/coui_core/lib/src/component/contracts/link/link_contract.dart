/// Cross-platform contract for unified hyperlink components.
library;

import 'package:coui_core/src/component/contracts/link/link_style.dart';
import 'package:coui_core/src/component/contracts/link/link_variant.dart';

/// Contract for a unified hyperlink component.
///
/// Renders tappable link text that navigates to [href] and / or
/// invokes [onPressed]. Every link chrome / animation override flows
/// through the single [linkStyle] field — see [CoreLinkStyle] for the
/// merge chain. The semantic [variant], the behaviour fields (`href`,
/// `external`, `underline`, `onPressed`) and the [child] slot stay flat on
/// the contract.
///
/// Type parameter:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
///
/// The activation callback is a parameterless `void Function()` —
/// Flutter `VoidCallback` and Web `CoreVoidCallback` are both
/// structural aliases of it, so no separate callback type parameter is
/// needed (the contract keeps only the widget type `<W>` generic).
abstract interface class CoreLinkContract<W> {
  /// Link destination URL.
  ///
  /// When [child] is null the [href] string is rendered as the link
  /// label.
  String get href;

  /// Whether the link opens in a new browsing context.
  ///
  /// On Web sets `target="_blank"` + `rel="noopener noreferrer"`. On
  /// Flutter the host's [onPressed] handler is expected to honour the
  /// external intent (e.g. launching an external browser).
  bool get external;

  /// Whether the link is always underlined.
  ///
  /// Defaults to `false`: a standalone link is recognised by its colour
  /// and shows the underline only while hovered, pressed or focused
  /// (`CoreLinkStyle.interactionTextDecoration`). Set it where the link
  /// sits inside running text, where colour alone cannot carry the
  /// recognition. The inline form (`Link.inlineSpan`) is that placement
  /// and is always underlined, so it takes no such flag.
  bool get underline;

  /// The tone the link reads in — the colour axis. See [CoreLinkVariant].
  CoreLinkVariant get variant;

  /// Callback invoked when the link is activated (tap / click /
  /// keyboard Enter).
  void Function()? get onPressed;

  /// Link content. When null, [href] is rendered as plain text.
  W? get child;

  /// Optional content before [child] — usually an icon that says what the
  /// link is (a link glyph). Absent by default. An icon here takes the
  /// link's text colour and [CoreLinkStyle.iconStyle]'s size, and sits
  /// [CoreLinkStyle.iconLabelGapStyle] away from the label. The underline
  /// stays on the label.
  W? get leading;

  /// Optional content after [child] — usually an icon that says where the
  /// link goes (an external-link glyph for a link that leaves the site).
  /// Absent by default. Styled and spaced like [leading].
  W? get trailing;

  /// Per-instance link style covering chrome + animation overrides plus
  /// the nested label style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreLinkStyle.defaultsByVariant[variant],
  ///                        CoreLinkStyle.defaultX)
  ///   → CoreLinkTheme.style
  ///   → CoreLinkTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.linkStyle
  /// ```
  ///
  /// Named [linkStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreLinkStyle? get linkStyle;
}
