/// ValidatorHint 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `validator_hint_web.dart` · `validator_hint_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/validator-hint.md`.
const String slug = 'validator-hint';

/// 플레이그라운드 · 구조 장면에 처음 보이는 메시지.
const String validatorHintMessage = '비밀번호는 8자 이상이어야 합니다.';

/// `icon` 속성에서 읽는 이름 — 이 이름이면 기본 아이콘 대신 자물쇠를 넘긴다.
///
/// 두 플랫폼 빌더는 크기를 적은 `Icon` 을 넘긴다. Web 힌트는 직접 넘긴
/// 아이콘에 자기 아이콘 크기를 내려 주지 않아, 크기를 비우면 Flutter 와 다른
/// 크기로 그려진다.
const String validatorHintCustomIcon = 'lock';

/// 규칙 목록 장면의 규칙 이름.
const List<String> validatorHintRules = ['8자 이상', '숫자 포함', '특수 문자 포함'];

/// 배치 장면의 체크박스 라벨과 그 아래 오류 문구.
const String validatorHintAgreementLabel = '약관에 동의합니다';
const String validatorHintAgreementError = '약관에 동의해 주세요.';

/// type 을 적는 것과 빼는 것을 견주는 카드의 성공 문구.
const String validatorHintSavedMessage = '저장했어요';

/// 문구를 견주는 카드 — 무엇을 해야 하는지 말하는 것과 말하지 않는 것.
const String validatorHintClearMessage = '16자리를 입력해 주세요';
const String validatorHintVagueMessage = '확인해 주세요';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 크기 축이 없어 크기 컨트롤은 없다. type 선택지는 Core 의 enum 에서
/// 읽는다 — 값이 늘거나 줄면 컨트롤이 함께 따라온다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: {'type': CoreValidatorHintType.defaultType.name},
  label: validatorHintMessage,
  controls: [
    DocsPlaygroundChoice(
      label: 'type',
      prop: 'type',
      options: [for (final type in CoreValidatorHintType.values) type.name],
    ),
    const DocsPlaygroundFlag(label: '아이콘 바꾸기', on: {'icon': validatorHintCustomIcon}),
    const DocsPlaygroundFlag(label: '숨기기', on: {'visible': 'false'}),
  ],
  code: _validatorHintCode,
);

/// 크기 표. ValidatorHint 는 크기 축이 없다 — `CoreValidatorHintStyle` 에
/// `defaultsBySize` 가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 → 코드. type 은 이름 있는 생성자로 적는다.
String _validatorHintCode(Map<String, String> props, String? label) {
  final type = previewEnum(CoreValidatorHintType.values, props['type'], CoreValidatorHintType.defaultType);
  final message = (label ?? validatorHintMessage).replaceAll("'", r"\'");
  final lines = [
    "message: Text('$message'),",
    if (!previewFlag(props, 'visible', fallback: true)) 'visible: false,',
    if (props['icon'] == validatorHintCustomIcon) ...[
      'icon: Icon(',
      '  LucideIcons.${docsIconIdentifier(validatorHintCustomIcon)},',
      '  iconStyle: CoreIconStyle(size: CoreIconSize.size16),',
      '),',
    ],
  ];
  return 'ValidatorHint.${type.name}(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
