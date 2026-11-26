# llms.txt + Dart CLI 컴포넌트 계약 추출 탐색 스파이크

- 일자: 2026-08-02
- 이슈: [#3589](https://github.com/coco-de/coui/issues/3589) (Epic E — 장기 AI · 생태계 인프라, 탐색)
- 산출물 성격: **탐색 스파이크** — "설계가 아니라 스파이크, 구체 스코프 미정"(`.claude/docs/docs-benchmark-followup/zenhub/priority.md`). 이 문서는 실제 코드를 읽고 손으로 추출을 재현해 **저비용인지 여부를 검증**하는 것이 목적이며, 프로덕션 도구를 확정하지 않는다.
- 관련: `docs/docs-benchmark-2026-08-01.md` §4 line 65 · `docs_core/test/registry/docs_api_sync_test.dart`(재사용 대상 정규식 추출 기법의 실제 소스) · `packages/coui_core/bin/export_figma_components.dart`(Dart bin/ CLI 선례)

## 한 줄 결론

**저비용 — 이미 검증된 기법을 재사용하는 문제다.** CoUI 는 이미 `docs_api_sync_test.dart` 에서 "Dart contract 소스를 정규식으로 읽어 이름 집합을 뽑는" 정확히 같은 문제를 풀어 프로덕션 게이트로 쓰고 있다. `package:analyzer` AST 파싱은 필요 없다 — 그 정규식을 재사용해 이름·타입·doc comment 를 뽑고, 그 결과를 `content/components/*.md` 의 Props 표(이미 사람이 큐레이션한 산문)와 병합하면 llms.txt 한 항목이 만들어진다. 위험은 **추출 난이도가 아니라 이중 소스 방지** — 새 도구가 `docs_core` 카탈로그·`docs_api_sync_test.dart` 게이트와 별도로 살면 [#3589 의 자매 실패 사례](#4-반례--coui_mcp-가-이미-이-패턴을-시도했고-드리프트했다)가 반복된다.

## 1. 질문 분해

이슈가 묻는 것은 하나다: "docs_core 의 순수 Dart 레지스트리에서 컴포넌트 계약을 텍스트로 뽑아내는 CLI가 CoUI 구조상 얼마나 저비용인가." 저비용 여부를 결정하는 하위 질문 셋:

1. **파싱 난이도** — Dart contract 소스에서 이름/타입/설명을 뽑는 데 `package:analyzer`(AST, 무거움)가 필요한가, 정규식(가벼움)으로 충분한가?
2. **연결 난이도** — `docs_core` 카탈로그(슬러그 목록)에서 실제 contract 파일 경로로 가는 길이 이미 있는가, 새로 만들어야 하는가?
3. **배치 난이도** — 새 CLI 가 melos 워크스페이스 안에 살 수 있는가, 별도 패키지가 필요한가?

## 2. 파싱 난이도 — 이미 프로덕션에 있는 정규식을 재사용

`docs_core/test/registry/docs_api_sync_test.dart` 는 지금 이 저장소에서, 매 CI 실행마다, contract 소스를 파싱해 실재 필드/getter 이름을 뽑는다:

```dart
// docs_api_sync_test.dart:171-178 — 이미 존재하는, CI 가 매번 돌리는 추출기
for (final match in RegExp(
  r'^\s*final\s+[\w<>,?\s]+?\s+(\w+);',
  multiLine: true,
).allMatches(source)) {
  real.add(match.group(1)!);
}
for (final match in RegExp(r'\bget\s+(\w+)\s*;').allMatches(source)) {
  real.add(match.group(1)!);
}
```

이 함수는 오늘 "문서가 실재하지 않는 파라미터를 광고하는가"를 검증하는 데 쓰이지만(doc → source 방향), llms.txt 추출은 **정확히 반대 방향**(source → doc)이라 같은 정규식을 그대로 재사용할 수 있다 — 새 파서를 만드는 게 아니라 기존 파서의 출력을 다른 곳에 쓰는 문제다.

### 손으로 재현 — 실제 `button_contract.dart` 로 검증

정규식이 실제로 뭘 뽑는지 손으로 추적한다. `packages/coui_core/lib/src/component/contracts/button/button_contract.dart` 의 실제 소스(발췌):

```dart
/// The main content of the button.
W get child;

/// Widget displayed before the main content (e.g. icon).
W? get leading;

/// Visual variant. Identifies the button semantically (primary /
/// secondary / outline / …); the design system maps this to a
/// pre-defined chrome look.
CoreButtonVariant get variant;

/// Per-instance button style covering chrome + dimensional
/// overrides plus nested label / leading / trailing icon styles.
CoreButtonStyle? get buttonStyle;
```

`\bget\s+(\w+)\s*;` 를 이 소스에 돌리면 `child`, `leading`, `variant`, `buttonStyle` 이 그대로 나온다(실제 파일은 ~35개 getter, 이 스파이크는 전량 실행하지 않고 표본으로 검증). **doc comment(`///`)는 이 정규식이 잡지 않는다** — getter 선언 직전 연속된 `///` 라인을 역방향으로 모으는 추가 정규식 한 줄(`^\s*///.*$`, `docs_api_sync_test.dart:47`에 있는 주석 제거용 패턴을 "제거"가 아니라 "수집" 방향으로 뒤집으면 됨)이 필요하지만, 이 역시 이미 파일 안에 존재하는 패턴의 변형이지 신규 기법이 아니다.

**결론**: 이름 추출은 검증됨(기존 정규식 재사용), doc comment 추출은 1줄 변형이 필요하지만 원리적으로 같은 난이도. `package:analyzer` 없이 충분하다 — `docs_api_sync_test.dart` 의 doc-comment(line 47)는 "제거용"으로 이미 doc comment 라인 패턴을 정확히 알고 있다.

## 3. 연결 난이도 — 카탈로그에 명시적 링크가 없다 (가장 큰 갭)

`docs_core/lib/shared/component_catalog.dart` 의 `DocsComponentEntry` 는 4개 필드뿐이다:

```dart
const DocsComponentEntry({
  required this.name,        // 'Button'
  required this.slug,        // 'button'
  required this.description, // 'Clickable button'
  required this.icon,        // '🔘'
});
```

**`slug` → contract 파일 경로로 가는 명시적 필드가 없다.** 지금은 `docs_api_sync_test.dart:29-38`(`widgetFile`) 와 `:164-166`(contract 디렉터리)가 각자 `slug.replaceAll('-', '_')` 관례를 **따로** 재구현해서 경로를 찾는다 — 카탈로그 자신은 이 변환을 모른다. 이는 §1의 "저비용" 판정과 별개인 **구조적 부채**다: CLI 를 새로 만들면 이 관례를 세 번째로 재구현하게 되고, 나중에 명명 관례가 바뀌면(예: `text-field` 처럼 slug↔클래스명이 불일치하는 40개 컴포넌트, `docs_api_sync_test.dart` 의 `kDocsPropsCheckUnparsedBaseline = 40` 이 이미 실측) 세 곳이 각자 어긋난다.

**권고(스파이크 판단, 미착수)**: CLI 를 짓기 전에 `slug → contract 디렉터리` 변환을 `docs_core/lib/shared/` 안 단일 함수로 뽑아 `docs_api_sync_test.dart` 와 새 CLI 가 **같은 함수**를 참조하게 만드는 편이, CLI 자체보다 먼저 갚아야 할 선행 작업이다. 이 저장소의 반복되는 원칙("단일 소스, 여러 사본 금지")과 정확히 같은 이유.

## 4. 반례 — `coui_mcp` 가 이미 이 패턴을 시도했고 드리프트했다

이 저장소에는 **이미 한 번 시도된 선례**가 있다 — `packages/coui_mcp`. 이 패키지는 "83개 컴포넌트 메타데이터"를 `coui://component/{name}/overview|examples|api|accessibility` MCP 리소스로 서빙한다고 README 에 적혀 있지만:

- 현재 카탈로그(`kDocsComponentEntries`)는 **140개** 컴포넌트를 갖고 있다.
- `packages/coui_mcp/data/components/` 는 **98개** 파일을 갖고 있다.
- `grep -rl "component_catalog\|DocsComponentEntry\|kDocsComponentEntries" packages/coui_mcp` 는 **0건** — `coui_mcp` 는 `docs_core` 의 단일 소스 카탈로그를 **전혀 읽지 않는다**. 자체 `data/components/component_metadata.json` 을 손으로 유지한다.
- `packages/coui_mcp` 는 melos `workspace:` 목록(`pubspec.yaml:55-65`)에도 **없다** — 워크스페이스 밖에서 독립적으로 산다.

83 / 98 / 140 세 숫자가 모두 다르다는 사실 자체가, "레지스트리에서 텍스트를 뽑아 AI 소비용으로 서빙"이라는 이 스파이크와 **동일한 목표**를 가진 이전 시도가 게이트 없이 방치되면 무슨 일이 일어나는지 보여주는 실측 증거다. `docs_api_sync_test.dart` 가 `.md` 문서 드리프트를 막는 것과 달리, `coui_mcp` 의 데이터에는 그런 게이트가 없다.

**이 스파이크의 가장 중요한 결론은 파싱 기법이 아니라 이것이다**: 새 llms.txt/CLI 를 만든다면, 반드시 `docs_core` 의 단일 소스(카탈로그 + contract 디렉터리)를 **직접, 매 실행마다** 읽어 생성해야 한다 — `coui_mcp` 처럼 한 번 손으로 만든 스냅샷을 커밋하고 마는 방식은 이 스파이크가 검증하려는 "저비용"의 정반대(영구적 유지보수 부채)로 귀결된다는 것이 이미 이 저장소 안에서 증명됐다.

## 5. 배치 난이도 — melos 워크스페이스 안, 파일시스템 상대 경로

두 가지 선례가 이미 있다:

- **`packages/coui_core/bin/export_figma_components.dart`**(355줄) — 인자 파싱 없는 순수 `void main()`, `import 'package:coui_core/coui_core.dart'` 로 런타임 값(예: `CoreButtonStyle.defaultsByVariant`)을 읽어 JSON 직렬화. `coui_core` 는 Flutter 의존성이 없는 순수 Dart 패키지(`pubspec.yaml:8-9`)라 이 방식이 안전하다.
- **`packages/coui_mcp/bin/coui_mcp.dart`**(135줄) — `package:args` 기반 실제 CLI(`--data-path`, `--docs-path`, `--help` 등) 의 배선 템플릿.

**중요한 함정**: `docs_core` 패키지 자체는 `pubspec.yaml` 에 `flutter: {sdk: flutter}` 의존성이 있다(jaspr_content 때문). `import 'package:docs_core/shared/component_catalog.dart';` 로 카탈로그를 읽는 CLI 를 만들면 Flutter SDK 가 있는 환경(이 melos 워크스페이스 안)에서만 돈다 — 순수 Dart CLI 로 독립 배포는 불가능하다. **`docs_api_sync_test.dart` 자신은 이 함정을 이미 피해가고 있다** — `dart:io` `File` 로 `content/components/$slug.md` 와 `../packages/coui_core/lib/src/component/contracts/...` 를 **패키지 import 가 아니라 파일시스템 상대 경로**로 직접 읽는다(`docs_api_sync_test.dart:26-27`). 새 CLI 도 같은 방식(파일시스템 상대 경로)을 따르면 Flutter 의존성을 피할 수 있다 — `coui_core`(순수 Dart) 의 contract 소스는 import 없이 텍스트로 읽고, `docs_core` 의 카탈로그도 마찬가지로 텍스트/정규식으로 읽거나, 혹은 카탈로그만은 순수 Dart이므로(`catalog_single_source_test.dart:191-208` 가 `component_catalog.dart` 에 `package:flutter`/`package:jaspr` import 가 없음을 이미 강제) 그 한 파일만 예외적으로 package import 해도 안전하다.

## 6. 손으로 재현한 예상 출력 (button 1건)

정규식 추출(§2) + 기존 `button.md` Props 표(사람이 이미 큐레이션한 것, `docs_core/content/components/button.md:179-186`)를 병합하면 나오는 llms.txt 스타일 항목의 **모양**을 손으로 재구성한다(실행 도구가 아니라 손 계산 — §3의 갭 때문에 슬러그→경로 연결이 아직 단일 소스가 아니므로, 자동 생성기를 지금 만들면 안 된다는 판단과 일관됨):

```text
## Button

Clickable button.

### Props (content · semantic)
- child: Widget (Flutter) / Component (Web), required — 버튼 본문 (label)
- variant: CoreButtonVariant = primary — 시맨틱 변형 (primary · secondary · outline · ghost · ...)
- size: CoreComponentSize = md — 크기 토큰
- leading: Widget? / Component? = null — 텍스트 앞 아이콘/위젯
- buttonStyle: CoreButtonStyle? = null — chrome / dimensional / nested slot 묶음

Doc: /components/button
```

이 출력의 "Props" 절은 **contract 소스에서 정규식으로 뽑은 이름**(§2)과 **`button.md` Props 표에서 뽑은 타입/기본값/설명**(사람이 이미 작성한 것, 재정규식화 가능 — markdown 표 파싱은 `docs_api_sync_test.dart:114-129` `documentedProps()` 가 이미 한다)을 병합한 것이다. 즉 §4의 결론과 합쳐, **이 CLI 가 해야 할 일은 "새로 파싱"이 아니라 "이미 두 곳에 따로 있는 검증된 파서 둘을 한 출력 포맷으로 합치는 것"** — 이것이 "저비용"이라는 결론의 실질적 근거다.

## 7. 스코프 권고 (미착수 — 방향만)

1. **먼저**: §3의 `slug → contract 디렉터리` 단일 함수화. CLI 착수 전 선행 작업.
2. **다음**: 정규식 추출(§2, 재사용) + markdown Props 표 파싱(재사용, `documentedProps()` 기존 로직) 을 병합하는 얇은 스크립트. `packages/coui_core/bin/` 패턴을 따르되, `docs_core` 콘텐츠는 파일시스템 상대 경로로 읽어 Flutter 의존성을 피한다(§5).
3. **게이팅**: `coui_mcp` 반례(§4)를 되풀이하지 않으려면, 이 CLI 의 출력을 커밋된 정적 파일로 두지 않고 **빌드 시점 생성물**로 두거나, `docs_api_sync_test.dart` 와 같은 방식으로 "생성물이 최신 소스와 일치하는가"를 검증하는 게이트를 같이 만든다. 이 게이트 설계 자체는 이번 스파이크 범위 밖.
4. **명시적으로 미룸**: MCP 서버(`coui_mcp`) 개편, llms.txt 의 실제 파일 위치/서빙 방식(정적 호스팅 vs 빌드 산출물), 40개 slug-불일치 컴포넌트(§2 각주)의 개별 처리 — 전부 "구체 스코프 미정"에 해당하며 별도 이슈로 쪼개야 할 크기.

## 8. 같이 보기

- `docs_core/test/registry/docs_api_sync_test.dart` — 재사용 대상 추출 정규식의 실제 소스.
- `packages/coui_core/bin/export_figma_components.dart` — Dart bin/ CLI 배치 선례.
- `packages/coui_mcp/` — 이 패턴의 미게이트 선례(§4의 반례).
- `docs/docs-benchmark-2026-08-01.md` — 이 스파이크의 출처가 된 벤치마크.
