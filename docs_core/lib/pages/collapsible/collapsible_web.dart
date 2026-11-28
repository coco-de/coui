/// Collapsible 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="collapsible/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`collapsible_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'collapsible_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _collapsible;

/// 장면 이름(`collapsible/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'collapsible/anatomy': () => _sized(_sample(expanded: true)),
  'collapsible/states': () => _sized(
    _captionedStack([
      ('접힘', _sample()),
      ('펼침', _sample(expanded: true)),
    ]),
  ),
  'collapsible/trigger-slot': () => _sized(_sample(expanded: true, icon: true)),
  'collapsible/related-accordion': () => Accordion(
    items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
  ),
  'collapsible/related-disclosure': () => Disclosure(
    title: '배송 안내',
    content: Text('2~3일 걸려요.'),
    open: true,
  ),
};

Component _collapsible(Map<String, String> props, String? label) => div(
  key: ValueKey(page.collapsiblePreviewKey(props)),
  styles: _widthStyles,
  [_sample(expanded: previewFlag(props, 'expanded'), icon: previewFlag(props, 'icon'))],
);

Component _sample({bool expanded = false, bool icon = false}) => Collapsible(
  trigger: icon
      ? div(classes: 'flex items-center', [
          Icon(LucideIcons.settings),
          const Gap.space8(),
          const Text(page.collapsibleDemoTrigger),
        ])
      : const Text(page.collapsibleDemoTrigger),
  content: const Text(page.collapsibleDemoContent),
  expanded: expanded,
  // Web 의 루트는 내용만큼만 차지한다 — 두 플랫폼의 폭을 맞춘다.
  classes: 'w-full',
);

Styles get _widthStyles => Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(page.collapsibleDemoWidth)})'});

/// 두 플랫폼이 같은 폭에 그리도록 폭을 정한 상자.
Component _sized(Component child) => div(styles: _widthStyles, [child]);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Component _captionedStack(List<(String, Component)> entries) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space24)},
  ),
  [
    for (final (caption, child) in entries)
      div(
        styles: Styles(
          raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8)},
        ),
        [Text(caption).labelSmall.onSurfaceVariant, child],
      ),
  ],
);
