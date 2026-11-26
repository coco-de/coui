import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Files the matrix pipeline consists of — #3608's completion definition
/// promises a new `CoreSurfaceStyleId` value costs the pipeline a zero-line
/// diff, which is only true if none of these files branch on an individual
/// preset by name (a `case .liquidGlass:` would have to grow a new arm for
/// a 6th style). This list is the pipeline's full surface today; a new file
/// that starts consuming `CoreSurfaceStyleId` belongs here too.
const _kPipelineFiles = [
  'tool/parity/manifest.dart',
  'tool/parity/src/manifest/parity_manifest.dart',
  'tool/parity/src/manifest/surface_style_pruning.dart',
  'tool/parity/src/manifest/material_reach.dart',
  'tool/parity/src/model/matrix_entry.dart',
];

void main() {
  test(
    'no pipeline file branches on an individual CoreSurfaceStyleId member',
    () {
      final repoRoot = Directory.current.path;
      // `CoreSurfaceStyleId.values` (iteration) and `.defaultId` (the one
      // named fallback) are the only allowed references — both are total
      // over however many members the enum has, so neither needs an edit
      // when a 6th style is added. Anything naming a specific member
      // (`.liquidGlass`, a `case .neoBrutalism:`, …) is a per-style branch,
      // and is exactly what a new preset would force someone to extend.
      final allowed = RegExp(r'CoreSurfaceStyleId\.(values|defaultId)\b');
      final anyReference = RegExp(r'CoreSurfaceStyleId\.');

      for (final relative in _kPipelineFiles) {
        final file = File(p.join(repoRoot, relative));
        expect(file.existsSync(), isTrue, reason: '$relative 를 찾을 수 없다');
        final source = file.readAsStringSync();

        final references = anyReference.allMatches(source).length;
        final allowedReferences = allowed.allMatches(source).length;
        expect(
          allowedReferences,
          references,
          reason:
              '$relative 가 CoreSurfaceStyleId 의 개별 멤버를 이름으로 참조한다 — '
              '.values 로 순회하거나 .defaultId 를 쓰는 것만 허용된다. '
              '새 프리셋이 추가될 때 이 파일도 고쳐야 한다면 완료 정의의 '
              '"diff 0줄" 이 거짓이 된다.',
        );
      }
    },
  );
}
