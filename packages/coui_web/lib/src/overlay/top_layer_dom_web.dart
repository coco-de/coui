/// Browser implementation of the top-layer promotion (see `top_layer.dart`).
library;

import 'dart:js_interop';

import 'package:coui_web/src/overlay/top_layer.dart'
    show kTopLayerPanelAttribute;
import 'package:web/web.dart' as web;

/// Panels that asked to be promoted. Plain attribute selectors only — they
/// are valid in every browser, so the unsupported-browser path is decided
/// by the promotion itself (below), not by a selector that fails to parse.
const String _kPanelSelector = '[$kTopLayerPanelAttribute][popover]';

/// Number of live hosts. The observer is shared by every host on the page
/// (the page root and each client island roots its own) and is disconnected
/// with the last one.
int _hosts = 0;
web.MutationObserver? _observer;

/// Promotes [element] into the top layer. Idempotent.
///
/// Returns whether the element is in the top layer afterwards. On a
/// browser without the Popover API — or when the promotion is rejected —
/// the `popover` attribute is removed: a supporting UA hides every
/// `[popover]:not(:popover-open)` element, and an overlay must never be
/// hidden by an enhancement that did not happen.
///
/// A node that is no longer in the document — inserted and removed again
/// before this microtask ran — is neither promoted nor rejected: it is left
/// as it is for its next insertion. Stripping `popover` from it would
/// silently drop the enhancement for good.
bool _promote(web.Element element) {
  if (!element.isConnected) return false;
  try {
    // Throws a SyntaxError on a browser that does not know the pseudo-class,
    // which is exactly the "unsupported" answer we want.
    if (element.matches(':popover-open')) return true;
    (element as web.HTMLElement).showPopover();
    return true;
  } on Object catch (_) {
    element.removeAttribute('popover');
    return false;
  }
}

void _promoteWithin(web.Element root) {
  if (root.matches(_kPanelSelector)) _promote(root);
  final found = root.querySelectorAll(_kPanelSelector);
  for (var i = 0; i < found.length; i++) {
    final node = found.item(i);
    if (node != null) _promote(node as web.Element);
  }
}

// A mutation observer callback is a microtask: it runs after the DOM change
// and before the next paint, so a panel inserted by a render is already in
// the top layer on its first frame.
//
// Two ways a panel becomes promotable: it is inserted (`childList`), or an
// element that is already there is reused for a panel and receives the marker
// (`attributes` on the marker only — the promoter's own `popover` removal is
// not observed, so it cannot loop). Jaspr reuses a DOM node in place when an
// unkeyed layer list keeps the same element type at the same index.
void _handleMutations(JSArray<web.MutationRecord> records, JSAny observer) {
  for (final record in records.toDart) {
    if (record.type == 'attributes') {
      final target = record.target;
      if (target.nodeType == web.Node.ELEMENT_NODE) {
        final element = target as web.Element;
        if (element.matches(_kPanelSelector)) _promote(element);
      }
      continue;
    }
    final added = record.addedNodes;
    for (var i = 0; i < added.length; i++) {
      final node = added.item(i);
      if (node != null && node.nodeType == web.Node.ELEMENT_NODE) {
        _promoteWithin(node as web.Element);
      }
    }
  }
}

/// Starts promoting marked panels as they are inserted anywhere in the
/// document, and promotes the ones already there (server-rendered open
/// panels, hydrated before a host existed). Returns the disposer.
void Function() installTopLayerPromoter() {
  _hosts++;
  if (_observer == null) {
    final root = web.document.documentElement;
    if (root != null) {
      final observer = web.MutationObserver(_handleMutations.toJS)
        ..observe(
          root,
          web.MutationObserverInit(
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: [kTopLayerPanelAttribute.toJS].toJS,
          ),
        );
      _observer = observer;
      _promoteWithin(root);
    }
  }
  var released = false;
  return () {
    if (released) return;
    released = true;
    _hosts--;
    if (_hosts == 0) {
      _observer?.disconnect();
      _observer = null;
    }
  };
}

/// Promotes the element with [elementId] into the top layer. Idempotent.
///
/// For roots that own their own promotion timing (the `Drawer` entry).
bool promoteToTopLayer(String elementId) {
  final element = web.document.getElementById(elementId);
  return element != null && _promote(element);
}
