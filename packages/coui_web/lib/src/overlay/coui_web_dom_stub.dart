/// SSR-safe stub for `CoUIWeb` runtime DOM helpers.
///
/// Server / non-`dart:js_interop` builds get inert no-ops so the
/// component compiles and renders its initial markup without any
/// `package:web` dependency. The real implementations live in
/// [coui_web_dom_web.dart].
library;

/// SSR stub — no media-query evaluation outside the browser.
bool get prefersDarkColorScheme => false;

/// SSR stub — no media-query evaluation outside the browser. The
/// server always renders the (unsuppressed) transition-tier duration;
/// the client re-evaluates on hydration before any exit timer arms.
bool get prefersReducedMotion => false;

/// SSR stub — no pointer to probe outside the browser. Unreachable in
/// practice: the only callers read it from inside a `mouseenter`
/// handler, and DOM events never fire on the server. `false` is the
/// conservative answer either way — no hover-driven behaviour.
bool get supportsHoverPointer => false;

/// SSR stub — no media-query evaluation outside the browser. The server
/// renders the surfaces as the style states them; the client reads the
/// preference on hydration.
bool get prefersReducedTransparency => false;

/// SSR stub — returns a no-op disposer.
void Function() registerReducedTransparencyListener(
  void Function({required bool reduced}) onChange,
) {
  return () {};
}

/// SSR stub — returns a no-op disposer.
void Function() registerDarkColorSchemeListener(
  void Function({required bool isDark}) onChange,
) {
  return () {};
}

/// SSR stub — no media-query evaluation outside the browser. The server
/// renders the stylesheet, which carries the media query itself; there is no
/// runtime filter list to keep in step with it.
bool get prefersPlainSurfaces => false;

/// SSR stub — returns a no-op disposer.
void Function() registerPlainSurfacesListener(void Function() onChange) {
  return () {};
}

/// SSR stub — context menu suppression has no meaning on the server.
/// Returns a no-op disposer.
void Function() suppressBrowserContextMenu() {
  return () {};
}

/// SSR stub — `<title>` is rendered into the SSR <head> by the host
/// app's document template; no runtime mutation needed.
void setDocumentTitle(String title) {}

/// SSR stub — `<html lang>` is set by the host app's document
/// template at SSR time; no runtime mutation needed.
void setHtmlLangAttribute(String languageTag) {}

/// SSR stub — `<html dir>` is set by the host app's document template
/// at SSR time; no runtime mutation needed.
void setHtmlDirAttribute(String direction) {}

/// SSR stub — the server does not know which browser will draw the page, so
/// it writes nothing; the browser build writes the attribute on hydration.
void markSvgBackdropSupport() {}

/// SSR stub — `<meta name="theme-color">` is rendered into the SSR
/// <head> by the host app's document template; no runtime mutation
/// needed.
void setMetaThemeColor(String color) {}

/// SSR stub — no `navigator.languages` outside the browser; the host
/// app negotiates locale at SSR time. Returns `null` (no match).
String? negotiateLocale(List<String> supportedTags) => null;

/// SSR stub — middle-click auto-scroll has no meaning on the server.
/// Returns a no-op disposer.
void Function() suppressMiddleClickAutoScroll() {
  return () {};
}

/// SSR stub — no browser locale outside the browser; assume a 24-hour
/// clock so the pre-hydration markup matches the historic default.
bool get prefersHour12Format => false;
