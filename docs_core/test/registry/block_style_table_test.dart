@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/block_catalog.dart';
import 'package:test/test.dart';

/// Blocks 페이지의 `## 스타일` 표가 그 블록의 `CoreXxxStyle` 필드와 같은지.
///
/// 컴포넌트 페이지의 스타일 표는 소스에서 생성되지만(`STYLE_TABLE`), Blocks
/// 페이지는 Figma 의 블록 템플릿대로 한국어 설명을 손으로 적는다. 손으로 적은
/// 목록은 필드가 늘거나 줄 때 조용히 낡는다 — 새 필드는 문서에 없고, 지운
/// 필드는 문서에 남아 없는 값을 가르친다. 그래서 이름의 집합을 양쪽으로 본다.
void main() {
  for (final block in kDocsBlocks) {
    test('${block.slug}: 스타일 표의 필드가 CoreXxxStyle 의 필드와 같다', () {
      final markdown = File('content/blocks/${block.slug}.md').readAsStringSync();
      final styleFile = File(
        '../packages/coui_core/lib/src/component/contracts/${block.slug}/${block.slug}_style.dart',
      );
      expect(styleFile.existsSync(), isTrue, reason: '${styleFile.path} 가 없다');

      final documented = _styleTableNames(markdown);
      final fields = _styleFields(styleFile.readAsStringSync());

      expect(documented, isNotEmpty, reason: '${block.slug}.md 에 `## 스타일` 표가 없다');
      expect(fields, isNotEmpty, reason: 'CoreXxxStyle 필드를 읽지 못했다 — 정규식이 낡았다');
      expect(
        documented.difference(fields),
        isEmpty,
        reason: '문서에만 있는 필드 — CoreXxxStyle 에 없다',
      );
      expect(
        fields.difference(documented),
        isEmpty,
        reason: 'CoreXxxStyle 에만 있는 필드 — 문서의 스타일 표에 없다',
      );
    });
  }

  test('필드 읽기가 nullable 인스턴스 필드만 센다', () {
    expect(
      _styleFields('''
class CoreXStyle {
  static const double defaultGap = 4;
  final CoreColor? backgroundColor;
  final double? gap;
}
'''),
      {'backgroundColor', 'gap'},
    );
  });
}

/// `## 스타일` 아래 표의 첫 칸에 백틱으로 적힌 이름.
Set<String> _styleTableNames(String markdown) {
  final names = <String>{};
  var inStyle = false;
  for (final line in markdown.split('\n')) {
    if (line.startsWith('#')) {
      inStyle = RegExp(r'^## 스타일\s*$').hasMatch(line);
      continue;
    }
    if (!inStyle) continue;
    final cell = RegExp(r'^\|\s*`([^`]+)`').firstMatch(line);
    if (cell != null) names.add(cell.group(1)!);
  }
  return names;
}

/// `CoreXxxStyle` 의 인스턴스 필드 — 모두 nullable 이다(`core/style-contract.md`).
Set<String> _styleFields(String source) => {
  for (final match in RegExp(r'^\s+final [\w<>?, ]+\? (\w+);', multiLine: true).allMatches(source)) match.group(1)!,
};
