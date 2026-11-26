/// SSR stub for the hero entrance observer.
///
/// Returns a no-op disposer and never calls `onVisible`. Server HTML
/// therefore stays in the pre-entrance state, which is the same state
/// the browser's first paint uses, so hydration does not disagree.
/// A `<noscript>` style in the widget shows the content when scripting
/// is unavailable.
library;

/// Subscribes [onVisible] to the first viewport intersection of
/// [elementId].
///
/// Returns a disposer, or null when the element is not in the document
/// yet and the caller should retry. This stub always returns a disposer.
void Function()? observeHeroAppear({
  required String elementId,
  required void Function() onVisible,
}) => () {};
