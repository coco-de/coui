import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart' as material;

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: coui_flutter')) {
    throw StateError(
      'coui_flutter 테스트를 레포 루트에서 돌리고 있다. '
      'cwd 가 빗나가면 골든이 픽셀 diff 34개로 실패하고 원인을 말하지 않는다.\n'
      'cd packages/coui_flutter && flutter test …\n'
      '또는 melos run test:flutter',
    );
  }
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: material.ThemeData(),
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: {.macOS},
        enabled: !const bool.fromEnvironment('CI'),
      ),
      ciGoldensConfig: CiGoldensConfig(
        enabled: const bool.fromEnvironment('CI'),
      ),
    ),
    run: () async => testMain(),
  );
}
