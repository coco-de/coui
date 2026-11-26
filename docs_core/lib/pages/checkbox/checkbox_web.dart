/// Checkbox 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="checkbox/...">` 가 읽는다. 같은 이름의 Flutter 파일(`checkbox_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _checkbox;

/// 장면 이름(`checkbox/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'checkbox/anatomy': () => Checkbox(
    checked: true,
    onChanged: (_) {},
    label: '약관에 동의합니다',
    description: '필수 항목입니다.',
  ),
  'checkbox/states': _checkboxStates,
  'checkbox/select-all': () => div(classes: 'docs-demo-stack', [
    Checkbox(checked: null, tristate: true, onChanged: (_) {}, label: '전체 선택'),
    div(
      classes: 'docs-demo-stack',
      styles: Styles(raw: {'width': 'auto', 'padding-inline-start': 'var(--coui-space-24)'}),
      [
        Checkbox(checked: true, onChanged: (_) {}, label: '서비스 이용약관'),
        Checkbox(checked: true, onChanged: (_) {}, label: '개인정보 처리방침'),
        Checkbox(checked: false, onChanged: (_) {}, label: '마케팅 정보 수신'),
      ],
    ),
  ]),
  'checkbox/related-toggle': () => docsWebDemoRow([
    Toggle(value: true, onChanged: (_) {}),
    Toggle(onChanged: (_) {}),
  ]),
  'checkbox/related-radio-group': () => RadioGroup(
    value: 'card',
    onChanged: (_) {},
    options: const [(value: 'card', label: '카드'), (value: 'transfer', label: '계좌이체')],
  ),
  'checkbox/related-switch-field': () => div(styles: Styles(raw: {'width': '15rem'}), [
    SwitchField(label: '알림 받기', value: true, onChanged: (_) {}),
  ]),
};

Component _checkbox(Map<String, String> props, String? label) {
  final checked = switch (props['checked']) {
    'true' => true,
    'null' => null,
    _ => false,
  };
  return Checkbox(
    checked: checked,
    tristate: checked == null,
    onChanged: (_) {},
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    label: label,
    description: props['description'],
  );
}

/// 상태 격자 — 다섯 상태 모두 실제 체크박스다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _checkboxStates() {
  const columns = ['해제', '선택', '불확정', '비활성', '비활성 · 선택'];
  Component cell(String state) => switch (state) {
    '선택' => Checkbox(checked: true, onChanged: (_) {}),
    '불확정' => Checkbox(checked: null, tristate: true, onChanged: (_) {}),
    '비활성' => Checkbox(checked: false, enabled: false, onChanged: (_) {}),
    '비활성 · 선택' => Checkbox(checked: true, enabled: false, onChanged: (_) {}),
    _ => Checkbox(checked: false, onChanged: (_) {}),
  };
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
