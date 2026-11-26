import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:docs_core/shared/block_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// `<BlockCatalogVisual kind>` 가 네이티브 앱에서 블록 카탈로그의 값을 그리는지
/// 본다.
///
/// 태그 커버리지 검사는 "등록돼 있다" 까지만 말한다. 빌더가 종류를 잘못 읽거나
/// 카드의 경로를 잇지 않아도 그 검사는 통과한다 — 여기서는 그려진 글자와
/// 눌렀을 때 요청되는 경로를 읽는다. 값은 사이트와 같은 목록(`kDocsBlocks` ·
/// `kDocsFooterStructure`)에서 기대값을 만든다.
void main() {
  Future<List<String>> pump(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final navigated = <String>[];
    await tester.pumpWidget(
      CoUIApp(
        home: SingleChildScrollView(
          child: DocsMarkdown(
            markdown: markdown,
            registry: buildDocsTagRegistry(onInternalLink: navigated.add),
            onInternalLink: navigated.add,
          ),
        ),
        scaling: .desktop,
        theme: ThemeData.fromCore(CoreThemePresets.previewLight),
      ),
    );
    await tester.pumpAndSettle();

    return navigated;
  }

  testWidgets('catalog 은 블록마다 이름 · 설명 · Layout 이름표를 그리고 누르면 그 블록으로 간다', (
    tester,
  ) async {
    final navigated = await pump(
      tester,
      '<BlockCatalogVisual kind="catalog" />',
    );

    for (final block in kDocsBlocks) {
      expect(find.text(block.name), findsOneWidget, reason: block.slug);
      expect(find.text(block.description), findsOneWidget, reason: block.slug);
    }
    // 카드의 이름표는 사이트와 같은 `Layout=<값>` 이다. 같은 값을 둘 이상의
    // 블록이 가지면(center) 그 수만큼 그려진다.
    final labels = [
      for (final block in kDocsBlocks)
        for (final layout in block.layouts) 'Layout=$layout',
    ];
    for (final label in labels.toSet()) {
      expect(
        find.text(label),
        findsNWidgets(labels.where((other) => other == label).length),
        reason: label,
      );
    }

    await tester.tap(find.text(kDocsBlocks.last.name));
    await tester.pump();
    expect(navigated, [kDocsBlocks.last.path]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero-layouts · footer-layouts 는 그 블록의 Layout 이름표만 그린다', (
    tester,
  ) async {
    final hero = kDocsBlocks.firstWhere((block) => block.slug == 'hero');
    final footer = kDocsBlocks.firstWhere((block) => block.slug == 'footer');

    await pump(tester, '<BlockCatalogVisual kind="hero-layouts" />');
    for (final layout in hero.layouts) {
      expect(
        find.text(hero.layoutLabel(layout)),
        findsOneWidget,
        reason: layout,
      );
    }
    expect(find.text(footer.layoutLabel(footer.layouts.first)), findsNothing);

    await pump(tester, '<BlockCatalogVisual kind="footer-layouts" />');
    for (final layout in footer.layouts) {
      expect(
        find.text(footer.layoutLabel(layout)),
        findsOneWidget,
        reason: layout,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('footer-structure 는 범례에 번호와 슬롯을 그린다', (tester) async {
    await pump(tester, '<BlockCatalogVisual kind="footer-structure" />');

    for (final (index, part) in kDocsFooterStructure.indexed) {
      expect(
        find.text('${index + 1} ${part.label}'),
        findsOneWidget,
        reason: part.label,
      );
      expect(find.text(part.slots), findsOneWidget, reason: part.label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('모르는 kind 는 아무것도 그리지 않는다', (tester) async {
    await pump(tester, '앞\n\n<BlockCatalogVisual kind="nope" />\n\n뒤');

    expect(find.textContaining('앞'), findsOneWidget);
    expect(find.textContaining('뒤'), findsOneWidget);
    expect(find.text(kDocsBlocks.first.name), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
