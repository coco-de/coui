/// Accordion 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="accordion/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`accordion_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'accordion_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _accordion;

/// 장면 이름(`accordion/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'accordion/anatomy': () => _sized(_sample(expanded: const {0})),
  'accordion/states': () => _sized(
    _captionedStack([
      ('접힘', _single(expanded: false)),
      ('펼침', _single(expanded: true)),
    ]),
  ),
  'accordion/allow-multiple': () => _sized(_sample(allowMultiple: true, expanded: const {0, 1})),
  'accordion/related-collapsible': () => const Collapsible(
    trigger: Text('배송 안내'),
    content: Text('2~3일 걸려요.'),
    expanded: true,
  ),
  'accordion/related-disclosure': () => const Disclosure(
    title: '배송 안내',
    content: Text('2~3일 걸려요.'),
    open: true,
  ),
  'accordion/related-tabs': () => Tabs(
    tabs: const [
      CoreTabItem(label: '설명'),
      CoreTabItem(label: '후기'),
    ],
    selectedIndex: 0,
    onChanged: (_) {},
  ),
};

Widget _accordion(Map<String, String> props, String? label) {
  final expanded = page.accordionPreviewExpanded(props);
  return KeyedSubtree(
    key: ValueKey(page.accordionPreviewKey(props)),
    child: _sized(
      _sample(
        allowMultiple: previewFlag(props, 'allowMultiple'),
        expanded: {?expanded},
      ),
    ),
  );
}

/// 항목 셋짜리 Accordion — [expanded] 위치의 항목은 펼친 채로 만든다.
Widget _sample({bool allowMultiple = false, Set<int> expanded = const {}}) => Accordion(
  allowMultiple: allowMultiple,
  items: [
    for (final (index, (title, content)) in page.accordionDemoItems.indexed)
      AccordionItem(title: title, content: Text(content), expanded: expanded.contains(index)),
  ],
);

/// 항목 하나짜리 Accordion.
Widget _single({required bool expanded}) {
  final (title, content) = page.accordionDemoItems.first;
  return Accordion(
    items: [AccordionItem(title: title, content: Text(content), expanded: expanded)],
  );
}

/// 두 플랫폼이 같은 폭에 그리도록 폭을 정한 상자.
Widget _sized(Widget child) => SizedBox(width: page.accordionDemoWidth, child: child);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Widget _captionedStack(List<(String, Widget)> entries) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: CoreSpace.space24,
  children: [
    for (final (caption, child) in entries)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CoreSpace.space8,
        children: [Text(caption).labelSmall.onSurfaceVariant, child],
      ),
  ],
);
