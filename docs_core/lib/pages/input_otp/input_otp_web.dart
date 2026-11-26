/// InputOtp 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="input-otp/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`input_otp_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'input_otp_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _inputOtp;

/// 장면 이름(`input-otp/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 앞의 두 칸을 채워 채운 칸 · 빈 칸 · 구분 막대가 함께 보이게 한다.
  'input-otp/anatomy': () => const InputOtp(initialValue: '12'),
  'input-otp/variants': () => _captioned([
    ('defaultVariant', const InputOtp(length: 4, separatorInterval: 0, initialValue: '12')),
    (
      'error',
      const InputOtp(length: 4, separatorInterval: 0, initialValue: '12', errorText: inputOtpPreviewError),
    ),
  ]),
  'input-otp/states': _inputOtpStates,
  'input-otp/cell-height': () => _captioned([
    (
      'cellSize: 48',
      const InputOtp(
        length: 4,
        separatorInterval: 0,
        initialValue: '12',
        inputOtpStyle: CoreInputOtpStyle(cellSize: CoreSize.size48),
      ),
    ),
    (
      'cellSize: 48 · cellHeight: 56',
      const InputOtp(
        length: 4,
        separatorInterval: 0,
        initialValue: '12',
        inputOtpStyle: CoreInputOtpStyle(cellSize: CoreSize.size48, cellHeight: CoreSize.size56),
      ),
    ),
  ]),
};

/// 속성으로 그린다. 처음 값 · 칸 수가 바뀌면 새로 그린다 — Web 의 입력창은
/// 처음 값을 마운트할 때만 읽고 칸 수가 바뀌어도 입력을 비우지 않으므로, 같은
/// 상태를 두면 컨트롤을 바꿔도 칸이 그대로다.
Component _inputOtp(Map<String, String> props, String? label) {
  final initialValue = props['initialValue'];
  return InputOtp(
    key: ValueKey('${props['length']}|$initialValue'),
    size: previewEnum(CoreInputOtpSize.values, props['size'], CoreInputOtpSize.defaultSize),
    length: int.tryParse(props['length'] ?? '') ?? CoreInputOtpContract.defaultLength,
    separatorInterval: int.tryParse(props['separatorInterval'] ?? '') ?? CoreInputOtpContract.defaultSeparatorInterval,
    initialValue: initialValue,
    obscured: previewFlag(props, 'obscured'),
    allowCellEditing: previewFlag(props, 'allowCellEditing'),
    errorText: props['errorText'],
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

/// 상태 격자 — 여섯 칸 모두 실제 입력창이다. 포커스 · hover 는 브라우저가
/// 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _inputOtpStates() {
  Component otp(String caption) => switch (caption) {
    '입력 중' => const InputOtp(length: 4, separatorInterval: 0, initialValue: '12'),
    '다 채움' => const InputOtp(length: 4, separatorInterval: 0, initialValue: '1234'),
    '가림' => const InputOtp(length: 4, separatorInterval: 0, initialValue: '12', obscured: true),
    '오류' => const InputOtp(length: 4, separatorInterval: 0, initialValue: '12', errorText: inputOtpPreviewError),
    '비활성' => const InputOtp(length: 4, separatorInterval: 0, initialValue: '12', enabled: false),
    _ => const InputOtp(length: 4, separatorInterval: 0),
  };
  return _captioned([for (final caption in inputOtpStateCaptions) (caption, otp(caption))]);
}

/// 이름을 단 입력창을 줄지어 놓는다 — 폭 30rem 안에서 줄바꿈해 넓은 화면에서는
/// 두 개씩, 좁은 화면에서는 하나씩 놓인다(Flutter 의 `Wrap` 과 같은 폭).
Component _captioned(List<(String, Component)> items) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-20) var(--coui-space-32)',
      'max-width': '30rem',
    },
  ),
  [
    for (final (caption, child) in items)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'flex-start',
            'gap': 'var(--coui-space-8)',
          },
        ),
        [
          span([Text(caption).labelSmall.onSurfaceVariant]),
          child,
        ],
      ),
  ],
);
