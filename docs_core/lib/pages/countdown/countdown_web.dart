/// Countdown 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="countdown/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`countdown_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/examples/web/countdown/countdown_units_example.dart';
import '../../previews/props/web_prop_previews.dart';
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

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _countdown;

/// 장면 이름(`countdown/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'countdown/related-progress': () => div(styles: Styles(raw: {'width': '12rem'}), [const Progress(value: 0.6)]),
  'countdown/related-stat': () => const Stat(label: '남은 좌석', value: '12', unit: '석'),
};

Component _countdown(Map<String, String> props, String? label) => Countdown(
  value: countdownPreviewValue(props),
  max: countdownPreviewMax(props),
  countdownStyle: countdownPreviewStyle(props),
);

/// 숫자마다 아래에 글을 단다 — 좁으면 줄이 바뀐다.
Component _captioned(List<(String, Component)> items) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-end',
      'gap': 'var(--coui-space-16) var(--coui-space-24)',
    },
  ),
  [
    for (final (caption, child) in items)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'center',
            'gap': 'var(--coui-space-4)',
          },
        ),
        [
          child,
          Text(caption).labelSmall.onSurfaceVariant,
        ],
      ),
  ],
);

/// 시 · 분 · 초 — 단위마다 하나씩 놓고 사이에 구분 글을 둔다.
Component _timeRow() => div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': 'var(--coui-space-4)'}),
  [
    for (final (index, value) in countdownTimeSample.indexed) ...[
      if (index > 0) const Text(':').headlineLarge,
      Countdown(value: value),
    ],
  ],
);

/// 숫자 앞뒤에 무엇이 남았는지 말하는 글을 둔다.
Component _withContext() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
    },
  ),
  [
    const Text(countdownContextBefore).bodyMedium,
    const Countdown(value: countdownContextValue),
    const Text(countdownContextAfter).bodyMedium,
  ],
);
