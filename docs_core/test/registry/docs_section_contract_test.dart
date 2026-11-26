@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/heading_slug.dart';
import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_template.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

// A missing section is invisible to the API-name gate: an absent contract cannot
// advertise a ghost parameter. Keep coverage catalog-derived so a new component
// cannot disappear behind the historical audit's fixed denominator.
const _props = 'Props / Parameters';
const _style = '스타일 시스템 (Style System)';
const _behavior = '동작 스펙 (Behavior)';
const _platform = '크로스 플랫폼 차이점 (Platform Differences)';

void main() {
  group('section gate regression fixtures', () {
    test('finds legacy Props and Theme headings', () {
      expect(
        _nonCanonicalHeadings('## Props\n\n## Theming\n'),
        ['Props → $_props', 'Theming → $_style'],
      );
    });

    test('ignores heading-looking text in fenced examples', () {
      expect(
        _nonCanonicalHeadings('```markdown\n## Props\n```\n\n## $_props\n'),
        isEmpty,
      );
    });

    test('specialized style details belong under the canonical section', () {
      expect(
        _nonCanonicalHeadings(
          '## $_style\n\n### `CoreWindowStyle`\n\nFields.\n',
        ),
        isEmpty,
      );
      expect(
        _nonCanonicalHeadings('## 스타일 시스템 — `windowStyle`\n'),
        ['스타일 시스템 — windowStyle → $_style'],
      );
    });

    test('a heading in a code example cannot satisfy section presence', () {
      expect(_headings('```markdown\n## $_behavior\n```'), isEmpty);
    });

    test('a demoted H3 already preserves its original fragment', () {
      expect(
        _aliasCollisions('### Theming\n\n<a id="theming"></a>\n'),
        ['theming'],
      );
      expect(
        _aliasCollisions('## $_props\n\n<a id="props"></a>\n'),
        isEmpty,
      );
    });

    test('legacy anchors survive the site Markdown renderer', () {
      final html = md.markdownToHtml(
        '## $_props\n\n<a id="props"></a>\n\nThe API.\n',
        extensionSet: docsHeadingAwareExtensionSet,
      );
      expect(html, contains('<h2 id="props-parameters">'));
      expect(html, contains('<a id="props"></a>'));
    });

    test('example anchors are not DOM ids, real attributed anchors are', () {
      expect(
        _aliasCollisions(
          '## $_props\n\n```html\n<a id="props-parameters"></a>\n```\n',
        ),
        isEmpty,
      );
      expect(
        _aliasCollisions(
          '## $_props\n\n<a class="legacy" id="props-parameters" aria-hidden="true"></a>\n',
        ),
        ['props-parameters'],
      );
    });
  });

  final pages = <String, String>{
    for (final entry in kDocsComponentEntries) 'components/${entry.slug}': 'content/components/${entry.slug}.md',
    for (final entry in kDocsBlocks) 'blocks/${entry.slug}': 'content/blocks/${entry.slug}.md',
  };

  test('component template emits the same canonical primary sections', () {
    final source = File('content/_templates/component.md').readAsStringSync();
    expect(_nonCanonicalHeadings(source), isEmpty);
    final headings = _headings(source);
    for (final required in ['Live Preview', _props, _behavior, _platform]) {
      expect(
        headings.where((heading) => heading == required),
        hasLength(1),
        reason: 'The template must emit one "$required" section',
      );
    }
  });

  test('published components and blocks use canonical section headings', () {
    expect(pages, isNotEmpty);
    final problems = <String>[];
    for (final entry in pages.entries) {
      final file = File(entry.value);
      expect(file.existsSync(), isTrue, reason: entry.key);
      final source = file.readAsStringSync();
      for (final issue in _nonCanonicalHeadings(source)) {
        problems.add('${entry.key}: $issue');
      }
      final headings = _headings(source);
      final v2 = docsUsesTemplateV2(source);
      final block = entry.key.startsWith('blocks/');
      // v2 페이지와 Blocks 페이지(`docs_template.dart`)는 Figma 페이지
      // 템플릿의 섹션을 갖는다 — 기존 구성의 필수 섹션은 그 자리로 옮겨 간다.
      final required = block
          ? kDocsBlockRequiredSections
          : v2
          ? kDocsV2RequiredSections
          : ['Live Preview', _props, _behavior, _platform];
      for (final section in required) {
        final count = headings.where((heading) => heading == section).length;
        if (count != 1) {
          problems.add('${entry.key}: "$section" must occur once (got $count)');
        }
      }
      if (block) {
        problems.addAll(_orderProblems(entry.key, headings, kDocsBlockSections, 'block'));
      } else if (v2) {
        problems.addAll(_orderProblems(entry.key, headings, kDocsV2Sections, 'v2'));
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('v2 order check catches a section placed out of order', () {
    expect(_orderProblems('fixture', ['플레이그라운드', 'API', '접근성'], kDocsV2Sections, 'v2'), hasLength(1));
    expect(_orderProblems('fixture', ['플레이그라운드', '링크 버튼', '접근성', 'API'], kDocsV2Sections, 'v2'), isEmpty);
  });

  test('block order check catches a section placed out of order', () {
    expect(_orderProblems('fixture', ['레이아웃', '접근성', '속성'], kDocsBlockSections, 'block'), hasLength(1));
    expect(_orderProblems('fixture', ['구조', '레이아웃', '레시피', '속성', '플랫폼 차이'], kDocsBlockSections, 'block'), isEmpty);
  });

  test('explicit legacy anchors do not duplicate heading ids', () {
    final problems = <String>[];
    for (final entry in pages.entries) {
      final source = File(entry.value).readAsStringSync();
      final seen = <String>{};
      for (final heading in _headings(source)) {
        final id = slugifyHeadingText(heading);
        if (!seen.add(id)) problems.add('${entry.key}: duplicate heading #$id');
      }
      for (final id in _aliasCollisions(source)) {
        problems.add('${entry.key}: duplicate legacy #$id');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}

/// 템플릿 섹션의 상대 순서 — 목록에 없는 섹션(그 페이지에만 있는 것)은 건너뛴다.
List<String> _orderProblems(String page, List<String> headings, List<String> sections, String template) {
  final problems = <String>[];
  var previous = -1;
  for (final heading in headings) {
    final rank = sections.indexOf(heading);
    if (rank < 0) continue;
    if (rank < previous) problems.add('$page: "$heading" is out of the $template order');
    if (rank > previous) previous = rank;
  }
  return problems;
}

List<md.Element> _headingNodes(String source) =>
    md.Document(
          blockSyntaxes: docsHeadingAwareBlockSyntaxes,
          inlineSyntaxes: docsHeadingAwareInlineSyntaxes,
        )
        .parseLines(source.split('\n'))
        .whereType<md.Element>()
        .where((node) => RegExp(r'^h[1-6]$').hasMatch(node.tag))
        .toList();

List<String> _headings(String source) =>
    _headingNodes(source).where((node) => node.tag == 'h2').map((node) => node.textContent).toList();

List<String> _aliasCollisions(String source) {
  final seen = _headingNodes(source).map((node) => node.generatedId ?? slugifyHeadingText(node.textContent)).toSet();
  final collisions = <String>[];
  final html = md.markdownToHtml(
    source,
    extensionSet: docsHeadingAwareExtensionSet,
  );
  for (final match in RegExp(r'<a\b[^>]*\bid="([^"]+)"[^>]*>').allMatches(html)) {
    final id = match.group(1)!;
    if (!seen.add(id)) collisions.add(id);
  }
  return collisions;
}

List<String> _nonCanonicalHeadings(String source) {
  final problems = <String>[];
  for (final heading in _headings(source)) {
    final canonical = switch (heading) {
      _ when RegExp(r'^(Props|Parameters|파라미터)\b').hasMatch(heading) => _props,
      _ when RegExp(r'^(스타일 시스템|테마 커스터마이징|Style|Theme|Theming)(?:$|\s|\()').hasMatch(heading) => _style,
      _ when heading.startsWith('동작 스펙') || heading == 'Behavior' => _behavior,
      _ when heading.startsWith('크로스 플랫폼') || heading.startsWith('양쪽 플랫폼 차이') || heading == 'Platform Differences' =>
        _platform,
      _ => null,
    };
    if (canonical != null && heading != canonical) {
      problems.add('$heading → $canonical');
    }
  }
  return problems;
}
