# CoUI Dart 린트 가이드라인

> CoUI 프로젝트의 코드 품질을 유지하기 위한 Dart 린트 규칙 및 베스트 프랙티스

## 목차
- [메모리 관리](#메모리-관리)
- [리스너 관리](#리스너-관리)
- [함수 설계](#함수-설계)
- [코드 정리](#코드-정리)
- [주석 작성](#주석-작성)
- [멤버 순서](#멤버-순서)
- [Enum 처리](#enum-처리)
- [Null Safety](#null-safety)

---

## 🔴 Priority 1: Critical Issues

### 메모리 관리

#### ❌ 잘못된 예: dispose되지 않는 필드
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
  // ❌ dispose 메서드가 없음!
}
```

#### ✅ 올바른 예: 항상 dispose 호출
```dart
class _MyWidgetState extends State<MyWidget> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose(); // ✅ 반드시 dispose!
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
```

**규칙**: `TextEditingController`, `AnimationController`, `FocusNode` 등은 반드시 dispose 호출!

---

### 리스너 관리

#### ❌ 잘못된 예: 제거되지 않는 리스너
```dart
class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
    // ❌ removeListener가 없음!
  }
  
  void _handleChange() {
    setState(() {});
  }
}
```

#### ✅ 올바른 예: dispose에서 리스너 제거
```dart
class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_handleChange); // ✅ 반드시 제거!
    super.dispose();
  }
  
  void _handleChange() {
    setState(() {});
  }
}
```

**규칙**: `addListener`를 사용했다면 반드시 `removeListener` 호출!

---

### Async 후 setState

#### ❌ 잘못된 예: 마운트 체크 없이 setState
```dart
Future<void> loadData() async {
  final data = await fetchData();
  setState(() {  // ❌ 위젯이 이미 unmount 되었을 수 있음!
    _data = data;
  });
}
```

#### ✅ 올바른 예: mounted 체크 후 setState
```dart
Future<void> loadData() async {
  final data = await fetchData();
  if (!mounted) return;  // ✅ 마운트 체크!
  setState(() {
    _data = data;
  });
}
```

**규칙**: `await` 이후 `setState`를 호출할 때는 항상 `mounted` 체크!

---

## 🟡 Priority 2: Code Quality

### 함수 설계

#### ❌ 잘못된 예: 항상 null을 반환
```dart
void Function()? onPressed() {
  // 복잡한 로직...
  return null;  // ❌ 항상 null을 반환한다면 의미 없음
}
```

#### ✅ 올바른 예 1: nullable 타입으로 명시
```dart
void Function()? get onPressed => null;  // ✅ 간단하게
```

#### ✅ 올바른 예 2: 실제 로직 구현
```dart
void Function()? onPressed() {
  if (widget.enabled) {
    return () => _handlePress();  // ✅ 조건에 따라 다른 값 반환
  }
  return null;
}
```

**규칙**: 함수가 항상 `null`을 반환한다면 `nullable` 필드나 getter로 변경!

---

### 불필요한 StatefulWidget

#### ❌ 잘못된 예: State가 없는 StatefulWidget
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.title);  // ❌ State를 전혀 사용하지 않음!
  }
}
```

#### ✅ 올바른 예: StatelessWidget으로 변경
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Text(title);  // ✅ 간단하고 효율적!
  }
}
```

**규칙**: `setState`, `initState`, `dispose` 등이 없다면 `StatelessWidget` 사용!

---

## 🟢 Priority 3: Style & Readability

### 코드 정리

#### ❌ 잘못된 예: 주석 처리된 코드
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Hello'),
      // Text('Old code'),  // ❌ 주석 처리된 코드
      // Container(
      //   child: Text('More old code'),
      // ),
    ],
  );
}
```

#### ✅ 올바른 예: 불필요한 코드 삭제
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Hello'),  // ✅ 깔끔!
    ],
  );
}
```

**규칙**: 주석 처리된 코드는 Git으로 관리하므로 삭제! 정말 필요하면 TODO 주석으로 표시!

---

### 주석 작성

#### ❌ 잘못된 예: 문장 형식이 아닌 주석
```dart
// calculate the sum  ❌ 소문자 시작, 마침표 없음
int sum(int a, int b) => a + b;
```

#### ✅ 올바른 예: 문장 형식 주석
```dart
/// Calculates the sum of two integers.  ✅ 대문자 시작, 마침표!
int sum(int a, int b) => a + b;
```

**규칙**: 주석은 대문자로 시작하고 마침표로 끝나는 완전한 문장으로!

---

### 멤버 순서

#### ❌ 잘못된 예: 순서 없는 멤버
```dart
class MyWidget extends StatefulWidget {
  void _helper() {}  // ❌ private method가 먼저
  
  @override
  State<MyWidget> createState() => _MyWidgetState();  // 생성자보다 늦음
  
  final String title;  // ❌ 필드가 중간에
  
  static const int maxCount = 10;  // ❌ static이 마지막에
}
```

#### ✅ 올바른 예: 정렬된 멤버 순서
```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key, required this.title});  // 1. 생성자
  
  static const int maxCount = 10;  // 2. static 멤버
  
  final String title;  // 3. 인스턴스 필드
  
  @override
  State<MyWidget> createState() => _MyWidgetState();  // 4. 오버라이드 메서드
  
  void _helper() {}  // 5. private 메서드
}
```

**규칙 순서**:
1. Constructors
2. Static methods/fields
3. Public fields
4. Private fields
5. Public methods (overrides 포함)
6. Private methods

---

### Enum 처리

#### ❌ 잘못된 예: if-else로 enum 처리
```dart
String getLabel(Status status) {
  if (status == Status.pending) {
    return 'Pending';
  } else if (status == Status.approved) {
    return 'Approved';
  } else if (status == Status.rejected) {
    return 'Rejected';
  }
  return 'Unknown';  // ❌ 새로운 enum 값 추가 시 놓칠 수 있음!
}
```

#### ✅ 올바른 예: switch로 enum 처리
```dart
String getLabel(Status status) {
  return switch (status) {  // ✅ 모든 케이스를 명시적으로!
    Status.pending => 'Pending',
    Status.approved => 'Approved',
    Status.rejected => 'Rejected',
  };
  // 새로운 enum 값이 추가되면 컴파일 에러 발생! ✅
}
```

**규칙**: Enum은 switch 사용! exhaustiveness checking 활용!

---

### Null Safety

#### ❌ 잘못된 예: null-assertion spread
```dart
List<Widget> children = [
  ...widget.leading!,  // ❌ ! 사용
  Text('Content'),
];
```

#### ✅ 올바른 예: null-aware spread
```dart
List<Widget> children = [
  ...?widget.leading,  // ✅ ...? 사용
  Text('Content'),
];```

**규칙**: null assertion(`!`) 대신 null-aware 연산자(`?`) 사용!

#### ❌ 잘못된 예: ?? 연산자 우선순위 불명확
```dart
final value = a ?? b == c;  // ❌ (a ?? b) == c ? 아니면 a ?? (b == c) ?
```

#### ✅ 올바른 예: 괄호로 명확하게
```dart
final value = (a ?? b) == c;  // ✅ 의도가 명확!
// 또는
final value = a ?? (b == c);  // ✅ 이것도 명확!
```

**규칙**: `??` 연산자와 다른 연산자를 함께 사용할 때는 괄호로 우선순위 명시!

---

## 📋 DCM 자동 수정

DCM은 많은 이슈를 자동으로 수정할 수 있습니다:

```bash
# 모든 패키지의 린트 이슈 자동 수정
melos run fix:dcm

# 또는 특정 패키지만
cd packages/coui_flutter
dcm fix lib
```

**자동 수정 가능한 규칙들**:
- `format-comment`: 주석 형식
- `member-ordering`: 멤버 순서
- `prefer-null-aware-spread`: null-aware spread
- `prefer-parentheses-with-if-null`: 괄호 추가
- `prefer-switch-with-enums`: if-else → switch

**수동 수정 필요한 규칙들**:
- `always-remove-listener`: 리스너 제거 로직
- `dispose-class-fields`: dispose 메서드 추가
- `avoid-commented-out-code`: 불필요한 코드 삭제
- `function-always-returns-null`: 함수 로직 재설계

---

## 🔍 린트 분석 워크플로우

### 1. 코드 작성 전
- 이 가이드라인을 숙지
- IDE의 린트 경고를 확인하며 작성

### 2. 커밋 전
```bash
# 분석 실행
melos run analyze:dcm

# 자동 수정 가능한 것들 수정
melos run fix:dcm

# 포맷팅
melos run format
```

### 3. PR 전
```bash
# 전체 분석 (Dart Analyzer + DCM)
melos run analyze:all
```

---

## 🎯 목표

- **WARNING 이슈**: 0개 (메모리 누수 방지)
- **STYLE 이슈**: 최소화 (코드 가독성)
- **코드 리뷰**: 린트 가이드라인 기반

---

## 📚 참고 자료

- [DCM 공식 문서](https://dcm.dev/docs/)
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## ⚠️ 주의사항

### 린트 규칙 무시하기 (최후의 수단)
정말 필요한 경우에만 린트 규칙을 무시할 수 있습니다:

```dart
// ignore: always-remove-listener
widget.controller.addListener(_handleChange);
```

하지만 **가능한 한 규칙을 따르는 것이 좋습니다**. 무시하기 전에:
1. 왜 이 규칙이 적용되었는지 이해하기
2. 코드를 재설계하여 규칙을 따를 수 있는지 검토하기
3. 정말 불가피한 경우에만 무시하고, 이유를 주석으로 명시하기

```dart
// HACK: Flutter 프레임워크 버그로 인해 removeListener가 크래시를 발생시킴
// TODO(username): Flutter 3.20에서 수정되면 제거하기
// ignore: always-remove-listener
widget.controller.addListener(_handleChange);
```

---

**마지막 업데이트**: 2025년 9월 30일
**관리자**: CoUI 팀
