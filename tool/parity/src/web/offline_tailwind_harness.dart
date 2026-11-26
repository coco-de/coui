// SPIKE-3 (#3602) — 오프라인 Tailwind 하네스 조립.
//
// `docs_core/lib/site_head.dart` 가 라이브 사이트에 쓰는 <head> 배선(Tailwind
// 스크립트 → `tailwind.config` 대입 → CSS 변수, 이 순서가 로드-순서 제약)을
// CDN 대신 `tool/parity/vendor/tailwind/` 의 버전 고정 벤더 사본으로
// 재현한다. 무엇을 왜 벤더링했는지·버전·sha256 은 그 디렉터리의 README.md 가
// 정본이다.
import 'dart:io';

import 'package:coui_web/coui_web.dart'
    show CoreBreakpointTier, ThemeConfig, kTypographyTierAttribute;
import 'package:path/path.dart' as p;

/// 벤더 스크립트의 저장소-루트 상대 경로 — 유일한 정본.
///
/// 버전을 올릴 때 이 상수 · `vendor/tailwind/README.md` 의 provenance 표 ·
/// 실제 파일명 세 곳을 함께 갱신한다(README 의 "Updating this vendor copy"
/// 참조).
const String kVendoredTailwindScriptRelativePath =
    'tool/parity/vendor/tailwind/tailwind-play-3.4.17.js';

/// VRT 캡처 전용 애니메이션 프리즈 CSS — 루프 애니메이션(스피너 ·
/// indeterminate 진행바)이 캡처 **위상**에 따라 다른 프레임으로 찍혀
/// 같은 커밋의 두 캡처가 일치하지 않는 것을 막는다 (실측: progress
/// indeterminate 0.9~1.0% · loading 2.3% 픽셀 차이로 baseline 재현성
/// 검증이 실패했다). `animation: none` 인 이유 — `animation-play-state:
/// paused` 는 **멈추는 위상 자체가 로드 타이밍에 따라 비결정**이라
/// 부적합하고, `none` 은 요소를 애니메이션 미적용 기본 상태로 렌더해
/// 항상 같은 픽셀을 준다. `transition` 도 같은 이유로 끈다(로드 중
/// 속성 변화가 전이 중간 프레임으로 찍히는 것 방지 — 값은 즉시 최종
/// 상태로 점프하므로 정착 픽셀은 동일).
///
/// 이 프리즈는 **오프라인 캡처 하네스 전용**이다 — docs_site 라이브
/// 페이지·런타임 reduced-motion 정책(표시 tier 애니메이션 보존,
/// `core/design-tokens.md`)과 무관하다.
const String kCaptureAnimationFreezeCss = '''
*, *::before, *::after {
  animation: none !important;
  transition: none !important;
}''';

/// Installed before any element exists, so every animation begins paused.
/// captureWebEntry additionally pins Animation.currentTime to zero after CSS
/// and fonts are ready, instead of pausing an arbitrary loaded frame.
const String kCaptureInitialAnimationCss = '''
*, *::before, *::after {
  animation-play-state: paused !important;
  transition: none !important;
}''';

/// [bodyHtml] 을 감싸는, 외부 네트워크 요청이 0건인 단일 정적 HTML 문서를
/// 만든다.
///
/// 순서가 의미를 가진다 — [vendoredTailwindScript] 가 먼저 실행되어 전역
/// `tailwind` 를 정의해야, 그 다음에 오는 `tailwind.config` 대입이 그 전역
/// 위에 얹힌다. `docs_core/lib/site_head.dart` 의 CDN 스크립트 → config
/// 스크립트 순서와 동일한 제약이고 동일한 이유다 — 순서를 바꾸면
/// `tailwind.config` 대입이 아직 존재하지 않는 전역에 쓰는 것이라 무시된다.
///
/// [surfaceStyleId] 는 `<html data-coui-style="...">` 로 축을 고정한다
/// (#3605 — Component ③ 책임 (c): "`<html data-theme=… data-coui-style=…>`
/// 로 축 고정"). `tool/screenshot.dart` 의 런타임 토글과 달리 이 하네스는
/// 정적 문서라 페이지가 로드될 때 이미 그 상태다 — 크로스페이드 전환을
/// 기다릴 필요가 없다(전환은 속성이 *바뀔 때* 생기지, 처음부터 그 값으로
/// 로드되는 경우엔 생기지 않는다). `null`/`defaultStyle` 은 속성을 아예
/// 안 붙인다 — `tool/screenshot.dart` 와 동일하게 "부재 = 기본 스타일"이
/// 값으로 표현하는 것보다 정확하다.
///
/// 글자 단계는 언제나 `<html data-coui-typography-tier="desktop">` 으로
/// 고정한다. 캡처 뷰포트 폭이 우연히 데스크톱 범위에 있어서 데스크톱 크기로
/// 찍히는 것이 아니라, 하네스가 그 단계를 진술해서 찍히게 하기 위해서다 —
/// 좁은 뷰포트를 여는 프로브도 baseline 과 같은 제목 크기를 읽는다. 단계별
/// 크기는 이 하네스가 아니라 단계 프로브(`typography_tier_probe_test.dart`)가
/// 렌더된 값으로 고정한다.
///
/// [additionalHeadHtml] 은 폰트 `@font-face` 같은 추가 `<head>` 조각을
/// CSS 변수 스타일 다음에 이어붙인다(순서 제약 없음 — 로드 순서에
/// 의존하지 않는 순수 선언이라).
///
/// **다크모드·서페이스 프리셋 변수는 `<style>` 로 정적 삽입하지 않는다.**
/// `themeConfig.cssVariables` 는 라이트 값만 담는다 — `darkVariableBlock`
/// (`[data-theme="dark"]{...}`) 과 `surfaceStyleVariableBlocks`
/// (`[data-coui-style="…"]{...}` 류) 은 별도 getter 다. `docs_core/lib/
/// site_head.dart` 의 `_darkCssInjectionScript()` 가 이 둘을 정적 `<style>`
/// 대신 **JS 로 `<script>` 실행 시점에 주입**하는 이유를 그 파일이 직접
/// 적어뒀다 — "Tailwind CDN 이 다크 값을 스캔해 라이트 모드를 깨는 것을
/// 막기 위해". 이 하네스가 정적 `<style>` 로 두 블록을 넣으면 정확히 그
/// 결함이 재현된다: 라이트/다크/프리셋 캡처가 전부 라이트 값으로 수렴해
/// 셋이 서로 구분되지 않는다(실측: light vs dark, defaultStyle vs
/// neoBrutalism 캡처가 바이트 단위로 동일했다). 그래서 동일 JS-주입
/// 기법을 그대로 재사용한다 — 계산은 여전히 `ThemeConfig` 한 곳에서
/// 나오고, 여기서 새로 만드는 것은 주입 방식뿐이다.
String buildOfflineTailwindHarnessHtml({
  required String bodyHtml,
  required ThemeConfig themeConfig,
  required String vendoredTailwindScript,
  String theme = 'light',
  String? surfaceStyleId,
  String additionalHeadHtml = '',
  String animationFreezeCss = kCaptureAnimationFreezeCss,
}) {
  final styleAttr = surfaceStyleId == null
      ? ''
      : ' data-coui-style="$surfaceStyleId"';
  final tierAttr =
      ' $kTypographyTierAttribute="${CoreBreakpointTier.desktop.name}"';

  return '''
<!doctype html>
<html data-theme="$theme"$styleAttr$tierAttr>
<head>
<meta charset="utf-8">
<script>$vendoredTailwindScript</script>
<script>${themeConfig.tailwindConfig}</script>
<style>${themeConfig.cssVariables}</style>
<style>$animationFreezeCss</style>
<script>${_darkAndSurfaceStyleInjectionScript(themeConfig)}</script>
$additionalHeadHtml
</head>
<body>
$bodyHtml
</body>
</html>
''';
}

/// Mirrors `docs_core/lib/site_head.dart`'s `_darkCssInjectionScript()` —
/// same technique (JS-injected `<style>` element, after the Tailwind CDN
/// script has already scanned the page), same two source blocks. Neither
/// block contains a literal `'` (both are CSS attribute-selector rules
/// over numeric/keyword values), so the single-quoted JS string literal
/// here needs no escaping, matching the site's own implementation.
String _darkAndSurfaceStyleInjectionScript(ThemeConfig themeConfig) {
  final rules =
      themeConfig.darkVariableBlock + themeConfig.surfaceStyleVariableBlocks;

  // A space at this seam would land inside the emitted JS statement —
  // these are two halves of one line of JS source split only for Dart's
  // line length, not a sentence.
  // ignore: missing_whitespace_between_adjacent_strings
  return '(function(){var s=document.createElement("style");'
      "s.textContent='$rules';document.head.appendChild(s);})()";
}

/// [kVendoredTailwindScriptRelativePath] 를 디스크에서 읽는다.
///
/// [repoRoot] 를 생략하면 `Directory.current` 를 저장소 루트로 가정한다 —
/// `tool/parity/promote.dart` 등 이 디렉터리의 다른 스크립트와 같은 관례로,
/// 저장소 루트에서 `dart run`/`dart test` 를 실행한다고 전제한다.
String loadVendoredTailwindScript({String? repoRoot}) {
  final root = repoRoot ?? Directory.current.path;
  final file = File(p.join(root, kVendoredTailwindScriptRelativePath));
  if (!file.existsSync()) {
    throw StateError(
      '벤더 Tailwind 스크립트를 찾지 못함: ${file.path}\n'
      '저장소 루트에서 실행 중인지 확인하라 '
      '(예: dart test tool/parity/test/web/).',
    );
  }

  return file.readAsStringSync();
}
