import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'refresh_deferred_owner_probe.dart';

@JS('globalThis.readRefreshOwner')
external set _readProbe(JSFunction callback);

void main() {
  _readProbe = (() => jsonEncode(readRefreshDeferredOwner?.call()).toJS).toJS;
  Jaspr.initializeApp();
  runApp(refreshDeferredOwnerProbe(), attachTo: '#refresh-owner-app');
  web.document.documentElement!.setAttribute('data-refresh-ready', 'true');
}
