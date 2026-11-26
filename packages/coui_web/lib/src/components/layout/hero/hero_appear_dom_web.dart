/// Browser implementation of the hero entrance observer.
///
/// `IntersectionObserver` is the viewport test: it already accounts for
/// ancestor overflow, so a hero scrolled out of a nested container does
/// not count as visible just because the container itself is on screen.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Subscribes [onVisible] to the first viewport intersection of
/// [elementId].
///
/// Returns a disposer, or null when the element is not in the document
/// yet. The callback the browser fires for a non-intersecting target is
/// ignored — the entrance waits for a real intersection, then the
/// observer disconnects so leaving the viewport does not reverse it.
void Function()? observeHeroAppear({
  required String elementId,
  required void Function() onVisible,
}) {
  final element = web.document.getElementById(elementId);
  if (element == null) return null;

  final observer = web.IntersectionObserver(
    ((
          JSArray<web.IntersectionObserverEntry> entries,
          web.IntersectionObserver self,
        ) {
          for (var i = 0; i < entries.length; i++) {
            if (!entries.toDart[i].isIntersecting) continue;
            onVisible();
            self.disconnect();
            return;
          }
        })
        .toJS,
  )..observe(element);

  // Tear-offs of `package:web` extension members aren't supported by
  // DDC — wrap the disconnect in a closure.
  // ignore: unnecessary_lambdas
  return () => observer.disconnect();
}
