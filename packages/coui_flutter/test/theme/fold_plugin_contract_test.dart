// The two halves of the iOS fold bridge agree on their words.
//
// The native half (`ios/`) is not compiled by any test here — it builds only
// with an iOS toolchain. What can drift without one is the wording the halves
// share: the class the tooling registers, the channel and its two methods,
// the keys of a reading and the names of the hinge's states. A rename on one
// side would build, pass every Dart test, and read "no fold" on a device.
// This reads both sides as text and holds them together.
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const String _kPluginRoot = 'ios';
const String _kSources = '$_kPluginRoot/coui_flutter/Sources/coui_flutter';

String _read(String path) => File(path).readAsStringSync();

/// The value of the `static NSString *const <name> = @"…";` in [source].
String _nativeConstant(String source, String name) {
  final match = RegExp(
    'static NSString \\*const $name = @"([^"]*)";',
  ).firstMatch(source);
  expect(match, isNotNull, reason: 'the native constant $name');

  return match!.group(1)!;
}

void main() {
  final pubspec = _read('pubspec.yaml');
  final header = _read('$_kSources/include/coui_flutter/CoUIFoldPlugin.h');
  final native = _read('$_kSources/CoUIFoldPlugin.m');
  final feed = _read('lib/src/theme/fold_feed.dart');

  test('the class the tooling registers is the class the plugin declares', () {
    final pluginClass = RegExp(
      r'ios:\s*\n\s*pluginClass:\s*(\w+)',
    ).firstMatch(pubspec)?.group(1);

    expect(pluginClass, isNotNull);
    expect(header, contains('@interface $pluginClass : NSObject'));
    expect(native, contains('@implementation $pluginClass'));
    // The generated registrant imports `<package/Class.h>`.
    expect(
      File('$_kSources/include/coui_flutter/$pluginClass.h').existsSync(),
      isTrue,
    );
  });

  test('both build systems build the package under its own name', () {
    final package = _read('$_kPluginRoot/coui_flutter/Package.swift');
    final podspec = _read('$_kPluginRoot/coui_flutter.podspec');

    expect(package, contains('name: "coui_flutter"'));
    // The tooling asks for the product by the package name with hyphens.
    expect(package, contains('.library(name: "coui-flutter"'));
    expect(package, contains('FlutterFramework'));
    expect(podspec, contains("s.name             = 'coui_flutter'"));
    expect(podspec, contains("'coui_flutter/Sources/coui_flutter/**/*.{h,m}'"));
  });

  test('the halves speak on one channel, with the same two methods', () {
    final channel = _nativeConstant(native, 'kCoUIFoldChannelName');
    final read = _nativeConstant(native, 'kCoUIFoldReadMethod');
    final changed = _nativeConstant(native, 'kCoUIFoldChangedMethod');

    expect(feed, contains("MethodChannel('$channel')"));
    expect(feed, contains("invokeMethod<Object?>('$read')"));
    expect(feed, contains("call.method == '$changed'"));
  });

  test('the hinge has the same states on both sides', () {
    final nativeStates = {
      for (final match in RegExp(
        r'static NSString \*const kCoUIFoldStatus\w+ = @"(\w+)";',
      ).allMatches(native))
        match.group(1)!,
    };

    expect(nativeStates, {
      for (final status in FoldHingeStatus.values) status.name,
    });
  });

  test('a reading the native half builds is one the Dart half reads', () {
    // Built here with the keys the native source spells, so a key renamed on
    // one side fails to read.
    for (final key in ['status', 'divisions']) {
      expect(native, contains('@"$key" :'), reason: key);
    }
    final division = <String, Object?>{};
    for (final key in ['left', 'top', 'width', 'height', 'active']) {
      expect(native, contains('@"$key" :'), reason: key);
      division[key] = key == 'active' ? true : 1.0;
    }

    final reading = FoldReading.fromMessage({
      'status': FoldHingeStatus.partiallyOpen.name,
      'divisions': [division],
    });

    expect(reading.status, FoldHingeStatus.partiallyOpen);
    expect(reading.divisions.single.active, isTrue);
    expect(reading.divisions.single.bounds, const Rect.fromLTWH(1, 1, 1, 1));
  });

  test('the fold APIs are behind the SDK check and the OS check', () {
    // Without the first an older Xcode fails to compile every app that
    // depends on the package; without the second the same binary calls an
    // API a device below iOS 27.1 does not have.
    expect(
      native,
      contains(
        '#if __has_include(<UIKit/UIHingeInteraction.h>) && '
        '__has_include(<UIKit/UIViewReservedRegion.h>)',
      ),
    );
    expect(native, contains('if (@available(iOS 27.1, *))'));
    final guarded = native.split('#if COUI_FOLD_HAS_SDK');
    // Every mention of the new types sits after a guard opens.
    expect(guarded.first, isNot(contains('UIHingeInteraction *')));
    expect(guarded.first, isNot(contains('UIViewReservedRegion *')));
  });
}
