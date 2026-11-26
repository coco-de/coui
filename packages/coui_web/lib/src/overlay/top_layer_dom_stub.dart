/// SSR stub for the browser half of the top-layer promotion.
///
/// There is no top layer outside the browser; the server renders the
/// declarative attributes and the client promotes on hydration.
library;

/// SSR stub — nothing to observe. Returns a no-op disposer.
void Function() installTopLayerPromoter() => () {};

/// SSR stub — no element to promote.
bool promoteToTopLayer(String elementId) => false;
