/// OptionItem 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="option-item/...">` 가 읽는다. 같은 이름의 Flutter 파일(`option_item_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'option_item_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _optionItem;

/// 장면 이름(`option-item/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 블록이 설명에 번호를 붙일 수 있게 설명에 `data-docs-part` 를 단다.
  'option-item/anatomy': () => _sized(
    OptionItem(
      leading: Icon(LucideIcons.star),
      label: const Text(optionItemPreviewLabel),
      description: span(
        attributes: const {'data-docs-part': 'description'},
        const [Text(optionItemPreviewDescription)],
      ),
      selected: true,
      onPressed: () {},
    ),
  ),
  'option-item/states': _optionItemStates,
  'option-item/list': () => _sized(
    OptionList(
      children: [
        for (final (index, label) in optionItemListLabels.indexed)
          OptionItem(label: Text(label), selected: index == 0, onPressed: () {}),
      ],
    ),
  ),
  'option-item/related-option-list': () => _sized(
    OptionList(
      children: [
        OptionItem(label: Text(optionItemListLabels[0]), selected: true, onPressed: () {}),
        OptionItem(label: Text(optionItemListLabels[1]), onPressed: () {}),
      ],
    ),
    width: '14rem',
  ),
};

/// 줄은 받은 폭을 채우므로 무대에는 폭을 정해 놓는다.
Component _sized(Component child, {String width = '20rem'}) =>
    div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [child]);

Component _optionItem(Map<String, String> props, String? label) {
  final description = props['description'];
  return _sized(
    OptionItem(
      selection: previewEnum(
        CoreOptionItemSelection.values,
        props['selection'],
        CoreOptionItemSelection.defaultSelection,
      ),
      selected: previewFlag(props, 'selected'),
      enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
      leading: docsWebIcon(props['leading']),
      label: Text(label ?? optionItemPreviewLabel),
      description: description == null ? null : Text(description),
      onPressed: () {},
    ),
  );
}

/// 상태 장면 — 상태마다 두 선택 방식을 나란히 놓는다. 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _optionItemStates() {
  Component group(List<Component> children, {required String direction, required String gap}) => div(
    styles: Styles(raw: {'display': 'flex', 'flex-direction': direction, 'flex-wrap': 'wrap', 'gap': gap}),
    children,
  );

  return group(direction: 'column', gap: 'var(--coui-space-12)', [
    for (final (name, selected, enabled) in optionItemStateRows)
      group(direction: 'column', gap: 'var(--coui-space-4)', [
        span([Text(name).labelSmall.onSurfaceVariant]),
        group(direction: 'row', gap: 'var(--coui-space-12)', [
          for (final selection in CoreOptionItemSelection.values)
            _sized(
              OptionItem(
                selection: selection,
                selected: selected,
                enabled: enabled,
                label: Text(selection.name),
                onPressed: () {},
              ),
              width: '12rem',
            ),
        ]),
      ]),
  ]);
}
