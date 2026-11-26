/// Browser implementation of `playHapticCue`.
///
/// Selected by the conditional export in `haptics.dart`; the header there
/// says what the browser does with the call.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// Pulses the device for [CoreHapticCue.pulseMilliseconds] through
/// `navigator.vibrate`, or does nothing when the browser has no such function.
///
/// The presence test is on the navigator itself rather than a user-agent
/// check: Safari is the browser that lacks it today, and any other browser
/// that does would be skipped the same way.
void playHapticCue(CoreHapticCue cue) {
  final navigator = web.window.navigator;
  if (!navigator.has('vibrate')) return;
  navigator.vibrate(cue.pulseMilliseconds.toJS);
}
