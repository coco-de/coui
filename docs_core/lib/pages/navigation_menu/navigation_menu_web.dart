/// NavigationMenu 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-menu/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`navigation_menu_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// 닫힌 바는 실제 `NavigationMenu` 다. 열린 모습은 그림이다 — `NavigationMenu`
/// 의 패널은 열리면 오버레이 호스트의 메뉴 층에 올라가고, 패널을 그 자리에
/// 그리는 공개 경로가 없다. 그래서 그림은 `NavigationMenu` 가 쓰는
/// `resolveNavigationMenu` 의 값으로 항목을 `Button(variant: menubar)` 로,
/// 패널을 `Popup` 모양의 상자로 그리고, 위치만 flex 상자로 잡는다. 화면
/// 가장자리 처리 · 여닫는 전환 · 항목 사이의 이동은 그림에 없다. 실제 패널은
/// 플레이그라운드의 아래 바가 연다. 그 바에는 [kDocsLiveComponentAttribute] 를
/// 달아 야간 진동 프로브가 그림과 구분해 찾는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_panel_id.dart';
import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'navigation_menu_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _navigationMenu;

/// 장면 이름(`navigation-menu/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'navigation-menu/anatomy': () =>
      _anatomyInset(_OpenPicture(items: page.demoBasicItems, openIndex: 0, content: _richBody(), marked: true)),
  'navigation-menu/kinds': () => NavigationMenu(items: _items(page.demoKindItems)),
  'navigation-menu/do-short': () => NavigationMenu(items: _items(page.demoBasicItems)),
  'navigation-menu/placement': () =>
      _OpenPicture(items: page.demoBasicItems, openIndex: 1, content: _body(page.demoSolutionsBody)),
};

/// 구조 장면의 위 여백 — 맨 위 부품에 붙는 번호가 무대 윗선에 걸치지 않게 한다.
Component _anatomyInset(Component picture) => div(
  styles: Styles(raw: {'padding-top': spaceCss(CoreSpace.space12)}),
  [picture],
);

Component _navigationMenu(Map<String, String> props, String? label) {
  final picture = _propPicture(props);
  if (!previewFlag(props, 'opener')) return picture;
  return _withOpener(props, picture);
}

/// 속성으로 고른 열린 모습의 그림 — 첫 항목이 열려 있다.
Component _propPicture(Map<String, String> props) => _OpenPicture(
  items: page.demoItemsOf(props),
  openIndex: 0,
  content: _body(page.demoProductsBody),
  style: page.demoStyleOf(props),
);

/// 플레이그라운드의 미리보기 — 그림 아래에 같은 속성의 실제 `NavigationMenu` 를
/// 둔다. 포인터를 올리거나 누르면 패널이 열린다.
Component _withOpener(Map<String, String> props, Component picture) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space48),
      'width': '100%',
    },
  ),
  [
    picture,
    NavigationMenu(
      items: _items(page.demoItemsOf(props)),
      navigationMenuStyle: page.demoStyleOf(props),
      attributes: const {kDocsLiveComponentAttribute: 'navigation-menu'},
    ),
  ],
);

List<CoreNavigationMenuItem<Component>> _items(List<page.DemoMenuItem> items) => [
  for (final item in items) _item(item),
];

CoreNavigationMenuItem<Component> _item(page.DemoMenuItem item) {
  final body = item.body;
  return CoreNavigationMenuItem<Component>(
    label: item.label,
    content: body == null ? null : _body(body),
    href: item.href,
    onTap: body == null ? () {} : null,
  );
}

Component _body(String text) => Text(text).bodyMedium;

/// 제목과 설명을 여러 줄 담은 패널 글.
Component _richBody() => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8)}),
  [
    for (final (title, description) in page.demoRichEntries) ...[
      Text(title).titleSmall,
      Text(description).bodySmall.onSurfaceVariant,
    ],
  ],
);

/// 열린 모습의 그림 — [openIndex] 항목이 열린 바와, 그 항목의 왼쪽 가장자리에
/// 맞춘 패널. [marked] 이면 부분마다 `data-docs-part` 를 달아 구조 블록이 번호를
/// 붙인다.
class _OpenPicture extends StatelessComponent {
  const _OpenPicture({
    required this.items,
    required this.openIndex,
    required this.content,
    this.style,
    this.marked = false,
  });

  final List<page.DemoMenuItem> items;
  final int openIndex;
  final Component content;
  final CoreNavigationMenuStyle? style;
  final bool marked;

  Map<String, String>? _part(String name) => marked ? {'data-docs-part': name} : null;

  @override
  Component build(BuildContext context) {
    const variant = CoreNavigationMenuVariant.standard;
    final resolved = resolveNavigationMenu(
      context,
      variant: variant,
      triggers: [
        for (var i = 0; i < items.length; i++)
          NavigationMenuTriggerState(
            highlighted: i == openIndex,
            open: i == openIndex,
            hasContent: items[i].body != null,
          ),
      ],
      navigationMenuStyle: style,
    );
    final gap = resolveNavigationMenuConfig(context, variant: variant, navigationMenuStyle: style).gap;
    final panel = div(
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
      attributes: _part('panel'),
      [
        div(attributes: _part('content'), [content]),
      ],
    );
    return div(
      styles: Styles(
        raw: {
          'display': 'inline-flex',
          'flex-direction': 'column',
          'align-items': 'flex-start',
          'gap': pinnedLengthCss(gap),
        },
      ),
      [
        div(
          classes: resolved.root.className,
          styles: resolved.root.inlineStyles,
          attributes: _part('bar'),
          [for (var i = 0; i < items.length; i++) _trigger(resolved, i, named: i == openIndex)],
        ),
        if (openIndex == 0)
          panel
        else
          // 열린 항목보다 앞의 항목을 보이지 않게 다시 놓아, 패널의 왼쪽을 열린
          // 항목의 왼쪽에 맞춘다.
          div(classes: resolved.root.className, styles: resolved.root.inlineStyles, [
            for (var i = 0; i < openIndex; i++)
              div(
                attributes: const {'aria-hidden': 'true'},
                styles: const Styles(raw: {'visibility': 'hidden'}),
                [_trigger(resolved, i)],
              ),
            panel,
          ]),
      ],
    );
  }

  /// 항목 하나 — `NavigationMenu` 의 항목과 같은 `Button` 과 화살표.
  Component _trigger(ResolvedNavigationMenu resolved, int index, {bool named = false}) {
    final chevron = resolved.triggers[index].chevron;
    return Button(
      variant: CoreButtonVariant.menubar,
      classes: 'whitespace-nowrap',
      buttonStyle: resolved.triggers[index].buttonStyle,
      attributes: named ? _part('trigger') : null,
      trailing: chevron == null
          ? null
          : span(
              classes: chevron.className,
              styles: chevron.inlineStyles,
              attributes: named ? _part('chevron') : null,
              [Icon(LucideIcons.chevronDown, iconStyle: resolved.chevronIconStyle)],
            ),
      onPressed: () {},
      child: Text(items[index].label),
    );
  }
}
