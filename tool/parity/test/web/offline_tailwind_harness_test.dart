// SPIKE-3 (#3602) — 오프라인 Tailwind 하네스가 실제로 네트워크 없이,
// CDN 경로와 동일한 계산값으로 렌더되는지 검증한다.
//
// 두 그룹으로 나뉜다:
//  1. 배선 확인(testServer) — jaspr_test SSR 이 실제 ThemeConfig 토큰
//     클래스를 그대로 방출하는지, 조립된 HTML 에 외부 스크립트 태그가 없는지.
//     브라우저·Chrome 이 필요 없어 항상 실행된다.
//  2. 오프라인 렌더 확인(puppeteer) — file:// + 브라우저 오프라인 모드에서
//     벤더 스크립트가 실제로 그 클래스들을 computed style 로 만드는지, 그리고
//     `pseudo-state-emit.md` / `check_forced_colors_focus.sh` 가 전제하는
//     v3 동작(outline-none 이 outline 을 지우지 않고 예약함)이 유지되는지.
//     로컬 Chrome 실행 파일이 있을 때만 실제로 돈다 — 없으면 건너뛴다(하네스가
//     이 SPIKE 를 검증할 수 없을 뿐, 배선 확인 그룹은 계속 실행된다).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:jaspr/dom.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../src/web/offline_tailwind_harness.dart';

/// 이 머신에 설치된 Chrome 실행 파일 — 없으면 null.
///
/// puppeteer 의 자체 Chromium 다운로드(~300MB, 네트워크 필요)에 기대지
/// 않는다: SPIKE-3 의 질문 자체가 "네트워크 없이 렌더할 수 있는가"라, 검증
/// 도구 준비 단계가 네트워크를 요구하면 그 질문에 스스로 답할 수 없다. 이미
/// 설치된 시스템 Chrome 을 가리켜 puppeteer 가 다운로드를 건너뛰게 한다.
String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

/// [cssVariables] 문자열에서 `--{varName}: R G B;` triplet 을 뽑아낸다.
///
/// [ThemeConfig.cssVariables] 가 실제 팔레트로부터 방출한 값을 그대로
/// 읽어와, 테스트가 색 리터럴을 하드코딩하지 않게 한다 — 팔레트가 바뀌면
/// 기대값도 같이 따라간다.
(int, int, int) _expectedRgb(String cssVariables, String varName) {
  final match = RegExp(
    '$varName:\\s*([0-9]+) ([0-9]+) ([0-9]+)',
  ).firstMatch(cssVariables);
  if (match == null) {
    throw StateError('$varName 값을 cssVariables 에서 찾지 못함.');
  }

  return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// 브라우저의 `rgb(r, g, b)` / `rgba(r, g, b, a)` computed-style 문자열에서
/// 채널을 뽑아낸다. 콤마·공백 표기는 엔진마다 갈릴 수 있어 숫자만 비교한다.
(int, int, int) _parseComputedRgb(String css) {
  final match = RegExp(
    r'rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)',
  ).firstMatch(css);
  if (match == null) {
    throw StateError('computed color 를 파싱하지 못함: $css');
  }

  return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();

  group('오프라인 Tailwind 하네스 배선 (SPIKE-3 / #3602)', () {
    testServer(
      'SSR 출력이 실제 CoUI 토큰 클래스를 그대로 담는다 — 벤더 스크립트가 '
      '스캔할 대상이 실재함을 확인',
      (tester) async {
        tester.pumpComponent(
          div(
            [],
            id: 'probe',
            classes:
                'bg-primary text-on-primary rounded-radius16 p-space16 '
                'outline-none',
          ),
        );
        final response = await tester.request('/');
        expect(response.statusCode, 200);
        expect(response.body, contains('id="probe"'));
        expect(response.body, contains('bg-primary'));
        expect(response.body, contains('outline-none'));
      },
    );

    test('조립된 하네스 HTML 은 외부 스크립트 참조가 없는 단일 문자열이다', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div id="probe" class="bg-primary outline-none"></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
      );
      // 벤더 스크립트 자신의 console.warn 문자열에 'cdn.tailwindcss.com' 이
      // 리터럴로 들어있다("... should not be used in production") — 이건
      // 경고 메시지일 뿐 네트워크 호출이 아니므로 문자열 존재 여부가 아니라
      // 실제 <script src> 참조 유무로 판정한다. 오프라인 렌더 그룹의
      // Chrome 기반 테스트가 실제 요청 0건을 별도로 검증한다.
      expect(html, isNot(contains('<script src=')));
      expect(html, contains('tailwind.config='));
      // 벤더 스크립트가 config 대입보다 먼저 나와야 한다 — 순서가 바뀌면
      // config 가 아직 없는 전역에 쓰는 것이라 무시된다(README.md 참조).
      expect(
        html.indexOf('tailwind.config='),
        greaterThan(html.indexOf(vendoredScript.substring(0, 40))),
      );
    });

    test('하네스는 애니메이션 프리즈 CSS 를 포함한다 — 루프 애니메이션 '
        '캡처가 위상에 따라 비결정이 되는 것을 막는다', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div id="probe"></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
      );
      expect(html, contains(kCaptureAnimationFreezeCss));
      expect(kCaptureAnimationFreezeCss, contains('animation: none'));
      expect(kCaptureAnimationFreezeCss, contains('transition: none'));
    });
  });

  group('오프라인 렌더 (SPIKE-3 / #3602, Chrome 필요)', () {
    final chromePath = _systemChromePath();

    test(
      '벤더 스크립트가 file:// + 브라우저 오프라인 모드에서 CoUI 토큰 클래스를 '
      '실제 computed style 로 만들고, outline-none 이 v3 대로 컴파일된다',
      () async {
        final probeHtml =
            '<div id="probe" class="bg-primary outline-none" '
            'style="width:10px;height:10px;">probe</div>';
        final harnessHtml = buildOfflineTailwindHarnessHtml(
          bodyHtml: probeHtml,
          themeConfig: themeConfig,
          vendoredTailwindScript: vendoredScript,
        );

        // Unique per run — a fixed name under the shared temp dir lets
        // concurrent jobs on one host delete each other's file mid-`goto`.
        final tempDir = Directory.systemTemp.createTempSync(
          'coui-parity-offline-harness-probe-',
        );
        final tempFile = File(p.join(tempDir.path, 'probe.html'))
          ..writeAsStringSync(harnessHtml);

        final browser = await pptr.puppeteer.launch(
          executablePath: chromePath,
        );
        final externalRequests = <String>[];
        try {
          final page = await browser.newPage();
          await page.setRequestInterception(true);
          page.onRequest.listen((request) {
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              externalRequests.add(request.url);
            }
            unawaited(request.continueRequest());
          });

          // SPIKE-3 의 핵심 조건 — "네트워크 차단 상태에서 렌더 성공"을
          // file:// 로드가 우연히 네트워크를 안 써서가 아니라, 브라우저가
          // 실제로 오프라인인 상태에서 검증한다.
          await page.setOfflineMode(true);

          final _ = await page.goto(
            Uri.file(tempFile.path).toString(),
            wait: pptr.Until.load,
          );

          final computedJson = await page.evaluate<String>(r'''
() => {
  const cs = getComputedStyle(document.getElementById('probe'));
  return JSON.stringify({
    backgroundColor: cs.backgroundColor,
    outlineStyle: cs.outlineStyle,
    outlineWidth: cs.outlineWidth,
    outlineColor: cs.outlineColor,
  });
}
''');
          final computed = jsonDecode(computedJson) as Map<String, dynamic>;

          // 색 — bg-primary 는 config 에 `rgb(var(--coui-primary))` 로
          // 등록돼 있으므로, 같은 ThemeConfig 가 emit 한 --coui-primary 값과
          // 브라우저 계산값을 채널 단위로 대조한다.
          final expected = _expectedRgb(
            themeConfig.cssVariables,
            '--coui-primary',
          );
          final actual = _parseComputedRgb(
            computed['backgroundColor'] as String,
          );
          expect(
            actual,
            expected,
            reason:
                '오프라인 벤더 스크립트가 bg-primary 를 --coui-primary 로 '
                '해석하지 못함(CDN 경로와 다른 값). computed='
                '${computed['backgroundColor']}',
          );

          // outline-none — v3 는 이걸 지우지 않고 예약한다
          // (outline: 2px solid transparent). check_forced_colors_focus.sh
          // 와 web/pseudo-state-emit.md 가 이 동작을 전제하므로, 버전이
          // 조용히 바뀌면(v4는 outline-style:none) 여기서 먼저 실패해야
          // 한다.
          expect(computed['outlineStyle'], 'solid');
          expect(computed['outlineWidth'], '2px');
          expect(
            _parseComputedRgb(computed['outlineColor'] as String),
            (0, 0, 0),
            reason: 'outline-none 의 색이 transparent(0,0,0)여야 v3 동작.',
          );
        } finally {
          await browser.close();
          tempDir.deleteSync(recursive: true);
        }

        // 네트워크 요청 0건 — 벤더 스크립트도 ThemeConfig CSS 변수도 전부
        // 파일에 인라인됐다. file:// 로드 자체는 네트워크 스택을 타지 않으니
        // 이 목록은 "탈출을 시도했지만 오프라인 모드가 막은 요청"까지 잡는다.
        expect(
          externalRequests,
          isEmpty,
          reason: '오프라인 하네스가 외부 요청을 시도함: $externalRequests',
        );
      },
      skip: chromePath == null
          ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀 — 오프라인 렌더 검증 '
                '불가(배선 확인 그룹은 계속 실행됨)'
          : null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
