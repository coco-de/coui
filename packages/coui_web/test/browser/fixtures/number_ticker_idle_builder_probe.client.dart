import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'number_ticker_idle_builder_probe.dart';

@JS('globalThis.readIdleBuilderProbe')
external set _readProbe(JSFunction callback);

@JS('globalThis.recordIdleBuilderFrame')
external JSFunction? get _recordFrame;

void main() {
  _readProbe = (() => jsonEncode(
    readNumberTickerIdleBuilder?.call(),
  ).toJS).toJS;
  numberTickerIdleBuilderFirstFrame = () {
    _recordFrame?.callAsFunction();
  };
  Jaspr.initializeApp();
  try {
    runApp(
      numberTickerIdleBuilderProbe(),
      attachTo: '#number-ticker-idle-app',
    );
  } finally {
    // Observes an attempted public mount without swallowing its errors.
    web.document.documentElement!.setAttribute('data-idle-attempted', 'true');
  }
}
