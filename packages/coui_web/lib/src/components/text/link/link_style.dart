import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/clickable/clickable_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Link`.
///
/// DOM shape:
///
/// ```text
/// <a href> (anchor) | Clickable (<div role="link">, host)  // anchor when
///   └─ content (<span>, root)                              //   navigating;
///        └─ child | Text(href)                             //   Clickable
///                                                          //   when acting
/// ```
///
/// The inline form (`Link.inlineSpan`) is a single anchor that sits in
/// someone else's paragraph and reads [span]:
///
/// ```text
/// <a href> (span)                              // no typography role —
///   └─ children | Text(text | href)            //   inherits the paragraph
/// ```
///
/// `link.dart` reads each slot's `className` + `inlineStyles` straight
/// from `resolved.<slot>` — no merge / fallback / conversion in the
/// component body.
///
/// A link is read in three shapes, and the shapes differ in who owns the
/// interaction state:
///
/// * an acting link's text is a child of a `Clickable`, which owns hover /
///   focus / press — so the text reveals its underline from the
///   `Clickable`'s state ([host] is the `group` marker that makes that
///   state readable from the child);
/// * a navigating link is its own `<a>`, which is the element that is
///   hovered and focused ([anchor] reveals the underline from its own
///   state and draws the focus ring itself);
/// * an inline link is the same `<a>` without a typography role, always
///   underlined ([span]).
///
/// The resolver carries only `WebElementChrome` slots (paint-ready
/// chrome) and the nested [CoreClickableStyle] slot forwarded to the
/// composed `Clickable`. No scalar metadata is exposed — every override is
/// folded into the chrome.
class ResolvedLink implements WebResolvedChrome {
  /// Creates a [ResolvedLink].
  const ResolvedLink({
    required this.root,
    required this.host,
    required this.anchor,
    required this.span,
    required this.clickableStyle,
    required this.iconStyle,
    required this.iconLabelGapStyle,
  });

  /// Paint-ready chrome for the acting link's content element (label
  /// typography, foreground colour, underline state) — the interaction
  /// chrome (cursor / press / focus ring) is owned by the composing
  /// `Clickable`.
  @override
  final WebElementChrome root;

  /// Chrome merged onto the composing `Clickable`'s root: the `group`
  /// marker the content element's `group-hover:` / `group-focus-visible:`
  /// underline reads.
  final WebElementChrome host;

  /// Paint-ready chrome for the navigating link's `<a href>` — [root]'s
  /// typography and colour, an underline that reveals from the anchor's own
  /// state, and the CoUI focus ring.
  final WebElementChrome anchor;

  /// Paint-ready chrome for the inline anchor — the same foreground colour
  /// and focus ring as [anchor], but always underlined and with no
  /// typography role class: an inline link takes size / weight / leading
  /// from the paragraph around it. Only fields the caller set explicitly
  /// on `CoreLinkStyle.labelStyle` are emitted (inline).
  final WebElementChrome span;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreLinkStyle.defaultClickableStyle` (pins `pressedScale: 1.0`;
  /// inline link text must not press-shrink) merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreIconStyle] for the `leading` / `trailing` icons, laid over
  /// [CoreLinkStyle.defaultIconStyle] and installed as the icons' ambient
  /// theme. Unset, the colour stays null so the glyph paints
  /// `currentColor` — the link's text colour, as on Flutter.
  final CoreIconStyle iconStyle;

  /// Nested [CoreGapStyle] between the label and an icon.
  final CoreGapStyle iconLabelGapStyle;
}

/// Scoped CSS text for the `<style>` block of a Web `Link` anchor.
///
/// Non-empty only when a per-instance / theme override moves the focus ring
/// off the design-system default — preset utility classes can no longer
/// express it, so the anchor gets `#scopeId:focus-visible` rules instead
/// (the ring class is dropped by [resolveLink] in the same condition:
/// class XOR rule). The acting link needs none: its `Clickable` mounts its
/// own.
class ResolvedLinkRules {
  /// Creates a [ResolvedLinkRules].
  const ResolvedLinkRules({required this.css});

  /// Raw CSS rule text — empty when the design-system defaults apply.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry points
// ═══════════════════════════════════════════════════

/// The merged style a link renders from, shared by [resolveLink] and
/// [resolveLinkRules] so both fold the identical chain.
CoreLinkStyle _mergedLinkStyle(
  BuildContext context,
  CoreLinkVariant variant,
  CoreLinkStyle? linkStyle,
) {
  final linkTheme = context.theme.coreComponentTheme?.link;

  return resolveStyleChain(const CoreLinkStyle(), [
    linkTheme?.style,
    linkTheme?.variantStyles?[variant],
    linkStyle,
  ]);
}

/// The ring a link's anchor draws is a `Clickable`'s ring — the nested
/// slot's default merged with the override, which is also what the composed
/// `Clickable` of an acting link receives.
CoreClickableStyle _clickableStyleOf(CoreLinkStyle merged) =>
    CoreLinkStyle.defaultClickableStyle.merge(merged.clickableStyle);

/// Resolves [ResolvedLink] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreLinkStyle.defaultsByVariant[variant],
///                        CoreLinkStyle.defaultX)
///   → theme.coreComponentTheme.link.style
///   → theme.coreComponentTheme.link.variantStyles[variant]
///   → widget.linkStyle
/// ```
///
/// [underline] states that the link is always underlined; it governs the
/// content element and the navigating anchor. The inline form is always
/// underlined whatever it is, so it never reads the flag.
ResolvedLink resolveLink(
  BuildContext context, {
  required CoreLinkVariant variant,
  bool underline = false,
  bool withIcons = false,
  CoreLinkStyle? linkStyle,
}) {
  final merged = _mergedLinkStyle(context, variant, linkStyle);
  final variantStyle = CoreLinkStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome values ───────────────────────────
  final transitionMs =
      (merged.transitionDuration ?? CoreLinkStyle.defaultTransitionDuration)
          .inMilliseconds;
  final interaction =
      merged.interactionTextDecoration ??
      CoreLinkStyle.defaultInteractionTextDecoration;

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = _clickableStyleOf(merged);

  // The ring the anchors draw themselves, and the clock its colour moves on
  // — both read from the Clickable chain the acting link's `Clickable` reads.
  final ring = resolveClickableRing(context, clickableStyle: clickableStyle);
  final ringMs = resolveClickableTiming(
    context,
    clickableStyle: clickableStyle,
  ).durationMs;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound values
  // (the design-system defaults) emit Tailwind classes so they stay
  // dark-mode reactive; raw overrides go inline. No `scheme.resolve` (a
  // no-op on Web) and no hand-rolled `if (override != null)` branches.

  // Effective foreground colour — `labelStyle.color` (nested slot, more
  // specific) wins over the flat `color` override; the variant's design
  // token is the base. `emitColor` emits the token class (`text-link`) by
  // default and inlines a raw override; the role/scalar typography overlay
  // is emitted separately (colour stripped) so the foreground has a single
  // source of truth.
  final foregroundColour =
      merged.labelStyle?.color ?? merged.color ?? variantStyle.color!;
  final foregroundEmit = emitColor(
    foregroundColour,
    variantStyle.color!,
    .text,
  );

  // Underline stroke colour — `text-decoration-color` has no `ColorTarget`
  // in the emit family (the four targets are bg / text / border / ring), so
  // it is emitted as a direct inline rule. The underline tracks the text
  // tone by inheriting `currentColor` (no class emitted), so only a caller
  // override of the underline itself surfaces here.
  final underlineColourOverride = merged.underlineColor;

  // Label typography — `emitTypography` merges the design-system role
  // default (`labelXl`) with the per-instance overlay, emitting a
  // `text-{role}` class for the role plus any explicit scalar overlay
  // (font-size / weight / line-height / letter-spacing) inline. A label
  // colour it may emit is the same value `foregroundEmit` reads first,
  // so the two never disagree.
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreLinkStyle.defaultLabelStyle,
  );

  // Inline-span typography — only the explicit overlay fields; the role is
  // left to the surrounding paragraph. Colour is owned by `foregroundEmit`.
  final spanTypography = merged.labelStyle?.toInlineCss(includeColor: false);

  // ─── Local builders ───────────────────────────────────

  /// Composes the colour / underline classes shared by every slot — the
  /// foreground colour class ([foregroundEmit] — dropped when the caller
  /// overrides the colour, the inline rule then winning via CSS
  /// precedence) and the underline.
  ///
  /// The underline's thickness and position are the font's own
  /// (`decoration-from-font` here, `text-underline-position` inline) — the
  /// same lines Flutter draws by default — so no offset or thickness is
  /// stated.
  ///
  /// A link that is not always underlined reveals the underline on hover,
  /// press and focus. [statePrefix] says whose state: the element's own
  /// (`''`) or an ancestor `Clickable`'s (`'group-'`).
  List<String> buildDecorationClasses({
    required bool alwaysUnderlined,
    String statePrefix = '',
  }) {
    return [
      foregroundEmit.className,
      if (alwaysUnderlined)
        CoreTextDecoration.underline.tailwindDecoration
      else ...[
        CoreTextDecoration.none.tailwindDecoration,
        if (interaction != CoreTextDecoration.none)
          for (final state in const ['hover', 'focus-visible', 'active'])
            '$statePrefix$state:${interaction.tailwindDecoration}',
      ],
      'decoration-from-font',
    ];
  }

  /// Composes a slot's inline-CSS bundle — the transitions (the colour
  /// fade, plus the ring's when [ringed]), the raw foreground override from
  /// [foregroundEmit], the slot's [typography] overlay, the underline-colour
  /// override, the underline position and the explicit font family. Token
  /// values stay on classes and contribute nothing here.
  Styles buildInlineStyles(
    Map<String, String>? typography, {
    required bool ringed,
  }) {
    final easing = CoreEasing.move.toVarCss();
    final raw = {
      // One declaration for every property that fades, so a class and an
      // inline rule never contest the property list.
      'transition': [
        'color ${durationMsCss(transitionMs)} $easing',
        if (ringed) 'outline-color ${durationMsCss(ringMs)} $easing',
      ].join(', '),
      // The font's own underline position; the offset is left `auto`, which
      // is what lets this apply.
      'text-underline-position': 'from-font',
      ...?foregroundEmit.inline,
      ...?typography,
    };

    // Underline stroke colour override (no `ColorTarget` slot) — emitted as
    // a direct `text-decoration-color` inline rule on override only.
    if (underlineColourOverride != null) {
      raw['text-decoration-color'] = underlineColourOverride.toValue();
    }

    return Styles(raw: raw);
  }

  /// Joins [classes] and the ring chrome's, dropping the empty ones.
  String joinClasses(List<String> classes) =>
      classes.where((cls) => cls.isNotEmpty).join(' ');

  /// Merges the ring's inline declarations into [styles] — present only when
  /// the style states a corner radius of its own.
  Styles withRing(Styles styles) =>
      Styles.combine([styles, ?ring.root.inlineStyles]);

  // A link with icons lays them and its label out as one centred row —
  // the Flutter twin's `Row`. The underline still reaches the label: a
  // flex item is in flow, so the decoration propagates into it.
  final iconRow = withIcons
      ? [WebLayout.inlineFlex, WebLayout.itemsCenter]
      : const <String>[];
  final iconStyle = CoreLinkStyle.defaultIconStyle.merge(merged.iconStyle);
  final iconLabelGapStyle = CoreLinkStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedLink(
    iconStyle: iconStyle,
    iconLabelGapStyle: iconLabelGapStyle,
    root: WebElementChrome(
      className: joinClasses([
        ...iconRow,
        labelEmit.className,
        ...buildDecorationClasses(
          alwaysUnderlined: underline,
          statePrefix: 'group-',
        ),
      ]),
      inlineStyles: buildInlineStyles(labelEmit.inline, ringed: false),
    ),
    host: const WebElementChrome(className: 'group'),
    anchor: WebElementChrome(
      className: joinClasses([
        ...iconRow,
        labelEmit.className,
        ...buildDecorationClasses(alwaysUnderlined: underline),
        ring.root.className,
      ]),
      inlineStyles: withRing(
        buildInlineStyles(labelEmit.inline, ringed: true),
      ),
    ),
    span: WebElementChrome(
      className: joinClasses([
        ...buildDecorationClasses(alwaysUnderlined: true),
        ring.root.className,
      ]),
      inlineStyles: withRing(buildInlineStyles(spanTypography, ringed: true)),
    ),
    clickableStyle: clickableStyle,
  );
}

/// Resolves the scoped focus-ring rules of a Web `Link` anchor whose ring
/// deviates from the design-system default (see [ResolvedLinkRules]).
/// Returns empty CSS on the default path.
ResolvedLinkRules resolveLinkRules(
  BuildContext context, {
  required String scopeId,
  required CoreLinkVariant variant,
  CoreLinkStyle? linkStyle,
}) {
  final merged = _mergedLinkStyle(context, variant, linkStyle);

  // The ring is a `Clickable`'s ring, so its scoped rule is the
  // `Clickable`'s — the anchor presses nothing, so no press feedback.
  final rules = resolveClickableRules(
    context,
    scopeId: scopeId,
    enabled: true,
    focusOutline: true,
    enableFeedback: false,
    clickableStyle: _clickableStyleOf(merged),
  );

  return ResolvedLinkRules(css: rules.css);
}
