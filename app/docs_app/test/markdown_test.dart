/// 마크다운 렌더러 — 파서 단위 테스트 + 실제 docs_site 콘텐츠 전수 렌더.
library;

import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/content/docs_page.dart';
import 'package:docs_app/src/markdown/docs_heading.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/preview/preview_theme.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// 커스텀 태그 자체는 여기 관심사가 아니다 — 자리만 잡는 스텁으로 둔다.
final _stubRegistry = DocsTagRegistry({
  for (final name in [
    'LivePreview',
    'Callout',
    'Tabs',
    'TabItem',
    'Info',
    'ComponentGrid',
  ])
    name: (context, tag) => const Text('stub'),
});

List<File> _contentFiles() => Directory('../../docs_core/content')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.md'))
    .toList();

void main() {
  group('docs_tag', () {
    test('커스텀 태그만 잡고 코드 펜스 안의 제네릭은 건드리지 않는다', () {
      const source = '''
<LivePreview component="card" variants="a,b" />

```dart
Map<String, List<Widget>> x;
```

산문 속의 <Widget> 은 태그가 아니다.

<Callout type="tip">
안쪽 **마크다운**
</Callout>
''';
      final tags = findDocsTags(source);

      expect(tags.map((match) => match.tag.name), ['LivePreview', 'Callout']);
      expect(tags.first.tag.attributes, {
        'component': 'card',
        'variants': 'a,b',
      });
      // self-closing 은 innerMarkdown 이 없다 — 빈 문자열과 구분된다.
      expect(tags.first.tag.innerMarkdown, isNull);
      expect(tags.last.tag.innerMarkdown, contains('안쪽 **마크다운**'));
    });

    test('속성 순서와 따옴표 종류는 결과를 바꾸지 않는다', () {
      final singleQuoted = parseDocsTag(
        "<LivePreview variants='a' component=\"card\" />",
      );
      final doubleQuoted = parseDocsTag(
        '<LivePreview component="card" variants="a" />',
      );

      expect(singleQuoted!.attributes, doubleQuoted!.attributes);
      expect(singleQuoted.attributes, {'component': 'card', 'variants': 'a'});
    });

    test('중첩된 같은 이름 태그의 짝을 맞춘다', () {
      final tags = findDocsTags('<Tabs>\n<Tabs>\n안\n</Tabs>\n</Tabs>');

      expect(tags, hasLength(1));
      expect(tags.single.tag.innerMarkdown, '<Tabs>\n안\n</Tabs>');
    });

    test('닫는 태그가 없으면 태그가 아니다', () {
      expect(findDocsTags('<Widget> 만 있고 닫는 태그가 없다'), isEmpty);
    });
  });

  group('docs_heading', () {
    test('h2/h3 만 담고 한글을 살리며 중복은 인덱스 접미사를 붙인다', () {
      final headings = extractDocsHeadings(
        '# H1\n## 개요\n### 하위\n#### H4\n## 개요\n',
      );

      expect(headings.map((heading) => heading.level), [2, 3, 2]);
      expect(headings.map((heading) => heading.text), ['개요', '하위', '개요']);
      expect(headings.map((heading) => heading.id), ['개요', '하위', '개요-2']);
    });

    test('실제 콘텐츠 전체에서 id 가 문서마다 유일하다', () {
      for (final file in _contentFiles()) {
        final headings = extractDocsHeadings(
          parseDocsPage(path: file.path, source: file.readAsStringSync()).body,
        );
        final ids = headings.map((heading) => heading.id).toList();
        expect(ids, ids.toSet().toList(), reason: file.path);
      }
    });
  });

  group('DocsMarkdown', () {
    testWidgets('콘텐츠 153개가 좁은 폭에서 예외 없이 렌더된다', (tester) async {
      tester.view.physicalSize = const Size(400, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final failures = <String>[];
      for (final file in _contentFiles()) {
        final page = parseDocsPage(
          path: file.path,
          source: file.readAsStringSync(),
        );
        await tester.pumpWidget(
          CoUIApp(
            home: Scaffold(
              child: SingleChildScrollView(
                child: DocsMarkdown(
                  markdown: page.body,
                  registry: _stubRegistry,
                ),
              ),
            ),
            theme: docsPreviewTheme(dark: false),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        final error = tester.takeException();
        if (error != null) failures.add('${file.path}: $error');
      }

      expect(failures, isEmpty);
    });

    testWidgets('블록 구성요소가 실제로 그려지고 링크 탭이 호스트까지 간다', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        CoUIApp(
          home: Scaffold(
            child: SingleChildScrollView(
              child: DocsMarkdown(
                markdown: '''
# Title

본문 **굵게** 와 `List<String>` 과 [링크](/components/card).

| A | B |
|---|---|
| 1 | 2 |

```dart
void main() {}
```

- 하나
- 둘

> 인용문

---

<Callout type="tip">
콜아웃 안
</Callout>
''',
                registry: DocsTagRegistry({
                  'Callout': (context, tag) =>
                      Text('CALLOUT:${tag.attribute('type')}'),
                }),
                onInternalLink: tapped.add,
              ),
            ),
          ),
          theme: docsPreviewTheme(dark: false),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Title', findRichText: true), findsOneWidget);
      // 엔티티 이스케이프(`List&lt;String&gt;`)가 새지 않는지 본다.
      expect(
        find.textContaining('List<String>', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('인용문', findRichText: true), findsOneWidget);
      expect(find.text('CALLOUT:tip'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(CodeSnippet), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 인라인 링크는 WidgetSpan 이 아니라 TextSpan + 인식기다 — 탭이 실제로
      // 호스트 콜백까지 도달하는지 본다. 범위 중앙(tapOnText 의 탐침점)이
      // 아니라 첫 글리프 안쪽(폭 1/4)을 탭한다 — 광학 트래킹의 음수
      // letter-spacing 으로 글리프 어드밴스가 소수가 되면 글리프 경계에
      // 서브픽셀 히트테스트 틈이 생기는데, 면적이 있는 실사용 탭과 달리
      // 단일 픽셀인 테스트 탭은 중앙점이 정확히 그 틈에 떨어질 수 있다.
      final richText = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('링크'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(richText);
      final start = paragraph.text.toPlainText().indexOf('링크');
      final linkBox = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + 2),
          )
          .first
          .toRect();
      await tester.tapAt(
        paragraph.localToGlobal(
          Offset(linkBox.left + linkBox.width / 4, linkBox.center.dy),
        ),
      );
      await tester.pump();
      expect(tapped, ['/components/card']);
    });

    testWidgets('모르는 태그는 조용히 건너뛴다', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          home: const Scaffold(
            child: DocsMarkdown(
              markdown: '앞\n\n<Mystery foo="bar" />\n\n뒤',
              registry: DocsTagRegistry.empty(),
            ),
          ),
          theme: docsPreviewTheme(dark: false),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('앞', findRichText: true), findsOneWidget);
      expect(find.textContaining('뒤', findRichText: true), findsOneWidget);
    });
  });
}
