/// ValidatorHint 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<Card props>` ·
/// 플레이그라운드가, 장면은 `<Preview demo="validator-hint/...">` · `<Card demo>`
/// 가 읽는다. 같은 이름의 Web 파일(`validator_hint_web.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'validator_hint_page.dart';

/// 속성 → Widget.
///
/// 태그의 `label` 이 메시지가 된다. `icon=lock` 이면 기본 아이콘 대신 크기를
/// 적은 자물쇠 아이콘을 넘긴다.
FlutterPropPreviewBuilder? get propPreview => _validatorHint;

/// 장면 이름(`validator-hint/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'validator-hint/anatomy': () => const ValidatorHint.error(message: Text(validatorHintMessage)),
  'validator-hint/checklist': _checklist,
  'validator-hint/placement-checkbox': () => _column([
    Checkbox(checked: false, onChanged: (_) {}, label: validatorHintAgreementLabel),
    const ValidatorHint.error(message: Text(validatorHintAgreementError)),
  ]),
  'validator-hint/do-type': () => const ValidatorHint.success(message: Text(validatorHintSavedMessage)),
  'validator-hint/dont-type': () => const ValidatorHint(message: Text(validatorHintSavedMessage)),
  'validator-hint/do-wording': () => const ValidatorHint.error(message: Text(validatorHintClearMessage)),
  'validator-hint/dont-wording': () => const ValidatorHint.error(message: Text(validatorHintVagueMessage)),
  'validator-hint/do-pending': () => _column([
    for (final rule in validatorHintRules) ValidatorHint.neutral(message: Text(rule)),
  ]),
  'validator-hint/dont-pending': () => _column([
    for (final rule in validatorHintRules) ValidatorHint.info(message: Text(rule)),
  ]),
  // Flutter 의 TextField 생성자는 const 가 아니라 두 카드는 const 를 붙이지 않는다.
  'validator-hint/related-validated': () => _sized(
    Validated(
      state: CoreValidationState.invalid,
      message: const Text('다시 확인해 주세요'),
      child: TextField(initialValue: 'coui'),
    ),
  ),
  'validator-hint/related-form-field': () => _sized(
    FormField(
      label: '이메일',
      error: '형식이 아니에요',
      child: TextField(initialValue: 'coui'),
    ),
  ),
  'validator-hint/related-validation-badge': () =>
      const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
};

/// `icon` 속성이 켜졌을 때 넘기는 아이콘.
const Widget _customIcon = Icon(LucideIcons.lock, iconStyle: CoreIconStyle(size: CoreIconSize.size16));

Widget _validatorHint(Map<String, String> props, String? label) => ValidatorHint(
  type: previewEnum(CoreValidatorHintType.values, props['type'], CoreValidatorHintType.defaultType),
  visible: previewFlag(props, 'visible', fallback: true),
  icon: props['icon'] == validatorHintCustomIcon ? _customIcon : null,
  message: Text(label ?? validatorHintMessage),
);

/// 규칙 목록 — 입력 전과 일부를 채운 뒤를 나란히 놓는다.
Widget _checklist() => Wrap(
  spacing: CoreSpace.space32,
  runSpacing: CoreSpace.space16,
  children: [_captioned('입력 전', _rules(0)), _captioned('하나를 채운 뒤', _rules(1))],
);

/// 앞에서 [met] 개만 채운 규칙 목록.
Widget _rules(int met) => _column([
  for (final (index, rule) in validatorHintRules.indexed)
    ValidatorHint(
      type: index < met ? CoreValidatorHintType.success : CoreValidatorHintType.neutral,
      message: Text(rule),
    ),
]);

Widget _captioned(String caption, Widget child) => _column([Text(caption).labelSmall.onSurfaceVariant, child]);

/// 위에서 아래로 쌓는다 — Web 장면의 세로 flex 와 같은 간격 4.
Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space4,
  children: children,
);

/// 입력창이 든 관련 카드의 폭 — Web 장면의 11rem 과 같은 176.
Widget _sized(Widget child) => SizedBox(width: 176, child: child);
