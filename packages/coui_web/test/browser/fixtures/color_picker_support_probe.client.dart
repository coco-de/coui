import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'color_picker_support_probe.dart';

@JS('globalThis.recordPickerFirstFrame')
external JSFunction? get _recordFirstFrame;

@JS('globalThis.readPickerStateTokens')
external set _readStateTokens(JSFunction callback);

@JS('globalThis.disposePickerOnFirstFrame')
external JSBoolean? get _disposeOnFirstFrame;

void main() {
  _readStateTokens = (() => jsonEncode(
    colorPickerSupportStateTokens(),
  ).toJS).toJS;
  colorPickerSupportFirstFrame = () {
    _recordFirstFrame?.callAsFunction();
    if (_disposeOnFirstFrame?.toDart ?? false) {
      ClientAppBinding.ensureInitialized().detachRootComponent();
    }
  };
  Jaspr.initializeApp();
  runApp(colorPickerSupportProbe(), attachTo: '#color-picker-support-app');
  web.document.documentElement!.setAttribute('data-picker-ready', 'true');
}
