---
title: AI · MCP
description: CoUI 컴포넌트를 검색하고, 필요한 부분만 읽고, 코드를 만들고, 검증하는 MCP 서버(coui-mcp)입니다. stdio 위의 JSON-RPC로 통신하며, API의 기준은 이 사이트의 컴포넌트 페이지입니다.
design: true
---

# AI · MCP

<a id="실행-run"></a>
<a id="직접-확인하기"></a>

## 실행

레포 루트에서 dart pub get을 한 번 실행하면 준비됩니다. 서버는 에이전트가 자식 프로세스로 띄우는 용도라 표준 입력을 기다립니다.

```bash
dart pub get
dart run packages/coui_mcp/bin/coui_mcp.dart
```

<a id="옵션"></a>

| 옵션 | 환경변수 | 설명 |
|---|---|---|
| `--data-path` | `COUI_DATA_PATH` | 번들 데이터 대신 쓸 데이터 디렉터리 |
| `--docs-path`, `-d` | `COUI_DOCS_PATH` | 문서 디렉터리 (레거시) |
| `--[no-]use-builtin` | `COUI_USE_BUILTIN` | 끄면 `--data-path` 없이 번들 데이터도 없을 때 시작하지 않습니다. 쓰는 데이터는 바꾸지 않습니다. 기본 켜짐 |
| `--version`, `-v` | | 버전 출력 |
| `--help`, `-h` | | 도움말 출력 |

<DesignNote>
우선순위는 CLI 옵션, 환경변수, 번들 데이터 순입니다. 시작 로그는 표준 에러로 나가 JSON-RPC 출력과 섞이지 않습니다.
</DesignNote>

`--data-path`에는 번들 데이터(`packages/coui_mcp/data`)와 같은 구조의 디렉터리를 주고, `--docs-path`는 Markdown 통문서 셋(llm-guide · quick-reference · common-patterns)을 읽는 곳을 바꿉니다. 없는 디렉터리를 주면 설정 오류를 표준 에러에 적고 시작하지 않습니다.

<a id="등록-register"></a>
<a id="claude-code"></a>

## 등록

Claude Code는 레포의 .mcp.json에 coui라는 이름으로 이미 등록되어 있습니다. Cursor와 Claude Desktop도 같은 mcpServers 형식을 씁니다.

<Code language="json" title=".mcp.json">
{
  "mcpServers": {
    "coui": {
      "command": "dart",
      "args": ["run", "packages/coui_mcp/bin/coui_mcp.dart"]
    }
  }
}
</Code>

<Code language="bash" title="레포 밖에서 등록">
claude mcp add coui -- dart run /path/to/coui/packages/coui_mcp/bin/coui_mcp.dart
</Code>

<a id="다른-클라이언트"></a>

args의 상대 경로는 서버를 띄우는 작업 디렉터리 기준이라, 레포를 작업 디렉터리로 두지 않는 클라이언트(Claude Desktop 등)에는 CoUI 체크아웃의 절대 경로를 적습니다.

<a id="툴-tools"></a>

## 툴

11개입니다. target 인자는 "flutter"(기본, coui_flutter) 또는 "jaspr"(coui_web)를 받습니다. "web" · "coui_web"도 Web으로 읽지만 그 밖의 값은 오류 없이 Flutter가 되므로, 응답의 target에서 실제로 쓴 플랫폼을 확인합니다.

<a id="문서"></a>
<a id="코드-생성"></a>
<a id="검증"></a>

| 그룹 | 툴 | 필수 인자 | 하는 일 |
|---|---|---|---|
| 문서 | `search_components` | query | 이름과 설명으로 컴포넌트 검색 (앞의 10개까지) |
| | `get_component_details` | component_name | 컴포넌트 상세 정보 (대소문자만 무시, alert_dialog처럼 이름 그대로) |
| 생성 | `generate_component` | component_name | 컴포넌트 하나의 코드 |
| | `generate_screen` | screen_type | 화면 골격 |
| | `generate_form` | form_name · fields | 검증이 붙은 폼 |
| | `generate_pattern` | pattern_name | 자주 쓰는 화면 패턴 |
| | `list_patterns` | — | generate_pattern이 받는 패턴 목록 |
| | `customize_style` | component_name · style_options | 스타일 오버라이드 코드 |
| 검증 | `validate_component` | component_name | 속성 사용 검증 (오류, 경고, 제안) |
| | `analyze_accessibility` | component_name | 접근성 점수와 권장 사항 |
| | `suggest_improvements` | code | Flutter 코드 개선 제안 |

<DesignNote>
패턴은 login, profile, dashboard, list-detail, settings, form, crud, master-detail입니다. 목록에 없는 이름은 오류 없이 기본 골격(CustomScreen)으로 나옵니다. jaspr 타깃에서는 login, form, dashboard만 Web 코드로 나오고, 나머지는 Flutter 코드로 나오며 응답의 note에 그렇게 적힙니다.
</DesignNote>

<a id="리소스-resources"></a>

## 리소스

툴이 작업을 요청하는 창구라면, 리소스는 에이전트가 필요한 URI만 골라 읽는 자료입니다. 통문서는 크기가 커서 템플릿 리소스로 필요한 만큼만 읽습니다.

<a id="컴포넌트-토큰-카테고리-템플릿"></a>
<a id="통문서-고정-uri"></a>
<a id="필요한-만큼만-읽기"></a>

| URI | 내용 |
|---|---|
| `coui://component/{name}/overview` | 이름, 한 줄 설명, 카테고리, 예제 수 |
| `coui://component/{name}/examples` | 사용 예제 |
| `coui://component/{name}/api` | 속성, variant, 크기 |
| `coui://component/{name}/accessibility` | WCAG 수준과 접근성 지침 |
| `coui://tokens/{type}` | colors, spacing, typography, sizes |
| `coui://category/{category}` | 카테고리별 컴포넌트 |
| `coui://docs/llm-guide` | 전체 레퍼런스 (약 26,000자) |
| `coui://docs/quick-reference` | 빠른 참조 (약 7,800자) |
| `coui://docs/common-patterns` | 자주 쓰는 화면 패턴 (약 25,000자) |
| `coui://docs/component-metadata` | 컴포넌트 메타데이터 (약 46,000자) |

{name}에는 메타데이터의 이름을 대소문자까지 그대로 넣습니다(button, alert_dialog — 툴과 달리 Button으로는 못 찾습니다). {category}는 actions, inputs, data-display, navigation, feedback, layout, other, all을 받습니다. 없는 값은 오류로 돌아옵니다.

<a id="현재-한계-known-limitations"></a>

## 현재 한계

결과를 그대로 믿지 말고, 아래 문제가 고쳐지기 전까지 주의합니다.

<DesignNote title="생성된 코드는 반드시 dart analyze로 확인합니다" variant="warning">
PrimaryButton(...), Button.primary(...)처럼 CoUI에 없는 API가 나올 수 있습니다. 실제 형태는 Button(variant: CoreButtonVariant.primary, …)입니다.
</DesignNote>

1. suggest_improvements가 Button을 PrimaryButton으로 바꾸라고 제안하지만 현재 규약과 반대이므로 따르지 않습니다. 이 툴은 코드를 분석하지 않고 글자만 찾아서, CoreButtonVariant를 쓴 올바른 코드에도 이 제안을 붙입니다.
2. coui://tokens/spacing의 xs, sm, md는 실제 토큰(CoreSpace.space4 등)이 아닙니다. colors의 destructive나 typography의 4xl 같은 이름도 CoUI에 없습니다. 토큰은 [디자인 토큰](/tokens/overview) 페이지를 기준으로 합니다.
3. api와 examples 리소스는 지금 모든 컴포넌트에서 내용 없이 돌아옵니다 — api는 속성 · variant · 크기가 빈 채로, examples는 컴포넌트마다 같은 안내 문구로. accessibility도 모든 컴포넌트에 같은 기본값(WCAG AA)을 돌려줍니다.
4. 메타데이터에는 83개 컴포넌트만 있어 일부 컴포넌트는 MCP에 없습니다. 반대로 multiselect처럼 CoUI에 없는 이름도 있습니다.
5. 번들 데이터는 킷의 코드에서 만들어지지 않은 고정된 사본이라, 킷이 바뀌어도 따라오지 않습니다.
6. generate_component가 따로 아는 컴포넌트는 button, input, card, avatar, badge, dialog뿐입니다. 다른 이름은 받은 이름을 그대로 부르는 코드(alert_dialog(…))로 나옵니다.
7. 생성된 Flutter 코드는 package:flutter/material.dart를 함께 import해 Card처럼 Material과 이름이 같은 위젯에서 분석 오류가 납니다. Web 코드의 글자는 Text(...) 체인이 아니라 jaspr의 text(...)로 나옵니다.
8. validate_component는 button, input, card, dialog를, analyze_accessibility는 button, input, image, dialog를 따로 검사하고 나머지는 거의 보지 않습니다. 문제가 없다는 결과가 검사했다는 뜻은 아니고, 버튼 크기 xl2는 오류로 나옵니다.
9. coui://category/{category}는 메타데이터의 카테고리를 읽지 않아 절반 넘게 overview의 카테고리와 다르고, 상당수가 other로 갑니다.
