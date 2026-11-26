import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// `<Cards>` · `<Steps>` · `<DesignNote>` · `<Code>` 가 네이티브 앱에서 실제로
/// 그려지는지 본다.
///
/// 옆의 태그 커버리지 검사는 "등록돼 있다" 까지만 말한다. 등록된 빌더가
/// 본문을 버리거나 카드의 링크를 잇지 않아도 그 검사는 통과한다 — 여기서는
/// 그려진 글자와 눌렀을 때 요청되는 경로를 읽는다.
void main() {
  Future<List<String>> pump(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 1600);
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

  testWidgets('카드 묶음의 이름표 · 제목 · 본문이 그려진다', (tester) async {
    await pump(tester, '''
<Cards columns="3">
  <Card eyebrow="01" title="하나의 토큰">

값을 한곳에서 정의합니다.

  </Card>
  <Card eyebrow="02" title="두 플랫폼, 같은 API">

같은 이름의 컴포넌트를 제공합니다.

  </Card>
</Cards>
''');

    expect(find.text('01'), findsOneWidget);
    expect(find.text('하나의 토큰'), findsOneWidget);
    expect(find.text('두 플랫폼, 같은 API'), findsOneWidget);
    expect(find.textContaining('값을 한곳에서 정의합니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('링크가 달린 카드를 누르면 그 경로를 요청한다', (tester) async {
    final navigated = await pump(tester, '''
<Cards>
  <Card title="빠른 시작" href="/getting-started" more="빠른 시작 보기">

설치부터 첫 컴포넌트까지.

  </Card>
</Cards>
''');

    await tester.tap(find.text('빠른 시작'));
    await tester.pump();

    expect(navigated, ['/getting-started']);
    expect(find.textContaining('빠른 시작 보기'), findsOneWidget);
  });

  testWidgets('단계는 순서대로 번호가 붙고 본문의 코드가 그려진다', (tester) async {
    await pump(tester, '''
<Steps>
  <Step title="패키지 추가">

`pubspec.yaml` 에 의존성을 추가합니다.

```yaml
dependencies:
  coui_flutter: any
```

  </Step>
  <Step title="앱 감싸기">

루트를 `CoUIApp` 으로 바꿉니다.

  </Step>
</Steps>
''');

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('패키지 추가'), findsOneWidget);
    expect(find.text('앱 감싸기'), findsOneWidget);
    expect(find.textContaining('coui_flutter: any'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('묶음 밖에 홀로 놓인 카드와 단계도 사라지지 않는다', (tester) async {
    await pump(tester, '''
<Card title="혼자인 카드">

본문.

</Card>

<Step title="혼자인 단계">

본문.

</Step>
''');

    expect(find.text('혼자인 카드'), findsOneWidget);
    expect(find.text('혼자인 단계'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('카드 묶음의 모양은 사이트와 같다 — 묶음이 정하고 카드가 덮는다', (tester) async {
    await pump(tester, '''
<Cards variant="outlined">
  <Card title="선 카드">

- 컴포넌트 이름 충돌

  </Card>
  <Card title="면 카드" variant="filled">

본문.

  </Card>
  <Card value="34" title="명세">

값을 정의합니다.

  </Card>
</Cards>
''');

    CoreCardVariant variantOf(String title) => tester
        .widget<Card>(
          find.ancestor(of: find.text(title), matching: find.byType(Card)),
        )
        .variant;

    expect(variantOf('선 카드'), CoreCardVariant.outlined);
    expect(variantOf('면 카드'), CoreCardVariant.filled);
    expect(variantOf('명세'), CoreCardVariant.outlined);
    // 숫자 카드 — 큰 숫자가 이름 위에 놓인다.
    expect(
      tester.getRect(find.text('34')).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('명세')).top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('따라 하기(`size="large"`)는 단계 사이가 짧은 절차보다 넉넉하다', (tester) async {
    Future<double> gap(String size) async {
      await pump(tester, '''
<Steps$size>
  <Step title="첫 단계">

본문.

  </Step>
  <Step title="둘째 단계">

본문.

  </Step>
</Steps>
''');
      final first = tester.getRect(find.text('1'));
      final second = tester.getRect(find.text('2'));
      return second.top - first.top;
    }

    final short = await gap('');
    final large = await gap(' size="large"');
    expect(large, greaterThan(short));
    expect(tester.takeException(), isNull);
  });

  testWidgets('노트는 제목과 본문을 그리고, 경고는 경고의 면이다', (tester) async {
    await pump(tester, '''
<DesignNote title="우회하면 조용히 깨집니다">
리터럴 색은 CSS 변수를 거치지 않습니다.
</DesignNote>

<DesignNote title="확인합니다" variant="warning">
경고 본문.
</DesignNote>
''');

    expect(find.text('우회하면 조용히 깨집니다'), findsOneWidget);
    expect(find.textContaining('리터럴 색은 CSS 변수를 거치지 않습니다.'), findsOneWidget);
    expect(find.text('확인합니다'), findsOneWidget);

    final theme = Theme.of(tester.element(find.text('확인합니다')));
    Color fillOf(String title) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text(title), matching: find.byType(DecoratedBox))
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    expect(
      fillOf('확인합니다'),
      theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.warningContainer))
          .toValue(),
    );
    expect(
      fillOf('우회하면 조용히 깨집니다'),
      theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.surfaceContainer))
          .toValue(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('코드 태그는 이름표와 코드를 그린다', (tester) async {
    await pump(tester, '''
<Code language="dart" title="버튼 하나만 바꾸기">
Button(child: Text('저장'))
</Code>
''');

    expect(find.text('버튼 하나만 바꾸기'), findsOneWidget);
    expect(find.textContaining("Button(child: Text('저장'))"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('머리줄이 빈 표는 이름 · 값 표다 — 빈 머리줄을 그리지 않는다', (tester) async {
    await pump(tester, '''
| | |
|---|---|
| 식별자 | coui-component-library |
| 고정 | main |
''');

    expect(tester.widget<Table>(find.byType(Table)).rows, hasLength(2));
    expect(find.text('식별자'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
