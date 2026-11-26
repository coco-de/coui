/// SSR-safe full-page navigation.
///
/// Same split as `coui_web`'s `popover_dom.dart`: server / non-web builds
/// get an inert stub, browser builds get the real `window.location` call.
/// Needed because `@client` island `State`s (like `DocsSearch`) hydrate in
/// isolation from the app's `Router` ancestor (`main.server.dart`'s
/// `ContentApp` router) — `Router.of(context)` throws inside an island —
/// so navigation on selection goes through a full page load instead of the
/// app's client-side router.
library;

export 'web_navigation_stub.dart' if (dart.library.js_interop) 'web_navigation_web.dart';
