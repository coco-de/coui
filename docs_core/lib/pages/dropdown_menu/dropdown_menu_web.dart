/// DropdownMenu 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="dropdown-menu/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`dropdown_menu_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 열린 패널은 그림이다. `DropdownMenu` 의 패널은 열리면 오버레이
/// 호스트의 메뉴 층에 올라가고, 패널을 제자리에 그리는 공개 경로가 없다. 대신
/// 패널이 안에 그리는 것 — `Menu` 하나 — 을 `DropdownMenu` 가 넘기는 것과 같은
/// 스타일(`CoreDropdownMenuStyle.defaultMenuStyle`)로 제자리에 그리고, 그 위에
/// 트리거 버튼을 `defaultMenuOffset` 만큼 띄워 놓는다. 실제 `DropdownMenu` 는
/// 플레이그라운드의 그림 아래 버튼이 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'dropdown_menu_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _dropdownMenu;

/// 장면 이름(`dropdown-menu/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'dropdown-menu/anatomy': () => _picture(page.demoAnatomyItems<Component>()),
  'dropdown-menu/entries': () => docsWebDemoRow([
    _panel(page.demoEntryItems<Component>()),
    _panel(page.demoToggleItems<Component>()),
  ]),
  'dropdown-menu/shortcut': () => _panel(page.demoShortcutItems<Component>()),
  'dropdown-menu/states': () => _panel(page.demoStateItems<Component>()),
  'dropdown-menu/do-group': () => _panel(page.demoGroupItems<Component>()),
  'dropdown-menu/dont-value-pick': () =>
      _picture(page.demoValuePickItems<Component>(), triggerLabel: page.demoValuePickTrigger),
  'dropdown-menu/do-critical-last': () => _panel(page.demoCriticalLastItems<Component>()),
  'dropdown-menu/dont-critical-middle': () => _panel(page.demoCriticalMiddleItems<Component>()),
};

Component _dropdownMenu(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _DropdownMenuOpener(props: props, label: label);
  return _picture(_propItems(props), triggerLabel: label ?? page.demoTriggerLabel);
}

/// 속성으로 고른 항목.
List<CoreMenuItem<Component>> _propItems(
  Map<String, String> props, {
  page.DropdownDemoValues values = page.demoInitialValues,
  void Function(page.DropdownDemoValues next)? onValues,
}) => page.demoItems<Component>(props, icon: (name) => Icon(name), values: values, onValues: onValues);

Component _trigger(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

/// 열린 패널 — `DropdownMenu` 가 패널에 그리는 `Menu`.
Component _panel(List<CoreMenuItem<Component>> items) => div(
  attributes: const {'data-docs-part': 'panel'},
  [Menu(items: items, menuStyle: CoreDropdownMenuStyle.defaultMenuStyle)],
);

/// 트리거와 열린 패널의 그림 — 패널은 트리거 아래에 왼쪽 끝을 맞춰 놓는다.
Component _picture(List<CoreMenuItem<Component>> items, {String triggerLabel = page.demoTriggerLabel}) => div(
  styles: Styles(
    raw: {
      'display': 'inline-flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': pinnedLengthCss(CoreDropdownMenuStyle.defaultMenuOffset),
    },
  ),
  [
    div(attributes: const {'data-docs-part': 'trigger'}, [_trigger(triggerLabel)]),
    _panel(items),
  ],
);

/// 플레이그라운드의 미리보기 — 그림 아래의 트리거가 같은 항목의 실제
/// `DropdownMenu` 를 연다. checkbox · radio 의 값은 여기서 들고, 실제 메뉴에서
/// 바꾸면 그림도 따라 바뀐다.
class _DropdownMenuOpener extends StatefulComponent {
  const _DropdownMenuOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  State<_DropdownMenuOpener> createState() => _DropdownMenuOpenerState();
}

class _DropdownMenuOpenerState extends State<_DropdownMenuOpener> {
  page.DropdownDemoValues _values = page.demoInitialValues;

  void _handleValues(page.DropdownDemoValues next) => setState(() => _values = next);

  @override
  Component build(BuildContext context) {
    final label = component.label ?? page.demoTriggerLabel;
    final items = _propItems(component.props, values: _values, onValues: _handleValues);
    return div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'gap': spaceCss(page.demoOpenerGap),
          'width': '100%',
        },
      ),
      [
        _picture(items, triggerLabel: label),
        DropdownMenu(trigger: _trigger(label), items: items),
      ],
    );
  }
}
