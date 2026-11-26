# figma_reader — AST 판독기

`packages/coui_core/lib/src/component/contracts/` 아래 모든 `CoreXxxStyle` /
namespace 소스를 `package:analyzer`의 `parseString`(미해소 AST, element
model 미사용)으로 전수 순회해 `tools/figma-token-sync/src/data/components.json`
을 생성하는 도구. `bin/export_figma_components.dart` 가 진입점.

## 파일

| 파일 | 역할 |
|---|---|
| `ast_value.dart` | 초기화식 → 구조화된 `AstValue`(Literal/Ref/Call/Map/List/Conditional/Raw) 분류. `NamedExpression`/`NamedArgument` 버전 차이를 `namedArg()` 하나로 격리 |
| `style_reader.dart` | 파일 하나의 `class` 선언 → 인스턴스 필드 / static 멤버 수집 |
| `repo_reader.dart` | `contracts/` 트리 재귀 glob + 전역 클래스 레지스트리 |
| `census.dart` | static 멤버를 타입 기반(Map 이면 dispatch, 아니면 scalar)으로 분류 |
| `token_scale.dart` | 숫자 원시토큰 네임스페이스 forward table + alias 추적 |
| `emit.dart` | 타입별 emit 함수(`emitDim`/`emitColor`/`emitInsets`/`emitRadius`/`emitText`/`emitGap`/`emitIcon`) |
| `axis_reader.dart` | v3 `axes` — 4축(variant=`Core{Pascal}Variant` 정확 일치 · size=contract 의 `CoreComponentSize` getter · state=`Core{Pascal}State` 정확 일치 · enabled=contract getter) + 규약 밖 상호배타 enum 의 `other[]` 전수 기록(enhanced enum 멤버가 const 생성자에 넘기는 리터럴은 `fields` 로 함께) |
| `section_reader.dart` | v3 `section` — coui_flutter 카테고리 디렉터리의 섹션 fold(`kSectionFold` 단일 상수, 디렉터리 단위만 — 근-항등 매핑이라 docs_core `kDocsComponentGroups` 와 1:1) + `sourceCategory` |
| `docs_reader.dart` | v3 `docs` — 설명(한국어 content md frontmatter 우선 → 영어 카탈로그 fallback) · docs_site URL · slug 3벌(kebab/snake/Pascal) |
| `example_reader.dart` | v3 `examples` — docs chain example 의 withStyle **식** 추출(원본 포매팅) + 실재 getter 기반 tokenChain. 기본 생성자는 비저장(빌더가 `axes` 에서 파생) |

## 스키마 v3

`meta.schema == 3`. v2 leaf 3종(`fields`/`variants`/`sizes`)은 byte-불변으로
유지되고, 컴포넌트마다 additive 키 4종(`section`/`axes`/`docs`/`examples`)이
그 뒤에 온다 — 키 순서까지 결정적이며 seal 테스트
(`test/export_figma_components_test.dart`)가 고정한다.

## analyzer 버전 갭 (2026-08-04 실측)

```
$ dart pub outdated
analyzer   *12.1.0   *12.1.0   *12.1.0   14.1.0
```

워크스페이스는 **analyzer 12.1.0** 에 고정돼 있다(`analysis_server_plugin`
0.3.14 → `analyzer: 12.1.0` exact-pin 경유, `coui_lints/pubspec.yaml` 참조).
`resolvable`/`latest` 는 **14.1.0** — 워크스페이스가 최신 대비 **2 메이저
뒤**에 있다. `analysis_server_plugin` 이 다음 minor 로 올라가는 날 이 핀이
움직이며, 그 시점에 analyzer 13/14 로 한 번에 점프할 수 있다.

analyzer 12→13 은 AST shape breaking change 다(`NamedExpression` 삭제 →
`NamedArgument`, `ArgumentList.arguments` 의 원소 타입 변경 등). 이 판독기는
그 변경의 유일한 접점을 `ast_value.dart#namedArg`(dynamic 어댑터) 하나로
격리했고, `scripts/guards/structure/check_analyzer_ast_churn.sh` 가 그
격리가 깨지지 않는지(금지 식별자 net-new 0) CI 에서 고정한다.

이 파일을 다시 실행해 갭이 좁혀졌는지 확인하려면:

```bash
dart pub outdated
```
