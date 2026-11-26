/// `<Tabs>` + `<TabItem label="..." value="...">` 태그.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';

/// 탭 태그 이름 → 빌더. [nested] 는 탭 본문(마크다운)을 렌더한다.
///
/// `TabItem` 도 등록한다 — `Tabs` 밖에 홀로 남은 `<TabItem>` 이 통째로
/// 사라지지 않고 본문만이라도 그려지게 하는 저하 경로다. `Tabs` 안의
/// `TabItem` 은 여기 오지 않는다 (부모가 innerMarkdown 에서 직접 뽑는다).
Map<String, DocsTagBuilder> docsTabsTagBuilders({
  required Widget Function(String markdown) nested,
}) => {
  'Tabs': (context, tag) => _DocsTabs(
    items: parseDocsTabItems(tag.innerMarkdown ?? ''),
    nested: nested,
  ),
  'TabItem': (context, tag) => nested(tag.innerMarkdown ?? ''),
};

/// `<Tabs>` 안에서 뽑아낸 탭 하나.
class DocsTabItemData {
  /// 탭 하나를 만든다.
  const DocsTabItemData({required this.label, required this.body});

  /// 탭 버튼에 표시할 라벨.
  final String label;

  /// 탭의 마크다운 본문.
  final String body;
}

/// `<Tabs>` 의 본문에서 `<TabItem>` 들을 순서대로 뽑는다.
///
/// 자식을 여기서 직접 뽑는 이유: 렌더러는 `Tabs` 의 innerMarkdown 을 통째로
/// 넘기는데, 탭 바를 그리려면 자식들의 `label` 을 **미리** 알아야 한다 —
/// 자식을 위젯으로 받고 나면 라벨을 되찾을 수 없다.
///
/// 태그 스캔은 [findDocsTags] 를 그대로 쓴다 — 자체 정규식을 두면 코드 펜스
/// 인식과 속성 따옴표 규칙이 렌더러와 갈라진다 (탭 본문은 거의 전부 `dart`
/// 코드 펜스다).
///
/// 라벨은 `label` 속성이 없으면 `value` 를, 그것도 없으면 순번을 쓴다.
List<DocsTabItemData> parseDocsTabItems(String innerMarkdown) {
  final items = <DocsTabItemData>[];
  for (final match in findDocsTags(innerMarkdown)) {
    final tag = match.tag;
    if (tag.name != 'TabItem') continue;
    final label = tag.attribute('label') ?? tag.attribute('value');
    items.add(
      DocsTabItemData(
        label: label ?? 'Tab ${items.length + 1}',
        body: tag.innerMarkdown ?? '',
      ),
    );
  }
  return items;
}

/// 탭 바 + 선택된 탭의 본문.
///
/// `groupId` 는 의도적으로 무시한다 — jaspr 쪽은 그 값으로 페이지 안의
/// 모든 Tabs 선택을 동기화하지만(플랫폼 탭 하나 고르면 전부 따라감), 여기서
/// 같은 걸 하려면 페이지 수명의 공유 상태가 필요하다. 인스턴스마다 독립
/// 선택으로 두는 게 지금의 명시적 선택이며, 필요해지면 InheritedWidget 으로
/// 올린다.
class _DocsTabs extends StatefulWidget {
  const _DocsTabs({required this.items, required this.nested});

  final List<DocsTabItemData> items;
  final Widget Function(String markdown) nested;

  @override
  State<_DocsTabs> createState() => _DocsTabsState();
}

class _DocsTabsState extends State<_DocsTabs> {
  int _selectedIndex = 0;

  void handleChanged(int index) => setState(() => _selectedIndex = index);

  @override
  void didUpdateWidget(_DocsTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 콘텐츠가 바뀌어 탭이 줄면 선택 인덱스가 범위를 벗어난다.
    if (_selectedIndex >= widget.items.length) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final index = _selectedIndex.clamp(0, items.length - 1);
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Tabs(
          onChanged: handleChanged,
          tabs: [
            for (final item in items) CoreTabItem<Widget>(label: item.label),
          ],
          selectedIndex: index,
          variant: .underline,
        ),
        const Gap.space16(),
        widget.nested(items[index].body),
      ],
    );
  }
}
