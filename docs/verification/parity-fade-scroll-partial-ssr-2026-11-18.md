# FadeScroll 부분 SSR 소유권 회귀 — #6409 / PR #6411

제품·테스트 소스는 `4b7dc023d9c5491a05d50d418d99a9be49287c34`, base는 main `34c4d5ff1e6660180434cee2541af4c1bfe28ee0`이다. 이 문서는 로컬 검증 완료 시점 기록이며 GitHub 머지 완료를 선취하지 않는다. 전체 파리티와 #6366은 계속 미완료다.

서버에 남은 A 밖에서 B만 client mount하면, #6401의 namespace 없는 State counter가 서버 A와 브라우저 B에 `co-fade-0`을 만들었다. 서로 다른 정상 local key여도 B의 효과가 A에 붙었다. State 수명 counter를 유지하며 정식 `kIsWeb`으로 `ssr`/`web` namespace를 구분한다. 공개 root ID/Key/const 생성자, Core 디자인 값·default·resolver/API·Native·SDK/locks·barrel exports·비교기준은 바꾸지 않았다. 자동 viewport ID와 이를 가리키는 내부 CSS 문자열은 바뀐다.

| 검증 | 실제 결과 |
|---|---|
| 수정 전 영구 회귀 테스트 | 최신 base 제품에서 A의 실제 RGBA assert 실패. A3/B0 effects, A mask가 none으로 변경. setup 실패를 제품 음성으로 세지 않았다. |
| 최종 tests | `dart test tool/parity/test/web/fade_scroll_timeline_test.dart packages/coui_web/test/components/fade_scroll_first_paint_test.dart packages/coui_web/test/components/fade_scroll_selection_test.dart --reporter=expanded` → exit0, Chrome6+SSR3=9 unique. 기존5 Chrome 본문 유지. |
| analyze / format | 변경 Dart2에 `--fatal-infos`, `--set-exit-if-changed --output=none` → 둘 다 exit0. 실행 전후 Source SHA 동일. |
| 독립 O2 Chrome157 | light/dark × 가로/세로 4쌍. before A3/B0·A800pixel(max234) 변경 → after A0/B3·A0pixel 변경. A 기존 root/viewport·공개 ID 유지, B effects target은 B 자신, runtime errors0. 실제 두 Core palette를 확인했다. |
| 전체 새 촬영 | Native752와 Web752 모두 새 촬영. PNG1528/JSON1504 생성·decode/parse. 이전 f817 검증본과 PNG1528 byte/RGBA 동일, JSON1362 byte 동일·142 captureContext.text만 차이. 이전 이미지를 최신 촬영으로 재라벨하지 않았다. |
| 촬영 인프라 | 최초 Web3번 shard의 Sidebar collapsed light 한 항목이 30초 timeout(exit2). 같은 소스·동일 기준의 별도 단일키 재촬영 exit0. 최초 실패/재시도 출처를 모두 보존했다. retry0이라고 하지 않는다. |
| 공식 report | pixel572pass/180fail; property416pass/278fail+12infra/46skip. 두 report exit1, 이전5889의 모든 key/role·property diff·infra/skip 목록 동일. 기준 승격·완화 없음. |
| docs | isolated SDK3.50/Jaspr0.24beta의 optimized build exit0, 359 unique routes. 실제 FadeScroll/TextField/InputOtp 72기록(44/12/16), light/dark·변형·scroll·입력·refresh 검증, JS/action errors0. |
| 토큰·chrome 가드 | token phase1..7 각각 exit0, chrome passthrough exit0. 미지원 `--phase all`의 진단 exit2는 원본 보존 후 정상 argv로 수행했다. |
| global contract 가드 | **exit1, 통과 아님.** main #6405에서 유입된 NavigationBar `spaceCss(CoreSpace.space0)` 직접 참조가 enforced check11에 걸린다. base/후보 해당 파일 byte 동일이며 #6412로 추적한다. 이 PR에 새 Core API·magic zero·guard suppression을 섞지 않았다. |
| Source·정리 | 추적22476파일 전체 SHA 불변, generated/locks 불변, 증거 문서 작성 전 WT clean. 소유 browser/runner 종료, docs server SIGTERM/reaped143·두 포트 닫힘. 다른 앱은 건드리지 않았다. |

부분 mount 검증은 일반 warm hydration 전체나 B DOM identity를 인증하지 않는다. 서버 전용 A의 기존 SSR mask를 보존하는 검증이며, SSR fit·Native #5134·#6366의 잔여를 해결했다는 뜻도 아니다. 기본 정적180개가 감소했다고 하지 않는다. 공개 API와 extension은 전후 원문이 같고 제품 변경은 private State의 initState 세 줄과 설명에 한정한다. 독립 검토도 구체적 제품 blocker를 찾지 않았으며 같은 범위 한계를 확인했다.

raw PNG8장은 비공개 미발행 draft release431249100에 올렸고 3일 뒤 만료된다. 기본 Native/Web light/dark4장과, 실제 partial B의 중간 scroll before34c/after4b7 light/dark4장이다. 후자의 빨강·파랑 배경은 명시적 동일 raw 입력이라 두 theme의 그림이 같지만 실제 theme palette는 다르다. 이미지 편집·추가 배경·CSS repair·PNG 커밋·baseline 승격은 없다. Figma 계약/캔버스는 변경하지 않았으며 새 디자이너 승인을 주장하지 않는다.

기계 판정·SHA·경로는 [JSON](parity-fade-scroll-partial-ssr-2026-11-18.json)에 남긴다. 원본 묶음은 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6409-partial-ssr-20261118.79b40hm8`이다. 전체 수동 CI·배포 성공으로 확대하지 않는다.
