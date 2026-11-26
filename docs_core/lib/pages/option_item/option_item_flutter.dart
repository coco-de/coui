/// OptionItem 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="option-item/...">` 가 읽는다. 같은 이름의 Web 파일(`option_item_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'option_item_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _optionItem;

/// 장면 이름(`option-item/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'option-item/anatomy': () => _sized(
    OptionItem(
      leading: Icon(LucideIcons.star),
      label: const Text(optionItemPreviewLabel),
      description: const Text(optionItemPreviewDescription),
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
    width: 224,
  ),
};

/// 줄은 받은 폭을 채우므로 무대에는 폭을 정해 놓는다.
Widget _sized(Widget child, {double width = 320}) => SizedBox(width: width, child: child);

Widget _optionItem(Map<String, String> props, String? label) {
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
      leading: docsFlutterIcon(props['leading']),
      label: Text(label ?? optionItemPreviewLabel),
      description: description == null ? null : Text(description),
      onPressed: () {},
    ),
  );
}

/// 상태 장면 — Web 과 같은 네 상태를 두 선택 방식으로 놓는다.
Widget _optionItemStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final (name, selected, enabled) in optionItemStateRows)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space4,
        children: [
          Text(name).labelSmall.onSurfaceVariant,
          Wrap(
            spacing: CoreSpace.space12,
            runSpacing: CoreSpace.space12,
            children: [
              for (final selection in CoreOptionItemSelection.values)
                _sized(
                  OptionItem(
                    selection: selection,
                    selected: selected,
                    enabled: enabled,
                    label: Text(selection.name),
                    onPressed: () {},
                  ),
                  width: 192,
                ),
            ],
          ),
        ],
      ),
  ],
);
