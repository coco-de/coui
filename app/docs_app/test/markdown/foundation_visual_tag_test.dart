import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:docs_core/shared/foundation_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

/// `<FoundationVisual kind="…" />` 가 네이티브 앱에서 실제로 값을 그리는지 본다.
///
/// 사이트는 이 태그를 그림으로 그리고 앱은 같은 값을 표로 그린다. 태그
/// 커버리지 검사는 "등록돼 있다" 까지만 말하므로, 여기서는 그려진 글자가
/// `foundation_visuals.dart` 의 값과 같은지 읽는다.
void main() {
  Future<List<String>> pump(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final navigated = <String>[];
    final registry = buildDocsTagRegistry(onInternalLink: navigated.add);

    await tester.pumpWidget(
      CoUIApp(
        home: SingleChildScrollView(
          child: DocsMarkdown(
            markdown: markdown,
            registry: registry,
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

  for (final kind in FoundationVisualKind.values) {
    testWidgets('${kind.attribute} 는 빈자리 없이 그려진다', (tester) async {
      await pump(tester, '<FoundationVisual kind="${kind.attribute}" />');

      expect(find.byType(DocsMarkdown), findsWidgets);
      expect(find.byType(Text), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('개요 목록의 항목을 누르면 그 파운데이션 페이지를 요청한다', (tester) async {
    final navigated = await pump(tester, '<FoundationVisual kind="topics" />');

    expect(
      find.textContaining(kFoundationTopicDescriptions['/guides/colors']!),
      findsOneWidget,
    );
    await tester.tap(find.textContaining('색상').first);
    await tester.pump();

    expect(navigated, ['/guides/colors']);
  });

  testWidgets('색 사다리는 단계마다 코드의 hex 를 쓴다', (tester) async {
    await pump(tester, '<FoundationVisual kind="neutral" />');

    for (final MapEntry(key: step, value: color)
        in foundationNeutralSteps.entries) {
      expect(find.textContaining('$step'), findsWidgets);
      expect(find.textContaining(color.toHex().substring(1)), findsWidgets);
    }
  });

  testWidgets('지속 시간과 이징은 토큰의 값을 쓴다', (tester) async {
    await pump(tester, '''
<FoundationVisual kind="duration" />

<FoundationVisual kind="easing" />
''');

    for (final duration in kFoundationDurations) {
      expect(find.textContaining('${duration.milliseconds}ms'), findsOneWidget);
    }
    for (final easing in kFoundationEasings) {
      expect(
        find.textContaining(foundationCubicBezier(easing.curve)),
        findsOneWidget,
      );
    }
  });

  testWidgets('모르는 kind 는 아무것도 그리지 않는다', (tester) async {
    await pump(tester, '<FoundationVisual kind="unknown" />');

    expect(find.byType(Table), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
