/// OptionList 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="option-list/...">` 가 읽는다. 같은 이름의 Web 파일(`option_list_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'option_list_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _optionList;

/// 장면 이름(`option-list/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'option-list/do-same-selection': () => _sheet(_list(selection: CoreOptionItemSelection.multiple), width: 224),
  'option-list/dont-mixed-selection': () => _sheet(
    OptionList(
      children: [
        _item('최신순', selected: true),
        _item('인기순', selection: CoreOptionItemSelection.multiple, selected: true),
        _item('낮은 가격순'),
      ],
    ),
    width: 224,
  ),
  'option-list/dont-divider': () => _sheet(
    OptionList(
      children: [
        _item('최신순', selected: true),
        const Divider(),
        _item('인기순'),
      ],
    ),
    width: 224,
  ),
  'option-list/related-option-item': () => _sheet(_item('최신순', selected: true), width: 224),
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
Widget _sheet(Widget child, {double width = 288}) => SizedBox(width: width, child: child);

Widget _item(
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

Widget _list({CoreOptionItemSelection selection = CoreOptionItemSelection.single, double? spacing}) {
  final selected = optionListPreviewSelected(selection);
  return OptionList(
    optionListStyle: spacing == null ? null : CoreOptionListStyle(spacing: spacing),
    children: [
      for (final (value, text) in optionListPreviewItems(selection))
        _item(text, selection: selection, selected: selected.contains(value)),
    ],
  );
}

Widget _optionList(Map<String, String> props, String? label) => _sheet(
  _list(selection: optionListPreviewSelection(props), spacing: optionListPreviewSpacing(props)),
);

/// single 과 multiple 목록을 나란히 — Web 과 같은 두 칸.
Widget _selectionDemo() => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final selection in CoreOptionItemSelection.values)
      SizedBox(
        width: 224,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [
            Text(optionListSelectionCaption(selection)).labelSmall.onSurfaceVariant,
            _list(selection: selection),
          ],
        ),
      ),
  ],
);
