# Frame 경계·표면 반지름·텍스트 측정 후속 검증 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131), PR #6318.

> 이 문서는 `88c7ca5`까지의 후속 결과다. 이후 Native 직선 dash 그리기를
> 수정해 Neo dashed dark도 통과했다. 현재 최종 판정은
> [Native 직선 그리기 검증](parity-frame-native-lines-2026-11-16.md)을 따른다.
> 아래 Frame 16/16, Neo dark 5.383857%는 이전 결과다.

기준은 clean main `185dca1ef84f196f5e7be26cfed0bc7af76bcb4d`이며 이 main을
작업 브랜치에도 병합했다. main과 수정본을 각각 새 프로세스로 촬영했다.
이 문서는 초기 draft의 462/286 결과를 대체한다. **최종 기본 스타일 결과는
461 통과·287 불일치**다. 전체 파리티나 디자이너 승인 완료 판정이 아니다.

## 확인된 원인과 수정

1. **Frame patterned border의 경계·순회·점 모양**: stroke 중심선을 반 두께만큼
   안에 놓고 SVG rect와 같은 좌상단 접점부터 시계 방향으로 순회한다.
   dotted는 유한 길이 선분에 round cap을 붙인 캡슐 대신 반지름 `stroke / 2`의
   원을 `stroke * 2` 간격으로 그린다. dashed의 기존 길이와 간격은 유지한다.
2. **바깥 모서리 반지름**: Core radius와 CSS border-radius는 바깥 경계의
   반지름이다. inset한 중심선은 반지름도 `max(0, outerRadius - stroke / 2)`로
   줄여야 한다. Flutter는 바깥 RRect를 deflate하고 Web SVG는 같은 식을 쓴다.
   초기 draft처럼 박스만 줄이고 원래 radius를 그대로 쓰면 이 계약이 어긋난다.
3. **공용 SVG의 토큰 경로**: 기존 raw rem 변환이 표면 스타일의 radius CSS
   변수를 우회했다. 기존 `radiusCss`를 거쳐 변수 참조를 유지한다.
   Frame·Button·OutlinedContainer·FileInput·ColorPicker의 helper에 적용되며
   새 토큰·새 public 인자·스타일별 예외를 만들지 않는다. off-scale 직접 지정값도
   원래 외곽 값 그대로 받고 중심선만 계산한다.
4. **실제로 그리는 텍스트 측정**: Flutter의 숨겨진 hint/opacity 0 측정 자식과
   아이콘 전용 DefaultTextStyle, Web의 그래픽 전용 wrapper·SVG title/desc·
   숨김/0면적 clip 요소를 대표 글자로 읽지 않는다. text-only Stack 탐색은 보이는
   positioned 본문까지 찾으며 chrome 탐색의 기존 범위는 유지한다. 실제 SVG text,
   입력값, 빈 입력의 기존 색상 선언 계약은 보존한다. Web은 먼저 나오는 직접
   텍스트를 건너뛰어 뒤의 부가 라벨을 읽지 않는다.
5. **CSS 값의 의미**: letter-spacing `normal`은 CSS 규격대로 0으로 정규화한다.
   line-height `normal`은 계속 미상(null)이다. placeholder의 line-height는 pseudo가
   아니라 실제 line box를 소유하는 input에서 읽는다. 필드 삭제나 비교 오차 확대가 아니다.

근거는 [CSS border-radius의 바깥 경계 정의](https://www.w3.org/TR/css-backgrounds-3/#border-radius),
[SVG rect equivalent path](https://www.w3.org/TR/SVG/latest/shapes.html#RectElement),
[SVG round linecap](https://www.w3.org/TR/SVG2/painting.html#LineCaps),
[CSS letter-spacing normal](https://www.w3.org/TR/css-text-3/#letter-spacing-property),
[placeholder에 적용되는 속성 범위](https://www.w3.org/TR/css-pseudo-4/#placeholder-pseudo)다.
Flutter SDK의 uniform Border도 바깥 RRect를 만든 뒤 stroke 폭에 맞게 deflate한다.

## 디자인·API 범위

Core 값·default·resolver 우선순위·Figma 데이터·플러그인·캔버스·폰트·타이포
토큰·export 변경은 0이다. 기존 Core 표면 geometry를 실제 테두리에 전달하고
동일한 바깥 경계를 그리도록 한 구현 수정이다. 새 디자인 결정을 추가하지 않았다.
별도 디자이너 승인을 받았다는 뜻은 아니다. Figma Frame builder에 명시되지 않은
stroke/radius 세부 사항까지 시안이 보장한다고 확대 해석하지 않는다.

Frame, SVG helper, native text/walk probe, Web normalizer의 body 제외 선언은
main과 동일하다. 인자 이름·타입·기본값·field 선언 SHA는 JSON에 기록했다.
Web raw 측정의 17필드 schema도 유지한다. `radius0` 기존 zero 상수 참조와 문서의
CoreColor/stroke2 타입 정리는 [초기 기록](parity-frame-border-2026-11-16.md)에 있다.

## 새 촬영 결과

판정은 기존 **pixel parity 5%, own-baseline 0.1%, RGBA 채널 차이 32 초과**,
크기 차이는 실패다. 실제 capture DPR은 1이다. mask·offset·resize·baseline 승격·
allowlist/threshold 변경·실패 키 제외는 없다. 아래 두 범위는 default 키가 겹치므로
합산하지 않는다.

| 범위 | main 통과/실패 | 수정 통과/실패 | 새 실패 | pixel infra/skip |
|---|---:|---:|---:|---:|
| 기본 스타일 748키 / 760 probe | 460 / 288 | **461 / 287** | 0 | 0 / 0 |
| helper 관련 등록 스타일 152키 | 39 / 113 | **42 / 110** | 0 | 0 / 0 |
| 위 범위 중 Frame 32키 | 13 / 19 | **16 / 16** | 0 | 0 / 0 |

152키는 Button 90, Frame 32, ColorPicker/FileInput/OutlinedContainer 각 10이다.
Frame 밖에서 pass/fail이 바뀐 키는 없다. FileInput Web 테두리 10개 PNG는
중심선 반지름 수정으로 바뀐다. Button/ColorPicker/OutlinedContainer 등록 예제는
해당 patterned 상태를 모두 전시하지 않으므로 실제 CSS helper/호출부 검사도 수행했다.

| Frame dashed | light main → 수정 | dark main → 수정 |
|---|---:|---:|
| defaultStyle | 9.339975% → **4.385341%** | 10.176125% → **5.221491%** |
| neoBrutalism | 11.367746% → **1.783659%** | 15.017261% → **5.383857%** |
| claymorphism | 8.254759% → **4.394236%** | 9.099804% → **5.283757%** |
| neumorphism | 9.793631% → **5.719623%** | 10.629781% → **6.573563%** |

**5%를 넘는 셀은 그대로 실패다.** 반지름 의미를 잘못 적용한 중간 구현은 통과 키가
더 많았지만, 숫자를 유지하기 위해 잘못된 계산으로 되돌리지 않았다.

기본 1,520 platform/probe PNG 중 1,513개는 RGBA가 같다. 달라진 것은
Frame dashed Flutter/Web 각 light/dark 4개, FileInput Web light/dark 2개,
StarRating Web dark의 최대 채널 차이 1인 미세 재촬영 차이 1개다.
기존 회귀 기준을 넘는 6개는 실제 테두리 변경이다. 관련 304 PNG 중 278개는
RGBA 동일, 나머지는 Frame 16개·FileInput Web 10개다.

기본 own-baseline은 **1,363 통과·133 차이·stage 24 첫 촬영**, 관련 범위는
**268 통과·36 차이**다. 첫 촬영을 통과로 세지 않고 기존 baseline을 보존했다.
pixel reporter exit1은 위의 공개된 불일치이며 인프라 실패가 아니다.

## 남은 Frame 차이의 위치

Frame column 8개와 elevated dark 4개를 실제 render box/DOM으로 측정했다.
글자 상자의 x/y, 요청한 font family/size/weight/spacing/line-height는 일치하고
너비에 subpixel 차이가 있다. column은 예를 들어 Flutter 39.252499px /
Web 39.265625px이며 줄 높이는 양쪽 21px이다. DOM span과 glyph range의
상자 높이는 서로 다른 의미이므로 같은 값이라고 주장하지 않는다.

이 12개 중 11개가 실패하며, 해당 12개 모두 채널 차이 32 초과 픽셀이 **텍스트
상자 안에만** 있다. column light default 432개, dark default 512개, elevated
dark default 1,137개이며 각 바깥 영역 차이는 0이다. 이는 글자 래스터 차이라는
위치 증거다. 모든 실패가 엔진의 불가피한 차이라고 확정하거나 허용한 것은 아니다.
Neumorphism dashed dark는 글자 안 414개, 밖 325개가 달라 테두리 차이도 남는다.
측정된 token/geometry가 같은 상태에서 이를 맞추려고 글꼴 두께·배치·허용치를
임의로 바꾸지 않았다. 자세한 양쪽 상자와 원본 픽셀 분류는 text-layout JSON에 있다.

## 텍스트 metadata 진단

같은 최종 normalizer로 main과 수정본을 모두 비교했다. 11,662개 공통 필드에서
**265개 불일치 해소, 새 불일치 0**이다. line-height 68, size 58, color 55,
weight 50, family 20, letter-spacing 14개다. box 관련 필드는 이 진단에서 바꾸지 않았다.
key 기준은 **260 통과·414 실패·12 infra·62 구조적 빈 root →
300 통과·390 실패·12 infra·46 구조적 빈 root**다. 새로 실제 글자를 찾은 root도
비교하며, 더 많이 skip해서 얻은 개선이 아니다.

property의 12개 stage metadata 부재는 pixel infra 0과 별개다. 기존 reporter는
Core-token 3자 판정을 `notChecked`로 반환하므로 이 결과를 Core/디자이너의
승인으로 부르지 않는다. 초기 draft의 command-empty 새 색상 차이 2개도 숨겨진
hint 대신 실제 query를 양쪽에서 읽도록 수정해 해소했다.

## 실행 검사와 반례

- Flutter: Frame 기존 8 + patterned 17 + text probe 10 + chrome probe 5 = **40 통과**.
  patterned는 1/2px × dashed/dotted × square/rounded × 1x/4x의 16개 raster와
  순회 시작점 검사다. 4x는 1px 점의 모양을 분해해서 보는 **단위 검사**이며 실제
  parity 촬영 DPR 1을 바꾸지 않는다. 박스 밖 잉크 0·안쪽 두께 전체·점의 지름을 확인한다.
- Web 호출부/Frame border/geometry 계약 **101 통과**.
- 실제 Chrome computed-style 39 + SVG geometry 6 + normalize 56 = **101 통과**.
  SVG geometry는 네 표면 preset, live radius 변수 11px, off-scale 7.25px의
  실제 Frame host radius와 SVG 중심선 radius를 함께 검사한다.
- 이전 코드 반례: dotted 캡슐 4 실패, SVG 토큰 경로 3 실패, 외곽 radius
  계약 6 실패, 숨겨진 input 2 실패, positioned-text fallback 1 실패,
  wrapper/visibility 5 실패, zero-clip/placeholder 2 실패, bare label 1 실패,
  normal spacing 2 실패. overflow가 있었던 초기 진단 fixture는 반례 증거에서 제외한다.
  단순 clipRect 대안은 2px 선 두께를 절반으로 줄이는 4개 실패를 검출했다.
- 변경 Dart **14개 analyze --fatal-infos: 이슈 0**, format **0 changed**.
- 최종 소스로 `jaspr build`: **357/357**, release `/components/frame/` curl **HTTP200**.
  실제 release UI의 dashed 탭과 표면 선택으로 CDP 측정: default host16/stroke2/
  SVG rx15/x1, Neo host4/stroke4/SVG rx2/x2, dash는 모두3/2px. 원본 변수 참조도 유지한다.
- 이 workspace의 실행 중인 Flutter 앱이 없어 새 test/capture 프로세스로 확인했다.
  다른 프로젝트 앱에는 hot reload를 수행하지 않았다.

clean main의 첫 Web 촬영에서 한 키가 timeout되어 같은 설정으로 그 키만 재시도했다.
최종 full 748개와 관련 152개는 누락 없이 완료했고 source SHA-256 6개를 촬영 뒤
재확인했다. 이전 중간 artifact를 최종 캡처로 재사용하지 않았다.

## 검증 7-1~7-29

기존 공개 API 유지 지시가 전체 API migration보다 우선한다. 이 표의 통과는
변경 범위에 관한 증거이며, 기존 Frame의 모든 계약을 새로 통일했다는 판정은 아니다.

| 항목 | Command | Expected | Evidence | Pass |
|---|---|---|---|---|
| 7-1 analyze | `dart analyze --fatal-infos` 변경 Dart 14개 | 새 이슈 0 | No issues found | 통과 |
| 7-2 format | 같은 파일 `dart format --output=none --set-exit-if-changed` | drift 0 | 14 files, 0 changed | 통과 |
| 7-3 snippet/example | 기존 Flutter/Web frameCode 5종 컴파일 검사 및 diff | 기존 API로 컴파일 | 양쪽 초기 검사 통과; 후속 snippet 변경 0 | 통과 |
| 7-4 SSR | `jaspr build`; release curl | 전체 경로·토큰 렌더 | 357/357, HTTP200, radius/stroke var 유지 | 통과 |
| 7-5 screenshot | 양쪽 748키+관련152키 새 촬영·PNG 확인 | 전후 실패/새 실패 공개 | 461/287, 42/110, 새 실패0 | 측정 완료; 전체 parity 미완료 |
| 7-6 Core/Style/Theme | 양쪽 resolver와 Core diff·AST 비교 | 기존 merge·계약 유지 | resolveFrame/scheme 경로 동일; 선언 SHA 동일 | 범위 내 통과 |
| 7-7 contract | body 제외 선언 비교; Core diff | 새 미구현/API 변경0 | Frame/helper/probe/normalizer 선언 동일 | 범위 내 통과 |
| 7-8 named API | 같은 AST 검사 | 이름·타입·default 유지 | JSON 선언 SHA 5개 동일 | 통과 |
| 7-9 color/token | Frame doc diff·snippet 검사·Core diff | 원래 CoreColor 참조 | 값/default 변경0, 토큰 var 경로 실제 측정 | 통과 |
| 7-10 disabled | 제품 diff | 상태 동작 변경0 | disabled 처리 diff0 | 해당 없음 |
| 7-11 composition | painter/helper diff·40 native 검사 | 기존 구성 보존 | private painter 수정, 구성/호출 API 동일 | 범위 내 통과 |
| 7-12 export | lib export diff | export 변경0 | export diff0 | 통과 |
| 7-13 legacy | 파일 목록·deprecated diff | 교체/삭제0 | legacy 변경0 | 해당 없음 |
| 7-14 Web 구조 | Frame 폴더·style 읽기 | widget/style 유지 | frame.dart + frame_style.dart 유지 | 통과 |
| 7-15 registry | 네 preview/code registry `rg 'frame'` | 양쪽 등록 유지 | 95/127/99/98행, 등록 변경0 | 통과 |
| 7-16 catalog/layout | shared catalog/constraints/layout `rg 'frame'` | 목록·제약 유지 | 884/219/220행, 변경0 | 통과 |
| 7-17 typography | 제품 token diff·paired property 진단 | 임의 typography 변경0 | 265 필드 해소, 새 불일치0; token diff0 | 범위 내 통과 |
| 7-18 cursor | handler/cursor diff | 동작 변경0 | 이벤트 처리 diff0 | 해당 없음 |
| 7-19 flex | 제품 diff·전후 PNG 크기 | 배치 변경0 | 변경 PNG는 경계; 전체 temporal 크기 차이0 | 범위 내 통과 |
| 7-20 motion | Core/양쪽 제품 diff | duration/curve 변경0 | motion diff0 | 해당 없음 |
| 7-21 variant | Frame 4변형×2테마×4스타일 | 누락 없이 기존 기준 판정 | 13/19→16/16, 새 실패0; 모든 ratio CSV | 측정 완료; 전체 parity 미완료 |
| 7-22 md API | md Props/스타일과 실제 선언 | 기존 타입·토큰 일치 | CoreColor?/double?/CoreFrameBorderStyle?/CoreBorderRadius?, stroke2 | 통과 |
| 7-23 hardcode | Core/Figma/threshold diff·SVG 실제 Chrome | 새 시각값0 | radiusCss 변수 보존; 6개 geometry 검사 통과 | 통과 |
| 7-24 computed style | release dashed 탭·표면 선택·CDP eval | outer-radius 파생식 | default16/2/15, Neo4/4/2; dash3/2 | 통과 |
| 7-25 render loop | fresh capture·40+101+101 tests | 새 render/infra 오류0 | 모든 capture 완료, pixel infra0, unit242 통과 | 범위 내 통과 |
| 7-26 token resolution | Frame resolver 읽기·diff | scheme/Core 경로 유지 | scheme.resolve 유지, Core diff0 | 범위 내 통과 |
| 7-27 mapping/default | Core/resolver/AST diff | 필드·매핑·default 변경0 | 관련 선언/파일 동일 | 범위 내 통과 |
| 7-28 Web chrome | frame_style.dart 읽기 | 기존 WebResolvedChrome 유지 | root/dashOverlay/dashRect WebElementChrome 유지 | 통과 |
| 7-29 enum | Core enum/adapter diff | 어휘·enum 변경0 | 관련 경로 diff0 | 해당 없음 |

## 기계 판독 증거와 재현

- [summary/provenance JSON](parity-frame-followup-2026-11-16.json)
- [기본 760 probe CSV](parity-frame-followup-2026-11-16-matrix.csv)
- [관련 스타일 152 probe CSV](parity-frame-followup-2026-11-16-related.csv)
- [13개 실제 글자 배치와 픽셀 영역 JSON](parity-frame-followup-2026-11-16-text-layout.json)

동일 registry에서 default manifest와 모든 등록 스타일의 위 5개 컴포넌트 manifest를
생성하고 clean main/수정본에서 각각 실행한다. capture에는 같은 manifest를 쓴다.

```sh
PARITY_MANIFEST="$S/manifest.json" PARITY_OUT="$S/captured" \
  flutter test --no-pub --reporter expanded test/parity/flutter_capture_matrix_test.dart
dart run tool/parity/capture_web.dart --manifest="$S/manifest.json" --out="$S/captured"
dart run tool/parity/report.dart --manifest="$S/manifest.json" --captured="$S/captured" \
  --signal=pixel --mode=parity --report-json="$S/parity.json"
dart run tool/parity/report.dart --manifest="$S/manifest.json" --captured="$S/captured" \
  --signal=pixel --mode=regression --report-json="$S/regression.json"
dart run tool/parity/report.dart --manifest="$S/manifest.json" --captured="$S/captured" \
  --signal=property --mode=parity --report-json="$S/property.json"
```

첫 명령의 cwd는 packages/coui_flutter, 나머지는 repository root다.
실패 결과 exit1을 숨기거나 PNG를 가공해서 재입력하지 않는다.
