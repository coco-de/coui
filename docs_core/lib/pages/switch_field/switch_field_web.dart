/// SwitchField 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="switch-field/...">` 가 읽는다. 같은 이름의 Flutter 파일(`switch_field_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 스위치 필드는 부모의 폭을 채우므로(`w-full`) 미리보기마다 폭을 준다 —
/// Flutter 쪽의 240 과 같은 15rem.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'switch_field_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _switchField;

/// 장면 이름(`switch-field/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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

Component _sized(Component child) => div(styles: Styles(raw: {'width': '15rem'}), [child]);

Component _column(List<Component> children) => div(
  styles: Styles(
    raw: {'width': '15rem', 'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space16)},
  ),
  children,
);

Component _switchField(Map<String, String> props, String? label) => _sized(
  SwitchField(
    label: label ?? switchFieldPreviewLabel,
    description: props['description'],
    value: previewFlag(props, 'value'),
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    onChanged: (_) {},
  ),
);
