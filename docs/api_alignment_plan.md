# CoUI API 정렬 계획

## 목표

coui_flutter와 coui_web이 **동일한 클래스명과 API 구조**를 사용하도록 정렬

## 현재 상태

### coui_flutter (Flutter)
```dart
import 'package:coui_flutter/coui_flutter.dart';

Button.primary(
  child: Text('Click'),
  onPressed: () => print('clicked'),
  leading: Icon(Icons.add),
  size: ButtonSize.md,
)
```

### coui_web (현재 - 다름)
```dart
import 'package:coui_web/coui_web.dart';

Button.primary(
  child: Component.text('Click'),          // Component != Widget
  onPressed: (MouseEvent e) => print(''),  // 다른 시그니처
  leading: Component(...),                 // Component
  size: ButtonSize.md,                     // enum은 동일
)
```

## 목표 상태

### coui_web (수정 후 - 동일)
```dart
import 'package:coui_web/coui_web.dart';

Button.primary(
  child: Component.text('Click'),  // Component (Web의 Widget)
  onPressed: () => print('clicked'), // VoidCallback 스타일
  leading: Component(...),          // Component
  size: ButtonSize.md,
)
```

**핵심**: `onPressed` 시그니처를 `void Function()?`로 통일!

## 필요한 수정사항

### 1. coui_web Button 수정

**Before**:
```dart
class Button extends UiComponent {
  Button({
    required this.child,
    this.onPressed,  // UiMouseEventHandler?
    ...
  });

  final UiMouseEventHandler? onPressed;
}
```

**After**:
```dart
class Button extends UiComponent {
  Button({
    required this.child,
    this.onPressed,  // void Function()?
    ...
  });

  final void Function()? onPressed;  // Flutter 스타일
}
```

### 2. 내부 구현 변환

```dart
@override
Component build(BuildContext context) {
  return Component.element(
    // onPressed를 내부에서 MouseEvent로 변환
    events: onPressed != null
        ? {'click': (event) => onPressed!()}
        : null,
    ...
  );
}
```

## 장점

1. ✅ **완전히 동일한 사용 코드**
2. ✅ **통합 패키지 불필요**
3. ✅ **간단한 구현**
4. ✅ **빠른 적용 가능**

## 구현 순서

1. ✅ coui_web의 Button `onPressed` 타입 변경
2. ⬜ coui_web의 Avatar, Skeleton, Chip 동일하게 수정
3. ⬜ 나머지 컴포넌트 순차적으로 정렬
4. ⬜ 예제 코드 작성 및 검증