/// `<head>` fragments and preview CSS shared by every docs_site entrypoint.
///
/// The docs pages (`DocsLayout`) and the chrome-less `/embed` route must emit
/// the *same* Tailwind config, CSS variables and fonts — the embed route is
/// what docs_app renders in its Web preview pane, so any divergence here shows
/// up as the two panes disagreeing about the design system. Keeping a single
/// definition (rather than a copy per entrypoint) is what makes that
/// impossible: updating a token or a font updates both callers at once.
library;

import 'package:coui_web/coui_web.dart' show CoreFontFamily, ThemeConfig, iconScript;
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/theme.dart' show ContentColors, ContentTheme, ThemeColor, ThemeColors;

import 'shared/glass_preview_backdrop.dart';
import 'shared/preview_constraints.dart' show kDocsPreviewContentInset;

/// The one theme config for the whole site — source of the Tailwind config,
/// the light CSS variables, and the dark variable overrides.
final _themeConfig = ThemeConfig.defaults();

/// The site-wide `jaspr_content` theme — single source for the docs pages
/// (`main.server.dart`) and the chrome-less `/embed` route.
///
/// The embed route needs it for `ContentTheme.styles`: the theme carries the
/// CSS reset (`reset: true` by default) that the docs pages render previews
/// under — `* { box-sizing: border-box }` plus the UA form-element reset
/// (`button { font-family: inherit; background: transparent; … }`). Without
/// the same reset the embed's components diverge from the site: `w-full` +
/// padding overflows the pane (content-box), `<button>`s keep the UA grey
/// fill / border / Arial font, and native focus outlines leak through.
ContentTheme docsContentTheme() => ContentTheme(
  primary: ThemeColor(
    ThemeColors.indigo.$500,
    dark: ThemeColors.indigo.$400,
  ),
  background: ThemeColor(
    ThemeColors.slate.$50,
    dark: ThemeColors.zinc.$950,
  ),
  colors: [
    ContentColors.quoteBorders.apply(ThemeColors.indigo.$400),
  ],
);

/// Where the site serves the kit's icon stroke normalizer — a package asset
/// Jaspr copies to the site root.
const String kDocsIconStrokeScript = '/packages/coui_web/iconify_stroke.js';

/// `<head>` children that bootstrap the CoUI design system.
///
/// Emitted by every entrypoint that renders CoUI components: the docs pages
/// and the `/embed` route. Deliberately excludes entrypoint-specific assets
/// (the Flutter embed bootstrap, highlight.js, the docs interaction scripts) —
/// those stay with the caller that needs them.
List<Component> docsSharedHead() => [
  // UTF-8 charset must precede any element that contains non-ASCII bytes
  // (Hangul title / description / body) — otherwise the browser decodes the
  // response with its OS default and shows mojibake (`�`). The shelf server
  // doesn't emit a `content-type: text/html; charset=utf-8` header, so this
  // meta is the authoritative declaration.
  Component.element(
    tag: 'meta',
    attributes: {'charset': 'utf-8'},
  ),
  // Pinned to an exact v3 release. The forced-colours focus fix at the app
  // root relies on v3's `outline-none` reserving a transparent outline (v4
  // removes it instead), and the unversioned URL follows whatever the CDN
  // serves that day — a release that changed that class would undo the fix
  // with nothing in this repo moving. Same release the parity harness
  // vendors (tool/parity/vendor/tailwind).
  script(src: 'https://cdn.tailwindcss.com/3.4.17'),
  // Iconify web component for Icon fallback.
  //
  // The stroke normalizer is asked for from the site root. Its default is a
  // relative path, and every page but the home page sits on a nested route:
  // the `<base href>` that would anchor it comes later in the document than
  // this script, so the browser resolved it against the page
  // (`/components/button/packages/…`) and got nothing.
  iconScript(normalizerSrc: kDocsIconStrokeScript),
  // Pretendard font for Flutter/Web visual parity.
  Component.element(
    tag: 'link',
    attributes: {
      'rel': 'stylesheet',
      'href': 'https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css',
    },
  ),
  // Geist Mono (CoreFontFamily.mono) for Flutter/Web parity — from the
  // same master files the Flutter embed draws its mono roles with, so the
  // two panes cannot meet different versions of the face.
  Component.element(
    tag: 'style',
    children: [
      Component.text(_monoFontFaces),
    ],
  ),
  // Tailwind config + CSS variables from coui_web. The config must follow the
  // Tailwind CDN script above — it assigns onto the global the CDN defines.
  Component.element(
    tag: 'script',
    children: [
      Component.text(_themeConfig.tailwindConfig),
    ],
  ),
  Component.element(
    tag: 'style',
    children: [
      Component.text(_themeConfig.cssVariables),
    ],
  ),
  // Dark mode CoUI semantic CSS variables.
  // Injected via JS to prevent Tailwind CDN from scanning dark values and
  // breaking light mode.
  Component.element(
    tag: 'script',
    children: [
      Component.text(_darkCssInjectionScript()),
    ],
  ),
];

/// The `GeistMono` masters `coui_flutter` bundles, by the CSS weight each
/// one is — the four weights it declares, which cover a code role's 400 and
/// the 600 a surface style's weight floor can raise it to.
const _kMonoMasters = {
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
};

/// `@font-face` rules that give the Web side [CoreFontFamily.mono].
///
/// The URLs are where this site already serves those masters: a package
/// font's Flutter asset key is `packages/<package>/<path in its pubspec>`,
/// `jaspr build` copies the Flutter build's `assets/` into the site root,
/// and `jaspr serve` proxies `assets/…` to the Flutter process. A font CDN
/// would serve a newer build of the face than the one Flutter bundles —
/// close, but not the same outlines and metrics.
final String _monoFontFaces = [
  for (final MapEntry(key: weight, value: name) in _kMonoMasters.entries)
    "@font-face{font-family:'${CoreFontFamily.mono}';font-style:normal;"
        'font-weight:$weight;font-display:swap;'
        "src:url('/assets/packages/coui_flutter/lib/fonts/GeistMono-$name.otf') "
        "format('opentype')}",
].join();

/// CSS for the preview surface — the preflight reset plus the LivePreview
/// rules.
///
/// Shared so that a component rendered inside `.preview-content` lands
/// identically on a docs page and in the `/embed` route. The `/embed` route
/// only exercises the `.preview-content` subset; the remaining rules
/// (`.live-preview`, `.preview-code`, `.variant-gallery`) match nothing there
/// and are inert — cheaper than splitting the rules into two lists that would
/// then have to be kept in sync by hand.
List<StyleRule> docsPreviewStyles() => [
  ..._previewPreflightReset(),
  ..._livePreviewStyles(),
];

/// Partial preflight reset for Web preview components.
///
/// Since tailwind.config has `preflight: false`, browser defaults for
/// `<ol>`, `<ul>`, `<a>` etc. persist and break Web component rendering.
/// These rules reset only within the preview pane so docs content is unaffected.
///
/// Every selector here is wrapped in `:where()` so the whole block carries
/// **zero specificity**. It still beats the UA sheet (author origin always
/// does), which is the only thing it is left to beat — but it loses to any
/// utility class a component emits. Written as plain element selectors
/// (`.preview-content a` = 0,1,1) the reset instead outranks single-class
/// utilities (0,1,0) and silently erases component chrome: `Link` emitted
/// `underline text-primary` and rendered as plain black text, because this
/// block's `text-decoration: none` / `color: inherit` won the cascade.
///
/// Dropping to zero specificity is only safe because the preview panes carry
/// `not-content` alongside `preview-content`. `jaspr_content`'s prose rules
/// (`.content :where(p):not(:where([class~="not-content"], …))` = 0,1,0) would
/// otherwise outrank this block and put its own `<p>` margins and link
/// underlines back — the UA sheet is not the only thing styling these tags.
/// `not-content` is that stylesheet's own opt-out, so the prose layer stops at
/// the preview boundary and component chrome is the only thing left inside.
/// Removing `not-content` from a preview wrapper silently re-enables prose
/// there; the two changes only work as a pair.
List<StyleRule> _previewPreflightReset() => [
  // Reset list styles inside preview panes.
  css(':where(.preview-content) :where(ol, ul)').styles(
    raw: {
      'list-style': 'none',
      'padding': '0',
      'margin': '0',
    },
  ),
  css(':where(.preview-content) :where(li)').styles(
    raw: {
      'list-style': 'none',
    },
  ),
  // Reset paragraph + heading margins inside preview panes. Browser
  // defaults add ~1em top/bottom margins to `<p>` / `<h1>`–`<h6>`, which
  // inflate the spacing between a field and its description (etc.) and
  // break parity with Flutter — CoUI drives all spacing via `Gap` /
  // tokens, so these UA margins are always unwanted.
  css(
    ':where(.preview-content) :where(p, h1, h2, h3, h4, h5, h6)',
  ).styles(
    raw: {
      'margin': '0',
      'padding': '0',
    },
  ),
  // Reset link underlines inside preview panes.
  css(':where(.preview-content) :where(a)').styles(
    raw: {
      'text-decoration': 'none',
      'color': 'inherit',
    },
  ),
];

/// Bit positions of each channel within a `0xAARRGGBB` int — [
/// _glassBackdropCss]'s ARGB → CSS hex conversion reads these back out.
const _kAlphaShift = 24;
const _kRedShift = 16;
const _kGreenShift = 8;
const _kBlueShift = 0;
const _kByteMask = 0xFF;

/// CSS `repeating-linear-gradient` angle for lines constant along X
/// (horizontal bands) vs. constant along Y (vertical bands).
const _kHorizontalAxisDeg = 0;
const _kVerticalAxisDeg = 90;

/// Builds the CSS `background` shorthand value for [backdrop] — the CSS
/// emit side of `glass_preview_backdrop.dart`'s platform-neutral data.
/// `background` layers paint front-to-back in list order, so this walks
/// [backdrop] in the order its own doc comment states (grid on top, base
/// fill last).
String _glassBackdropCss(GlassPreviewBackdrop backdrop) {
  // CSS 8-/6-digit hex packs channels RGB(A); the data carries ARGB, so the
  // alpha byte moves from the top to the bottom of the string.
  String channel(int argb, int shift) => ((argb >> shift) & _kByteMask).toRadixString(16).padLeft(2, '0');
  String hex8(int argb) =>
      '#${channel(argb, _kRedShift)}${channel(argb, _kGreenShift)}${channel(argb, _kBlueShift)}${channel(argb, _kAlphaShift)}';
  String hex6(int argb) => '#${channel(argb, _kRedShift)}${channel(argb, _kGreenShift)}${channel(argb, _kBlueShift)}';

  String gridLayer(GlassGridLine line, int axisDeg) =>
      'repeating-linear-gradient(${axisDeg}deg, ${hex8(line.colorArgb)} 0 '
      '${line.lineWidth}px, transparent ${line.lineWidth}px ${line.spacing}px)';

  final band = backdrop.band;
  final bandLayer =
      'linear-gradient(${band.angleDeg}deg, transparent 0 ${band.startPercent}%, '
      '${hex8(band.colorArgb)} ${band.startPercent}% ${band.endPercent}%, '
      'transparent ${band.endPercent}%)';

  final washLayers = backdrop.washes.map(
    (w) =>
        'radial-gradient(circle at ${w.centerXPercent}% ${w.centerYPercent}%, '
        '${hex8(w.colorArgb)}, transparent ${w.radiusPercent}%)',
  );

  return [
    gridLayer(backdrop.horizontalGrid, _kHorizontalAxisDeg),
    gridLayer(backdrop.verticalGrid, _kVerticalAxisDeg),
    bandLayer,
    ...washLayers,
    'var(--color-surface, ${hex6(backdrop.baseColorArgb)})',
  ].join(',');
}

/// LivePreview CSS styles including dark mode, responsive, and animations.
List<StyleRule> _livePreviewStyles() => [
  // Main container.
  css('.live-preview').styles(
    raw: {
      'border': '1px solid var(--color-border, #e2e8f0)',
      'border-radius': '0.5rem',
      'overflow': 'visible',
      'margin': '1.5rem 0',
    },
  ),
  // Two-column grid for Web/Flutter.
  css('.preview-container').styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'minmax(0, 1fr) minmax(0, 1fr)',
      'gap': '1px',
      'background': 'var(--color-border, #e2e8f0)',
      'border-radius': '0.5rem 0.5rem 0 0',
      'overflow': 'hidden',
    },
  ),
  // Stacked layout for wide components (description-card, table, etc.).
  css('.preview-container--stacked').styles(
    raw: {
      'grid-template-columns': '1fr',
    },
  ),
  // Wide components stretch to fill container instead of centering.
  css('.preview-container--stacked .preview-content').styles(
    raw: {
      'align-items': 'stretch',
    },
  ),
  // Allow stacked panes to grow with content (no clipping).
  css('.preview-container--stacked .preview-pane').styles(
    raw: {
      'overflow': 'visible',
    },
  ),
  // Preview panes.
  css('.preview-pane').styles(
    raw: {
      // Both panes use the same semantic surface as the Flutter embed.
      // CoUI's variables contain RGB channels, rather than a CSS color.
      'background': 'rgb(var(--coui-surface))',
      'padding': '1.5rem',
      'overflow': 'hidden',
      'min-width': '0',
    },
  ),
  // A backdrop the glass style has something to be glass *about*.
  //
  // Scoped to that one style on purpose. A translucent, blurred,
  // saturation-boosting surface over a flat opaque pane is
  // indistinguishable from an opaque one — the material is applied and
  // there is nothing behind it to show through, so the preview says
  // "this looks like every other panel" about the one style whose whole
  // point is that it does not. Every other style keeps the flat pane, so
  // their captures are unchanged.
  //
  // Colour alone is not enough, which is the part this pane was missing.
  // Two of the material's terms act on *structure*, not on hue:
  //
  //   - Refraction bends what is behind the surface, and bending a smooth
  //     gradient yields a smooth gradient. A correct displacement and no
  //     displacement at all then render the same picture.
  //   - Frost is a question about how much fine detail survives, so a
  //     backdrop carrying no fine detail cannot separate one blur from
  //     another.
  //
  // Measured on a card, as the worst channel change between the shipped
  // frame and the same frame with one term wound back:
  //
  //     backdrop            refraction on/off    blur 4 vs 12
  //     washes only                        22               4
  //     + band + grid                     107              29
  //
  // Four in a channel is not a difference anyone can see, which is what
  // "the frost decision cannot be judged here" looks like as a number.
  //
  // The band does most of that work and the grid is deliberately quiet:
  // band-only already scores 103/25, so a louder field buys a couple of
  // levels and costs the component's legibility. What the grid adds is
  // coverage — the band crosses one part of one rim, and a component sits
  // wherever it sits.
  //
  // Both are coarse on purpose. The filter list runs blur *before* the
  // displacement, so anything finer than the blur radius is erased before
  // refraction can bend it: the 1px hairlines this replaced were doing
  // nothing for either question.
  //
  // Scoped further to `.preview-web` — not `.preview-flutter` — because
  // Flutter now paints this same recipe itself
  // (`glass_preview_backdrop_painter.dart`) as an opaque layer covering its
  // own canvas. Leaving this rule on `.preview-flutter` too used to put the
  // pattern on *both* the DOM element and the canvas painted on top of it;
  // wherever the canvas came up even a pixel short of that element's own
  // box (a `ViewConstraints`/measured-height mismatch — routine, not a
  // bug on its own), the element's own CSS background showed through
  // beneath the canvas — computed against that *element's* full height,
  // not the canvas's. Two copies of the same band, each solving for a
  // different total height, met at the seam at a visibly different slope
  // — a kink partway down a line that should have been straight, which is
  // a worse failure than the plain surface colour the base `.preview-pane`
  // rule below now shows in that gap instead.
  css('[data-coui-style="liquidGlass"] .preview-pane.preview-web').styles(
    raw: {'background': _glassBackdropCss(kGlassPreviewBackdropLight)},
  ),
  // Compound, not descendant. The site sets both attributes on the *same*
  // element (`<html>`), so a space here asks for a `data-coui-style` node
  // nested inside a `data-theme` node and matches nothing — which is what
  // it did: the dark glass pane rendered flat, with neither the washes nor
  // anything else, for as long as this rule has existed.
  css(
    '[data-theme="dark"][data-coui-style="liquidGlass"] .preview-pane.preview-web',
  ).styles(
    raw: {'background': _glassBackdropCss(kGlassPreviewBackdropDark)},
  ),
  // Label with colored dot.
  css('.preview-label').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '0.375rem',
      'font-size': '0.6875rem',
      'font-weight': '600',
      'text-transform': 'uppercase',
      'letter-spacing': '0.05em',
      'color': 'var(--color-text-secondary, #64748b)',
      'margin-bottom': '0.75rem',
    },
  ),
  css('.preview-label-dot').styles(
    raw: {
      'width': '6px',
      'height': '6px',
      'border-radius': '50%',
    },
  ),
  css('.preview-label-dot--web').styles(
    raw: {
      'background': '#3b82f6',
    },
  ),
  css('.preview-label-dot--flutter').styles(
    raw: {
      'background': '#06b6d4',
    },
  ),
  // Content area — center both Web and Flutter components.
  css('.preview-content').styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      // Top-align so short components don't drift down the box.
      // Mirrors Flutter preview's `Align(topCenter)` setup in
      // `widgets/preview_app.dart` so Web/Flutter share the same
      // baseline regardless of component height.
      'justify-content': 'flex-start',
      'min-height': '60px',
      // Breathing room above and below the preview. Both panes carry this
      // class, so the stage under it is the only thing that sets their
      // heights — the same tier `maxHeight` on each side.
      'padding-top': '${kDocsPreviewContentInset.toInt()}px',
      'padding-bottom': '${kDocsPreviewContentInset.toInt()}px',
    },
  ),
  // Flutter embed view — fill available width and resolve inner height.
  //
  // FlutterEmbedView renders an outer div with min-height/max-height
  // (no explicit height) and an inner div with height:100%.
  // Without display:flex, the inner div's height:100% resolves to 0
  // because the parent has no explicit height property.
  // Making the outer div a flex column ensures the inner div stretches
  // to fill the min-height.
  css('.preview-content > div[id^="flutter-"]').styles(
    raw: {
      'width': '100%',
      'max-width': '100%',
      'display': 'flex',
      'flex-direction': 'column',
      'overflow': 'hidden',
    },
  ),
  // Ensure flutter-view element respects container bounds.
  css('.preview-content flutter-view').styles(
    raw: {
      'max-width': '100%',
    },
  ),
  // Web embed view — match Flutter's FlutterEmbedView isolation.
  //
  // Floating panels (Popover / Tooltip / DropdownMenu) portal up
  // to the root [OverlayHost] and need viewport-anchored
  // `position: fixed`, so we deliberately do NOT introduce a
  // containing block here (no `transform`, `filter`, `perspective`,
  // `will-change: transform`, etc.). `position: relative` is fine —
  // it only affects descendants with `position: absolute` and does
  // not capture `position: fixed`.
  css('.preview-content > div[id^="web-"]').styles(
    raw: {
      'width': '100%',
      'max-width': '100%',
      'overflow': 'hidden',
      'position': 'relative',
      'display': 'flex',
      'flex-direction': 'column',
      // `align-items: stretch` so the CoUIWeb root (a flex child here)
      // gets the full inline-axis to work with — `w-full` emitted by
      // the root is honoured. The actual visual centering of preview
      // components is delegated one level deeper via the rule below
      // (`> div > .w-full[class*="text-on-surface"]`) so that we
      // mirror Flutter `Align(topCenter)` *inside* the application
      // root without forcing every external `CoUIWeb` user to inherit
      // a `flex flex-col items-center` layout.
      'align-items': 'stretch',
      'padding': '8px 16px',
    },
  ),
  // Visually centre preview components horizontally — applies only
  // inside docs (NOT shipped to external `CoUIWeb` consumers). The
  // selector targets CoUIWeb's outer wrapper `<div>` (matched by its
  // baseline `text-on-surface text-body-medium` classes) so children
  // — whether narrow (Button, Badge, DatePicker) or full-bleed
  // (TextField, Slider, Carousel, Banner) — line up vertically with
  // their Flutter counterparts under `Align(topCenter)`. Full-bleed
  // children still go edge-to-edge because they emit `w-full` on
  // their own root, which expands them to the cross-axis size that
  // matches CoUIWeb's `w-full`.
  css('.preview-content > div[id^="web-"] > div.w-full').styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
    },
  ),
  // Resizable previews must fill the preview width to match their Flutter
  // counterpart. The CoUIWeb scroll-view interceptor wrapper is a flex item
  // under the `align-items: center` root above, so it shrinks to content —
  // and Resizable has no intrinsic width (flex panes use `basis: 0`), so it
  // collapses to the label text width. Stretching the interceptor that wraps
  // a `.coui-resizable-preview` example lets the component's `w-full` resolve
  // to the full preview width. Scoped via `:has()` so narrow components keep
  // their centred layout.
  css(
    '.preview-content > div[id^="web-"] > div.w-full > '
    'div[id^="co-scrollview"]:has(.coui-resizable-preview)',
  ).styles(raw: {'width': '100%'}),
  // Full-bleed components (TextField, TextArea, Slider, Form, Stat, …)
  // emit `w-full` on their own root, but the CoUIWeb scroll-view
  // interceptor wrapper sits between the centred `div.w-full` root and
  // that component root with no width of its own. As a centred flex item
  // (`align-items: center` above) the interceptor shrinks to content,
  // collapsing the inner `w-full` to the label width — so the web side
  // stays narrow while the Flutter twin fills under `Align(topCenter)`.
  // Stretch the interceptor to full width whenever the component root it
  // wraps is full-bleed (`> div.contents > .w-full`). Narrow components
  // (Button, Badge — `inline-flex` root, no `w-full`) are not matched
  // and keep their shrink-to-content + centred layout.
  css(
    '.preview-content > div[id^="web-"] > div.w-full > '
    'div[id^="co-scrollview"]:has(> div.contents > .w-full)',
  ).styles(raw: {'width': '100%'}),
  // Chain examples that compare two styled instances wrap them in a
  // shared `div(classes: 'flex flex-col items-start')` container (the
  // "T1" chain-example authoring convention — `dart run
  // tool/generate_chain_artifacts.dart`). That wrapper carries no width
  // class of its own, so the `:has(> div.contents > .w-full)` rule above
  // — which only looks one level down — misses the full-bleed component
  // root sitting *inside* it and the interceptor stays shrink-to-content
  // (Alert/Banner/ChipInput/Command/DescriptionCard/ItemPicker/
  // PhoneInput/Progress/Stat/Table/TextField/TextArea all hit this).
  // Reach one level deeper, but scoped to that *exact* wrapper shape —
  // not a bare descendant match. Components whose extra wrapper is a
  // deliberate *fixed*-width sizing box (DatePicker/TimePicker/Fieldset's
  // `w-{token}` preview box, DraggablePanel's fixed drag-canvas) never
  // carry `flex flex-col items-start`, so they correctly fall through
  // and stay centred — forcing the interceptor to 100% there would strip
  // their centring (nothing re-centres a fixed-width, non-flex child
  // inside a stretched parent) and shift them flush-left instead.
  css(
    '.preview-content > div[id^="web-"] > div.w-full > '
    'div[id^="co-scrollview"]:has('
    '> div.contents > .flex.flex-col.items-start > .w-full'
    ')',
  ).styles(raw: {'width': '100%'}),
  // Cap every interceptor at the preview width so fixed-width content
  // clamps to the pane the way a Flutter `Container(width:)` shrinks to
  // its bounded parent — instead of overflowing (the Web CSS default)
  // and getting clipped by the embed's `overflow: hidden`. `min-width:
  // 0` lets the centred flex item shrink below its intrinsic content
  // width so the cap can bite; the component's own `max-width: 100%`
  // then bounds the fixed-width child to the pane. Content that already
  // fits the pane is unaffected (stays centred at its natural size).
  css(
    '.preview-content > div[id^="web-"] > div.w-full > '
    'div[id^="co-scrollview"]',
  ).styles(raw: {'max-width': '100%', 'min-width': '0'}),
  // Inline-level example roots (Badge, Status, Loading, Kbd …) are
  // baseline-aligned inside the interceptor's inline formatting
  // context: the line-box strut (the base body role's line-height)
  // pushes them a few px below their Flutter twin, which places the
  // widget directly at the pane top. `vertical-align: top` pins the
  // inline root to the line-box top instead. It is a no-op for
  // block-level roots (TextField, Progress, …), so full-bleed layout
  // and the `:has(> div.contents > .w-full)` stretch rule above keep
  // working — no extra wrapper box is introduced.
  css(
    '.preview-content > div[id^="web-"] > div.w-full > '
    'div[id^="co-scrollview"] > div.contents > *',
  ).styles(raw: {'vertical-align': 'top'}),
  css('.preview-unavailable').styles(
    raw: {
      'color': 'var(--color-text-secondary, #94a3b8)',
      'font-size': '0.875rem',
      'font-style': 'italic',
    },
  ),
  // Code section.
  css('.preview-code').styles(
    raw: {
      'border-top': '1px solid var(--color-border, #e2e8f0)',
      'border-radius': '0 0 0.5rem 0.5rem',
      'overflow': 'hidden',
      'position': 'relative',
    },
  ),
  css('.preview-code-header').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'space-between',
      'padding': '0.5rem 1rem',
      'background': 'var(--color-surface-alt, #f8fafc)',
      'border-bottom': '1px solid var(--color-border, #e2e8f0)',
    },
  ),
  // Code tab bar.
  css('.preview-code-tabs').styles(
    raw: {
      'display': 'flex',
      'gap': '0.125rem',
    },
  ),
  css('.preview-code-tab').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '0.375rem',
      'font-size': '0.6875rem',
      'font-weight': '500',
      'text-transform': 'uppercase',
      'letter-spacing': '0.05em',
      'padding': '0.25rem 0.75rem',
      'border-radius': '0.25rem',
      'border': 'none',
      'background': 'transparent',
      'color': 'var(--color-text-secondary, #94a3b8)',
      'cursor': 'pointer',
      'transition': 'all 0.15s ease',
    },
  ),
  css('.preview-code-tab:hover').styles(
    raw: {
      'color': 'var(--color-text, #1e293b)',
      'background': 'var(--color-surface, #ffffff)',
    },
  ),
  css('.preview-code-tab--active').styles(
    raw: {
      'color': 'var(--color-text, #1e293b)',
      'background': 'var(--color-surface, #ffffff)',
      'box-shadow': '0 1px 2px rgba(0, 0, 0, 0.05)',
    },
  ),
  // Code panels (hidden by default, active shown).
  css('.preview-code-panel').styles(
    raw: {
      'display': 'none',
    },
  ),
  css('.preview-code-panel--active').styles(
    raw: {
      'display': 'block',
    },
  ),
  css('.preview-copy-btn').styles(
    raw: {
      'font-size': '0.75rem',
      'padding': '0.25rem 0.75rem',
      'border-radius': '0.25rem',
      'border': '1px solid var(--color-border, #e2e8f0)',
      'background': 'transparent',
      'color': 'var(--color-text-secondary, #64748b)',
      'cursor': 'pointer',
      'transition': 'all 0.15s ease',
    },
  ),
  css('.preview-copy-btn:hover').styles(
    raw: {
      'background': 'var(--color-surface-alt, #f1f5f9)',
      'color': 'var(--color-text, #1e293b)',
    },
  ),
  css('.preview-code pre').styles(
    raw: {
      'margin': '0',
      'border-radius': '0',
    },
  ),
  // Skeleton loader.
  css('.preview-skeleton').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '100%',
      'min-height': '80px',
      'background': 'linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%)',
      'background-size': '200% 100%',
      'animation': 'shimmer 1.5s infinite',
      'border-radius': '4px',
      'position': 'relative',
    },
  ),
  css('.preview-skeleton-text').styles(
    raw: {
      'color': '#94a3b8',
      'font-size': '0.75rem',
    },
  ),
  // Variant gallery — outer margin lives on the wrapper (below), not on
  // `.variant-gallery` itself, because chain now renders as a sibling
  // block *outside* the grid (see `.variant-gallery-wrap` for why).
  css('.variant-gallery-wrap').styles(
    raw: {'margin': '1.5rem 0'},
  ),
  //
  // auto-fit(auto-fill 아님) — 컨테이너 폭이 수용 가능한 트랙 수는
  // auto-fill 과 동일하게 세지만, 그중 아이템이 하나도 없는 트랙은 완전히
  // 접어(0폭) 남는 폭을 실제 아이템에게 재분배한다. auto-fill 이면 그
  // 빈 트랙이 예약된 채로 남아, variant 가 1개뿐인 갤러리(가장 흔한
  // 케이스 — chain 을 뺀 "진짜" variant 가 1개)의 그 하나가 전체 폭이
  // 아니라 트랙 1개 폭에 머물고 옆은 그냥 빈 칸이 된다. 아이템 수가
  // 트랙 수를 다 채울 만큼 많으면 auto-fit/auto-fill 은 동일하게 동작
  // 하므로 다중 variant 갤러리(badge 등)에는 영향 없다.
  //
  // chain 은 이 grid 의 자식이 **아니다** — `.variant-gallery-wrap` 을
  // 참조. grid 안에 두고 `grid-column: 1 / -1` 로 펼치기만 하면, chain
  // 이 걸친 트랙이 "어느 행에서 쓰이는 중"으로 카운트돼 auto-fit 이 그
  // 트랙을 안 접는다 — 그러면 real variant 가 그 안 접힌 트랙 폭에
  // 갇혀 전체 폭을 못 받는다(실측: default 356px / 전체 728px, span 인
  // chain 만 728px). 그래서 chain 은 grid 밖 완전한 별도 형제로 렌더한다.
  css('.variant-gallery').styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fit, minmax(300px, 1fr))',
      'gap': '1rem',
    },
  ),
  // Single-column variant gallery for wide components.
  css('.variant-gallery--stacked').styles(
    raw: {
      'grid-template-columns': '1fr',
    },
  ),
  // chain 이 `.variant-gallery` 뒤에 형제로 오면(= real variant 가
  // 있어 grid 가 렌더된 경우) grid 의 내부 아이템 간격(`gap: 1rem`)과
  // 맞춰 같은 여백을 준다. grid 없이 chain 혼자만 있는 경우(프로덕션에선
  // 안 일어남 — `kDocsChainPreviewMode.appended` 는 항상 최소 `default`
  // 를 끼워 넣는다)는 인접 형제 셀렉터라 매칭되지 않아 이중 여백이 안
  // 생긴다.
  css('.variant-gallery + .variant-gallery-item--chain').styles(
    raw: {'margin-top': '1rem'},
  ),
  css('.variant-gallery-label').styles(
    raw: {
      'font-size': '0.75rem',
      'font-weight': '600',
      'color': 'var(--color-text-secondary, #64748b)',
      'margin-bottom': '0.5rem',
      'text-transform': 'capitalize',
    },
  ),
  // chain 항목 라벨 행 — 순열 칩·셔플 버튼이 같은 행에 앉는 flex. 긴 칩
  // (`.radius9999.surfaceContainer` 류)이 버튼을 밀어내면 wrap 으로 다음 줄.
  css('.variant-gallery-label--chain').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '0.5rem',
      'flex-wrap': 'wrap',
    },
  ),
  // 아일랜드 루트가 flex 배치를 가로막지 않게 — 칩/버튼/SR 리전이 라벨
  // 행의 직접 자식처럼 흐른다.
  css('.chain-shuffle-control').styles(raw: {'display': 'contents'}),
  // 순열 칩 = 재현 좌표 표기 — 라벨 행의 capitalize 상속이 좌표를
  // 왜곡하면(`.Radius16.Primary`) "칩 = 재현 좌표" 가 표시 레벨에서
  // 깨지므로 monospace + text-transform 명시 해제.
  css('.chain-permutation-chip').styles(
    raw: {
      'font-family': 'ui-monospace, SFMono-Regular, Menlo, monospace',
      'font-weight': '400',
      'font-size': '0.6875rem',
      'text-transform': 'none',
      'color': 'var(--color-text-secondary, #64748b)',
    },
  ),
  // 셔플 버튼 — 갤러리-로컬 어휘(.preview-copy-btn 레시피)를 시맨틱
  // 클래스로. 헤더 컨트롤(.surface-style-switcher) 클래스 차용은 후손
  // 셀렉터 유출 위험이라 금지. focus outline 은 UA 기본 유지(억제 금지).
  css('.chain-shuffle-btn').styles(
    raw: {
      'margin-left': 'auto',
      'font-size': '0.6875rem',
      'padding': '0.25rem 0.75rem',
      'border-radius': '0.25rem',
      'border': '1px solid var(--color-border, #e2e8f0)',
      'background': 'transparent',
      'color': 'var(--color-text-secondary, #64748b)',
      'cursor': 'pointer',
      'transition': 'all 0.15s ease',
      'text-transform': 'none',
    },
  ),
  css('.chain-shuffle-btn:hover').styles(
    raw: {
      'background': 'var(--color-surface-alt, #f1f5f9)',
      'color': 'var(--color-text, #1e293b)',
    },
  ),
  // SR 전용 통보 리전 — 시각 표면에서 제거하되 접근성 트리에는 남긴다.
  css('.chain-sr-only').styles(
    raw: {
      'position': 'absolute',
      'width': '1px',
      'height': '1px',
      'padding': '0',
      'margin': '-1px',
      'overflow': 'hidden',
      'clip': 'rect(0, 0, 0, 0)',
      'white-space': 'nowrap',
      'border': '0',
    },
  ),
  css('.variant-gallery-item .live-preview').styles(
    raw: {
      'margin': '0',
    },
  ),
  // Dark mode.
  css('[data-theme="dark"] .preview-code-header').styles(
    raw: {
      'background': 'var(--color-surface-alt, #0f172a)',
    },
  ),
  css('[data-theme="dark"] .preview-code-tab:hover').styles(
    raw: {
      'color': 'var(--color-text, #f1f5f9)',
      'background': 'var(--color-surface, #1e293b)',
    },
  ),
  css('[data-theme="dark"] .preview-code-tab--active').styles(
    raw: {
      'color': 'var(--color-text, #f1f5f9)',
      'background': 'var(--color-surface, #1e293b)',
      'box-shadow': '0 1px 2px rgba(0, 0, 0, 0.2)',
    },
  ),
  css('[data-theme="dark"] .preview-skeleton').styles(
    raw: {
      'background': 'linear-gradient(90deg, #1e293b 25%, #334155 50%, #1e293b 75%)',
      'background-size': '200% 100%',
    },
  ),
  css('[data-theme="dark"] .preview-skeleton-text').styles(
    raw: {
      'color': '#475569',
    },
  ),
];

/// JS script that dynamically injects dark mode CSS variables.
///
/// Using JS injection instead of `<style>` to prevent Tailwind CDN
/// from scanning dark values and overriding light mode colors.
String _darkCssInjectionScript() {
  // The rules come from the library rather than being spelled out here —
  // an app should not have to know the attribute names or which variables
  // an axis writes. Surface-style rules ride along because they switch the
  // same variables and would otherwise need this same escape hatch.
  final rules =
      '${_themeConfig.darkVariableBlock}'
      '${_themeConfig.surfaceStyleVariableBlocks}';

  return '(function(){'
      'var s=document.createElement("style");'
      's.textContent=\'$rules\';'
      'document.head.appendChild(s);'
      '})()';
}
