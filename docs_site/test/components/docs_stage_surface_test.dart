@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// 문서의 무대 바탕이 카드 흰색 하나인지 본다.
///
/// CoUI 라이트에서 `surfaceContainer` 는 `secondaryContainer` ·
/// `disabledContainer` 와 같은 값이라, 회색 타일 무대에서는 트랙 · filled 입력 ·
/// 비활성 면이 통째로 사라진다. 플레이그라운드의 Flutter 칸은
/// `preview_app.dart` 가 `surface` 를 칠하므로, 어느 시트가 Web 무대만 다시
/// 칠하면 두 칸의 바탕이 갈린다 — 더 구체적인 선택자를 가진 규칙 하나가 오류
/// 없이 바탕을 덮고, 그 차이는 화면을 열어 보기 전까지 보이지 않는다.
void main() {
  /// 주석을 뺀 (파일 이름, 선택자, 선언) 목록.
  final rules = [
    for (final sheet in Directory('web').listSync().whereType<File>().where((f) => f.path.endsWith('.css')))
      for (final rule in RegExp(r'([^{}]+)\{([^{}]*)\}').allMatches(
        sheet.readAsStringSync().replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ''),
      ))
        (file: sheet.uri.pathSegments.last, selector: rule.group(1)!.trim(), body: rule.group(2)!),
  ];

  /// 무대 상자 자신을 고르는 선택자 — 무대 안의 자손을 고르는 것은 뺀다.
  final stage = RegExp(r'\.docs-(playground-stage|anatomy-stage|stage(--[a-z0-9]+)?)(?![\w-])[^\s>+~,]*\s*(,|$)');

  List<String> painting() => [
    for (final rule in rules)
      if (stage.hasMatch(rule.selector) && RegExp(r'(^|;)\s*background(-color)?\s*:').hasMatch(rule.body))
        '${rule.file}: ${rule.selector} → ${RegExp(r'background(-color)?\s*:\s*([^;]+)').firstMatch(rule.body)!.group(2)!.trim()}',
  ];

  test('바탕을 칠하는 규칙은 미리보기 무대와 플레이그라운드 둘이고 카드 면을 읽는다', () {
    expect(
      painting(),
      unorderedEquals([
        'docs-shell.css: .docs-stage → rgb(var(--site-card))',
        'docs-shell.css: .docs-playground-stage → rgb(var(--site-card))',
      ]),
    );
  });

  test('카드 면은 surface 다', () {
    expect(File('web/docs-shell.css').readAsStringSync(), contains('--site-card: var(--coui-surface);'));
  });

  test('미리보기 무대의 경계는 자리를 차지하지 않는 선이다', () {
    // 좁은 화면 규칙도 같은 선택자를 쓴다 — 바탕을 칠하는 것이 기본 규칙이다.
    final base = rules.singleWhere(
      (rule) => rule.file == 'docs-shell.css' && rule.selector == '.docs-stage' && rule.body.contains('background:'),
    );
    expect(base.body, contains('outline: var(--coui-stroke-width-1) solid rgb(var(--site-line));'));
    expect(base.body, isNot(contains('border:')));
  });
}
