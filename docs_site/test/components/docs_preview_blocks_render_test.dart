@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_site/components/docs_blocks.dart';
import 'package:docs_site/components/docs_preview_blocks.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';

/// 컴포넌트 페이지(v2 템플릿)의 미리보기 블록이 **서버 렌더에서** 무엇을
/// 내는지 본다.
///
/// 블록의 미리보기는 속성 문자열로 고른다. 속성을 읽지 않고 기본 버튼만
/// 그려도 페이지는 에러 없이 그려지므로, 여기서는 속성이 마크업까지
/// 닿았는지(라벨 · 아이콘만 있는 모양 · 크기마다의 행)를 읽는다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  Component render(List<Node> nodes) => CoUIWeb(
    theme: ThemeData.coui,
    child: NodesBuilder([DocsBlocks(), DocsPreviewBlocks()]).build(nodes),
  );

  testServer('Variant 행 — 무대의 버튼 라벨, 이름, 설명', (tester) async {
    tester.pumpComponent(
      render([
        ElementNode(
          'VariantRow',
          const {'name': 'outline', 'component': 'button', 'props': 'variant=outline', 'label': '취소'},
          [
            ElementNode('p', const {}, [TextNode('중립적인 행동에 씁니다.')]),
          ],
        ),
      ]),
    );
    final document = (await tester.request('/')).document!;

    final row = document.querySelector('.docs-variant-row')!;
    expect(row.querySelector('.docs-stage')!.text, contains('취소'));
    expect(row.querySelector('.docs-variant-name')!.text, 'outline');
    expect(row.querySelector('.docs-variant-body')!.text, contains('중립적인 행동에 씁니다.'));
  });

  testServer('크기 표 — 크기마다 무대의 칸과 표의 행, 숫자는 Core 크기 행', (tester) async {
    tester.pumpComponent(
      render([
        ElementNode('SizeSpec', const {'component': 'button', 'label': '버튼'}, const []),
      ]),
    );
    final document = (await tester.request('/')).document!;

    final spec = document.querySelector('.docs-size-spec')!;
    expect(spec.querySelectorAll('.docs-size-item'), hasLength(6));
    final cells = [
      for (final row in spec.querySelectorAll('tbody tr'))
        row.querySelectorAll('td').map((td) => td.text.trim()).toList(),
    ];
    expect(cells.first, ['xs', '24 · 8', '12', '12 Medium · 6']);
    expect(cells.last, ['xl2', '64 · 28', '24', '16 Medium · 16']);
  });

  testServer('모르는 컴포넌트의 크기 표는 아무것도 그리지 않는다', (tester) async {
    tester.pumpComponent(
      render([
        ElementNode('SizeSpec', const {'component': 'avatar'}, const []),
      ]),
    );
    final document = (await tester.request('/')).document!;
    expect(document.querySelector('.docs-size-spec'), isNull);
  });

  testServer('미리보기를 단 카드 — 무대가 위에, 권장 · 금지 색은 그대로', (tester) async {
    tester.pumpComponent(
      render([
        ElementNode(
          'Cards',
          const {'columns': '2'},
          [
            ElementNode(
              'Card',
              const {
                'component': 'button',
                'props': 'variant=primary',
                'label': '저장하기',
                'tone': 'do',
                'eyebrow': '이렇게 하세요',
              },
              [
                ElementNode('p', const {}, [TextNode('한 영역에는 primary를 하나만 둡니다.')]),
              ],
            ),
            ElementNode(
              'Card',
              const {'title': '글만 있는 카드'},
              [
                ElementNode('p', const {}, [TextNode('본문')]),
              ],
            ),
          ],
        ),
      ]),
    );
    final document = (await tester.request('/')).document!;

    final cards = document.querySelectorAll('.docs-card');
    expect(cards.first.classes, containsAll(['docs-card--preview', 'docs-card--do']));
    expect(cards.first.children.first.classes, contains('docs-stage'));
    expect(cards.first.querySelector('.docs-stage')!.text, contains('저장하기'));
    // 미리보기가 없는 카드는 지금까지의 모양 그대로다.
    expect(cards.last.classes, isNot(contains('docs-card--preview')));
    expect(cards.last.querySelector('.docs-stage'), isNull);
  });
}
