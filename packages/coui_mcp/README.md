# CoUI MCP - Enhanced Model Context Protocol Server

Dart 기반 MCP(Model Context Protocol) 서버로, CoUI Flutter 컴포넌트 문서와 코드 생성 기능을 AI 모델에게 제공합니다.

## 🎯 NEW: Blueprint-Inspired Architecture

**70-85% 토큰 감소** 달성! Context-on-demand 아키텍처로 전환:

- **Before**: `coui://docs/llm-guide` → 1,372 라인 (모든 것)
- **After**: `coui://component/button/overview` → ~50 라인 (필요한 것만)

### 새로운 리소스 타입

#### 🔍 Granular Component Resources
- `coui://component/{name}/overview` - 컴포넌트 개요 (~50 lines, 96% 감소)
- `coui://component/{name}/examples` - 사용 예제만
- `coui://component/{name}/api` - API 레퍼런스
- `coui://component/{name}/accessibility` - 접근성 가이드

#### 🎨 Design Token Resources
- `coui://tokens/colors` - 색상 시스템
- `coui://tokens/spacing` - 간격 스케일
- `coui://tokens/typography` - 타이포그래피
- `coui://tokens/sizes` - 컴포넌트 크기

#### 📂 Category Resources
- `coui://category/actions` - 액션 컴포넌트 (버튼, 모달 등)
- `coui://category/inputs` - 입력 컴포넌트 (폼, 체크박스 등)
- `coui://category/data-display` - 데이터 표시 (카드, 테이블 등)
- `coui://category/navigation` - 내비게이션 (네비바, 탭 등)
- `coui://category/feedback` - 피드백 (알림, 진행바 등)

📖 **상세 문서**: [BLUEPRINT_IMPLEMENTATION.md](./BLUEPRINT_IMPLEMENTATION.md)

## 🚀 주요 기능

### 📚 Documentation (문서)
- CoUI Flutter 컴포넌트 전체 문서 접근
- 컴포넌트 검색 및 상세 정보 조회
- 83개 컴포넌트 메타데이터

### 🏗️ Code Generation (코드 생성)
- 개별 컴포넌트 코드 생성
- 완전한 화면(Screen) 생성
- 폼(Form) 자동 생성
- 패턴 기반 화면 생성 (Login, Profile, Dashboard 등)

### 🎨 Styling (스타일링)
- 컴포넌트 스타일 커스터마이징
- 테마 통합

### ✅ Validation (검증)
- 컴포넌트 사용법 검증
- 접근성(Accessibility) 분석
- 코드 개선 제안

## 📖 Tools (도구) 목록

### Documentation Tools

#### 1. `search_components`
컴포넌트를 이름이나 설명으로 검색합니다.

```json
{
  "name": "search_components",
  "arguments": {
    "query": "button"
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

### Code Generation Tools

#### 3. `generate_component`
CoUI 컴포넌트의 Flutter 코드를 생성합니다.

```json
{
  "name": "generate_component",
  "arguments": {
    "component_name": "button",
    "variant": "primary",
    "properties": {
      "text": "Click Me",
      "size": "lg",
      "icon": "add"
    }
  }
}
```

**지원 컴포넌트:**
- Button (variants: primary, secondary, ghost, link, destructive)
- Input, Card, Avatar, Badge, Dialog 등

#### 4. `generate_screen`
여러 컴포넌트로 구성된 완전한 화면을 생성합니다.

```json
{
  "name": "generate_screen",
  "arguments": {
    "screen_type": "list",
    "title": "Users",
    "components": []
  }
}
```

**화면 타입:**
- `list`: 목록 화면
- `form`: 폼 화면
- `detail`: 상세 화면

#### 5. `generate_form`
검증 기능이 포함된 폼을 생성합니다.

```json
{
  "name": "generate_form",
  "arguments": {
    "form_name": "user_registration",
    "fields": [
      {"name": "email", "type": "email", "required": true},
      {"name": "password", "type": "password", "required": true},
      {"name": "name", "type": "text", "required": true}
    ]
  }
}
```

#### 6. `generate_pattern`
일반적인 화면 패턴을 빠르게 생성합니다.

```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "login",
    "customization": {
      "title": "Welcome Back",
      "social_login": true
    }
  }
}
```

**사용 가능한 패턴:**
- `login`: 로그인 화면 (이메일/비밀번호, 소셜 로그인 옵션)
- `profile`: 프로필 화면 (편집 가능한 필드, 설정)
- `dashboard`: 대시보드 (통계, 차트, 활동 피드)
- `list-detail`: 마스터-디테일 레이아웃
- `settings`: 설정 화면 (섹션, 스위치)
- `form`: 일반 폼 화면
- `crud`: Create/Read/Update/Delete 인터페이스
- `master-detail`: 반응형 마스터-디테일 레이아웃

#### 7. `list_patterns`
사용 가능한 모든 화면 패턴을 나열합니다.

```json
{
  "name": "list_patterns",
  "arguments": {}
}
```

### Styling Tools

#### 8. `customize_style`
컴포넌트의 커스텀 스타일 코드를 생성합니다.

```json
{
  "name": "customize_style",
  "arguments": {
    "component_name": "button",
    "style_options": {
      "size": "large",
      "shape": "circle",
      "density": "comfortable"
    }
  }
}
```

### Validation Tools

#### 9. `validate_component`
컴포넌트 사용법과 속성을 검증합니다.

```json
{
  "name": "validate_component",
  "arguments": {
    "component_name": "button",
    "properties": {
      "text": "Button",
      "onPressed": true
    }
  }
}
```

**반환 정보:**
- `errors`: 치명적인 오류
- `warnings`: 경고
- `suggestions`: 개선 제안

#### 10. `analyze_accessibility`
컴포넌트의 접근성을 분석하고 권장사항을 제공합니다.

```json
{
  "name": "analyze_accessibility",
  "arguments": {
    "component_name": "button",
    "properties": {
      "icon": "add"
    }
  }
}
```

**반환 정보:**
- `score`: 접근성 점수 (0-100)
- `level`: 접근성 레벨 (Excellent, Good, Fair, Poor, Critical)
- `issues`: 발견된 문제점
- `recommendations`: 개선 권장사항

#### 11. `suggest_improvements`
Flutter 코드를 분석하여 개선사항을 제안합니다.

```json
{
  "name": "suggest_improvements",
  "arguments": {
    "code": "class MyWidget extends StatelessWidget { ... }"
  }
}
```

**체크 항목:**
- Co 접두사 오류 (Button → PrimaryButton)
- 누락된 import 문
- const 생성자 누락
- key 파라미터 누락
- 하드코딩된 문자열
- 에러 핸들링 누락

## 🚀 설치 및 실행

### CoUI 프로젝트 내에서 사용

```bash
cd packages/coui_mcp
dart pub get
dart run bin/coui_mcp.dart
```

### 외부 프로젝트에서 사용 (Git 의존성)

petmedi, kobic, good-teacher 등 외부 프로젝트에서 사용하려면:

#### 1. pubspec.yaml에 의존성 추가

```yaml
dependencies:
  coui_mcp:
    git:
      url: https://github.com/coco-de/coui.git
      path: packages/coui_mcp
```

#### 2. 의존성 설치 및 실행

```bash
dart pub get
dart run coui_mcp
```

### CLI 옵션

```bash
coui_mcp [options]

Options:
  --data-path          커스텀 데이터 디렉토리 경로
  --docs-path, -d      문서 디렉토리 경로 (레거시)
  --use-builtin        내장 데이터 사용 (기본값: true)
  --version, -v        버전 정보 표시
  --help, -h           도움말 표시
```

### 환경변수 지원

```bash
# 커스텀 데이터 경로 설정
export COUI_DATA_PATH=/path/to/custom/data
export COUI_DOCS_PATH=/path/to/custom/docs
export COUI_USE_BUILTIN=false

dart run coui_mcp
```

### 설정 우선순위

1. CLI 옵션 (최우선)
2. 환경변수
3. 내장 데이터 (기본값)

### 빌드 (선택)

```bash
dart compile exe bin/coui_mcp.dart -o coui_mcp
./coui_mcp
```

## 🔧 설정

### Claude Code 설정 (권장)

`.claude/settings.json`:

```json
{
  "mcpServers": {
    "coui": {
      "command": "dart",
      "args": ["run", "coui_mcp"],
      "cwd": "/path/to/your/project"
    }
  }
}
```

### Claude Desktop 설정

`~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "coui-flutter": {
      "command": "dart",
      "args": [
        "run",
        "/Users/YOUR_USERNAME/Development/cocode/uiux/coui/packages/coui_mcp/bin/coui_mcp.dart"
      ]
    }
  }
}
```

### Cursor 설정

`.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "coui-flutter": {
      "command": "dart",
      "args": ["run", "coui_mcp"]
    }
  }
}
```

### 외부 프로젝트 전체 설정 예시

```json
{
  "mcpServers": {
    "coui": {
      "command": "dart",
      "args": ["run", "coui_mcp"],
      "env": {
        "COUI_USE_BUILTIN": "true"
      }
    }
  }
}
```

## 📖 사용 예시

### 예시 1: 로그인 화면 생성

```
AI: generate_pattern 도구를 사용하여 로그인 화면 생성
→ 완전한 로그인 화면 코드 반환 (이메일/비밀번호 입력, 소셜 로그인 옵션)
```

### 예시 2: 사용자 프로필 폼 생성

```
AI: generate_form 도구로 사용자 프로필 폼 생성
→ 검증 기능이 포함된 폼 코드 반환
```

### 예시 3: 컴포넌트 검색 및 사용

```
AI: search_components로 "input" 검색
→ 관련 컴포넌트 목록 반환

AI: get_component_details로 "input" 상세 정보 조회
→ Input 컴포넌트 사용법 및 예제 반환

AI: generate_component로 Input 코드 생성
→ 즉시 사용 가능한 Flutter 코드 반환
```

### 예시 4: 코드 개선

```
AI: suggest_improvements로 기존 코드 분석
→ 개선사항 목록 반환 (네이밍 오류, 누락된 import 등)
```

### 예시 5: 접근성 검증

```
AI: analyze_accessibility로 버튼 접근성 분석
→ 접근성 점수 및 개선 권장사항 반환
```

## 🎯 주요 이점

### 1. 빠른 개발
- 패턴 기반 화면 생성으로 개발 시간 단축
- 반복적인 코드 작성 불필요

### 2. 일관성
- 모든 프로젝트에서 동일한 CoUI 컴포넌트 사용 패턴
- 일관된 코드 스타일 및 네이밍

### 3. 품질 보증
- 자동 검증 및 접근성 체크
- Best practice 기반 코드 생성

### 4. 학습 곡선 감소
- AI가 올바른 컴포넌트 사용법을 자동으로 적용
- 문서 참조 필요성 감소

### 5. 최신 정보
- 문서가 업데이트되면 모든 프로젝트에 자동 반영
- 항상 최신 API 사용

## 🏗️ 아키텍처

```
packages/coui_mcp/
├── bin/
│   └── coui_mcp.dart                     # CLI 엔트리포인트
├── lib/
│   └── src/
│       ├── config/
│       │   └── coui_mcp_config.dart      # 설정 클래스
│       ├── server/
│       │   └── coui_mcp_server.dart      # MCP 서버 (mcp_dart SDK)
│       ├── resources/
│       │   ├── component_resources.dart  # 컴포넌트 리소스
│       │   ├── token_resources.dart      # 토큰 리소스
│       │   └── category_resources.dart   # 카테고리 리소스
│       ├── tools/
│       │   ├── component_generator.dart  # 컴포넌트/화면 생성
│       │   ├── component_validator.dart  # 검증 및 분석
│       │   └── pattern_generator.dart    # 패턴 기반 생성
│       └── models/
│           ├── component_spec.dart       # 컴포넌트 스펙
│           └── design_token.dart         # 디자인 토큰
├── data/                                 # 번들된 데이터 (자동 생성)
│   ├── components/
│   │   ├── component_metadata.json       # 83개 컴포넌트 메타데이터
│   │   └── examples/                     # 컴포넌트별 예제 코드
│   ├── docs/
│   │   ├── llm_guide.md                  # LLM 가이드
│   │   ├── quick_reference.md            # 빠른 참조
│   │   └── common_patterns.md            # 공통 패턴
│   ├── tokens/
│   │   ├── colors.json                   # 색상 토큰
│   │   ├── spacing.json                  # 간격 토큰
│   │   ├── typography.json               # 타이포그래피 토큰
│   │   └── sizes.json                    # 크기 토큰
│   └── icons/
│       ├── bootstrap.json                # Bootstrap 아이콘 (2,050개)
│       ├── lucide.json                   # Lucide 아이콘 (1,557개)
│       ├── radix.json                    # Radix 아이콘 (333개)
│       └── hero.json                     # Hero 아이콘 (324개)
├── tool/
│   └── generate_docs.dart                # 문서 생성 스크립트
└── pubspec.yaml
```

### 데이터 재생성

번들된 데이터를 재생성하려면:

```bash
cd packages/coui_mcp
dart run tool/generate_docs.dart
```

## 🧪 테스트

### MCP 서버 테스트

```bash
# 서버 시작
dart run bin/coui_mcp.dart

# 다른 터미널에서 테스트 요청
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | dart run bin/coui_mcp.dart
```

### 도구 테스트

```bash
# 컴포넌트 검색
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search_components","arguments":{"query":"button"}}}' | dart run bin/coui_mcp.dart

# 패턴 목록
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_patterns","arguments":{}}}' | dart run bin/coui_mcp.dart
```

## 📊 지원 현황

| 기능 | 상태 | 설명 |
|------|------|------|
| Resources | ✅ | 5개 문서 리소스 |
| Documentation Tools | ✅ | 검색, 상세 조회 |
| Code Generation | ✅ | 컴포넌트, 화면, 폼, 패턴 |
| Styling Tools | ✅ | 커스터마이징 |
| Validation Tools | ✅ | 검증, 접근성, 개선 제안 |
| STDIO Communication | ✅ | JSON-RPC over STDIO |
| Error Handling | ✅ | 상세한 에러 메시지 |

## 🤝 기여

문서 업데이트나 새로운 기능 추가는 언제든 환영합니다!

## 📝 관련 문서

- [MCP 사양](https://modelcontextprotocol.io)
- [dart_mcp 패키지](https://pub.dev/packages/dart_mcp)
- [CoUI Flutter 문서](../../docs/README.md)

## 📄 라이선스

CoUI 프로젝트와 동일한 라이선스를 따릅니다.

## 🔄 변경 이력

### v2.1.0 (Latest)
- ✨ 외부 프로젝트 지원 (Git 의존성)
- ✨ 데이터 번들링 시스템 추가
- ✨ 환경변수 설정 지원
- ✨ CouiMcpConfig 설정 클래스
- ✨ 문서 자동 생성 스크립트
- ✨ 4,264개 아이콘 메타데이터 번들
- ✨ 175개 컴포넌트 예제 코드

### v2.0.0
- ✨ mcp_dart SDK로 마이그레이션
- ✨ 11개 도구로 확장 (기존 2개 → 11개)
- ✨ 코드 생성 기능 추가
- ✨ 패턴 기반 화면 생성
- ✨ 검증 및 접근성 분석
- ✨ 코드 개선 제안

### v1.0.0
- 📚 문서 리소스 제공
- 🔍 컴포넌트 검색
- 📖 상세 정보 조회
