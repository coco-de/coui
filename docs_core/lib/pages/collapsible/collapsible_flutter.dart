/// Collapsible 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="collapsible/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`collapsible_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'collapsible_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _collapsible;

/// 장면 이름(`collapsible/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'collapsible/anatomy': () => _sized(_sample(expanded: true)),
  'collapsible/states': () => _sized(
    _captionedStack([
      ('접힘', _sample()),
      ('펼침', _sample(expanded: true)),
    ]),
  ),
  'collapsible/trigger-slot': () => _sized(_sample(expanded: true, icon: true)),
  'collapsible/related-accordion': () => const Accordion(
    items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
  ),
  'collapsible/related-disclosure': () => const Disclosure(
    title: '배송 안내',
    content: Text('2~3일 걸려요.'),
    open: true,
  ),
};

Widget _collapsible(Map<String, String> props, String? label) => KeyedSubtree(
  key: ValueKey(page.collapsiblePreviewKey(props)),
  child: _sized(_sample(expanded: previewFlag(props, 'expanded'), icon: previewFlag(props, 'icon'))),
);

Widget _sample({bool expanded = false, bool icon = false}) => Collapsible(
  trigger: icon
      ? const Row(
          children: [
            Icon(LucideIcons.settings),
            Gap.space8(),
            Text(page.collapsibleDemoTrigger),
          ],
        )
      : const Text(page.collapsibleDemoTrigger),
  content: const Text(page.collapsibleDemoContent),
  expanded: expanded,
);

/// 두 플랫폼이 같은 폭에 그리도록 폭을 정한 상자.
Widget _sized(Widget child) => SizedBox(width: page.collapsibleDemoWidth, child: child);

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
