// #3852 — a malformed raw `getComputedStyle()` value must fail this ONE
// (entry, role) — as an `InfraFailure` `report.dart`/`compare.dart` already
// know how to isolate — not escape as an uncaught `FormatException` that
// kills the whole manifest run.
//
// #3860 — that isolation only covered `normalizeWebSnapshot`'s own
// `FormatException` on the Web side. The `jsonDecode` call one line above
// it, and any wrong-shape `TypeError` from an `as`/`!` on either platform,
// still escaped uncaught — and `loadFlutterPropertySnapshot` had no
// try/catch at all. Every test below has a mirror-image counterpart on the
// other platform so the isolation boundary can't drift out of sync between
// the two again without a failing test noticing.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/report/entry_loader.dart';

void main() {
  group('loadWebPropertySnapshot', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coui-entry-loader-');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    void writeWebJson(String key, Map<String, Object?> rootProperties) {
      File('${tempDir.path}/$key.web.json').writeAsStringSync(
        jsonEncode({
          'key': key,
          'chromeVersion': 'HeadlessChrome/1.0',
          'byRole': {'root': rootProperties},
        }),
      );
    }

    const validRootProperties = {
      'fontFamily': 'Pretendard',
      'fontWeight': '400',
      'fontSize': '14px',
      'lineHeight': '22.4px',
      'letterSpacing': 'normal',
      'color': 'rgb(29, 29, 31)',
      'backgroundColor': 'transparent',
      'borderTopColor': 'transparent',
      'borderRightColor': 'transparent',
      'borderBottomColor': 'transparent',
      'borderLeftColor': 'transparent',
      'borderTopWidth': '0px',
      'borderRightWidth': '0px',
      'borderBottomWidth': '0px',
      'borderLeftWidth': '0px',
      'borderTopLeftRadius': '0px',
      'borderTopRightRadius': '0px',
      'borderBottomRightRadius': '0px',
      'borderBottomLeftRadius': '0px',
      'paddingTop': '0px',
      'paddingRight': '0px',
      'paddingBottom': '0px',
      'paddingLeft': '0px',
      'outlineWidth': '0px',
      'outlineOffset': '0px',
      'boxShadow': 'none',
      'opacity': '1',
    };

    test('a well-formed capture normalizes without throwing', () {
      writeWebJson('button-primary-light-defaultStyle', validRootProperties);
      final snapshot = loadWebPropertySnapshot(
        key: 'button-primary-light-defaultStyle',
        capturedDir: tempDir,
        probeRole: 'root',
      );
      expect(snapshot.fontFamily, 'Pretendard');
    });

    // `color(srgb ...)` box shadows now parse (css_value_parsers_test.dart
    // covers that directly) — this uses a color syntax no parser recognizes
    // (`oklch(...)`) purely to exercise the *isolation* behavior: any
    // parser exception the normalizer throws must surface here as an
    // `InfraFailure`, not the raw `FormatException`.
    test(
      'a raw value no parser recognizes throws InfraFailure, not '
      'FormatException — this cell is skippable, not fatal to the whole run',
      () {
        writeWebJson('card-elevated-dark-claymorphism', {
          ...validRootProperties,
          'boxShadow': 'oklch(0 0 0 / 0.06) 0px 4px 12.8px -2px',
        });
        expect(
          () => loadWebPropertySnapshot(
            key: 'card-elevated-dark-claymorphism',
            capturedDir: tempDir,
            probeRole: 'root',
          ),
          throwsA(isA<InfraFailure>()),
        );
      },
    );

    // #3860 — the `jsonDecode` call was outside the old try/catch entirely,
    // so a truncated capture file threw an uncaught `FormatException`
    // straight out of this function.
    test(
      'truncated JSON throws InfraFailure, not a raw FormatException '
      '(#3860 — jsonDecode was outside the old try)',
      () {
        File(
          '${tempDir.path}/truncated-entry.web.json',
        ).writeAsStringSync('{"key": "truncated-entry", "byRole": {"roo');
        expect(
          () => loadWebPropertySnapshot(
            key: 'truncated-entry',
            capturedDir: tempDir,
            probeRole: 'root',
          ),
          throwsA(isA<InfraFailure>()),
        );
      },
    );

    test('an empty capture file throws InfraFailure, not FormatException', () {
      File('${tempDir.path}/empty-entry.web.json').writeAsStringSync('');
      expect(
        () => loadWebPropertySnapshot(
          key: 'empty-entry',
          capturedDir: tempDir,
          probeRole: 'root',
        ),
        throwsA(isA<InfraFailure>()),
      );
    });

    // #3860 — the old try/catch only ever caught `FormatException`, so a
    // `byRole.<role>` value that parsed as JSON but wasn't the expected
    // `Map` shape threw an uncaught `TypeError` from the `(raw as Map)`
    // cast one line into that same try block.
    test(
      'a role value of the wrong JSON type throws InfraFailure, not '
      'TypeError (#3860 — old catch clause was FormatException-only)',
      () {
        File('${tempDir.path}/wrong-shape-entry.web.json').writeAsStringSync(
          jsonEncode({
            'key': 'wrong-shape-entry',
            // 'root' should be an object (getComputedStyle() map); a bare
            // string is the kind of shape corruption a capture-harness bug
            // could produce.
            'byRole': {'root': 'not-an-object'},
          }),
        );
        expect(
          () => loadWebPropertySnapshot(
            key: 'wrong-shape-entry',
            capturedDir: tempDir,
            probeRole: 'root',
          ),
          throwsA(isA<InfraFailure>()),
        );
      },
    );

    test(
      "one entry's malformed capture does not prevent loading a sibling "
      "entry's well-formed capture — the run-wide crash #3852 reported",
      () {
        writeWebJson('card-elevated-dark-claymorphism', {
          ...validRootProperties,
          'boxShadow': 'oklch(0 0 0 / 0.06) 0px 4px 12.8px -2px',
        });
        writeWebJson('button-primary-light-defaultStyle', validRootProperties);

        // Mirrors report.dart's/compare.dart's own per-entry try/catch —
        // the malformed entry is caught and skipped, the well-formed
        // sibling still loads.
        InfraFailure? caught;
        try {
          loadWebPropertySnapshot(
            key: 'card-elevated-dark-claymorphism',
            capturedDir: tempDir,
            probeRole: 'root',
          );
        } on InfraFailure catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);

        final sibling = loadWebPropertySnapshot(
          key: 'button-primary-light-defaultStyle',
          capturedDir: tempDir,
          probeRole: 'root',
        );
        expect(sibling.fontFamily, 'Pretendard');
      },
    );
  });

  group('loadFlutterPropertySnapshot', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coui-entry-loader-');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    void writeFlutterJson(String key, Map<String, Object?> rootProperties) {
      File('${tempDir.path}/$key.flutter.json').writeAsStringSync(
        jsonEncode({
          'key': key,
          'byRole': {'root': rootProperties},
        }),
      );
    }

    const validRootProperties = {
      'key': 'button-primary-light-defaultStyle',
      'platform': 'flutter',
      'probeRole': 'root',
      'fontFamily': 'Pretendard',
      'fontWeight': 400,
    };

    test('a well-formed capture loads without throwing', () {
      writeFlutterJson(
        'button-primary-light-defaultStyle',
        validRootProperties,
      );
      final snapshot = loadFlutterPropertySnapshot(
        key: 'button-primary-light-defaultStyle',
        capturedDir: tempDir,
        probeRole: 'root',
      );
      expect(snapshot.fontFamily, 'Pretendard');
    });

    // #3860's own repro: a corrupted Flutter capture threw a `TypeError`
    // straight out of `main()` (exit 255) because this loader had *no*
    // try/catch at all — this test is the one that would have caught the
    // bug this issue reports.
    test(
      'a field of the wrong JSON type throws InfraFailure, not TypeError '
      "— #3860's measured repro (exit 255, whole run dead)",
      () {
        writeFlutterJson('corrupted-entry', {
          ...validRootProperties,
          // `key` must be a String (`PropertySnapshot.fromJson`'s
          // `json['key']! as String`) — an int is the wrong-shape capture
          // #3860 measured hitting this as an uncaught TypeError.
          'key': 12345,
        });
        expect(
          () => loadFlutterPropertySnapshot(
            key: 'corrupted-entry',
            capturedDir: tempDir,
            probeRole: 'root',
          ),
          throwsA(isA<InfraFailure>()),
        );
      },
    );

    test(
      'truncated JSON throws InfraFailure, not a raw FormatException '
      '(#3860 — jsonDecode had no try/catch on the Flutter path at all)',
      () {
        File(
          '${tempDir.path}/truncated-entry.flutter.json',
        ).writeAsStringSync('{"key": "truncated-entry", "byRole": {"roo');
        expect(
          () => loadFlutterPropertySnapshot(
            key: 'truncated-entry',
            capturedDir: tempDir,
            probeRole: 'root',
          ),
          throwsA(isA<InfraFailure>()),
        );
      },
    );

    test('an empty capture file throws InfraFailure, not FormatException', () {
      File('${tempDir.path}/empty-entry.flutter.json').writeAsStringSync('');
      expect(
        () => loadFlutterPropertySnapshot(
          key: 'empty-entry',
          capturedDir: tempDir,
          probeRole: 'root',
        ),
        throwsA(isA<InfraFailure>()),
      );
    });

    test(
      "one entry's malformed Flutter capture does not prevent loading a "
      "sibling entry's well-formed capture — mirrors the Web-side "
      "isolation test above so the two platforms can't drift apart again",
      () {
        writeFlutterJson('corrupted-entry', {
          ...validRootProperties,
          'key': 12345,
        });
        writeFlutterJson(
          'button-primary-light-defaultStyle',
          validRootProperties,
        );

        InfraFailure? caught;
        try {
          loadFlutterPropertySnapshot(
            key: 'corrupted-entry',
            capturedDir: tempDir,
            probeRole: 'root',
          );
        } on InfraFailure catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);

        final sibling = loadFlutterPropertySnapshot(
          key: 'button-primary-light-defaultStyle',
          capturedDir: tempDir,
          probeRole: 'root',
        );
        expect(sibling.fontFamily, 'Pretendard');
      },
    );
  });

  group('flutterStructuralSkipReason — rootOmitted 마커', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coui-structural-');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    void writeFlutterJson(
      String key, {
      required bool marker,
      Map<String, Object?> byRole = const {},
    }) {
      File('${tempDir.path}/$key.flutter.json').writeAsStringSync(
        jsonEncode({
          'key': key,
          'byRole': byRole,
          if (marker) 'rootOmitted': kRootOmittedNoChrome,
        }),
      );
    }

    test('마커 + role 부재 → 구조적 스킵 사유를 낸다', () {
      writeFlutterJson('star-rating-default-light-defaultStyle', marker: true);
      final reason = flutterStructuralSkipReason(
        key: 'star-rating-default-light-defaultStyle',
        capturedDir: tempDir,
        probeRole: 'root',
      );
      expect(reason, isNotNull);
      expect(reason, contains('구조적'));
      expect(reason, contains('픽셀 회귀는 계속'));
    });

    test('마커 없이 role 만 부재 → null (진짜 인프라 실패로 남는다)', () {
      writeFlutterJson('broken-default-light-defaultStyle', marker: false);
      final reason = flutterStructuralSkipReason(
        key: 'broken-default-light-defaultStyle',
        capturedDir: tempDir,
        probeRole: 'root',
      );
      expect(reason, isNull);
      expect(
        () => loadFlutterPropertySnapshot(
          key: 'broken-default-light-defaultStyle',
          capturedDir: tempDir,
          probeRole: 'root',
        ),
        throwsA(isA<InfraFailure>()),
      );
    });

    test('마커가 있어도 role 이 실재하면 null — 정상 로딩 경로', () {
      writeFlutterJson(
        'odd-default-light-defaultStyle',
        marker: true,
        byRole: {
          'root': {'fontWeight': 400},
        },
      );
      final reason = flutterStructuralSkipReason(
        key: 'odd-default-light-defaultStyle',
        capturedDir: tempDir,
        probeRole: 'root',
      );
      expect(reason, isNull);
    });

    test('파일 부재/손상 → null (그 사실은 원래의 InfraFailure 가 보고)', () {
      expect(
        flutterStructuralSkipReason(
          key: 'missing-default-light-defaultStyle',
          capturedDir: tempDir,
          probeRole: 'root',
        ),
        isNull,
      );
      File(
        '${tempDir.path}/corrupt-default-light-defaultStyle.flutter.json',
      ).writeAsStringSync('{not json');
      expect(
        flutterStructuralSkipReason(
          key: 'corrupt-default-light-defaultStyle',
          capturedDir: tempDir,
          probeRole: 'root',
        ),
        isNull,
      );
    });
  });
}
