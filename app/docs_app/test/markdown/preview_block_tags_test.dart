import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// `<Preview>` · `<VariantRow>` · `<SizeSpec>` · 미리보기를 단 `<Card>` 가
/// 네이티브 앱에서 실제 컴포넌트를 그리는지 본다.
///
/// 태그 커버리지 검사는 "등록돼 있다" 까지만 말한다. 빌더가 속성을 읽지
/// 않고 기본 버튼만 그려도 그 검사는 통과한다 — 여기서는 속성이 위젯까지
/// 닿았는지(variant · size · 라벨)를 읽는다.
void main() {
  Future<void> pump(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final registry = buildDocsTagRegistry(onInternalLink: (_) {});
    await tester.pumpWidget(
      CoUIApp(
        home: SingleChildScrollView(
          child: DocsMarkdown(
            markdown: markdown,
            registry: registry,
            onInternalLink: (_) {},
          ),
        ),
        scaling: .desktop,
        theme: ThemeData.fromCore(CoreThemePresets.previewLight),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Variant 행은 속성대로 그린 버튼과 이름 · 설명을 그린다', (tester) async {
    await pump(tester, '''
<VariantRow name="outline" component="button" props="variant=outline;size=lg" label="취소">

중립적인 행동에 씁니다.

</VariantRow>
''');

    final button = tester.widget<Button>(find.byType(Button));
    expect(button.variant, CoreButtonVariant.outline);
    expect(button.size, CoreComponentSize.lg);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('outline'), findsOneWidget);
    expect(find.textContaining('중립적인 행동에 씁니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('크기 표는 크기마다 버튼 하나와 표의 행을 그린다', (tester) async {
    await pump(tester, '<SizeSpec component="button" label="버튼" />\n');

    final sizes = [
      for (final b in tester.widgetList<Button>(find.byType(Button))) b.size,
    ];
    expect(sizes, CoreComponentSize.values);
    expect(find.text('64 · 28'), findsOneWidget);
    expect(find.text('12 Medium · 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('미리보기를 단 카드와 입력창 미리보기', (tester) async {
    await pump(tester, '''
<Cards columns="2">
<Card component="button" props="shape=square;variant=outline" title="square">

아이콘만 있는 버튼입니다.

</Card>
</Cards>

<Preview component="text-field" props="label=이메일;placeholder=이메일을 입력하세요;variant=filled" />
''');

    expect(
      tester.widget<Button>(find.byType(Button)).shape,
      CoreButtonShape.square,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.variant, CoreTextFieldVariant.filled);
    expect(field.label, '이메일');
    expect(find.text('square'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
