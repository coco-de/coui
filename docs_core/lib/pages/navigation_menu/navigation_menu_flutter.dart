/// NavigationMenu 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-menu/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`navigation_menu_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 닫힌 바는 실제 `NavigationMenu` 다. 열린 모습은 그림이다 — `NavigationMenu`
/// 의 패널은 열리면 루트 `Overlay` 에 올라가고, 패널을 그 자리에 그리는 공개
/// 경로가 없다. 그래서 그림은 `NavigationMenu` 가 쓰는 `resolveNavigationMenu`
/// 의 값으로 항목을 `Button(variant: menubar)` 로, 패널을 같은 `Popup` 으로
/// 그리고, 위치만 `Column` · `Row` 로 잡는다. 화면 가장자리 처리 · 여닫는 전환 ·
/// 항목 사이의 이동은 그림에 없다. 실제 패널은 플레이그라운드의 아래 바가 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'navigation_menu_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _navigationMenu;

/// 장면 이름(`navigation-menu/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'navigation-menu/anatomy': () => _fit(_OpenPicture(items: page.demoBasicItems, openIndex: 0, content: _richBody())),
  'navigation-menu/kinds': () => _fit(NavigationMenu(items: _items(page.demoKindItems))),
  'navigation-menu/do-short': () => _fit(NavigationMenu(items: _items(page.demoBasicItems))),
  'navigation-menu/placement': () =>
      _fit(_OpenPicture(items: page.demoBasicItems, openIndex: 1, content: _body(page.demoSolutionsBody))),
};

Widget _navigationMenu(Map<String, String> props, String? label) {
  final picture = _propPicture(props);
  if (!previewFlag(props, 'opener')) return picture;
  return _withOpener(props, picture);
}

/// 속성으로 고른 열린 모습의 그림 — 첫 항목이 열려 있다.
Widget _propPicture(Map<String, String> props) => _fit(
  _OpenPicture(
    items: page.demoItemsOf(props),
    openIndex: 0,
    content: _body(page.demoProductsBody),
    style: page.demoStyleOf(props),
  ),
);

/// 플레이그라운드의 미리보기 — 그림 아래에 같은 속성의 실제 `NavigationMenu` 를
/// 둔다. 포인터를 올리거나 누르면 패널이 열린다.
Widget _withOpener(Map<String, String> props, Widget picture) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    picture,
    const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space48)),
    _fit(NavigationMenu(items: _items(page.demoItemsOf(props)), navigationMenuStyle: page.demoStyleOf(props))),
  ],
);

/// 바는 줄을 바꾸거나 스크롤하지 않으므로, 좁은 자리에서는 줄여 그린다.
Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);

List<CoreNavigationMenuItem<Widget>> _items(List<page.DemoMenuItem> items) => [
  for (final item in items) _item(item),
];

CoreNavigationMenuItem<Widget> _item(page.DemoMenuItem item) {
  final body = item.body;
  return CoreNavigationMenuItem<Widget>(
    label: item.label,
    content: body == null ? null : _body(body),
    href: item.href,
    onTap: body == null ? () {} : null,
  );
}

Widget _body(String text) => Text(text).bodyMedium;

/// 제목과 설명을 여러 줄 담은 패널 글.
Widget _richBody() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [
    for (final (title, description) in page.demoRichEntries) ...[
      Text(title).titleSmall,
      Text(description).bodySmall.onSurfaceVariant,
    ],
  ],
);

/// 열린 모습의 그림 — [openIndex] 항목이 열린 바와, 그 항목의 왼쪽 가장자리에
/// 맞춘 패널.
class _OpenPicture extends StatelessWidget {
  const _OpenPicture({required this.items, required this.openIndex, required this.content, this.style});

  final List<page.DemoMenuItem> items;
  final int openIndex;
  final Widget content;
  final CoreNavigationMenuStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveNavigationMenu(
      context,
      variant: CoreNavigationMenuVariant.standard,
      navigationMenuStyle: style,
    );
    final panel = Popup(popupStyle: resolved.panelStyle, children: [content]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: resolved.menuOffset,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: resolved.triggerSpacing,
          children: [for (var i = 0; i < items.length; i++) _trigger(resolved, i)],
        ),
        if (openIndex == 0)
          panel
        else
          // 열린 항목보다 앞의 항목을 보이지 않게 다시 놓아, 패널의 왼쪽을 열린
          // 항목의 왼쪽에 맞춘다.
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: resolved.triggerSpacing,
            children: [
              for (var i = 0; i < openIndex; i++)
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _trigger(resolved, i),
                ),
              panel,
            ],
          ),
      ],
    );
  }

  /// 항목 하나 — `NavigationMenu` 의 항목과 같은 `Button` 과 화살표.
  Widget _trigger(ResolvedNavigationMenu resolved, int index) {
    final hasContent = items[index].body != null;
    final open = index == openIndex;
    return Button(
      variant: CoreButtonVariant.menubar,
      buttonStyle: !hasContent
          ? resolved.triggerButtonStyle
          : open
          ? resolved.openTriggerButtonStyle
          : resolved.contentTriggerButtonStyle,
      disableFocusOutline: true,
      trailing: hasContent
          ? RotatedBox(
              quarterTurns: open ? 2 : 0,
              child: Icon(LucideIcons.chevronDown, iconStyle: resolved.chevronIconStyle),
            )
          : null,
      onPressed: () {},
      child: Text(items[index].label, style: resolved.triggerTextStyle),
    );
  }
}
