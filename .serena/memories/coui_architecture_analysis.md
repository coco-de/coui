# CoUI 아키텍처 분석 및 통합 전략

## 프로젝트 개요
CoUI는 Flutter와 Web(Jaspr)에서 동일하게 렌더링되는 컴포넌트를 제공하는 모노레포 프로젝트입니다.

## 현재 상태

### 1. coui_flutter (v0.0.44)
**기술 스택**: Flutter SDK 기반
**컴포넌트 수**: 80+ 컴포넌트
**아키텍처**:
- StatefulWidget/StatelessWidget 기반
- ThemeData 중심의 테마 시스템
- ButtonStyle과 같은 MaterialState 기반 스타일링
- 풍부한 상호작용 지원 (onPressed, onHover, onFocus 등)

**주요 컴포넌트 카테고리**:
- Control: Button, Clickable, Command, Scrollbar, Scrollview
- Display: Avatar, Badge, Calendar, Carousel, Chip, Progress, Skeleton 등
- Form: Input, Checkbox, Select, DatePicker, TimePicker, Slider 등 (25+ 컴포넌트)
- Layout: Card, Dialog, Table, Tree, Accordion, Collapsible 등
- Menu: Menu, Menubar, ContextMenu, DropdownMenu, Popup
- Navigation: NavigationBar, Pagination, Tabs
- Overlay: Dialog, Drawer, HoverCard, Popover, Toast, Tooltip
- Text: Text, Selectable

**스타일링 패턴**:
```dart
Button(
  style: ButtonStyle.primary(
    size: ButtonSize.large,
    density: ButtonDensity.comfortable,
    shape: ButtonShape.rectangle,
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

### 2. coui_web (v0.1.0 - PoC)
**기술 스택**: Jaspr 기반 (DaisyUI 스타일)
**컴포넌트 수**: 14개 기본 컴포넌트
**아키텍처**:
- UiComponent 추상 클래스 기반
- Styling 클래스를 통한 CSS 유틸리티 패턴
- HTML 태그 직접 렌더링
- 간단한 이벤트 핸들링

**컴포넌트 목록**:
- Alert, Badge, Button, Card, Checkbox
- Divider, Icon, Input, Link, Loading
- Progress, Radio, Select, Textarea, Toggle

**스타일링 패턴**:
```dart
Button(
  tag: 'button',
  style: [
    ButtonStyling().primary().lg().wide(),
    Spacing.p4(),
  ],
  onClick: (e) {},
  child: text('Button'),
)
```

## 핵심 차이점

### 아키텍처
| 측면 | coui_flutter | coui_web |
|------|--------------|----------|
| 기본 클래스 | StatefulWidget/StatelessWidget | UiComponent (Jaspr StatelessComponent) |
| 렌더링 | Flutter Widgets | HTML/DOM |
| 스타일링 | ThemeData + MaterialState | CSS Classes + Styling utilities |
| 상태 관리 | State<T> | Stateless (이벤트 기반) |

### API 패턴
- **coui_flutter**: 객체 지향, 타입 안전성 높음, Flutter 생태계 통합
- **coui_web**: 함수형 스타일, CSS 유틸리티 기반, 경량화

### 컴포넌트 성숙도
- **coui_flutter**: 프로덕션 준비 (v0.0.44, 80+ 컴포넌트)
- **coui_web**: PoC 단계 (v0.1.0, 14개 컴포넌트)

## 통합 전략

### 전략 1: 추상화 레이어 도입 (권장)
**목표**: 플랫폼별 구현을 유지하면서 공통 API 제공

```
packages/
├── coui_core/          # 새로운 공통 추상화 레이어
│   ├── component_specs/    # 컴포넌트 스펙 정의
│   ├── style_system/       # 공통 스타일 시스템
│   └── platform_interface/ # 플랫폼 인터페이스
├── coui_flutter/       # Flutter 구현
├── coui_web/           # Web 구현
└── coui/               # 통합 패키지 (플랫폼 자동 선택)
```

**장점**:
- 기존 코드 재사용 가능
- 플랫폼별 최적화 유지
- 점진적 마이그레이션 가능

**구현 계획**:

#### Phase 1: Core 추상화 레이어
```dart
// packages/coui_core/lib/src/component_spec.dart
abstract class ComponentSpec<T extends ComponentStyle> {
  final T style;
  final List<Component>? children;
  final Component? child;
  
  const ComponentSpec({
    required this.style,
    this.children,
    this.child,
  });
}

// packages/coui_core/lib/src/button_spec.dart
class ButtonSpec extends ComponentSpec<ButtonStyleSpec> {
  final VoidCallback? onPressed;
  final bool enabled;
  
  const ButtonSpec({
    required super.style,
    this.onPressed,
    this.enabled = true,
    super.child,
  });
}
```

#### Phase 2: 플랫폼 구현
```dart
// packages/coui_flutter/lib/src/button_impl.dart
class ButtonImpl extends StatelessWidget {
  final ButtonSpec spec;
  
  const ButtonImpl(this.spec);
  
  @override
  Widget build(BuildContext context) {
    return Button(
      style: _convertToFlutterStyle(spec.style),
      onPressed: spec.onPressed,
      enabled: spec.enabled,
      child: spec.child,
    );
  }
}

// packages/coui_web/lib/src/button_impl.dart
class ButtonImpl extends UiComponent {
  final ButtonSpec spec;
  
  const ButtonImpl(this.spec);
  
  @override
  Component build(BuildContext context) {
    return Button(
      style: _convertToWebStyle(spec.style),
      onClick: spec.onPressed != null 
        ? (_) => spec.onPressed!() 
        : null,
      disabled: !spec.enabled,
      child: spec.child,
    );
  }
}
```

#### Phase 3: 통합 API
```dart
// packages/coui/lib/src/button.dart
import 'button_impl.dart' 
  if (dart.library.html) 'button_impl_web.dart'
  if (dart.library.io) 'button_impl_flutter.dart';

class CouiButton {
  static Widget create(ButtonSpec spec) {
    return ButtonImpl(spec);
  }
}
```

### 전략 2: 스타일 시스템 통합

**공통 스타일 정의**:
```dart
// packages/coui_core/lib/src/style_system.dart
enum ComponentSize { xs, sm, md, lg, xl }
enum ComponentVariant { primary, secondary, outline, ghost, link }
enum ComponentDensity { compact, comfortable, spacious }

abstract class ComponentStyleSpec {
  final ComponentSize? size;
  final ComponentVariant? variant;
  final ComponentDensity? density;
  
  const ComponentStyleSpec({
    this.size,
    this.variant,
    this.density,
  });
}

class ButtonStyleSpec extends ComponentStyleSpec {
  final bool? wide;
  final bool? circle;
  final bool? block;
  
  const ButtonStyleSpec({
    super.size,
    super.variant,
    super.density,
    this.wide,
    this.circle,
    this.block,
  });
}
```

**플랫폼별 변환**:
```dart
// packages/coui_flutter/lib/src/style_converter.dart
ButtonStyle convertToFlutterStyle(ButtonStyleSpec spec) {
  return ButtonStyle(
    size: _convertSize(spec.size),
    variance: _convertVariant(spec.variant),
    density: _convertDensity(spec.density),
    shape: spec.circle == true ? ButtonShape.circle : ButtonShape.rectangle,
  );
}

// packages/coui_web/lib/src/style_converter.dart
List<Styling> convertToWebStyle(ButtonStyleSpec spec) {
  return [
    if (spec.variant != null) _variantStyle(spec.variant!),
    if (spec.size != null) _sizeStyle(spec.size!),
    if (spec.wide == true) ButtonStyling().wide(),
    if (spec.circle == true) ButtonStyling().circle(),
  ];
}
```

### 전략 3: 컴포넌트 우선순위

**Phase 1 - 기본 컴포넌트** (3개월):
- Button, Input, Checkbox, Radio, Select
- Card, Alert, Badge
- Dialog, Toast

**Phase 2 - 폼 컴포넌트** (2개월):
- DatePicker, TimePicker, Slider
- Autocomplete, ChipInput
- FileInput, ColorPicker

**Phase 3 - 레이아웃 컴포넌트** (2개월):
- Table, Tree, Accordion
- Tabs, Navigation
- Drawer, Popover

**Phase 4 - 고급 컴포넌트** (3개월):
- Calendar, Carousel
- Menu system (Menu, Menubar, ContextMenu)
- Advanced layouts (Resizable, Sortable)

## 마이그레이션 전략

### 단계별 접근

**Step 1: 기반 구축 (1개월)**
1. coui_core 패키지 생성
2. ComponentSpec 추상화 정의
3. 스타일 시스템 설계
4. 플랫폼 인터페이스 정의

**Step 2: PoC 구현 (1개월)**
1. Button 컴포넌트로 전체 흐름 검증
2. Flutter/Web 양쪽 구현
3. 통합 API 테스트
4. 개발자 경험 평가

**Step 3: 핵심 컴포넌트 (3개월)**
1. 기본 8-10개 컴포넌트 마이그레이션
2. 테스트 커버리지 확보
3. 문서화 및 예제 작성

**Step 4: 점진적 확장 (6개월)**
1. 나머지 컴포넌트 마이그레이션
2. coui_web 기능 완성도 향상
3. 성능 최적화

### 호환성 유지

**기존 API 지원**:
```dart
// 기존 Flutter API (유지)
import 'package:coui_flutter/coui_flutter.dart';

Button(
  style: ButtonStyle.primary(),
  onPressed: () {},
  child: Text('Old API'),
)

// 새로운 통합 API
import 'package:coui/coui.dart';

CouiButton(
  spec: ButtonSpec(
    style: ButtonStyleSpec(variant: ComponentVariant.primary),
    onPressed: () {},
  ),
  child: Text('New API'),
)
```

## 기술적 고려사항

### 1. 조건부 임포트
```dart
export 'src/button.dart'
  if (dart.library.html) 'src/web/button.dart'
  if (dart.library.io) 'src/flutter/button.dart';
```

### 2. 빌드 시스템
- Melos를 통한 모노레포 관리 (이미 구축됨)
- 각 패키지별 독립 빌드
- 통합 테스트 환경

### 3. 테스트 전략
- 컴포넌트 스펙 유닛 테스트
- 플랫폼별 통합 테스트
- 시각적 회귀 테스트

### 4. 문서화
- 통합 API 문서
- 플랫폼별 구현 가이드
- 마이그레이션 가이드

## 예상 타임라인

- **Q1 2025**: 기반 구축 및 PoC (2개월)
- **Q2 2025**: 핵심 컴포넌트 (3개월)
- **Q3 2025**: 폼 컴포넌트 (3개월)
- **Q4 2025**: 레이아웃 및 고급 컴포넌트 (4개월)

## 성공 지표

1. **API 통일성**: 80% 이상 공통 API
2. **컴포넌트 패리티**: 50+ 컴포넌트 양쪽 지원
3. **성능**: 플랫폼별 네이티브 수준 유지
4. **개발자 경험**: 단일 코드로 양쪽 플랫폼 지원
5. **테스트 커버리지**: 80% 이상