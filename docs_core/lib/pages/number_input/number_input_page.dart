/// NumberInput 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `number_input_web.dart` · `number_input_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 범위 · 값 · 글자는 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/number-input.md`.
const String slug = 'number-input';

/// 미리보기의 가장 작은 값.
const double numberInputPreviewMin = 1;

/// 미리보기의 가장 큰 값.
const double numberInputPreviewMax = 8;

/// 미리보기가 값을 말하지 않을 때의 값.
const double numberInputPreviewValue = 2;

/// 미리보기의 라벨.
const String numberInputPreviewLabel = '인원';

/// 미리보기의 도움말.
const String numberInputPreviewDescription = '최대 8명까지 예약할 수 있어요';

/// 플레이그라운드의 오류 문구.
const String numberInputPreviewError = '8명을 넘길 수 없어요';

/// 상태 격자의 오류 문구 — 좁은 칸에 들어가는 짧은 글.
const String numberInputStatesError = '자리가 부족해요';

/// 속성 `value` 를 미리보기의 값으로 읽는다 — 없거나 숫자가 아니면
/// [numberInputPreviewValue].
double numberInputPreviewValueOf(Map<String, String> props) =>
    double.tryParse(props['value'] ?? '') ?? numberInputPreviewValue;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `error` variant 는 고르지 않는다 — `errorText` 를 주면 같은 오류 모양이
/// 켜지므로 오류는 켜고 끄는 컨트롤이다. 처음 variant 는 기본값이다 —
/// 플레이그라운드 무대와 채움은 같은 `surface` 지만 테두리로 경계가 보인다.
/// 미리보기는
/// `value` 로 값을 넘긴다 — 컨트롤을 바꾸면 같은 자리의 NumberInput 이 새
/// 값을 받아야 하는데, `initialValue` 는 처음 한 번만 읽힌다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'variant': 'defaultVariant', 'size': 'md', 'label': numberInputPreviewLabel},
  controls: [
    const DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: ['defaultVariant', 'filled'],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundFlag(label: '최댓값', on: {'value': CoreNumberInputMath.format(numberInputPreviewMax)}),
    const DocsPlaygroundFlag(label: '도움말', on: {'description': numberInputPreviewDescription}),
    const DocsPlaygroundFlag(label: '오류', on: {'errorText': numberInputPreviewError}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _numberInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// NumberInput 의 크기는 자기 사다리(`CoreNumberInputSize`: sm · md · lg)다.
/// 필드는 같은 이름의 TextField 행을, 양 끝 버튼은 한 단 아래의 Button 행을
/// 쓴다 — 그래서 각 열을 그 행에서 읽는다. 폭은 NumberInput 자신의 행이다.
DocsSizeSpec Function()? get sizeSpec => _numberInputSpec;

String _numberInputCode(Map<String, String> props, String? label) {
  String? quoted(String key) => props[key] == null ? null : "'${props[key]}'";
  final lines = [
    'value: ${CoreNumberInputMath.format(numberInputPreviewValueOf(props))},',
    'min: ${CoreNumberInputMath.format(numberInputPreviewMin)},',
    'max: ${CoreNumberInputMath.format(numberInputPreviewMax)},',
    if (props['variant'] != null && props['variant'] != 'defaultVariant')
      'variant: CoreNumberInputVariant.${props['variant']},',
    "size: CoreNumberInputSize.${props['size'] ?? 'md'},",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (quoted('label') case final v?) 'label: $v,',
    if (quoted('description') case final v?) 'description: $v,',
    if (quoted('errorText') case final v?) 'errorText: $v,',
    'onChanged: setGuests,',
  ];
  return 'NumberInput(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _numberInputSpec() {
  return DocsSizeSpec(
    columns: const ['size', '필드 (너비 × 높이)', '버튼 · 글리프', '모서리 (필드 · 버튼)'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreNumberInputStyle.defaultsBySize.entries)
        if ((
              CoreTextFieldStyle.defaultsBySize[size.toComponentSize()]!,
              CoreButtonStyle.defaultsBySize[size.toStepButtonSize()]!,
            )
            case (final field, final button))
          DocsSizeSpecRow(
            size: size.toComponentSize(),
            cells: [
              '${docsSizeNumber(row.width)} × ${docsSizeNumber(field.minHeight)}',
              '${docsSizeNumber(button.height)} · ${docsSizeNumber(button.iconShapeIconStyle?.size)}',
              '${docsSizeNumber(field.borderRadius?.topLeft)} · ${docsSizeNumber(button.borderRadius?.topLeft)}',
            ],
          ),
    ],
  );
}
