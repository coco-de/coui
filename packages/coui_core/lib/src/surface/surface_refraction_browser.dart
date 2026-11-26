/// Which browsers may bend a surface's backdrop with an SVG filter.
///
/// On the Web a refraction is a `url(#filter)` appended to the surface's
/// `backdrop-filter` list, and the browser decides what that list draws. Only
/// Blink composites an SVG filter named there. WebKit accepts the value —
/// `CSS.supports('backdrop-filter', 'url(#f)')` is true — and then draws
/// **nothing for a list that names a filter**. Measured in Safari 27.0: on a
/// pane whose style is `blur(10px) url(#f)` from the start, every pixel behind
/// it is as with `none`, while `blur(10px)` alone changes them all; a reference
/// to a filter that does not exist is dropped the same way.
///
/// A reference appended after the pane was already drawn with its stylesheet
/// chain leaves that layer as it was, which is how the surface still looks
/// right on first paint. The next time the browser builds the layer again — the
/// pane hidden with `display: none` and shown, or its node removed and
/// inserted — it is built from the list that names the filter, and the pane is
/// a tinted rectangle: against a control pane with its filter forced off,
/// 0 of 16 384 pixels differ. Firefox is recorded as behaving alike and has not
/// been measured here.
///
/// A support query for the feature itself cannot tell those browsers from
/// Blink — both answer true — which is why the decision is made on the user
/// agent. It lives here, as a pure function, so the two Web targets — Flutter
/// Web and the Jaspr components — read one answer and a table of user agents
/// (the shared fixture) pins it for both.
///
/// The Jaspr stylesheet asks one more question of WebKit alone, which a query
/// on Apple's own features answers in CSS before any script runs: the frost
/// and the body shade, two SVG filters in the list, are taken out of it there
/// from the first paint. A layer drawn from a list that names a filter keeps
/// its missing blur when the list is corrected afterwards (measured in Safari
/// 27.0), so for WebKit a rule that waits for the user agent comes too late.
library;

/// The token Blink-based browsers put in their user agent.
///
/// `Chrome/` covers Chrome, Edge, Opera, Samsung Internet, Brave and Android
/// WebView, which all send it, and `Chromium/` covers the browser of that
/// name. Chrome on iOS runs WebKit and says `CriOS/`, Edge on iOS `EdgiOS/`,
/// Firefox on iOS `FxiOS/` — none of them contains `Chrome/`, so they fall
/// to the material without the bend, as they should.
final RegExp _kBlinkUserAgentToken = RegExp('(Chrome|Chromium)/');

/// Whether the browser that sent [userAgent] composites an SVG filter named in
/// `backdrop-filter`.
///
/// An empty string — no `navigator` at all, as on a server — is not
/// supported: there is nothing to bend there.
bool surfaceRefractionBrowserSupported(String userAgent) =>
    _kBlinkUserAgentToken.hasMatch(userAgent);
