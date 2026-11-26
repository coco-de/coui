import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/model/capture_surface.dart';

/// The Flutter-side mirror `capture_surface.dart`'s own doc comment names
/// — `coui_flutter` can't `import` this file (separate pub package), so it
/// carries its own copy of the value. Re-reading that copy's source text
/// here — the same "declare a literal, verify it doesn't silently drift"
/// pattern `surface_marker_registry_test.dart` already uses for a
/// different cross-package literal — is what keeps that copy honest: a PR
/// that changes one without the other fails this test instead of the two
/// captures silently comparing against two different widths.
const String _kFlutterMirrorRelativePath =
    'packages/coui_flutter/test/parity/capture_surface_test.dart';

final RegExp _kConstDeclarationPattern = RegExp(
  r'const int kCaptureAvailableWidthPx = (\d+);',
);

int _readMirroredConstant(String repoRoot) {
  final file = File(p.join(repoRoot, _kFlutterMirrorRelativePath));
  if (!file.existsSync()) {
    throw StateError('Flutter-side mirror를 찾지 못함: ${file.path}');
  }
  final match = _kConstDeclarationPattern.firstMatch(file.readAsStringSync());
  if (match == null) {
    throw StateError(
      '${file.path} 에서 kCaptureAvailableWidthPx 선언을 찾지 못함 — '
      '패턴이 갈렸거나 상수가 삭제됨.',
    );
  }
  return int.parse(match.group(1)!);
}

void main() {
  test(
    'kCaptureAvailableWidthPx matches its Flutter-side mirror '
    '($_kFlutterMirrorRelativePath)',
    () {
      final repoRoot = Directory.current.path;
      expect(
        kCaptureAvailableWidthPx,
        _readMirroredConstant(repoRoot),
        reason:
            'capture_surface.dart 의 kCaptureAvailableWidthPx 와 '
            '$_kFlutterMirrorRelativePath 의 사본이 갈렸다 — 한쪽만 '
            '바꾸면 두 플랫폼이 서로 다른 가용 폭을 캡처하게 된다. 둘을 '
            '같이 갱신하라.',
      );
    },
  );

  test('kCaptureAvailableWidthCss derives from kCaptureAvailableWidthPx', () {
    expect(kCaptureAvailableWidthCss, '${kCaptureAvailableWidthPx}px');
  });
}
