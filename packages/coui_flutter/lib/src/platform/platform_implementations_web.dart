import 'dart:js_interop';

import 'package:coui_flutter/coui_flutter.dart';

@JS('Window')
extension type const _Window(JSObject _) implements JSObject {
  // dispatchEvent method
  external void dispatchEvent(JSObject event);

  external _GlobalThis get globalThis;
  external set couiAppLoaded(bool value);
}

@JS()
extension type const _GlobalThis(JSObject _) implements JSObject {
  external JSObject? get CoUIApp;
}

@JS('Event')
extension type const _Event._(JSObject _) implements JSObject {
  external _Event(String type);
}

@JS('window')
external _Window get _window;

@JS('CoUIAppThemeChangedEvent')
extension type const _CoUIAppThemeChangedEvent._(JSObject _)
    implements JSObject {
  external _CoUIAppThemeChangedEvent(_CoUIAppTheme theme);
}

@JS('CoUIAppTheme')
extension type const _CoUIAppTheme._(JSObject _) implements JSObject {
  external _CoUIAppTheme(String background, String foreground, String primary);
}

class CoUIFlutterPlatformImplementations {
  static bool get _isPreloaderAvailable {
    return _window.globalThis.CoUIApp != null;
  }

  static void onAppInitialized() {
    if (!_isPreloaderAvailable) {
      return;
    }
    _window.couiAppLoaded = true;
    final event = _Event('coui_flutter_app_ready');
    _window.dispatchEvent(event);
  }

  static void onThemeChanged(ThemeData theme) {
    if (!_isPreloaderAvailable) {
      return;
    }
    final couiAppTheme = _CoUIAppTheme(
      _colorToCssRgba(theme.colorScheme.background),
      _colorToCssRgba(theme.colorScheme.foreground),
      _colorToCssRgba(theme.colorScheme.primary),
    );
    final event = _CoUIAppThemeChangedEvent(couiAppTheme);
    _window.dispatchEvent(event);
  }
}

String _colorToCssRgba(Color color) {
  return 'rgba(${color.r * 255}, ${color.g * 255}, ${color.b * 255}, ${color.a})';
}
