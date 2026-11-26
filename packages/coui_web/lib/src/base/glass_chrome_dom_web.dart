import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One document listener for native glass chrome, regardless of bar count.
/// Scroll changes only a paint variable — it neither rebuilds nor reads back
/// the optical backdrop per frame. Nothing here measures geometry: a centred
/// title is placed by the bar's own grid (`resolveAppBar`), in CSS.
abstract final class GlassChromeDom {
  static int _users = 0;
  static JSFunction? _scroll;

  /// Retains the document driver and returns an idempotent release callback.
  static void Function() retain() {
    if (_users++ == 0) _install();
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (--_users != 0) return;
      if (_scroll != null) {
        web.document.removeEventListener('scroll', _scroll, true.toJS);
      }
      _scroll = null;
    };
  }

  static List<web.HTMLElement> _bars() {
    final nodes = web.document.querySelectorAll('[data-coui-app-bar-glass]');
    return [
      for (var i = 0; i < nodes.length; i++) nodes.item(i)! as web.HTMLElement,
    ];
  }

  static void _install() {
    _scroll = ((web.Event event) {
      final target = event.target;
      final scroller = target != null && target.isA<web.Element>()
          ? target as web.Element
          : web.document.scrollingElement;
      if (scroller == null) return;
      for (final bar in _bars()) {
        if (bar.contains(scroller)) continue;
        final scope = bar.closest('[data-coui-scaffold]') ?? bar.parentElement;
        if (!(scope?.contains(scroller) ?? false) && !scroller.contains(bar)) {
          continue;
        }
        final distance =
            double.tryParse(
              bar.getAttribute('data-coui-app-bar-edge-distance') ?? '',
            ) ??
            24;
        final progress = (scroller.scrollTop / distance).clamp(0.0, 1.0);
        bar.style.setProperty(
          '--coui-app-bar-edge-opacity',
          '${progress * .92}',
        );
      }
    }).toJS;
    web.document.addEventListener('scroll', _scroll, true.toJS);
  }
}
