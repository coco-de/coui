/// MenuItem 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="menu-item/...">` 가 읽는다. 같은 이름의 Flutter 파일(`menu_item_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'menu_item_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _menuItem;

/// 장면 이름(`menu-item/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
Component _sized(Component child, {String width = '15rem'}) =>
    div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [child]);

Component _column(List<Component> children, {String gap = 'var(--coui-space-4)'}) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': gap}),
  children,
);

Component _menuItem(Map<String, String> props, String? label) {
  final tone = menuItemPreviewTone(props);
  final description = menuItemPreviewDescription(props);
  final shortcut = menuItemPreviewShortcut(props);
  return _sized(
    MenuItem(
      size: menuItemPreviewSize(props),
      tone: tone,
      mark: previewFlag(props, 'mark') ? Icon(LucideIcons.check) : null,
      reserveMark: previewFlag(props, 'reserveMark'),
      leading: docsWebIcon(menuItemPreviewLeading(props)),
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

/// 구조 블록이 번호를 붙일 수 있게 자리마다 `data-docs-part` 를 단 상자로 감싼다.
Component _part(String name, Component child) =>
    span(classes: 'flex shrink-0', attributes: {'data-docs-part': name}, [child]);

Component _menuItemAnatomy() {
  final sample = menuItemSample(CoreMenuItemTone.neutral);
  return _sized(
    MenuItem(
      size: CoreMenuItemSize.lg,
      mark: _part('mark', Icon(LucideIcons.check)),
      leading: _part('leading', Icon(LucideIcons.copy)),
      label: Text(sample.label),
      description: _part('description', Text(sample.description)),
      shortcut: _part('shortcut', Text(sample.shortcut)),
      trailing: _part('trailing', Text('베타').labelSmall.onSurfaceVariant),
      onPressed: () {},
    ),
    width: '22.5rem',
  );
}

Component _menuItemDescriptions() {
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
    ], gap: 'var(--coui-space-8)'),
    width: '17.5rem',
  );
}

Component _menuItemMarks() => _sized(
  _column([
    MenuItem(mark: Icon(LucideIcons.check), selected: true, label: const Text('격자 보기'), onPressed: () {}),
    MenuItem(reserveMark: true, label: const Text('눈금자 보기'), onPressed: () {}),
    MenuItem(label: const Text('새로 고침'), onPressed: () {}),
  ]),
);

/// 상태 장면 — 톤마다 네 상태를 쌓는다. hover · 눌림 · 포커스는 브라우저가
/// 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _menuItemStates() => div(
  styles: Styles(raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--coui-space-24)'}),
  [
    for (final tone in CoreMenuItemTone.values)
      _sized(
        _column([
          span([Text(tone.name).labelSmall.onSurfaceVariant]),
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
        width: '14rem',
      ),
  ],
);

/// 위험한 행의 자리 — `criticalLast` 면 구분선 뒤 마지막, 아니면 가운데.
Component _fileMenu({required bool criticalLast}) {
  final rename = CoreMenuItem<Component>.action('이름 바꾸기', onPressed: () {});
  final duplicate = CoreMenuItem<Component>.action('복제', onPressed: () {});
  final remove = CoreMenuItem<Component>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {});
  return Menu(
    ariaLabel: '파일 동작',
    items: criticalLast ? [rename, duplicate, const CoreMenuItem.divider(), remove] : [rename, remove, duplicate],
  );
}
