# 파리티 캡처 상태 정렬과 후속 수정 (2026-11-13)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).
기준 커밋은 #6284가 머지된 `b5ed3907f36b7c0ad7d2ecfac2ad0b72040d75df`다.
아래에서 별도 문제로 기록했던 Loading.bar와 Swiper는 이어서 수정했다.
현재 동작 검증은 [motion·입력 후속 기록](parity-motion-input-2026-11-13.md)에 있다.

defaultStyle 라이트·다크 **748칸 중 450 통과·298 실패·인프라 누락 0**이다.
직전 433 통과·315 실패에서 17칸이 통과로 바뀌었고 기존 통과의 실패 전환은 0개다.
치수 실패는 120→110, 같은 크기의 픽셀 실패는 195→188이다. 이 수치는 임계값과
allowlist를 그대로 둔 교차 플랫폼 비교이며, 자체 baseline 비교와 구분한다.

원래 325개 실패 키의 측정은 [기존 CSV](parity-remaining-2026-11-13.csv)에
보존했다. `after_*`는 #6284, `capture_state_*`는 이번 결과다.

## 수정한 원인

| 대상 | 원인과 최종 처리 | 근거·검증 |
|---|---|---|
| NumberTicker·ResponsiveRowColumn·StageContainer | SSR은 최종 숫자·viewport 분기·ResizeObserver 측정 결과를 만들 수 없었다. 이 세 예제만 실제 registry를 client로 실행하고 관찰 가능한 완료 조건을 기다린다 | [#6287](https://github.com/coco-de/coui/issues/6287). NumberTicker `1234`, 행·열 및 실제 자식 간격, Stage의 builder 문구와 실제 padding을 확인. default·chain, 400·800 폭 회귀 검사 |
| Web runtime viewport | 800 폭 host를 1600 viewport에서 측정하면 MediaQuery를 쓰는 Flutter 800 viewport와 다른 조건이다. runtime 캡처는 viewport도 800×1200으로 설정 | sidecar에 실제 viewport, root·child 상자, padding, text, renderPhase 기록. 기본 Stage 양쪽 좌우 88, 콘텐츠 폭 624 |
| Tabs underline | Web root의 border가 바깥 높이에 1px를 더했다. 같은 Core 폭·색의 실제 border를 absolute 요소로 안쪽에 그린다. 과거의 active 음수 margin 제거 | [#6288](https://github.com/coco-de/coui/issues/6288). 기존 Flutter와 #5534/#4916/#6228의 outside-height·비레이아웃 paint 결정. 실제 Chrome에서 32/40/48 높이, border override 3, 스크롤 중 선 고정, forced-colors, optimized hydration·pointer·keyboard·RTL 검사 |
| Swiper preview | 내용 폭으로 줄어든 예제가 전체 swipe surface를 보여 주지 못했다. 공유 preview fill-width 목록에 default·sheet 추가 | [#6289](https://github.com/coco-de/coui/issues/6289). #3112의 전체 폭×256 무대 결정과 Flutter 예제의 무한 폭. 양쪽 800×256 확인. 옛 내용 상자 밖에서 실제 마우스 드래그가 Drawer를 마운트하는 초기 hit surface 검사 |
| ResponsiveRowColumn column | Web의 무조건 `w-full`이 Flutter Flex의 가로축·세로축을 혼동했다. row와 crossAxis stretch만 채우고 일반 column은 내용 폭을 따른다 | [#6290](https://github.com/coco-de/coui/issues/6290). desktop column Web 800→78, Flutter 78. 높이 258↔259는 남으며 임의 오프셋으로 보정하지 않음 |
| 반복 애니메이션 캡처 | Web의 animation:none과 Flutter의 진행 중 프레임은 같은 시점이 아니었다. Loading·Marquee·Progress만 양쪽 첫 tick 이전 상태로 고정 | [#6291](https://github.com/coco-de/coui/issues/6291). Web은 CSS paused와 WAAPI currentTime=0, 음수 delay 유지. Flutter는 생성 전 ancestor TickerMode(false). 독립 Web 페이지 픽셀 동일 및 Flutter 537ms 뒤 동일; 일반 앱 Loading은 계속 움직이는 positive control |
| ToggleGroup disabled selected override | Web은 선택 굵기 결정 뒤 disabled override가 다시 덮었다. Flutter처럼 disabled 색·크기를 병합한 뒤 선택 굵기를 보존 | [#6292](https://github.com/coco-de/coui/issues/6292). #5903의 색만 비활성화하는 결정. 양쪽 selected 600·unselected 800·19px override 회귀 검사. 기본 748칸 바깥의 override 결함 |
| Loading spinner | CSS border-top은 약 10:30→1:30이고 끝이 round cap이 아니었다. 기존 Core 90°를 SVG arc로 12시→3시에 그린다 | [#6293](https://github.com/coco-de/coui/issues/6293). Flutter drawArc가 기준. Core 값·slot·공개 API 유지. 실제 Chrome 32px·stroke 4·700ms override에서 NE/E arc, NW/W track 픽셀 및 1/4주기 회전 검사 |

## API와 디자인 범위

Core Contract·Style·기본값·토큰은 변경하지 않았다. 패키지 생성자·함수 인자·공개
Resolved 필드도 유지한다. 변경한 패키지 라이브러리 9개를 Dart AST로 기준 커밋과
대조해 공개 선언 차이 0개를 확인했다. `core_to_css.dart`와 `web_layout.dart`도
바이트 동일이다. 도구의 WebCaptureResult에는 실행 상태 metadata를 추가했다.
이 도구 결과는 배포 패키지의 공개 API가 아니다.

Tabs의 실제 높이, column의 폭, 선택 label 굵기, spinner 도형은 기존 계약을
구현하도록 바뀐다. Figma 캔버스를 새로 Generate·검수한 결과는 아니다.

## 검토한 이전 기준 이미지 50칸만 승격

#6284에서 남겼던 자체 baseline 차이 50칸을 재촬영하고 독립 시각 검토했다.
새 PNG는 검토했던 이미지와 픽셀 차이 0이었다. canonical BaselinePromoter의
입력 디렉터리를 이 50칸의 PNG·JSON 100개로 제한해 실행했다.
**50 PNG와 40 Web JSON이 바뀌고 10 Flutter JSON은 동일**했다. 신규 baseline,
allowlist 승인, 임계값 변경은 없다. [100개 파일의 SHA-256 기록](parity-baseline-promotion-2026-11-13.csv)은
기준 커밋과 승격 결과를 모두 담는다.

| 플랫폼·대상 | 칸 | 승격 근거 |
|---|---:|---|
| Accordion Web | 8 | #6284의 부모 제약에 따른 내용 폭 |
| NavigationBar rail Web | 10 | #6284의 Core intrinsic 최소 폭 |
| ObjectInput Flutter·Web | 20 | #6284의 hint 타이포·한 줄 힌트. Web liquidGlass 2칸에는 기존 #6198 surfaceBleed rim도 포함 |
| Toast Web | 10 | #6284의 문구 열 폭 배분 |
| TextField Web dark liquidGlass | 2 | 마지막 baseline #6143 뒤 기존 #6168 frame 수정. #6284 전 main을 별도 재촬영해 새 이미지와 동일함을 검증 |

승격 뒤 해당 5개 컴포넌트 98쌍·196 플랫폼 셀은 자체 baseline 비교에서 모두 통과했다.
이번 캡처 상태·새 수정의 5개 컴포넌트는 별도로 모든 등록 변형·스타일 142쌍·284셀을
촬영했다. 그 결과 **186셀 통과·98셀 차이·누락 0**이며 이번에 이 98셀을 승격하지
않는다. Loading 48셀은 초기 pose 변경, ResponsiveRowColumn Web 20셀은 runtime·폭,
Swiper Web 20셀은 무대 폭, Tabs Web 10셀은 구분선 기하 변경이다.
ToggleGroup 기본 화면은 양쪽 60셀 모두 기존 baseline과 같다.

## 검증과 한계

| 검증 | 결과 |
|---|---|
| 기본 스타일 양 플랫폼 전체 캡처 | 748쌍 완료·누락 0 |
| 최종 실제 Chrome 회귀 | 18 통과: runtime·초기 위상·Swiper 시작 영역 6, spinner 1, Tabs geometry 4, Tabs optimized hydration 등 7 |
| Web Loading·ToggleGroup·navigation·layout | 870 통과 |
| Flutter Loading·ToggleGroup·Tabs·capture motion | 131 통과 |
| docs registry | 1,526 통과 |
| 전체 parity 도구 | 1,077 통과·3 skip |
| 변경 Dart 23개 analyze·format | 진단 0·포맷 차이 0 |
| `jaspr build` | 355 routes 생성 성공 |
| Web resolver guard | net-new 위반 0 |
| 공개 선언 비교 | 9개 파일·변경 0 |
| 재촬영 예측 guard | 변경 baseline 90파일 모두 예측 범위 안·예측 밖 0 |

[PR #6297](https://github.com/coco-de/coui/pull/6297)과
[이미지 증거](https://github.com/coco-de/coui/pull/6297#issuecomment-6845728118)에
실행 결과를 기록했다. 로컬 결과를 전체 수동 CI의 성공으로 쓰지 않는다.

초기 pose baseline은 운동 전체의 검증이 아니다. Loading.bar는 Flutter의
`sin(ease(t) × π)`와 Web의 반주기별 ease가 t=0.25에서 0.394730↔0.5로 다르다.
이는 [#6294](https://github.com/coco-de/coui/issues/6294)에 기록한 수정 전 원인이다.
후속 수정에서 Web도 전체 주기의 easing 뒤 sine을 적용하고 중간 구간을 검사했다.
Progress의 t=0은 track만 보여 fill 비율·속도 회귀를 검증하지 못한다.

Swiper의 초기 드래그 영역과 완전 열림도 구분한다. 실제 드래그를 끝까지 진행한
검사에서는 Drawer mount 뒤 배경 inert가 후속 입력을 차단하는 별도 문제가 발견됐다.
[#6296](https://github.com/coco-de/coui/issues/6296)에 실제 registry 재현과 독립
Chrome inert A/B 실험을 기록했다. 후속 수정에서는 문서 수준 Pointer Events로
추적하고 실제 registry의 완전 열림까지 검사했다. 초기 캡처 결과 자체가 완전 열림을
증명하는 것은 아니다.

나머지 298칸에는 글자 래스터, 소수점 기하, 공개적으로 근사하기로 한 점선,
host 범위 차이 등이 남는다. 모두 불가피한 엔진 차이라고 확정하지 않는다.
특히 Mockup의 옛 Web root PNG는 바깥 돌출부를 잘랐으므로, PNG에 여백을 붙이는
후처리로 일치를 주장하지 않는다. 공통 800 host를 실제 재촬영하는 후속 검증이 필요하다.
