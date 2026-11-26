/// FormattedInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="formatted-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Flutter 파일
/// (`formatted_input_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'formatted_input_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _formattedInput;

/// 장면 이름(`formatted-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 앞 아이콘 · 값 · 뒤 버튼이 모두 보이게 채운다.
  'formatted-input/anatomy': () => _sized(
    _field(
      formattedInputPresets.first,
      value: formattedInputPresets.first.example,
      leading: const Icon(LucideIcons.smartphone, attributes: {'data-docs-part': 'leading'}),
      trailing: _sendButton(),
    ),
    width: '20rem',
  ),
  'formatted-input/masks': _maskList,
  'formatted-input/states': _formattedInputStates,
  'formatted-input/trailing-action': () => _sized(
    _field(formattedInputPresets.first, trailing: _sendButton()),
    width: '20rem',
  ),
  'formatted-input/do-form-field': () => _sized(_labelled(), width: '16rem'),
  'formatted-input/dont-bare-mask': () => _sized(_field(formattedInputPresets.first), width: '16rem'),
  'formatted-input/do-iso-date': () => _sized(
    const FormattedInput(parts: formattedInputIsoDateParts, value: formattedInputIsoDateExample),
    width: '16rem',
  ),
  'formatted-input/dont-us-date': () => _sized(
    const FormattedInput.date(value: formattedInputIsoDateExample),
    width: '16rem',
  ),
  'formatted-input/related-input-otp': () => const InputOtp(length: 4, separatorInterval: 0, initialValue: '12'),
  'formatted-input/related-form-field': () => _sized(_labelled(), width: '15rem'),
};

Component _sized(Component child, {String width = '18rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 속성으로 그린다. 마스크나 값이 바뀌면 새 입력창으로 그린다
/// ([formattedInputPreviewKey]).
Component _formattedInput(Map<String, String> props, String? label) {
  final preset = formattedInputPresetFor(props);
  return _sized(
    _field(
      preset,
      key: ValueKey(formattedInputPreviewKey(props)),
      value: formattedInputPreviewValue(props),
      leading: previewFlag(props, 'leading') ? docsWebIcon(preset.icon) : null,
      enabled: previewFlag(props, 'enabled', fallback: true),
    ),
  );
}

/// 프리셋의 입력창 — 기본 마스크는 그 생성자로, 나머지는 `parts` 로.
Component _field(
  FormattedInputPreset preset, {
  Key? key,
  String? value,
  Component? leading,
  Component? trailing,
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

Component _sendButton() => Button(
  variant: CoreButtonVariant.plain,
  size: CoreComponentSize.sm,
  onPressed: () {},
  child: const Text('인증번호 보내기'),
);

Component _labelled() => FormField(
  label: '휴대폰 번호',
  description: '인증번호를 받을 번호입니다.',
  child: _field(formattedInputPresets.first),
);

/// 마스크 목록 — 프리셋마다 이름과 예시 값을 채운 입력창.
Component _maskList() => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-16)', 'width': '18rem'}),
  [
    for (final preset in formattedInputPresets)
      div(
        styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-6)'}),
        [
          Text(preset.label).bodySmall.onSurfaceVariant,
          _field(preset, value: preset.example),
        ],
      ),
  ],
);

/// 상태 격자 — 다섯 칸 모두 실제 입력창이다. Focus 칸은 포커스 테두리 색을
/// Core 기본값에서 읽어 쉬는 테두리와 Hover 테두리에 고정했다(포인터나 키보드
/// 없이 포커스를 켤 수 없고, Hover 테두리까지 고정해야 포인터를 올려도 Focus
/// 모양이 남는다).
Component _formattedInputStates() {
  const columns = ['빈 칸', '입력 중', '다 채움', 'Focus', '비활성'];
  final preset = formattedInputPresets.first;
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
      '입력 중' => _field(preset, value: '0101'),
      '다 채움' => _field(preset, value: preset.example),
      'Focus' => _field(preset, value: '0101234', style: formattedInputFocusLookStyle),
      '비활성' => _field(preset, value: preset.example, enabled: false),
      _ => _field(preset),
    },
  ]);
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
