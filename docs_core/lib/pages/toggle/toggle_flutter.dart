/// Toggle 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="toggle/...">` 가 읽는다. 같은 이름의 Web 파일(`toggle_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _toggle;

/// 장면 이름(`toggle/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'toggle/anatomy': () => Toggle(value: false, onChanged: (_) {}, label: '알림 받기'),
  'toggle/states': _toggleStates,
  'toggle/settings': () => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [
      Toggle(value: true, onChanged: (_) {}, label: '다크 모드'),
      Toggle(value: false, onChanged: (_) {}, label: '푸시 알림'),
      Toggle(value: true, onChanged: (_) {}, label: '자동 저장'),
    ],
  ),
  'toggle/related-switch-field': () => SizedBox(
    width: 240,
    child: SwitchField(label: '알림 받기', description: '새 댓글이 달리면 알려 드려요.', value: true, onChanged: (_) {}),
  ),
  'toggle/related-slider': () => SizedBox(
    width: 192,
    child: Slider(value: 60, min: 0, max: 100, onChanged: (_) {}),
  ),
};

Widget _toggle(Map<String, String> props, String? label) => Toggle(
  value: previewFlag(props, 'value'),
  onChanged: (_) {},
  enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
  size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
  label: label,
);

/// 상태 격자 — Web 과 같은 네 상태.
Widget _toggleStates() {
  const columns = ['꺼짐', '켜짐', '비활성', '비활성 · 켜짐'];
  Widget cell(String state) => switch (state) {
    '켜짐' => Toggle(value: true, onChanged: (_) {}),
    '비활성' => Toggle(value: false, enabled: false, onChanged: (_) {}),
    '비활성 · 켜짐' => Toggle(value: true, enabled: false, onChanged: (_) {}),
    _ => Toggle(value: false, onChanged: (_) {}),
  };
  return Wrap(
    spacing: CoreSpace.space16,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
