import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';

/// A unified hyperlink text component.
///
/// `Link` renders tappable link text that points at [href] and
/// invokes [onPressed] when activated. A standalone link is recognised by
/// its colour and shows an underline only while hovered, pressed or
/// focused; set [underline] for a link that is always underlined. [variant]
/// picks the tone — `muted` for a link in a supporting position.
///
/// Every link chrome / animation value flows through the single
/// [linkStyle] field — see [CoreLinkStyle] for the merge chain.
///
/// ```dart
/// Link(
///   href: 'https://example.com',
///   onPressed: () => openUrl('https://example.com'),
///   child: const Text('Visit Example'),
/// )
/// ```
///
/// Inside running text use [Link.inlineSpan] instead — `Link` is a
/// widget, so in a `Text.rich` it can only ride a `WidgetSpan`, which
/// never breaks across lines and paints its label in its own label role
/// rather than the paragraph's.
class Link extends StatefulWidget implements CoreLinkContract<Widget> {
  /// Creates a [Link].
  const Link({
    required this.href,
    this.onPressed,
    this.external = false,
    this.underline = false,
    this.variant = CoreLinkVariant.defaultVariant,
    this.linkStyle,
    this.leading,
    this.trailing,
    this.child,
    super.key,
  });

  @override
  final String href;

  @override
  final bool external;

  @override
  final bool underline;

  @override
  final CoreLinkVariant variant;

  @override
  final VoidCallback? onPressed;

  @override
  final CoreLinkStyle? linkStyle;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final Widget? child;

  /// A link that flows inside running text — a `Text.rich`, a table
  /// cell, a heading.
  ///
  /// Returns a [TextSpan], not a widget, so the link text wraps
  /// mid-phrase with the words around it and takes its size, weight and
  /// leading from the paragraph it sits in. Only the colour comes from
  /// [CoreLinkStyle] (plus any field set explicitly on its `labelStyle`),
  /// through the same resolver as the [Link] widget.
  ///
  /// It is always underlined: inside a sentence the colour alone cannot
  /// carry the recognition, so there is no flag to turn it off.
  ///
  /// The label is [text], or [children] when the link text itself carries
  /// inline styling (bold, code). With neither, [href] is shown. Every
  /// text leaf inside [children] receives the tap — a recognizer on a
  /// `TextSpan` covers only its own text, never its children's.
  ///
  /// When [onPressed] is set the span gets a [TapGestureRecognizer],
  /// which also marks it as a link for accessibility. A recognizer must
  /// be disposed by whoever owns the span, so it is added to
  /// [recognizers]: keep that list in the `State` that builds the text,
  /// dispose its entries in `dispose`, and clear them before each rebuild.
  ///
  /// [external] states the same intent as on [Link]; on Flutter the host's
  /// [onPressed] honours it (the Web twin sets `target="_blank"`).
  ///
  /// ```dart
  /// Text.rich(
  ///   TextSpan(children: [
  ///     const TextSpan(text: 'Read the '),
  ///     Link.inlineSpan(
  ///       context,
  ///       href: '/docs/theming',
  ///       text: 'theming guide',
  ///       onPressed: openTheming,
  ///       recognizers: _recognizers,
  ///     ),
  ///     const TextSpan(text: ' before overriding tokens.'),
  ///   ]),
  /// )
  /// ```
  ///
  /// The inline form has no focus ring and does not respond to the
  /// keyboard on its own — a span is not a focusable node. Use the
  /// [Link] widget where the link must be reachable by Tab.
  static InlineSpan inlineSpan(
    BuildContext context, {
    required String href,
    String? text,
    List<InlineSpan>? children,
    VoidCallback? onPressed,
    bool external = false,
    CoreLinkVariant variant = CoreLinkVariant.defaultVariant,
    CoreLinkStyle? linkStyle,
    List<GestureRecognizer>? recognizers,
  }) {
    assert(
      onPressed == null || recognizers != null,
      'Link.inlineSpan creates a TapGestureRecognizer for onPressed; pass '
      'the `recognizers` list that owns (and later disposes) it.',
    );
    final resolved = resolveLink(
      context,
      variant: variant,
      linkStyle: linkStyle,
    );

    final recognizer = onPressed == null
        ? null
        : (TapGestureRecognizer()..onTap = onPressed);
    if (recognizer != null) recognizers?.add(recognizer);

    return TextSpan(
      text: text ?? (children == null ? href : null),
      children: children == null
          ? null
          : [
              for (final span in children)
                _attachLinkRecognizer(span, recognizer),
            ],
      style: resolved.spanTextStyle,
      recognizer: recognizer,
    );
  }

  /// Returns a copy of this [Link] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Link copyWith({
    Key? key,
    VoidCallback? onPressed,
    String? href,
    bool? external,
    bool? underline,
    CoreLinkVariant? variant,
    CoreLinkStyle? linkStyle,
    Widget? leading,
    Widget? trailing,
    Widget? child,
  }) {
    return Link(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      href: href ?? this.href,
      external: external ?? this.external,
      underline: underline ?? this.underline,
      variant: variant ?? this.variant,
      linkStyle: linkStyle ?? this.linkStyle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      child: child ?? this.child,
    );
  }

  @override
  State<Link> createState() => _LinkState();
}

class _LinkState extends State<Link> {
  // State DETECTION lives here (native to Flutter, like the Web CSS
  // pseudo-classes); what each state looks like is resolved by `resolveLink`.
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interacting => _hovered || _focused || _pressed;

  void _handleHover(bool hovered) {
    if (!mounted || _hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _handleFocus(bool focused) {
    if (!mounted || _focused == focused) return;
    setState(() => _focused = focused);
  }

  void _handlePressedChange(bool pressed) {
    if (!mounted || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveLink(
      context,
      underline: widget.underline,
      variant: widget.variant,
      linkStyle: widget.linkStyle,
    );

    // Flutter twin of the Web link: the composed Clickable owns tap /
    // keyboard activation / cursor / focus ring (press-shrink is pinned
    // off via the nested clickableStyle slot — inline link text must
    // not squash) and reports hover / focus / press, which pick the label
    // style that shows the interaction underline. The child supplies the
    // platform's control semantics.
    return Clickable(
      onPressed: widget.onPressed,
      semanticsButton: false,
      onHover: _handleHover,
      onFocus: _handleFocus,
      onPressedChange: _handlePressedChange,
      clickableStyle: resolved.clickableStyle,
      child: AnimatedDefaultTextStyle(
        style: _interacting
            ? resolved.interactionLabelStyle
            : resolved.labelStyle,
        curve: CoreEasing.move.toValue(),
        duration: resolved.transitionDuration,
        child: Semantics(
          button: true,
          // Some web engines need a URL to expose the anchor's role, but
          // a native URL can bypass the host's onPressed. Keep activation
          // with Clickable and preserve the native link declaration.
          link: !kIsWeb,
          child: _content(resolved),
        ),
      ),
    );
  }
}

extension on _LinkState {
  /// The label, with the `leading` / `trailing` icons beside it when the
  /// caller gave any — one centred row, the gap between each icon and the
  /// label. The underline stays on the label's text.
  Widget _content(ResolvedLink resolved) {
    final label = widget.child ?? Text(widget.href);
    final leading = widget.leading;
    final trailing = widget.trailing;
    if (leading == null && trailing == null) return label;
    return IconTheme.merge(
      data: resolved.iconTheme,
      child: Row(
        mainAxisSize: .min,
        children: [
          if (leading != null) ...[
            leading,
            Gap(gapStyle: resolved.iconLabelGapStyle),
          ],
          label,
          if (trailing != null) ...[
            Gap(gapStyle: resolved.iconLabelGapStyle),
            trailing,
          ],
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreLinkStyle] patch into
/// [Link.linkStyle] without hand-reconstructing every field. Mirrors
/// the Web `Link.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLinkStyle.merge` right-side-wins semantics).
extension LinkStyleChain on Link {
  /// Returns a copy of this [Link] with [patch] merged into
  /// [linkStyle] (patch fields win on conflict).
  Link withStyle(CoreLinkStyle patch) =>
      copyWith(linkStyle: (linkStyle ?? const CoreLinkStyle()).merge(patch));
}

/// Rebuilds [span] so every text leaf answers [recognizer].
///
/// A `TextSpan`'s recognizer covers its own text only — hit testing lands
/// on the leaf, and a leaf without its own recognizer ignores the tap even
/// when its parent has one. A leaf that already carries a recognizer keeps
/// it; `WidgetSpan`s pass through untouched.
InlineSpan _attachLinkRecognizer(
  InlineSpan span,
  GestureRecognizer? recognizer,
) {
  if (span is! TextSpan || recognizer == null) return span;
  final ownRecognizer = span.recognizer;
  final childSpans = span.children;
  return TextSpan(
    text: span.text,
    children: childSpans == null
        ? null
        : [
            for (final child in childSpans)
              _attachLinkRecognizer(child, ownRecognizer ?? recognizer),
          ],
    style: span.style,
    recognizer: ownRecognizer ?? recognizer,
    // A deferring cursor is the "no recognizer" default; dropping it lets
    // the span pick the click cursor that comes with the recognizer.
    mouseCursor: span.mouseCursor == MouseCursor.defer
        ? null
        : span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}
