@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// 콘텐츠의 `<TabItem>` 이 전부 `value` 를 갖는지 본다.
///
/// 사이트의 탭은 `value` 로 탭과 패널을 짝짓고, 같은 `groupId` 의
/// 묶음들을 그 값으로 함께 바꾼다. 적지 않은 탭들은 같은 값(빈 문자열)으로
/// 겹쳐 첫 탭만 고를 수 있다 — 페이지는 에러 없이 렌더되고, 다른 플랫폼의
/// 코드로 갈 길만 사라진다.
void main() {
  test('모든 TabItem 이 value 를 갖는다', () {
    final tag = RegExp('<TabItem\\b[^>]*>');
    final missing = <String>[];

    for (final file in Directory('content').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;

      final lines = file.readAsLinesSync();
      for (final (index, line) in lines.indexed) {
        for (final match in tag.allMatches(line)) {
          if (!match.group(0)!.contains(RegExp(r'\bvalue\s*='))) missing.add('${file.path}:${index + 1}');
        }
      }
    }

    expect(missing, isEmpty, reason: '`value` 없는 탭은 서로 같은 탭으로 읽힌다');
  });

  test('한 묶음 안의 value 는 서로 다르다', () {
    final group = RegExp(r'<Tabs\b[^>]*>([\s\S]*?)</Tabs>');
    final value = RegExp('<TabItem\\b[^>]*\\bvalue\\s*=\\s*"([^"]*)"');
    final clashing = <String>[];

    for (final file in Directory('content').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;

      for (final tabs in group.allMatches(file.readAsStringSync())) {
        final values = value.allMatches(tabs.group(1)!).map((match) => match.group(1)!).toList();
        if (values.toSet().length != values.length) clashing.add('${file.path}: $values');
      }
    }

    expect(clashing, isEmpty);
  });
}
