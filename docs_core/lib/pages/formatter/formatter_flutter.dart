/// Formatter 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="formatter/...">` ·
/// `<Card demo>` 가 읽는다. 같은 이름의 Web 파일(`formatter_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'formatter_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _formatter;

/// 장면 이름(`formatter/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'formatter/samples': _samples,
  'formatter/related-text-field': () => SizedBox(width: 192, child: TextField(placeholder: Text('이름'))),
  'formatter/related-formatted-input': () => SizedBox(
    width: 192,
    child: FormattedInput.koreanPhone(value: '01012345678'),
  ),
  'formatter/related-number-input': () => SizedBox(width: 160, child: NumberInput(initialValue: 3, min: 1, max: 10)),
};

/// 속성의 서식기를 단 입력창.
Widget _formatter(Map<String, String> props, String? label) {
  final kind = formatterPreviewKindOf(props);
  final formatter = switch (kind) {
    FormatterPreviewKind.integerOnly => TextInputFormatters.integerOnly(
      min: formatterPreviewMin,
      max: formatterPreviewMax,
    ),
    FormatterPreviewKind.decimalOnly => TextInputFormatters.decimalOnly(decimalDigits: formatterPreviewDecimalDigits),
    FormatterPreviewKind.toUpperCase => TextInputFormatters.toUpperCase(),
    FormatterPreviewKind.toLowerCase => TextInputFormatters.toLowerCase(),
    FormatterPreviewKind.time => TextInputFormatters.time(length: formatterPreviewTimeLength),
    FormatterPreviewKind.mathExpression => TextInputFormatters.mathExpression(),
  };
  return SizedBox(
    width: 280,
    child: TextField(
      // 서식기를 바꾸면 입력창을 새로 만든다. 앞 서식기가 남긴 글자를 새 서식기가
      // 읽지 못하면(영문 뒤의 integerOnly 처럼) 한 글자씩 지우는 것도 거절된다.
      key: ValueKey('formatter-${kind.name}'),
      placeholder: Text(kind.placeholder),
      inputFormatters: kind.runsOnSubmit ? null : [formatter],
      submitFormatters: kind.runsOnSubmit ? [formatter] : const [],
    ),
  );
}

/// 서식기마다 넣은 글자와 결과 — Web 과 같은 줄.
Widget _samples() => SizedBox(
  width: 288,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space12,
    children: [
      for (final sample in formatterSamples)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space4,
          children: [
            Text(sample.snippet).codeSm.onSurface,
            Text(sample.result).bodySmall.onSurfaceVariant,
          ],
        ),
    ],
  ),
);
