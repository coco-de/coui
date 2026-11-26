import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'number_ticker_zero_probe.dart';

@JS('globalThis.readZeroProbe')
external set _readProbe(JSFunction callback);

@JS('globalThis.recordZeroFrame')
external JSFunction? get _recordFrame;

void main() {
  _readProbe = (() => jsonEncode(readNumberTickerZero?.call()).toJS).toJS;
  numberTickerZeroFrame = (phase) {
    _recordFrame?.callAsFunction(null, phase.toJS);
  };
  Jaspr.initializeApp();
  runApp(numberTickerZeroProbe(), attachTo: '#number-ticker-zero-app');
  web.document.documentElement!.setAttribute('data-zero-ready', 'true');
}
