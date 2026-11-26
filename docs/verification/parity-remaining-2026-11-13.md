# 기본 스타일 파리티 잔여 항목 재점검 (2026-11-13)

이 문서는 #6284 시점의 기록이다. 후속 캡처 상태 정렬·추가 수정과 기준 이미지
50칸 승격 결과는 [후속 검증 기록](parity-capture-state-2026-11-13.md)에 있다.
CSV는 기존 측정을 보존하고 `capture_state_*` 열에 후속 결과를 덧붙였다.

이전 [#6131 갱신 11](https://github.com/coco-de/coui/issues/6131#issuecomment-6819405805)의
결과는 162개 컴포넌트·748칸 중 423 통과, 325 실패였다. 프로브 테스트의
실패가 0이라는 결과와 별개이며, 325칸 전부를 엔진 차이라고 결론 내릴 수 없었다.

저장된 325칸을 치수 차이 124칸과 같은 크기의 픽셀 차이 201칸으로 나누어 전부
대조했다. 라이트·다크를 묶어 보되 키는 생략하지 않았다. 키별 원래 측정과 판단은
[CSV](parity-remaining-2026-11-13.csv)에 있다. 후보를 찾은 사람과 별도로 소스·기존
의도·실제 렌더를 검증했다. Workflow 도구 대신 읽기 전용 조수와 순차 수정을 썼다.

원인 수정 후 같은 748칸을 다시 촬영한 결과는 **433 통과·315 실패·인프라 누락 0**이다.
이전 실패 중 rail 2칸, ObjectInput 2칸, 이미지 입력 차이 6칸이 통과로 바뀌었다.
기존 통과가 실패로 바뀐 키는 0개다. 남은 실패는 치수 차이 120칸과 같은 크기의
픽셀 차이 195칸이다. CSV의 `after_result`와 `after_measurement`가 최종 결과다.

## 실제로 고친 것

| 대상 | 원인 | 수정·검증 |
|---|---|---|
| [Toast #6274](https://github.com/coco-de/coui/issues/6274) | Web의 `justify-between` 아래에서 문구 열이 남는 폭을 채우지 않아 오른쪽으로 밀림 | 문구 열이 남는 폭을 채우고 줄어들 수 있게 함. 브라우저에서 아이콘 뒤 문구 시작 위치 검사 |
| [TextField 타이포 #6275](https://github.com/coco-de/coui/issues/6275) | Web은 `placeholderStyle`의 색만 읽었음. 네이티브 입력 리셋은 값의 코드 역할 서체도 덮었음 | placeholder의 역할·직접 지정한 타이포를 별도로 emit. 값은 코드 서체, 힌트는 본문 서체를 유지. 역할 없는 base, 임의 색·크기·굵기·자간과 크기별 base도 브라우저에서 검사 |
| [한 줄 hintText #6281](https://github.com/coco-de/coui/issues/6281) | Flutter는 긴 힌트를 먼저 줄바꿈한 뒤 첫 줄만 보여줌 | 자동 생성한 한 줄 `hintText`만 줄바꿈하지 않게 함. 실제 글꼴의 24px 입력에서 `RenderParagraph.didExceedMaxLines`가 수정 전 true임을 재현. 여러 줄 및 호출자 placeholder Widget 동작을 함께 검사 |
| [Accordion #6276](https://github.com/coco-de/coui/issues/6276) | Web의 무조건적인 `w-full`이 느슨한 flex 부모에서도 800을 채움 | 강제 폭을 제거하고 부모 흐름을 따름. flex 부모에서 내용 폭, 일반 block 부모에서 기존처럼 채움. 호출자 폭·좁은 부모·빈 내용·다음 block과의 간격을 검사 |
| [NavigationBar rail #6277](https://github.com/coco-de/coui/issues/6277) | `min(64px,100%)`가 intrinsic 폭 계산에서 Core 최소 폭을 기여하지 못함 | 아이콘 전용 항목의 기존 내부 요소에 높이 0의 폭 기여 요소를 합성. 한 열 grid로 부모 제약에 따라 줄어들게 함. 81px 자연 폭, 좁은 부모, 직접 지정 폭, margin 검사. 가로 bar는 유지 |
| [상태색 예제 #6278](https://github.com/coco-de/coui/issues/6278) | Web 칩의 block 부모가 내부 label보다 큰 줄 상자를 만들어 네 줄에서 약 12px 누적 | 칩을 flex로 배치. Web 전체 202.39 → 191.14, Flutter 190. 남은 소수점 차이를 토큰이나 오프셋으로 보정하지 않음 |
| [TextStyle 예제 #6278](https://github.com/coco-de/coui/issues/6278) | Web의 실제 문구·스타일 작성법이 Flutter 및 Web 코드 스니펫과 달랐음 | 실행 예제도 `s14 + semiBold + primary` 문자열과 동일한 chain을 사용 |
| [CodeSnippet 캡처 #6280](https://github.com/coco-de/coui/issues/6280) | highlighter Future 대기 화면인데 `pumpAndSettle`만 보고 준비 완료로 기록 | 초기 mount와 실제 highlighter Future 완료를 `runAsync`에서 기다림. 임의 지연이나 모든 FutureBuilder 대기를 넣지 않음. 10초 timeout은 캡처 실패로 처리 |
| [이미지 캡처 입력 #6282](https://github.com/coco-de/coui/issues/6282) | Flutter는 회색 스텁을 쓰는데 Web은 실제 CDN 사진을 받아 다른 입력을 비교했고, 네트워크 timeout도 발생 | 양쪽 캡처가 동일한 400×300 로컬 PNG를 읽음. Web 캡처 페이지만 HTTP 이미지 요청을 대체하고 offline 모드에서 decode 완료를 기다림. 748칸 모두 캡처 완료. 앱의 이미지 요청·실제 문서 예제는 유지 |

Core 디자인 값과 컴포넌트 생성자 인자는 바꾸지 않았다. Web의 기존 공개 함수·상수와
Resolved 생성자·필드도 유지한다. 부모 컴포넌트의 scoped-rule
테스트는 자식 TextField나 Button의 별도 규칙을 세지 않고, 해당 frame id를 실제로
대상으로 삼는 규칙을 검사한다. 단언을 전역 `<style>` 개수로 대신하지 않는다.

## 기존 디자인 결정과 API 범위 재검토

디자이너 이슈의 최초 표뿐 아니라 뒤의 정정 답변도 대조했다.

| 수정 | 기존 의도의 근거 |
|---|---|
| ObjectInput 힌트 | [#5831](https://github.com/coco-de/coui/issues/5831)의 ObjectInput 자리표시를 Pretendard 15 · Body/Large로 정한 표와 디자이너 작성 커밋 `2f54389397`의 Core 기본값. 값은 Code/MD, 힌트는 Body/Large라는 별도 슬롯을 그대로 읽는다. 한 줄 힌트의 줄바꿈 수정도 같은 글자·폭·서체를 유지한다 |
| rail 최소 폭 | [11-04 최종 정정](https://github.com/coco-de/coui/issues/5740#issuecomment-6621983921)은 Label=none을 64×40, 알약을 48×28로 명시한다. 초기 56px 결정으로 되돌리지 않는다. Core 최소 폭 64와 부모 제약에 양보하는 조건을 함께 구현한다. 새 치수 토큰은 없다 |
| Toast 문구 배치 | 기존 Flutter의 `Expanded` 문구 열과 같은 남는 폭 배분. [디자이너의 닫기·문구 여백 결정](https://github.com/coco-de/coui/issues/6214#issuecomment-6814600718)인 오른쪽 48, 끝 인셋 8, 세로 가운데를 유지한다. 글리프는 이후 #6257의 18 결정을 유지한다 |
| Accordion 폭 | 근거는 `4ac87ac7a2`(#1350, 2026-05-09)부터 유지된 Flutter `IntrinsicWidth`와 Flutter-first 원칙이다. 247px는 이 예제 내용의 측정값이다. 새로운 디자이너 고정 폭 명세로 취급하지 않는다. 일반 block 부모, flex 부모, 호출자 지정 폭·좁은 부모를 각각 검증했다 |
| 문서·캡처 | 상태색·TextStyle은 양쪽 예제의 같은 내용·스타일을 보여 준다. highlighter 완료 대기와 공통 이미지 fixture는 비교 입력·시점에만 적용된다 |

공개 API를 늘리지 않고 기존 계약을 구현한다.

| 범위 | 최종 상태 |
|---|---|
| Flutter/Web 컴포넌트 생성자·Core Contract·Core Style | 기존 필드·필수 인자·기본값 유지 |
| Web 공개 유틸·상수 | `core_to_css.dart`와 `web_layout.dart`는 origin/main과 바이트 단위로 동일 |
| Web `src`의 기존 Resolved·resolver | 기존 필드·생성자·함수 인자 유지. 직접 `implements`한 소비자에게 새 getter 요구 없음 |
| 새 렌더 보조 처리 | TextField의 private 함수·상수, NavigationBar 라이브러리의 private part와 private 함수로 한정 |

TextField는 기존 `placeholderStyle`을 읽어 입력별 CSS 변수를 내고, private 규칙이
해당 값만 `::placeholder`에 적용한다. 값의 서체 보완도 TextField private 헬퍼에 둔다.
Rail의 Core 최소 폭 계산은 기존 resolver의 destination CSS 변수로 전달하고,
private part가 기존 paint-ready 결과에서 구조만 구성한다. 공개 Resolved 슬롯을 더하지 않는다.

변경한 패키지 라이브러리·part와 공개 유틸 11개 파일을 Dart AST로 origin/main과
대조했다. 공개 선언·필드·생성자·함수 인자 차이는 0건이고 새 part의 공개 선언도 0개다.
이는 호출 API의 비교다. 렌더 동작은 이 PR에서 의도적으로 바뀐다(Accordion의 느슨한
부모 폭, rail 최소 폭, Toast 문구 위치와 입력 힌트). 현재 Figma 캔버스를 다시 생성·검수한
결과를 뜻하지 않는다.

## 원래 325칸에서 대조한 나머지

| 분류 | 칸 | 판단 범위 |
|---|---:|---|
| 치수 차이의 실제 컴포넌트 후보 | 6 | Accordion·rail·Toast, 각 라이트·다크. 위 수정에 반영 |
| 치수 차이의 예제 후보 | 4 | 상태색·TextStyle, 각 라이트·다크. 위 수정에 반영 |
| 작은 소수점 기하 차이 | 78 | PNG와 원시 치수를 대조. 작은 차이라는 이유만으로 불가피한 엔진 차이라고 확정하지 않음 |
| 캡처 호스트 차이 | 18 | Mockup·Swiper·Responsive 계열. 내용과 호스트의 측정 범위를 구분 |
| 네이티브 caret 여유 폭 | 5 | SelectableText와 강조가 완료된 CodeSnippet. Flutter의 caret 여유를 Web padding으로 흉내 내지 않음 |
| 캡처 시점 | 5 | SSR 카운트·responsive 초기 상태와 CodeSnippet highlighter 대기. CodeSnippet 준비 판정은 위에서 수정 |
| 기존 Kbd 헤어라인 결정 | 8 | 기존 플랫폼 결정을 유지 |
| 같은 크기의 글자·도형 래스터 | 166 | 모든 쌍을 대조해 새 구조·문구 후보는 찾지 못함. 모두 불가피한 엔진 차이라는 보장은 아님 |
| placeholder 타이포 후보 | 2 | ObjectInput 라이트·다크. Web 타이포와 Flutter 힌트 줄바꿈을 각각 수정 |
| 애니메이션 단계 | 12 | 정지 상태가 서로 다른 캡처 |
| 이미지 입력 차이 | 6 | 원래 Flutter의 회색 스텁과 Web의 실제 사진을 비교했음. 위에서 같은 입력으로 수정한 뒤 모두 통과 |
| SSR 측정 전 상태 | 1 | StageContainer는 Web 초기 측정 폭이 없고 Flutter는 이미 측정함 |
| DisclosureBadge 점선 패턴 | 2 | Core의 고정 3/2와 CSS native dash 패턴이 다름. 공개 override 누락은 아니며 이 변경에서는 유지 |
| Frame 점선·글자 래스터 | 2 | 새 캡처에서 같은 문구임을 확인. 처음의 문구 차이 의심을 기각 |
| 글자 장식 래스터 | 10 | 밑줄 등 래스터 차이 |
| 합계 | 325 | 누락 0 |

## 검증 방식과 남는 한계

- `remaining_layout_probe_test.dart`는 실제 Chrome의 상자와 `::placeholder` 계산값을
  읽는다. 클래스 문자열만 맞추는 테스트가 아니다.
- Flutter 힌트 테스트는 실제 Pretendard를 로드하고 렌더된 문단의 잘림·줄바꿈을 읽는다.
- 기본 스타일 748칸의 Flutter·Web을 모두 최종 코드로 촬영했다. 외부 사진 입력을
  통일한 오프라인 캡처에서 인프라 누락은 0개다. 공개 API를 유지하도록 내부 처리를
  정리한 뒤에는 관련 변형·스타일·입력 합성 예제 162개를 추가 촬영했고, 정리 전 캡처와
  치수·픽셀이 모두 동일했다(누락·픽셀 차이 0).
- 픽셀 비교는 여전히 치수가 1px만 달라도 실패한다. 따라서 문구 배치를 고쳐도
  줄 높이 1px 차이가 남으면 같은 칸이 계속 실패할 수 있다. 실패 개수만으로
  실제 결함 수정 건수를 대체하지 않는다.
- 허용 목록과 픽셀 임계값은 변경하지 않았다. 기준 이미지도 이 PR에서 승격하지 않는다.
- 전체 수동 CI를 실행한 결과로 적지 않는다. 실행한 로컬 테스트·빌드와 캡처 결과는
  PR의 검증 표와 이미지 증거에 기록한다.

## 실행한 로컬 검증

| 검증 | 결과 |
|---|---|
| 변경한 Dart 21개 파일 `dart analyze --fatal-infos` 및 포맷 | 진단 0·포맷 차이 0 |
| Web form·navigation·layout·overlay·util | 2,393 통과 |
| Flutter form (실제 글꼴 힌트 회귀 3개 포함) | 1,502 통과 |
| docs registry | 1,524 통과 |
| parity 도구 전체 | 1,064 통과·3 skip (이미지 fixture 추가 전 실행) |
| 이미지 fixture 반영 후 Web backend | 18 통과 |
| 실제 Chrome 레이아웃·placeholder 회귀 | 7 통과 |
| `docs_site`의 `jaspr build` | 355 routes 생성 성공 |
| defaultStyle 라이트·다크 교차 플랫폼 픽셀 비교 | 433 통과·315 실패·0 infra-skip |
| 변경한 5개 컴포넌트 전체 등록 스타일·변형의 자체 baseline 비교 | 98쌍·196 플랫폼 캡처 중 146 통과·50 차이·0 infra-skip |
| API 보존 후 공개 선언 비교 | 패키지 라이브러리·part·유틸 11개 파일, 공개 선언 차이 0 |
| API 보존 후 Web 관련 테스트·실제 Chrome 회귀 재실행 | 2,393 통과·7 통과, 변경 파일 analyze 진단 0 |
| API 보존 후 Web 재촬영·빌드 | 162개 모두 정리 전과 픽셀 동일, 355 routes 빌드 성공 |

교차 플랫폼 비교의 실패 315칸을 통과라고 쓰지 않는다. 전체 스타일·상호작용 상태에
대한 무불일치 보증도 아니다. 자체 baseline 회귀 비교는 별도이며 PR에 수치를 적는다.

자체 baseline 차이 50개는 Accordion Web 8개, rail Web 10개, ObjectInput 양쪽
20개, Toast Web 10개와 TextField Web 2개다. 앞의 48개는 위에서 고친 렌더다.
나머지는 `text-field-{default,error}-dark-liquidGlass`: `origin/main`의 Web 패키지를
별도 디렉터리에 읽어 같은 하니스로 다시 캡처했으며 이번 결과와 픽셀이 완전히 같았다.
즉 기존 baseline과 main의 차이다. baseline을 승격하거나 allowlist로 승인한 항목은 0개다.
