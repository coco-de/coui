/// Toggle 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="toggle/...">` 가 읽는다. 같은 이름의 Flutter 파일(`toggle_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _toggle;

/// 장면 이름(`toggle/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'toggle/anatomy': () => Toggle(value: false, onChanged: (_) {}, label: '알림 받기'),
  'toggle/states': _toggleStates,
  'toggle/settings': () => div(classes: 'docs-demo-stack', [
    Toggle(value: true, onChanged: (_) {}, label: '다크 모드'),
    Toggle(value: false, onChanged: (_) {}, label: '푸시 알림'),
    Toggle(value: true, onChanged: (_) {}, label: '자동 저장'),
  ]),
  'toggle/related-switch-field': () => div(styles: Styles(raw: {'width': '15rem'}), [
    SwitchField(label: '알림 받기', description: '새 댓글이 달리면 알려 드려요.', value: true, onChanged: (_) {}),
  ]),
  'toggle/related-slider': () => div(styles: Styles(raw: {'width': '12rem'}), [
    Slider(value: 60, min: 0, max: 100, onChanged: (_) {}),
  ]),
};

Component _toggle(Map<String, String> props, String? label) => Toggle(
  value: previewFlag(props, 'value'),
  onChanged: (_) {},
  enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
  size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
  label: label,
);

/// 상태 격자 — 네 상태 모두 실제 토글이다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _toggleStates() {
  const columns = ['꺼짐', '켜짐', '비활성', '비활성 · 켜짐'];
  Component cell(String state) => switch (state) {
    '켜짐' => Toggle(value: true, onChanged: (_) {}),
    '비활성' => Toggle(enabled: false, onChanged: (_) {}),
    '비활성 · 켜짐' => Toggle(value: true, enabled: false, onChanged: (_) {}),
    _ => Toggle(onChanged: (_) {}),
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
