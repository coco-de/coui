# CoUI Flutter - LLM 개발 가이드

> **AI 모델을 위한 완전한 coui_flutter 컴포넌트 참조 가이드**
> 
> 이 문서는 AI/LLM이 coui_flutter 컴포넌트를 정확하게 사용하여 Flutter 애플리케이션을 구축할 수 있도록 작성되었습니다.

## 📋 목차

1. [개요](#개요)
2. [🚨 중요: 명명 규칙](#중요-명명-규칙)
3. [빠른 시작](#빠른-시작)
4. [컴포넌트 카탈로그](#컴포넌트-카탈로그)
   - [Control (제어)](#control-제어-컴포넌트)
   - [Display (표시)](#display-표시-컴포넌트)
   - [Form (폼)](#form-폼-컴포넌트)
   - [Layout (레이아웃)](#layout-레이아웃-컴포넌트)
   - [Menu (메뉴)](#menu-메뉴-컴포넌트)
   - [Navigation (네비게이션)](#navigation-네비게이션-컴포넌트)
   - [Overlay (오버레이)](#overlay-오버레이-컴포넌트)
   - [Text (텍스트)](#text-텍스트-컴포넌트)
5. [테마 및 스타일링](#테마-및-스타일링)
6. [일반적인 패턴](#일반적인-패턴)
7. [빠른 참조 인덱스](#빠른-참조-인덱스)
8. [자주 하는 실수](#자주-하는-실수)

---

## 개요

**coui_flutter**는 Flutter 애플리케이션을 위한 현대적이고 포괄적인 UI 컴포넌트 라이브러리입니다.

### 핵심 특징

- ✅ **타입 안전성**: Dart의 강력한 타입 시스템 활용
- ✅ **풍부한 컴포넌트**: 80개 이상의 프로덕션 준비 완료 컴포넌트
- ✅ **테마 시스템**: 일관된 디자인을 위한 강력한 테마 지원
- ✅ **검증된 예제**: 모든 컴포넌트에 실행 가능한 예제 포함
- ✅ **크로스 플랫폼**: iOS, Android, Web, Desktop 지원

### 패키지 정보

```yaml
dependencies:
  coui_flutter: ^0.1.0
```

### 기본 Import

```dart
import 'package:coui_flutter/coui_flutter.dart';
```

이 한 줄의 import로 모든 coui_flutter 컴포넌트에 접근할 수 있습니다.

---

## 🚨 중요: 명명 규칙

### ❌ 잘못된 컴포넌트명 (절대 사용하지 마세요!)

```dart
// 이런 컴포넌트 이름은 존재하지 않습니다!
CoButton(...)          // ❌ 잘못됨
CoAvatar(...)          // ❌ 잘못됨
CoCard(...)            // ❌ 잘못됨
CoDivider(...)         // ❌ 잘못됨
CoInput(...)           // ❌ 잘못됨
CoDialog(...)          // ❌ 잘못됨
```

### ✅ 올바른 컴포넌트명

```dart
// coui_flutter 컴포넌트는 Co 접두사가 없습니다
PrimaryButton(...)     // ✅ 올바름
Avatar(...)            // ✅ 올바름
Card(...)              // ✅ 올바름
Divider(...)           // ✅ 올바름
Input(...)             // ✅ 올바름
Dialog(...)            // ✅ 올바름
```

### 명명 규칙 요약

1. **Co 접두사 없음**: 모든 컴포넌트는 `Co` 접두사 없이 직접 사용합니다.
2. **Variant 구분**: 컴포넌트 변형은 클래스명으로 구분합니다 (예: `PrimaryButton`, `SecondaryButton`, `GhostButton`)
3. **직관적 명명**: 컴포넌트 이름은 용도를 명확하게 나타냅니다.

---

## 빠른 시작

### 1. 기본 앱 구조

```dart
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoUI Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
```

### 2. 첫 번째 화면 만들기

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoUI Flutter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 타이틀
            const Text('Welcome').x2Large.bold,
            Gap.v(8),
            
            // 설명
            const Text('CoUI Flutter로 앱을 만들어보세요').muted,
            Gap.v(24),
            
            // 버튼
            PrimaryButton(
              onPressed: () {
                print('Button pressed!');
              },
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. 주요 컴포넌트 빠른 참조

```dart
// 버튼
PrimaryButton(child: Text('Primary'), onPressed: () {})
GhostButton(child: Text('Ghost'), onPressed: () {})

// 입력
Input(placeholder: '이름을 입력하세요')
TextArea(placeholder: '메시지를 입력하세요')

// 레이아웃
Card(child: Text('카드 내용'))
Divider()
Gap.v(16)  // 세로 간격
Gap.h(16)  // 가로 간격

// 표시
Avatar(child: Icon(Icons.person))
PrimaryBadge(child: Text('New'))

// 피드백
showDialog(
  context: context,
  builder: (context) => Dialog(child: Text('다이얼로그')),
)
```

---

## 컴포넌트 카탈로그

이 섹션에서는 모든 coui_flutter 컴포넌트를 카테고리별로 분류하여 상세히 설명합니다.

각 컴포넌트는 다음 정보를 포함합니다:
- **용도**: 컴포넌트의 사용 목적
- **주요 클래스**: 사용 가능한 클래스와 variant
- **기본 사용법**: 가장 간단한 예제
- **주요 매개변수**: 중요한 속성과 설정
- **실전 예제**: 실제 사용 시나리오
- **관련 컴포넌트**: 함께 사용하면 좋은 컴포넌트

---

## Control (제어) 컴포넌트

Control 컴포넌트는 사용자 상호작용을 처리하는 인터랙티브 요소입니다.

### Button

**용도**: 사용자가 액션을 수행하도록 유도하는 클릭 가능한 버튼

**주요 클래스**:
- `PrimaryButton` - 주요 액션을 위한 강조된 버튼
- `SecondaryButton` - 보조 액션을 위한 버튼
- `OutlineButton` - 테두리가 있는 버튼
- `GhostButton` - 배경 없는 텍스트 버튼
- `LinkButton` - 링크 스타일의 텍스트 버튼
- `TextButton` - 단순 텍스트 버튼
- `DestructiveButton` - 삭제/경고와 같은 위험한 액션용 버튼
- `IconButton` - 아이콘만 있는 버튼

**기본 사용법**:

```dart
// Primary Button - 주요 액션
PrimaryButton(
  child: const Text('Primary'),
  onPressed: () {
    // 버튼 클릭 처리
  },
)

// Secondary Button - 보조 액션
SecondaryButton(
  child: const Text('Secondary'),
  onPressed: () {},
)

// Outline Button - 테두리 버튼
OutlineButton(
  child: const Text('Outlined'),
  onPressed: () {},
)

// Ghost Button - 투명 버튼
GhostButton(
  child: const Text('Ghost'),
  onPressed: () {},
)

// Destructive Button - 경고 액션
DestructiveButton(
  child: const Text('Delete'),
  onPressed: () {},
)

// Link Button - 링크 스타일
LinkButton(
  child: const Text('Link'),
  onPressed: () {},
)
```

**주요 매개변수**:

- `child` (Widget, 필수) - 버튼 내부에 표시할 위젯 (보통 Text)
- `onPressed` (VoidCallback?, 선택) - 버튼 클릭 시 호출되는 함수. `null`이면 버튼이 비활성화됩니다.
- `leading` (Widget?, 선택) - 텍스트 앞쪽에 표시할 위젯 (보통 Icon)
- `trailing` (Widget?, 선택) - 텍스트 뒤쪽에 표시할 위젯 (보통 Icon)
- `style` (ButtonStyle?, 선택) - 커스텀 버튼 스타일

**실전 예제**:

```dart
// 1. 아이콘과 함께 사용
PrimaryButton(
  onPressed: () {},
  trailing: const Icon(Icons.add),
  child: const Text('Add'),
)

SecondaryButton(
  onPressed: () {},
  leading: const Icon(Icons.save),
  child: const Text('Save'),
)

// 2. 비활성화된 버튼 (onPressed를 null로 설정)
const PrimaryButton(child: Text('Disabled'))

// 3. 아이콘 전용 버튼
IconButton.primary(
  icon: const Icon(Icons.add),
  onPressed: () {},
  density: ButtonDensity.icon,
)

IconButton.ghost(
  icon: const Icon(Icons.more_vert),
  onPressed: () {},
  density: ButtonDensity.icon,
)

IconButton.destructive(
  icon: const Icon(Icons.delete),
  onPressed: () {},
  density: ButtonDensity.icon,
)

// 4. 여러 버튼을 가로로 나열
Wrap(
  spacing: 8,
  children: [
    PrimaryButton(
      child: const Text('Submit'),
      onPressed: () {},
    ),
    GhostButton(
      child: const Text('Cancel'),
      onPressed: () {},
    ),
  ],
)

// 5. 전체 너비 버튼
SizedBox(
  width: double.infinity,
  child: PrimaryButton(
    child: const Text('Full Width'),
    onPressed: () {},
  ),
)
```

**일반적인 사용 시나리오**:

```dart
// 폼 제출
Column(
  children: [
    Input(placeholder: '이름'),
    Gap.v(16),
    PrimaryButton(
      child: const Text('제출'),
      onPressed: () {
        // 폼 제출 로직
      },
    ),
  ],
)

// 삭제 확인 다이얼로그
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    GhostButton(
      child: const Text('취소'),
      onPressed: () => Navigator.pop(context),
    ),
    Gap.h(8),
    DestructiveButton(
      child: const Text('삭제'),
      onPressed: () {
        // 삭제 로직
        Navigator.pop(context);
      },
    ),
  ],
)

// 네비게이션
PrimaryButton(
  child: const Text('다음'),
  trailing: const Icon(Icons.arrow_forward),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NextPage()),
    );
  },
)
```

**관련 컴포넌트**:
- `ButtonGroup` - 여러 버튼을 그룹화
- `LoadingButton` - 로딩 상태를 표시하는 버튼

**예제 파일 참조**:
- Primary: `button/button_example_1.dart`
- Secondary: `button/button_example_2.dart`
- Outline: `button/button_example_3.dart`
- Ghost: `button/button_example_4.dart`
- Destructive: `button/button_example_5.dart`
- Link: `button/button_example_6.dart`
- Disabled: `button/button_example_7.dart`
- Icon: `button/button_example_8.dart`
- With Icons: `button/button_example_9.dart`

---

### Command

**용도**: 검색 가능한 명령 팔레트를 표시합니다 (Cmd+K 스타일).

**기본 사용법**:

```dart
// Command 다이얼로그 표시
showCommand(
  context: context,
  builder: (context) {
    return Command(
      // 명령 항목들
    );
  },
)
```

---

## Display (표시) 컴포넌트

Display 컴포넌트는 정보를 시각적으로 표시하는 비인터랙티브 요소입니다.

### Avatar

**용도**: 사용자 프로필 사진이나 아이콘을 원형/사각형으로 표시

**기본 사용법**:

```dart
// 이미지로 아바타 생성
Avatar(
  provider: NetworkImage('https://example.com/avatar.jpg'),
  initials: Avatar.getInitials('John Doe'),  // 이미지 로딩 실패 시 대체
  backgroundColor: Colors.blue,
)

// 아이콘으로 아바타 생성
Avatar(child: Icon(Icons.person))

// 이니셜로 아바타 생성
Avatar(initials: Avatar.getInitials('Jane Smith'))
```

**주요 매개변수**:
- `provider` (ImageProvider?, 선택) - 이미지 소스
- `initials` (String?, 선택) - 이미지 대신 표시할 이니셜 (예: "JS")
- `child` (Widget?, 선택) - 커스텀 위젯 (보통 Icon)
- `backgroundColor` (Color?, 선택) - 배경색

**실전 예제**:

```dart
// 프로필 헤더
Row(
  children: [
    Avatar(
      provider: NetworkImage(user.photoUrl),
      initials: Avatar.getInitials(user.name),
    ),
    Gap.h(12),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.name).bold,
        Text(user.email).muted.small,
      ],
    ),
  ],
)

// 아바타 그룹
AvatarGroup(
  children: [
    Avatar(initials: 'JD'),
    Avatar(initials: 'AS'),
    Avatar(initials: 'MK'),
  ],
)
```

---

### Badge

**용도**: 상태, 카운트, 라벨을 표시하는 작은 뱃지

**주요 클래스**:
- `PrimaryBadge` - 주요 상태 표시
- `SecondaryBadge` - 보조 상태 표시
- `OutlineBadge` - 테두리 뱃지
- `DestructiveBadge` - 경고/오류 상태 표시

**기본 사용법**:

```dart
PrimaryBadge(child: Text('Primary'))
SecondaryBadge(child: Text('Secondary'))
OutlineBadge(child: Text('Outline'))
DestructiveBadge(child: Text('Error'))
```

**실전 예제**:

```dart
// 알림 개수 표시
Row(
  children: [
    Icon(Icons.notifications),
    Gap.h(4),
    PrimaryBadge(child: Text('3')),
  ],
)

// 상태 표시
Row(
  children: [
    Text('서버 상태:'),
    Gap.h(8),
    SecondaryBadge(child: Text('실행 중')),
  ],
)
```

---

### Card

**용도**: 관련 정보를 그룹화하여 표시하는 컨테이너

**기본 사용법**:

```dart
Card(
  child: Column(
    children: [
      Text('제목').bold.large,
      Gap.v(8),
      Text('내용을 여기에 입력하세요'),
    ],
  ),
)

// 패딩 추가
Card(
  padding: EdgeInsets.all(16),
  child: Text('패딩이 있는 카드'),
)

// Surface Card (블러 효과)
SurfaceCard(
  child: Text('블러 효과가 있는 카드'),
)
```

**실전 예제**:

```dart
// 프로젝트 카드
Card(
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('프로젝트 생성').semiBold(),
      Gap.v(4),
      const Text('새 프로젝트를 빠르게 배포하세요').muted().small(),
      Gap.v(24),
      const TextField(placeholder: Text('프로젝트 이름')),
      Gap.v(16),
      const TextField(placeholder: Text('설명')),
      Gap.v(24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlineButton(child: const Text('취소'), onPressed: () {}),
          Gap.h(8),
          PrimaryButton(child: const Text('생성'), onPressed: () {}),
        ],
      ),
    ],
  ),
)
```

---

### Divider

**용도**: 콘텐츠를 시각적으로 구분하는 구분선

**기본 사용법**:

```dart
// 수평 구분선
Divider()

// 수직 구분선
VerticalDivider()
```

**실전 예제**:

```dart
// 섹션 구분
Column(
  children: [
    Text('섹션 1'),
    Divider(),
    Text('섹션 2'),
  ],
)

// 버튼 사이 구분
Row(
  children: [
    TextButton(child: Text('로그인'), onPressed: () {}),
    VerticalDivider(height: 12),
    TextButton(child: Text('회원가입'), onPressed: () {}),
  ],
)
```

---

### Gap

**용도**: 위젯 사이에 간격을 추가 (SizedBox의 편리한 대안)

**기본 사용법**:

```dart
// 세로 간격
Gap.v(8)   // 8px 세로 간격
Gap.v(16)  // 16px 세로 간격
Gap.v(24)  // 24px 세로 간격

// 가로 간격
Gap.h(8)   // 8px 가로 간격
Gap.h(16)  // 16px 가로 간격
```

**실전 예제**:

```dart
Column(
  children: [
    Text('제목'),
    Gap.v(8),
    Text('부제목'),
    Gap.v(16),
    PrimaryButton(child: Text('확인'), onPressed: () {}),
  ],
)

Row(
  children: [
    Icon(Icons.star),
    Gap.h(4),
    Text('4.5'),
  ],
)
```

---

### 기타 Display 컴포넌트 (간략)

- **Calendar** - 달력 및 날짜 선택기
- **Carousel** - 이미지 슬라이더
- **Chip** - 태그나 필터를 표시하는 작은 요소
- **CircularProgressIndicator** - 원형 로딩 인디케이터
- **LinearProgressIndicator** - 선형 진행률 표시
- **Progress** - 커스터마이징 가능한 진행률 표시
- **Loading** / **Skeleton** - 로딩 상태 플레이스홀더
- **CodeSnippet** - 코드 블록 표시
- **DotIndicator** - 페이지 인디케이터 (점)
- **NumberTicker** - 애니메이션 숫자 카운터
- **KeyboardShortcut** - 키보드 단축키 표시

---

## Form (폼) 컴포넌트

Form 컴포넌트는 사용자 입력을 받는 인터랙티브 요소입니다.

### Input / TextField

**용도**: 한 줄 텍스트 입력 필드

**기본 사용법**:

```dart
// 기본 입력 필드
TextField(placeholder: Text('이름을 입력하세요'))

// Input (TextField의 alias)
Input(placeholder: '이메일')
```

**주요 매개변수**:
- `placeholder` (Widget, 선택) - 플레이스홀더 텍스트
- `controller` (TextEditingController?, 선택) - 입력 값 제어
- `onChanged` (ValueChanged<String>?, 선택) - 값 변경 콜백
- `leading` (Widget?, 선택) - 앞쪽 아이콘
- `trailing` (Widget?, 선택) - 뒤쪽 아이콘 (예: 지우기 버튼)

**실전 예제**:

```dart
// 검색 입력
TextField(
  placeholder: Text('검색...'),
  leading: Icon(Icons.search),
  onChanged: (value) {
    // 검색 로직
  },
)

// 비밀번호 입력
TextField(
  placeholder: Text('비밀번호'),
  leading: Icon(Icons.lock),
  obscureText: true,
)

// 컨트롤러 사용
final controller = TextEditingController();

TextField(
  controller: controller,
  placeholder: Text('메시지'),
)

// 값 가져오기
print(controller.text);
```

---

### TextArea

**용도**: 여러 줄 텍스트 입력 필드

**기본 사용법**:

```dart
TextArea(
  placeholder: Text('메시지를 입력하세요'),
  minLines: 3,
  maxLines: 6,
)
```

---

### Checkbox

**용도**: Boolean 값을 선택하는 체크박스

**기본 사용법**:

```dart
bool isChecked = false;

Checkbox(
  value: isChecked,
  onChanged: (value) {
    setState(() {
      isChecked = value ?? false;
    });
  },
  child: Text('동의합니다'),
)
```

**실전 예제**:

```dart
// 약관 동의
Column(
  children: [
    Checkbox(
      value: termsAgreed,
      onChanged: (value) => setState(() => termsAgreed = value ?? false),
      child: Text('이용약관에 동의합니다'),
    ),
    Checkbox(
      value: privacyAgreed,
      onChanged: (value) => setState(() => privacyAgreed = value ?? false),
      child: Text('개인정보 처리방침에 동의합니다'),
    ),
  ],
)
```

---

### RadioGroup

**용도**: 여러 옵션 중 하나를 선택

**기본 사용법**:

```dart
String selected = 'option1';

RadioGroup<String>(
  value: selected,
  onChanged: (value) {
    setState(() {
      selected = value;
    });
  },
  items: [
    RadioGroupItem(value: 'option1', label: Text('옵션 1')),
    RadioGroupItem(value: 'option2', label: Text('옵션 2')),
    RadioGroupItem(value: 'option3', label: Text('옵션 3')),
  ],
)
```

---

### Toggle / Switch

**용도**: On/Off 상태를 전환하는 스위치

**기본 사용법**:

```dart
bool isEnabled = false;

Toggle(
  value: isEnabled,
  onChanged: (value) {
    setState(() {
      isEnabled = value;
    });
  },
)

// Switch (Toggle의 alias)
Switch(
  value: isEnabled,
  onChanged: (value) {
    setState(() {
      isEnabled = value;
    });
  },
)
```

---

### Select

**용도**: 드롭다운 선택 목록

**기본 사용법**:

```dart
String? selectedValue;

Select<String>(
  value: selectedValue,
  placeholder: Text('옵션을 선택하세요'),
  onChanged: (value) {
    setState(() {
      selectedValue = value;
    });
  },
  items: [
    SelectItem(value: '1', label: Text('옵션 1')),
    SelectItem(value: '2', label: Text('옵션 2')),
    SelectItem(value: '3', label: Text('옵션 3')),
  ],
)
```

---

### 기타 Form 컴포넌트 (간략)

- **Autocomplete** - 자동완성 입력
- **Slider** - 범위 값 선택 슬라이더
- **StarRating** - 별점 평가
- **DatePicker** - 날짜 선택
- **TimePicker** - 시간 선택
- **ColorPicker** - 색상 선택
- **PhoneInput** - 전화번호 입력 (국가 코드 포함)
- **InputOtp** - OTP 코드 입력
- **ChipInput** - 태그 입력 (멀티 셀렉트)
- **Form** - 폼 유효성 검사 래퍼

---

## Layout (레이아웃) 컴포넌트

### 주요 컴포넌트

- **Card** - 콘텐츠를 그룹화하는 컨테이너 (위에서 설명함)
- **Accordion** - 확장/축소 가능한 패널
- **Collapsible** - 토글 가능한 콘텐츠
- **Alert** - 알림 메시지 박스
- **AlertDialog** - 모달 알림 다이얼로그
- **Breadcrumb** - 네비게이션 경로 표시
- **Steps** - 다단계 프로세스 표시
- **Stepper** - 단계별 진행 상황
- **Timeline** - 시간순 이벤트 표시
- **Table** - 데이터 테이블
- **Tree** - 계층 구조 트리
- **Scaffold** - 기본 페이지 레이아웃
- **Window** - 창 레이아웃
- **Resizable** - 크기 조절 가능한 패널

**간단한 사용 예시**:

```dart
// Alert
Alert(
  child: Text('중요한 공지사항입니다'),
)

// Accordion
Accordion(
  items: [
    AccordionItem(
      header: Text('섹션 1'),
      child: Text('섹션 1 내용'),
    ),
    AccordionItem(
      header: Text('섹션 2'),
      child: Text('섹션 2 내용'),
    ),
  ],
)

// Breadcrumb
Breadcrumb(
  items: [
    BreadcrumbItem(label: Text('홈')),
    BreadcrumbItem(label: Text('제품')),
    BreadcrumbItem(label: Text('상세')),
  ],
)
```

---

## Menu (메뉴) 컴포넌트

- **ContextMenu** - 우클릭 메뉴
- **DropdownMenu** - 드롭다운 메뉴
- **Menubar** - 메뉴바
- **NavigationMenu** - 네비게이션 메뉴

---

## Navigation (네비게이션) 컴포넌트

- **NavigationBar** - 하단 네비게이션 바
- **NavigationRail** - 측면 네비게이션
- **NavigationSidebar** - 사이드바 네비게이션
- **Pagination** - 페이지 네비게이션
- **Tabs** / **TabList** / **TabPane** - 탭 네비게이션
- **Switcher** - 뷰 전환기

---

## Overlay (오버레이) 컴포넌트

Overlay 컴포넌트는 메인 콘텐츠 위에 표시되는 요소입니다.

### Dialog

**용도**: 모달 다이얼로그를 표시합니다.

**기본 사용법**:

```dart
// 다이얼로그 표시
showDialog(
  context: context,
  builder: (context) {
    return Dialog(
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
              GhostButton(
                child: Text('취소'),
                onPressed: () => Navigator.pop(context),
              ),
              Gap.h(8),
              DestructiveButton(
                child: Text('삭제'),
                onPressed: () {
                  // 삭제 로직
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  },
)
```

---

### Toast

**용도**: 일시적인 알림 메시지를 표시합니다.

**기본 사용법**:

```dart
// Toast 표시
showToast(
  context: context,
  builder: (context) {
    return Toast(
      child: Text('저장되었습니다'),
    );
  },
)
```

---

### Tooltip

**용도**: 호버 시 설명 텍스트를 표시합니다.

**기본 사용법**:

```dart
Tooltip(
  message: '이 버튼을 클릭하면 저장됩니다',
  child: IconButton.primary(
    icon: Icon(Icons.save),
    onPressed: () {},
  ),
)
```

---

### 기타 Overlay 컴포넌트

- **Drawer** - 측면에서 슬라이드되는 메뉴
- **Sheet** - 하단 시트
- **Popover** - 팝오버 (상세 정보 표시)
- **HoverCard** - 호버 카드

---

## Text (텍스트) 컴포넌트

coui_flutter는 Text 위젯에 강력한 extension을 제공합니다.

### 타이포그래피 크기

```dart
Text('Extra Small').xSmall    // 아주 작은 텍스트
Text('Small').small            // 작은 텍스트
Text('Base').base              // 기본 텍스트
Text('Large').large            // 큰 텍스트
Text('XLarge').xLarge          // 아주 큰 텍스트
Text('2XLarge').x2Large        // 더 큰 텍스트
Text('3XLarge').x3Large        // 매우 큰 텍스트
Text('4XLarge').x4Large        // 제목용 큰 텍스트
Text('5XLarge').x5Large        // 헤더용 큰 텍스트
Text('6XLarge').x6Large        // 메인 헤더
Text('7XLarge').x7Large        // 최대 크기
```

### 텍스트 스타일

```dart
Text('Bold').bold              // 굵게
Text('SemiBold').semiBold      // 중간 굵기
Text('Medium').medium          // 보통 굵기
Text('Regular').regular        // 기본 굵기
Text('Light').light            // 얇게

Text('Muted').muted            // 흐릿한 색상 (보통 회색)
Text('Primary').primary        // 주요 색상
Text('Destructive').destructive // 경고 색상

Text('Underline').underline    // 밑줄
Text('Italic').italic          // 기울임
Text('LineThrough').lineThrough // 취소선
```

### 조합 사용

```dart
// 여러 modifier를 체이닝
Text('Welcome').x2Large.bold.primary

Text('Description').small.muted

Text('Error Message').bold.destructive

// 실전 예제
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Dashboard').x3Large.bold,
    Gap.v(4),
    Text('Welcome back!').muted,
    Gap.v(24),
    Text('Recent Activity').large.semiBold,
    Gap.v(12),
    Text('You have 5 new notifications').small,
  ],
)
```

---

## 테마 및 스타일링

### Gap 시스템

일관된 간격을 위해 Gap을 사용하세요:

```dart
Gap.v(4)   // 4px  - 아주 작은 간격
Gap.v(8)   // 8px  - 작은 간격
Gap.v(12)  // 12px - 중간 간격
Gap.v(16)  // 16px - 기본 간격
Gap.v(24)  // 24px - 큰 간격
Gap.v(32)  // 32px - 아주 큰 간격
Gap.v(48)  // 48px - 섹션 간 간격

// 가로 간격도 동일
Gap.h(8), Gap.h(16), etc.
```

---

## 일반적인 패턴

### 1. 로그인 폼

```dart
Card(
  padding: EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('로그인').x2Large.bold,
      Gap.v(24),
      TextField(
        placeholder: Text('이메일'),
        leading: Icon(Icons.email),
      ),
      Gap.v(16),
      TextField(
        placeholder: Text('비밀번호'),
        leading: Icon(Icons.lock),
        obscureText: true,
      ),
      Gap.v(24),
      PrimaryButton(
        child: Text('로그인'),
        onPressed: () {},
      ),
      Gap.v(12),
      GhostButton(
        child: Text('회원가입'),
        onPressed: () {},
      ),
    ],
  ),
)
```

### 2. 리스트 아이템

```dart
Card(
  child: Row(
    children: [
      Avatar(initials: 'JD'),
      Gap.h(12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('John Doe').bold,
            Text('john@example.com').small.muted,
          ],
        ),
      ),
      IconButton.ghost(
        icon: Icon(Icons.more_vert),
        onPressed: () {},
      ),
    ],
  ),
)
```

### 3. 설정 화면

```dart
Column(
  children: [
    Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('알림'),
              Toggle(value: true, onChanged: (v) {}),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('다크 모드'),
              Toggle(value: false, onChanged: (v) {}),
            ],
          ),
        ],
      ),
    ),
  ],
)
```

---

## 빠른 참조 인덱스

### 용도별 컴포넌트 찾기

**버튼이 필요할 때**:
- 주요 액션 → `PrimaryButton`
- 보조 액션 → `SecondaryButton`
- 텍스트 버튼 → `GhostButton`, `LinkButton`
- 아이콘 버튼 → `IconButton`
- 위험한 액션 → `DestructiveButton`

**입력 필드가 필요할 때**:
- 한 줄 텍스트 → `TextField` / `Input`
- 여러 줄 텍스트 → `TextArea`
- 선택 → `Select`, `Autocomplete`
- 체크 → `Checkbox`
- 라디오 → `RadioGroup`
- 토글 → `Toggle` / `Switch`
- 슬라이더 → `Slider`
- 날짜 → `DatePicker`
- 시간 → `TimePicker`

**레이아웃이 필요할 때**:
- 카드 → `Card`
- 구분선 → `Divider`, `VerticalDivider`
- 간격 → `Gap.v()`, `Gap.h()`
- 테이블 → `Table`
- 아코디언 → `Accordion`

**표시가 필요할 때**:
- 아바타 → `Avatar`
- 배지 → `PrimaryBadge`, `SecondaryBadge`
- 진행률 → `Progress`, `CircularProgressIndicator`
- 로딩 → `Loading`, `Skeleton`

**피드백이 필요할 때**:
- 모달 → `Dialog`
- 알림 → `Toast`
- 툴팁 → `Tooltip`
- 경고 → `Alert`

---

## 자주 하는 실수

### 1. Co 접두사 사용 ❌

```dart
// ❌ 잘못됨
CoButton(...)
CoInput(...)
CoCard(...)

// ✅ 올바름
PrimaryButton(...)
TextField(...)
Card(...)
```

### 2. onPressed null 처리 잊기

```dart
// 비활성화하려면 onPressed를 null로
const PrimaryButton(child: Text('Disabled'))
// onPressed를 생략하면 에러 발생할 수 있음
```

### 3. Gap 대신 SizedBox 과용

```dart
// ❌ 비추천
SizedBox(height: 16)

// ✅ 추천
Gap.v(16)
```

### 4. Text modifier 순서

```dart
// ✅ 올바름 - 크기 → 스타일 → 색상
Text('Hello').large.bold.primary

// ❌ 작동은 하지만 일관성 없음
Text('Hello').primary.large.bold
```

### 5. setState 없이 상태 변경

```dart
// ❌ 잘못됨 - 화면이 업데이트되지 않음
bool isChecked = false;
Checkbox(
  value: isChecked,
  onChanged: (value) {
    isChecked = value ?? false;  // setState 없음!
  },
)

// ✅ 올바름
onChanged: (value) {
  setState(() {
    isChecked = value ?? false;
  });
}
```

---

## 마치며

이 가이드는 coui_flutter의 핵심 컴포넌트와 패턴을 다룹니다. 

더 자세한 정보는:
- 예제 코드: `packages/coui_flutter/docs/lib/pages/docs/components/`
- 컴포넌트 소스: `packages/coui_flutter/lib/src/components/`

**주의사항**:
- ✅ 모든 컴포넌트는 **Co 접두사 없이** 사용
- ✅ Variant는 클래스명으로 구분 (`PrimaryButton`, `GhostButton`)
- ✅ `Gap` 사용으로 일관된 간격 유지
- ✅ Text extensions로 타이포그래피 일관성 유지
- ✅ 상태 변경 시 항상 `setState` 사용

