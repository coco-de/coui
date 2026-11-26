/// 사이트가 쓰는 모션 어휘 — 값은 전부 `coui_core` 의 alias 에서 온다.
///
/// ## 왜 한 곳인가
///
/// 사이트의 움직임은 세 군데에서 일어난다 — 스타일시트의 `transition` /
/// `animation`, 정적 스크립트(`web/docs-shell.js` · `web/docs-landing.js`)의
/// 타이머와 숫자 굴림, 그리고 그 안에 놓인 CoUI 컴포넌트 자신의 전환. 앞의
/// 둘이 `150ms` 나 `ease-out` 을 각자 적으면 같은 화면에 시계가 둘이 되고,
/// 동작 줄이기는 그중 변수를 거친 쪽에만 닿는다.
///
/// 그래서 이 파일이 `--site-duration-*` · `--site-easing-*` 를 **한 번**
/// 선언하고, 스타일시트와 스크립트는 그 이름만 읽는다. 각 이름은 Core 의
/// 시맨틱 alias 하나를 가리키고(`fast` → `CoreDuration.fast`), 값은
/// `--coui-duration-*` · `--easing-*` 변수 참조로 나간다 — 그래서
/// `prefers-reduced-motion` 이 그 변수를 0 으로 줄이면 사이트의 전환도
/// 같이 0 이 된다. 사이트 쪽에는 그 설정을 읽는 코드가 없다.
///
/// 표시 시간(`hold`)은 전환이 아니라 "얼마나 머무르나" 라서 alias 가 없고
/// raw 단계를 가리킨다. 동작 줄이기가 켜져도 그대로 남는다.
library;

import 'package:coui_web/coui_web.dart' show CoreCubicBezierToVarCss, CoreDuration, CoreEasing, durationMsCss;

/// 순차 등장에서 한 항목과 다음 항목 사이의 간격.
const int kSiteStaggerStepMs = CoreDuration.ms50;

/// 순차 등장에서 한 항목이 들어오는 데 걸리는 시간.
const int kSiteRevealMs = CoreDuration.moderate;

/// 한 시퀀스에서 지연이 더 늘지 않는 마지막 순번(0 부터).
///
/// 순차 등장은 **총합**이 [CoreDuration.slow] 를 넘지 않아야 한다 —
/// 마지막 항목의 지연에 한 항목의 길이를 더한 값이다. 항목 수는 화면마다
/// 다르므로, 간격이 아니라 순번을 여기서 자른다: 이 순번을 넘는 항목은
/// 마지막 항목과 같이 들어온다.
const int kSiteStaggerLastIndex = (CoreDuration.slow - kSiteRevealMs) ~/ kSiteStaggerStepMs;

/// 문서 요소에 선언하는 모션 어휘 — 헤더 · 사이드바 · 본문이 함께 읽는다.
///
/// 문서 요소인 이유는 페이지 사이의 전환이다. `::view-transition-*` 은 문서
/// 요소의 가상 요소라, 그보다 안쪽 상자에 선언한 변수는 거기서 읽히지 않고
/// 그 전환만 자기 시계를 갖게 된다.
String get siteMotionRootCss => ':root{${SiteMotion.css}--site-stagger-last:$kSiteStaggerLastIndex;}';

/// 사이트의 모션 변수 — 이름과 Core 값이 만나는 유일한 자리.
abstract final class SiteMotion {
  const SiteMotion._();

  /// 체크 · 토글처럼 즉시 바뀌는 것.
  static const String instant = '--site-duration-instant';

  /// 작은 요소의 hover · 포커스.
  static const String fast = '--site-duration-fast';

  /// 대부분의 전환.
  static const String normal = '--site-duration-normal';

  /// 한 항목의 등장.
  static const String moderate = '--site-duration-moderate';

  /// 한 시퀀스 전체.
  static const String slow = '--site-duration-slow';

  /// 순차 등장의 간격.
  static const String staggerStep = '--site-stagger-step';

  /// "복사됨" 처럼 잠깐 머무는 표시 — 전환이 아니다.
  static const String hold = '--site-duration-hold';

  /// 화면 안에서 자리 · 상태가 바뀔 때.
  static const String move = '--site-easing-move';

  /// 들어올 때.
  static const String enter = '--site-easing-enter';

  /// 나갈 때.
  static const String exit = '--site-easing-exit';

  /// 눌렀을 때 — 살짝 넘쳤다 돌아온다.
  static const String feedback = '--site-easing-feedback';

  /// 변수 이름 → 값. 문서 요소와 `.landing` 에 선언된다.
  static Map<String, String> get declarations => {
    instant: durationMsCss(CoreDuration.instant),
    fast: durationMsCss(CoreDuration.fast),
    normal: durationMsCss(CoreDuration.normal),
    moderate: durationMsCss(kSiteRevealMs),
    slow: durationMsCss(CoreDuration.slow),
    staggerStep: durationMsCss(kSiteStaggerStepMs),
    hold: durationMsCss(CoreDuration.ms2000),
    move: CoreEasing.move.toVarCss(),
    enter: CoreEasing.enter.toVarCss(),
    exit: CoreEasing.exit.toVarCss(),
    feedback: CoreEasing.feedback.toVarCss(),
  };

  /// 선언을 CSS 한 줄로.
  static String get css => declarations.entries.map((entry) => '${entry.key}:${entry.value};').join();
}
