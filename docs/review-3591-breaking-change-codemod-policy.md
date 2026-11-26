# Breaking change codemod 정책 검토 — Astryx `astryx upgrade` 패턴 vs `deprecation.md`

- 일자: 2026-08-02
- 이슈: [#3591](https://github.com/coco-de/coui/issues/3591) (Epic E — 장기 AI · 생태계 인프라, 탐색)
- 산출물 성격: **결정 산출물** — 구현이 아니다 (`.claude/docs/docs-benchmark-followup/zenhub/priority.md` p2 근거란). 이 문서는 "지금 코드를 어떻게 바꿀지"가 아니라 "이 패턴을 CoUI 에 결합해도 되는지, 결합한다면 무엇부터인지"를 판정한다.
- 관련: `docs/docs-benchmark-2026-08-01.md` §4 "장기 비전"(line 67) · `.claude/rules/process/deprecation.md`(CoUI deprecation 정책, 이 검토의 대상)

## 한 줄 결론

**부분 결합 가능, 전면 자동화는 불가능** — Astryx `astryx upgrade` 의 "breaking마다 codemod 자동 첨부"라는 **형태**는 CoUI 의 명명 규칙(rename) 부류에 한해 저비용으로 흉내 낼 수 있지만, `astryx upgrade` 가 실제로 하는 일의 대부분(React 컴포넌트 트리의 구조적 재작성, 즉 jscodeshift/ts-morph 급 AST 변환)에 대응하는 CoUI breaking change 부류(시맨틱 변경 · 필드 분리 · Style 슬롯 이관)는 자동 코드 변환 자체가 원리적으로 안전하지 않다. 그래서 이 검토가 내리는 판정은 "전부 자동화" 도 "전부 거부" 도 아니라, **deprecation 이 이미 요구하는 것(대체재 이름 · 이유 · 시작 버전)에서 자동 도출 가능한 rename 류만 codemod 를 붙이고, 나머지는 지금처럼 마이그레이션 가이드(산문 + diff)로 남긴다**는 **분류 정책**이다.

## 1. 두 시스템이 실제로 하는 일 (사실 확인)

### 1.1 Astryx `astryx upgrade`

`docs/docs-benchmark-2026-08-01.md:27` — "Breaking 마다 **codemod 자동 첨부**(`astryx upgrade`)". Astryx 는 React 컴포넌트 라이브러리이므로, breaking change 의 실체는 대부분 **JSX 트리의 구조적 치환**이다: prop 이름 변경, prop 값 enum 변경, 컴포넌트 분리/합병, children 구조 변경. 이런 변경은 JS/TS 생태계에서 `jscodeshift` 류 AST-투-AST 변환기로 기계적으로 재현 가능하다 — 정적 타입이 없어도(TS 라면 타입 정보까지 활용해) "이 JSX 노드를 찾아 저 형태로 바꿔라"가 결정적(deterministic) 규칙으로 표현되는 경우가 많다.

### 1.2 CoUI `deprecation.md` — 지금 이미 하는 일

이 저장소는 [deprecation 정책](contributing/upgrading.md#deprecation)가 이미 상세한 정책을 갖고 있다. 핵심 요지:

- 모든 패키지가 `0.x`, breaking 은 마이너 상승. `@Deprecated` 메시지에 `since <major>.<minor>` 필수 — **`scripts/guards/structure/check_deprecation_policy.sh` 가 CI 에서 강제**(ratchet baseline, net-new 위반만 차단). 이 가드는 "창을 셀 수 있는가"만 보고, 대체재 이름의 정확성이나 이유의 진실성은 사람 리뷰 몫이라고 스스로 명시한다.
- 예고는 대체재가 동작하는 릴리스와 같은 릴리스에 붙는다. 메시지는 **무엇이 대체하는가 · 왜 · 언제부터** 세 가지를 담는다.
- 제거는 예고로부터 **최소** 두 마이너 뒤(하한, 최댓값 아님).
- **제거 PR 은 옛 코드 → 새 코드 를 실제 코드로 보인다** — "기계적 치환이 안전하지 않은 경우(의미가 달라진 경우)는 그 사실을 먼저 적는다"라는 문장이 이미 있다.

즉 CoUI 는 이미 "예고 → 유지 기간 → 대체 경로 제시"라는 **뼈대**를 갖고 있다. `astryx upgrade` 가 더하는 것은 그 "대체 경로 제시"를 **산문(옛 코드→새 코드 diff)에서 실행 가능한 변환기**로 승격하는 것뿐이다 — 새 개념을 들여오는 게 아니라 기존 정책의 한 조항을 강화하는 문제다.

## 2. CoUI breaking change 의 실제 분류 — codemod 적합도가 부류마다 다르다

`deprecation.md` 자체와 이 저장소의 CoUI 엔지니어링 룰(`.claude/rules/`)에서 관찰되는 breaking change 부류를 codemod 적합도 순으로 나열한다.

| # | 부류 | 예 | AST 변환으로 결정적(deterministic) 표현 가능한가 | codemod 적합도 |
|---|---|---|---|---|
| A | **순수 이름 변경(rename)** — 시그니처·의미 불변 | `CoreCardElevation` → 필드명만 변경, 클래스/파일 rename(`code-style/naming.md` 의 `List`→`Listing`, `Stack`→`StackLayout` 류) | Yes — find-and-replace 수준, 타입 검증까지 자동화 가능 | **높음** |
| B | **필드 이동(같은 타입, 다른 소유자)** — nested Style 슬롯 이관 | `labelColor`/`labelFontSize` 평면 필드 → `labelStyle: CoreTextStyle?` 슬롯 결합(`core/style-contract.md` "Child Component Composition") | 반자동 — 값 이동은 기계적이지만 **여러 평면 필드가 하나의 nested 값으로 합쳐지는 지점**은 호출부마다 사람이 "이 조합이 맞는 병합인가"를 확인해야 함 | **중간** — 변환 스캐폴드는 자동, 최종 검증은 사람 |
| C | **soft-requiredness 변경** — optional→required 또는 반대 | `enabled: bool` → `bool?` + `?? (onX != null)` (`cross-platform/api.md`) | 대체로 가능하지만 **콜백 존재 여부로 기본값을 유도하는 로직**은 호출부의 의도(콜백이 왜 없는지)를 코드가 모름 | **낮음** — 자동 escape가 필요한 곳을 못 찾음 |
| D | **시맨틱 재구성** — 컴포넌트 합병/분리, 우선순위 변경 | `Separator` → `Divider` 통합(`code-style/naming.md` "얇은 선 = `Divider` 하나"), merge chain 우선순위 재배치(`resolver/resolver-pattern.md`) | No — 옛 API 의 여러 필드가 새 API 의 한 필드로 **의미가 재해석**되며, 그 재해석 규칙 자체가 코드가 아니라 디자인 판단 | **없음** — 마이그레이션 가이드(산문)만 |
| E | **default 값 변경** — 시그니처는 그대로, 런타임 동작만 변화 | `enabled` 기본값 유도 방식 변경으로 인한 "동작 변화" (`cross-platform/api.md` "머지 전 사용자 승인 필요") | 애초에 AST 로 감지 불가 — 소스 텍스트가 안 바뀌는데 동작이 바뀜 | **codemod 대상 아님** — CHANGELOG 경고만 가능 |

**핵심 관찰**: Astryx 가 React 세계에서 codemod 를 "breaking마다 자동 첨부"할 수 있는 이유는, React 컴포넌트 트리 변경의 대다수가 부류 A/B 수준(prop rename, prop 재배치)에 머물기 때문이다. CoUI 의 breaking change 이력(`deprecation.md` 자체가 인용하는 실제 사례들 — `Separator`→`Divider`, `CoreCardElevation` 필드 정리, `enabled` soft-requiredness)은 A~E 전 부류에 걸쳐 있고, 그중 자동 변환이 안전한 것은 A, 반자동인 것은 B 뿐이다. "전면 자동화"를 정책 문구로 못박으면 D/E 부류에서 **틀린 자동 변환이 조용히 컴파일되는 코드를 만든다** — 이건 `deprecation.md` 가 이미 경계하는 정확히 그 실패("기계적 치환이 안전하지 않은 경우… 이름만 바뀐 줄 알고 sed 를 돌린 소비자가 조용히 다른 동작을 얻는 것")를 codemod 저자(CoUI) 스스로 저지르는 셈이 된다.

## 3. 저장소에 이미 있는 관련 인프라 (재사용 vs 신규)

- **`dart fix`**: 루트 `pubspec.yaml` 에 `dart fix --apply`/`--dry-run` melos 스크립트가 이미 있다(lint 자동수정 목적). 이는 Dart 자체의 `// ignore: deprecated_member_use` 대응 아님 — analyzer 의 `DeprecationInfo`(Dart SDK 가 `@Deprecated` 애노테이션을 인식해 quick-fix 를 제안하는 표준 메커니즘)와는 별개이지만, **Dart 언어가 이미 `@Deprecated` 부착 시 IDE quick-fix 를 표준으로 제공**한다는 점은 중요하다 — CoUI 가 codemod 인프라를 처음부터 만들 필요 없이, 이름 변경(부류 A)에 한해 **`@Deprecated('Use Y instead.')` 를 컴파일러가 읽을 수 있는 형태로 정확히 채우기만 해도** `dart fix` 가 상당 부분을 대신할 잠재력이 있다(단, Dart 의 자동 quick-fix 는 `@Deprecated` 만으로 rename 대상을 추론하지 않는다 — `// ignore: deprecated_member_use_from_same_package` 류 억제만 자동화되고, 실제 rename 자동 치환은 별도 규약이 필요하다는 점은 아래 §4 에서 다룬다).
- **`packages/coui_lints`**: `analysis_options.yaml` 에 배선된 CoUI 전용 analyzer plugin — `avoid_hardcoded_chrome_literal`, `avoid_override_prefixed_resolved_field` 등 **패턴 탐지**는 이미 갖췄다. 이 인프라가 "탐지"에서 "자동 수정 제안"으로 확장되면(analyzer plugin 의 `QuickFix` API), 부류 A 급 codemod 의 자연스러운 확장 지점이 된다 — **새 도구를 도입하지 않고 기존 plugin 에 fix 를 추가하는 경로**가 이미 존재한다.
- **`scripts/guards/structure/check_deprecation_policy.sh`**: 이미 "`since <major>.<minor>`" 를 강제하는 ratchet 가드가 있다. codemod 정책을 추가한다면 이 가드가 자연스러운 확장 지점이다 — 예: "부류 A(rename)로 표시된 `@Deprecated` 는 `replacement:` 구조화 필드도 요구" 같은 확장.

## 4. 결합 가능하다면 무엇부터 — 권고 (구현 아님, 방향 판정)

이 문서는 결정 산출물이므로 다음은 **채택 여부를 논의할 후보**이지 착수 계획이 아니다.

1. **부류 A(순수 rename)에 한해 구조화된 `@Deprecated` 메시지 규약 도입 검토**: 현재 `@Deprecated('설명 문장 (since 0.128)')` 은 자유 텍스트다. rename 류만이라도 사람 + 기계가 동시에 읽을 수 있는 최소 구조(예: 메시지 안에 `replacement: NewClassName` 같은 파싱 가능한 토큰을 문장 안에 자연스럽게 포함시키는 것 — 새 필드 문법을 Dart 애노테이션에 추가할 수는 없으므로 메시지 문자열 규약으로)를 얹으면, 그 메시지에서 **rename 표만 기계적으로 뽑아 `dart fix`/사용자 스크립트에 제공**하는 것이 가능해진다. 이것이 `astryx upgrade` 가 하는 일 중 CoUI 가 안전하게 흉내 낼 수 있는 유일한 부분이다.
2. **부류 B(Style 슬롯 이관)는 codemod "스캐폴드"만**: 완전 자동 변환은 위험하지만, "이 호출부가 이 옛 평면 필드를 쓰고 있다"는 **탐지**(coui_lints 가 이미 하는 것과 같은 부류의 정적 분석)까지는 저비용이다. 탐지 결과를 사람이 검토하며 반자동 치환하는 도구(제안만 하고 적용은 리뷰 필수)는 시도할 가치가 있으나, 이 저장소 전례가 있는 것은 아니다 — 신규 투자.
3. **부류 D/E 는 대상에서 제외를 명문화**: `deprecation.md` 의 "제거 PR 은 옛 코드 → 새 코드 를 실제 코드로 보인다" 요구사항을 그대로 유지하되, "codemod 자동 첨부"라는 표현을 정책에 넣지 않는다 — 대신 "동작이 달라지는 breaking change 는 자동 변환 대상이 아님을 먼저 밝힌다"는 기존 문장을 강화 표시(예: PR 템플릿에 "codemod 없음 — 수동 마이그레이션 필요" 체크박스)하는 정도가 안전한 상한이다.
4. **우선순위**: 이 저장소의 breaking change 이력에서 부류 A 가 차지하는 비중을 먼저 정량화(과거 `@Deprecated` 커밋들을 부류별로 표본 분류)한 뒤, 비중이 유의미하면 1번부터 착수하는 것이 순서다. 이 정량화 자체는 이번 스파이크 범위 밖이다.

## 5. 왜 "전면 자동화 채택"으로 결론 내지 않는가

- **정확성 리스크가 비대칭이다**: codemod 가 틀리면 "런타임에 다른 동작을 조용히 얻는 코드가 컴파일된다" — 이것은 `deprecation.md` 가 명시적으로 "이 문서가 막으려는 최악"이라 부르는 시나리오와 동일하다. codemod 그 자체가 이 실패 모드를 만들 수 있다면, 그 codemod 는 문제를 옮길 뿐 없애지 않는다.
- **CoUI 의 breaking change 는 React props 재배치보다 구조적으로 무겁다**: 이 저장소의 룰(`core/style-contract.md`, `resolver/resolver-pattern.md`)이 보여주듯, 한 필드의 의미는 merge chain 우선순위·default 위치·nested slot 여부에 걸쳐 있다 — 단순 텍스트 치환기가 안전하게 다룰 수 있는 표면이 아니다.
- **CoUI 는 이미 소비자가 적다**(`process/deprecation.md` "소비자에게 릴리스는 태그다" — pub.dev 배포가 아니라 git 태그 참조). 다운로드 통계도 없고 소비 앱 수도 적은 단계에서, codemod 인프라(파싱기·변환 규칙 DSL·테스트 스위트)에 투자하는 비용 대비 편익이 Astryx(다수 외부 소비자를 가진 공개 라이브러리) 상황과 다르다 — 이는 채택 시점의 문제이지 원리적 거부는 아니다.

## 6. 같이 보기

- [deprecation 정책](contributing/upgrading.md#deprecation) — 이 검토가 대상으로 삼은 CoUI 기존 정책.
- `docs/docs-benchmark-2026-08-01.md` §4 — 이 스파이크의 출처가 된 원 벤치마크 항목.
- `.claude/docs/docs-benchmark-followup/zenhub/priority.md` — 이 이슈가 "결정 산출물 — 구현이 아님"으로 분류된 근거.
