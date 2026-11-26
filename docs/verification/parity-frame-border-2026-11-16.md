# Frame 점선 렌더링과 SVG 텍스트 측정 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).

> **초기 draft `371eb51`의 이력 기록**이다. 아래 462/286 및 Neo 악화 수치는
> 초기 구현의 결과이며 최종 결과가 아니다. Core의 바깥 반지름 의미와 공용 SVG
> 토큰 경로까지 수정한 [후속 검증](parity-frame-followup-2026-11-16.md)이
> 현재 브랜치의 판정 근거다.

검증 기준은 최신 main `5e426634e76cf31671fd3431fc2fba7f21c05701`이다.
#6312와 #6315는 이미 main에 반영됐고 각 Release도 성공했다. 이 문서는
그 뒤의 **미머지 브랜치** 결과다. 전체 파리티나 Frame의 모든 스타일이
완료됐다는 판정은 아니다.

## 변경 근거와 디자인 범위

Flutter의 patterned border는 경로를 Frame 박스의 가장자리에 놓고 그렸다.
stroke는 경로 양옆에 반씩 그려지므로 지정한 두께의 절반이 박스 밖으로
나갔다. 이제 경로를 두께의 절반만큼 안에 놓아 선 전체가 할당된 박스 안에
들어가게 한다. 실제 Web SVG도 이 inset과 `width - strokeWidth`를 사용한다.

또한 Skia `addRRect`와 SVG rect의 순회 시작점이 달라 같은 dash/gap이어도
점선 위치가 달랐다. Flutter 경로를 좌상단 접점부터 시계 방향으로 구성한다.
SVG의 기준은 [W3C SVG 2 rect equivalent path](https://www.w3.org/TR/SVG/latest/shapes.html#RectElement)다.
색·선 두께·dash 길이·gap·radius 입력을 바꾸거나 offset 상수를 조정한 것이
아니다. 네 모서리 반지름과 radius normalization도 유지한다.

Core 토큰 값·기본값·스타일 우선순위·외부 API는 바꾸지 않는다.
`radius0`의 `CoreBorderRadius.all(CoreRadius.radius0)` → `CoreBorderRadius.zero`는
동일한 `all(0)`의 기존 상수 사용이다. 나머지 같은 파일 lint 정리는 Wrap의
기본 horizontal 인자 생략과 추론 가능한 지역 변수 타입뿐이다.

문서 코드의 `.toValue()` 또는 RGB 문자열은 기존 `CoreColor`를 받는 Frame
API와 타입이 맞지 않았다. 같은 `surfaceContainer`·`surface`·`outline`·
`outlineVariant` 토큰을 직접 넘기도록 고쳤다. 존재하지 않는 문서 예제의
`CoreBorderWidth.medium`은 실제 dashed preview가 이미 사용하는
`CoreStrokeWidth.stroke2`로 맞췄다. 새 두께나 새 색을 결정한 것이 아니다.

**디자이너의 별도 승인으로 표현하지 않는다.** 저장소의 Figma Frame builder는
stroke weight/radius를 지정하지 않는다. Core와 기존 Web 구현은 이 수정을
뒷받침하지만, 그 사실을 Figma 시안에 명시된 stroke alignment의 증거로
확대하지 않는다. Figma 데이터·플러그인·캔버스·Generate는 변경하지 않았다.

## 실제 검사와 반례

- dashed/dotted × 1px/2px × square/rounded의 실제 raster 8개는 기존 코드에서
  모두 박스 밖의 잉크를 검출했다. 수정 뒤에는 박스 밖 0이며 안쪽에 지정한
  두께 전체가 있다.
- 기존 contour로는 첫 dash의 위치 검사가 실패했고, 수정 뒤 통과한다.
- inset 대신 `clipRect`만 넣는 변이도 검사했다. 8개 중 2px 조합 4개가
  안쪽 선 두께 1px로 실패했다. 바깥을 가려 통과시키는 검사가 아니다.
  이 변이는 복구했고 최종 Frame 기존+새 검사 17개가 통과했다.
- Web의 실제 Frame border layout/opt-in 검사는 7개 통과했다.
- 변경 Dart 6개 `dart analyze --fatal-infos`: `No issues found!`.
- 같은 6개 `dart format --output=none --set-exit-if-changed`: `0 changed`.
- 문서 문자열에서 Flutter/Web 5개씩 실제 클래스를 생성해 각각 컴파일했다.
  양쪽 테스트 모두 `+1: All tests passed!`다.
- `docs_site`의 `jaspr build`: 357/357 routes, exit 0.
- release 정적 페이지 `curl /components/frame/`: HTTP 200. CDP로 실제 dashed
  탭을 눌러 확인한 SVG는 `strokeWidth: 2px`, `strokeDasharray: 3px, 2px`,
  `fill: none`, host padding `26px`였다. 실제 geometry CSS는 half-stroke inset과
  `width/height: calc(100% - var(--coui-stroke-width-2))`다.
- 이 workspace의 실행 중인 Flutter debug 앱은 없어서 hot reload는 하지
  않았다. 다른 프로젝트의 앱을 건드리지 않고 새 test/capture 프로세스로 검증했다.

Frame 파일의 모든 FunctionBody를 AST로 제외하고 나머지 선언 토큰을 비교했다.
변경 전후 SHA-256은 둘 다
`32236a8369df36dd9d2d074d69fbb1f00123373ed2e9189258155d0689635237`다.
생성자·필드·named parameter·메서드 signature·기본값은 동일하다. Core와 Web
라이브러리 및 export 변경도 0이다. 공개 API 변경이나 별도 migration은 없다.

## 전체 748키 재촬영

동일한 748키·760 probe를 양쪽에서 새로 촬영했다. main의 clean detached
worktree에서도 같은 manifest로 수정 전 748키를 다시 촬영했다. #6314의 문서
및 TextBlock chain 문구 변경을 이번 수정의 효과로 집계하지 않는다.
촬영 코드와 manifest의 SHA-256은 [JSON](parity-frame-border-2026-11-16.json)에 있다.

| 교차 플랫폼 픽셀 | 수정 전 main | 수정 후 브랜치 |
|---|---:|---:|
| 통과 키 | 460 | 462 |
| 불일치 키 | 288 | 286 |
| 인프라 / skip | 0 / 0 | 0 / 0 |
| 통과 / 실패 probe | 469 / 291 | 471 / 289 |

해결된 것은 `frame-dashed-{light,dark}-defaultStyle` 두 키다. diff ratio는
light 9.34% → 3.42%, dark 10.18% → 4.27%다. 픽셀이 완전히 같다는 의미는
아니다. 기존 parity 기준 5% 아래로 들어온 것이다. 새 실패 키는 0이다.
잔여 286키는 치수 차이 100·같은 크기의 픽셀 차이 186이며 report는 exit 1이다.

전후 플랫폼/probe PNG 1,520개 중 바뀐 것은 Flutter의 해당 두 PNG뿐이다.
나머지 1,518개는 RGBA 최대 채널차 0이다. Web PNG는 전부 같다.
own-baseline 1,496개 플랫폼 셀은 1,367 통과·129 차이이고, stage 24개는
첫 캡처다. 기존 127 차이 외에 실제 Frame 수정 2개가 추가된 것이며 이를
자동 승인하지 않았다. baseline 승격·allowlist·임계값·마스크·패딩·스케일 변경은 0이다.

[전체 키·역할 CSV](parity-frame-border-2026-11-16.csv)에 수치를 남겼다.

## 추가 스타일 검사와 남은 차이

등록된 Frame 32키와 조사 중이던 CodeSnippet 10키를 별도 촬영했다. 이 42키를
전체 컴포넌트의 모든 스타일 검사라고 부르지 않는다.

| 범위 | 수정 전 통과 / 실패 | 수정 후 통과 / 실패 | 새 실패 키 |
|---|---:|---:|---:|
| Frame 32 | 13 / 19 | 16 / 16 | 0 |
| CodeSnippet 10 | 0 / 10 | 0 / 10 | 0 |

Frame의 dashed 8개 Flutter PNG만 바뀐다. Frame own-baseline은 기존 64개
플랫폼 셀 모두 통과에서 56 통과·8 차이로 바뀐다. CodeSnippet은 양쪽 PNG가
전후 동일하며 own-baseline 11 통과·9 차이도 같다. 총 67 통과·17 차이다.

**NeoBrutalism의 수치 악화도 남긴다.** dashed light는 11.37% → 15.10%, dark는
15.02% → 18.70%다. 둘 다 전후 실패다. 초기 native는 Core의 작은 반지름
(4px)·굵은 선, Web은 원래 16px 반지름을 사용한 스타일 차이가 있었다. 선을 온전히 그리는 수정만으로
그 차이가 해결되지는 않는다. 이를 허용 오차 변경이나 이미지 보정으로 숨기지
않는다. claymorphism의 두 키와 neumorphism dark도 계속 실패다. 이 브랜치를
Frame의 모든 스타일에 대한 파리티 완료나 디자이너 승인으로 취급하지 않는다.

[스타일 CSV](parity-frame-border-2026-11-16-styles.csv)에 실패를 포함한 42키가 있다.

## SVG 그래픽을 글자로 읽던 측정

SVG의 `currentColor`는 border/icon의 stroke 또는 fill일 수 있다. 글자가 없는
SVG를 text candidate에서 제외하고 `title`/`desc`를 visible text로 세지 않는다.
실제 SVG `<text>`와 그 색 override는 계속 읽는다. 빈 input의 own-color 계약도
유지한다. 이 선택 검사는 기존 3실패·1통과에서 새 코드로 4통과, 전체 Chrome
probe 검사 29통과다. component slug 분기나 새 skip은 없다.

전체 촬영에서 Web metadata가 바뀐 것은 36키다. 바뀐 필드는 기존 텍스트 6개
필드 안에 있고 box·크기·padding 등은 유지된다. 별도 property 진단에서 기존
불일치 필드 93개가 일치로 바뀌었다. 그러나 `command-empty`의 light/dark 색
두 필드는 일치에서 불일치로 바뀌었다. 이전의 SVG outline 색 대신 실제 query
텍스트의 onSurface 색을 읽으면서 드러난 대표 노드 선택 차이다. Flutter는
outline 색을 계속 보고한다. 이 두 필드를 해결했다고 하지 않는다.

property 진단은 260 통과·414 실패 → 270 통과·404 실패이며, 기존의 12개
추가 stage property 인프라 분류·62개 구조적 빈 root 분류가 전후 그대로다.
이것은 위의 **픽셀 검사 인프라/skip 0**과 다른 진단이다. 남은 property 차이를
색 토큰 변경이나 nullable field 삭제로 통과시키지 않는다.

## 변경 범위 검증 (7-1~7-29)

아래는 이 bug fix에서 실제 확인한 범위다. 기존 Frame 전체의 API/스타일
재설계·통일 완료 검증이 아니다. flat Inspect API를 제거하는 일반 migration
규칙보다 사용자의 외부 API 변경 금지 지시를 우선한다.

| 항목 | Command / 확인 | Expected | Evidence | Pass |
|---|---|---|---|---|
| 7-1 analyze | 변경 Dart 6개 `dart analyze --fatal-infos` | 새 이슈 0 | `No issues found!` | 통과 |
| 7-2 format | 같은 6개 `dart format --output=none --set-exit-if-changed` | drift 0 | `Formatted 6 files (0 changed)` | 통과 |
| 7-3 snippet/example | `frameCode` 5종씩 실제 클래스 컴파일 | 기존 CoreColor API로 컴파일 | Flutter +1 / Web +1, 모두 통과 | 통과 |
| 7-4 SSR | `jaspr build`; release page curl | 페이지 생성·토큰 출력 | 357/357, HTTP 200; Web border 테스트의 `var(--coui-stroke-width-2)` | 통과 |
| 7-5 screenshot | Flutter/Web 748 + 관련 스타일 42키 새 캡처·이미지 직접 확인 | 변경 범위와 잔여 차이 식별 | 기본 dashed 두 키 통과; Frame 스타일 16키는 실패 유지 | 측정 완료, 전체 파리티 미완료 |
| 7-6 Core/Style/Theme | `rg 'resolveFrame|CoreFrameStyle|frameTheme'` 양쪽 Frame/Style/Core | 기존 resolver·계약 유지 | 양쪽 `resolveFrame`; Core `frameStyle`; API 선언 hash 동일 | 범위 내 통과, 새 migration 없음 |
| 7-7 contract | AST body 제외 선언 비교; Core/Web `git diff --name-only` | 새 getter/미구현 추가 0 | 선언 hash 동일, Core/Web 출력 없음 | 범위 내 통과 |
| 7-8 named API | 같은 AST 비교와 Web source diff | 이름·기본값 변경 0 | 선언 hash 동일, Web source 변경 0 | 통과 |
| 7-9 color/token | Frame doc diff와 양쪽 snippet 컴파일 | 동일 CoreColor 참조 | surfaceContainer/surface/outline/outlineVariant 유지 | 통과 |
| 7-10 disabled | Frame API diff | disabled 동작 추가 없음 | 선언 동일; disabled 코드 변경 없음 | N/A |
| 7-11 composition | Frame diff 및 테스트 raster | 기존 컴포넌트 구성 유지 | 변경은 기존 private painter; 8개 raster + phase 통과 | 범위 내 통과 |
| 7-12 export | package lib/export diff | export 변경 없음 | 변경 라이브러리는 Frame 본문 1개뿐 | N/A, API 유지 |
| 7-13 legacy | 변경 파일 목록 | legacy 교체/삭제 없음 | deprecated/legacy 파일 변경 0 | N/A |
| 7-14 Web 구조 | Web Frame 폴더 읽기 | widget/style 유지 | `frame.dart`, `frame_style.dart`; 변경 0 | 통과 |
| 7-15 registry | `rg "'frame'"` preview/code registries | Flutter/Web preview/code 등록 | flutter_registry:95, web_registry:127, flutter_code_registry:99, code_registry:98 | 통과 |
| 7-16 catalog/layout | 같은 slug 검색 | 기존 목록·constraints 유지 | component_catalog:884, preview_constraints:219, preview_layout:220 | 통과 |
| 7-17 typography | 변경 diff; property 전후 진단 | 제품 typography 변경 0 | Web PNG 전부 동일; metadata 93개 개선·2개 새 불일치 명시 | 측정 보완, 남은 진단 별도 |
| 7-18 cursor | Frame diff | 이벤트/cursor 변경 없음 | 이벤트·handler diff 0 | N/A |
| 7-19 flex | Frame diff; 전체 전후 PNG 비교 | 레이아웃 변경 없음 | Wrap default horizontal 유지, var 추론 동일; PNG 차이는 border 두 개 | 범위 내 통과 |
| 7-20 motion | Frame/Core/Web diff | duration/curve 변경 없음 | 해당 선언·resolver 변경 0 | N/A |
| 7-21 variant | 4개 Frame variant의 등록 스타일 32키 캡처 | 변형 결과를 누락하지 않음 | 13/19 → 16/16, 새 실패 키 0; Neo ratio 악화도 공개 | 측정 완료, 전체 파리티 미완료 |
| 7-22 md API | md Props/Parameters와 실제 Frame 선언 대조 | 기존 타입·토큰 일치 | CoreColor?, double?, CoreFrameBorderStyle?, CoreBorderRadius?; stroke2는 실제 preview와 동일 | 통과 |
| 7-23 hardcode | token/Core/Figma diff; radius 정의 대조 | 새 제품 토큰/값 0 | Core/Figma 변경 0; radius0=0, zero=all(0); red/white는 검사 fixture | 통과 |
| 7-24 computed style | `scripts/cdp_inspect.sh` release Frame dashed 탭 | 실제 stroke/dash 및 inset 확인 | 2px / 3px,2px / fill none / padding26px / half-stroke CSS | 통과 |
| 7-25 render loop | 새 Flutter raster 검사; 전체 캡처 | 새 build/render error 없음 | Frame 17 통과; 양쪽 748+42 캡처 성공, pixel infra 0 | 통과 |
| 7-26 token resolution | 양쪽 Frame resolver 읽기·diff | 기존 scheme 경로 유지 | Flutter `scheme.resolve(...).toValue()`, Web token CSS; resolver 변경 0 | 범위 내 통과 |
| 7-27 mapping/default | Core/양쪽 resolver diff | 필드·default·매핑 변경 없음 | 해당 파일 diff 0; 공개 API 선언 동일 | N/A, 기존 계약 유지 |
| 7-28 Web chrome | Web frame_style.dart:34~63 읽기 | 기존 WebResolvedChrome 유지 | `ResolvedFrame implements WebResolvedChrome`; root/dashOverlay/dashRect는 WebElementChrome | 통과 |
| 7-29 enum | Core enum/adapter diff | enum/adapter 변경 없음 | 해당 경로 diff 0 | N/A |

전체 파리티 실패·스타일 차이·property 미해결을 남긴 채 검증한 변경이다.
이미지 baseline을 새 정답으로 승격하거나 디자이너 승인으로 표시하지 않았다.

## 재현

[전체 재촬영 절차](parity-remeasurement-2026-11-16.md)처럼 같은 manifest로
`flutter_capture_matrix_test.dart`와 `tool/parity/capture_web.dart`를 실행한다.
`PARITY_OUT` / `--out`은 서로 다른 임시 디렉터리로 두고, main의 별도 clean
worktree에서도 똑같이 실행한다. report는 `--mode=parity --signal=pixel`과
`--mode=regression --signal=pixel`을 분리한다. 텍스트 측정 진단에는 별도로
`--mode=parity --signal=property`를 쓴다. 기본 스타일은 748키/760 probe,
추가 범위는 Frame 32키·CodeSnippet 10키인지 먼저 확인한다.
