import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'color_picker_disabled_probe.dart';

@JS('globalThis.readDisabledPickerStates')
external set _readStates(JSFunction callback);

void main() {
  _readStates = (() => jsonEncode(
    readColorPickerDisabledStates?.call(),
  ).toJS).toJS;
  Jaspr.initializeApp();
  runApp(colorPickerDisabledProbe(), attachTo: '#color-picker-disabled-app');
  web.document.documentElement!.setAttribute('data-disabled-ready', 'true');
}
