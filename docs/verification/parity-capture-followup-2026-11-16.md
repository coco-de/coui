# 캡처 조건 정합성 보완과 잔여 치수 진단 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).
직전 main 재측정은 [451 통과·297 불일치 기록](parity-remeasurement-2026-11-16.md)에 있다.

캡처 도구의 두 입력 차이를 수정했다. Skeleton·LoadingRegion을 기존 초기 시점
정책에 포함하고, SSR도 Flutter와 같은 viewport에서 촬영한다. **전체 결과는
451 통과·297 불일치로 유지된다.** 실패를 통과로 바꾼 수정은 아니며, 이전에
통과로 집계됐던 8칸의 비교 시점과 SSR의 viewport 조건을 바로잡은 것이다.

## 수정과 회귀 증거

### Skeleton·LoadingRegion의 첫 프레임

두 컴포넌트가 공유 `fixedTimeCaptureComponents` 목록에서 빠져 있었다.
Flutter는 반복 pulse 때문에 3초 후에도 정착하지 않아 fallback 프레임을
촬영했고, Web은 `animation:none` 상태였다. 같은 초기 위상을 비교하지 않았다.

기존 Loading·Progress·Marquee에 쓰던 정책에 두 항목을 포함했다. Flutter는
생성 전 `TickerMode(false)`, Web은 생성 전 CSS pause와 준비 후 WAAPI
`currentTime=0`을 사용한다. 별도의 색·크기·motion 기본값은 만들지 않는다.

수정 전 새 회귀 검사에서 Flutter 4개와 Web 4개가 실패했다. 수정 뒤 Flutter는
default/circle/text/region 모두 537ms 뒤 픽셀이 같고 예약 frame도 없다.
일반 실행의 네 placeholder와 Loading은 계속 움직인다. Web도 독립 페이지의
첫 시점·paused 상태·PNG 재현성을 검사하고, capture freeze를 적용하지 않은
실제 registry에서는 pulse 색이 바뀌는 것을 확인한다.

등록된 모든 스타일의 32쌍을 재촬영했다. 교차 플랫폼은 **32 통과·0 실패**, 플랫폼별
committed baseline 비교는 **64 통과·0 회귀·0 누락·0 승인**이다. baseline은
승격하지 않았다. 초기 시점 검증을 전체 pulse 주기 검증으로 확대하지 않는다.

### SSR viewport

Web backend는 client capture만 viewport를 800×1200으로 바꿨다. SSR은
wrapper 폭이 800이어도 browser launcher의 1600×1200 viewport를 물려받았다.
CSS media query는 SSR에서도 browser viewport를 보므로 입력이 달랐다.

모든 capture page에 `availableWidthPx × 1200` viewport를 설정한다. 새 회귀
검사는 800과 400에서 실제 viewport를 읽으며, 내용 폭으로 그리는 Button의
폭은 부모 폭이 달라져도 유지되는지 확인한다. 수정 전에는 800 대신 1600이
나와 실패했고 수정 뒤 통과했다. 공개 함수의 인자는 그대로다.

## 전체 재촬영

기준 main은 `0459dd702f2a66aa2c68b2046ab2c5c97f9e65dc`다. 완료 후 fetch에서도
같은 origin/main SHA를 확인했다. 여기에 위 두 capture 변경을 적용한 상태에서
기존 748칸 manifest의 양 플랫폼을 모두 새 디렉터리에 촬영했다.
[요약 JSON](parity-capture-followup-2026-11-16.json)에 실행한 도구 소스의
SHA-256과 시작 시점, [전체 CSV](parity-capture-followup-2026-11-16.csv)에
각 키의 판정·크기·단계·viewport를 남겼다.

| 항목 | 보완 전 | 보완 후 |
|---|---:|---:|
| 통과 / 불일치 | 451 / 297 | 451 / 297 |
| 새 실패 / 해소된 실패 | — | 0 / 0 |
| 인프라 누락 / 구조적 skip | 0 / 0 | 0 / 0 |
| Flutter settled-runtime | 718 | 718 |
| Flutter initial-frame | 22 | 30 |
| Flutter unsettled-runtime | 8 | **0** |
| Web 800×1200 viewport | client capture만 | **748칸 전체** |

2,992개 PNG·JSON을 새로 생성했다. pixel report는 실제 불일치가 남아
**exit 1**이다. 이전 실패 키 297개가 정확히 유지되며 치수 110·같은 크기 픽셀
187이다. 같은 플랫폼의 이전 PNG와 비교하면 Flutter 8개·Web 21개가 달랐다.
실패 키가 같다는 결과를 이미지 전체가 동일하다는 주장으로 읽지 않는다.

viewport 변경이 전체 Web 캡처에 닿으므로 own-baseline도 양쪽 전체를 대조했다.
보완 전 main과 보완 후 모두 **1,496개 플랫폼 셀 중 1,381 통과·115 baseline
차이**다. 실패한 키/플랫폼뿐 아니라 115개의 측정값도 정확히 같다. 새 회귀와
해소된 회귀는 각각 0이다. [기존 차이 전체 CSV](parity-baseline-comparison-2026-11-16.csv)에
전후 값을 함께 남긴다. 양쪽 report는 기존 차이가 있어 exit 1이다.
이 115개는 별도 own-baseline 비교 결과이며 교차 플랫폼 잔여 297칸에 더하지
않는다. 승인·누락 baseline·skip·인프라 실패는 0이며 baseline을 변경하지 않았다.

## 치수 92칸의 추가 진단

높이만 다른 80칸과 Mockup·ResponsiveContainer의 root 범위가 다른 12칸을
라이트·다크 모두 실제로 렌더했다. Flutter의 RenderBox·RenderParagraph와
Web DOM의 bounding rect·computed style을 읽었다.
[치수 CSV](parity-layout-diagnostics-2026-11-16.csv)와
[텍스트별 CSV](parity-layout-fonts-2026-11-16.csv)에 측정값을 남겼다.
이 진단은 자연 크기이며, PNG의 정수 경계와 raw 소수점 치수를 구분한다.

92칸의 실제 문구와 문구별 출현 횟수가 같다. 반복 문구는 같은 문구의 출현
순서로 짝지었다. 총 364개 텍스트에서 글꼴의 첫 family·크기·굵기·자간·요청
line-height(px)가 모두 같다(숫자 대조 epsilon 0.0001). 이 epsilon은 기록한
CSS 수치의 비교에만 쓰며, 픽셀 gate를 바꾸지 않는다. Web의 fallback stack
전체가 Flutter와 같다는 주장도 아니다.

**이 결과로 92칸을 허용 처리하지 않았다.** 글꼴 입력의 일치를 확인한 것으로,
모든 padding·border·도형·실제 fallback glyph의 일치나 플랫폼 차이에 대한
디자이너 승인을 증명하지 않는다. Flutter paragraph box와 Web inline element
box는 서로 다른 종류의 상자이므로 CSV의 두 높이를 직접 같은 줄 상자로
간주하지 않는다.

구체적으로 확인한 두 사례:

- Alert default 양쪽 제목은 Pretendard 14/600, 행간 19.6px이고 설명은
  Pretendard 13/400, 행간 19.5px다. Flutter paragraph 높이는 각각 20px라
  `24 padding + 20 + 2 gap + 20 = 66`이다. Web 텍스트 열은 41.09375px라
  전체가 65.09375px다. 입력이 같은데 배치 결과가 다른 사례이며, 1px padding
  보정으로 통과시키지 않는다.
- ResponsiveContainer는 Flutter Align 800px 안의 제한 상자가 x=80,
  폭 640px이고 Web root도 640px다. MockupDevice 기본형도 Flutter Align
  800px 안의 기기 본체는 x=240, 폭 320px이고 Web root는 320px다. 현재
  root PNG는 바깥 Align과 안쪽 본체를 비교한다. 기기 버튼은 본체 밖으로
  약 1.5px 돌출하므로 Web PNG의 범위 문제도 남는다. 본체 치수가 같다는
  이유로 전체 그림이 같다고 선언하거나, PNG에 빈 여백을 붙이지 않았다.

## 범위와 남은 작업

### 잔여 297칸 전체의 글꼴 입력 스크리닝

치수 진단에 이어 기존 실패 키 297개 모두의 실제 텍스트 입력 목록을 읽었다.
[키별 입력과 진단 범위 CSV](parity-remaining-font-screen-2026-11-16.csv)에
양쪽 문구·family·크기·굵기·자간·요청 행간을 보존했다. 중복 문구는 font tuple
목록의 중복 개수를 포함해 대조했다. 글꼴 입력 목록이 같다는 결과는 어느
문구가 어느 위치에 그려졌는지, 색·장식·glyph·도형이 같은지를 증명하지 않는다.

| 진단 범위 | 칸 | 확인과 한계 |
|---|---:|---|
| 글꼴 tuple 입력 목록 일치 | 285 | 문구와 5개 글꼴 필드의 목록·중복 개수가 같음. paint 승인 없음 |
| 문단 텍스트가 없는 도형 | 6 | StarRating·Loading.pulse·Icon.search 각 라이트·다크. 글꼴 진단으로 설명하지 않음 |
| CodeSnippet editable/inline 범위 | 2 | 실제 highlighter 완료 후 RenderEditable의 span을 읽음. DOM token 분할과 caret 범위는 별도로 남김 |
| Swap 숨김 뒷면 | 1 | Web DOM은 backface-visibility로 숨기는 면도 보존함. 단순 DOM text 목록과 보이는 글자를 구분 |
| 자간 표현 차이 | 2 | TabPane editor-strip의 Flutter 0과 Web normal. 강제 정규화로 일치 처리하지 않음 |
| keepAll 표시용 제어 문자 | 1 | Flutter U+2060 삽입과 Web word-break:keep-all의 기존 구현 경로. CSV에서 문자를 지우지 않음 |
| 합계 | 297 | 기존 pixel 실패 판정 모두 유지 |

첫 스크리닝에서 Filter·ToggleGroup 8칸의 굵기가 어긋나는 것처럼 보였으나,
소스를 대조하니 폭 예약용 숨김 selected label과 보이는 label이 양 플랫폼의
트리에 반대 순서로 있었다. 이를 제품 결함으로 등록하지 않았다. 숨김 쌍을
포함한 입력 목록이 같은 사실까지만 기록한다.

NumberTicker·ResponsiveRowColumn 4칸은 SSR 스냅샷으로 결론을 내리지 않고
canonical capture와 같은 client-settled 조건으로 다시 읽었다. SelectableText
4칸과 CodeSnippet 2칸은 일반 RenderParagraph만 찾는 진단으로 누락되므로
RenderEditable을 추가 조사했다. rich text는 실제 상속된 TextSpan run을
DOM text-node와 대조했다. 이 보조 조사는 제품 코드나 canonical gate를
변경하지 않았다.

새로 확정한 제품 결함은 없다. 이 결과를 모든 색·도형·배치가 정확하다거나
잔여 297칸이 불가피하다는 결론으로 확대하지 않는다.

### 변경 경계

배포 패키지 `coui_core/lib`, `coui_flutter/lib`, `coui_web/lib`와
`docs_core/lib`는 기준 main과 diff 0이다. 기존 디자이너 결정·Core 값·실행
예제·제품의 motion·공개 생성자/함수/Resolved 표면을 변경하지 않았다.
baseline·allowlist·픽셀 임계값·root 캡처 범위도 변경하지 않았다.

| 잔여 범위 | 이번에 확인한 것 | 아직 필요한 것 |
|---|---|---|
| 높이 80칸 | 실제 문구·글꼴 입력과 자연 상자 치수 | 배치·paint 원인을 좁히고 기존 계약 위반이 확인되면 수정 |
| root 범위 12칸 | Align과 본체/제한 상자의 서로 다른 측정 범위 | 돌출부·정렬을 보존하는 공통 비교 계약 검증 |
| 다른 치수 18칸 | 기존 110칸에 포함된 상태 유지 | caret·hairline 등 개별 근거 재확인 |
| 같은 크기 픽셀 187칸 | 기존 실패 키 유지 | 실제 색·도형 결함과 렌더러 차이의 근거 추가 |

전체 파리티 작업은 완료되지 않았다. 수정된 capture 조건과 추가 진단을
제품 결함 전량 해소 또는 디자이너 승인으로 보고하지 않는다.

## 실행 결과

| 명령·범위 | 실제 결과 |
|---|---|
| `flutter test test/parity/capture_motion_host_test.dart -r expanded` | 13 통과, 수정 전 새 고정 시점 검사 4 실패 |
| `dart test tool/parity/test/web/{capture_state_test,web_capture_backend_test}.dart -r expanded` | 30 통과, 수정 전 phase 4·viewport 1 실패 |
| `dart test tool/parity/test/model/capture_surface_test.dart tool/parity/test/web/offline_tailwind_harness_test.dart -r expanded` | 6 통과 |
| Skeleton·LoadingRegion 전체 등록 스타일 capture + `report.dart --signal=pixel --mode=both` | 32쌍 파리티 통과, 64개 own-baseline 통과 |
| 기존 defaultStyle manifest 전체 양 플랫폼 capture + `report.dart --signal=pixel --mode=parity` | 748쌍, 451 통과·297 실패, exit 1 |
| 보완 전/후 전체 `report.dart --signal=pixel --mode=regression` | 각각 1,496개 중 1,381 통과·115 기존 차이. 실패 키/플랫폼·측정값 동일, 새 회귀 0, 양쪽 exit 1 |
| raw layout 진단 + 실제 텍스트의 문구/폰트 tuple 대조 | 92칸·364 tuple 일치, 파리티 허용 판정 없음 |
| 잔여 키 전체의 글꼴 입력 목록 스크리닝 | 297칸을 위 6개 진단 범위로 기록, pixel 실패 297 유지 |
| 변경 Dart 파일 `dart analyze --fatal-infos` / format | 진단 0 / 포맷 차이 0 |

도구·테스트 변경이므로 제품 UI 빌드 경로는 변경되지 않았다. 전체 수동 CI와
`jaspr build`는 이번 변경에서 실행하지 않았다. 이 작업트리에 연결된 Flutter
앱이 없어 hot reload 대상도 없으며, 캡처와 회귀 검사는 새 테스트 프로세스로 실행했다.
