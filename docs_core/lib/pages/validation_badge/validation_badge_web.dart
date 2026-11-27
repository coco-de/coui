/// ValidationBadge 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="validation-badge/...">` · `<Card demo>` · `<Anatomy demo>`
/// 가 읽는다. 같은 이름의 Flutter 파일(`validation_badge_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'validation_badge_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _validationBadge;

/// 장면 이름(`validation-badge/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'validation-badge/anatomy': () => const ValidationBadge(
    label: page.validationBadgeSampleLabel,
    state: CoreValidationState.valid,
    size: CoreValidationBadgeSize.medium,
  ),
  'validation-badge/with-pending': () => _spread([
    _captioned('입력 전', _rules('')),
    _captioned("'${page.validationBadgeSamplePassword}' 입력 뒤", _rules(page.validationBadgeSamplePassword)),
  ]),
  'validation-badge/custom-icons': () => _spread([
    for (final state in CoreValidationState.values)
      ValidationBadge(
        label: page.validationBadgeStateWords[state]!,
        state: state,
        pendingIcon: page.validationBadgeCustomIcons[CoreValidationState.pending],
        validIcon: page.validationBadgeCustomIcons[CoreValidationState.valid],
        invalidIcon: page.validationBadgeCustomIcons[CoreValidationState.invalid],
      ),
  ]),
  'validation-badge/do-pending': () => _column([
    for (final rule in page.validationBadgeFewRules) ValidationBadge(label: rule, state: CoreValidationState.pending),
  ]),
  'validation-badge/dont-pending': () => _column([
    for (final rule in page.validationBadgeFewRules) ValidationBadge(label: rule, state: CoreValidationState.invalid),
  ]),
  'validation-badge/do-wording': () => _column([
    for (final (state, label) in page.validationBadgeClearSamples) ValidationBadge(label: label, state: state),
  ]),
  'validation-badge/dont-wording': () => _column([
    for (final (state, label) in page.validationBadgeVagueSamples) ValidationBadge(label: label, state: state),
  ]),
  'validation-badge/do-count': () => _column([
    for (final rule in page.validationBadgeFewRules) ValidationBadge(label: rule, state: CoreValidationState.pending),
  ]),
  'validation-badge/dont-count': () => _column([
    for (final rule in page.validationBadgeManyRules) ValidationBadge(label: rule, state: CoreValidationState.pending),
  ]),
  'validation-badge/checklist': () => _rules(page.validationBadgeSamplePassword),
  'validation-badge/with-field': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--coui-space-12)',
        'width': pinnedLengthCss(CoreSpace.space240),
      },
    ),
    [
      const TextField(
        label: '새 비밀번호',
        obscureText: true,
        readOnly: true,
        initialValue: page.validationBadgeSamplePassword,
      ),
      _rules(page.validationBadgeSamplePassword),
    ],
  ),
  'validation-badge/long-label': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(page.validationBadgeNarrowWidth)}),
    [const ValidationBadge(label: page.validationBadgeLongLabel, state: CoreValidationState.invalid)],
  ),
  'validation-badge/state-words': () => _column([
    for (final state in CoreValidationState.values)
      ValidationBadge(
        label: page.validationBadgeStateLabel(page.validationBadgeSampleLabel, state),
        state: state,
      ),
  ]),
  'validation-badge/related-validator-hint': () => const ValidatorHint.error(message: Text('8자 이상 입력해 주세요.')),
  'validation-badge/related-text-field': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(CoreSpace.space176)}),
    [const TextField(label: '새 비밀번호', errorText: '8자 이상 입력해 주세요.')],
  ),
  'validation-badge/related-status': () => Status(variant: CoreStatusVariant.online, label: const Text('온라인')),
  'validation-badge/related-badge': () => const Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
};

Component _validationBadge(Map<String, String> props, String? label) {
  final custom = previewFlag(props, 'customIcon');
  return ValidationBadge(
    label: page.validationBadgePreviewLabel(props, label),
    state: page.validationBadgePreviewState(props),
    size: page.validationBadgePreviewSize(props),
    pendingIcon: custom ? page.validationBadgeCustomIcons[CoreValidationState.pending] : null,
    validIcon: custom ? page.validationBadgeCustomIcons[CoreValidationState.valid] : null,
    invalidIcon: custom ? page.validationBadgeCustomIcons[CoreValidationState.invalid] : null,
    style: previewFlag(props, 'bordered') ? page.validationBadgeBorderStyle : null,
  );
}

/// [password] 를 입력한 때의 규칙 목록 — 빈 글이면 모두 pending 이다.
Component _rules(String password) => _column([
  for (final (rule, met) in page.validationBadgeRules(password))
    ValidationBadge.withPending(label: rule, hasInput: password.isNotEmpty, isValid: met),
]);

/// 위에서 아래로 쌓는다. 앞을 맞춰 배지가 내용 폭을 갖게 한다.
Component _column(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-8)',
    },
  ),
  children,
);

/// 나란히 놓는다 — 좁으면 다음 줄로 넘어간다.
Component _spread(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'column-gap': 'var(--coui-space-32)',
      'row-gap': 'var(--coui-space-12)',
    },
  ),
  children,
);

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => _column([Text(caption).labelSmall.onSurfaceVariant, child]);
