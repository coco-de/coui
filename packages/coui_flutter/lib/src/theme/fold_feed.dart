import 'dart:async';

import 'package:coui_flutter/src/theme/fold_reading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the fold of a platform that does not report it to Flutter comes
/// from. `FoldScopeHost` watches one and writes what it measures into
/// `MediaQuery.displayFeatures`.
///
/// The package has one of its own, for iOS ([FoldFeed.forPlatform]). An app
/// hands the host another to measure a different way, and a test hands it one
/// to say what the device reports.
abstract class FoldFeed {
  /// A feed.
  const FoldFeed();

  /// The feed for the platform the app runs on: the package's plugin on iOS,
  /// null everywhere else. Android's engine reports folds to `MediaQuery`
  /// itself, and on the Web and the desktop there is nothing to ask.
  static FoldFeed? forPlatform() =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS
      ? null
      : const _PluginFoldFeed();

  /// Starts watching. [onReading] is called with what the platform measures
  /// now and with every reading that differs, until the returned callback is
  /// called.
  VoidCallback watch(ValueChanged<FoldReading> onReading);

  /// Asks the platform to measure again and tell every watcher. For the
  /// moments a change can pass unreported — the app coming back to the
  /// foreground.
  void refresh() {}
}

/// The feed the package's iOS plugin (`CoUIFoldPlugin`) answers.
///
/// One method channel both ways: Dart asks `read`, the plugin calls `changed`.
/// Not an event channel — listening to one that nothing answers is reported
/// as an error, and nothing answers in a widget test, on a simulator build
/// made before the plugin existed, or in an app that embeds Flutter without
/// registering plugins. Asking and hearing nothing is how those read: no
/// fold.
class _PluginFoldFeed extends FoldFeed {
  const _PluginFoldFeed();

  static const _channel = MethodChannel('coui_flutter/fold');

  /// Every watcher of the channel. A channel has one handler, and an app may
  /// mount more than one host.
  static final _watchers = <ValueChanged<FoldReading>>[];

  static void _tell(FoldReading reading) {
    for (final watcher in List.of(_watchers)) {
      watcher(reading);
    }
  }

  static Future<Object?> _handleCall(MethodCall call) async {
    if (call.method == 'changed') {
      _tell(FoldReading.fromMessage(call.arguments));
    }

    return null;
  }

  static Future<void> _read() async {
    Object? message;
    try {
      message = await _channel.invokeMethod<Object?>('read');
    } on MissingPluginException {
      // Nothing answers: no fold.
    } on PlatformException {
      // The plugin answered that it could not measure: no fold.
    }
    _tell(FoldReading.fromMessage(message));
  }

  @override
  VoidCallback watch(ValueChanged<FoldReading> onReading) {
    if (_watchers.isEmpty) _channel.setMethodCallHandler(_handleCall);
    _watchers.add(onReading);
    // Asking is also what attaches the plugin to the view the app is in.
    unawaited(_read());

    return () {
      _watchers.remove(onReading);
      if (_watchers.isEmpty) _channel.setMethodCallHandler(null);
    };
  }

  @override
  void refresh() => unawaited(_read());
}
