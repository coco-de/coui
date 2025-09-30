# CoUI Component Implementation Guide

## 목표
coui_flutter의 API 구조를 coui_web에서 동일하게 제공하여 개발자가 Flutter와 Web에서 같은 코드 패턴으로 UI를 구현할 수 있도록 한다.

## 설계 원칙

### 1. API 호환성
- coui_flutter의 API 서명을 최대한 유지
- Named constructors 제공 (`.primary()`, `.secondary()`, `.outline()` 등)
- 동일한 파라미터 이름 사용

### 2. 플랫폼별 차이 허용
- Flutter: StatefulWidget/StatelessWidget 기반
- Web: UiComponent 기반, DaisyUI CSS 클래스 사용
- 내부 구현은 다르지만 외부 API는 동일

### 3. 점진적 구현
- 카테고리별로 1-2개 템플릿 구현
- 패턴 확립 후 나머지 컴포넌트에 적용

## 구현 패턴

### Button 컴포넌트 (Control 카테고리)

#### coui_flutter API
```dart
Button(
  child: Text('Click me'),
  onPressed: () {},
  enabled: true,
  leading: Icon(Icons.add),
  trailing: Icon(Icons.arrow_forward),
  style: ButtonStyle.primary(size: ButtonSize.lg),
)

Button.primary(
  child: Text('Primary'),
  onPressed: () {},
)
```

#### coui_web 구현 전략

**1. 기본 구조**
```dart
class Button extends UiComponent {
  // coui_flutter와 동일한 파라미터
  Button({
    required Widget child,  // Jaspr에서는 Component
    VoidCallback? onPressed,
    bool enabled = true,
    Widget? leading,
    Widget? trailing,
    ButtonSize? size,
    ButtonShape? shape,
  }) : super(...);

  // Named constructors
  Button.primary({...}) : this(...);
  Button.secondary({...}) : this(...);
  Button.outline({...}) : this(...);
}
```

**2. 스타일 매핑**
```dart
// coui_flutter → DaisyUI 클래스 매핑
ButtonSize.xs    → 'btn-xs'
ButtonSize.sm    → 'btn-sm'
ButtonSize.md    → 'btn-md'
ButtonSize.lg    → 'btn-lg'
ButtonSize.xl    → 'btn-xl'

ButtonStyle.primary    → 'btn-primary'
ButtonStyle.secondary  → 'btn-secondary'
ButtonStyle.outline    → 'btn-outline'
ButtonStyle.ghost      → 'btn-ghost'
```

**3. 이벤트 핸들러 매핑**
```dart
// Flutter → Jaspr 이벤트
onPressed    → onClick
onHover      → onMouseEnter + onMouseLeave
onFocus      → onFocus + onBlur
```

### Input 컴포넌트 (Form 카테고리)

#### coui_flutter API
```dart
Input(
  value: 'text',
  onChanged: (value) {},
  placeholder: 'Enter text',
  enabled: true,
  prefix: Icon(Icons.search),
  suffix: Icon(Icons.clear),
)
```

#### coui_web 구현
```dart
class Input extends UiComponent {
  Input({
    String? value,
    ValueChanged<String>? onChanged,
    String? placeholder,
    bool enabled = true,
    Widget? prefix,
    Widget? suffix,
  }) : super(
    tag: 'input',
    attributes: {
      'value': value,
      'placeholder': placeholder,
      if (!enabled) 'disabled': '',
    },
    style: [
      InputStyle.base,  // 'input' 클래스
      if (prefix != null || suffix != null) InputStyle.bordered,
    ],
    onInput: onChanged != null ? (e) => onChanged(e.value) : null,
  );
}
```

### Avatar 컴포넌트 (Display 카테고리)

#### coui_flutter API
```dart
Avatar(
  image: NetworkImage('url'),
  size: AvatarSize.md,
  shape: AvatarShape.circle,
  placeholder: Icon(Icons.person),
)
```

#### coui_web 구현
```dart
class Avatar extends UiComponent {
  Avatar({
    ImageProvider? image,
    AvatarSize size = AvatarSize.md,
    AvatarShape shape = AvatarShape.circle,
    Widget? placeholder,
  }) : super(
    tag: 'div',
    classes: 'avatar',
    style: [
      _getSizeStyle(size),
      if (shape == AvatarShape.circle) AvatarStyle.circle,
    ],
    child: _buildAvatarContent(image, placeholder),
  );

  static Component _buildAvatarContent(ImageProvider? image, Widget? placeholder) {
    if (image != null) {
      return img(src: image.url, classes: 'rounded-full');
    }
    return placeholder ?? div(children: [text('?')]);
  }
}
```

## 구현 체크리스트

### 각 컴포넌트 구현 시
- [ ] coui_flutter API 분석 완료
- [ ] Named constructors 구현
- [ ] 파라미터 매핑 (이름 동일)
- [ ] 이벤트 핸들러 매핑
- [ ] DaisyUI 클래스 매핑
- [ ] leading/trailing/prefix/suffix 지원
- [ ] enabled/disabled 상태 처리
- [ ] Size 변형 지원
- [ ] 기본 문서화 작성

### 카테고리별 진행 상태

#### Control (버튼, 인터랙션)
- [ ] Button (템플릿) - 진행중
- [ ] Clickable
- [ ] Command
- [ ] Scrollbar
- [ ] Scrollview

#### Form (입력 요소)
- [ ] Input (템플릿)
- [ ] Checkbox
- [ ] Radio/RadioGroup
- [ ] Select
- [ ] Switch/Toggle
- [ ] Slider
- [ ] DatePicker
- [ ] TimePicker
- [ ] ColorPicker
- [ ] FileInput
- [ ] TextArea
- [ ] Autocomplete
- [ ] ChipInput
- [ ] StarRating
- [ ] PhoneInput
- [ ] InputOTP
- [ ] FormattedInput

#### Display (표시 요소)
- [ ] Avatar (템플릿)
- [ ] Badge
- [ ] Chip
- [ ] Progress
- [ ] Spinner/CircularProgressIndicator
- [ ] LinearProgressIndicator
- [ ] Skeleton
- [ ] Calendar
- [ ] Carousel
- [ ] CodeSnippet
- [ ] Divider
- [ ] DotIndicator
- [ ] KeyboardShortcut
- [ ] NumberTicker

#### Layout (레이아웃)
- [ ] Card (템플릿)
- [ ] Dialog/AlertDialog
- [ ] Drawer
- [ ] Accordion
- [ ] Alert
- [ ] Breadcrumb
- [ ] Collapsible
- [ ] FocusOutline
- [ ] OutlinedContainer
- [ ] OverflowMarquee
- [ ] Resizable
- [ ] Scaffold
- [ ] ScrollableClient
- [ ] Sortable
- [ ] StageContainer
- [ ] Stepper/Steps
- [ ] Table
- [ ] Timeline
- [ ] Tree
- [ ] Window

#### Navigation (내비게이션)
- [ ] NavigationBar
- [ ] Pagination
- [ ] Tabs/TabList/TabPane/TabContainer
- [ ] Subfocus
- [ ] Switcher

#### Menu (메뉴)
- [ ] Menu
- [ ] Menubar
- [ ] NavigationMenu
- [ ] ContextMenu
- [ ] DropdownMenu
- [ ] Popup

#### Overlay (오버레이)
- [ ] Dialog
- [ ] HoverCard
- [ ] Popover
- [ ] Tooltip
- [ ] Toast
- [ ] RefreshTrigger
- [ ] Swiper

## DaisyUI 클래스 참조

### Button
- Base: `btn`
- Variants: `btn-primary`, `btn-secondary`, `btn-accent`, `btn-neutral`
- Styles: `btn-outline`, `btn-ghost`, `btn-link`, `btn-dash`, `btn-soft`
- Sizes: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`
- Modifiers: `btn-wide`, `btn-block`, `btn-square`, `btn-circle`
- States: `btn-active`, `btn-disabled`

### Input
- Base: `input`
- Variants: `input-primary`, `input-secondary`, `input-accent`
- Styles: `input-bordered`, `input-ghost`
- Sizes: `input-xs`, `input-sm`, `input-md`, `input-lg`

### Avatar
- Base: `avatar`
- Modifiers: `avatar-online`, `avatar-offline`, `avatar-placeholder`
- Group: `avatar-group`

### Card
- Base: `card`
- Variants: `card-bordered`, `card-compact`, `card-side`, `card-normal`
- Children: `card-body`, `card-title`, `card-actions`

## 개발 워크플로우

### 1단계: 템플릿 구현 (현재)
- Control: Button
- Form: Input, Checkbox
- Display: Avatar, Badge
- Layout: Card, Dialog

### 2단계: 패턴 확립 (1-2주)
- 템플릿 검증 및 개선
- 구현 가이드 업데이트
- 자동화 스크립트 개발

### 3단계: 대량 구현 (1-2개월)
- 카테고리별 순차 구현
- 테스트 커버리지 확보
- 예제 및 문서 작성

### 4단계: 검증 및 최적화 (1개월)
- 성능 최적화
- 크로스 브라우저 테스트
- 접근성 검증

## 제약 사항 및 차이점

### Flutter에서만 가능한 것
- State 관리 (StatefulWidget)
- Hot reload
- 네이티브 플랫폼 기능

### Web에서만 가능한 것
- HTML/CSS 직접 제어
- DOM API 접근
- 브라우저 전용 기능

### API 차이가 필요한 경우
- Animation: Flutter는 AnimationController, Web은 CSS transitions
- Focus: Flutter는 FocusNode, Web은 DOM focus/blur
- Layout: Flutter는 RenderObject, Web은 CSS flexbox/grid

이런 경우 최대한 비슷한 API를 제공하되, 플랫폼 특성을 살리는 방향으로 구현

## 참고 자료
- DaisyUI 문서: https://daisyui.com/components/
- Jaspr 문서: https://docs.page/schultek/jaspr
- coui_flutter 소스: packages/coui_flutter/lib/src/components/