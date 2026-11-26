# BDD Acceptance Criteria: figma-contract-components

> PRD `.bmad/prd-figma-contract-components-2026-08-07.md` 의 인수 조건 정본. 실행 표면: Dart 골든/유닛 테스트(exporter), TS selftest(빌더·G10), 가드 스크립트(CI), Figma 실행 로그(마이그레이션·멱등).

## Feature: schema v3 — 축 데이터 (FR-001)

```gherkin
Scenario: variant 축 enum 멤버 전수 export
  Given coui_core 에 CoreButtonVariant enum 이 12개 멤버를 갖는다
  When melos run export:figma-components 를 실행하면
  Then components.json 의 button.axes.variant.members 는 12개 멤버 전부를 소스 선언 순서로 담고
  And defaultVariant 를 선언한 enum(예: CoreTabVariant)은 그 멤버가 default 로 실리며
  And 선언하지 않은 enum(CoreButtonVariant 등 7종)은 default 가 null 이다 (첫 멤버 추정 금지)

Scenario: state 축 판별 술어 — 정확 일치만
  Given state 축은 Core{Component}State 이름이 정확히 일치하는 enum 만 승격한다
  And checkbox 의 값은 tristate bool? 이고 그 이름의 enum 을 선언하지 않는다
  And navigation_bar_variant.dart 에 CoreNavigationBarMode 등 비-규약 enum 이 있다
  When export 를 실행하면
  Then checkbox.axes.state 는 부재하고 checkbox.axes.other[] 에도 실리지 않으며
  And navigation_bar.axes.state 는 부재하며 CoreNavigationBarMode 는 navigation_bar.axes.other[] 에 멤버 전수로 등장한다

Scenario: v2 하위호환
  When v3 export 를 실행하면
  Then 기존 v2 키(fields/variants/sizes)는 byte-단위로 불변이고 G1·G3·G4·기존 selftest 가 green 이다
```

## Feature: schema v3 — 섹션·docs·예시 (FR-002~004)

```gherkin
Scenario: 섹션 fold
  Given tabs 는 coui_flutter/src/components/navigation/ 소속이다
  When export 를 실행하면
  Then tabs.section == "Control" 이고 tabs.sourceCategory == "navigation" 이다

Scenario: 설명 우선순위 — 한국어 우선, 영어 fallback
  Given button 의 content md frontmatter description 이 한국어로 존재한다
  When export 를 실행하면
  Then button.docs.description 은 그 한국어 문자열이다
  Given 어떤 컴포넌트의 content md 가 없고 카탈로그 영어 설명만 있다
  Then 그 컴포넌트의 docs.description 은 영어 fallback 이며 빈 문자열이 아니다

Scenario: 예시는 식 스니펫만
  Given docs 에 tabs_chain_example.dart 가 존재한다
  When export 를 실행하면
  Then tabs.examples.withStyle 은 "withStyle(" 을 포함하는 식 스니펫이고
  And "class " / "StatefulWidget" 같은 보일러플레이트 토큰을 포함하지 않는다
  And chain example 이 없는 컴포넌트도 컨트랙트 파생 canonical 스니펫을 가진다(빈 값 금지)
```

## Feature: 페이지 재구성 (FR-006)

```gherkin
Scenario: 컴포넌트당 페이지 + 명명 + 섹션 블록
  When 플러그인 generate 를 실행하면
  Then 모든 컴포넌트가 자기 "❖ {Component}" 페이지를 갖고 (D-27 — 섹션은 이름에 넣지 않는다)
  And 컴포넌트 페이지가 1개 이상인 섹션마다 헤더 페이지가 정확히 하나 있고 (D-26)
  And 컴포넌트 페이지가 0개인 섹션에는 헤더가 없으며
  And 생성기가 소유하는 페이지 이름은 문서에서 유일하다

Scenario: 디자이너가 강등한 페이지는 옵트아웃이다
  Given 디자이너가 "❖ Stacks" 에서 "❖" 를 빼고 들여써 "  Stacks" 로 강등했다
  When 플러그인 generate 를 실행하면
  Then Stacks 는 빌드되지 않고 "❖ Stacks" 도 새로 생기지 않으며
  And verify 는 Stacks 를 "페이지 없음" 이 아니라 "강등" 으로 센다
  And 강등 페이지만 남은 섹션의 헤더는 있어도 없어도 통과한다 (생성기가 심지도 지우지도 않는다)
```

## Feature: 마이그레이션 — identity 보존 (FR-007·008, NFR-F)

```gherkin
Scenario: 페이지 이동은 key 를 보존한다
  Given 구 "🧩 Components" 페이지에 기존 ComponentNode/Set 들이 있고 실행 전 key 목록을 기록했다
  When 배치 정규화를 포함한 generate 를 실행하면
  Then 모든 노드가 자기 "❖ {Component}" 페이지로 이동했고
  And 실행 후 key 목록이 실행 전과 완전 일치하며(신규 노드 · COMPONENT→COMPONENT_SET 입양 승격 제외)
  And 빈 소스 페이지는 제거된다

Scenario: 마이그레이션 부분 실패 후 재실행 = 복구
  Given 마이그레이션이 중간에 중단돼 일부 노드만 이동됐다
  When generate 를 재실행하면
  Then 이미 이동된 노드는 skip 되고 남은 노드만 이동하며 key 는 여전히 전부 보존된다
  And 소스 페이지는 완전히 빌 때까지 제거되지 않는다

Scenario: static → variant set 입양 승격은 key 를 보존한다
  Given Tabs 가 static ComponentNode 로 존재하고 그 key 를 기록했다
  When 승격을 포함한 generate 를 실행하면
  Then 그 노드는 rename("Variant=underline") 후 새 ComponentSet 의 자식으로 포함되고
  And 자식 ComponentNode 의 key 가 실행 전과 같다 (remove+재생성 금지)
```

## Feature: 4축 완전 조합 (FR-009·010)

```gherkin
Scenario: Button 144 조합
  When generate 후 Button set 을 조사하면
  Then variant 자식 수 == 12(Variant) × 6(Size) × 2(Enabled) == 144 이고
  And 각 자식의 variantProperties 가 세 축 값을 모두 가진다

Scenario: Checkbox — disabled×checked 소실 금지
  When generate 후 Checkbox set 을 조사하면
  Then State=Checked, Enabled=False 조합이 존재한다 (State 축에 Disabled 평탄화 금지)
  And 자식 수 == 1 × 6 × 3 × 2 == 36

Scenario: Tabs pill 노출 (갭 패턴 2 해소)
  When generate 후 Tabs set 을 조사하면
  Then Variant=pill 과 Variant=underline 자식이 모두 존재한다
```

## Feature: 문서 표면 (FR-011~013)

```gherkin
Scenario: Properties 표 전수
  When 임의 표본 10 페이지를 조사하면
  Then 각 페이지 Properties 표에 4축 + axes.other + 나머지 컨트랙트 프로퍼티가 전수로 나열되고
  And 캡션에 컨트랙트 파일 경로가 있다

Scenario: 설명·링크·예시
  Then 표본의 ComponentSet/ComponentNode.description 이 docs.description(우선순위 규칙 적용)과 일치하고
  And documentationLinks 가 docs.url 이며
  And Code Examples 프레임에 예시 ≥2종(기본 생성자 + 슈거 체인 1종 이상)이 있다
```

## Feature: 멱등·hash 입도 (FR-014, NFR-A)

```gherkin
Scenario: 2회차 all-skip (판정 + 시간)
  Given 1회차 generate 가 완료됐다
  When 아무 변경 없이 2회차를 실행하면
  Then 모든 엔트리가 skipped 로 보고되고 프레임 재생성이 0이며 실행 시간이 1회차의 10% 미만이다

Scenario: docs 1건 수정은 1개 엔트리만 재빌드
  Given badge 의 md description 만 수정하고 export 를 재실행했다
  When generate 를 실행하면
  Then badge 엔트리만 rebuilt 이고 나머지 100개는 skipped 다
```

## Feature: 가드 (FR-015·016)

```gherkin
Scenario: G10 — 축 누락 검출 (mutation 검증)
  Given 빌더 하나에서 Size 축 파생을 임의로 제거한다
  When npm run selftest 를 실행하면
  Then G10 섹션이 그 컴포넌트의 size uncovered 를 보고하고 종료 코드 != 0 이다
  And 제거를 되돌리면 uncovered 0 · 종료 코드 0 이다

Scenario: G2 CI 배선
  Given REGISTRY 에 coui_core 에 없는 phantom 이름을 임의 추가한다
  When CI 가드 잡(check_figma_registry_parity.sh)을 실행하면
  Then 잡이 fail 하고, 되돌리면 green 이다
```

> mutation 시나리오(G10·G2)는 "가드는 실패시켜 보기 전까지 가드가 아니다" 룰의 적용 — 구현 PR 에서 실제로 주입·확인 후 되돌린 증거를 남긴다.
