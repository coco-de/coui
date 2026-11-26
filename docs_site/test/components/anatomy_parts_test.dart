@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 구조(`<Anatomy>`)의 번호가 가리키는 부분이 서버가 그린 마크업에 있는가.
///
/// 번호는 브라우저에서 `web/docs-shell.js` 가 부분을 찾아 그 옆에 놓는다.
/// 부분을 못 찾으면 번호가 숨고, 엉뚱한 요소를 찾으면(컴포넌트가 앞에 그린
/// `<style>` 의 글자처럼) 무대 밖으로 간다 — 둘 다 에러 없이 지나가서, 실제로
/// 여러 페이지가 그렇게 그려진 채 만들어졌다. 여기서는 레지스트리의 모든
/// 페이지에 대해 스크립트와 같은 규칙으로 부분을 찾는다.
///
/// 이 테스트가 보지 못하는 것: 배치(번호가 다른 번호 · 요소와 겹치는지)는
/// 글꼴과 폭이 정하므로 브라우저에서 본다. 그리지 않는 요소를 빼는 규칙 중
/// "화면에 상자가 있는가" 는 서버 마크업으로 알 수 없어, 태그로 정하는
/// 부분만 따라 한다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final script = File('web/docs-shell.js').readAsStringSync();
  final skipped = _skippedTags(script);

  test('스크립트가 그리지 않는 태그 목록을 하나로 갖는다', () {
    expect(skipped, containsAll(['style', 'script']));
  });

  test('라벨은 앞에 그려진 <style> 의 글자가 아니라 그 뒤의 글자다', () {
    // 상태 규칙을 범위 지정 `<style>` 로 내는 컴포넌트(Button · Checkbox ·
    // Toggle …)가 이 모양이다. 지금 페이지들은 선택자로 이 경우를 비켜 가므로
    // 규칙은 여기서 고정한다.
    final root = html_parser
        .parseFragment('<button><style>.a{color:red}</style><span>저장</span></button>')
        .children
        .single;
    final label = _part(root, 'label', skipped);
    expect(label?.localName, 'span');
    expect(label?.text, '저장');
  });

  final slugs = kDocsPlaygrounds.keys.toList()..sort();
  test('레지스트리의 페이지를 돈다', () => expect(slugs, isNotEmpty));

  for (final slug in slugs) {
    for (final scene in readDocsScenes(slug).where((scene) => scene.tag == 'Anatomy')) {
      testServer('$slug ${scene.attributes['demo'] ?? scene.attributes['component']} — 모든 번호가 부분을 찾는다', (
        tester,
      ) async {
        tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: renderWebScene(scene)));
        final document = (await tester.request('/')).document!;
        final stage = document.querySelector('[data-docs-anatomy]')!;
        final root = stage.querySelector('.docs-anatomy-target')!.children.first;

        final problems = <String>[];
        for (final spec in stage.attributes['data-docs-anatomy']!.split(';')) {
          final at = spec.lastIndexOf('@');
          final what = at < 0 ? spec : spec.substring(0, at);
          if (what.isEmpty) continue;
          final html.Element? found;
          try {
            found = _part(root, what, skipped);
          } on UnsupportedError catch (error) {
            problems.add('"$what": ${error.message}');
            continue;
          }
          if (found == null) {
            problems.add('"$what": 찾지 못함 — 번호가 숨는다');
          } else if (_insideAny(found, _neverDrawn)) {
            problems.add('"$what": 그리지 않는 <${found.localName}> 를 찾음 — 번호가 무대 밖으로 간다');
          }
        }
        expect(problems, isEmpty, reason: '$slug ${scene.origins.first}\n  ${problems.join('\n  ')}');
      });
    }
  }
}

/// 화면에 아무것도 그리지 않는 태그 — 번호가 가리켜서는 안 되는 요소.
///
/// 스크립트의 목록([_skippedTags])과 따로 둔다: 같은 목록으로 찾고 같은
/// 목록으로 판정하면, 스크립트에서 한 태그를 빼는 회귀를 볼 수 없다.
const _neverDrawn = ['style', 'script', 'template', 'noscript'];

/// 스크립트의 `anatomySkippedTags` — 부분을 찾을 때 건너뛰는 태그(소문자).
List<String> _skippedTags(String script) {
  final list = RegExp(r'const anatomySkippedTags = \[([^\]]*)\]').firstMatch(script);
  if (list == null) throw StateError('docs-shell.js 에 anatomySkippedTags 가 없다');
  return [for (final m in RegExp("'([A-Z]+)'").allMatches(list.group(1)!)) m.group(1)!.toLowerCase()];
}

/// 스크립트의 `anatomyPart` 와 같은 규칙.
html.Element? _part(html.Element root, String what, List<String> skipped) {
  List<html.Element> icons() => [
    for (final svg in root.querySelectorAll('svg'))
      if (!_insideAny(svg, skipped)) svg,
  ];
  switch (what) {
    case 'container':
      return root;
    case 'leading':
      return icons().firstOrNull;
    case 'trailing':
      final all = icons();
      return all.length > 1 ? all.last : null;
    case 'label':
      for (final element in root.querySelectorAll('*')) {
        if (_insideAny(element, skipped)) continue;
        if (_insideAny(element, const ['svg']) || element.querySelector('svg') != null) continue;
        if (element.children.isEmpty && element.text.trim().isNotEmpty) return element;
      }
      return null;
    default:
      return _select(root, what);
  }
}

/// `root.querySelector(selector)` — 이 페이지들이 쓰는 `A:has(> B)` 는
/// `package:html` 이 읽지 못해 직접 푼다. 그 밖에 읽지 못하는 선택자는
/// 실패로 알린다(검사하지 못한 채 지나가지 않게).
html.Element? _select(html.Element root, String selector) {
  if (selector.contains(':nth-child(')) {
    // `package:html` 은 이것을 글자 노드까지 0부터 센다 — 여기서 찾은 것은
    // 브라우저가 찾는 것과 다르다.
    throw UnsupportedError('`:nth-child` 는 검사하지 못한다 — `+` · `:first-child` · `:last-child` 를 쓴다');
  }
  final has = RegExp(r'^(.+?):has\(>\s*(.+)\)$').firstMatch(selector);
  try {
    if (has == null) return root.querySelector(selector);
    for (final candidate in root.querySelectorAll(has.group(1)!)) {
      if (candidate.querySelectorAll(has.group(2)!).any((child) => child.parent == candidate)) return candidate;
    }
    return null;
  } on UnimplementedError catch (error) {
    throw UnsupportedError('이 테스트가 읽지 못하는 선택자 (${error.message}) — 더 단순한 선택자를 쓴다');
  }
}

/// [element] 또는 그 조상이 [tags] 중 하나인가.
bool _insideAny(html.Element element, List<String> tags) {
  for (html.Element? node = element; node != null; node = node.parent) {
    if (tags.contains(node.localName)) return true;
  }
  return false;
}
