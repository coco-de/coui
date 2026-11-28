/// Disclosure 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="disclosure/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`disclosure_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'disclosure_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _disclosure;

/// 장면 이름(`disclosure/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'disclosure/related-collapsible': () => const Collapsible(
    trigger: Text('배송 안내'),
    content: Text('2~3일 걸려요.'),
    expanded: true,
  ),
  'disclosure/related-accordion': () => const Accordion(
    items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
  ),
};

Widget _disclosure(Map<String, String> props, String? label) => KeyedSubtree(
  key: ValueKey(page.disclosurePreviewKey(props)),
  child: _sized(_sample(open: previewFlag(props, 'open'), icon: previewFlag(props, 'icon'))),
);

Widget _sample({bool open = false, bool icon = false}) {
  final (title, content) = page.disclosureDemoItems.first;
  return Disclosure(
    title: icon ? null : title,
    trigger: icon
        ? Row(
            children: [
              const Icon(LucideIcons.info),
              const Gap.space8(),
              Text(title),
            ],
          )
        : null,
    content: Text(content),
    open: open,
  );
}

/// 두 플랫폼이 같은 폭에 그리도록 폭을 정한 상자.
Widget _sized(Widget child) => SizedBox(width: page.disclosureDemoWidth, child: child);

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
