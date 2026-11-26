import 'dart:async';

/// Browser-run tests under `test/web/` take this config instead of the
/// package one: that one reads `pubspec.yaml` through `dart:io`, which a
/// browser test cannot compile. Nothing here touches goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
