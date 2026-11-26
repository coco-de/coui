/// Select 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="select/...">` 가 읽는다. 같은 이름의 Web 파일(`select_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'select_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _select;

/// 장면 이름(`select/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'select/anatomy': () => _sized(
    Select<String>(
      label: '카테고리',
      value: 'fruit',
      description: '하나만 고를 수 있습니다.',
      onChanged: (_) {},
      items: _items,
    ),
  ),
  'select/states': _selectStates,
  'select/suffix': () => _sized(
    Select<String>(
      value: 'KRW',
      onChanged: (_) {},
      suffix: const Text('변경'),
      items: const [
        CoreSelectItem(value: 'KRW', label: 'KRW'),
        CoreSelectItem(value: 'USD', label: 'USD'),
      ],
    ),
  ),
  'select/related-autocomplete': () => _sized(
    Autocomplete(
      placeholder: '국가 검색',
      onChanged: (_) {},
      suggestions: const ['대한민국', '일본', '미국'],
    ),
    width: 192,
  ),
};

final List<CoreSelectItem<String>> _items = [
  for (final (value, text) in selectPreviewItems) CoreSelectItem(value: value, label: text),
];

Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

Widget _select(Map<String, String> props, String? label) => _sized(
  Select<String>(
    variant: previewEnum(CoreSelectVariant.values, props['variant'], CoreSelectVariant.defaultVariant),
    size: previewEnum(CoreSelectSize.values, props['size'], CoreSelectSize.md),
    label: props['label'],
    placeholder: props['placeholder'],
    value: props['value'],
    description: props['description'],
    errorText: props['errorText'],
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
    items: _items,
  ),
);

/// 상태 격자 — Web 과 같은 다섯 칸.
Widget _selectStates() {
  const columns = ['기본', '선택됨', 'filled', '오류', '비활성'];
  Widget cell(String state) => SizedBox(
    width: 152,
    child: switch (state) {
      '선택됨' => Select<String>(value: 'fruit', onChanged: (_) {}, items: _items),
      'filled' => Select<String>(
        variant: CoreSelectVariant.filled,
        value: 'fruit',
        onChanged: (_) {},
        items: _items,
      ),
      '오류' => Select<String>(placeholder: '선택', errorText: '필수 항목', onChanged: (_) {}, items: _items),
      '비활성' => Select<String>(value: 'fruit', enabled: false, onChanged: (_) {}, items: _items),
      _ => Select<String>(placeholder: '선택', onChanged: (_) {}, items: _items),
    },
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
