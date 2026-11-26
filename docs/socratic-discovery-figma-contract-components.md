# Socratic Discovery: figma-contract-components

> 요청 원문에서 드러난 숨은 가정과 그 해소 기록. 각 항목: 표면 요구 → 꼬리 질문 → 드러난 가정 → 해소(출처).
> 해소 출처 표기: **[사용자]** = 게이트에서 직접 확정, **[룰]** = `.claude/rules/` 원칙으로 자동 확정, **[코드]** = 레포 실사로 확정.

## Q1. "섹션별 피그마 페이지 하나당 1 컴포넌트" 는 무슨 구조인가?
- 꼬리: 페이지가 4개(섹션당 1)인가, 컴포넌트 수만큼인가? 섹션은 그럼 무엇으로 표현되나?
- 숨은 가정: "페이지" 가 Figma PageNode 를 뜻하며, 현행 단일 페이지 + 섹션 컬럼 구조를 버린다는 것.
- **해소 [사용자]**: 컴포넌트당 PageNode 1개(101+). 페이지 이름 `{Section} / {Component}`, 섹션 구분 페이지(`─── Display ───` 류)로 정렬. 각 페이지 안: ComponentSet(전 variant) + 프로퍼티 표 + 코드 예시.

## Q2. Display·Control·Form·Layout 4섹션에 나머지 카테고리는 어디로 가나?
- 꼬리: 섹션의 SSOT 는 무엇인가(플러그인 5섹션 / docs 카탈로그 11그룹 / coui_flutter 디렉터리 12개가 전부 다름)? Navigation·Overlay·Menu·Infra 는?
- 숨은 가정: 4섹션이 완전 분할(exhaustive partition)이라는 것 — 실제 코드엔 그 밖의 카테고리가 6개 있다.
- **해소 [사용자]**: 출처 = coui_flutter 카테고리 디렉터리(코드 SSOT), **디렉터리 단위로만** fold(컴포넌트별 재분류 금지 — 4번째 분류체계 생성 방지). 확정 fold 맵:
  - `Control` ← control(6) + navigation(5) + menu(5)
  - `Display` ← display(36) + overlay(9) + text(3) + icon(1)
  - `Form` ← form(31) / `Layout` ← layout(35)
  - infra(14) → Figma 미노출(제외) — docs 미등록 관례와 대칭.

## Q3. "프로퍼티 반영은 필수" 의 범위는? (variant 만? size? 상태? 조합 폭발은?)
- 꼬리: Button 은 variant 12 × size 6 = 72 조합이다. 전부 그리나? boolean(enabled/loading)은? hover 같은 상호작용 상태는?
- 숨은 가정: "프로퍼티" = 컨트랙트 생성자 표면의 축(시맨틱 enum·size·상호배타 state·boolean toggle)이지, 런타임 상호작용 상태(hover/press/focus — DETECTION 은 위젯/브라우저 소유)가 아니라는 것.
- **해소 [룰]**: `cross-platform/api.md` "범위 애매하면 항상 완전 호환(A) — 묻지 않는다" → **전 축 완전 조합**(72 포함). 축 유형별 Figma 표현:
  - variant enum · size · 상호배타 state enum · enabled(시각이 바뀜) → **Figma variant 축** (`Variant=` / `Size=` / `State=`)
  - 레이어 유무 boolean(leading/trailing 슬롯 존재 등) → **BOOLEAN component property**
  - 텍스트 콘텐츠 슬롯(label/placeholder) → **TEXT component property**
  - 상호작용 상태(hover/press/focus)는 생성자 표면이 아니므로 **범위 제외** (`widget/render-only.md` 의 state DETECTION 분리와 동일 논리).

## Q4. 축 데이터의 출처는? (빌더가 어떻게 "컨트랙트를 잘 따르나")
- 꼬리: 현행 components.json(schema v2)에는 variant enum 멤버 목록이 없다(스타일 default 있는 variant 만 등장). 그럼 빌더는 무엇을 보고 축을 만드나?
- 숨은 가정: 스키마가 이미 충분하다는 것 — 실사 결과 부족.
- **해소 [코드]**: **schema v3 확장** 필요 — exporter(AST 리더)가 `{component}_variant.dart` enum 멤버 전수 + size 목록 + 상태 축 + 섹션(fold 맵 적용) + 설명 + docs URL 을 추가 emit. 빌더는 v3 축 데이터에서 조합을 파생(하드코딩 금지 — G7 ratchet 감소 방향과 일치).

## Q5. "docs 에 있는 설명" 은 어느 소스·어느 언어·어디로 가나?
- 꼬리: 카탈로그(영어 한 줄) vs content md frontmatter(한국어)? Figma 의 어느 표면에?
- **해소 [코드+판단]**: 본문 언어와 일치하는 **한국어 md frontmatter description 우선**, 없으면 카탈로그 영어 fallback. 기록 위치 ① `ComponentNode/ComponentSetNode.description`(인스펙터 노출) ② `documentationLinks` = docs_site 컴포넌트 URL ③ 페이지 내 설명 텍스트 프레임. slug 3벌(kebab/snake/Pascal) 대조는 exporter 가 단일 대조표로 emit.

## Q6. "슈거 체인 예시" 는 어떤 형태인가?
- 꼬리: 코드 텍스트 블록인가, 스타일 패치를 실제 적용한 렌더 프레임인가?
- 숨은 가정: "가능하다면" = soft 요구 — 형태 선택권이 구현 쪽에 있음.
- **해소 [판단]**: **코드 텍스트 블록 = 필수**(전 페이지): ① 기본 생성자 ② `withStyle(patch)` ③ 토큰-정확 getter 체인(예: `.radius4.primary`) — composition slot 은 Text 체인 표기(`Text('...').bodyMedium.onSurface`), chrome 은 withStyle 계열로 룰의 역할 분리를 따름. 소스는 docs `*_chain_example.dart` 존재 시 그것, 없으면 exporter 가 컨트랙트에서 파생한 canonical 스니펫. **스타일 패치 적용 렌더 프레임은 이번 범위 제외**(빌더가 default 토큰 바인딩 전제라 임의 patch 렌더는 별도 경로 — 후속 후보).

## Q7. 컨트랙트 143 vs 빌더 101 — 미등재 42종도 새로 그리나?
- 숨은 가정: "컨트랙트를 잘 따라 구현" = 기존 101개의 충실도 문제이지, 커버리지 확장 요구가 아니라는 것.
- **해소 [판단]**: 이번 범위 = **registry 등재 101개**(+ infra 제외 반영). 미등재분은 G2 uncovered ratchet(baseline 44)으로 계속 추적, 커버리지 확장은 별도 후속. 단 G2 가드의 **CI 배선**(현재 미배선 발견)은 이번 범위에 포함 — registry 를 크게 흔드는 작업의 안전망.

## Q8. 기존 파일/노드는 어떻게 되나? (identity)
- 꼬리: 페이지를 쪼개면 기존 문서의 인스턴스 링크가 깨지나?
- **해소 [코드]**: mint-by-name 은 이름 기반 재활용이라 페이지 이동은 id/key 를 보존. 단 ① 노드 조회 스코프를 단일 페이지 → 문서 전체로 일반화 ② 1회성 구조 마이그레이션(기존 페이지의 노드를 새 페이지로 이동)을 renames.ts 계열의 명시 목록으로 처리. 컴포넌트 이름 자체는 불변(렌네임 없음)이라 `SET_RENAMES` 불필요.

## Q9. 선행 파이프라인(Epic D/E)과의 관계는?
- **해소 [판단, breakdown 에서 집행]**: 이번 요청은 Epic D(#3724 판독기·스키마 v2)의 **연장**(schema v3)이자 Epic E(#3725 빌더 SSOT 전환)의 **상위 집합**. breakdown 단계에서 중복 이슈 생성 금지 — 기존 Epic 을 승계/확장하거나 명시적으로 supersede 처리.

## Q10. 성공을 무엇으로 재나?
- **해소 [판단]**: 선행 파이프라인 교훈("가드 green ≠ Figma 픽셀 정합") 승계 — 성공 판정은 **축 반영률 ratchet(G10 신설)**: 분모 = schema v3 가 선언한 축, 분자 = selftest-registry-runtime 이 확인한 빌더 바인딩 축. 대상 101개에서 100% + 기존 가드(G1·G3·G4·G6·G7) green + 멱등(2회차 all-skip) + 5분 예산 유지.
