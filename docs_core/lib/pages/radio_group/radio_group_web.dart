/// RadioGroup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="radio-group/...">` 가 읽는다. 같은 이름의 Flutter 파일(`radio_group_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'radio_group_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _radioGroup;

/// 장면 이름(`radio-group/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'radio-group/anatomy': () => RadioGroup(
    value: 'pro',
    onChanged: (_) {},
    child: _column([
      const Radio(value: 'basic', label: 'Basic', description: '개인 프로젝트용'),
      const Radio(value: 'pro', label: 'Pro', description: '팀 협업과 우선 지원'),
    ]),
  ),
  'radio-group/card': () => div(styles: Styles(raw: {'width': '18rem'}), [
    RadioGroup(
      value: 'pro',
      onChanged: (_) {},
      variant: CoreRadioGroupVariant.card,
      child: _column([
        const Radio(value: 'basic', label: 'Basic', description: '개인 프로젝트용'),
        const Radio(value: 'pro', label: 'Pro', description: '팀 협업과 우선 지원'),
      ]),
    ),
  ]),
  'radio-group/states': _radioStates,
  'radio-group/dont-many': () => RadioGroup(
    value: 'kr',
    onChanged: (_) {},
    options: const [
      (value: 'kr', label: '대한민국'),
      (value: 'jp', label: '일본'),
      (value: 'us', label: '미국'),
      (value: 'gb', label: '영국'),
      (value: 'de', label: '독일'),
      (value: 'fr', label: '프랑스'),
      (value: 'ca', label: '캐나다'),
      (value: 'au', label: '호주'),
    ],
  ),
  'radio-group/related-switch-field': () => div(styles: Styles(raw: {'width': '15rem'}), [
    SwitchField(label: '알림 받기', value: true, onChanged: (_) {}),
  ]),
};

Component _radioGroup(Map<String, String> props, String? label) {
  final count = int.tryParse(props['options'] ?? '') ?? radioGroupPreviewOptions.length;
  return RadioGroup(
    value: props['value'] ?? 'pro',
    onChanged: (_) {},
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    variant: previewEnum(CoreRadioGroupVariant.values, props['variant'], CoreRadioGroupVariant.defaultVariant),
    orientation: previewEnum(
      CoreRadioGroupOrientation.values,
      props['orientation'],
      CoreRadioGroupOrientation.vertical,
    ),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    options: [
      for (final (value, text) in radioGroupPreviewOptions.take(count)) (value: value, label: text),
    ],
  );
}

Component _column(List<Component> children) => div(classes: 'flex flex-col gap-${CoreSpace.scale.space8}', children);

/// 상태 격자 — 그룹 밖의 `Radio` 를 상태마다 하나씩 둔다. hover · 눌림 ·
/// 포커스는 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _radioStates() {
  const columns = ['미선택', '선택', '비활성', '비활성 · 선택'];
  Component cell(String state) => switch (state) {
    '선택' => Radio(value: 'a', groupValue: 'a', onChanged: (_) {}),
    '비활성' => Radio(value: 'a', enabled: false, onChanged: (_) {}),
    '비활성 · 선택' => Radio(value: 'a', groupValue: 'a', enabled: false, onChanged: (_) {}),
    _ => Radio(value: 'a', onChanged: (_) {}),
  };
  return div(
    classes: 'docs-demo-field-states',
    styles: Styles(raw: {'grid-template-columns': 'repeat(${columns.length}, max-content)'}),
    [
      for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
      for (final column in columns) cell(column),
    ],
  );
}
