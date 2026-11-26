import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String previewSource;
  late Set<String> flutterRegistryKeys;
  late Map<String, String> constraintMap;

  setUpAll(() {
    // 제약 맵은 `shared/preview_constraints.dart` 로 옮겼다 — 순수 Dart 라
    // jaspr 사이트와 네이티브 docs_app 이 같은 숫자를 읽는다.
    previewSource = File(
      'lib/shared/preview_constraints.dart',
    ).readAsStringSync();
    flutterRegistryKeys = _parseRegistryKeys(
      'lib/previews/flutter_registry.dart',
    );
    constraintMap = _parseConstraintMap(previewSource);
  });

  group('Flutter preview constraints', () {
    test('every constraint references a valid component key', () {
      for (final key in constraintMap.keys) {
        expect(
          flutterRegistryKeys,
          contains(key),
          reason: '"$key" in constraint map but missing from flutter registry',
        );
      }
    });

    test('constraint variables are defined', () {
      final definedVars = RegExp(
        r'(?:final|const)\s+(_?k\w+Constraints)\s*=',
      ).allMatches(previewSource).map((m) => m.group(1)!).toSet();

      for (final entry in constraintMap.entries) {
        expect(
          definedVars,
          contains(entry.value),
          reason: '${entry.key} references ${entry.value} which is not defined',
        );
      }
    });

    test('compact components use compact constraints', () {
      const compactComponents = [
        'badge',
        'kbd',
        'divider',
        'separator',
        'dot-indicator',
        'status',
        'loading',
        'icon',
      ];

      for (final key in compactComponents) {
        if (constraintMap.containsKey(key)) {
          expect(
            constraintMap[key],
            equals('kDocsCompactConstraints'),
            reason: '$key should use kDocsCompactConstraints',
          );
        }
      }
    });

    test('overlay components use tall or extra-tall constraints', () {
      const overlayComponents = ['dialog', 'drawer', 'command'];
      const tallVars = {'kDocsTallConstraints', 'kDocsExtraTallConstraints'};

      for (final key in overlayComponents) {
        if (constraintMap.containsKey(key)) {
          expect(
            tallVars,
            contains(constraintMap[key]),
            reason: '$key should use tall/extra-tall constraints',
          );
        }
      }
    });

    test('default constraints exist for unlisted components', () {
      expect(
        previewSource,
        contains('kDocsDefaultConstraints'),
        reason: 'Default constraints variable must be defined',
      );

      // 폴백 체인은 조회 단일 출처 `docsPreviewConstraintsFor` 가 소유한다
      // (per-variant → chain 하한 → component → 기본값). 소비자(web_preview,
      // docs_site 의 flutter_preview)는 그 함수를 부를 뿐이다 — 폴백 동작
      // 자체는 shared/preview_constraints_lookup_test.dart 가 값으로
      // 검증하고, 여기서는 web_preview 가 손으로 체인을 복제하지 않고
      // 단일 출처를 경유하는지만 본다.
      expect(
        File('lib/components/web_preview.dart').readAsStringSync(),
        contains('docsPreviewConstraintsFor('),
        reason: 'web_preview must resolve constraints via the shared lookup',
      );
    });

    test('Web pane sits on the same fixed stage as the Flutter view', () {
      // Flutter view 는 앱 루트가 뷰를 채우므로 tier 의 maxHeight 로
      // 풀린다. Web 팬이 `max-height` 상한만 받으면 콘텐츠만큼 줄어들어
      // 두 팬 높이가 갈린다 — 고정 `height` 여야 구조적으로 같다.
      final webPreview = File(
        'lib/components/web_preview.dart',
      ).readAsStringSync();
      expect(
        webPreview,
        contains("'height': '\${constraints.maxHeight.toInt()}px'"),
        reason: 'Web pane must take the tier maxHeight as a fixed height',
      );
      expect(
        webPreview,
        isNot(contains("'max-height':")),
        reason: 'a max-height cap lets the Web pane shrink below the stage',
      );
    });
  });
}

Set<String> _parseRegistryKeys(String path) {
  final content = File(path).readAsStringSync();
  // Value may be public or private (`_buttonPreview` / `buttonCode`).
  final regex = RegExp(
    r"^\s*'([a-z][a-z0-9-]*)'\s*:\s*[_a-zA-Z]",
    multiLine: true,
  );
  return regex.allMatches(content).map((m) => m.group(1)!).toSet();
}

/// Parses `'component': kXxxConstraints,` from the constraint map.
///
/// The constraint variables are public (`kCompactConstraints`); the optional
/// `_` keeps the matcher tolerant of legacy private naming.
Map<String, String> _parseConstraintMap(String source) {
  final regex = RegExp(
    r"'([a-z][a-z0-9-]*)'\s*:\s*(_?k\w+Constraints)",
    multiLine: true,
  );
  return {
    for (final m in regex.allMatches(source)) m.group(1)!: m.group(2)!,
  };
}
