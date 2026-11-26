import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_document.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/inline_renderer.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:docs_core/internal/preview/flutter_card_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

List<DocsTag> _sourceCards() {
  final cards = <DocsTag>[];

  void visit(String source) {
    for (final match in findDocsTags(source)) {
      final tag = match.tag;
      if (tag.name == 'Card' &&
          (tag.attributes.containsKey('component') ||
              tag.attributes.containsKey('demo'))) {
        cards.add(tag);
      }
      if (tag.innerMarkdown != null) visit(tag.innerMarkdown!);
    }
  }

  final files = Directory(
    '../../docs_core/content/components',
  ).listSync().whereType<File>().where((file) => file.path.endsWith('.md'));
  for (final file in files) {
    visit(file.readAsStringSync());
  }
  return cards;
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      scaling: .desktop,
      home: SingleChildScrollView(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every current Card keeps its actual Native paragraph body', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final cards = _sourceCards();
    expect(cards, isNotEmpty);

    for (final card in cards) {
      final rawBody = card.innerMarkdown ?? '';
      final parsed = parseDocsMarkdownNodes(rawBody.trim());
      expect(
        parsed.every((node) => node is md.Element && node.tag == 'p'),
        isTrue,
        reason: '${card.attributes}',
      );
      await _pump(
        tester,
        buildFlutterDocsCardScene(card.attributes, rawBody),
      );
      expect(tester.takeException(), isNull, reason: '${card.attributes}');
      expect(find.byType(FlutterDocsCardView), findsOneWidget);
      expect(
        tester.getSize(find.byType(FlutterDocsCardsLayout)).width,
        800,
      );

      final rendered = tester.widgetList<DocsRichText>(
        find.byType(DocsRichText),
      );
      expect(
        rendered.map((widget) => widget.nodes.map((n) => n.textContent).join()),
        parsed.map((node) => node.textContent),
        reason: '${card.attributes}',
      );
    }
  });

  testWidgets('the app Card delegate retains the real route callback', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final links = <String>[];
    final registry = buildDocsTagRegistry(onInternalLink: links.add);
    await _pump(
      tester,
      DocsMarkdown(
        markdown: '''
<Card title="Shared route" href="/components/card" more="Read">

The **original** paragraph and `inline` renderer stay active.

</Card>
''',
        registry: registry,
        onInternalLink: links.add,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterDocsCardsLayout), findsOneWidget);
    expect(find.byType(DocsRichText), findsOneWidget);
    await tester.tap(find.text('Shared route'));
    await tester.pump();
    expect(links, ['/components/card']);
  });

  testWidgets('unsupported Card body blocks fail explicitly', (tester) async {
    addTearDown(tester.view.reset);
    for (final source in ['# A heading', '- A list item']) {
      await _pump(
        tester,
        buildFlutterDocsCardScene(const {'title': 'Unsupported'}, source),
      );
      expect(tester.takeException(), isA<UnsupportedError>());
    }
  });
}
