# CoUI Widgetbook 린트 개선 보고서

## 실행일: 2025-09-30

### 📊 분석 결과

**스캔 대상**:
- 폴더: 25개
- 파일: 28개

**발견된 이슈**:
- WARNING: 77개
- STYLE: 56개
- 총합: **133개**

### 🔍 주요 이슈 패턴

#### 1. WARNING 이슈 (77개)

**가장 많이 발생한 이슈**:

1. **no-empty-block** (40개)
   - 빈 onPressed 블록
   - 예: `onPressed: () {}`
   
2. **avoid-unused-parameters** (28개)
   - 사용하지 않는 BuildContext 파라미터
   - 예: `Widget build(BuildContext context)` 에서 context 미사용

3. **avoid-unused-instances** (2개)
   - 사용하지 않는 인스턴스 생성

4. **avoid-unsafe-collection-methods** (1개)
   - `.last` 대신 `.lastOrNull` 사용 권장

5. **avoid-nullable-interpolation** (1개)
   - nullable 값의 문자열 보간

#### 2. STYLE 이슈 (56개)

1. **arguments-ordering** (55개)
   - Named arguments가 알파벳 순서대로 정렬되지 않음

2. **prefer-correct-identifier-length** (1개)
   - 식별자 길이가 너무 짧음 (예: `e`)

---

### ✅ 수행한 작업

#### 1. DCM 자동 수정 실행
```bash
cd app/coui_widgetbook
dcm fix lib
```

**결과**: arguments-ordering 등 일부 STYLE 이슈 자동 수정 완료

#### 2. 수동 수정 (예제)

**파일 1: `lib/component/chip/chip.dart`**
- 빈 onPressed 블록에 로그 추가
- 변경 전: `onPressed: () {}`
- 변경 후:
  ```dart
  onPressed: () {
    // ignore: avoid_print
    print('Chip pressed');
  }
  ```

**파일 2: `lib/component/select/select.dart`**
- nullable interpolation 수정
- 짧은 식별자 개선 (`e` → `option`)
- 변경 전: `(e) => SelectItemButton(value: e, child: Text(e))`
- 변경 후: `(option) => SelectItemButton(value: option, child: Text(option))`

---

### 🎯 권장 수정 방법

#### Pattern 1: 빈 onPressed 블록

**❌ 잘못된 예:**
```dart
coui.Button.primary(
  onPressed: () {},  // 빈 블록
  child: Text('Click me'),
)
```

**✅ 올바른 예:**
```dart
coui.Button.primary(
  onPressed: () {
    // ignore: avoid_print
    print('Button pressed');
  },
  child: Text('Click me'),
)
```

#### Pattern 2: 사용하지 않는 context

**❌ 잘못된 예:**
```dart
Widget buildSomethingUseCase(BuildContext context) {
  // context를 전혀 사용하지 않음
  return Container();
}
```

**✅ 올바른 예 1:** context 사용하기
```dart
Widget buildSomethingUseCase(BuildContext context) {
  return Container(
    color: context.knobs.color(label: 'color'),
  );
}
```

**✅ 올바른 예 2:** 정말 사용하지 않으면 _ 로
```dart
Widget buildSomethingUseCase(BuildContext _) {
  return Container();
}
```

#### Pattern 3: 짧은 식별자

**❌ 잘못된 예:**
```dart
items.map((e) => Text(e)).toList()
```

**✅ 올바른 예:**
```dart
items.map((item) => Text(item)).toList()
```

---

### 📋 남은 작업

#### 우선순위 1: WARNING 이슈 (수동 수정 필요)
1. **no-empty-block** (40개)
   - 모든 빈 onPressed에 로그 추가
   - 파일: input_otp, star_rating, chip_input, slider, switch, button 등

2. **avoid-unused-parameters** (28개)
   - 사용하지 않는 BuildContext를 _ 로 변경
   - 파일: date_picker, color_picker, time_picker, text_field 등

#### 우선순위 2: STYLE 이슈 (이미 일부 자동 수정 완료)
- arguments-ordering: DCM fix로 대부분 해결됨

---

### 🚀 향후 작업 가이드라인

#### 새로운 위젯북 작성 시

**✅ DO:**
```dart
@UseCase(name: 'example', type: MyWidget)
Widget buildMyWidgetExampleUseCase(BuildContext context) {
  return MyWidget(
    // knobs로 interactive하게!
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    onPressed: () {
      // ignore: avoid_print
      print('Widget pressed');  // 항상 로그 추가!
    },
    child: Text(context.knobs.string(label: 'text', initialValue: 'Hello')),
  );
}
```

**❌ DON'T:**
```dart
Widget buildMyWidgetExampleUseCase(BuildContext context) {
  return MyWidget(
    onPressed: () {},  // ❌ 빈 블록
    child: Text('Hello'),  // ❌ 하드코딩, knobs 미사용
  );
}
```

#### 커밋 전 체크리스트
```bash
# 1. DCM 분석
cd app/coui_widgetbook
dcm analyze lib --reporter=console

# 2. 자동 수정
dcm fix lib

# 3. 포맷팅
dart format lib/

# 4. 재확인
dcm analyze lib --reporter=console
```

---

### 📈 개선 효과 (예상)

#### Before (현재)
- WARNING: 77개
- STYLE: 56개
- **총 133개 이슈**

#### After (모든 수정 완료 시)
- WARNING: 0개 (목표)
- STYLE: 0개 (목표)
- **깨끗한 코드베이스** ✨

#### 예상 작업 시간
- 자동 수정: ✅ 완료 (1분)
- 수동 수정 (패턴 1-2): 약 30분
- 검증 및 테스트: 약 10분
- **총 예상 시간: 약 40분**

---

### 🛠️ 자동화 스크립트 (선택사항)

빈 블록을 일괄 수정하려면:

```bash
#!/bin/bash
# fix_empty_blocks.sh

find lib/component -name "*.dart" -exec sed -i '' \
  's/onPressed: () {}/onPressed: () {\
      \/\/ ignore: avoid_print\
      print('\''Action triggered'\'');\
    }/g' {} \;

dart format lib/
```

**주의**: sed 스크립트는 신중하게 사용하세요. Git으로 변경사항 확인 후 커밋!

---

### 📚 참고 문서

- **CoUI 린트 가이드라인**: `docs/LINT_GUIDELINES.md`
- **DCM 공식 문서**: https://dcm.dev/docs/
- **Widgetbook 문서**: https://docs.widgetbook.io/

---

**다음 단계**: 
1. 남은 WARNING 이슈 수동 수정
2. 전체 재분석 및 검증
3. 새로운 위젯북 작성 시 이 가이드라인 준수

**목표**: 깨끗한 위젯북 코드베이스 유지! ✨
