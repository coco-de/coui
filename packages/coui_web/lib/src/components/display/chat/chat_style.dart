import 'dart:math';
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/display/chat/chat_alignment_scope.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output — Chat / ChatGroup row chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Chat` and `ChatGroup`.
///
/// DOM shape (per-alignment chrome baked in at resolve time):
///
/// ```text
/// root (<div>)                              // row container — flex w-full justify-{start|end}
///   ├─ avatarWrapper (<div>)                // co_chat renders only when avatar != null; mounts on leading/trailing side per alignment
///   └─ column (<div>)                       // inline-flex flex-col items-{start|end} min-w-0
///        ├─ header (<div>)                  // co_chat renders only when header != null — text-style inline CSS
///        ├─ bubblesColumn (<div>)           // co_chat_group: wraps consecutive bubbles with native `gap` flex layout (parity with Flutter `Column.spacing`); co_chat: skipped, bubble rendered inline
///        └─ footer (<div>)                  // co_chat renders only when footer != null — text-style inline CSS
/// ```
///
/// All slot chromes are non-null — `co_chat` / `co_chat_group` decide
/// whether to render each optional slot based on instance state.
/// Inter-bubble spacing inside `ChatGroup` is baked into the
/// [bubblesColumn] `<div>`'s native `gap` CSS rule (parity with Flutter
/// `Column.spacing`) — no separator `<div>` interleaved between
/// bubbles.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// `CoreChatStyle` exposes no nested `CoreXxxStyle` slot today, so no
/// Cat 2 slot is forwarded.
class ResolvedChat implements WebResolvedChrome {
  /// Creates a [ResolvedChat].
  const ResolvedChat({
    required this.root,
    required this.column,
    required this.bubblesColumn,
    required this.avatarWrapper,
    required this.header,
    required this.footer,
  });

  /// Paint-ready chrome for the row container `<div>` — `flex w-full
  /// justify-{start|end}` className driven by [CoreChatAlignment].
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner column `<div>` — `inline-flex
  /// flex-col items-{start|end} min-w-0` className driven by
  /// [CoreChatAlignment]. No `gap` rule — inter-bubble spacing belongs
  /// to [bubblesColumn] so `Chat` (single bubble) is unaffected.
  final WebElementChrome column;

  /// Paint-ready chrome for the `ChatGroup` bubbles wrapper `<div>` —
  /// `flex flex-col items-{start|end}` className plus a runtime `gap`
  /// inline CSS rule that reproduces inter-bubble spacing through the
  /// native CSS flex gap (parity with Flutter `Column.spacing`).
  /// `co_chat_group` mounts this wrapper around all bubbles; `co_chat`
  /// skips it and renders its single bubble inline.
  final WebElementChrome bubblesColumn;

  /// Paint-ready chrome for the avatar wrapper `<div>` —
  /// alignment-dependent `margin-inline-{start|end}` inline CSS.
  /// Reused for both leading-avatar (start alignment) and
  /// trailing-avatar (end alignment) placements: the widget decides
  /// which side to mount it on; the chrome itself is identical.
  final WebElementChrome avatarWrapper;

  /// Paint-ready chrome for the optional header text wrapper `<div>`
  /// — empty className; inline CSS carries the [CoreTextStyle]
  /// override (font-size / font-weight / line-height / letter-
  /// spacing / font-family / color) when present.
  final WebElementChrome header;

  /// Paint-ready chrome for the optional footer text wrapper `<div>`
  /// — same shape as [header].
  final WebElementChrome footer;
}

// ═══════════════════════════════════════════════════
// Resolver — Chat / ChatGroup
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChat] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.chat.style
///   → widget.chatStyle
/// ```
///
/// The semantic [alignment] is a widget prop — it threads through to
/// pick row / column / avatar-side classes here. The theme cannot
/// override it (Epic #1603 옵션 B 최종).
ResolvedChat resolveChat(
  BuildContext context, {
  required CoreChatAlignment alignment,
  CoreChatStyle? chatStyle,
}) {
  final chatTheme = context.theme.coreComponentTheme?.chat;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreChatStyle(), [
    chatTheme?.style,
    chatStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final avatarSpacing =
      merged.avatarSpacing ?? CoreChatStyle.defaultAvatarSpacing;
  // `ChatGroup` inter-bubble spacing — caller override wins, else
  // design-system default. Flows directly into the column `<div>`'s
  // native `gap` CSS rule below (parity with Flutter `Column.spacing`).
  final groupSpacing = merged.groupSpacing ?? CoreChatStyle.defaultGroupSpacing;
  final isEnd = alignment == .end;

  // Header / footer typography — the emit family owns the role-class
  // vs overlay-inline split: the token-backed default role goes out as
  // a `text-{role}` class (so both platforms materialise the same
  // typography instead of inheriting divergent ambient defaults) and
  // only explicit per-instance overrides emit inline.
  final headerText = emitTypography(
    merged.headerTextStyle,
    CoreChatStyle.defaultHeaderTextStyle,
  );
  final footerText = emitTypography(
    merged.footerTextStyle,
    CoreChatStyle.defaultFooterTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the row container `<div>` Tailwind className —
  /// `flex w-full justify-{start|end}`.
  String buildRootClassName() {
    final align = isEnd ? WebLayout.justifyEnd : WebLayout.justifyStart;
    return '${WebLayout.flex} ${WebLayout.wFull} $align';
  }

  /// Composes the inner column `<div>` Tailwind className —
  /// `flex flex-col w-full items-{start|end} min-w-0`. The column spans
  /// the full row so the bubble's `max-width: 75%` resolves against the
  /// real available width — a content-sized (inline-flex) column made
  /// the percentage shrink to 75% of the bubble's own intrinsic width,
  /// wrapping the message far narrower than the Flutter twin
  /// (`constraints.maxWidth * factor`). Alignment stays visually
  /// identical: `items-{start|end}` on the full-width column replaces
  /// the row-level shift of the shrink-to-fit column.
  String buildColumnClassName() {
    final cross = isEnd ? WebLayout.itemsEnd : WebLayout.itemsStart;
    return '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull} '
        '$cross ${WebLayout.minWZero}';
  }

  /// Composes the `ChatGroup` bubbles wrapper `<div>` Tailwind
  /// className — `flex flex-col items-{start|end}` (alignment-driven).
  String buildBubblesColumnClassName() {
    return isEnd
        ? '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsEnd}'
        : WebLayout.flexColItemsStart;
  }

  /// Composes the `ChatGroup` bubbles wrapper `<div>` inline CSS —
  /// runtime `gap` rule that reproduces inter-bubble spacing through
  /// the native CSS flex gap (parity with Flutter `Column.spacing`).
  Styles buildBubblesColumnInlineStyles() => .new(
    raw: {'gap': spaceCss(groupSpacing)},
  );

  /// Composes the avatar wrapper `<div>` inline CSS —
  /// `margin-inline-{end|start}` depending on alignment.
  Styles buildAvatarWrapperInlineStyles() {
    return Styles(
      raw: {
        isEnd ? 'margin-inline-start' : 'margin-inline-end': spaceCss(
          avatarSpacing,
        ),
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedChat(
    root: WebElementChrome(className: buildRootClassName()),
    column: WebElementChrome(className: buildColumnClassName()),
    bubblesColumn: WebElementChrome(
      className: buildBubblesColumnClassName(),
      inlineStyles: buildBubblesColumnInlineStyles(),
    ),
    avatarWrapper: WebElementChrome(
      className: '',
      inlineStyles: buildAvatarWrapperInlineStyles(),
    ),
    header: WebElementChrome(
      className: headerText.className,
      inlineStyles: headerText.inline == null
          ? null
          : Styles(raw: headerText.inline),
    ),
    footer: WebElementChrome(
      className: footerText.className,
      inlineStyles: footerText.inline == null
          ? null
          : Styles(raw: footerText.inline),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolved output — ChatBubble bubble + tail chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ChatBubble`.
///
/// DOM shape (per-alignment tail chrome baked in at resolve time):
///
/// ```text
/// // tail = false:
/// root (<div>)                              // inline-block + full chrome inline CSS
///
/// // tail = true:
/// wrapper (<div>)                           // relative inline-block + max-width inline CSS
///   └─ root (<div>)                         // the bubble — relative, positions the tail
///        ├─ child
///        └─ tail (<div>)                    // absolute clip-path pointer, fill inherited from root
/// ```
///
/// The tail is the root's child, not its sibling, so it can inherit the
/// root's *computed* fill. That is what a surface style restates: under a
/// material preset the root's background is the published triplet at the
/// material's share, and a tail painted from the authored token instead
/// stayed at full strength beside a translucent body — the two halves of
/// one silhouette in two different materials.
///
/// `wrapper` and `tail` are null when the bubble draws no tail: either the
/// `tail` prop is off, or the bubble paints no fill for a tail to extend (the
/// `plain` variant, a transparent override). The resolver decides, the widget
/// only reads which slots exist.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// `CoreChatBubbleStyle` exposes no nested `CoreXxxStyle` slot
/// forwarded to a unified child widget today, so no Cat 2 slot is
/// emitted.
class ResolvedChatBubble implements WebResolvedChrome {
  /// Creates a [ResolvedChatBubble].
  const ResolvedChatBubble({
    required this.root,
    this.wrapper,
    this.tail,
  }) : assert(
         (wrapper == null) == (tail == null),
         'wrapper and tail exist together: the tail is drawn inside the '
         'wrapper that owns the width',
       );

  /// Paint-ready chrome for the bubble `<div>` — `inline-block`
  /// className plus full chrome inline CSS (padding /
  /// border-radius / background-color / color / max-width + optional
  /// text-style overrides). The bubble element is always present so
  /// it doubles as the interface `root`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the tail wrapper `<div>` — `relative
  /// inline-block` className plus `max-width` inline CSS. Null when no tail
  /// is drawn — the root then carries the max-width itself.
  final WebElementChrome? wrapper;

  /// Paint-ready chrome for the tail `<div>` — empty className;
  /// inline CSS carries the absolute-anchored box clipped
  /// (`clip-path: path()`) to the same rounded-apex pointer geometry the
  /// Flutter `_ChatTailPainter` draws, filled with `inherit` so it paints
  /// whatever the root paints. Null when no tail is drawn.
  final WebElementChrome? tail;
}

// ═══════════════════════════════════════════════════
// Resolver — ChatBubble
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChatBubble] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → CoreChatBubbleStyle.defaultsByVariant[variant]
///   → theme.coreComponentTheme.chatBubble.style
///   → theme.coreComponentTheme.chatBubble.variantStyles[variant]
///   → widget.chatBubbleStyle
/// ```
///
/// The semantic [variant] / [alignment] / [tail] are widget props —
/// they thread through to pick the variant token table, the bubble
/// max-width / alignment classes, and the tail anchoring side here.
/// The theme cannot override them (Epic #1603 옵션 B 최종).
///
/// A prop the caller states is used as stated. One left `null` is the
/// bubble's to pick: the alignment of the row it sits in
/// ([ChatAlignmentScope]), and from that side the variant and tail it takes
/// by default (`CoreChatBubbleContract.defaultVariantFor` /
/// `defaultTailFor`).
ResolvedChatBubble resolveChatBubble(
  BuildContext context, {
  CoreChatBubbleVariant? variant,
  CoreChatAlignment? alignment,
  bool? tail,
  CoreChatBubbleStyle? chatBubbleStyle,
}) {
  final bubbleAlignment =
      alignment ??
      ChatAlignmentScope.maybeOf(context) ??
      CoreChatAlignment.defaultAlignment;
  final bubbleVariant =
      variant ?? CoreChatBubbleContract.defaultVariantFor(bubbleAlignment);
  final bubbleTail =
      tail ?? CoreChatBubbleContract.defaultTailFor(bubbleAlignment);
  final bubbleTheme = context.theme.coreComponentTheme?.chatBubble;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreChatBubbleStyle(), [
    bubbleTheme?.style,
    bubbleTheme?.variantStyles?[bubbleVariant],
    chatBubbleStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreChatBubbleStyle.defaultsByVariant[bubbleVariant]!;

  // ─── Resolved chrome values ───────────────────────────
  final paddingCore =
      merged.padding ??
      variantStyle.padding ??
      CoreChatBubbleStyle.defaultPadding;
  final mergedRadius =
      merged.borderRadius ?? CoreChatBubbleStyle.defaultBorderRadius;
  final tailEdge = merged.tailEdge ?? CoreChatBubbleStyle.defaultTailEdge;
  final isEnd = bubbleAlignment == .end;
  final onTop = tailEdge == .top;
  final backgroundCore = merged.backgroundColor ?? variantStyle.backgroundColor;
  // A bubble with no fill (the `plain` variant, a transparent override) has
  // no surface: no material marker, no published fill, no tail. Same axis as
  // the Flutter twin's `backgroundColor.a > 0`.
  final hasFill = surfacePaintsFill(backgroundCore);
  final effectiveTail = bubbleTail && hasFill;
  // The tail corner — the tail edge's corner on the alignment side. A
  // drawn pointer flows out of it, so it must be square for the concave
  // curve to continue the bubble edge (daisyUI `border-end-end-radius: 0`
  // convention) — a rounded corner leaves a notch between the bubble and
  // the tail. Without a pointer it is the stated tail corner, else simply
  // the `borderRadius` corner. Same shaping as the Flutter twin.
  final tailCorner = effectiveTail ? 0.0 : merged.tailCornerRadius;
  final radiusCore = tailCorner == null
      ? mergedRadius
      : tailEdge.withTailCorner(
          mergedRadius,
          alignment: bubbleAlignment,
          corner: tailCorner,
        );
  final foregroundCore = merged.foregroundColor ?? variantStyle.foregroundColor;

  final padding = paddingCore.toValue();
  final borderRadius = radiusCore.toValue();
  // The fill through the emit family: a token goes out as a `bg-*` class, a
  // raw colour inline. It used to go inline unconditionally, and an inline
  // declaration outranks every selector — so the rule a material preset
  // writes for marked surfaces (`background-color` at the material's share)
  // never reached this bubble. It was marked, frosted and bent behind a
  // fill that stayed opaque. A class sits under that rule the way every
  // other surface's fill does.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    variantStyle.backgroundColor,
    .background,
  );
  // `.toValue()` is token-safe (token → `rgb(var(--coui-X))`); `.toRgba()`
  // throws on an unresolved token during SSR (#2129).
  final foregroundColor = foregroundCore.toValue();
  final maxWidthFactor =
      merged.maxWidthFactor ??
      variantStyle.maxWidthFactor ??
      CoreChatBubbleStyle.defaultMaxWidthFactor;
  final maxWidthPercent =
      '${(maxWidthFactor * kPercentScale).toStringAsFixed(0)}%';
  final tailWidth = merged.tailWidth ?? CoreChatBubbleStyle.defaultTailWidth;
  final tailHeight = merged.tailHeight ?? CoreChatBubbleStyle.defaultTailHeight;
  final tailTipRadius =
      merged.tailTipRadius ?? CoreChatBubbleStyle.defaultTailTipRadius;
  // Bubble content typography — the emit family owns the role-class vs
  // overlay-inline split (token-backed default role → `text-{role}`
  // class; explicit per-instance overrides → inline), so both platforms
  // materialise the same typography instead of inheriting divergent
  // ambient defaults. An explicit override colour wins over the
  // variant foreground (mirrors Flutter `base.merge(resolved.textStyle)`).
  final bubbleText = emitTypography(
    merged.textStyle,
    CoreChatBubbleStyle.defaultTextStyle,
  );
  final tailWidthRem = tailWidth / kRemDivisor;
  final tailHeightRem = tailHeight / kRemDivisor;

  // ─── Local builders ───────────────────────────────────

  /// Composes the bubble `<div>` Tailwind className — inline-block
  /// plus the content typography role class (`text-{role}`) from the
  /// emit family.
  String buildBubbleClassName() => [
    WebLayout.inlineBlock,
    // The tail is positioned against this box (it is the box's child).
    WebLayout.relative,
    bubbleText.className,
    backgroundEmit.className,
    // Marks this element as a component surface — restated here
    // because ChatBubble can't compose `OutlinedContainer` (its
    // concave tail path is cut against the same fill, #4358).
    if (hasFill) ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the bubble `<div>` inline CSS — full chrome (padding,
  /// border-radius, background, foreground, max-width) plus the
  /// explicit per-instance typography overlays from the emit family
  /// (added last so an explicit override colour wins over the variant
  /// foreground `color` rule).
  Styles buildBubbleInlineStyles() {
    final raw = {
      'padding': padding,
      'border-radius': borderRadius,
      ...?backgroundEmit.inline,
      'color': foregroundColor,
      // 폭 한도는 한 곳만 건다. 꼬리가 있으면 wrapper 가 소유한다(column
      // 폭의 factor%) — 여기서 또 factor% 를 걸면 wrapper 기준으로 이중
      // 적용(75%×75%)되어 말풍선이 Flutter(가용 폭 × factor)보다 훨씬
      // 좁게 wrap 된다. 꼬리가 없으면 wrapper 가 없으니 root 가 직접 건다.
      'max-width': effectiveTail ? '100%' : maxWidthPercent,
      ...?bubbleText.inline,
      // The marker's other half — a preset restates this fill at a
      // lower alpha and cannot know which token the bubble chose.
      if (hasFill) ...surfaceFillVar(backgroundCore),
    };
    return Styles(raw: raw);
  }

  /// Composes the tail wrapper `<div>` Tailwind className.
  String buildWrapperClassName() => WebLayout.relativeInlineBlock;

  /// Composes the tail wrapper `<div>` inline CSS — `max-width`
  /// matching the bubble's so the tail extends past it without
  /// breaking layout.
  Styles buildWrapperInlineStyles() =>
      .new(raw: {'max-width': maxWidthPercent});

  /// Composes the tail `<div>` inline CSS — absolute-anchored,
  /// background-filled box clipped to the exact same path the Flutter
  /// `_ChatTailPainter` draws (shadcn_flutter tail convention): a
  /// right triangle sticking out sideways from the bubble's corner on
  /// the tail edge, alignment side, its outer edge flush with that
  /// edge, outward tip rounded by `tailTipRadius`. The
  /// alignment-side offset keeps the
  /// `CoreChatBubbleContract.tailEdgeOverlap` bubble overlap so no
  /// anti-aliasing seam shows.
  ///
  /// `clip-path: path()` coordinates are unitless user units (px) —
  /// they match the rem-sized box at the 16px root font-size both
  /// platforms render at (Flutter does not text-scale the tail either).
  Styles buildTailInlineStyles() {
    final r = tailTipRadius;
    // Where the rounded tip rejoins the hypotenuse — `r` back from
    // the tip along the hypotenuse direction.
    final hypotenuse = sqrt(tailWidth * tailWidth + tailHeight * tailHeight);
    final backX = r * tailWidth / hypotenuse;
    final backY = r * tailHeight / hypotenuse;
    String f(double v) => v.toStringAsFixed(2);
    // The bottom-edge outline, reflected for a top tail.
    String y(double v) => f(onTop ? tailHeight - v : v);
    // Mirrors _ChatTailPainter.paint — moveTo / lineTo / quadratic
    // tip arc / lineTo / close, per pointing side.
    final d = isEnd
        ? 'M 0 ${y(0)} '
              'L ${f(tailWidth - backX)} ${y(tailHeight - backY)} '
              'Q ${f(tailWidth)} ${y(tailHeight)} '
              '${f(tailWidth - r)} ${y(tailHeight)} '
              'L 0 ${y(tailHeight)} Z'
        : 'M ${f(tailWidth)} ${y(0)} '
              'L ${f(backX)} ${y(tailHeight - backY)} '
              'Q 0 ${y(tailHeight)} ${f(r)} ${y(tailHeight)} '
              'L ${f(tailWidth)} ${y(tailHeight)} Z';
    final offsetRem =
        (tailWidth - CoreChatBubbleContract.tailEdgeOverlap) / kRemDivisor;
    final raw = {
      'position': 'absolute',
      if (onTop) 'top': '0' else 'bottom': '0',
      'width': '${tailWidthRem}rem',
      'height': '${tailHeightRem}rem',
      // The root's computed fill — whatever a material preset restated it
      // to, the tail follows, so body and tail stay one silhouette.
      'background-color': 'inherit',
      'clip-path': "path('$d')",
      if (isEnd) 'right': '-${offsetRem}rem' else 'left': '-${offsetRem}rem',
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedChatBubble(
    root: WebElementChrome(
      className: buildBubbleClassName(),
      inlineStyles: buildBubbleInlineStyles(),
    ),
    wrapper: effectiveTail
        ? WebElementChrome(
            className: buildWrapperClassName(),
            inlineStyles: buildWrapperInlineStyles(),
          )
        : null,
    tail: effectiveTail
        ? WebElementChrome(
            className: '',
            inlineStyles: buildTailInlineStyles(),
          )
        : null,
  );
}
