/// Validated 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `validated_web.dart` · `validated_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Validated 가 직접 그리는 것은 메시지 한 줄뿐이고, 나머지는 감싼 필드에
/// 상태를 내려보내는 일이다. 그래서 플레이그라운드는 `state` 와 메시지를
/// 넘길지(`message`)만 바꾼다. 감싼 필드는 늘 같은 값의 입력창이라, 달라지는
/// 것이 상태 때문이라는 것이 보인다. 크기 · variant 축은 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/validated.md`.
const String slug = 'validated';

/// 플레이그라운드의 감싼 입력창 라벨 — 두 플랫폼 미리보기와 코드가 함께 쓴다.
const String validatedPreviewLabel = '닉네임';

/// 감싼 입력창의 처음 값.
const String validatedPreviewValue = 'coco';

/// `pending` 에 넘기는 메시지 — 넘겨도 그려지지 않는다.
const String validatedPendingMessage = '닉네임을 확인하고 있습니다.';

/// `valid` 의 메시지.
const String validatedValidMessage = '사용할 수 있는 닉네임입니다.';

/// `invalid` 의 메시지.
const String validatedInvalidMessage = '이미 사용 중인 닉네임입니다.';

/// `validated/propagation` 장면의 메시지.
const String validatedSceneRetryMessage = '다시 확인해 주세요.';

/// 좁은 카드 장면의 메시지 — 비어 있는 필수 항목.
const String validatedSceneRequiredMessage = '필수 항목입니다.';

/// 좁은 카드 장면의 메시지 — 형식 오류.
const String validatedSceneFormatMessage = '형식이 다릅니다.';

/// 좁은 카드 장면의 메시지 — 통과.
const String validatedSceneCheckedMessage = '확인했습니다.';

/// 필드마다 감싸기 · 묶어서 감싸기 장면에서 맞게 쓴 이름.
const String validatedSceneNameValue = '김코코';

/// `validated/dont-border-color` 장면이 입력창에 직접 주는 테두리 색.
const CoreTextFieldStyle validatedSceneErrorBorder = CoreTextFieldStyle(
  borderColor: CoreColor.token(CoreColors.error),
);

/// 상태마다 넘기는 메시지.
String validatedPreviewMessage(CoreValidationState state) => switch (state) {
  CoreValidationState.pending => validatedPendingMessage,
  CoreValidationState.valid => validatedValidMessage,
  CoreValidationState.invalid => validatedInvalidMessage,
};

/// 속성의 `state` → 상태. 없거나 모르는 값은 `invalid`.
CoreValidationState validatedPreviewState(Map<String, String> props) =>
    previewEnum(CoreValidationState.values, props['state'], CoreValidationState.invalid);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'state': 'invalid', 'message': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'state', prop: 'state', options: ['pending', 'valid', 'invalid'], segmented: true),
    DocsPlaygroundFlag(label: '메시지', on: {'message': 'true'}),
  ],
  code: _validatedCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Validated 에는 크기 행(`defaultsBySize`)이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _validatedCode(Map<String, String> props, String? label) {
  final state = validatedPreviewState(props);
  final lines = [
    'state: CoreValidationState.${state.name},',
    if (previewFlag(props, 'message')) "message: Text('${validatedPreviewMessage(state)}'),",
    "child: TextField(label: '$validatedPreviewLabel', initialValue: '$validatedPreviewValue'),",
  ];
  return 'Validated(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
