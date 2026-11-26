/// SwitchField 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="switch-field/...">` 가 읽는다. 같은 이름의 Web 파일(`switch_field_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 스위치 필드는 라벨 열을 `Expanded` 로 두므로 폭이 정해진 부모가
/// 필요하다 — 미리보기마다 Web 의 15rem 과 같은 240 을 준다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'switch_field_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _switchField;

/// 장면 이름(`switch-field/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'switch-field/anatomy': () => _sized(
    SwitchField(
      label: switchFieldPreviewLabel,
      description: switchFieldPreviewDescription,
      value: true,
      onChanged: (_) {},
    ),
  ),
  'switch-field/states': () => _column([
    for (final (label, value, enabled) in switchFieldStateRows)
      SwitchField(
        label: label,
        description: switchFieldPreviewDescription,
        value: value,
        enabled: enabled,
        onChanged: (_) {},
      ),
  ]),
  'switch-field/sizes': () => _column([
    for (final size in switchFieldSceneSizes)
      SwitchField(
        label: switchFieldSizeLabel(size),
        value: true,
        onChanged: (_) {},
        switchFieldStyle: CoreSwitchFieldStyle(size: size),
      ),
  ]),
  'switch-field/settings': () => _column([
    for (final (label, description, value) in switchFieldSettingsRows)
      SwitchField(label: label, description: description, value: value, onChanged: (_) {}),
  ]),
};

Widget _sized(Widget child) => SizedBox(width: 240, child: child);

Widget _column(List<Widget> children) => SizedBox(
  width: 240,
  child: Column(mainAxisSize: MainAxisSize.min, spacing: CoreSpace.space16, children: children),
);

Widget _switchField(Map<String, String> props, String? label) => _sized(
  SwitchField(
    label: label ?? switchFieldPreviewLabel,
    description: props['description'],
    value: previewFlag(props, 'value'),
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    onChanged: (_) {},
  ),
);
