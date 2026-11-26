/// OptionList 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="option-list/...">` 가 읽는다. 같은 이름의 Flutter 파일(`option_list_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'option_list_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _optionList;

/// 장면 이름(`option-list/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'option-list/anatomy': () => _sheet(_list()),
  'option-list/selection': _selectionDemo,
  'option-list/disabled': () => _sheet(
    OptionList(
      children: [
        _item('최신순', selected: true),
        _item('인기순', enabled: false),
        _item('낮은 가격순'),
      ],
    ),
  ),
  'option-list/do-same-selection': () => _sheet(_list(selection: CoreOptionItemSelection.multiple), width: '14rem'),
  'option-list/dont-mixed-selection': () => _sheet(
    OptionList(
      children: [
        _item('최신순', selected: true),
        _item('인기순', selection: CoreOptionItemSelection.multiple, selected: true),
        _item('낮은 가격순'),
      ],
    ),
    width: '14rem',
  ),
  'option-list/dont-divider': () => _sheet(
    OptionList(
      children: [
        _item('최신순', selected: true),
        const Divider(),
        _item('인기순'),
      ],
    ),
    width: '14rem',
  ),
  'option-list/related-option-item': () => _sheet(_item('최신순', selected: true), width: '14rem'),
  'option-list/related-menu': () => Menu(
    ariaLabel: '파일 동작',
    items: [
      CoreMenuItem.action('이름 바꾸기', onPressed: () {}),
      CoreMenuItem.action('복제', onPressed: () {}),
      CoreMenuItem.action('삭제', onPressed: () {}),
    ],
  ),
};

/// 시트 안처럼 폭이 정해진 틀 — 목록은 받은 폭을 채운다.
Component _sheet(Component child, {String width = '18rem'}) =>
    div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [child]);

Component _item(
  String text, {
  CoreOptionItemSelection selection = CoreOptionItemSelection.single,
  bool selected = false,
  bool? enabled,
}) => OptionItem(
  selection: selection,
  label: Text(text),
  selected: selected,
  enabled: enabled,
  onPressed: () {},
);

Component _list({CoreOptionItemSelection selection = CoreOptionItemSelection.single, double? spacing}) {
  final selected = optionListPreviewSelected(selection);
  return OptionList(
    optionListStyle: spacing == null ? null : CoreOptionListStyle(spacing: spacing),
    children: [
      for (final (value, text) in optionListPreviewItems(selection))
        _item(text, selection: selection, selected: selected.contains(value)),
    ],
  );
}

Component _optionList(Map<String, String> props, String? label) => _sheet(
  _list(selection: optionListPreviewSelection(props), spacing: optionListPreviewSpacing(props)),
);

/// single 과 multiple 목록을 나란히 — 폭이 모자라면 아래로 넘어간다.
Component _selectionDemo() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': '1.5rem',
      'width': '100%',
    },
  ),
  [
    for (final selection in CoreOptionItemSelection.values)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': '0.5rem',
            'width': '14rem',
            'max-width': '100%',
          },
        ),
        [
          span([Text(optionListSelectionCaption(selection)).labelSmall.onSurfaceVariant]),
          _list(selection: selection),
        ],
      ),
  ],
);
