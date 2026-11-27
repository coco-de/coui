import 'dart:convert';

import 'package:puppeteer/puppeteer.dart';

import 'bottom_action_bar_ssr_source.dart';
import 'breakpoint_showcase_ssr_source.dart';
import 'device_paint_source_probe.dart';
import 'showcase_allocation_ssr_source.dart';
import 'text_showcase_ssr_source.dart';

/// The canonical raw probe shared by browser transports.
/// Extra arguments cannot supply an unwitnessed paint node to this legacy API.
String get computedStyleProbeScript =>
    '(selector) => ($_kComputedStyleJs)(selector)';

/// Runs both samplers with the Device paint node kept inside this validated
/// request wrapper. Only this module can supply the private paint argument.
String sourceValidatedComputedStyleAndBoxScript(String boxSamplerScript) =>
    '''
(request) => {
  const bottom = ($bottomActionBarRequestBindingScript)(request);
  if (bottom.error) throw new Error(bottom.error);
  if (bottom.applied && !bottom.validateCurrentBinding()) throw new Error('BOTTOM_ACTION_BAR_CURRENT_BINDING_CHANGED');
  const showcase = ($showcaseAllocationRequestBindingScript)(request);
  if (showcase.error) throw new Error(showcase.error);
  if (showcase.applied && !showcase.validateCurrentBinding()) throw new Error('SHOWCASE_ALLOCATION_CURRENT_BINDING_CHANGED');
  const breakpoint = ($breakpointShowcaseRequestBindingScript)(request);
  if (breakpoint.error) throw new Error(breakpoint.error);
  if (breakpoint.applied && !breakpoint.validateCurrentBinding()) throw new Error('BREAKPOINT_SHOWCASE_CURRENT_BINDING_CHANGED');
  const text = ($textShowcaseRequestBindingScript)(request);
  if (text.error) throw new Error(text.error);
  if (text.applied && !text.validateCurrentBinding()) throw new Error('TEXT_SHOWCASE_CURRENT_BINDING_CHANGED');
  const paint = ($devicePaintSourceResolverScript)(request);
  if (paint.error) throw new Error(paint.error);
  if (paint.applied && !paint.validateCurrentBinding()) throw new Error('DEVICE_PAINT_SOURCE_STALE');
  const legacy = JSON.parse(($_kComputedStyleJs)(request.selector,paint.applied ? paint.sourcePaintElement : null));
  if (bottom.applied && !bottom.validateCurrentBinding()) throw new Error('BOTTOM_ACTION_BAR_BINDING_CHANGED_DURING_LEGACY_READ');
  if (showcase.applied && !showcase.validateCurrentBinding()) throw new Error('SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_LEGACY_READ');
  if (breakpoint.applied && !breakpoint.validateCurrentBinding()) throw new Error('BREAKPOINT_SHOWCASE_BINDING_CHANGED_DURING_LEGACY_READ');
  if (text.applied && !text.validateCurrentBinding()) throw new Error('TEXT_SHOWCASE_BINDING_CHANGED_DURING_LEGACY_READ');
  if (paint.applied && !paint.validateCurrentBinding()) throw new Error('DEVICE_PAINT_SOURCE_STALE');
  const box = JSON.parse(($boxSamplerScript)(request));
  if (bottom.applied && !bottom.validateCurrentBinding()) throw new Error('BOTTOM_ACTION_BAR_BINDING_CHANGED_DURING_BOX_READ');
  if (showcase.applied && !showcase.validateCurrentBinding()) throw new Error('SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_BOX_READ');
  if (breakpoint.applied && !breakpoint.validateCurrentBinding()) throw new Error('BREAKPOINT_SHOWCASE_BINDING_CHANGED_DURING_BOX_READ');
  if (text.applied && !text.validateCurrentBinding()) throw new Error('TEXT_SHOWCASE_BINDING_CHANGED_DURING_BOX_READ');
  if (paint.applied && !paint.validateCurrentBinding()) throw new Error('DEVICE_PAINT_SOURCE_STALE');
  return JSON.stringify({legacy,box});
}
''';

/// Reads raw `getComputedStyle()` values for whatever [selector] matches.
///
/// This is deliberately **raw** — browser strings (`'16px'`, `'rgb(29, 29,
/// 31)'`, `'400'`), not the normalized `{r,g,b,a}` / px-double schema
/// `PropertySnapshot` uses. Converting units and color spaces is
/// Normalizer's job (#3606) — `.bmad/architecture-*.md` Component ④, and
/// its own completion definition treats "same physical quantity, different
/// input unit" as the exact failure mode it exists to guard. Capturing
/// pre-normalized here would duplicate that conversion in two places with
/// no way to keep them in agreement.
///
/// [selector] is a complete CSS query, whatever the `ProbeSpec.webSelector`
/// for the role being captured states — this function does not special
/// case the `root` role (see `rootProbeSpec` in `../model/probe_spec.dart`
/// for why its selector is shaped `[data-parity-key="…"] > *` rather than
/// this function reaching into a wrapper's `firstElementChild` itself).
///
/// #3852 (Web half) — the six CSS-*inherited* text fields
/// (`fontFamily`/`fontWeight`/`fontSize`/`lineHeight`/`letterSpacing`/
/// `color`) are **not** all read from the matched element itself. See
/// [_kComputedStyleJs]'s own comment for why and how — this mirrors
/// `packages/coui_flutter/test/parity/root_text_probe.dart`'s "root's own
/// declared value, or the first local override found within root" fix for
/// the Flutter half of the same root-attribution gap (#3852's issue body).
///
/// #4872 — box-level fields (background/border*/padding*/outline*/
/// boxShadow) are never CSS-inherited either, but the matched element is
/// not always the box that paints them. Flutter's `byType:` root is a
/// Widget that never paints, so `findChromeNode` walks a single-child path
/// to the first `DecoratedBox`. Web's `[data-parity-key] > *` *is* that
/// painted box for a component whose outer DOM node carries the fill
/// (Button), and an unpainted layout/Clickable wrapper for one that puts
/// chrome on a child (Range track, SwitchField's Toggle). Reading the
/// wrapper described a transparent 800px div against Flutter's pill —
/// 66 (component, variant) on the nightly T2 sweep, one shape, not 66
/// component bugs. [_kFindChromeJs] is the Web twin of `findRootScoped` +
/// `findChromeNode`: stay on the matched node when it paints chrome, else
/// walk. Size (`widthPx`/`heightPx`) and `opacity` still come from the
/// matched node — Flutter reads those off the root finder, not the chrome
/// box. See [_kFindChromeJs] for why a per-component DOM rewrite is the
/// wrong layer.
///
/// The six text fields are `null` when nothing under the matched element
/// paints text at all — no text node outside `<style>`/`<script>` or a
/// hidden subtree, no field holding a value, no placeholder on screen. A
/// `Divider` or a `Range` has an inherited `color` like every element, but
/// no glyph it applies to; reporting it described text that did not exist,
/// and Flutter's twin (`root_text_probe.dart`) says `null` for the same
/// component because it finds no `Text` to read. Measured on the nightly
/// sweep: the six fields disagreed as `flutter=null web=<ambient>` on
/// some forty cells whose roots draw no text. Once text exists anywhere
/// under the root the fallback to the root's own inherited style is kept —
/// raw text that inherits is still text, and Flutter reads a style for it.
Future<Map<String, Object?>?> captureComputedStyle(
  Page page,
  String selector,
) async {
  final json = await page.evaluate<String?>(
    computedStyleProbeScript,
    args: [selector],
  );
  if (json == null) return null;
  return jsonDecode(json) as Map<String, Object?>;
}

/// The element [selector] matches, stepped through box-less wrappers to the
/// box it holds ([kBoxRootJs]) — the element a capture screenshots. `null`
/// when [selector] matches nothing.
Future<ElementHandle?> findBoxRoot(Page page, String selector) async {
  final handle = await page.evaluateHandle<JsHandle>(
    '(sel) => { $kBoxRootJs return boxRoot(document.querySelector(sel)); }',
    args: [selector],
  );

  return handle.asElement;
}

/// [_kDeclaresOwnColorJs] + [_kFindTextSourceJs] implement the Web half of
/// #3852: `[data-parity-key] > *` (`rootProbeSpec`) reads the matched
/// element's **own** `getComputedStyle()` — correct CSS semantics (its own
/// declared value, or whatever it inherits if it declares none). The bug
/// isn't in that semantic, it's that a large share of t1 roots declare no
/// `text-*` color class of their own at all (measured: 40/62 distinct
/// `(component,variant)` root shapes in the t1 manifest), so their own
/// computed `color` is always whatever they inherit from `.coui-root`'s
/// ambient `text-on-surface` — regardless of what color the component's
/// *actual visible text* paints, because that text lives on a descendant
/// element the plain `[data-parity-key] > *` selector never reaches.
///
/// Flutter's matching probe (`root_text_probe.dart`) resolves this by
/// scanning root's own subtree in tree order for the first of two widget
/// types — `DefaultTextStyle` (a wrapper declaring an ambient override for
/// everything under it) or bare `Text` (no local override; its resolved
/// style already *is* whatever's ambient at that point) — and stopping at
/// *whichever comes first*, reading that candidate's own value even when
/// it turns out to be the plain ambient one. [_kFindTextSourceJs] mirrors
/// both candidate types in DOM/CSS terms and applies the same "first
/// found, in either form, wins" rule:
///
/// 1. **Wrapper-declares** (`DefaultTextStyle`-equivalent): an element
///    whose own class list (or inline `style.color`) declares a color
///    rule of its own — [_kDeclaresOwnColorJs]. Root itself qualifies
///    trivially when it declares (checked before any descendant, so nothing
///    can pre-empt it).
/// 2. **Bare-leaf** (`Text`-equivalent): a `<span class="text-inherit">` —
///    CoUI's own `Text()` chain sentinel for "no local color override, read
///    whatever's ambient here" (`web/web-specifics.md`). Its own computed
///    `color` already *is* the correct ambient value at its position,
///    exactly like Flutter's bare-`Text` fallback.
///
/// Whichever of the two is encountered *first* in document order — root
/// itself, then a depth-first walk of its subtree — wins; the walk does
/// not keep looking past it for a "better" (elsewhere-declared) candidate.
/// This is why type 2 has to be a candidate in its own right rather than
/// stopping only at type-1 matches: without it, walking straight past an
/// early bare `text-inherit` leaf (`scaffold`'s own "Dashboard" title, read
/// correctly at 24/25/27) to a *later* element that happens to declare its
/// own color (`scaffold`'s own "Ready" status text, 77/78/81) reproduces
/// the exact "picked an unrelated descendant" defect this fix exists to
/// close — measured as a regression during development (`scaffold`/
/// `refresh-trigger` flipped from matching to failing) before type 2 was
/// added.
///
/// If neither type is found anywhere in the subtree, fall back to the
/// matched element itself — nothing anywhere locally overrides the ambient
/// value, so the matched element's own (inherited) value already *is* the
/// ambient value, same as Flutter's own fallback.
///
/// [_kDeclaresOwnColorJs] answers "does this element declare its own color"
/// by **class-list membership**, not by comparing computed values —
/// comparing `getComputedStyle(node).color` against the parent's was tried
/// first and measurably regressed `color` (31.7%→35.6% failing on the
/// same 202-entry comparable sample): `.coui-root`'s own ambient default
/// **is** `text-on-surface` (`coui_web.dart`'s `defaultTextColor`), so any
/// element that explicitly re-declares `text-on-surface` — the single most
/// common default, e.g. `card`'s and `menu`'s own root class — computes to
/// the *identical* value its parent already had purely by inheritance.
/// Value-comparison cannot tell "explicitly declared, happens to match"
/// apart from "never declared, purely inherited", so it kept walking straight
/// past a root that had, in fact, already declared its own value, into a
/// genuinely unrelated nested sub-component (`card`'s own footer "Action"
/// button, `menu`'s own item secondary-text) and read *that* instead —
/// exactly the "foreign chrome" mistake `root_text_probe.dart`'s own doc
/// comment describes Flutter's naive first-`Text` probe making. Reading the
/// class list directly is immune: it answers "was a color *rule* written
/// for this element" regardless of what value that rule happens to
/// resolve to. The known color-key set — `text-{key}` is Tailwind's
/// *color* utility, distinct from `text-{role}` typography-scale classes
/// sharing the same `text-` prefix (`core/design-tokens.md`'s "size 토큰
/// 함정" is the sibling case for `w-`/`h-`) — is read from the live page's
/// own `tailwind.config.theme.extend.colors` (`theme_config.dart`'s
/// `_colorsConfig`, the single source every capture's Tailwind config was
/// already built from) rather than duplicated as a second, driftable list.
/// A class carrying a pseudo-variant prefix (`hover:text-primary`,
/// `disabled:text-on-surface`) is skipped — it doesn't affect the
/// *rest*-state computed color this probe reads.
///
/// A candidate with `display:none` is skipped — an undeclared-but-present
/// element (a hidden native `<input>` some form components mount for a11y,
/// `web/web-specifics.md`) can carry its own `color` declaration that
/// nothing ever paints; picking it as the representative would defeat the
/// entire point of finding what's *actually visible*.
///
/// A third candidate sits ahead of both, because it is not reachable by
/// walking at all: a field currently showing its **`::placeholder`**. See
/// [_kFindTextSourceJs]'s own comment for the rule and why the pseudo is
/// read only while it is what's on screen.
const String _kDeclaresOwnColorJs = r'''
function declaresOwnColor(node) {
  if (node.style && node.style.color) return true;
  if (!node.classList) return false;
  let colorKeys;
  try {
    colorKeys = window.__coui_parity_color_keys__ ||
      (window.__coui_parity_color_keys__ =
        new Set(Object.keys(tailwind.config.theme.extend.colors)));
  } catch (e) {
    return false;
  }
  for (const cls of node.classList) {
    if (cls.indexOf(':') !== -1) continue;
    const m = /^text-([a-z0-9-]+?)(?:\/\d+)?$/.exec(cls);
    if (m && colorKeys.has(m[1])) return true;
  }
  return false;
}
''';

/// A field showing its placeholder has no DOM node carrying that text — the
/// glyphs come from the browser's `::placeholder` pseudo-element, which
/// `querySelectorAll` cannot reach. Before this, such a field fell through
/// to the root fallback and reported the root's own `color`, i.e. the colour
/// of the value the user has *not* typed. The Flutter twin reports the
/// placeholder's own colour, so the pair diverged on every text input while
/// both platforms were in fact painting the same thing.
///
/// The pseudo is read only while it is what's actually on screen: an
/// `<input>`/`<textarea>` that declares a `placeholder` **and** currently
/// holds no value. A field with a value paints the value, and reading the
/// pseudo there would report a colour nothing draws.
///
/// `value` is read from the live property, not the attribute — the attribute
/// is the initial value and stops tracking once anything is typed.
const String _kFindTextSourceJs = '''
function isBareTextLeaf(node) {
  if (node.tagName === 'SPAN' && node.classList &&
      node.classList.contains('text-inherit')) return true;
  // Raw text can sit directly in a semantic wrapper without the Text
  // chain sentinel. Do not walk past it to a later secondary label.
  return Array.from(node.childNodes).some(child =>
    child.nodeType === Node.TEXT_NODE &&
    child.nodeValue && child.nodeValue.trim());
}

function isTextCandidate(node) {
  // Graphic-only wrappers also carry colour (e.g. an icon button).
  // Keep field declarations, including the existing empty-field contract.
  const tag = node.tagName.toUpperCase();
  if (tag !== 'INPUT' && tag !== 'TEXTAREA' && !hasVisibleText(node)) return false;
  return declaresOwnColor(node) || isBareTextLeaf(node);
}

function showsPlaceholder(node) {
  const tag = node.tagName;
  if (tag !== 'INPUT' && tag !== 'TEXTAREA') return false;
  if (!node.hasAttribute('placeholder')) return false;
  if (!node.getAttribute('placeholder')) return false;
  return !node.value;
}

// Whether anything under `el` (inclusive) actually paints glyphs: a
// non-blank text node outside <style>/<script> and outside any
// `display:none` subtree, or a form field currently holding a value.
function isHiddenUnder(node, root) {
  if (getComputedStyle(node).visibility !== 'visible') return true;
  let ancestor = node;
  while (ancestor && ancestor !== root.parentElement) {
    const tag = ancestor.tagName.toUpperCase();
    if (tag === 'STYLE' || tag === 'SCRIPT' ||
        tag === 'TITLE' || tag === 'DESC') return true;
    const style = getComputedStyle(ancestor);
    if (style.display === 'none' || style.opacity === '0') return true;
    if (style.display !== 'contents') {
      const bounds = ancestor.getBoundingClientRect();
      if ((['hidden', 'clip', 'scroll', 'auto'].includes(style.overflowX) &&
           bounds.width === 0) ||
          (['hidden', 'clip', 'scroll', 'auto'].includes(style.overflowY) &&
           bounds.height === 0)) return true;
    }
    // Screen-reader-only text remains in the DOM but paints no glyphs.
    if (style.clip.startsWith('rect(')) {
      const sides = style.clip.slice(5, -1).replaceAll(',', ' ')
        .split(' ').filter(Boolean).map(Number.parseFloat);
      if (sides.length === 4 && sides.every(Number.isFinite) &&
          sides[0] === sides[2] && sides[1] === sides[3]) return true;
    }
    ancestor = ancestor.parentElement;
  }
  return false;
}

function hasVisibleText(el) {
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
  let textNode;
  while ((textNode = walker.nextNode())) {
    if (!textNode.nodeValue || !textNode.nodeValue.trim()) continue;
    if (!isHiddenUnder(textNode.parentElement, el)) return true;
  }
  const fields = [el, ...el.querySelectorAll('input, textarea')];
  for (const field of fields) {
    const tag = field.tagName;
    if (tag !== 'INPUT' && tag !== 'TEXTAREA') continue;
    if (field.value && !isHiddenUnder(field, el)) return true;
  }
  return false;
}

// Returns { node, pseudo } — `pseudo` is null for an ordinary element and
// '::placeholder' when the visible text belongs to that pseudo-element.
// `node` is null when nothing under `el` paints any text at all: then
// there is no text style to measure, and reporting `el`'s own inherited
// values would describe glyphs that do not exist (see the Dart-side
// comment on the six text fields being nullable).
function findTextSource(el) {
  if (isHiddenUnder(el, el)) return { node: null, pseudo: null };
  if (showsPlaceholder(el)) return { node: el, pseudo: '::placeholder' };
  if (isTextCandidate(el)) return { node: el, pseudo: null };
  const candidates = el.querySelectorAll('*');
  for (const candidate of candidates) {
    if (isHiddenUnder(candidate, el)) continue;
    // Checked before the generic candidate test: an input that shows its
    // placeholder may also carry its own colour class, and that class
    // describes the value, not the glyphs currently on screen.
    if (showsPlaceholder(candidate)) {
      return { node: candidate, pseudo: '::placeholder' };
    }
    if (isTextCandidate(candidate)) return { node: candidate, pseudo: null };
  }
  if (!hasVisibleText(el)) return { node: null, pseudo: null };
  return { node: el, pseudo: null };
}
''';

/// #4872 — Web twin of `findChromeNode` / `findRootScoped`.
///
/// Why the probe, not 66 component roots: Flutter never paints at the
/// widget class the finder names, so chrome is always a descendant walk.
/// Web's matched node *can* paint (the `<button>` *is* the fill) and
/// rewriting every wrapper that doesn't would duplicate that walk in
/// widget code, breaking the cases where the wrapper is the honest root.
/// Outline-only and radius-only do not count as chrome — Clickable's
/// rest-state ring and an unpainted rounded flex wrapper would otherwise
/// pin the walk to the layout node Flutter never reports.
const String _kFindChromeJs = r'''
function isTransparentColor(c) {
  if (!c || c === 'transparent') return true;
  const m = /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*[,/]\s*([\d.]+))?\s*\)$/.exec(c);
  if (!m) return false;
  return m[4] !== undefined && parseFloat(m[4]) === 0;
}

function isPaintedChrome(node) {
  if (!node || node.nodeType !== 1) return false;
  const s = getComputedStyle(node);
  if (s.display === 'none' || s.visibility === 'hidden') return false;
  const hasFill = !isTransparentColor(s.backgroundColor);
  const hasBorder =
    parseFloat(s.borderTopWidth) > 0 ||
    parseFloat(s.borderRightWidth) > 0 ||
    parseFloat(s.borderBottomWidth) > 0 ||
    parseFloat(s.borderLeftWidth) > 0;
  const hasShadow = s.boxShadow && s.boxShadow !== 'none';
  return hasFill || hasBorder || hasShadow;
}

function elementChildren(node) {
  return [...node.children].filter((c) => {
    const tag = c.tagName;
    if (tag === 'SCRIPT' || tag === 'STYLE') return false;
    return getComputedStyle(c).display !== 'none';
  });
}

function isAbsolutelyPositioned(node) {
  const pos = getComputedStyle(node).position;
  return pos === 'absolute' || pos === 'fixed';
}

function isEmptySibling(node) {
  const r = node.getBoundingClientRect();
  return r.width === 0 && r.height === 0;
}

function findChromeFrom(node) {
  const children = elementChildren(node);
  if (children.length === 0) return null;

  const inFlow = children.filter((c) => !isAbsolutelyPositioned(c));
  let searchable = children;
  if (inFlow.length === 1) {
    const only = inFlow[0];
    return isPaintedChrome(only) ? only : findChromeFrom(only);
  }
  if (inFlow.length > 0 && inFlow.length !== children.length) {
    searchable = inFlow;
  }

  if (searchable.some(isEmptySibling)) return null;

  if (searchable.length === 1) {
    const only = searchable[0];
    return isPaintedChrome(only) ? only : findChromeFrom(only);
  }

  const found = [];
  for (const child of searchable) {
    const hit = isPaintedChrome(child) ? child : findChromeFrom(child);
    if (hit) found.push(hit);
  }
  return found.length === 1 ? found[0] : null;
}

function resolveChrome(el) {
  if (isPaintedChrome(el)) return el;
  return findChromeFrom(el);
}
''';

/// `boxRoot(el)` — `el` itself, or, when `el` is a box-less wrapper
/// (`display: contents`, a `BrightnessScope`), the first element it holds
/// that generates a box, stepping through nested wrappers.
///
/// A `display: contents` element is not a box: its rect is 0×0 and it
/// paints nothing, so neither the screenshot nor the measurements have
/// anything to read on it. The box it holds is the root — what Flutter's
/// root measures, the scope's widgets being single-child proxies of their
/// child's size. Only a wrapper holding exactly one *drawn* element is
/// stepped through: one holding several has no single box to stand for it.
///
/// What counts as drawn is what Flutter's tree would also have as a child.
/// `display: none` (a `<style>`) is not drawn, and neither is an out-of-flow
/// 1×1 element — the visually hidden live region a `LoadingRegion` keeps
/// next to its content, which has no Flutter counterpart in layout. The
/// region sits *beside* the content, so it is the first element under the
/// capture wrapper and the root selector (`[data-parity-key] > *`) lands on
/// it: the capture measured the 1×1 region instead of the content. A match
/// that is not drawn therefore moves on to the next sibling that is.
///
/// Shared by the screenshot ([findBoxRoot]) and the computed-style probe
/// below, so the two read the same element.
const String kBoxRootJs = '''
function isDrawn(c) {
  const cs = getComputedStyle(c);
  if (cs.display === 'none') return false;
  if (cs.position === 'absolute' || cs.position === 'fixed') {
    const r = c.getBoundingClientRect();
    if (r.width <= 1 && r.height <= 1) return false;
  }
  return true;
}
function drawnChildren(el) {
  return Array.from(el.children).filter(isDrawn);
}
function firstDrawn(el) {
  while (el && !isDrawn(el) && el.nextElementSibling) el = el.nextElementSibling;
  return el;
}
function boxRoot(el) {
  el = firstDrawn(el);
  while (el && getComputedStyle(el).display === 'contents') {
    const kids = drawnChildren(el);
    if (kids.length !== 1) break;
    el = kids[0];
  }
  return el;
}
''';

const String _kComputedStyleJs =
    '''
(sel, sourcePaintElement = null) => {
  $_kDeclaresOwnColorJs
  $_kFindTextSourceJs
  $_kFindChromeJs
  $kBoxRootJs
  const el = boxRoot(document.querySelector(sel));
  if (!el) return null;
  const chrome = resolveChrome(el);
  // No painted chrome — report the same "absence" Flutter does
  // (`decoration == null` → padding/fill null). Reading the unpainted
  // wrapper would attribute example layout padding (Text's `p-16`
  // column) to a component that has no box of its own (#4872).
  const box = chrome ? getComputedStyle(chrome) : null;
  // A closed current-producer witness may supply paint authority separately.
  // Padding/outline stay on the existing chrome path; root/text stay below.
  const paintBox = sourcePaintElement ? getComputedStyle(sourcePaintElement) : box;
  const rootStyle = getComputedStyle(el);
  const source = findTextSource(el);
  // Null when the root paints no text — the six text fields below then
  // come out null rather than as the root's inherited (and unused) style.
  const text = source.node
    ? getComputedStyle(source.node, source.pseudo)
    : null;
  // Geometry comes from the rect, NOT from `box.width` / `box.height`.
  // Chrome reports those as the CONTENT box whatever `box-sizing` says,
  // so a padded component would read narrower here than the same
  // component's `RenderBox.size` does on Flutter and every one of them
  // would look divergent. `getBoundingClientRect()` is the border box —
  // the same edge Flutter measures.
  const rect = el.getBoundingClientRect();
  return JSON.stringify({
    fontFamily: text ? text.fontFamily : null,
    fontWeight: text ? text.fontWeight : null,
    fontSize: text ? text.fontSize : null,
    // Inline layout properties do not apply to ::placeholder; the input
    // owns its line box even when the pseudo reports normal.
    lineHeight: source.pseudo === '::placeholder'
      ? getComputedStyle(source.node).lineHeight
      : text ? text.lineHeight : null,
    letterSpacing: text ? text.letterSpacing : null,
    color: text ? text.color : null,
    backgroundColor: paintBox ? paintBox.backgroundColor : 'rgba(0, 0, 0, 0)',
    borderTopColor: paintBox ? paintBox.borderTopColor : 'rgba(0, 0, 0, 0)',
    borderRightColor: paintBox ? paintBox.borderRightColor : 'rgba(0, 0, 0, 0)',
    borderBottomColor: paintBox ? paintBox.borderBottomColor : 'rgba(0, 0, 0, 0)',
    borderLeftColor: paintBox ? paintBox.borderLeftColor : 'rgba(0, 0, 0, 0)',
    borderTopWidth: paintBox ? paintBox.borderTopWidth : '0px',
    borderRightWidth: paintBox ? paintBox.borderRightWidth : '0px',
    borderBottomWidth: paintBox ? paintBox.borderBottomWidth : '0px',
    borderLeftWidth: paintBox ? paintBox.borderLeftWidth : '0px',
    borderTopLeftRadius: paintBox ? paintBox.borderTopLeftRadius : '0px',
    borderTopRightRadius: paintBox ? paintBox.borderTopRightRadius : '0px',
    borderBottomRightRadius: paintBox ? paintBox.borderBottomRightRadius : '0px',
    borderBottomLeftRadius: paintBox ? paintBox.borderBottomLeftRadius : '0px',
    paddingTop: box ? box.paddingTop : '0px',
    paddingRight: box ? box.paddingRight : '0px',
    paddingBottom: box ? box.paddingBottom : '0px',
    paddingLeft: box ? box.paddingLeft : '0px',
    outlineWidth: box ? box.outlineWidth : '0px',
    // Captured so the normalizer can tell a drawn outline from a width
    // that draws nothing. `outline-width`'s initial value is `medium`,
    // which Chrome computes to 3px on EVERY element — a bare `<div>` with
    // no styling at all reports `3px` / `none`. Reading the width alone
    // said every component had a 3px outline at rest.
    outlineStyle: box ? box.outlineStyle : 'none',
    // Internal raw-capture protocol: colour is needed to distinguish an
    // active solid outline from the same ring at zero alpha while resting.
    // Preserve the unrounded browser string; faint positive alpha is paint.
    outlineColor: box ? box.outlineColor : null,
    outlineOffset: box ? box.outlineOffset : '0px',
    boxShadow: paintBox ? paintBox.boxShadow : 'none',
    opacity: rootStyle.opacity,
    widthPx: rect.width,
    heightPx: rect.height,
  });
}
''';
