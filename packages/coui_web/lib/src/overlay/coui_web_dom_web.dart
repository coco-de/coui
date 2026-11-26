// The runtime narrows inside `addEventListener` callbacks
// (`event as web.MouseEvent` etc.) are gated by `event.isA<...>()`, which
// is the only narrowing `package:web` extension types admit — they are
// not instantiable, so `is` cannot see through them.

/// Web implementation of `CoUIWeb` runtime DOM helpers.
///
/// Selected via the conditional export in [coui_web_dom.dart] for
/// browser builds — kept out of the main `coui_web.dart` so SSR /
/// non-web targets do not pull in `package:web` / `dart:js_interop`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coui_web/src/components/infra/outlined_container/refraction_map.dart';
import 'package:coui_web/src/overlay/locale_match.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:web/web.dart' as web;

const String _kDarkSchemeQuery = '(prefers-color-scheme: dark)';
const String _kReducedMotionQuery = '(prefers-reduced-motion: reduce)';
const String _kReducedTransparencyQuery =
    '(prefers-reduced-transparency: reduce)';
const String _kHoverPointerQuery = '(hover: hover)';
const String _kMoreContrastQuery = '(prefers-contrast: more)';
const String _kForcedColorsQuery = '(forced-colors: active)';

/// Reads `prefers-color-scheme: dark` once. Used on first build
/// before [registerDarkColorSchemeListener] starts firing change
/// events.
bool get prefersDarkColorScheme {
  return web.window.matchMedia(_kDarkSchemeQuery).matches;
}

/// Reads `prefers-reduced-motion: reduce` once, read fresh on every
/// call (no cached listener — checked at the moment a transition-tier
/// timer is about to be armed, e.g. an overlay's exit-unmount delay).
/// `CoreReducedMotion.resolve` is the platform-neutral policy that
/// turns this flag into "suppress or keep" per duration; this getter
/// only answers "is the OS setting on", mirroring
/// [prefersDarkColorScheme]'s one-shot read shape.
bool get prefersReducedMotion {
  return web.window.matchMedia(_kReducedMotionQuery).matches;
}

/// Reads `prefers-reduced-transparency: reduce` once. The stylesheet answers
/// the preference on its own (surfaces turn opaque); this is for the code that
/// has to *say* which tier the surfaces are drawn at.
bool get prefersReducedTransparency {
  return web.window.matchMedia(_kReducedTransparencyQuery).matches;
}

/// Subscribes to `prefers-reduced-transparency` changes. Returns a disposer.
void Function() registerReducedTransparencyListener(
  void Function({required bool reduced}) onChange,
) {
  final query = web.window.matchMedia(_kReducedTransparencyQuery);
  final handler = ((web.Event event) {
    if (!event.isA<web.MediaQueryListEvent>()) return;
    onChange(reduced: (event as web.MediaQueryListEvent).matches);
  }).toJS;
  query.addEventListener('change', handler);
  return () => query.removeEventListener('change', handler);
}

/// Whether the primary pointer can hover — `(hover: hover)`. Read fresh
/// on every call (a hybrid device can gain or lose a mouse), mirroring
/// [prefersReducedMotion]'s one-shot read shape.
///
/// Web-only gate for hover-driven *behaviour* (not hover chrome, which
/// stays CSS `:hover`). Touch browsers emulate `mouseenter` ahead of
/// `click` on tap, so a hover handler that changes state would fire and
/// then be undone by the tap's own handler — e.g. tapping a menubar
/// trigger while another menu is open would switch to it on the
/// emulated hover and immediately toggle it shut on the click.
///
/// Flutter needs no equivalent: its hover arrives via
/// `FocusableActionDetector.onShowHoverHighlight` (a `MouseRegion`),
/// which only reports mouse pointers. Same capability, each platform's
/// own idiom.
bool get supportsHoverPointer {
  return web.window.matchMedia(_kHoverPointerQuery).matches;
}

/// Subscribes to `prefers-color-scheme` changes — fires [onChange]
/// every time the OS-level dark/light preference flips so
/// `CoUIWeb` can rebuild with the matching `ThemeData`.
///
/// Returns a disposer the caller invokes from `State.dispose` to
/// detach the listener.
void Function() registerDarkColorSchemeListener(
  void Function({required bool isDark}) onChange,
) {
  final query = web.window.matchMedia(_kDarkSchemeQuery);
  final handler = ((web.Event event) {
    if (!event.isA<web.MediaQueryListEvent>()) return;
    final mqe = event as web.MediaQueryListEvent;
    onChange(isDark: mqe.matches);
  }).toJS;
  query.addEventListener('change', handler);
  return () => query.removeEventListener('change', handler);
}

/// Whether the person asked for more contrast, or the platform forces its own
/// palette — the two preferences under which the frost and the body shade a
/// glass surface lays over its backdrop are taken away.
///
/// Read fresh on every call, like [prefersReducedMotion]: the stylesheet takes
/// the two terms away with a media query, and the runtime that copies the
/// computed filter list onto a surface has to know whether the list it just
/// read was computed under that query.
bool get prefersPlainSurfaces {
  return web.window.matchMedia(_kMoreContrastQuery).matches ||
      web.window.matchMedia(_kForcedColorsQuery).matches;
}

/// Subscribes to changes of either preference [prefersPlainSurfaces] reads —
/// fires [onChange] every time one of them flips.
///
/// Returns a disposer the caller invokes to detach both listeners.
void Function() registerPlainSurfacesListener(void Function() onChange) {
  final handler = ((web.Event event) {
    onChange();
  }).toJS;
  final queries = [
    web.window.matchMedia(_kMoreContrastQuery),
    web.window.matchMedia(_kForcedColorsQuery),
  ];
  for (final query in queries) {
    query.addEventListener('change', handler);
  }

  return () {
    for (final query in queries) {
      query.removeEventListener('change', handler);
    }
  };
}

/// Installs a `contextmenu` listener on `document` that calls
/// `preventDefault` so right-click / two-finger-tap doesn't surface
/// the browser's native context menu over CoUI components. Returns
/// a disposer the owning State invokes on `dispose`.
///
/// Mirrors Flutter `CoUIApp.disableBrowserContextMenu` semantics
/// (`BrowserContextMenu.disableContextMenu()`).
void Function() suppressBrowserContextMenu() {
  final handler = ((web.Event event) {
    event.preventDefault();
  }).toJS;
  web.document.addEventListener('contextmenu', handler);
  return () => web.document.removeEventListener('contextmenu', handler);
}

/// Sets `document.title` to [title]. Mirrors Flutter `CoUIApp.title`
/// → the browser tab / OS window-list label. Re-callable any number
/// of times so [CoUIWeb.didUpdateComponent] can keep the tab in sync
/// with `widget.title`.
void setDocumentTitle(String title) {
  web.document.title = title;
}

/// Sets `<html lang>` to [languageTag] (BCP 47). Mirrors Flutter
/// `CoUIApp.locale` for screen readers / SEO / browser auto-translate
/// heuristics. Pass an empty string to clear.
void setHtmlLangAttribute(String languageTag) {
  // `documentElement` is `<html>`; `lang` is a string attribute on
  // every Element. `package:web` types it as a String getter/setter
  // but the underlying API is `setAttribute('lang', ...)` so we use
  // the explicit form for predictable serialization (e.g.
  // `Locale('en')` → `'en'`, `Locale('en', 'US')` → `'en-US'`).
  web.document.documentElement?.setAttribute('lang', languageTag);
}

/// Sets `<html dir>` to [direction] (`ltr` / `rtl`).
///
/// Set next to `lang`, from the same resolved locale, because the two
/// answer one question between them: `lang` says which language the
/// page is in and `dir` says which way it runs. Setting only the first
/// leaves an Arabic page laid out left-to-right — announced correctly
/// and rendered backwards.
///
/// On the element rather than a wrapper: `dir` inherits, so the whole
/// document — including anything portalled outside the app root —
/// picks it up, and CSS logical properties resolve against it.
void setHtmlDirAttribute(String direction) {
  web.document.documentElement?.setAttribute('dir', direction);
}

/// Writes [kWebSvgBackdropAttribute] on `<html>` when this browser does not
/// draw an SVG filter named in `backdrop-filter`, and nothing otherwise.
///
/// The attribute is what the stylesheet's rule for the frost and the body
/// shade is keyed on: a browser that draws nothing for a list naming such a
/// filter would otherwise lose the glass's blur to those two terms. The answer
/// is the refraction's ([webSurfaceRefractionSupported]) — one answer for every
/// SVG filter in a backdrop list — and the attribute is never written on
/// the server, which does not know the browser.
///
/// For WebKit the sheet does not wait for it: a feature query takes the two
/// terms out from the first paint, because a layer that was drawn from the
/// list keeps its missing blur when the attribute lands afterwards. What this
/// reaches is the browsers that query cannot name, and the surfaces created
/// after it is written.
void markSvgBackdropSupport() {
  if (webSurfaceRefractionSupported) return;
  web.document.documentElement?.setAttribute(
    kWebSvgBackdropAttribute,
    kWebSvgBackdropOff,
  );
}

/// Sets `<meta name="theme-color">` `content` to [color]. Mirrors
/// Flutter `CoUIApp.color` → the colour mobile browsers tint their
/// chrome (address bar / task switcher) with. Reuses an existing
/// `<meta name="theme-color">` (a host SSR template may pre-render one)
/// and otherwise creates and appends it to `<head>`. Re-callable so
/// [CoUIWeb.didUpdateComponent] can keep it in sync.
void setMetaThemeColor(String color) {
  final existing =
      web.document.querySelector('meta[name="theme-color"]')
          as web.HTMLMetaElement?;
  if (existing != null) {
    existing.content = color;
    return;
  }
  final head = web.document.head;
  if (head == null) return;
  final meta = web.document.createElement('meta') as web.HTMLMetaElement;
  meta.name = 'theme-color';
  meta.content = color;
  // `append` returns void (unlike `appendChild`, whose returned Node we
  // would otherwise discard).
  head.append(meta);
}

/// Negotiates the best-matching locale tag between the browser's
/// preferences (`navigator.languages`, in priority order) and the app's
/// [supportedTags] (BCP 47 strings). Mirrors Flutter
/// `WidgetsApp.supportedLocales` resolution: for each browser preference
/// (highest priority first), an exact `lang-REGION` match wins, then a
/// language-only match. Returns the matching entry from [supportedTags]
/// (so casing / region of the app's own list is preserved), or `null`
/// when nothing matches.
String? negotiateLocale(List<String> supportedTags) {
  final prefs = [
    for (final pref in web.window.navigator.languages.toDart) pref.toDart,
  ];
  return matchLocale(prefs, supportedTags);
}

/// Installs a `mousedown` listener on `document` that suppresses
/// the browser's native middle-click auto-scroll cursor. Mirrors
/// Flutter `CoUIApp.enableScrollInterception=false` semantics:
/// when scroll interception is disabled, the host app does not
/// want CoUI's (or the browser's) auto-scroll handling.
///
/// On the browser side the equivalent of disabling middle-click
/// auto-scroll is calling `preventDefault()` on the
/// `mousedown` event whose `button === 1` (the middle button).
/// Returns a disposer the owning State invokes on dispose.
void Function() suppressMiddleClickAutoScroll() {
  final handler = ((web.Event event) {
    if (!event.isA<web.MouseEvent>()) return;
    final mouse = event as web.MouseEvent;
    // Per `MouseEvent.button` spec: 0 = left, 1 = middle, 2 = right.
    if (mouse.button == 1) event.preventDefault();
  }).toJS;
  web.document.addEventListener('mousedown', handler);
  return () => web.document.removeEventListener('mousedown', handler);
}

/// Whether the browser locale prefers a 12-hour clock (AM/PM).
///
/// Mirrors Flutter's `MediaQuery.alwaysUse24HourFormatOf` capability on
/// the Web: `Intl.DateTimeFormat` resolves the active browser locale's
/// hour cycle. `hour12` is only populated on `resolvedOptions()` when
/// the `hour` option is requested, so the probe asks for a numeric hour.
bool get prefersHour12Format {
  final options = JSObject()..setProperty('hour'.toJS, 'numeric'.toJS);
  // `Intl.DateTimeFormat` rejects a `null` locales argument (TypeError)
  // — pass the browser UI locale explicitly instead.
  final locale = web.window.navigator.language.toJS;
  final resolved = _IntlDateTimeFormat(locale, options).resolvedOptions();
  final hour12 = resolved.getProperty<JSBoolean?>('hour12'.toJS);
  return hour12?.toDart ?? false;
}

@JS('Intl.DateTimeFormat')
extension type const _IntlDateTimeFormat._(JSObject _) implements JSObject {
  external factory _IntlDateTimeFormat(JSAny? locales, JSObject options);
  external JSObject resolvedOptions();
}
