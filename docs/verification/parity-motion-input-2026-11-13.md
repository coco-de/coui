# Loading.bar와 Swiper 동작 수정 (2026-11-13)

Part of [#6131](https://github.com/coco-de/coui/issues/6131),
[PR #6297](https://github.com/coco-de/coui/pull/6297).
이전에 분리했던 [#6294](https://github.com/coco-de/coui/issues/6294)와
[#6296](https://github.com/coco-de/coui/issues/6296)을 같은 PR에서 수정했다.
Core 디자인 값과 기존 공개 패키지 API를 유지한다.

## Loading.bar

Flutter는 전체 주기의 `CoreEasing.move`를 계산한 뒤 `sin(eased × π)`를
이동 비율로 사용한다. 이전 Web은 각 반주기에 easing을 다시 적용했다.
주기의 0·0.5·1에서는 같아도 0.25에서 이동 비율이 0.394730↔0.5로 달랐다.

Web도 같은 순서로 계산한다. 비상속 numeric CSS property를 0→1로 한 번
보간하고, 같은 fill 요소의 transform에서 sine을 적용한다. 이동 거리는 기존
Core fill 비율 0.35에 따라 `(track − fill)`이다. 새 duration·ratio·easing
인자를 추가하지 않았다. 기존 transform 애니메이션의 합성 레이어를 유지해
매 프레임 paint와 초기 화면의 래스터 변화도 피한다.

실제 SSR에서 numeric property 등록을 검사한다. `syntax`의 angle bracket는
CSS escape로 출력해 Jaspr의 HTML 처리에 손상되지 않게 한다. Chrome에서
`CSSPropertyRule.syntax`가 실제 `<number>`인지 검사하며, 서로 다른 fill의
phase가 독립적으로 보간되는지도 확인한다.

양 플랫폼의 기본값·테마·variant·인스턴스·size-step 5개 설정을 같은 fixture로
검사했다. 각 설정의 주기 0·0.125·0.25·0.5·0.75·0.875·1·1.125를 사용한다.
Web은 라이트·다크 80개, Flutter는 40개 실제 렌더 좌표를 측정했다.
[모든 측정값 CSV](loading-bar-motion-2026-11-13.csv)에 속도·폭·높이·phase·좌표를
기록했다. 인스턴스 duration 1237ms·전체 길이 400에서 quarter의 Web 위치는
102.63이며, 정확한 Core 계산은 102.629848653이다. 기존 반주기 방식의 130과
구별된다.

Flutter `Cubic`의 수치 해법은 브라우저보다 오차 허용 범위가 크다. 같은 설정의
Flutter 위치는 102.272036483이며 전체 샘플에서 양 플랫폼 최대 차이는 약
0.358 logical px다. 동일한 함수·duration·입력으로 고쳤다는 결과이며 모든
프레임의 픽셀이 완전히 같다는 보증은 아니다. Flutter의 실제 adapter 결과는
0.005 logical px, Web의 정확한 Core 계산은 0.03 logical px 안에서 검사했다.
이는 동작 테스트의 수치 해석이며 기존 픽셀 gate 임계값을 바꾸지 않는다.

## Swiper

기존 자식의 mousemove/up 리스너는 Drawer mount 직후 배경에 걸리는 inert
때문에 후속 입력을 받지 못했다. 기존 `registerDragListeners`를 재사용해
시작 pointerId의 document pointermove/up/cancel을 추적한다. 모달 격리는
유지한다. 수평은 `pan-y pinch-zoom`, 수직은 `pan-x pinch-zoom`으로 다른 축
스크롤과 확대를 보존한다. 비활성화 시 정책은 auto다.

포인터 종료·취소·window blur·문서 숨김·비활성화·방향 변경·controlled close·
소유자 dispose에서 추적을 정리한다. 단순 클릭과 자식 버튼의 focus/click은
유지하고, 다른 pointer가 진행 중인 제스처를 바꾸거나 끝내지 못하게 한다.
commit은 true 한 번, 이후 정상 dismiss는 false 한 번이며 abort는 둘 다 0번이다.
이미 열린 Drawer는 gesture enabled=false만으로 닫지 않는다.

Drawer 완료 콜백은 session을 확인해 오래된 완료가 새 제스처를 지우지 못하게 한다.
Escape 이후 늦게 온 pointerup은 Swiper가 종료된 제스처의 progress와 리스너를
확인해 무시한다. 공개 `DrawerScrubController`를 영구 종료하지 않는다. 명시적인
`update`는 다시 scrub을 시작하고, 반복 `settle`은 새 요청을 반영한다. 같은
컨트롤러를 다음 Drawer mount에서 다시 사용할 수 있다. mount 전에 들어온 최신
settle은 private 상태로 재생하고, entry가 dispose되면 그 기록을 지운다.
이미 닫기 시작한 entry는 예약 frame에서 다시 열지 않는다.

앞선 구현의 일회성 guard는 재사용을 제한했다. 공개 호출 순서
`update(.3) → settle(open: true/false) → update(.7)`의 회귀 검사 2개가 수정 전
실패하고 수정 뒤 통과했다. 실제 Chrome에서도 열린 Drawer의 재-scrub,
`settle(true) → settle(false)`, 같은 컨트롤러로 세 차례 연속 mount가 통과한다.

실제 문서 registry의 800px 예제에서 카드 밖 x560에 시작한 마우스 드래그가
inert 이후에도 이어지고 Drawer가 x0까지 완전히 열림을 확인했다. 별도 실제
컴포넌트 검사는 drawer/sheet × 네 방향, native touch, 취소 후 재시도와
위 lifecycle 경로를 검사한다. mount 전 종료 경쟁만 같은 task에 연속 이벤트를
dispatch해 재현하고, 일반 마우스·터치 추적은 Chrome의 trusted 입력을 사용한다.

## 검증

| 명령·범위 | 실제 결과 |
|---|---|
| `dart test .../loading_bar_motion_probe_test.dart` | 라이트·다크 2 통과·80개 phase 좌표 |
| `flutter test test/parity/loading_bar_motion_test.dart` | 5 통과·40개 native 좌표 |
| `dart test .../swiper_scrub_probe_test.dart` | 기존 입력·lifecycle 22개 + 공개 컨트롤러 호환성 3개 |
| `dart test test/components/overlay` | 공개 재사용 회귀 2개를 포함한 300 통과 |
| `dart test .../capture_state_test.dart` | 실제 registry 완전 열림을 포함한 6개 검사 |
| 기존 Drawer fling·rubber band·modal dismiss 실제 Chrome | 79 통과 |
| Web overlay·Loading | 326 통과 |
| Flutter Swiper·Loading·초기 pose·새 motion | 30 통과 |
| Web Loading·Swiper 모든 등록 스타일·변형 52개 재촬영 | 앞선 최종 캡처와 PNG 픽셀 차이 0 |
| 공개 API AST 대조 | 패키지 라이브러리·part·유틸 12파일, 공개 선언 차이 0 |

기준 이미지·allowlist·픽셀 임계값을 추가 변경하지 않았다. 정적 화면이 같아도
동작이 다를 수 있으므로 초기 pose 회귀와 주기 중간·실제 입력 회귀를 함께 유지한다.
최신 main 통합 후의 451 통과·297 교차 플랫폼 잔여 실패도 이 두 동작 수정의
초기 화면 차이 없이 유지된다. 전체 플랫폼·모든 상태의 무불일치 보증은 아니다.
