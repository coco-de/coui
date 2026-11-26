import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Alert`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="alert">)
///   └─ row (<div>)
///        ├─ icon (<div>)                  // when leading == null
///        │    └─ Icon(iconStyle)
///        │  or leading (<div>)              // when leading != null
///        │    └─ IconTheme(leadingIconStyle)
///        │         └─ leading
///        ├─ Gap(iconContentGapStyle)
///        ├─ content (<div>)
///        │    ├─ title (<div>)
///        │    └─ description (<div>)   // stacked only, and only when description != null
///        ├─ Gap(iconContentGapStyle)  // alert renders only when action != null
///        ├─ action (<div>)              // alert renders only when action != null
///        ├─ Gap(iconContentGapStyle)  // alert renders only when onDismiss != null
///        └─ dismiss (<div>)             // alert renders only when onDismiss != null
///             └─ Button.plain (closeButtonStyle)
///                  └─ Icon(closeButtonStyle.leadingIconStyle)
/// ```
///
/// All slot chromes are non-null — `alert` decides whether to
/// render each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (background / border colour / border radius / padding /
/// foreground colour) is emitted **inline** through
/// `(merged.X ?? CoreAlertStyle.defaultX).toValue()` — no class-drop
/// branch decides between a Tailwind utility and an inline rule. Only
/// pseudo-state (`hover:` / `focus:`) and structural (`flex` /
/// `relative` / `inline-flex` / `items-*`) classes remain on the
/// className surface.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [iconStyle] is forwarded to the variant icon via
///   `Icon(iconStyle: …)`; [leadingIconStyle] is the same size with the
///   glyph colour stated, handed to a caller's `leading` as its ambient
///   `IconTheme` — the way the Flutter twin does, so a bare icon matches
///   the glyph it replaces and nothing else in the slot is recoloured;
///   [iconContentGapStyle] is forwarded to each `Gap(gapStyle: …)`
///   spacer that separates icon → content → action → dismiss;
///   [actionButtonStyle] is forwarded to the action when it is a
///   `Button`; [closeButtonStyle] is raw-forwarded to
///   `Button(variant: .plain, buttonStyle: …)` for the dismiss
///   affordance.
///
/// No scalar metadata (variant / iconSize / etc.) is exposed —
/// semantic identifiers stay on the widget prop.
class ResolvedAlert implements WebResolvedChrome {
  /// Creates a [ResolvedAlert].
  const ResolvedAlert({
    required this.root,
    required this.row,
    required this.icon,
    required this.leading,
    required this.content,
    required this.title,
    required this.description,
    required this.action,
    required this.dismiss,
    required this.iconStyle,
    required this.leadingIconStyle,
    required this.iconContentGapStyle,
    required this.actionButtonStyle,
    required this.closeButtonStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="alert">` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the row wrapper `<div>` (flex container).
  final WebElementChrome row;

  /// Paint-ready chrome for the variant-icon slot `<div>` — carries the
  /// glyph colour as `currentColor` and a line height of 1, which suit a
  /// glyph and nothing else. `alert` draws it only when `leading == null`.
  final WebElementChrome icon;

  /// Paint-ready chrome for the box a caller's `leading` sits in —
  /// structural only. The glyph colour and the glyph's line height are the
  /// [icon] box's, so a text `leading` is not recoloured by it; an icon
  /// there takes the colour from the ambient [leadingIconStyle] instead.
  final WebElementChrome leading;

  /// Paint-ready chrome for the title+description wrapper `<div>`.
  final WebElementChrome content;

  /// Paint-ready chrome for the title `<div>` — one truncated line in the
  /// inline layout.
  final WebElementChrome title;

  /// Paint-ready chrome for the description `<div>` — carries the
  /// title-to-description gap as its top margin, so a title-only alert
  /// adds nothing under the title (the Flutter twin pads the description,
  /// not the title, for the same reason).
  final WebElementChrome description;

  /// Paint-ready chrome for the action slot `<div>` — `alert` skips
  /// this element when `action == null`.
  final WebElementChrome action;

  /// Paint-ready chrome for the dismiss-affordance wrapper `<div>` —
  /// structural only (`shrink-0`); the unified
  /// `Button(variant: .plain)` inside it owns the hover / focus /
  /// cursor chrome via [closeButtonStyle]. `alert` skips this
  /// element when `onDismiss == null`.
  final WebElementChrome dismiss;

  /// Nested `CoreIconStyle` slot — passed to `Icon(iconStyle: …)` for the
  /// variant icon. Carries the layout's icon size and (when overridden)
  /// colour; an unstated colour reaches the glyph from the [icon] box.
  final CoreIconStyle iconStyle;

  /// Nested `CoreIconStyle` slot — the ambient `IconTheme` of a caller's
  /// `leading`: the layout's icon size and the glyph colour, stated
  /// outright (the variant's icon colour unless overridden) because the
  /// [leading] box does not pass one down.
  final CoreIconStyle leadingIconStyle;

  /// Nested `CoreGapStyle` slot — forwarded to each `Gap(gapStyle: …)`
  /// spacer that separates icon → content → action → dismiss. Mirrors
  /// the Flutter `Gap` siblings (icon ↔ content, content ↔ action,
  /// content ↔ dismiss).
  final CoreGapStyle iconContentGapStyle;

  /// Nested `CoreButtonStyle` slot — forwarded to the action when it is
  /// a `Button`. `null` when the caller supplied no action-button
  /// chrome override.
  final CoreButtonStyle? actionButtonStyle;

  /// Nested `CoreButtonStyle` slot for the dismiss affordance —
  /// `CoreAlertStyle.defaultCloseButtonStyle` chained with the
  /// variant-foreground injection layer (icon colour at the idle
  /// opacity, full icon colour on hover) and the per-instance
  /// override, then raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. The button resolves
  /// its own padding / radius / hover-fade / focus ring.
  final CoreButtonStyle closeButtonStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAlert] for the given [context].
///
/// Walks the merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.alert.style
///   → widget.alertStyle
/// ```
///
/// The semantic [variant] and [layout] are widget props — they thread
/// through to pick the variant and layout token tables here and the glyph
/// in `alert`. The theme cannot override them (Epic #1603 옵션 B 최종).
/// [layout] defaults to [CoreAlertLayout.defaultLayout], so a caller that
/// predates it resolves the stacked panel it always did.
ResolvedAlert resolveAlert(
  BuildContext context, {
  required CoreAlertVariant variant,
  CoreAlertLayout layout = CoreAlertLayout.defaultLayout,
  CoreAlertStyle? alertStyle,
}) {
  final alertTheme = context.theme.coreComponentTheme?.alert;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAlertStyle(), [
    alertTheme?.style,
    alertTheme?.variantStyles?[variant],
    alertStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreAlertStyle.defaultsByVariant[variant]!;
  // The layout's measurements — padding, floor, gap, glyph size, title role
  // and colour. Read under the merge chain, so an override wins in either
  // layout. Every row states all six, hence the `!` below.
  final chrome = CoreAlertStyle.defaultsByLayout[layout]!;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family —
  // a single class-XOR-inline decision per design value. Token-bound
  // values (variant defaults AND token overrides) emit Tailwind classes
  // so they stay dark-mode reactive; raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled typography
  // role classes.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    variantStyle.backgroundColor,
    .background,
  );
  // No border by design (`defaultBorderWidth` is stroke0). The slot stays
  // so a caller can opt one back in; unstated it resolves transparent and
  // the zero width means nothing paints regardless.
  final borderEmit = emitColor(
    merged.borderColor,
    CoreAlertStyle.defaultBorderColor,
    .border,
  );
  // A tone's title takes the glyph's colour; `neutral` states none and keeps
  // the layout's. `titleColor` outranks `foregroundColor`, as on Flutter.
  final foregroundEmit = emitColor(
    merged.titleColor ?? merged.foregroundColor,
    variantStyle.titleColor ?? chrome.titleColor!,
    .text,
  );
  // Description reads `onSurfaceVariant` on every tone (the variant row
  // states it), unless the caller's `foregroundColor` says otherwise.
  final descriptionColorEmit = emitColor(
    merged.foregroundColor,
    variantStyle.descriptionColor,
    .text,
  );
  final minHeight = merged.minHeight ?? chrome.minHeight!;
  // Title / description typography — `emitTypography` merges the
  // design-system role default with any per-instance overlay, emitting a
  // `text-{role}` class for a pure role or an inline bundle for a
  // scalar/raw overlay.
  final titleEmit = emitTypography(merged.titleStyle, chrome.titleStyle!);
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    CoreAlertStyle.defaultDescriptionStyle,
  );
  // Nested text colors take precedence at their own face; the root keeps
  // its foreground for leading, action and other inherited content.
  final titleOverridesColor = merged.titleStyle?.color != null;
  final descriptionOverridesColor = merged.descriptionStyle?.color != null;

  final borderWidth = merged.borderWidth ?? CoreAlertStyle.defaultBorderWidth;
  // This surface qualifies for a style's contributed boundary — it paints
  // its own fill and reads as one discrete object, and at either layout's
  // height a contributed stroke has room to sit — and it draws none of its
  // own by
  // default, which is exactly the case the contribution is for. The
  // Flutter twin takes the same boundary through `resolveInjectedBorderSpec`
  // on the `OutlinedContainer` it composes; this side drew nothing, so a
  // boxed style left the alert unboxed on Web alone.
  //
  // A caller who states a width outranks the contribution, as on Flutter:
  // the stroke floor lifts an authored border instead.
  final takesContributedBorder = borderWidth <= 0;
  final borderRadius =
      (merged.borderRadius ?? CoreAlertStyle.defaultBorderRadius).toValue();
  // The stacked panel's horizontal padding is asymmetric (16 leading /
  // 12 trailing), so it is declared directionally and emits as logical
  // properties. The `padding` shorthand is physical by construction and
  // throws for a directional value — deliberately, because flattening it
  // would be right in English and wrong in Arabic with nothing to see in
  // between.
  final paddingDeclarations = (merged.padding ?? chrome.padding!)
      .toLogicalDeclarations('padding');
  // Nested `CoreGapStyle` slot — merge the layout's gap with the
  // per-instance override and forward straight to `Gap(gapStyle: …)`
  // siblings (icon ↔ content, content ↔ action, content ↔ dismiss).
  // Mirrors the Flutter `Gap` parity exemplar (basic/breadcrumb).
  final iconContentGapStyle = chrome.iconContentGapStyle!.merge(
    merged.iconContentGapStyle,
  );
  final titleBottomMargin =
      merged.titleBottomMargin ?? CoreAlertStyle.defaultTitleBottomMargin;

  // Icon style — the layout's glyph size (18 stacked, 16 inline) merged
  // with the per-instance `iconStyle` override.
  final iconStyle = chrome.iconStyle!.merge(merged.iconStyle);
  // Icon colour — slot override wins, else the variant icon colour.
  // Routed through `emitColor` (token → class, raw → inline `color`).
  final iconEmit = emitColor(iconStyle.color, variantStyle.iconColor, .text);
  // The same colour, stated, for a caller's `leading`: that box carries no
  // `currentColor` of its own (see [buildLeadingClassName]), so the glyph
  // colour reaches a bare icon there through the ambient `IconTheme` — as it
  // does on Flutter.
  final leadingIconStyle = CoreIconStyle(
    color: variantStyle.iconColor,
  ).merge(iconStyle);

  // Dismiss-button (Button.plain) chrome — chained
  // `defaultCloseButtonStyle` (4-px tap padding, 4-px corner radius,
  // 150 ms hover transition, 16-px close glyph), tinted with
  // `dismissCore` below, then the per-instance override
  // on top. Raw-forwarded to `Button(variant: .plain,
  // buttonStyle: …)` — the button resolves its own padding / icon /
  // hover-fade / focus-ring (mirrors the toast close button).
  // The glyph states `on-surface-variant` outright, resting and hovered
  // alike — matching Flutter. A tint multiplied by an opacity resolves
  // against whatever panel sits behind it, so no contrast guard can read
  // the result; a token can.
  final dismissCore = merged.dismissColor ?? CoreAlertStyle.defaultDismissColor;
  final closeButtonStyle = CoreAlertStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: dismissCore,
          hoverForegroundColor: dismissCore,
        ),
      )
      .merge(merged.closeButtonStyle);

  // Action-button slot — forwarded straight to a `Button` action by
  // `alert` (Epic #1603 옵션 B coverage gate — `actionButtonStyle`
  // is reflected here).
  final actionButtonStyle = merged.actionButtonStyle;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div role="alert">` Tailwind className —
  /// structural classes plus the emit-family background / border /
  /// foreground colour classes (token values → class, raw → inline).
  String buildRootClassName() => <String>[
    // Flex, not block. The floor lives on this box, so the centring has
    // to live here too — an `align-items` on a `display:block` box is
    // emitted and discarded, which is exactly how this drifted: the
    // declaration was present, inert, and looked like a decision.
    // `relative` stays for absolutely-positioned children.
    '${WebLayout.flexFullItemsCenter} relative',
    // Either the authored border or the contributed one — never both. The
    // `border` utility and an inline width would outrank the marker's
    // rule, so they go out only when the alert states a stroke itself.
    if (takesContributedBorder) kControlBorderMarker else 'border',
    // Marks this as a component surface, so a material preset reaches it.
    // Its Flutter twin has this by composing `OutlinedContainer`; without
    // the restatement here the same alert is glass on one platform and an
    // opaque box on the other — measured, and it was.
    //
    // Paired with the fill publish below: carry the marker alone and the
    // preset's rule resolves against a variable nobody set, which removes
    // the background rather than making it translucent.
    ...webSurfaceMarkerFor(CoreSurfaceRole.content),
    // The alert states no shadow of its own, so it takes the style's —
    // the way its Flutter twin does by composing `OutlinedContainer`.
    // This surface draws its own box here rather than composing that
    // component (a DOM restructure, tracked separately), so the opt-in is
    // restated. No-op under every style that injects no cast.
    kControlShadowRestMarker,
    backgroundEmit.className,
    if (!takesContributedBorder) borderEmit.className,
    foregroundEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the root `<div role="alert">` inline-CSS bundle — border
  /// width / radius / padding plus any raw-override colour fragments
  /// produced by the emit family (token colours stay on classes).
  Styles buildRootInlineStyles() => .new(
    raw: {
      if (!takesContributedBorder) 'border-width': strokeWidthCss(borderWidth),
      'border-radius': borderRadius,
      ...paddingDeclarations,
      // The floor half of the pairing that keeps a description-less alert
      // the same height instead of collapsing around one line. The
      // centring half is `items-center` in `buildRootClassName` — on the
      // SAME box, deliberately, because that box is what the floor opens
      // up. Flutter states the same pair as a ConstrainedBox over a
      // centre-aligned Row. The inline strip states no floor (0), so it
      // emits none and is as tall as its content.
      if (minHeight > 0) 'min-height': '${minHeight / kRemDivisor}rem',
      // The other half of the surface contract — the preset restates the
      // fill at its own alpha, and only the component knows which token
      // it filled with.
      ...surfaceFillVar(
        merged.backgroundColor ?? variantStyle.backgroundColor,
      ),
      ...?backgroundEmit.inline,
      if (!takesContributedBorder)
        ...?borderEmit.inline
      // The contributed boundary's colour is the palette's `outline`,
      // stated by the marker's rule; a colour the caller stated still wins,
      // as `merged.borderColor ?? injected.color` does on Flutter. Inline,
      // so it outranks the rule whichever stylesheet lands later.
      else if (merged.borderColor case final stated?)
        'border-color': stated.toValue(),
      ...?foregroundEmit.inline,
    },
  );

  /// Composes the row wrapper `<div>` Tailwind className — arranges
  /// icon / content / action / dismiss horizontally.
  /// `w-full` because the row is now a flex item of the root and would
  /// otherwise shrink-to-fit; `items-center` so the glyph, the text block,
  /// the action and the dismiss mark share the row's middle — the Flutter
  /// twin's `Row` is centred the same way. The root centres this row inside
  /// the floor, which is what keeps a title-only alert centred rather than
  /// pinned to the top.
  String buildRowClassName() => WebLayout.flexRowItemsCenterFull;

  /// Composes the variant-icon slot Tailwind className — structural
  /// classes plus the emit-family icon colour class (token → class).
  String buildIconClassName() => <String>[
    WebLayout.inlineFlex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    'leading-none',
    WebLayout.shrinkZero,
    iconEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the variant-icon inline-CSS bundle — raw-override icon
  /// colour fragment only (token colour stays on the class). `null` when
  /// the icon colour is token-bound (no inline rule). The icon → content
  /// gap is rendered by a dedicated `Gap` sibling via
  /// [iconContentGapStyle].
  Styles? buildIconInlineStyles() {
    final inline = iconEmit.inline;
    return inline == null || inline.isEmpty ? null : Styles(raw: inline);
  }

  /// Composes the box a caller's `leading` sits in — the glyph box's
  /// structure without its colour and its line height. A text `leading`
  /// then inherits the colour and the line height any other text in the row
  /// does, as it does on Flutter, where the slot is wrapped in an
  /// `IconTheme` and nothing more.
  String buildLeadingClassName() => <String>[
    WebLayout.inlineFlex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    WebLayout.shrinkZero,
  ].join(' ');

  /// Composes the content-wrapper (title + description) Tailwind
  /// className.
  String buildContentClassName() => '${WebLayout.flex1} ${WebLayout.minWZero}';

  /// Composes the content-wrapper inline-CSS bundle — forces
  /// `word-break: break-word` so long English words wrap mid-letter
  /// when the column is narrow (matches Flutter `Text` soft-wrap).
  Styles buildContentInlineStyles() => const .new(
    raw: {
      'word-break': 'break-word',
      'overflow-wrap': 'break-word',
    },
  );

  /// Composes the alert title Tailwind className — the foreground
  /// colour class plus the typography role class from
  /// [titleEmit] (a `text-{role}` class for a pure role; empty for a raw
  /// overlay, which then emits everything inline). A layout that caps the
  /// title (`CoreAlertLayout.titleMaxLines`, one line in the inline strip)
  /// ends it in an ellipsis (`truncate`), as the Flutter twin's `maxLines` /
  /// `TextOverflow.ellipsis` does from the same cap.
  String buildTitleClassName() => <String>[
    if (!titleOverridesColor) foregroundEmit.className,
    titleEmit.className,
    if (layout.titleMaxLines == 1) WebLayout.truncate,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the alert title inline-CSS bundle — any raw-override
  /// foreground fragment and the typography overlay fragments from
  /// [titleEmit] (explicit scalar / raw-colour overrides). `null` when
  /// neither produces an inline rule. The title-to-description gap lives on
  /// the description, so a title-only alert adds nothing under its title.
  Styles? buildTitleInlineStyles() {
    final raw = {
      if (!titleOverridesColor) ...?foregroundEmit.inline,
      ...?titleEmit.inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the alert description Tailwind className — the
  /// foreground colour class plus the typography role class from
  /// [descriptionEmit].
  String buildDescriptionClassName() => <String>[
    if (!descriptionOverridesColor) descriptionColorEmit.className,
    descriptionEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the alert description inline-CSS bundle — the
  /// title-to-description gap (`titleBottomMargin`, as a top margin), the
  /// raw-override description colour fragment and the typography overlay
  /// fragments from [descriptionEmit].
  Styles buildDescriptionInlineStyles() => .new(
    raw: {
      'margin-top': spaceCss(titleBottomMargin),
      if (!descriptionOverridesColor) ...?descriptionColorEmit.inline,
      ...?descriptionEmit.inline,
    },
  );

  /// Composes the action slot Tailwind className — `shrink-0` so the
  /// action does not get squished by long content. The content → action
  /// gap is rendered by a dedicated `Gap` sibling via
  /// [iconContentGapStyle].
  String buildActionClassName() => WebLayout.shrinkZero;

  /// Composes the dismiss-affordance wrapper Tailwind className —
  /// structural only (`shrink-0` so the unified
  /// `Button(variant: .plain)` inside it does not get squished by
  /// long content; the button owns its own hover / focus / cursor
  /// chrome via [ResolvedAlert.closeButtonStyle]). The content →
  /// dismiss gap is rendered by a dedicated `Gap` sibling via
  /// [iconContentGapStyle].
  String buildDismissClassName() => [
    WebLayout.inlineFlex,
    WebLayout.itemsCenter,
    WebLayout.shrinkZero,
  ].join(' ');

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAlert(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    row: WebElementChrome(className: buildRowClassName()),
    icon: WebElementChrome(
      className: buildIconClassName(),
      inlineStyles: buildIconInlineStyles(),
    ),
    leading: WebElementChrome(className: buildLeadingClassName()),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    action: WebElementChrome(className: buildActionClassName()),
    dismiss: WebElementChrome(className: buildDismissClassName()),
    iconStyle: iconStyle,
    leadingIconStyle: leadingIconStyle,
    iconContentGapStyle: iconContentGapStyle,
    actionButtonStyle: actionButtonStyle,
    closeButtonStyle: closeButtonStyle,
  );
}
