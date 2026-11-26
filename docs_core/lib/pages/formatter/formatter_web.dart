/// Formatter 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="formatter/...">` ·
/// `<Card demo>` 가 읽는다. 같은 이름의 Flutter 파일(`formatter_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'formatter_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _formatter;

/// 장면 이름(`formatter/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'formatter/samples': _samples,
  'formatter/related-text-field': () => _sized(const TextField(placeholder: Text('이름')), width: '12rem'),
  'formatter/related-formatted-input': () => _sized(
    const FormattedInput.koreanPhone(value: '01012345678'),
    width: '12rem',
  ),
  'formatter/related-number-input': () => _sized(const NumberInput(initialValue: 3, min: 1, max: 10), width: '10rem'),
};

Component _sized(Component child, {required String width}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 속성의 서식기를 단 입력창.
Component _formatter(Map<String, String> props, String? label) {
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
  return _sized(
    TextField(
      // 서식기를 바꾸면 입력창을 새로 만든다. 앞 서식기가 남긴 글자를 새 서식기가
      // 읽지 못하면(영문 뒤의 integerOnly 처럼) 한 글자씩 지우는 것도 거절된다.
      key: ValueKey('formatter-${kind.name}'),
      placeholder: Text(kind.placeholder),
      inputFormatters: kind.runsOnSubmit ? null : [formatter],
      submitFormatters: kind.runsOnSubmit ? [formatter] : const [],
    ),
    width: '17.5rem',
  );
}

/// 서식기마다 넣은 글자와 결과 — 결과는 서식기를 돌려 얻는다.
Component _samples() => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-12)', 'width': '18rem'}),
  [
    for (final sample in formatterSamples)
      div(
        styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-4)'}),
        [
          Text(sample.snippet).codeSm.onSurface,
          Text(sample.result).bodySmall.onSurfaceVariant,
        ],
      ),
  ],
);
