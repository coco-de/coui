# CoUI Flutter - 빠른 참조 가이드

> **AI/LLM을 위한 coui_flutter 컴포넌트 치트시트**

## 🚨 가장 중요한 규칙

### ❌ Co 접두사 사용하지 마세요!

```dart
// ❌ 절대 하지 마세요
Button(...)
Avatar(...)
Card(...)
```

### ✅ 올바른 컴포넌트명

```dart
// ✅ 이렇게 사용하세요
PrimaryButton(...)
Avatar(...)
Card(...)
```

---

## 컴포넌트 빠른 찾기

### Control (제어)

| 컴포넌트 | 사용 예시 |
|---------|----------|
| `PrimaryButton` | `PrimaryButton(child: Text('확인'), onPressed: () {})` |
| `SecondaryButton` | `SecondaryButton(child: Text('취소'), onPressed: () {})` |
| `GhostButton` | `GhostButton(child: Text('취소'), onPressed: () {})` |
| `IconButton` | `IconButton.primary(icon: Icon(Icons.add), onPressed: () {})` |
| `DestructiveButton` | `DestructiveButton(child: Text('삭제'), onPressed: () {})` |

### Display (표시)

| 컴포넌트 | 사용 예시 |
|---------|----------|
| `Avatar` | `Avatar(initials: 'JD')` |
| `PrimaryBadge` | `PrimaryBadge(child: Text('New'))` |
| `Card` | `Card(child: Text('내용'))` |
| `Divider` | `Divider()` |
| `Gap.v(16)` | 세로 간격 16px |
| `Gap.h(8)` | 가로 간격 8px |

### Form (폼)

| 컴포넌트 | 사용 예시 |
|---------|----------|
| `TextField` | `TextField(placeholder: Text('이름'))` |
| `TextArea` | `TextArea(placeholder: Text('내용'), minLines: 3)` |
| `Checkbox` | `Checkbox(value: true, onChanged: (v) {}, child: Text('동의'))` |
| `RadioGroup` | `RadioGroup(value: selected, items: [...], onChanged: (v) {})` |
| `Toggle` | `Toggle(value: true, onChanged: (v) {})` |
| `Select` | `Select(items: [...], onChanged: (v) {})` |

### Overlay (오버레이)

| 컴포넌트 | 사용 예시 |
|---------|----------|
| `Dialog` | `showDialog(context: context, builder: (c) => Dialog(...))` |
| `Toast` | `showToast(context: context, builder: (c) => Toast(...))` |
| `Tooltip` | `Tooltip(message: '설명', child: ...)` |

### Text (텍스트)

| Extension | 사용 예시 |
|----------|----------|
| 크기 | `Text('Hello').large`, `.x2Large`, `.x3Large` |
| 굵기 | `Text('Hello').bold`, `.semiBold`, `.light` |
| 색상 | `Text('Hello').base200`, `.primary`, `.destructive` |
| 조합 | `Text('Welcome').x2Large.bold.primary` |

---

## 일반적인 패턴

### 로그인 폼

```dart
Column(
  children: [
    TextField(placeholder: Text('이메일'), leading: Icon(Icons.email)),
    Gap.v(16),
    TextField(placeholder: Text('비밀번호'), obscureText: true),
    Gap.v(24),
    PrimaryButton(child: Text('로그인'), onPressed: () {}),
  ],
)
```

### 프로필 카드

```dart
Card(
  padding: EdgeInsets.all(16),
  child: Row(
    children: [
      Avatar(initials: 'JD'),
      Gap.h(12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('John Doe').bold,
          Text('john@example.com').small.base200,
        ],
      ),
    ],
  ),
)
```

### 확인 다이얼로그

```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('확인').bold.large,
        Gap.v(16),
        Text('정말 삭제하시겠습니까?'),
        Gap.v(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(child: Text('취소'), onPressed: () => Navigator.pop(context)),
            Gap.h(8),
            DestructiveButton(child: Text('삭제'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ],
    ),
  ),
)
```

### 설정 토글

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('다크 모드'),
    Toggle(value: isDark, onChanged: (v) => setState(() => isDark = v)),
  ],
)
```

---

## 자주 사용하는 Gap 값

```dart
Gap.v(4)   // 아주 작은 간격
Gap.v(8)   // 작은 간격
Gap.v(16)  // 기본 간격
Gap.v(24)  // 큰 간격
Gap.v(32)  // 아주 큰 간격
```

---

## 버튼 상태

```dart
// 활성화
PrimaryButton(child: Text('Submit'), onPressed: () {})

// 비활성화 (onPressed를 null로)
const PrimaryButton(child: Text('Disabled'))
```

---

## 입력 필드 컨트롤러

```dart
final controller = TextEditingController();

TextField(
  controller: controller,
  placeholder: Text('입력하세요'),
)

// 값 가져오기
print(controller.text);

// 값 설정하기
controller.text = '새 값';
```

---

## 체크박스/토글 상태 관리

```dart
bool isChecked = false;

Checkbox(
  value: isChecked,
  onChanged: (value) {
    setState(() {
      isChecked = value ?? false;  // setState 필수!
    });
  },
  child: Text('동의합니다'),
)
```

---

## 전체 예제: 간단한 폼 화면

```dart
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class SimpleFormScreen extends StatefulWidget {
  const SimpleFormScreen({super.key});

  @override
  State<SimpleFormScreen> createState() => _SimpleFormScreenState();
}

class _SimpleFormScreenState extends State<SimpleFormScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool agreeTerms = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('계정 생성').x2Large.bold,
            Gap.v(8),
            const Text('새 계정을 만들어보세요').base200,
            Gap.v(32),
            
            TextField(
              controller: emailController,
              placeholder: const Text('이메일'),
              leading: const Icon(Icons.email),
            ),
            Gap.v(16),
            
            TextField(
              controller: passwordController,
              placeholder: const Text('비밀번호'),
              leading: const Icon(Icons.lock),
              obscureText: true,
            ),
            Gap.v(24),
            
            Checkbox(
              value: agreeTerms,
              onChanged: (value) {
                setState(() {
                  agreeTerms = value ?? false;
                });
              },
              child: const Text('이용약관에 동의합니다'),
            ),
            Gap.v(32),
            
            PrimaryButton(
              onPressed: agreeTerms
                  ? () {
                      // 회원가입 로직
                      print('Email: ${emailController.text}');
                      print('Password: ${passwordController.text}');
                    }
                  : null,
              child: const Text('회원가입'),
            ),
            Gap.v(12),
            
            GhostButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('이미 계정이 있으신가요?'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 알파벳순 컴포넌트 목록

- Accordion
- Alert / AlertDialog
- Autocomplete
- Avatar / AvatarGroup
- Badge (Primary, Secondary, Outline, Destructive)
- Breadcrumb
- Button (Primary, Secondary, Outline, Ghost, Link, Text, Destructive, Icon)
- Calendar
- Card / SurfaceCard
- Carousel
- Checkbox
- Chip / ChipInput
- CircularProgressIndicator / LinearProgressIndicator
- CodeSnippet
- Collapsible
- ColorPicker
- Command
- ContextMenu
- DatePicker
- Dialog
- Divider / VerticalDivider
- DotIndicator
- Drawer
- DropdownMenu
- Gap
- HoverCard
- Input / TextField
- InputOtp
- ItemPicker
- Kbd
- Loading / Skeleton
- Menubar
- NavigationBar / NavigationMenu / NavigationRail / NavigationSidebar
- NumberTicker
- Pagination
- PhoneInput
- Popover
- Progress
- RadioGroup
- Resizable
- Scaffold
- Select
- Sheet
- Slider
- StarRating
- Stepper / Steps
- Switch / Toggle
- Switcher
- Table
- Tabs / TabList / TabPane
- TextArea
- Timeline
- TimePicker
- Toast
- Tooltip
- Tree
- Window

---

## 주의사항 요약

1. ✅ **Co 접두사 없음** - `PrimaryButton`, `Avatar`, `Card` 등
2. ✅ **Gap 사용** - `Gap.v(16)`, `Gap.h(8)`
3. ✅ **setState 필수** - 상태 변경 시 항상 사용
4. ✅ **Text extensions** - `.bold`, `.base200`, `.large` 등
5. ✅ **onPressed null** - 버튼 비활성화

