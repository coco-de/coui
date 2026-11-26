/// InputOtp 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="input-otp/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`input_otp_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'input_otp_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _inputOtp;

/// 장면 이름(`input-otp/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 앞의 두 칸을 채워 채운 칸 · 빈 칸 · 구분 막대가 함께 보이게 한다.
  'input-otp/anatomy': () => InputOtp(initialValue: _digits('12')),
  'input-otp/variants': () => _captioned([
    ('defaultVariant', InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12'))),
    (
      'error',
      InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12'), errorText: inputOtpPreviewError),
    ),
  ]),
  'input-otp/states': _inputOtpStates,
  'input-otp/cell-height': () => _captioned([
    (
      'cellSize: 48',
      InputOtp(
        length: 4,
        separatorInterval: 0,
        initialValue: _digits('12'),
        inputOtpStyle: const CoreInputOtpStyle(cellSize: CoreSize.size48),
      ),
    ),
    (
      'cellSize: 48 · cellHeight: 56',
      InputOtp(
        length: 4,
        separatorInterval: 0,
        initialValue: _digits('12'),
        inputOtpStyle: const CoreInputOtpStyle(cellSize: CoreSize.size48, cellHeight: CoreSize.size56),
      ),
    ),
  ]),
};

/// Flutter 의 값은 문자 코드 목록이다 — `'1'` 은 49.
List<int?> _digits(String digits) => digits.codeUnits;

/// 속성으로 그린다. 처음 값 · 칸 수가 바뀌면 새로 그린다 — 입력창은 처음
/// 값을 마운트할 때 읽으므로(칸 수가 바뀔 때는 Flutter 도 다시 읽는다), 같은
/// 상태를 두면 처음 값 플래그를 바꿔도 칸이 그대로다. Web 과 같은 key 를 쓴다.
Widget _inputOtp(Map<String, String> props, String? label) {
  final initialValue = props['initialValue'];
  return InputOtp(
    key: ValueKey('${props['length']}|$initialValue'),
    size: previewEnum(CoreInputOtpSize.values, props['size'], CoreInputOtpSize.defaultSize),
    length: int.tryParse(props['length'] ?? '') ?? CoreInputOtpContract.defaultLength,
    separatorInterval: int.tryParse(props['separatorInterval'] ?? '') ?? CoreInputOtpContract.defaultSeparatorInterval,
    initialValue: initialValue == null ? null : _digits(initialValue),
    obscured: previewFlag(props, 'obscured'),
    allowCellEditing: previewFlag(props, 'allowCellEditing'),
    errorText: props['errorText'],
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

/// 상태 격자 — Web 과 같은 여섯 칸.
Widget _inputOtpStates() {
  Widget otp(String caption) => switch (caption) {
    '입력 중' => InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12')),
    '다 채움' => InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('1234')),
    '가림' => InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12'), obscured: true),
    '오류' => InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12'), errorText: inputOtpPreviewError),
    '비활성' => InputOtp(length: 4, separatorInterval: 0, initialValue: _digits('12'), enabled: false),
    _ => const InputOtp(length: 4, separatorInterval: 0),
  };
  return _captioned([for (final caption in inputOtpStateCaptions) (caption, otp(caption))]);
}

/// 이름을 단 입력창을 줄지어 놓는다 — Web 과 같은 폭(480) 안에서 줄바꿈한다.
Widget _captioned(List<(String, Widget)> items) => SizedBox(
  width: 480,
  child: Wrap(
    spacing: CoreSpace.space32,
    runSpacing: CoreSpace.space20,
    children: [
      for (final (caption, child) in items)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [Text(caption).labelSmall.onSurfaceVariant, child],
        ),
    ],
  ),
);
