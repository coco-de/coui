import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/link/link_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// The id a link's scoped focus-ring rules are written against, derived from
/// what identifies the link — `seed` is the instance's own key or identity
/// for a widget, the destination for the inline form (which has no instance).
String _scopeIdFor(Object seed) => 'co-link-${seed.hashCode.toRadixString(36)}';

/// A unified cross-platform hyperlink text component for CoUI Web.
///
/// `Link` renders tappable link text that points at [href] and
/// invokes [onPressed] when activated (click / keyboard Enter). A
/// standalone link is recognised by its colour and shows an underline
/// only while hovered, pressed or focused; set [underline] for a link that
/// is always underlined. [variant] picks the tone — `muted` for a link in a
/// supporting position.
///
/// A navigating link (no [onPressed]) renders a real `<a href>`; an
/// acting link renders the composed `Clickable` as `<div role="link">`
/// so keyboard activation and press chrome match the Flutter widget.
/// Inside running text use [Link.inlineSpan]. Every link chrome / animation
/// value flows through the single [linkStyle] field — see [CoreLinkStyle]
/// for the merge chain.
///
/// ```dart
/// Link(
///   href: 'https://example.com',
///   child: text('Visit Example'),
/// )
/// ```
class Link extends UiComponent implements CoreLinkContract<Component> {
  /// Creates a [Link].
  const Link({
    required this.href,
    super.key,
    this.onPressed,
    this.external = false,
    this.underline = false,
    this.variant = CoreLinkVariant.defaultVariant,
    this.linkStyle,
    this.leading,
    this.trailing,
    this.child,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final String href;

  @override
  final CoreVoidCallback? onPressed;

  @override
  final bool external;

  @override
  final bool underline;

  @override
  final CoreLinkVariant variant;

  /// Per-instance link style. See [CoreLinkStyle] for the merge
  /// chain.
  @override
  final CoreLinkStyle? linkStyle;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final Component? child;

  /// A link that flows inside running text — a paragraph, a table cell,
  /// a heading.
  ///
  /// Renders a bare `<a href>` with no typography role, so the link text
  /// wraps with the words around it and takes its size, weight and
  /// leading from the element it sits in. Only the colour comes from
  /// [CoreLinkStyle] (plus any field set explicitly on its `labelStyle`),
  /// through the same resolver as the [Link] component.
  ///
  /// It is always underlined: inside a sentence the colour alone cannot
  /// carry the recognition, so there is no flag to turn it off. It draws the
  /// same focus ring a navigating [Link] does.
  ///
  /// The label is [text], or [children] when the link text itself carries
  /// inline styling. With neither, [href] is shown. With [onPressed] the
  /// anchor keeps its `href` but a click runs the callback instead of
  /// navigating; Enter on the focused anchor does the same.
  ///
  /// Same call shape as the Flutter `Link.inlineSpan`; the Flutter-only
  /// `recognizers` list has no Web counterpart because the anchor owns
  /// its own click handling.
  ///
  /// ```dart
  /// p([
  ///   const Text('Read the '),
  ///   Link.inlineSpan(context, href: '/docs/theming', text: 'theming guide'),
  ///   const Text(' before overriding tokens.'),
  /// ])
  /// ```
  static Component inlineSpan(
    BuildContext context, {
    required String href,
    String? text,
    List<Component>? children,
    CoreVoidCallback? onPressed,
    bool external = false,
    CoreLinkVariant variant = CoreLinkVariant.defaultVariant,
    CoreLinkStyle? linkStyle,
  }) {
    final resolved = resolveLink(
      context,
      variant: variant,
      linkStyle: linkStyle,
    );
    final scopeId = _scopeIdFor(href);
    final rules = resolveLinkRules(
      context,
      scopeId: scopeId,
      variant: variant,
      linkStyle: linkStyle,
    );

    return Component.element(
      tag: 'a',
      id: rules.css.isEmpty ? null : scopeId,
      classes: resolved.span.className,
      styles: resolved.span.inlineStyles,
      attributes: {
        'href': href,
        if (external) ...{
          'target': '_blank',
          'rel': 'noopener noreferrer',
        },
      },
      events: onPressed == null
          ? null
          : {
              'click': (event) {
                // The callback replaces navigation, as it does on the
                // acting [Link] — the href stays for crawlers and
                // middle-click.
                preventDefault(event);
                onPressed();
              },
            },
      children: [
        // `<style>` is `display: none`, so it never affects the line box.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        ...children ?? [Text(text ?? href)],
      ],
    );
  }

  @override
  Link copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? href,
    CoreVoidCallback? onPressed,
    bool? external,
    bool? underline,
    CoreLinkVariant? variant,
    CoreLinkStyle? linkStyle,
    Component? leading,
    Component? trailing,
    Component? child,
  }) {
    return Link(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      href: href ?? this.href,
      external: external ?? this.external,
      underline: underline ?? this.underline,
      variant: variant ?? this.variant,
      linkStyle: linkStyle ?? this.linkStyle,
      id: id ?? this.id,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final currentLeading = leading;
    final currentTrailing = trailing;
    final withIcons = currentLeading != null || currentTrailing != null;
    final resolved = resolveLink(
      context,
      underline: underline,
      variant: variant,
      withIcons: withIcons,
      linkStyle: linkStyle,
    );

    final currentChild = child;
    final label = currentChild ?? Text(href);
    // The icons sit beside the label in the element's own row (the Flutter
    // twin's `Row`), a `Gap` between each and the label. `IconTheme` emits
    // no DOM.
    final contentChildren = withIcons
        ? [
            IconTheme(
              data: IconThemeData.fromCoreIconStyle(resolved.iconStyle),
              child: Component.fragment([
                if (currentLeading != null) ...[
                  currentLeading,
                  Gap(gapStyle: resolved.iconLabelGapStyle),
                ],
                label,
                if (currentTrailing != null) ...[
                  Gap(gapStyle: resolved.iconLabelGapStyle),
                  currentTrailing,
                ],
              ]),
            ),
          ]
        : [label];

    // ── Navigation links render as a real `<a href>` ──────────────
    //
    // When there is no [onPressed], this Link *navigates* — and
    // navigation belongs to an anchor. The `Clickable` path below
    // emits `<div role="link" data-href>`, which on a statically
    // rendered page means: no navigation without JS, nothing for a
    // crawler to follow (Lighthouse `crawlable-anchors`), no
    // middle-click / open-in-new-tab, and no `mailto:` / `tel:`
    // handoff to the OS. `href` never reached the DOM as an `href`.
    //
    // Being its own focusable element, the anchor draws the CoUI focus
    // ring itself (the browser's own outline is replaced) and reveals the
    // underline from its own hover / focus / press.
    //
    // The `Clickable` path is kept for [onPressed] links so the Flutter
    // twin's behaviour (keyboard activation, press chrome) is unchanged.
    if (onPressed == null) {
      // The id only exists to aim the scoped ring rules at this element
      // (or for caller passthrough) — default-path instances stay id-less
      // so SSR markup doesn't churn.
      final scopeId = id ?? _scopeIdFor(key ?? this);
      final rules = resolveLinkRules(
        context,
        scopeId: scopeId,
        variant: variant,
        linkStyle: linkStyle,
      );

      return Component.element(
        tag: 'a',
        id: rules.css.isNotEmpty ? scopeId : id,
        classes: [
          resolved.anchor.className,
          ?classes,
        ].where((c) => c.isNotEmpty).join(' '),
        styles: css == null
            ? resolved.anchor.inlineStyles
            : Styles.combine([?resolved.anchor.inlineStyles, css!]),
        attributes: {
          'href': href,
          // `noopener` keeps the new tab from reaching back into this
          // window; `noreferrer` keeps our URL out of their logs.
          if (external) ...{
            'target': '_blank',
            'rel': 'noopener noreferrer',
          },
          ...componentAttributes,
        },
        events: events,
        children: [
          // `<style>` is `display: none`, so it never affects the line box.
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          ...contentChildren,
        ],
      );
    }

    // Flutter twin: `Clickable(child: link text)` — the composed
    // Clickable owns click / keyboard activation (Enter / Space) /
    // cursor / focus ring (press-shrink is pinned off via the nested
    // clickableStyle slot; inline link text must not squash). The
    // caller chrome (id / classes / css / attributes / eventHandlers)
    // rides the Clickable root, whose generic `role="button"` is
    // overridden to `role="link"` below (caller attributes win); the
    // inner <span> carries only the resolved label chrome. The root also
    // carries the `group` marker the span's underline reads, because it is
    // the Clickable — not the span — that is hovered and focused.
    return Clickable(
      onPressed: onPressed,
      attributes: {
        ...componentAttributes,
        'role': 'link',
        'data-href': href,
        if (external) 'data-external': 'true',
      },
      classes: [
        resolved.host.className,
        ?classes,
      ].where((c) => c.isNotEmpty).join(' '),
      css: css,
      eventHandlers: eventHandlers,
      id: id,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'span',
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
        children: contentChildren,
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `Link.withStyle` extension —
/// merges a [CoreLinkStyle] patch into [Link.linkStyle] via the
/// existing [Link.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLinkStyle.merge` right-side-wins semantics).
extension LinkStyleChain on Link {
  /// Returns a copy of this [Link] with [patch] merged into
  /// [linkStyle] (patch fields win on conflict).
  Link withStyle(CoreLinkStyle patch) =>
      copyWith(linkStyle: (linkStyle ?? const CoreLinkStyle()).merge(patch));
}
