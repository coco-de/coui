/// Countdown 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="countdown/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`countdown_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/examples/flutter/countdown/countdown_units_example.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'countdown_page.dart'
    show
        countdownContextAfter,
        countdownContextBefore,
        countdownContextValue,
        countdownPreviewMax,
        countdownPreviewStyle,
        countdownPreviewValue,
        countdownRangeSamples,
        countdownStyleSamples,
        countdownTimeSample,
        countdownTotalSecondsMax,
        countdownTotalSecondsSample;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _countdown;

/// 장면 이름(`countdown/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'countdown/range': () => _captioned([
    for (final (caption, value, max) in countdownRangeSamples) (caption, Countdown(value: value, max: max)),
  ]),
  'countdown/time-row': _timeRow,
  // 네 단위 조합은 실행 가능한 예제 그대로 그린다 — 본문이 연결하는 소스와
  // 화면이 갈라지지 않는다.
  'countdown/units': () => const CountdownUnitsExample(),
  'countdown/styles': () => _captioned([
    for (final (caption, style) in countdownStyleSamples) (caption, Countdown(value: 42, countdownStyle: style)),
  ]),
  'countdown/dont-total-seconds': () =>
      const Countdown(value: countdownTotalSecondsSample, max: countdownTotalSecondsMax),
  'countdown/do-max': () => _captioned([('value: 120, max: 365', const Countdown(value: 120, max: 365))]),
  'countdown/dont-clamped': () => _captioned([('value: 120', const Countdown(value: 120))]),
  'countdown/do-context': _withContext,
  'countdown/dont-bare': () => const Countdown(value: countdownContextValue),
  'countdown/related-number-ticker': () => const NumberTicker(value: 1234),
  'countdown/related-progress': () => const SizedBox(width: CoreSpace.space192, child: Progress(value: 0.6)),
  'countdown/related-stat': () => const Stat(label: '남은 좌석', value: '12', unit: '석'),
};

Widget _countdown(Map<String, String> props, String? label) => Countdown(
  value: countdownPreviewValue(props),
  max: countdownPreviewMax(props),
  countdownStyle: countdownPreviewStyle(props),
);

/// 숫자마다 아래에 글을 단다 — 좁으면 줄이 바뀐다.
Widget _captioned(List<(String, Widget)> items) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.end,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space16,
  children: [
    for (final (caption, child) in items)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space4,
        children: [child, Text(caption).labelSmall.onSurfaceVariant],
      ),
  ],
);

/// 시 · 분 · 초 — 단위마다 하나씩 놓고 사이에 구분 글을 둔다.
Widget _timeRow() => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space4,
  children: [
    for (final (index, value) in countdownTimeSample.indexed) ...[
      if (index > 0) const Text(':').headlineLarge,
      Countdown(value: value),
    ],
  ],
);

/// 숫자 앞뒤에 무엇이 남았는지 말하는 글을 둔다.
Widget _withContext() => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: CoreSpace.space8,
  children: [
    const Text(countdownContextBefore).bodyMedium,
    const Countdown(value: countdownContextValue),
    const Text(countdownContextAfter).bodyMedium,
  ],
);
