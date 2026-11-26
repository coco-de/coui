import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'number_ticker_lifetime_probe.dart';

@JS('globalThis.readTickerProbe')
external set _readProbe(JSFunction callback);

@JS('globalThis.disposeTickerRoot')
external set _disposeRoot(JSFunction callback);

@JS('globalThis.disposeTickerOnFirstFrame')
external JSBoolean? get _disposeAtFirstFrame;

@JS('globalThis.tickerWithoutInitialValues')
external JSBoolean? get _withoutInitialValues;

@JS('globalThis.recordTickerFirstFrame')
external JSFunction? get _firstFrame;

void main() {
  _readProbe = (() => jsonEncode(readNumberTickerLifetime?.call()).toJS).toJS;
  _disposeRoot = (() {
    ClientAppBinding.ensureInitialized().detachRootComponent();
  }).toJS;
  numberTickerLifetimeFirstFrame = () {
    _firstFrame?.callAsFunction();
    if (_disposeAtFirstFrame?.toDart ?? false) {
      ClientAppBinding.ensureInitialized().detachRootComponent();
    }
  };
  Jaspr.initializeApp();
  runApp(
    numberTickerLifetimeProbe(
      withInitialValues: !(_withoutInitialValues?.toDart ?? false),
    ),
    attachTo: '#number-ticker-lifetime-app',
  );
  web.document.documentElement!.setAttribute('data-ticker-ready', 'true');
}
