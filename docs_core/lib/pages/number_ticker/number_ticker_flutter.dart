/// NumberTicker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="number-ticker/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`number_ticker_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'number_ticker_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _numberTicker;

/// 장면 이름(`number-ticker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'number-ticker/formats': () => _column([
    for (final (index, (caption, value, formatter)) in numberTickerSceneFormats.indexed) ...[
      if (index > 0) const Gap.space12(),
      _row([
        SizedBox(width: CoreSpace.space128, child: Text(caption).labelSmall.onSurfaceVariant),
        NumberTicker(value: value, formatter: formatter),
      ]),
    ],
  ]),
  'number-ticker/builder': () => NumberTicker.builder(
    value: numberTickerSceneScore,
    child: Icon(LucideIcons.star),
    builder: (context, number, child) => _row([
      ?child,
      const Gap.space8(),
      Text('${number.round()}점').headlineSmall.onSurface,
    ]),
  ),
  'number-ticker/styles': () => _row([
    _captioned('기본', const NumberTicker(value: numberTickerSceneScore, formatter: numberTickerGrouped)),
    const Gap.space48(),
    _captioned(
      '역할과 색 바꿈',
      const NumberTicker(
        value: numberTickerSceneScore,
        formatter: numberTickerGrouped,
        numberTickerStyle: numberTickerSceneStyle,
      ),
    ),
  ]),
  'number-ticker/placement': () => SizedBox(
    width: CoreSpace.space200,
    child: _column(stretch: true, [
      for (final (index, (name, value)) in numberTickerSceneMetrics.indexed) ...[
        if (index > 0) const Gap.space8(),
        Row(
          children: [
            Expanded(child: Text(name).bodyMedium.onSurfaceVariant),
            NumberTicker(value: value, formatter: numberTickerGrouped),
          ],
        ),
      ],
    ]),
  ),
  'number-ticker/do-format': () => const NumberTicker(
    value: numberTickerSceneAmount,
    formatter: numberTickerWon,
    numberTickerStyle: numberTickerSceneCardStyle,
  ),
  'number-ticker/dont-format': () => const NumberTicker(
    value: numberTickerSceneAmount,
    numberTickerStyle: numberTickerSceneCardStyle,
  ),
  'number-ticker/related-stat': () => const SizedBox(
    width: CoreSpace.space200,
    child: Stat(label: '방문자', value: '12,480'),
  ),
  'number-ticker/related-countdown': () => const Countdown(value: 42),
  'number-ticker/related-progress': () => const SizedBox(width: CoreSpace.space160, child: Progress(value: 0.65)),
};

Widget _numberTicker(Map<String, String> props, String? label) => NumberTicker(
  key: ValueKey(numberTickerPreviewKey(props)),
  value: numberTickerPreviewValue(props),
  initialValue: numberTickerPreviewInitialValue(props),
  formatter: numberTickerPreviewFormatter(props),
  curve: numberTickerPreviewCurve(props),
  numberTickerStyle: numberTickerPreviewStyle(props),
);

/// 가로로 놓는다 — 내용만큼만 차지한다.
Widget _row(List<Widget> children) => Row(mainAxisSize: MainAxisSize.min, children: children);

/// 세로로 쌓는다. [stretch] 면 자식이 폭을 다 쓴다.
Widget _column(List<Widget> children, {bool stretch = false}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
  children: children,
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) =>
    _column([Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child]);
