/// Select 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="select/...">` 가 읽는다. 같은 이름의 Flutter 파일(`select_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'select_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _select;

/// 장면 이름(`select/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
    width: '12rem',
  ),
};

final List<CoreSelectItem<String>> _items = [
  for (final (value, text) in selectPreviewItems) CoreSelectItem(value: value, label: text),
];

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

Component _select(Map<String, String> props, String? label) => _sized(
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

/// 상태 격자 — 다섯 칸 모두 실제 Select 다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _selectStates() {
  const columns = ['기본', '선택됨', 'filled', '오류', '비활성'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
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
  ]);
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
