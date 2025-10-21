# CoUI MCP - Model Context Protocol Server

Dart 기반 MCP(Model Context Protocol) 서버로, CoUI Flutter 컴포넌트 문서를 AI 모델에게 제공합니다.

## 📚 제공 기능

### Resources (문서 제공)

AI 모델이 다음 문서에 접근할 수 있습니다:

| URI | 설명 | 크기 |
|-----|------|------|
| `coui://docs/llm-guide` | 메인 LLM 가이드 - 모든 컴포넌트 상세 설명 | 1,372줄 |
| `coui://docs/quick-reference` | 빠른 참조 치트시트 | 381줄 |
| `coui://docs/common-patterns` | 8가지 일반적인 화면 패턴 | 960줄 |
| `coui://docs/component-metadata` | 83개 컴포넌트 JSON 메타데이터 | 582줄 |
| `coui://docs/index` | 문서 인덱스 및 가이드 | 215줄 |

### Tools (도구)

AI 모델이 사용할 수 있는 도구:

#### 1. `search_components`
컴포넌트를 이름, 설명, 카테고리로 검색합니다.

```json
{
  "name": "search_components",
  "arguments": {
    "query": "button",
    "category": "control"  // optional
  }
}
```

#### 2. `get_component_details`
특정 컴포넌트의 상세 정보를 가져옵니다.

```json
{
  "name": "get_component_details",
  "arguments": {
    "component_name": "button"
  }
}
```

#### 3. `list_all_components`
모든 컴포넌트 목록을 가져옵니다.

```json
{
  "name": "list_all_components",
  "arguments": {
    "sort_by": "name"  // or "examples"
  }
}
```

## 🚀 설치 및 실행

### 1. 의존성 설치

```bash
cd packages/coui_mcp
dart pub get
```

### 2. 직접 실행

```bash
# 기본 경로 (../../docs)
dart run bin/coui_mcp.dart

# 커스텀 docs 경로
dart run bin/coui_mcp.dart --docs-path /path/to/docs
```

### 3. 빌드 (선택)

```bash
dart compile exe bin/coui_mcp.dart -o coui_mcp
./coui_mcp
```

## 🔧 Cursor 설정

### .cursor/mcp.json

다른 프로젝트에서 CoUI 문서를 사용하려면:

```json
{
  "mcpServers": {
    "coui-flutter": {
      "command": "dart",
      "args": [
        "run",
        "/Users/dongwoo/Development/cocode/uiux/coui/packages/coui_mcp/bin/coui_mcp.dart",
        "--docs-path",
        "/Users/dongwoo/Development/cocode/uiux/coui/docs"
      ]
    }
  }
}
```

또는 컴파일된 실행 파일 사용:

```json
{
  "mcpServers": {
    "coui-flutter": {
      "command": "/Users/dongwoo/Development/cocode/uiux/coui/packages/coui_mcp/coui_mcp",
      "args": [
        "--docs-path",
        "/Users/dongwoo/Development/cocode/uiux/coui/docs"
      ]
    }
  }
}
```

### VS Code 설정

`.vscode/settings.json`:

```json
{
  "mcpServers": {
    "coui-flutter": {
      "command": "dart",
      "args": [
        "run",
        "${workspaceFolder}/../coui/packages/coui_mcp/bin/coui_mcp.dart"
      ]
    }
  }
}
```

## 📖 사용 예시

AI 모델이 자동으로 다음과 같이 사용합니다:

### 문서 읽기

```
AI: coui://docs/llm-guide 문서를 읽어서 Button 컴포넌트 사용법을 알려줘
```

→ MCP 서버가 `coui_flutter_llm_guide.md` 전체 내용 제공

### 컴포넌트 검색

```
AI: 입력 필드 컴포넌트를 검색해줘
```

→ `search_components` 도구로 "input", "textfield" 등 검색

### 상세 정보 조회

```
AI: Avatar 컴포넌트의 상세 정보를 알려줘
```

→ `get_component_details` 도구로 avatar 정보 조회

## 🎯 이점

### 1. 자동 컨텍스트 제공
다른 프로젝트에서 CoUI를 사용할 때 AI가 자동으로 올바른 컴포넌트 사용법을 알게 됩니다.

### 2. 일관성
모든 프로젝트에서 동일한 문서를 참조하므로 일관된 코드 생성.

### 3. 최신 정보
문서가 업데이트되면 모든 프로젝트에 자동 반영.

### 4. 검색 가능
특정 컴포넌트를 빠르게 찾고 사용법 확인 가능.

## 🔍 디버깅

### 로그 확인

서버는 stderr로 로그를 출력합니다:

```bash
dart run bin/coui_mcp.dart 2>server.log
```

### 수동 테스트

JSON-RPC 메시지를 stdin으로 보내서 테스트:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | dart run bin/coui_mcp.dart
```

## 📊 지원 현황

| 기능 | 상태 | 설명 |
|------|------|------|
| Resources | ✅ | 5개 문서 리소스 |
| Tools | ✅ | 3개 검색/조회 도구 |
| Prompts | ❌ | 미지원 (향후 추가 가능) |
| STDIO | ✅ | STDIO 통신 |
| Progress | ✅ | dart_mcp 기본 지원 |
| Logging | ✅ | stderr로 로깅 |

## 🛠️ 개발

### 프로젝트 구조

```
packages/coui_mcp/
├── bin/
│   └── coui_mcp.dart           # 메인 실행 파일
├── lib/
│   └── coui_mcp.dart            # 서버 구현
├── pubspec.yaml
└── README.md
```

### 테스트

```bash
# 서버 시작
dart run bin/coui_mcp.dart

# 다른 터미널에서 JSON-RPC 요청 전송
echo '{"jsonrpc":"2.0","id":1,"method":"resources/list"}' | dart run bin/coui_mcp.dart
```

## 📝 문서

- [MCP 사양](https://modelcontextprotocol.io)
- [dart_mcp 패키지](https://pub.dev/packages/dart_mcp)
- [CoUI Flutter 문서](../../docs/README.md)

## 🤝 기여

문서 업데이트나 새로운 기능 추가는 언제든 환영합니다!

## 📄 라이선스

CoUI 프로젝트와 동일한 라이선스를 따릅니다.
