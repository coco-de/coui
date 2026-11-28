/// Disclosure 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="disclosure/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`disclosure_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'disclosure_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _disclosure;

/// 장면 이름(`disclosure/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'disclosure/anatomy': () => _sized(_sample(open: true)),
  'disclosure/states': () => _sized(
    _captionedStack([
      ('닫힘', _sample()),
      ('열림', _sample(open: true)),
    ]),
  ),
  'disclosure/group': () => _sized(
    DisclosureGroup(
      items: [
        for (final (index, (title, content)) in page.disclosureDemoItems.indexed)
          Disclosure(title: title, content: Text(content), open: index == 0),
      ],
    ),
  ),
  'disclosure/related-collapsible': () => Collapsible(
    trigger: Text('배송 안내'),
    content: Text('2~3일 걸려요.'),
    expanded: true,
  ),
  'disclosure/related-accordion': () => Accordion(
    items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
  ),
};

Component _disclosure(Map<String, String> props, String? label) => div(
  key: ValueKey(page.disclosurePreviewKey(props)),
  styles: _widthStyles,
  [_sample(open: previewFlag(props, 'open'), icon: previewFlag(props, 'icon'))],
);

Component _sample({bool open = false, bool icon = false}) {
  final (title, content) = page.disclosureDemoItems.first;
  return Disclosure(
    title: icon ? null : title,
    trigger: icon
        ? div(classes: 'flex items-center', [
            Icon(LucideIcons.info),
            const Gap.space8(),
            Text(title),
          ])
        : null,
    content: Text(content),
    open: open,
    classes: 'w-full',
  );
}

Styles get _widthStyles => Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(page.disclosureDemoWidth)})'});

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
