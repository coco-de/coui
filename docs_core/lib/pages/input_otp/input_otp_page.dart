/// InputOtp 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `input_otp_web.dart` · `input_otp_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/input-otp.md`.
const String slug = 'input-otp';

/// 미리보기 · 코드가 함께 쓰는 오류 문구.
const String inputOtpPreviewError = '인증번호가 일치하지 않습니다.';

/// 상태 격자의 칸 이름 — 두 플랫폼이 같은 순서로 그린다.
const List<String> inputOtpStateCaptions = ['비어 있음', '입력 중', '다 채움', '가림', '오류', '비활성'];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 처음 값은 앞의 세 칸을 채운다 — 플레이그라운드 무대는 카드 바탕(`surface`)
/// 이라 채운 칸(`surface`)은 테두리로만, 빈 칸(`surfaceContainerLow`)은 한 단계
/// 다른 채움으로 보인다. 둘을 함께 보이게 한다.
///
/// 값의 표현이 플랫폼마다 다르다(Flutter 는 문자 코드 목록, Web 은 문자열).
/// 그래서 `initialValue` 를 적는 줄만 갈리고, 그 때문에 [DocsPlaygroundSpec.webCode]
/// 를 둔다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'length': '6', 'separatorInterval': '3', 'initialValue': '123'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['md', 'lg'], segmented: true),
    DocsPlaygroundChoice(label: 'length', prop: 'length', options: ['4', '6', '8'], segmented: true),
    DocsPlaygroundChoice(
      label: 'separatorInterval',
      prop: 'separatorInterval',
      options: ['0', '2', '3', '4'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '처음 값', on: {'initialValue': '123'}),
    DocsPlaygroundFlag(label: '가림', on: {'obscured': 'true'}),
    DocsPlaygroundFlag(label: '칸 편집', on: {'allowCellEditing': 'true'}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': inputOtpPreviewError}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// InputOtp 의 크기는 자기 사다리(`CoreInputOtpSize`: md · lg)다. 표의 행은
/// `CoreComponentSize` 를 받으므로 같은 이름의 크기로 옮긴다.
DocsSizeSpec Function()? get sizeSpec => _inputOtpSpec;

String _flutterCode(Map<String, String> props, String? label) => _inputOtpCode(props, flutter: true);

String _webCode(Map<String, String> props, String? label) => _inputOtpCode(props, flutter: false);

String _inputOtpCode(Map<String, String> props, {required bool flutter}) {
  final separatorInterval = props['separatorInterval'];
  final initialValue = props['initialValue'];
  final lines = [
    "size: CoreInputOtpSize.${props['size'] ?? 'md'},",
    'length: ${props['length'] ?? CoreInputOtpContract.defaultLength},',
    if (separatorInterval != null && separatorInterval != '${CoreInputOtpContract.defaultSeparatorInterval}')
      'separatorInterval: $separatorInterval,',
    if (initialValue != null) flutter ? "initialValue: '$initialValue'.codeUnits," : "initialValue: '$initialValue',",
    if (previewFlag(props, 'obscured')) 'obscured: true,',
    if (previewFlag(props, 'allowCellEditing')) 'allowCellEditing: true,',
    if (props['errorText'] case final errorText?) "errorText: '$errorText',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onCompleted: verifyCode,',
  ];
  return 'InputOtp(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _inputOtpSpec() {
  // 숫자의 크기는 역할이, 굵기는 크기 행이 얹은 값이 정한다(`lg` 는
  // `headlineSmall` 위에 SemiBold 만 얹는다) — 역할만 풀면 굵기가 빠진다.
  String digit(CoreTextStyle style) {
    final role = docsSizeResolve(style)!;
    return docsSizeLabel(role.copyWith(fontWeight: style.fontWeight ?? role.fontWeight));
  }

  return DocsSizeSpec(
    columns: const ['size', '칸', '모서리', '숫자', '커서'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreInputOtpStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: CoreComponentSize.values.byName(size.name),
          cells: [
            '${docsSizeNumber(row.cellSize ?? CoreInputOtpStyle.defaultCellSize)} × '
                '${docsSizeNumber(row.cellHeight ?? row.cellSize ?? CoreInputOtpStyle.defaultCellHeight)}',
            docsSizeNumber((row.borderRadius ?? CoreInputOtpStyle.defaultBorderRadius).topLeft),
            digit(CoreInputOtpStyle.defaultTextStyle.merge(row.textStyle)),
            '${docsSizeNumber(row.caretWidth ?? CoreInputOtpStyle.defaultCaretWidth)} × '
                '${docsSizeNumber(row.caretHeight ?? CoreInputOtpStyle.defaultCaretHeight)}',
          ],
        ),
    ],
  );
}
