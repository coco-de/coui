# CoUI 통합 API 전략

## 문제 상황

현재 coui_flutter와 coui_web의 API가 완전히 달라서 동일한 코드로 사용 불가능:

```dart
// Flutter
Button.primary(
  child: Text('Click'),
  onPressed: () => print('clicked'),
)

// Web (현재)
Button.primary(
  child: Component.text('Click'),
  onPressed: (MouseEvent e) => print('clicked'),
)
```

## 해결 방안

### 방안 1: 조건부 import를 활용한 Platform 추상화 (권장)

```
coui/
├── packages/
│   ├── coui/                    # 통합 패키지 (NEW!)
│   │   ├── lib/
│   │   │   ├── coui.dart       # 메인 export
│   │   │   ├── src/
│   │   │   │   ├── button.dart          # 공통 인터페이스
│   │   │   │   ├── button_stub.dart     # 스텁
│   │   │   │   ├── button_flutter.dart  # Flutter 구현
│   │   │   │   └── button_web.dart      # Web 구현
│   ├── coui_flutter/           # Flutter 전용 패키지
│   └── coui_web/               # Web 전용 패키지
```

**사용 예시**:
```dart
// app에서 단일 import
import 'package:coui/coui.dart';

// Flutter와 Web에서 동일하게 작동
Button.primary(
  child: Text('Click me'),
  onPressed: () => print('clicked'),
  leading: Icon(Icons.add),
)
```

**장점**:
- ✅ 완전히 동일한 API
- ✅ 타입 안정성 보장
- ✅ IDE 자동완성 완벽 지원
- ✅ 플랫폼별 최적화 가능

**단점**:
- ❌ 초기 설정 복잡도
- ❌ 3개 패키지 관리 필요

### 방안 2: 어댑터 레이어 (간단하지만 제한적)

```dart
// coui_web에 Flutter-like wrapper 추가
class FlutterButton {
  static Component primary({
    required Widget child,
    VoidCallback? onPressed,
    Widget? leading,
  }) {
    return Button.primary(
      child: _convertWidget(child),
      onPressed: onPressed != null ? (_) => onPressed() : null,
      leading: leading != null ? _convertWidget(leading) : null,
    );
  }
}
```

**장점**:
- ✅ 빠른 구현
- ✅ 기존 코드 재사용

**단점**:
- ❌ Widget → Component 변환 오버헤드
- ❌ 모든 Flutter 기능 지원 어려움
- ❌ 완벽한 API 동일성 불가능

### 방안 3: Code Generation (장기적으로 최선)

```yaml
# coui_generator 패키지
coui_generator:
  components:
    - button
    - input
    - card
  platforms:
    - flutter
    - web
```

**build_runner**로 플랫폼별 코드 자동 생성:
```bash
dart run build_runner build
```

**장점**:
- ✅ 완벽한 API 일관성
- ✅ 타입 안정성
- ✅ 유지보수 용이
- ✅ 새 플랫폼 추가 쉬움

**단점**:
- ❌ 초기 개발 시간 많이 소요
- ❌ 빌드 스텝 추가

## 권장 구현 단계

### Phase 1: 조건부 import 패턴 도입 (1-2주)

1. **coui 통합 패키지 생성**
   ```bash
   cd packages
   mkdir coui
   dart create coui --template=package-simple
   ```

2. **조건부 export 설정**
   ```dart
   // lib/coui.dart
   export 'src/button.dart';

   // lib/src/button.dart
   export 'button_stub.dart'
       if (dart.library.html) 'button_web.dart'
       if (dart.library.io) 'button_flutter.dart';
   ```

3. **공통 인터페이스 정의**
   ```dart
   // lib/src/button_interface.dart
   abstract class ButtonInterface {
     factory ButtonInterface.primary({
       required dynamic child,
       required VoidCallback? onPressed,
       dynamic leading,
     }) = Button.primary;
   }
   ```

4. **플랫폼별 구현**
   - `button_flutter.dart`: coui_flutter의 Button 래핑
   - `button_web.dart`: coui_web의 Button 래핑

### Phase 2: 핵심 컴포넌트 통합 (2-3주)

우선순위별 통합:
1. Button, Input, Checkbox (가장 많이 사용)
2. Card, Dialog, Select
3. Avatar, Chip, Badge
4. 나머지 컴포넌트들

### Phase 3: 고급 기능 (3-4주)

- 테마 시스템 통합
- 폼 관리 통합
- 애니메이션 통합
- 접근성 기능 통합

## 코드 예시: Button 통합

### 공통 인터페이스
```dart
// packages/coui/lib/src/components/button.dart
abstract class Button {
  factory Button.primary({
    required Object child,
    VoidCallback? onPressed,
    Object? leading,
    Object? trailing,
  }) = _Button.primary;

  factory Button.secondary({...}) = _Button.secondary;
  factory Button.outline({...}) = _Button.outline;
}
```

### Flutter 구현
```dart
// packages/coui/lib/src/components/button_flutter.dart
import 'package:coui_flutter/coui_flutter.dart' as flutter;

class _Button implements Button {
  factory _Button.primary({
    required Object child,
    VoidCallback? onPressed,
    Object? leading,
    Object? trailing,
  }) {
    return _Button._(
      flutter.Button.primary(
        child: child as Widget,
        onPressed: onPressed,
        leading: leading as Widget?,
        trailing: trailing as Widget?,
      ),
    );
  }
}
```

### Web 구현
```dart
// packages/coui/lib/src/components/button_web.dart
import 'package:coui_web/coui_web.dart' as web;

class _Button implements Button {
  factory _Button.primary({
    required Object child,
    VoidCallback? onPressed,
    Object? leading,
    Object? trailing,
  }) {
    return _Button._(
      web.Button.primary(
        child: child as Component,
        onPressed: onPressed != null ? (_) => onPressed() : null,
        leading: leading as Component?,
        trailing: trailing as Component?,
      ),
    );
  }
}
```

## 마이그레이션 가이드

### Before (플랫폼별 코드)
```dart
// Flutter app
import 'package:coui_flutter/coui_flutter.dart';

Button.primary(
  child: Text('Click'),
  onPressed: () {},
)

// Web app
import 'package:coui_web/coui_web.dart';

Button.primary(
  child: Component.text('Click'),
  onPressed: (_) {},
)
```

### After (통합 코드)
```dart
// Both Flutter and Web
import 'package:coui/coui.dart';

Button.primary(
  child: Text('Click'),  // or Component.text() on web
  onPressed: () {},
)
```

## 다음 단계

1. ✅ 현재 문제 분석 완료
2. ⬜ 통합 패키지 구조 결정
3. ⬜ Button 컴포넌트 PoC 구현
4. ⬜ 테스트 및 검증
5. ⬜ 나머지 컴포넌트 마이그레이션
6. ⬜ 문서화 및 예제 작성