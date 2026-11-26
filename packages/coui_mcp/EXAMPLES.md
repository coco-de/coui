# CoUI MCP - 사용 예시

이 문서는 CoUI MCP 서버의 모든 도구에 대한 상세한 사용 예시를 제공합니다.

## 📚 Documentation Tools

### 1. 컴포넌트 검색

**요청:**
```json
{
  "name": "search_components",
  "arguments": {
    "query": "button"
  }
}
```

**응답:**
```json
{
  "query": "button",
  "results_count": 5,
  "results": [
    {
      "name": "button",
      "displayName": "Button",
      "description": "Buttons allow users to take actions and make choices with a single tap.",
      "exampleCount": 15
    }
  ]
}
```

### 2. 컴포넌트 상세 정보

**요청:**
```json
{
  "name": "get_component_details",
  "arguments": {
    "component_name": "avatar"
  }
}
```

**응답:**
```json
{
  "name": "avatar",
  "displayName": "Avatar",
  "description": "Avatars are used to represent people or objects.",
  "exampleCount": 4,
  "category": "display"
}
```

## 🏗️ Code Generation Tools

### 3. 버튼 생성

**기본 Primary 버튼:**
```json
{
  "name": "generate_component",
  "arguments": {
    "component_name": "button",
    "variant": "primary",
    "properties": {
      "text": "Submit",
      "size": "lg"
    }
  }
}
```

**생성된 코드:**
```dart
PrimaryButton(
  size: ButtonSize.large,
  onPressed: () {
    // TODO: Implement button action
  },
  child: Text('Submit'),
)
```

**아이콘이 있는 버튼:**
```json
{
  "name": "generate_component",
  "arguments": {
    "component_name": "button",
    "variant": "secondary",
    "properties": {
      "text": "Add Item",
      "icon": "add",
      "size": "md"
    }
  }
}
```

**생성된 코드:**
```dart
SecondaryButton(
  size: ButtonSize.medium,
  leading: Icon(Icons.add),
  onPressed: () {
    // TODO: Implement button action
  },
  child: Text('Add Item'),
)
```

### 4. 입력 필드 생성

**기본 텍스트 입력:**
```json
{
  "name": "generate_component",
  "arguments": {
    "component_name": "input",
    "properties": {
      "label": "Email",
      "placeholder": "Enter your email",
      "required": true,
      "type": "email"
    }
  }
}
```

**생성된 코드:**
```dart
Input(
  label: 'Email',
  placeholder: 'Enter your email',
  required: true,
  onChanged: (value) {
    // TODO: Handle input change
  },
)
```

### 5. 카드 생성

**콘텐츠와 푸터가 있는 카드:**
```json
{
  "name": "generate_component",
  "arguments": {
    "component_name": "card",
    "properties": {
      "title": "Product Details",
      "description": "This is a great product with amazing features.",
      "footer": true
    }
  }
}
```

**생성된 코드:**
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('This is a great product with amazing features.'),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SecondaryButton(
              onPressed: () {},
              child: Text('Cancel'),
            ),
            SizedBox(width: 8),
            PrimaryButton(
              onPressed: () {},
              child: Text('Confirm'),
            ),
          ],
        ),
      ],
    ),
  ),
)
```

### 6. 완전한 화면 생성

**리스트 화면:**
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

**생성된 코드:**
```dart
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Item $index'),
            subtitle: Text('Description for item $index'),
            onTap: () {
              // TODO: Navigate to detail
            },
          ),
        );
      },
    );
  }
}
```

### 7. 폼 생성

**사용자 등록 폼:**
```json
{
  "name": "generate_form",
  "arguments": {
    "form_name": "user_registration",
    "fields": [
      {
        "name": "full_name",
        "type": "text",
        "required": true
      },
      {
        "name": "email",
        "type": "email",
        "required": true
      },
      {
        "name": "password",
        "type": "password",
        "required": true
      },
      {
        "name": "bio",
        "type": "text",
        "required": false
      }
    ]
  }
}
```

**생성된 코드:**
```dart
class UserRegistrationForm extends StatefulWidget {
  const UserRegistrationForm({super.key});

  @override
  State<UserRegistrationForm> createState() => _UserRegistrationFormState();
}

class _UserRegistrationFormState extends State<UserRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Input(
            label: 'Full Name',
            controller: _fullNameController,
            required: true,
          ),
          SizedBox(height: 16),
          Input(
            label: 'Email',
            controller: _emailController,
            required: true,
          ),
          SizedBox(height: 16),
          Input(
            label: 'Password',
            controller: _passwordController,
            required: true,
          ),
          SizedBox(height: 16),
          Input(
            label: 'Bio',
            controller: _bioController,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(
                onPressed: () {
                  _formKey.currentState?.reset();
                },
                child: Text('Reset'),
              ),
              SizedBox(width: 8),
              PrimaryButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Submit form
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## 🎨 Pattern Generation

### 8. 로그인 화면 패턴

**기본 로그인:**
```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "login",
    "customization": {
      "title": "Welcome Back"
    }
  }
}
```

**소셜 로그인 포함:**
```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "login",
    "customization": {
      "title": "Sign In",
      "social_login": true
    }
  }
}
```

### 9. 프로필 화면 패턴

**편집 가능한 프로필:**
```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "profile",
    "customization": {
      "editable": true
    }
  }
}
```

**읽기 전용 프로필:**
```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "profile",
    "customization": {
      "editable": false
    }
  }
}
```

### 10. 대시보드 패턴

**커스텀 위젯 포함:**
```json
{
  "name": "generate_pattern",
  "arguments": {
    "pattern_name": "dashboard",
    "customization": {
      "widgets": ["stats", "chart", "activity"]
    }
  }
}
```

### 11. 패턴 목록 조회

**요청:**
```json
{
  "name": "list_patterns",
  "arguments": {}
}
```

**응답:**
```json
{
  "patterns": [
    {
      "name": "login",
      "displayName": "Login Screen",
      "description": "Authentication screen with email/password",
      "category": "auth"
    },
    {
      "name": "profile",
      "displayName": "Profile Screen",
      "description": "User profile with editable fields",
      "category": "user"
    },
    {
      "name": "dashboard",
      "displayName": "Dashboard",
      "description": "Dashboard with stats and charts",
      "category": "overview"
    }
  ],
  "count": 8
}
```

## 🎨 Styling Tools

### 12. 버튼 스타일 커스터마이징

**요청:**
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

**응답:**
```json
{
  "component": "button",
  "style_options": {
    "size": "large",
    "shape": "circle",
    "density": "comfortable"
  },
  "code": "ButtonStyle(\n  size: ButtonSize.large,\n  shape: ButtonShape.circle,\n  density: ButtonDensity.comfortable,\n)"
}
```

## ✅ Validation Tools

### 13. 컴포넌트 검증

**올바른 사용:**
```json
{
  "name": "validate_component",
  "arguments": {
    "component_name": "button",
    "properties": {
      "child": "Button Text",
      "onPressed": true,
      "size": "md"
    }
  }
}
```

**응답:**
```json
{
  "valid": true,
  "errors": [],
  "warnings": [],
  "suggestions": []
}
```

**잘못된 사용:**
```json
{
  "name": "validate_component",
  "arguments": {
    "component_name": "button",
    "properties": {
      "size": "invalid_size"
    }
  }
}
```

**응답:**
```json
{
  "valid": false,
  "errors": [
    "Button must have either 'child' or 'text' property",
    "Invalid button size: invalid_size. Valid values: xs, sm, md, lg, xl"
  ],
  "warnings": [
    "Button without onPressed callback will be disabled"
  ],
  "suggestions": []
}
```

### 14. 접근성 분석

**아이콘만 있는 버튼 (문제 있음):**
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

**응답:**
```json
{
  "score": 70,
  "level": "Fair",
  "issues": [
    "Icon-only button missing semanticLabel"
  ],
  "recommendations": [
    "Consider using explicit button style for better color contrast"
  ]
}
```

**개선된 버전:**
```json
{
  "name": "analyze_accessibility",
  "arguments": {
    "component_name": "button",
    "properties": {
      "icon": "add",
      "semanticLabel": "Add new item"
    }
  }
}
```

**응답:**
```json
{
  "score": 95,
  "level": "Excellent",
  "issues": [],
  "recommendations": []
}
```

### 15. 코드 개선 제안

**문제가 있는 코드:**
```json
{
  "name": "suggest_improvements",
  "arguments": {
    "code": "class MyWidget extends StatelessWidget {\n  Widget build(BuildContext context) {\n    return Button(\n      onPressed: () {},\n      child: Text('Button'),\n    );\n  }\n}"
  }
}
```

**응답:**
```json
{
  "improvements": [
    {
      "type": "error",
      "message": "Invalid component name with Co prefix",
      "suggestion": "Remove Co prefix. Use 'PrimaryButton' instead of 'Button'",
      "line": 3
    },
    {
      "type": "warning",
      "message": "Missing import statement",
      "suggestion": "Add: import 'package:coui_flutter/coui_flutter.dart';",
      "line": 1
    },
    {
      "type": "suggestion",
      "message": "Widget without key parameter",
      "suggestion": "Add {super.key} to constructor",
      "line": 1
    }
  ],
  "count": 3,
  "has_errors": true,
  "has_warnings": true
}
```

## 🎯 실제 워크플로우 예시

### 시나리오 1: 새로운 사용자 등록 화면 만들기

```
1. 패턴 검색
   → list_patterns로 사용 가능한 패턴 확인

2. 폼 생성
   → generate_form으로 등록 폼 생성
   → fields: email, password, name, phone

3. 검증
   → validate_component로 각 필드 검증
   → analyze_accessibility로 접근성 체크

4. 개선
   → suggest_improvements로 코드 품질 체크
```

### 시나리오 2: 대시보드 구축

```
1. 패턴 사용
   → generate_pattern (dashboard)
   → customization: stats, chart, activity

2. 컴포넌트 추가
   → generate_component (card) - 통계 카드
   → generate_component (chart) - 차트 컴포넌트
   → generate_component (list) - 최근 활동

3. 스타일링
   → customize_style로 각 컴포넌트 스타일 조정

4. 최종 검증
   → suggest_improvements로 전체 코드 리뷰
```

### 시나리오 3: 기존 코드 개선

```
1. 분석
   → suggest_improvements로 현재 코드 분석

2. 문제 수정
   → 네이밍 오류 수정 (Button → PrimaryButton)
   → 누락된 import 추가
   → const 생성자 추가

3. 접근성 개선
   → analyze_accessibility로 각 컴포넌트 체크
   → semanticLabel 추가
   → 색상 대비 개선

4. 검증
   → validate_component로 최종 검증
```

## 💡 Best Practices

### 1. 항상 검증하기
```
생성 → 검증 → 접근성 분석 → 개선
```

### 2. 패턴 우선 사용
```
새 화면 필요 → 패턴 확인 → 패턴 사용 or 커스텀 생성
```

### 3. 접근성 고려
```
컴포넌트 생성 시 항상 analyze_accessibility 실행
```

### 4. 코드 리뷰
```
코드 완성 후 suggest_improvements로 자동 리뷰
```

## 🔍 디버깅 팁

### 도구가 작동하지 않을 때

1. **서버 로그 확인**
```bash
dart run bin/coui_mcp.dart 2>server.log
tail -f server.log
```

2. **JSON 요청 검증**
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | jq
```

3. **문서 경로 확인**
```bash
ls -la /path/to/docs/component_metadata.json
```

### 일반적인 오류

**오류: "Unknown tool"**
- tools/list로 사용 가능한 도구 확인
- 도구 이름 철자 확인

**오류: "File not found"**
- --docs-path 옵션으로 올바른 경로 지정
- 필수 파일 존재 확인

**오류: "Invalid component_name"**
- search_components로 유효한 컴포넌트 확인
- 소문자 사용 (button, not Button)
