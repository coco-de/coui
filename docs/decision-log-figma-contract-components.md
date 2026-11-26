# Decision Log: figma-contract-components

> 형식: 결정 / 근거 / 기각된 대안. 출처 표기 [사용자]=게이트 확정 · [룰]=`.claude/rules/` 자동 확정 · [코드]=레포 실사 · [검토]=Contrarian/Simplifier 반영.

| ID | 결정 | 근거 | 기각된 대안 |
|---|---|---|---|
| D-1 [사용자] | 컴포넌트당 Figma 페이지 1개, `{Section} / {Component}` 명명 + 섹션 구분 페이지 | 게이트 질문 A1 에서 프리뷰로 확정 | 섹션당 페이지 4개(컴포넌트는 프레임) |
| D-2 [사용자] | 섹션 출처 = coui_flutter 카테고리 디렉터리 + 고정 fold 맵: Control←control+navigation+menu, Display←display+overlay+text+icon, Form←form, Layout←layout, infra 제외 | 분류 3벌(플러그인5/카탈로그11/디렉터리12)이 서로 어긋남 — 코드 SSOT 하나를 정본으로. 디렉터리 단위 fold 만 허용해 4번째 분류체계 생성 방지 | 오버레이→Control 분류 / 6섹션 유지 / docs 카탈로그 기준 |
| D-3 [룰] | 축 반영은 전 축 완전 조합(Button 72 포함) — 묻지 않고 확정 | `cross-platform/api.md` "범위 애매하면 항상 완전 호환(A), 사용자에게 묻지 않는다" | 조합 상한/대표 조합만 |
| D-4 | 축 유형별 Figma 표현: 시각이 바뀌는 축(variant·size·상호배타 state·enabled)=variant 축, 레이어 유무 boolean=BOOLEAN property, 텍스트 콘텐츠=TEXT property | Figma BOOLEAN property 는 레이어 visibility 용이라 disabled 같은 시각 변화를 표현 못함 — 시각 상태는 variant 축이어야 함 | enabled 를 BOOLEAN property 로 (시각 미반영이라 기각) |
| D-5 | 상호작용 상태(hover/press/focus) variant 는 범위 외 | 컨트랙트 생성자 표면이 아님 — state DETECTION 은 런타임 엔진 소유(`widget/render-only.md`). 축 = 생성자 표면으로 정의 | hover/focus variant 동반 생성(조합 추가 폭발) |
| D-6 | 설명 = 한국어 md frontmatter 우선, 카탈로그 영어 fallback. `description` + `documentationLinks` + 페이지 헤더 3표면 | 사용자 요청 언어·docs 본문 언어와 일치, md frontmatter 가 더 서술적. URL 은 docs_site 정본 | 영어 카탈로그 우선 |
| D-7 | 슈거 체인 예시 = 코드 텍스트 블록 3종(기본/withStyle/토큰 getter) 필수, 스타일 패치 렌더 프레임은 범위 외 | "가능하다면" = soft 요구. 렌더 프레임은 default-토큰 바인딩 전제를 깨는 별도 렌더 경로 필요 — 비용 대비 후속이 적절. 코드 블록 소스는 docs `*_chain_example.dart` 재사용 우선 | 전 컴포넌트 렌더 프레임 동반 |
| D-8 | 섹션 내 컴포넌트 정렬 = 알파벳순 | 결정적·논쟁 없음. 카탈로그 큐레이션 순서는 docs 전용 의미라 Figma 페이지 목록에 이식할 근거 약함 | 카탈로그 큐레이션 순서 |
| D-9 | 대상 = registry 등재 101개(infra 제외 반영). 미등재 42종 커버리지 확장은 후속 | 사용자 문구는 기존 컴포넌트의 컨트랙트 충실도 요구. G2 uncovered ratchet 이 추적 장치로 이미 존재 | 143 전체 신규 빌더 동반(범위 3배) |
| D-10 | G2(registry parity) CI 배선을 이번 범위에 포함 | 실사에서 G2 미배선 발견 — registry 를 크게 흔드는 작업의 안전망이 수동 실행 전용인 채로 진행할 수 없음 | 현상 유지(수동 실행) |
| D-11 | 성공 판정 = G10 축 반영률 ratchet (분모 schema v3 axes, 분자 빌더 바인딩 축) | 선행 파이프라인 교훈: "가드 green ≠ Figma 정합" — 필드 존재가 아니라 축 도달을 재는 가드가 성공 판정이어야 함 (선행 G7 방식 승계) | 수동 검수만 |
| D-12 | Epic D(#3724)/E(#3725) 는 breakdown 에서 승계·supersede 정리(중복 이슈 금지) | `process/workflow.md` 이슈 scope 규칙 + 선행 파이프라인이 이미 같은 방향(FR-006/007)을 선언 | 무관한 새 Epic 병립(중복) |

## 검토 반영 (Contrarian 13건 / Simplifier 5건 — 2026-08-06)

| ID | 출처 | 처분 | 스펙 반영 |
|---|---|---|---|
| D-13 [검토] | CH-007 (**Critical**) | 수용 | `PAGE_MIGRATIONS` 신설(appendChild 이동 — key 보존), static→set 승격은 **입양**(rename 후 combineAsVariants 포함, remove 금지), NFR-F 검증 단위 = ComponentNode key, 스코프 일반화·이동·승격 동일 릴리스 원자성 (FR-2·FR-3·NFR-F) |
| D-14 [검토] | CH-001·CH-002 (Major) | 수용 | State 와 Enabled 를 **별도 축**으로 — 곱집합 보존(disabled×checked 소실 금지). 산수 정정: Button 12×6×2=**144** (§1 "4축") |
| D-15 [검토] | CH-011 (Major) | 수용 | variant 축 = `Core{Component}Variant` 명명 규약으로 기계 판별. mode/orientation 류는 `axes.other[]` 전수 기록 + Properties 표 문서화, Figma 축 승격은 **명시적 Won't**(별도 카운트 추적) (§1·§4-2) |
| D-16 [사용자] | S-004·CH-010 | 게이트 확정 | BOOLEAN/TEXT/INSTANCE_SWAP property 는 후속 분리. "프로퍼티 반영 필수" = 4축 variant + Properties 표 전수 문서화로 충족 (§4-3) |
| D-17 [사용자] | S-002·CH-005 | 게이트 확정 | 섹션 구분 페이지 **폐기** — 이름 접두 + 물리 정렬만. 섹션 순서 주장은 파일 내 페이지 목록 한정(Assets 패널 범위 외) (FR-2) |
| D-18 [검토] | CH-008·S-001 (Major) | 수용 | examples = 추출된 **식 스니펫만**(withStyle·토큰 체인), 기본 생성자는 빌더 파생(저장 안 함), hash 입도 = per-entry v3 서브트리 (FR-1·NFR-A) |
| D-19 [검토] | CH-009·S-003 (Major) | 수용 | G10 = 신규 스크립트가 아니라 selftest-registry-runtime **확장**. 빌드 결과 트리 축 판독기 추가를 명시적 Must 로 (FR-6) |
| D-20 [검토] | CH-004 (Major) | 수용 | 페이지 내 프레임 ②③도 per-entry hash-skip 대상 — 2회차 all-skip 이 시간에도 성립 (FR-2) |
| D-21 [검토] | CH-006·CH-012·CH-013 (Minor) | 수용 | NFR-E 에 loadAsync·프레임 TextNode 계상 / 예시 게이트 최소 2종 / 대상 N=101 실측 명기 + infra fold 시 RETIRED (NFR-E·FR-4·§1) |
| D-22 [검토] | S-005 | 수용 | 4프레임 → **3프레임** — 설명 헤더를 Properties 표 캡션(컨트랙트 경로)으로 병합, 이름·설명은 네이티브 메타데이터로 (FR-2·FR-5) |
| — | CH-003 | 기각 유지 | 조합 규모(144) 자체는 Figma 실무 범위 내 — 축소 없음 (Contrarian 스스로 기각) |
| — | S-001 대안(별도 examples 파일) | 기각 | SSOT 2개화 + G1류 가드 중복 — components.json 인라인 유지 |

## 설계 단계 결정 (Architecture 2026-08-07)

| ID | 결정 | 근거 | 기각된 대안 |
|---|---|---|---|
| D-23 [설계] | seed spec 의 "PAGE_MIGRATIONS 1회성 명시 목록"을 **상시 배치 정규화(T-13)** 로 정제 — 목표 페이지가 v3 에서 완전 파생되므로 목록은 같은 정보의 2번째 출처. 재실행=복구(R-1)·자가 치유 자동 성립, 감사는 이동/key 로그로 | `.bmad/architecture-figma-contract-components-2026-08-07.md` T-13. seed spec 의 의도(identity 보존·감사·복구)는 전부 보존 — 메커니즘만 정제 | 1회성 명시 목록(정보 중복 + 수동 노드 이동 시 재발 미방어) |
| D-24 [설계] | 조합 열거 헬퍼를 빌더와 G10 이 공유(T-14) / `SCHEMA_REV` 전역 재빌드 상수(T-15) / 다축 이름 축 순서 고정(T-16) | 분자·분모 산수 분기 차단 / per-entry 입도의 전역 무효화 수단 / rename·입양·파싱 단일 규약 | — |

## 개발 중 스코프 결정 (2026-08-07)

| ID | 결정 | 근거 | 기각된 대안 |
|---|---|---|---|
| D-25 [사용자] | seed spec §4-3(BOOLEAN/TEXT property 후속 분리)을 **해제** — F1 #4099 로 즉시 진행. 1차는 TEXT(텍스트 렌더 슬롯)+BOOLEAN(유무 슬롯), INSTANCE_SWAP 은 실익 검토 후 | Dialog 류 축 없는 슬롯형 컴포넌트의 Properties 패널이 비어 실사용성 저하 — 사용자 실물 확인 후 게이트 재결정. exporter 는 `W?` slot getter 이름만 기계 emit(발명 없음), TEXT/BOOLEAN 판정은 빌더가 실제 렌더하는 노드 기준 | 현행 유지(표 문서화만) |
| D-26 [사용자] | 섹션 구분 페이지 **재도입**(#4100) — D-17 번복. 정렬 패스에서 섹션 헤더 페이지를 find-or-create 하고 [헤더 → 그 섹션 페이지들] 순 interleave. 해당 섹션 컴포넌트 페이지가 있을 때만 생성 | 실물 파일 확인 후 사용자 재결정 — 100+ 페이지 목록에서 섹션 경계 시인성 필요. S-002 의 가드 예외 우려는 실측상 불성립(컴포넌트 없는 빈 페이지 = 노드 인덱스·mint·G1/G2 무영향) | 접두 명명만 유지(D-17) |
| D-27 [사용자] | 페이지 명명을 레퍼런스 라이브러리 조직으로 — 섹션 헤더 `🖥️ DISPLAY`(이모지+대문자) · 컴포넌트 페이지 `❖ {Name}`(섹션 접두 제거). D-1 의 `{Section} / {Name}` 스킴 대체. 파생은 `componentPageNameOf`/`sectionHeaderPageNameOf` 단일 출처(generate 배치·verify 정합 공용), 구 스킴 페이지는 배치 정규화가 노드를 옮긴 뒤 **비었을 때만** 제거(비어있지 않으면 보고만) | 사용자가 레퍼런스 스크린샷 제시("이렇게 정리되면 좋겠다") — 헤더 페이지가 섹션을 말하므로 100+ 페이지에 섹션 접두 반복은 사이드바 노이즈. 스킴 rename 은 T-13 재실행=복구로 자동 이행(appendChild 이동, id/key 보존) | `{Section} / {Name}` 유지 + divider 만 삽입 |
