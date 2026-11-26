/// MenuItem 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="menu-item/...">` 가 읽는다. 같은 이름의 Web 파일(`menu_item_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'menu_item_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _menuItem;

/// 장면 이름(`menu-item/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'menu-item/anatomy': _menuItemAnatomy,
  'menu-item/description': _menuItemDescriptions,
  'menu-item/marks': _menuItemMarks,
  'menu-item/states': _menuItemStates,
  'menu-item/do-critical-last': () => _fileMenu(criticalLast: true),
  'menu-item/dont-critical-middle': () => _fileMenu(criticalLast: false),
  'menu-item/related-menu': () => Menu(
    ariaLabel: '편집 동작',
    items: [
      CoreMenuItem.action('복사', shortcut: '⌘C', onPressed: () {}),
      CoreMenuItem.checkbox('격자 보기', checked: true, onChanged: (_) {}),
      CoreMenuItem.action('붙여넣기', onPressed: () {}),
    ],
  ),
};

/// 행은 받은 폭을 채우므로 무대에는 폭을 정해 놓는다.
Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

Widget _column(List<Widget> children, {double gap = CoreSpace.space4}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: gap,
  children: children,
);

Widget _menuItem(Map<String, String> props, String? label) {
  final tone = menuItemPreviewTone(props);
  final description = menuItemPreviewDescription(props);
  final shortcut = menuItemPreviewShortcut(props);
  return _sized(
    MenuItem(
      size: menuItemPreviewSize(props),
      tone: tone,
      mark: previewFlag(props, 'mark') ? Icon(LucideIcons.check) : null,
      reserveMark: previewFlag(props, 'reserveMark'),
      leading: docsFlutterIcon(menuItemPreviewLeading(props)),
      label: Text(label ?? menuItemSample(tone).label),
      description: description == null ? null : Text(description),
      shortcut: shortcut == null ? null : Text(shortcut),
      hasSubmenu: previewFlag(props, 'hasSubmenu'),
      selected: previewFlag(props, 'selected'),
      enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
      onPressed: () {},
    ),
  );
}

Widget _menuItemAnatomy() {
  final sample = menuItemSample(CoreMenuItemTone.neutral);
  return _sized(
    MenuItem(
      size: CoreMenuItemSize.lg,
      mark: Icon(LucideIcons.check),
      leading: Icon(LucideIcons.copy),
      label: Text(sample.label),
      description: Text(sample.description),
      shortcut: Text(sample.shortcut),
      trailing: Text('베타').labelSmall.onSurfaceVariant,
      onPressed: () {},
    ),
    width: 360,
  );
}

Widget _menuItemDescriptions() {
  final sample = menuItemSample(CoreMenuItemTone.neutral);
  return _sized(
    _column([
      for (final size in CoreMenuItemSize.values)
        MenuItem(
          size: size,
          leading: Icon(LucideIcons.copy),
          label: Text('${sample.label} (${size.name})'),
          description: Text(sample.description),
          shortcut: Text(sample.shortcut),
          onPressed: () {},
        ),
    ], gap: CoreSpace.space8),
    width: 280,
  );
}

Widget _menuItemMarks() => _sized(
  _column([
    MenuItem(mark: Icon(LucideIcons.check), selected: true, label: const Text('격자 보기'), onPressed: () {}),
    MenuItem(reserveMark: true, label: const Text('눈금자 보기'), onPressed: () {}),
    MenuItem(label: const Text('새로 고침'), onPressed: () {}),
  ]),
);

/// 상태 장면 — Web 과 같은 네 상태를 톤마다 쌓는다.
Widget _menuItemStates() => Wrap(
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final tone in CoreMenuItemTone.values)
      _sized(
        _column([
          Text(tone.name).labelSmall.onSurfaceVariant,
          for (final (name, selected, enabled) in menuItemStateRows)
            MenuItem(
              tone: tone,
              leading: Icon(tone == CoreMenuItemTone.critical ? LucideIcons.trash2 : LucideIcons.copy),
              label: Text(name),
              shortcut: Text(menuItemSample(tone).shortcut),
              selected: selected,
              enabled: enabled,
              onPressed: () {},
            ),
        ]),
        width: 224,
      ),
  ],
);

/// 위험한 행의 자리 — `criticalLast` 면 구분선 뒤 마지막, 아니면 가운데.
Widget _fileMenu({required bool criticalLast}) {
  final rename = CoreMenuItem<Widget>.action('이름 바꾸기', onPressed: () {});
  final duplicate = CoreMenuItem<Widget>.action('복제', onPressed: () {});
  final remove = CoreMenuItem<Widget>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {});
  return Menu(
    ariaLabel: '파일 동작',
    items: criticalLast ? [rename, duplicate, const CoreMenuItem.divider(), remove] : [rename, remove, duplicate],
  );
}
