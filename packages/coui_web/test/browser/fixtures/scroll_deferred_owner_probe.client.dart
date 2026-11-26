import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'scroll_deferred_owner_probe.dart';

@JS('globalThis.readScrollOwner')
external set _readProbe(JSFunction callback);

@JS('globalThis.scrollOwnerMode')
external JSString? get _mode;

@JS('globalThis.recordScrollOwner')
external JSFunction? get _record;

void main() {
  _readProbe = (() => jsonEncode(readScrollDeferredOwner()).toJS).toJS;
  scrollDeferredFirstFrame = (generation) {
    _record?.callAsFunction(null, 'first-$generation'.toJS);
    if (generation != 'A') {
      return;
    }
    final mode = _mode?.toDart ?? 'stable';
    if (mode == 'stable') {
      return;
    }
    ClientAppBinding.ensureInitialized().detachRootComponent();
    _record?.callAsFunction(null, 'after-detach-A'.toJS);
    // The host owns this mount point. Retire the disposed tree's retained DOM
    // before mounting B; there is never a simultaneous duplicate public id.
    final mount = web.document.querySelector('#scroll-owner-app')!;
    var child = mount.firstChild;
    while (child != null) {
      mount.removeChild(child);
      child = mount.firstChild;
    }
    _record?.callAsFunction(null, 'after-retire-A-DOM'.toJS);
    if (mode == 'replace') {
      runApp(scrollDeferredOwnerProbe('B'), attachTo: '#scroll-owner-app');
      _record?.callAsFunction(null, 'after-attach-B'.toJS);
    }
  };
  Jaspr.initializeApp();
  runApp(scrollDeferredOwnerProbe('A'), attachTo: '#scroll-owner-app');
  web.document.documentElement!.setAttribute('data-scroll-ready', 'true');
}
