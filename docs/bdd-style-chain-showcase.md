# BDD Acceptance Criteria: style-chain-showcase

- 일자: 2026-08-07 · AC 원본: LOCKED seed spec §5 (AC-1~AC-11, AC-4 결번)
- 표기: 실행 하네스 무관 Gherkin — 검증 방법 칼럼은 seed spec §5·tech-spec TR-8 참조.

## Feature A: chain 갤러리 노출 (REQ-A1/A2/A4/A5)

```gherkin
Feature: 컴포넌트 문서의 chain 슈거 체인 갤러리

  Scenario: Style 슬롯 보유 컴포넌트 문서에 chain 갤러리가 노출된다  # AC-1
    Given kDocsChainPreviewMode 가 appended 이고
    And 컴포넌트가 chain 스니펫을 보유한다 (docsComponentHasChainPreview == true)
    When 그 컴포넌트 md 페이지가 렌더된다
    Then variant 갤러리 마지막 item 으로 'chain' 라벨 패널이 나타난다
    And 선언된 기존 variant 목록은 순서 그대로 유지된다

  Scenario: 선언 variant 가 없던 컴포넌트는 default 뒤에 chain 이 붙는다  # AC-1
    Given md 가 variants 를 선언하지 않은 컴포넌트
    When 페이지가 렌더된다
    Then 갤러리는 [default, chain] 순서다

  Scenario Outline: chain 예제가 자기 티어 요소를 충족한다  # AC-2
    Given 실측표에서 <컴포넌트> 의 티어가 <티어> 다
    When 그 *_chain_example.dart (Flutter·Web 쌍) 를 검사한다
    Then <필수 요소> 를 모두 포함하고 순열 dispatch 배관은 포함하지 않는다
    Examples:
      | 컴포넌트   | 티어 | 필수 요소 |
      | button 급  | T1  | radius getter ≥1, 색 getter ≥1, 조합 체인 ≥1, withStyle 고유 필드 ≥min(n,3) |
      | slider 급  | T2  | 보유 축 getter ≥1, 보유 축 내 조합, withStyle 고유 필드 ≥min(n,3) |
      | checkbox 급 | T3  | withStyle 고유 필드 ≥min(n,3) 만 |

  Scenario: 코드 스니펫이 예제와 동일하다  # AC-3
    Given 임의의 chain 예제
    When _code.dart 의 'chain' 스니펫과 example 클래스 전문을 비교한다
    Then 두 텍스트가 동일하다 (import 제외)

  Scenario: Style 슬롯 보유인데 chain 예제가 없던 컴포넌트가 보충된다  # AC-2/A5
    Given 실측표가 withStyle 보유(131) 대비 chain 예제 부재 갭을 나열한다
    When Part A 가 완료된다
    Then 갭 목록의 모든 컴포넌트에 chain 예제 쌍이 존재하거나 제외 목록에 사유와 함께 올라 있다
```

## Feature B: 랜덤 순열 토글 (REQ-B1/B7/B9 — T1 한정)

```gherkin
Feature: T1 컴포넌트의 랜덤 순열 토글

  Background:
    Given T1 컴포넌트의 md 페이지가 열려 있고 chain 갤러리 패널이 보인다

  Scenario: 랜덤 버튼이 T1 에만 노출된다
    Then T1 chain 패널에는 랜덤 버튼이 있다
    And T2/T3 컴포넌트의 chain 패널에는 랜덤 버튼이 없다

  Scenario: 클릭 시 세 표면이 같은 순열을 동시에 반영한다  # AC-5
    When 랜덤 버튼을 1회 클릭한다
    Then Web 팬의 computed style 이 새 순열의 radius·색 토큰 값을 갖는다
    And Flutter 팬이 같은 순열을 렌더한다
    And 코드 패널(Web 탭·Flutter 탭 모두)의 체인 코드에 같은 순열의 getter 이름이 표시된다
    And 세 표면이 서로 다른 순열을 보이는 상태는 존재하지 않는다 (settled 기준 — flow I-1: 반영 완료 대기 후 판정, 프레임 경계 순간 샘플 금지)  # REQ-B7 파리티

  Scenario: 재마운트 부작용이 없다  # M-1 회피 검증
    When 랜덤 버튼을 연속 5회 클릭한다
    Then Flutter embed 는 스켈레톤을 다시 표시하지 않는다
    And 프리뷰 패널의 높이 제약(constraints)이 유지된다

  Scenario: 같은 페이지의 다른 프리뷰 패널은 영향받지 않는다  # per-panel 스코프
    Given 같은 페이지에 다른 variant 패널들이 렌더되어 있다
    When chain 패널의 랜덤 버튼을 클릭한다
    Then chain 패널만 갱신되고 다른 패널의 스타일·코드는 변하지 않는다

  Scenario: 다크모드 전환과 직교한다
    Given 랜덤 순열이 적용된 상태다
    When 사이트 테마를 dark 로 전환한다
    Then 순열(토큰 좌표)은 유지된 채 두 팬 모두 dark 값으로 재해석된다

  Scenario: surface 스타일 전환과 직교한다  # flow R-1
    Given 랜덤 순열이 적용된 상태다
    When 헤더의 surface 스타일을 전환한다
    Then 순열(토큰 좌표)은 유지된 채 두 팬 모두 새 표면 스타일로 재해석된다

  Scenario: Copy 는 지금 보이는 순열 코드를 복사한다  # flow G-1
    Given 랜덤 순열이 적용된 상태다
    When Copy 버튼을 누른다
    Then 클립보드 내용이 코드 패널에 표시된 현재 순열 코드와 동일하다
```

## Feature C: 결정성·코드 파생 (REQ-B2/B3)

```gherkin
Feature: 순열 시퀀스 결정성과 코드 치환

  Scenario: 같은 seed·같은 클릭 횟수는 같은 순열이다  # AC-6
    Given seed S 로 초기화된 순열 시퀀스 두 개
    When 각각 k 번 전진시킨다
    Then 두 시퀀스의 k 번째 순열 좌표가 동일하다

  Scenario: 치환은 실재 getter 이름만 생성한다  # AC-7
    Given 실측표의 T1 컴포넌트 getter 이름 목록
    When 모든 (radiusIndex, colorIndex) 조합으로 코드 치환을 실행한다
    Then 산출된 모든 getter 이름이 그 목록에 존재한다 (미존재 이름 0)

  Scenario: 치환 앵커가 base 스니펫에 존재한다  # REQ-B3 앵커
    Given T1 의 동기화된 base 스니펫
    Then 양축 getter 리터럴이 각 1개 이상 포함되어 있다
    And 그 리터럴이 초기(클릭 전) 코드 패널 표시와 일치한다

  Scenario: 순열별 스니펫 저작물이 존재하지 않는다  # 209-금지
    When _code.dart 파일들을 검사한다
    Then 순열 조합별로 저작된 스니펫 분기는 없다 (chain base 1개만)

  Scenario: 시퀀스는 전 조합을 중복 없이 순회한다  # flow R-2
    Given 양축(19×11=209) T1 컴포넌트의 순열 시퀀스
    When 시퀀스를 209회 전진시킨다
    Then 209개 좌표가 전부 서로 다르고 (전 조합 커버)
    And 210번째 좌표는 첫 좌표와 같다 (base 복귀 순환)
```

## Feature D: 접근성·기술 경계 (REQ-B5/B6, AC-9/AC-11)

```gherkin
Feature: 접근성과 경계 게이트

  Scenario: 키보드만으로 랜덤 토글을 조작한다  # AC-9
    When Tab 으로 랜덤 버튼에 포커스를 이동하고 Enter(또는 Space)를 누른다
    Then 포커스 표시가 보이고 순열이 전환된다
    And 버튼에 의미 있는 aria-label 이 있다

  Scenario: 순열 모듈은 순수 Dart 다  # AC-11
    When docs_core/lib/shared/ 순열 모듈의 import 그래프를 grep 한다
    Then jaspr·Flutter import 가 0 이다

  Scenario: 인터랙션 코드는 @client 경계 안에만 있다  # AC-11
    When 랜덤 토글 이벤트 핸들러의 파일 위치를 검사한다
    Then 전부 @client 아일랜드 소속이고, dynamic event dispatch 가 0 이다 (EventHandlers 경유)
```

## Feature E: 게이트·회귀 (AC-8/AC-10)

```gherkin
Feature: transport PoC 게이트와 회귀 없음

  Scenario: PoC 가 채널 요구를 증명한다  # AC-10 — Epic 최선두
    Given T1 중 variant 갤러리와 chain 이 공존하는 대표 컴포넌트(button 급)
    When per-panel 채널 PoC 로 랜덤 전환을 시연한다
    Then 세 표면 동시 갱신·재마운트 무부작용·per-panel 스코프가 모두 확인된다

  Scenario: PoC 실패 시 Part B 만 중단된다  # 게이트 분기
    Given PoC 가 채널 요구를 만족하지 못했다
    Then Part B 스토리는 착수하지 않고 재설계 이슈로 회부된다
    And Part A (예제 확충 + appended 전환) 는 영향 없이 진행된다

  Scenario: 기존 문서·프리뷰 회귀가 없다  # AC-8
    When 전체 docs 테스트 스위트와 변경 라인 analyze/dcm 을 실행한다
    Then 실패 0 · 신규 이슈 0 이다
    And hidden 이던 시절의 기존 variant 갤러리 렌더 결과는 변하지 않았다 (chain 추가 외)
```
