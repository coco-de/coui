# Frame Native 직선 dash 검증 (2026-11-16)

Part of #6131, PR #6318. [이전 검증](parity-frame-followup-2026-11-16.md)의
Neo dashed dark 실패를 이어서 수정했다. **Neo dashed는 light/dark 모두 기존
5% pixel gate를 통과한다.** 전체 Neo 스타일이나 Frame 전체 완료 판정은 아니다.

## 수정

기존 painter는 직선 dash도 다른 조각들과 하나의 stroke Path에 모아 그렸다.
이제 시작·끝 tangent가 같은 축의 같은 방향이고, 두 점의 위치도 해당 축에
놓이는 dash는 `Canvas.drawLine`으로 그린다. 단일 직선의 길이는 해당 border
box의 폭/높이를 넘을 수 없다는 조건도 확인한다. 모서리를 가로지르는 조각과
둘레 전체를 도는 긴 dash는 기존 extracted Path로 그린다.

**좌표·dash 길이/간격·두께·반지름·색·line cap·곡선 길이 계산은 그대로다.**
표면 이름·테마·키에 따른 분기가 없고 AA flag, offset, 이미지 처리, threshold를
추가하지 않았다. 실제 컴포넌트의 Native 그리기 primitive를 바꾼 수정이다.
Frame Dartdoc 예제의 색/반지름 타입도 기존 CoreColor/CoreBorderRadius API에 맞췄다.

수학적 원호 길이로 전체 dash 위치를 다시 계산하는 실험은 채택하지 않았다.
그 실험은 기존 SVG와 다른 패턴이 되어 Neo light에 새 실패를 만들었다.
`shape-rendering: geometricPrecision` 및 같은 SVG path로의 변환도 실제 Web
픽셀을 바꾸지 않았다. 최종 구현에는 이 실험들이 들어 있지 않다.

## 결과

| Neo dashed | main | 이전 PR | 현재 | 현재 판정 |
|---|---:|---:|---:|---|
| light | 11.367746% | 1.783659% | **0.928818%** | 통과 |
| dark | 15.017261% | 5.383857% | **4.635870%** | 통과 |

dark의 차이 655픽셀은 **564픽셀**로 줄었다. 글자 상자 안 527개는 유지되고
바깥 테두리 영역은 128개에서 **37개**로 줄었다. light는 글자 안89개·바깥24개다.
이 영역 분류는 진단이며 pixel gate에서 제외하거나 mask로 쓰지 않았다.

| 범위 | main 통과/실패 | 이전 PR | 현재 | 새 실패 |
|---|---:|---:|---:|---:|
| default 748키 / 760 probe | 460 / 288 | 461 / 287 | **461 / 287** | 0 |
| 관련 등록 스타일152키 | 39 / 113 | 42 / 110 | **43 / 109** | 0 |
| 그중 Frame32키 | 13 / 19 | 16 / 16 | **17 / 15** | 0 |

default 748키는 Neo를 포함하지 않으므로 이 수정으로 전체287개가286개가 되지는
않는다. Frame에 남은15개도 계속 실패다. text 영역11개와 다른 dashed4개가 남으며
이를 엔진 차이로 확정하거나 디자이너 승인으로 처리하지 않는다.

default의 이전 PR 대비 PNG1,520개는 모두 기존 회귀 기준 안이다. Native Frame
dashed light/dark 두 PNG만 RGBA가 달라지고 최대 채널 차이는13/14, 채널32 초과
픽셀은0이다. Neo는 별도 스타일 표에서 판정한다. own-baseline은 기존 그대로
1,363통과·133차이·stage24첫촬영이며 baseline을 승격하지 않았다.

## 검증과 최신 main

- Native **50 통과**: 기존 Frame8, patterned27, text10, chrome5. patterned에는
  dashed/dotted × stroke1/2/4 × square/rounded × DPR1/4의24개 raster와
  시작점·모서리 통과 dash·둘레보다 긴 dash의3개 geometry 검사가 있다.
  DPR4는 점의 모양을 분해하는 단위 검사이고 실제 parity 촬영은 DPR1이다.
- 최종 Native748키·관련152키를 새 프로세스로 다시 촬영했다. Web 소스와
  font assets는 그대로여서 이전의 실제 Web 촬영본을 재사용했다. 별도로 Web
  default/Neo light/dark4개를 새로 촬영해 이전 Web과 RGBA가 같은 것도 확인했다.
- 변경 Dart analyze --fatal-infos 이슈0·format0 changed. 공개 선언 SHA5개 동일.
  Core 값·default·export·Figma 데이터·baseline·allowlist·비교 기준 변경0이다.
- property 진단은300통과·390실패·12stage infra·46빈root로 그대로다. 이전의
  공통11,662필드 중265개 불일치 해소·새 불일치0도 유지된다. pixel infra는0이다.
- 최신 main `98a404ae6e4f50810a72a600f72f47256147ed13`(#6320/#6321)을 병합했다.
  이전 clean main185dca1과 바뀐 render 관련 Dart110개를 비교했다. 주석 및
  FAB의 Deprecated 안내 문구를 제외한 token이 모두 같다. 상수·resolver·preview
  실행 코드는 같고, 최신 registry로 manifest를 재생성해748/152키의 모든 entry와
  probe가 그대로인 것도 확인했다. 이전 main 촬영본을 새 main 촬영본이라고 쓰지 않는다.
- 마지막 fetch의 main `6cfd416c21caa71496aea550db699d8257088fd5`(#6313 release/#6324)도 병합했다.
  추가 변경은 버전/changelog와 docs table의 code 줄바꿈이며 renderer library/
  preview/parity source diff는0이다. 새 docs CSS 검사21개도 통과했다.
- 병합 후 docs 문구 검사7통과, `jaspr build` **357/357**. 전체 수동 CI와 배포는
  실행하지 않았다. 이전 Web 계약101·Chrome probe/geometry/normalize101의
  대상 실행 소스는 바뀌지 않았다. 기존 SSR HTTP200/CDP stroke/radius 검증도 유지한다.
- 실행 중인 이 workspace의 Flutter 앱이 없어 새 test/capture engine으로 검증했다.
  다른 앱에는 hot reload하지 않았다.

## 증거

- [source/API/main 비교 증거 JSON](parity-frame-native-lines-2026-11-16.json)
- [관련152키 전후 CSV](parity-frame-native-lines-2026-11-16.csv)
- 이전 default760 probe와 raw layout 진단은 [이전 검증](parity-frame-followup-2026-11-16.md)에 있다.

기존7-1~7-29의 변경 범위 검증을 이어서 적용했다. 실행 소스가 바뀌지 않은
항목은 이전 검증의 명령과 증거를 유지하며, 아래에 항목별 판정을 모두 남긴다.

| 항목 | Command | Expected | Evidence | Pass |
|---|---|---|---|---|
| 7-1 analyze | `dart analyze --fatal-infos` 변경 Dart 14개 | 새 이슈 0 | No issues found | 통과 |
| 7-2 format | 같은 파일 `dart format --output=none --set-exit-if-changed` | drift 0 | 14 files, 0 changed | 통과 |
| 7-3 snippet/example | 기존 코드 예제와 Frame Dartdoc 대조 | 기존 Core API 사용 | 기존 예제 검사 유지; Dartdoc도 CoreColor/CoreBorderRadius로 정정 | 통과 |
| 7-4 SSR | 최신 main 병합 뒤 `jaspr build` | 모든 route 생성 | 357/357; 기존 HTTP200 Web 소스/조건 유지 | 통과 |
| 7-5 screenshot | Native748+152 재촬영·Web controls4·PNG 직접 확인 | 새 실패/잔여 공개 | 461/287, 43/109, Neo dashed 양쪽 통과, 새 실패0 | 측정 완료; 전체 parity 미완료 |
| 7-6 Core/Style/Theme | resolver/Core diff·AST·main token 비교 | merge·계약 유지 | 선언 SHA5개 동일, main 변경110개 token 동일(주석/Deprecated 문구 제외) | 범위 내 통과 |
| 7-7 contract | body 제외 선언 비교; Core diff | 새 미구현/API 변경0 | Frame/helper/probe/normalizer 선언 동일 | 범위 내 통과 |
| 7-8 named API | 같은 AST 검사 | 이름·타입·default 유지 | JSON 선언 SHA 5개 동일 | 통과 |
| 7-9 color/token | Frame doc diff·snippet 검사·Core diff | 원래 CoreColor 참조 | 값/default 변경0, 토큰 var 경로 실제 측정 | 통과 |
| 7-10 disabled | 제품 diff | 상태 동작 변경0 | disabled 처리 diff0 | 해당 없음 |
| 7-11 composition | private painter diff·Native50 검사 | 기존 구성/기하 유지 | 직선 primitive 사용, corner/full-loop 기존 경로 보존 | 범위 내 통과 |
| 7-12 export | lib export diff | export 변경0 | export diff0 | 통과 |
| 7-13 legacy | 파일 목록·deprecated diff | 교체/삭제0 | legacy 변경0 | 해당 없음 |
| 7-14 Web 구조 | Frame 폴더·style 읽기 | widget/style 유지 | frame.dart + frame_style.dart 유지 | 통과 |
| 7-15 registry | 네 preview/code registry `rg 'frame'` | 양쪽 등록 유지 | 95/127/99/98행, 등록 변경0 | 통과 |
| 7-16 catalog/layout | shared catalog/constraints/layout `rg 'frame'` | 목록·제약 유지 | 884/219/220행, 변경0 | 통과 |
| 7-17 typography | property report·원본 글자 픽셀 분류 | 임의 font 변경0 | property300/390 유지; Neo dark text527개 유지 | 범위 내 통과 |
| 7-18 cursor | handler/cursor diff | 동작 변경0 | 이벤트 처리 diff0 | 해당 없음 |
| 7-19 flex | 제품 diff·전후 PNG/metadata | 배치 변경0 | 배치 코드0, temporal PNG 치수 변화0 | 범위 내 통과 |
| 7-20 motion | Core/양쪽 제품 diff | duration/curve 변경0 | motion diff0 | 해당 없음 |
| 7-21 variant | Frame4변형×2테마×4스타일 동일 판정 | 누락 없이 기존 기준 적용 | main13/19→이전16/16→현재17/15, 새 실패0 | 측정 완료; 전체 parity 미완료 |
| 7-22 md API | md Props/스타일과 실제 선언 | 기존 타입·토큰 일치 | CoreColor?/double?/CoreFrameBorderStyle?/CoreBorderRadius?, stroke2 | 통과 |
| 7-23 hardcode | 제품/Core/가드 diff | 새 시각값/예외0 | 직선 기하 판별만 추가, 원래 좌표/스타일 보존 | 통과 |
| 7-24 computed style | Web source hash·실제4개 controls | 기존 CSS/토큰 경로 유지 | RGBA 동일, 이전 release default16/2/15·Neo4/4/2 유지 | 이전 Web 증거 유지 |
| 7-25 render loop | Native50·748+152 fresh capture | corner/full-loop 포함 새 오류0 | 모두 완료; pixel infra0, 새 실패0 | 범위 내 통과 |
| 7-26 token resolution | Frame resolver 읽기·diff | scheme/Core 경로 유지 | scheme.resolve 유지, Core diff0 | 범위 내 통과 |
| 7-27 mapping/default | Core/resolver/AST diff | 필드·매핑·default 변경0 | 관련 선언/파일 동일 | 범위 내 통과 |
| 7-28 Web chrome | frame_style.dart 읽기 | 기존 WebResolvedChrome 유지 | root/dashOverlay/dashRect WebElementChrome 유지 | 통과 |
| 7-29 enum | Core enum/adapter diff | 어휘·enum 변경0 | 관련 경로 diff0 | 해당 없음 |
