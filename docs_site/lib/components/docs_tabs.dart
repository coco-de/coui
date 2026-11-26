/// 본문의 탭 — 플랫폼마다 다른 코드를 한 자리에 둔다.
///
/// ```md
/// <Tabs groupId="platform">
///   <TabItem label="Flutter" value="flutter">
///
/// 본문 — 문단, 코드 펜스, 표가 그대로 들어간다.
///
///   </TabItem>
///   <TabItem label="Web" value="web">
///
/// …
///
///   </TabItem>
/// </Tabs>
/// ```
///
/// 같은 태그를 네이티브 문서 앱(`app/docs_app`)도 그린다.
///
/// ## 서버가 탭을 다 그린다
///
/// 탭 막대 · 선택된 탭 · 보이는 패널이 전부 서버가 낸 마크업에 있다 —
/// `role="tablist"` · `role="tab"` 의 `aria-selected` · `role="tabpanel"` 의
/// `hidden`. 본문은 브라우저에서 깨어나지 않으므로 탭을 바꾸는 일은 정적
/// 스크립트(`web/docs-shell.js`)가 그 속성을 고쳐서 한다. 스크립트가 없는
/// 문서에서는 모든 패널이 자기 이름표를 달고 이어서 보인다
/// (`web/docs-shell.css` 의 `scripting: none`).
///
/// ## 패널의 이름은 탭의 이름이다
///
/// 패널은 `aria-label` 로 자기 탭의 이름을 갖는다. 탭을 `id` 로 가리키는
/// `aria-labelledby` 와 같은 이름이 계산되고, 페이지 안에서 겹치지 않는
/// `id` 를 서버가 지어낼 필요가 없다.
///
/// ## 같은 `groupId` 의 묶음은 함께 바뀐다
///
/// `groupId` 는 `data-group` 으로 나간다. 한 묶음에서 탭을 고르면 스크립트가
/// 같은 `data-group` 의 다른 묶음도 같은 `value` 의 탭으로 옮기고, 그 선택을
/// 다음 페이지로 가져간다. 그래서 `<TabItem>` 에는 `value` 를 적는다 —
/// 묶음끼리 맞출 이름이 그것이다.
///
/// ## 글자는 킷이, 상자는 시트가
///
/// 탭의 글자는 킷의 `Text` 역할이고, 밑줄 · 간격 · 색은
/// `web/docs-shell.css` 가 킷의 변수로 그린다. 킷의 `Tabs` 는 선택된 탭의
/// 모양을 다시 그려서 바꾸므로, 깨어나지 않는 본문에서는 쓸 수 없다.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// 탭 묶음을 표시하는 속성 — 정적 스크립트가 이것으로 묶음을 찾는다.
const String kDocsTabsAttribute = 'data-docs-tabs';

/// 함께 바뀌는 묶음의 이름을 싣는 속성 (`<Tabs groupId>`).
const String kDocsTabsGroupAttribute = 'data-group';

/// 탭과 패널을 짝짓는 값을 싣는 속성 (`<TabItem value>`).
const String kDocsTabValueAttribute = 'data-value';

/// 탭 하나 — 이름, 묶음끼리 맞추는 값, 패널의 내용.
typedef _TabItem = ({String label, String value, Component child});

/// `<Tabs>` · `<TabItem>`.
class DocsTabs extends CustomComponent {
  /// 탭 컴포넌트를 만든다.
  DocsTabs() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node is! ElementNode) return null;

    return switch (node.tag) {
      'Tabs' => _tabs(node, builder),
      // 묶음 밖에 홀로 놓인 것 — 사라지지 않고 탭 하나짜리 묶음으로 그려진다.
      'TabItem' => _group([_item(node, builder)]),
      _ => null,
    };
  }

  Component _tabs(ElementNode node, NodesBuilder builder) {
    final items = [
      for (final child in node.children ?? const <Node>[])
        if (child is ElementNode && child.tag == 'TabItem') _item(child, builder),
    ];
    // 탭이 하나도 없는 묶음 — 안에 적힌 것을 그대로 둔다.
    if (items.isEmpty) return builder.build(node.children);

    return _group(
      items,
      selected: _attribute(node, 'defaultValue'),
      group: _attribute(node, 'groupId'),
      label: _attribute(node, 'label'),
    );
  }

  _TabItem _item(ElementNode node, NodesBuilder builder) => (
    label: _attribute(node, 'label') ?? '',
    value: _attribute(node, 'value') ?? '',
    child: builder.build(node.children),
  );

  /// [name] 속성의 값.
  ///
  /// 마크다운 파서는 태그 이름의 대소문자는 지키고 **속성 이름은 소문자로**
  /// 넘긴다 — 콘텐츠의 `groupId` 는 `groupid` 로 온다. 적힌 그대로의 이름만
  /// 찾으면 대문자가 든 속성은 에러 없이 읽히지 않는다.
  String? _attribute(ElementNode node, String name) => node.attributes[name] ?? node.attributes[name.toLowerCase()];

  /// [selected] 는 처음 보이는 탭의 값 — 없거나 어느 탭의 것도 아니면 첫 탭.
  Component _group(List<_TabItem> items, {String? selected, String? group, String? label}) {
    final initial = items.any((item) => item.value == selected) ? selected : items.first.value;
    // 값이 겹친 탭(값을 적지 않은 것들)은 앞의 하나만 고른다 — 두 탭이 함께
    // 선택된 탭 막대는 없다.
    final chosen = items.indexWhere((item) => item.value == initial);

    return div(
      classes: 'docs-tabs',
      attributes: {
        kDocsTabsAttribute: '',
        kDocsTabsGroupAttribute: ?group,
      },
      [
        div(
          // `not-content`: 본문의 산문 규칙이 탭 막대를 다시 꾸미지 않는다.
          classes: 'docs-tabs-list not-content',
          attributes: {
            'role': 'tablist',
            'aria-label': ?label,
          },
          [
            for (final (index, item) in items.indexed)
              Component.element(
                tag: 'button',
                classes: 'docs-tab',
                attributes: {
                  'type': 'button',
                  'role': 'tab',
                  'aria-selected': index == chosen ? 'true' : 'false',
                  // 탭 막대는 탭 정지점 하나다 — 선택된 탭. 나머지는
                  // 화살표로 닿는다.
                  'tabindex': index == chosen ? '0' : '-1',
                  kDocsTabValueAttribute: item.value,
                },
                children: [Text(item.label).labelLarge],
              ),
          ],
        ),
        for (final (index, item) in items.indexed)
          div(
            classes: 'docs-tab-panel',
            attributes: {
              'role': 'tabpanel',
              'aria-label': item.label,
              kDocsTabValueAttribute: item.value,
              if (index != chosen) 'hidden': '',
            },
            [item.child],
          ),
      ],
    );
  }
}
