@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Figma 라이브러리 페이지가 기준 파일(`_data/figma_library.json`)과 같은
/// 라이브러리를 말하는지.
///
/// 페이지는 "기준 문서가 바뀌면 이 파일 하나만 고친다" 고 말하면서 식별자 ·
/// 표시 이름 · 링크를 본문에 적는다 — 앱은 템플릿을 풀지 않아 값을 본문에
/// 직접 적어야 한다. 그래서 기준 파일이 바뀌는 날 본문이 옛 라이브러리를
/// 가리킨 채 남지 않게, 두 곳이 같은지 여기서 본다.
void main() {
  final library = jsonDecode(File('content/_data/figma_library.json').readAsStringSync()) as Map<String, Object?>;
  final page = File('content/guides/figma-library.md').readAsStringSync();

  String row(String name) {
    final match = RegExp('^\\| ${RegExp.escape(name)} \\| (.+?) \\|\$', multiLine: true).firstMatch(page);
    expect(match, isNotNull, reason: '라이브러리 정보 표에 "$name" 줄이 없다');
    return match!.group(1)!.trim();
  }

  test('식별자가 기준 파일과 같다', () {
    expect(row('식별자'), library['identifier']);
  });

  test('표시 이름이 기준 파일과 같다', () {
    expect(row('표시 이름'), library['displayName']);
  });

  test('Figma 링크가 기준 파일의 주소로 간다', () {
    expect(row('Figma 링크'), endsWith('(${library['url']})'));
  });
}
