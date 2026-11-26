@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:test/test.dart';

// The docs are read by people who USE the kit. The words below are the ones
// people who MAKE the kit say to each other; in a page they are noise the
// reader has to decode before the sentence means anything. A reader stopped
// on a heading that began with one of them — that is what this guards.
//
// What is scanned is the prose a person wrote: body text, table cells, page
// titles and descriptions, and the comments inside code examples. API names
// are not prose — anything in backticks, link targets, the code of a fenced
// example, and the Style tables generated from source comments are skipped.
//
// The list is closed on purpose: a word is here because a plainer one says
// the same thing. Words a developer already knows (오버라이드 · 래퍼 · 네이티브)
// and design-system words the glossary defines (슬롯 · 토큰 · variant) are not.

/// A word the docs do not use, and what to write instead.
typedef _Word = ({String label, RegExp pattern, String instead});

final List<_Word> _words = [
  (
    label: 'chrome',
    // Lower-case only: `Chrome` is the browser's name.
    pattern: RegExp('(?<![A-Za-z])chrome(?![A-Za-z])'),
    instead: '겉모습 — 필요하면 "겉모습(색 · 크기 · 간격)"',
  ),
  (label: '크롬', pattern: RegExp('크롬'), instead: '겉모습 · 모양 · 창 틀'),
  (label: 'dimensional', pattern: RegExp(r'\bdimensional', caseSensitive: false), instead: '크기 · 간격'),
  (
    label: 'nested slot',
    pattern: RegExp(r'\bnested', caseSensitive: false),
    instead: '안쪽 부품의 스타일',
  ),
  (
    label: '단일 진입점',
    pattern: RegExp('단일 진입점'),
    instead: '"xxxStyle 하나" · "한 곳"',
  ),
  (label: '단일 슬롯', pattern: RegExp('단일 슬롯'), instead: '"xxxStyle 하나" · "한 곳"'),
  (
    label: 'resolver',
    pattern: RegExp(r'\bresolver|리졸버', caseSensitive: false),
    instead: '주어에서 빼거나 "스타일을 계산하는 코드"',
  ),
  (
    label: 'resolve chain',
    pattern: RegExp(r'\bresolve(?!r)', caseSensitive: false),
    instead: '값이 정해지는 순서 · 우선순위',
  ),
  (label: 'emit', pattern: RegExp(r'\bemit', caseSensitive: false), instead: '내보낸다 · 붙인다'),
  (label: 'paint-ready', pattern: RegExp('paint-ready', caseSensitive: false), instead: '바로 그릴 수 있는 값'),
  (label: 'raw-forward', pattern: RegExp('raw[- ]forward', caseSensitive: false), instead: '그대로 넘긴다'),
  (
    label: 'passthrough',
    pattern: RegExp('pass-?through|패스스루', caseSensitive: false),
    instead: '그대로 넘긴다',
  ),
  (
    label: 'flat 파라미터',
    pattern: RegExp(r'\bflat\s+(?:chrome|파라미터|필드|param|prop)|평면\s+(?:파라미터|필드)', caseSensitive: false),
    instead: '낱개 파라미터 · 낱개 필드',
  ),
  (
    label: 'behaviour',
    // Lower-case only: `(Behavior)` is the English gloss of a canonical heading.
    pattern: RegExp(r'\bbehaviou?r\b'),
    instead: '동작',
  ),
  (
    label: '시맨틱 enum',
    // The kit's sense — "the parameters that say what a thing is". The
    // accessibility sense (`Semantics`, 시맨틱 노드) is the platform's own word.
    pattern: RegExp(r'시맨틱\s*(?:enum|vs|축|식별자|변형|/\s*(?:behaviou?r|동작|구조))|시맨틱\s*\((?:variant|위젯)'),
    instead: '종류를 고르는 값 (variant · size)',
  ),
  (label: '합성 슬롯', pattern: RegExp(r'합성\s*슬롯'), instead: '위젯 슬롯'),
  (label: '중첩 슬롯', pattern: RegExp(r'중첩\s*슬롯'), instead: '안쪽 부품의 스타일'),
  (
    label: '단일 출처',
    pattern: RegExp(r'단일\s*출처|단일\s*소스|single source', caseSensitive: false),
    instead: '"한 곳에서 정한다"',
  ),
  (label: 'ambient', pattern: RegExp(r'\bambient\b', caseSensitive: false), instead: '주변의 · 위에서 내려 준'),
  (label: 'caller', pattern: RegExp(r'\bcallers?\b', caseSensitive: false), instead: '호출자'),
  (label: 'capability', pattern: RegExp(r'\bcapabilit', caseSensitive: false), instead: '기능'),
  (label: 'intrinsic', pattern: RegExp(r'\bintrinsic', caseSensitive: false), instead: '내용 크기 · 내용이 차지하는 폭'),
];

/// The words a generated Style table must not use.
///
/// The table's descriptions are the first paragraph of each field's doc
/// comment, in English. So this is the English half of [_words] — without
/// "caller", "behaviour" and "capability", which are ordinary English — plus
/// the notes the kit's makers leave each other in those comments.
final List<_Word> _tableWords = [
  for (final word in _words)
    if (const {
      'chrome',
      'dimensional',
      'nested slot',
      'resolver',
      'resolve chain',
      'emit',
      'paint-ready',
      'raw-forward',
      'passthrough',
      '단일 출처',
      'ambient',
      'intrinsic',
    }.contains(word.label))
      word,
  (label: 'seat', pattern: RegExp(r'\bseats?\b|1:1:1'), instead: '만드는 쪽의 메모 — 뒤 문단으로'),
  (label: 'wire it', pattern: RegExp(r'wire it|by no resolver', caseSensitive: false), instead: '만드는 쪽의 메모 — 뒤 문단으로'),
  (label: 'deliberately', pattern: RegExp(r'\bdeliberately\b', caseSensitive: false), instead: '만드는 쪽의 메모 — 뒤 문단으로'),
];

/// The description cell of each row of the `CoreXxxStyle` field tables in
/// [source], keyed by 1-based line number, with API names (anything in
/// backticks) taken out.
Map<int, String> styleTableDescriptions(String source) {
  final cells = <int, String>{};
  var inGenerated = false;
  var inFieldTable = false;
  for (final (index, line) in source.split('\n').indexed) {
    if (_generatedBegin.hasMatch(line) && line.contains('STYLE_TABLE')) {
      inGenerated = true;
      continue;
    }
    if (!inGenerated) continue;
    if (_generatedEnd.hasMatch(line)) {
      inGenerated = false;
      inFieldTable = false;
      continue;
    }
    if (line.startsWith('### ')) {
      inFieldTable = line.endsWith(' 필드');
      continue;
    }
    if (!inFieldTable || !line.startsWith('| `')) continue;
    final columns = line.split('|');
    if (columns.length < 5) continue;
    cells[index + 1] = columns[columns.length - 2].replaceAll(RegExp('`+[^`]*`+'), '\u0001');
  }
  return cells;
}

/// Pages written for the people who make the kit, where naming its layers is
/// the point.
const _makerPages = {'content/contributing.md'};

/// What is an API name rather than prose, inside a line of body text.
final _protected = RegExp(
  r'`+[^`\n]*`+' // inline code
  r'|\]\([^)\s]*\)' // link target
  r'|<a\s+id="[^"]*"></a>' // a preserved heading fragment
  r'|\b(?:component|variants|href|src|id|type|groupId|value|slug|icon|variant|language)="[^"]*"'
  r'|https?://\S+',
);
final _generatedBegin = RegExp(r'<!--\s*[A-Z_]+:BEGIN');
final _generatedEnd = RegExp(r'<!--\s*[A-Z_]+:END');
final _fence = RegExp(r'^\s*(```+|~~~+)');
final _frontmatterProse = RegExp(r'^(?:title|description):\s*(.*)$');
final _comment = RegExp(r'(?:^|\s)(?://|#)\s?(.*)$');

/// The prose of each line of [source], keyed by 1-based line number.
///
/// Lines that hold no prose (code, generated tables, structural markup) are
/// absent.
Map<int, String> proseOf(String source) {
  final prose = <int, String>{};
  final lines = source.split('\n');
  var inFrontmatter = false;
  var inGenerated = false;
  String? fence;
  for (final (index, line) in lines.indexed) {
    final number = index + 1;
    if (index == 0 && line.trim() == '---') {
      inFrontmatter = true;
      continue;
    }
    if (inFrontmatter) {
      if (line.trim() == '---') {
        inFrontmatter = false;
      } else if (_frontmatterProse.firstMatch(line) case final match?) {
        prose[number] = match.group(1)!;
      }
      continue;
    }
    final fenceMark = _fence.firstMatch(line)?.group(1)?.substring(0, 3);
    if (inGenerated) {
      if (_generatedEnd.hasMatch(line)) inGenerated = false;
      continue;
    }
    // A marker quoted inside a fenced example (the page template shows one) is
    // not a real one.
    if (fence == null && fenceMark == null && _generatedBegin.hasMatch(line)) {
      inGenerated = true;
      continue;
    }
    if (fenceMark != null) {
      if (fence == null) {
        fence = fenceMark;
      } else if (fence == fenceMark) {
        fence = null;
      }
      continue;
    }
    if (fence != null) {
      if (_comment.firstMatch(line) case final match?) prose[number] = match.group(1)!;
      continue;
    }
    prose[number] = line.replaceAll(_protected, '\u0001');
  }

  return prose;
}

/// The words of [_words] used in the prose of [source], as `line: word → fix`.
List<String> insiderWords(String source) => [
  for (final MapEntry(key: number, value: text) in proseOf(source).entries)
    for (final word in _words)
      if (word.pattern.hasMatch(text)) '$number: "${word.label}" → ${word.instead}',
];

void main() {
  group('the scanner', () {
    test('reads prose, and only prose', () {
      const page = '''
---
title: 버튼
description: chrome 을 가진 컨트롤
---

# 버튼

겉모습은 `chromeAnimationDuration` 과 [링크](/guides/chrome) 로 바꿉니다.
Chrome 브라우저에서는 다르게 그립니다.
모든 chrome 은 한 곳으로 갑니다.

```dart
final chrome = resolver.emit(); // caller 가 넘긴 값
```

<!-- STYLE_TABLE:BEGIN — generated -->
| `x` | Chrome of the nested slot, raw-forwarded by the resolver. |
<!-- STYLE_TABLE:END -->

안쪽 부품의 스타일은 그대로 넘깁니다.
''';

      expect(insiderWords(page), [
        // The page description is prose a reader sees.
        startsWith('3: "chrome"'),
        // Backticks, a link target and the browser's name are not flagged;
        // the bare word on the next line is.
        startsWith('10: "chrome"'),
        // Inside a fence only the comment is prose.
        startsWith('13: "caller"'),
      ]);
    });

    test('a generated-table marker quoted in a fenced example opens no block', () {
      const page = '''
```text
<!-- STYLE_TABLE:BEGIN — auto-generated -->
```

여기의 chrome 은 본문이다.
''';

      expect(insiderWords(page), [startsWith('5: "chrome"')]);
    });

    test('reads only the description cells of a generated field table', () {
      const page = '''
<!-- STYLE_TABLE:BEGIN — generated -->

### `CoreXxxStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `nestedStyle` | `CoreChromeStyle?` | Look of the label. `chromeColor` stays. |
| `gapStyle` | `CoreGapStyle?` | Nested slot for the gap. |

### `CoreXxxStyle` 변형별 기본값 (`CoreXxxVariantStyle`)

| 필드 | `nested` |
|------|------|
| `x` | chrome |

<!-- STYLE_TABLE:END -->
| `y` | `T` | chrome outside the block |
''';

      final cells = styleTableDescriptions(page);
      expect(cells.keys, [7, 8]);
      // Field names, types and API names in the description are not prose.
      expect(cells[7], isNot(contains('chrome')));
      expect(cells[8], contains('Nested slot'));
    });
  });

  test('pages explain in plain words, not in the words of the people who make the kit', () {
    final files =
        Directory('content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'))
            .map((file) => file.path.replaceAll(r'\', '/'))
            .where((path) => !path.contains('/_data/') && !_makerPages.contains(path))
            .toList()
          ..sort();
    // The walk found the pages — an empty walk would pass everything.
    expect(files.length, greaterThan(150));

    final problems = [
      for (final path in files)
        for (final issue in insiderWords(File(path).readAsStringSync())) '$path:$issue',
    ];

    expect(
      problems,
      isEmpty,
      reason:
          'These lines use words only the kit\'s makers use. Say what the word '
          'means instead (see content/guides/glossary.md):\n${problems.join('\n')}',
    );
  });

  test('the generated Style tables describe each field in plain words', () {
    final files =
        Directory('content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'))
            .map((file) => file.path.replaceAll(r'\', '/'))
            .where((path) => !path.contains('/_data/') && !path.contains('/_templates/'))
            .toList()
          ..sort();

    var rows = 0;
    final problems = <String>[];
    for (final path in files) {
      final cells = styleTableDescriptions(File(path).readAsStringSync());
      rows += cells.length;
      for (final MapEntry(key: number, value: text) in cells.entries) {
        for (final word in _tableWords) {
          if (word.pattern.hasMatch(text)) problems.add('$path:$number: "${word.label}" → ${word.instead}');
        }
      }
    }
    // The walk found the tables — an empty walk would pass everything.
    expect(rows, greaterThan(1000));

    expect(
      problems,
      isEmpty,
      reason:
          'A Style table shows the first paragraph of each field\'s doc '
          'comment. Rewrite that paragraph in CoreXxxStyle for the people who '
          'use the kit, move notes for the people who change it below it, and '
          'regenerate (dart run tool/generate_style_tables.dart --write):\n'
          '${problems.join('\n')}',
    );
  });

  test('the catalog describes each component in plain words', () {
    // The one-line description under each name on the component grid.
    final descriptions = {
      for (final entry in kDocsComponentEntries) entry.slug: entry.description,
      for (final block in kDocsBlocks) block.slug: block.description,
    };
    expect(descriptions.length, greaterThan(150));

    final problems = [
      for (final MapEntry(key: slug, value: description) in descriptions.entries)
        for (final word in _words)
          if (word.pattern.hasMatch(description)) '$slug: "$description" uses "${word.label}"',
    ];

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the glossary tells a reader how every one of those words is said here', () {
    final glossary = File('content/guides/glossary.md').readAsStringSync();
    final section = glossary.substring(glossary.indexOf('## 이 문서가 쓰지 않는 말'));

    for (final word in _words) {
      // The row names the word in backticks, so the page that lists the words
      // does not use them.
      final named = section.contains('`${word.label}`') || section.contains('`${word.label.split(' ').first}`');
      expect(named, isTrue, reason: '"${word.label}" has no row in the glossary');
    }
  });
}
