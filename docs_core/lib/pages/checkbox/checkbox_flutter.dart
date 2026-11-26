/// Checkbox 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="checkbox/...">` 가 읽는다. 같은 이름의 Web 파일(`checkbox_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _checkbox;

/// 장면 이름(`checkbox/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'checkbox/anatomy': () => Checkbox(
    checked: true,
    onChanged: (_) {},
    label: '약관에 동의합니다',
    description: '필수 항목입니다.',
  ),
  'checkbox/states': _checkboxStates,
  'checkbox/select-all': () => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [
      Checkbox(checked: null, tristate: true, onChanged: (_) {}, label: '전체 선택'),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: CoreSpace.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [
            Checkbox(checked: true, onChanged: (_) {}, label: '서비스 이용약관'),
            Checkbox(checked: true, onChanged: (_) {}, label: '개인정보 처리방침'),
            Checkbox(checked: false, onChanged: (_) {}, label: '마케팅 정보 수신'),
          ],
        ),
      ),
    ],
  ),
  'checkbox/related-toggle': () => docsFlutterDemoRow([
    Toggle(value: true, onChanged: (_) {}),
    Toggle(value: false, onChanged: (_) {}),
  ]),
  'checkbox/related-radio-group': () => RadioGroup<String>(
    value: 'card',
    onChanged: (_) {},
    options: const [(value: 'card', label: '카드'), (value: 'transfer', label: '계좌이체')],
  ),
  'checkbox/related-switch-field': () => SizedBox(
    width: 240,
    child: SwitchField(label: '알림 받기', value: true, onChanged: (_) {}),
  ),
};

Widget _checkbox(Map<String, String> props, String? label) {
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

/// 상태 격자 — Web 과 같은 다섯 상태.
Widget _checkboxStates() {
  const columns = ['해제', '선택', '불확정', '비활성', '비활성 · 선택'];
  Widget cell(String state) => switch (state) {
    '선택' => Checkbox(checked: true, onChanged: (_) {}),
    '불확정' => Checkbox(checked: null, tristate: true, onChanged: (_) {}),
    '비활성' => Checkbox(checked: false, enabled: false, onChanged: (_) {}),
    '비활성 · 선택' => Checkbox(checked: true, enabled: false, onChanged: (_) {}),
    _ => Checkbox(checked: false, onChanged: (_) {}),
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
