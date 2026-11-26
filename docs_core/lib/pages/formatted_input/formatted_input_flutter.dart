/// FormattedInput 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="formatted-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`formatted_input_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'formatted_input_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _formattedInput;

/// 장면 이름(`formatted-input/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 앞 아이콘 · 값 · 뒤 버튼이 모두 보이게 채운다.
  'formatted-input/anatomy': () => _sized(
    _field(
      formattedInputPresets.first,
      value: formattedInputPresets.first.example,
      leading: const Icon(LucideIcons.smartphone),
      trailing: _sendButton(),
    ),
    width: 320,
  ),
  'formatted-input/masks': _maskList,
  'formatted-input/states': _formattedInputStates,
  'formatted-input/trailing-action': () => _sized(
    _field(formattedInputPresets.first, trailing: _sendButton()),
    width: 320,
  ),
  'formatted-input/do-form-field': () => _sized(_labelled(), width: 256),
  'formatted-input/dont-bare-mask': () => _sized(_field(formattedInputPresets.first), width: 256),
  'formatted-input/do-iso-date': () => _sized(
    const FormattedInput(parts: formattedInputIsoDateParts, value: formattedInputIsoDateExample),
    width: 256,
  ),
  'formatted-input/dont-us-date': () => _sized(
    const FormattedInput.date(value: formattedInputIsoDateExample),
    width: 256,
  ),
  'formatted-input/related-input-otp': () => InputOtp(length: 4, separatorInterval: 0, initialValue: '12'.codeUnits),
  'formatted-input/related-form-field': () => _sized(_labelled(), width: 240),
};

/// 폭을 준다 — 입력창은 부모가 준 폭을 채우므로, 폭이 없는 부모 아래에
/// 두지 않는다.
Widget _sized(Widget child, {double width = 288}) => SizedBox(width: width, child: child);

/// 속성으로 그린다. 마스크나 값이 바뀌면 새 입력창으로 그린다
/// ([formattedInputPreviewKey]).
Widget _formattedInput(Map<String, String> props, String? label) {
  final preset = formattedInputPresetFor(props);
  return _sized(
    _field(
      preset,
      key: ValueKey(formattedInputPreviewKey(props)),
      value: formattedInputPreviewValue(props),
      leading: previewFlag(props, 'leading') ? docsFlutterIcon(preset.icon) : null,
      enabled: previewFlag(props, 'enabled', fallback: true),
    ),
  );
}

/// 프리셋의 입력창 — 기본 마스크는 그 생성자로, 나머지는 `parts` 로.
Widget _field(
  FormattedInputPreset preset, {
  Key? key,
  String? value,
  Widget? leading,
  Widget? trailing,
  bool enabled = true,
  CoreFormattedInputStyle? style,
}) => switch (preset.name) {
  'koreanPhone' => FormattedInput.koreanPhone(
    key: key,
    value: value,
    enabled: enabled,
    leading: leading,
    trailing: trailing,
    formattedInputStyle: style,
  ),
  'phone' => FormattedInput.phone(
    key: key,
    value: value,
    enabled: enabled,
    leading: leading,
    trailing: trailing,
    formattedInputStyle: style,
  ),
  'creditCard' => FormattedInput.creditCard(
    key: key,
    value: value,
    enabled: enabled,
    leading: leading,
    trailing: trailing,
    formattedInputStyle: style,
  ),
  'date' => FormattedInput.date(
    key: key,
    value: value,
    enabled: enabled,
    leading: leading,
    trailing: trailing,
    formattedInputStyle: style,
  ),
  _ => FormattedInput(
    parts: preset.parts,
    key: key,
    value: value,
    enabled: enabled,
    leading: leading,
    trailing: trailing,
    formattedInputStyle: style,
  ),
};

Widget _sendButton() => Button(
  variant: CoreButtonVariant.plain,
  size: CoreComponentSize.sm,
  onPressed: () {},
  child: const Text('인증번호 보내기'),
);

Widget _labelled() => FormField(
  label: '휴대폰 번호',
  description: '인증번호를 받을 번호입니다.',
  child: _field(formattedInputPresets.first),
);

/// 마스크 목록 — 프리셋마다 이름과 예시 값을 채운 입력창.
Widget _maskList() => SizedBox(
  width: 288,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space16,
    children: [
      for (final preset in formattedInputPresets)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CoreSpace.space6,
          children: [
            Text(preset.label).bodySmall.onSurfaceVariant,
            _field(preset, value: preset.example),
          ],
        ),
    ],
  ),
);

/// 상태 — 다섯 입력창. Focus 는 포커스 테두리 색을 Core 기본값에서 읽어 쉬는
/// 테두리와 Hover 테두리에 고정했다(포인터를 올려도 Focus 모양이 남는다).
Widget _formattedInputStates() {
  final preset = formattedInputPresets.first;
  return SizedBox(
    width: 240,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space12,
      children: [
        _field(preset),
        _field(preset, value: '0101'),
        _field(preset, value: preset.example),
        _field(preset, value: '0101234', style: formattedInputFocusLookStyle),
        _field(preset, value: preset.example, enabled: false),
      ],
    ),
  );
}
