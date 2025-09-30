# CoUI Web Phase 1 구현 계획

## 작업 시작일
2025-09-30

## 목표
coui_flutter의 핵심 컴포넌트를 coui_web에 구현 (우선순위 기반)

## Phase 1 대상 컴포넌트 (14개)

### 📊 우선순위 분류

#### 🔴 최우선 (High Priority) - 8개
가장 자주 사용되는 필수 컴포넌트

**Overlay 카테고리 (4개)**:
1. **Dialog** - 모달 다이얼로그 (필수)
2. **Drawer** - 사이드 드로어/패널 (필수)
3. **Toast** - 알림 메시지 (필수)
4. **Tooltip** - 툴팁/힌트 (필수)

**Navigation 카테고리 (3개)**:
5. **Tabs** - 탭 내비게이션 (필수)
6. **Pagination** - 페이지네이션 (필수)
7. **NavigationBar** - 내비게이션 바 (필수)

**Menu 카테고리 (1개)**:
8. **DropdownMenu** - 드롭다운 메뉴 (필수)

#### 🟡 중간 우선순위 (Medium Priority) - 6개
자주 사용되는 유용한 컴포넌트

**Menu 카테고리 (1개)**:
9. **ContextMenu** - 컨텍스트 메뉴

**Layout 카테고리 (2개)**:
10. **Accordion** - 아코디언
11. **Breadcrumb** - 브레드크럼

**Form 카테고리 (2개)**:
12. **DatePicker** - 날짜 선택기
13. **Slider** - 슬라이더

**Overlay 카테고리 (1개)**:
14. **Popover** - 팝오버

---

## 구현 전략

### 1. DaisyUI 기반 구현
- DaisyUI 컴포넌트 클래스 활용
- DaisyUI 테마 시스템 통합
- 접근성 (ARIA) 표준 준수

### 2. Flutter API 호환성
- 모든 이벤트 핸들러를 Flutter 스타일로 정렬
- `void Function()?` 타입 사용
- `ValueChanged<T>?` 타입 사용
- 내부적으로만 Web 이벤트로 변환

### 3. 컴포넌트 구조
```dart
// 표준 구조
class ComponentName extends UiComponent {
  // Flutter 호환 생성자
  const ComponentName({
    required this.children,
    this.onAction, // void Function()?
    // ... other properties
  });

  // Flutter 스타일 이벤트 핸들러
  final void Function()? onAction;

  // 내부 변환 (Web 이벤트로)
  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }
}
```

### 4. 스타일 시스템
```dart
// 스타일 클래스 정의
class ComponentNameStyle extends ComponentStyling {
  const ComponentNameStyle(super.cssClass, {required super.type});
}

// 타입별 스타일
abstract class ComponentNameStyling implements ComponentStyling {}
```

---

## 카테고리별 구현 계획

### 📁 Overlay 카테고리 (5개)

#### 1. Dialog
**파일 위치**: `packages/coui_web/lib/src/components/overlay/dialog/`
- `dialog.dart` - 메인 컴포넌트
- `dialog_style.dart` - 스타일 정의

**주요 기능**:
- 모달/비모달 다이얼로그
- 배경 클릭 닫기
- ESC 키 닫기
- 애니메이션 지원
- `onClose: void Function()? `

**DaisyUI 클래스**: `dialog`, `dialog-open`, `modal`

**API**:
```dart
Dialog(
  children: [...],
  onClose: () => print('Dialog closed'),
  modal: true,
  style: [Dialog.open],
)
```

#### 2. Drawer
**파일 위치**: `packages/coui_web/lib/src/components/overlay/drawer/`
- `drawer.dart`
- `drawer_style.dart`

**주요 기능**:
- 좌/우/상/하 방향 지원
- 오버레이/푸시 모드
- 스와이프 제스처
- `onClose: void Function()?`

**DaisyUI 클래스**: `drawer`, `drawer-open`, `drawer-side`, `drawer-content`

**API**:
```dart
Drawer(
  children: [...],
  position: DrawerPosition.left,
  onClose: () => print('Drawer closed'),
  style: [Drawer.open],
)
```

#### 3. Toast
**파일 위치**: `packages/coui_web/lib/src/components/overlay/toast/`
- `toast.dart`
- `toast_style.dart`

**주요 기능**:
- 알림 메시지 표시
- 자동 닫기 (duration)
- 위치 지정 (top, bottom, center)
- 타입별 스타일 (success, error, warning, info)

**DaisyUI 클래스**: `toast`, `alert`

**API**:
```dart
Toast(
  child: Text('Success!'),
  duration: Duration(seconds: 3),
  position: ToastPosition.top,
  style: [Toast.success],
)
```

#### 4. Tooltip
**파일 위치**: `packages/coui_web/lib/src/components/overlay/tooltip/`
- `tooltip.dart`
- `tooltip_style.dart`

**주요 기능**:
- 호버시 툴팁 표시
- 위치 지정 (top, bottom, left, right)
- 딜레이 설정

**DaisyUI 클래스**: `tooltip`, `tooltip-open`, `tooltip-top`, `tooltip-bottom`, `tooltip-left`, `tooltip-right`

**API**:
```dart
Tooltip(
  message: 'Helpful hint',
  position: TooltipPosition.top,
  child: Button(...),
)
```

#### 5. Popover
**파일 위치**: `packages/coui_web/lib/src/components/overlay/popover/`
- `popover.dart`
- `popover_style.dart`

**주요 기능**:
- 클릭시 팝업 표시
- 위치 지정
- 외부 클릭 닫기
- `onClose: void Function()?`

**DaisyUI 클래스**: `popover`, `popover-open`

**API**:
```dart
Popover(
  content: [...],
  position: PopoverPosition.bottom,
  onClose: () => print('Popover closed'),
  child: Button(...),
)
```

---

### 📁 Navigation 카테고리 (3개)

#### 6. Tabs
**파일 위치**: `packages/coui_web/lib/src/components/navigation/tabs/`
- `tabs.dart`
- `tab_list.dart`
- `tab_pane.dart`
- `tab_container.dart`
- `tabs_style.dart`

**주요 기능**:
- 탭 전환
- 활성 탭 표시
- `onTabChange: void Function(int)?`

**DaisyUI 클래스**: `tabs`, `tab`, `tab-active`, `tab-lifted`, `tab-bordered`

**API**:
```dart
Tabs(
  [
    Tab(label: 'Tab 1', content: [...]),
    Tab(label: 'Tab 2', content: [...]),
  ],
  selectedIndex: 0,
  onTabChange: (index) => print('Tab $index selected'),
  style: [Tabs.lifted],
)
```

#### 7. Pagination
**파일 위치**: `packages/coui_web/lib/src/components/navigation/pagination/`
- `pagination.dart`
- `pagination_style.dart`

**주요 기능**:
- 페이지 번호 표시
- 이전/다음 버튼
- `onPageChange: void Function(int)?`

**DaisyUI 클래스**: `join`, `btn`, `btn-active` (조합)

**API**:
```dart
Pagination(
  totalPages: 10,
  currentPage: 1,
  onPageChange: (page) => print('Page $page'),
  style: [Pagination.bordered],
)
```

#### 8. NavigationBar
**파일 위치**: `packages/coui_web/lib/src/components/navigation/navigation_bar/`
- `navigation_bar.dart`
- `navigation_bar_style.dart`

**주요 기능**:
- 하단 내비게이션 바
- 아이템 선택
- `onItemSelect: void Function(int)?`

**DaisyUI 클래스**: `btm-nav`, `active`

**API**:
```dart
NavigationBar(
  items: [
    NavigationBarItem(icon: Icon('home'), label: 'Home'),
    NavigationBarItem(icon: Icon('settings'), label: 'Settings'),
  ],
  selectedIndex: 0,
  onItemSelect: (index) => print('Item $index selected'),
)
```

---

### 📁 Menu 카테고리 (2개)

#### 9. DropdownMenu
**파일 위치**: `packages/coui_web/lib/src/components/menu/dropdown_menu/`
- `dropdown_menu.dart`
- `dropdown_menu_style.dart`

**주요 기능**:
- 드롭다운 메뉴 표시
- 메뉴 아이템 선택
- `onItemSelect: void Function(String)?`

**DaisyUI 클래스**: `dropdown`, `dropdown-open`, `dropdown-content`, `menu`

**API**:
```dart
DropdownMenu(
  items: [
    MenuItem(label: 'Item 1', value: '1'),
    MenuItem(label: 'Item 2', value: '2'),
  ],
  onItemSelect: (value) => print('Selected: $value'),
  child: Button(...),
)
```

#### 10. ContextMenu
**파일 위치**: `packages/coui_web/lib/src/components/menu/context_menu/`
- `context_menu.dart`
- `context_menu_style.dart`

**주요 기능**:
- 우클릭 메뉴
- 메뉴 아이템 선택
- `onItemSelect: void Function(String)?`

**DaisyUI 클래스**: `menu`, `menu-compact`

**API**:
```dart
ContextMenu(
  items: [
    MenuItem(label: 'Copy', value: 'copy'),
    MenuItem(label: 'Paste', value: 'paste'),
  ],
  onItemSelect: (value) => print('Action: $value'),
  child: YourContent(...),
)
```

---

### 📁 Layout 카테고리 (2개)

#### 11. Accordion
**파일 위치**: `packages/coui_web/lib/src/components/layout/accordion/`
- `accordion.dart`
- `accordion_style.dart`

**주요 기능**:
- 접기/펼치기
- 다중 항목 동시 펼침 지원
- `onExpand: void Function(int)?`

**DaisyUI 클래스**: `collapse`, `collapse-open`, `collapse-title`, `collapse-content`

**API**:
```dart
Accordion(
  items: [
    AccordionItem(title: 'Item 1', content: [...]),
    AccordionItem(title: 'Item 2', content: [...]),
  ],
  expandedIndex: 0,
  onExpand: (index) => print('Expanded: $index'),
  style: [Accordion.bordered],
)
```

#### 12. Breadcrumb
**파일 위치**: `packages/coui_web/lib/src/components/layout/breadcrumb/`
- `breadcrumb.dart`
- `breadcrumb_style.dart`

**주요 기능**:
- 경로 표시
- 항목 클릭
- `onItemClick: void Function(int)?`

**DaisyUI 클래스**: `breadcrumbs`

**API**:
```dart
Breadcrumb(
  items: [
    BreadcrumbItem(label: 'Home', href: '/'),
    BreadcrumbItem(label: 'Products', href: '/products'),
    BreadcrumbItem(label: 'Detail'),
  ],
  onItemClick: (index) => print('Clicked: $index'),
)
```

---

### 📁 Form 카테고리 (2개)

#### 13. DatePicker
**파일 위치**: `packages/coui_web/lib/src/components/form/date_picker/`
- `date_picker.dart`
- `date_picker_style.dart`

**주요 기능**:
- 날짜 선택
- 캘린더 표시
- `onDateChange: void Function(DateTime)?`

**DaisyUI 클래스**: `input`, `dropdown` (조합으로 커스텀 구현)

**API**:
```dart
DatePicker(
  value: DateTime.now(),
  onDateChange: (date) => print('Selected: $date'),
  minDate: DateTime(2020),
  maxDate: DateTime(2030),
)
```

#### 14. Slider
**파일 위치**: `packages/coui_web/lib/src/components/form/slider/`
- `slider.dart`
- `slider_style.dart`

**주요 기능**:
- 값 슬라이더
- 범위 슬라이더
- `onChanged: void Function(double)?`

**DaisyUI 클래스**: `range`

**API**:
```dart
Slider(
  value: 50,
  min: 0,
  max: 100,
  onChanged: (value) => print('Value: $value'),
  style: [Slider.primary],
)
```

---

## 구현 순서

### Week 1-2: Overlay 컴포넌트 (5개)
1. Dialog (1-2일)
2. Drawer (1-2일)
3. Toast (1일)
4. Tooltip (1일)
5. Popover (1일)

### Week 3: Navigation 컴포넌트 (3개)
6. Tabs (2일)
7. Pagination (1일)
8. NavigationBar (1일)

### Week 4: Menu + Layout + Form (6개)
9. DropdownMenu (1일)
10. ContextMenu (1일)
11. Accordion (1일)
12. Breadcrumb (1일)
13. DatePicker (2일)
14. Slider (1일)

---

## 품질 기준

### ✅ 필수 체크리스트
각 컴포넌트마다 다음을 확인:

1. **API 호환성**
   - [ ] Flutter 스타일 이벤트 핸들러 사용
   - [ ] 내부 Web 이벤트 변환 구현
   - [ ] 타입 안정성 확보

2. **DaisyUI 통합**
   - [ ] DaisyUI 클래스 정확히 적용
   - [ ] 스타일 modifier 지원
   - [ ] 테마 시스템 통합

3. **접근성 (A11y)**
   - [ ] ARIA 속성 올바르게 설정
   - [ ] 키보드 내비게이션 지원
   - [ ] 스크린 리더 호환성

4. **코드 품질**
   - [ ] `dart analyze` 통과
   - [ ] 문서화 주석 작성
   - [ ] copyWith 메서드 구현

5. **테스트**
   - [ ] 기본 동작 검증
   - [ ] 이벤트 핸들러 동작 확인
   - [ ] 스타일 적용 확인

---

## Export 업데이트

각 컴포넌트 구현 후 `coui_web.dart`에 export 추가:

```dart
// --- OVERLAY ---
export 'src/components/overlay/dialog/dialog.dart';
export 'src/components/overlay/dialog/dialog_style.dart' show DialogStyling;
export 'src/components/overlay/drawer/drawer.dart';
export 'src/components/overlay/drawer/drawer_style.dart' show DrawerStyling;
// ... etc

// --- NAVIGATION ---
export 'src/components/navigation/tabs/tabs.dart';
export 'src/components/navigation/tabs/tabs_style.dart' show TabsStyling;
// ... etc

// --- MENU ---
export 'src/components/menu/dropdown_menu/dropdown_menu.dart';
export 'src/components/menu/dropdown_menu/dropdown_menu_style.dart' show DropdownMenuStyling;
// ... etc

// --- LAYOUT (additional) ---
export 'src/components/layout/accordion/accordion.dart';
export 'src/components/layout/accordion/accordion_style.dart' show AccordionStyling;
// ... etc

// --- FORM (additional) ---
export 'src/components/form/date_picker/date_picker.dart';
export 'src/components/form/date_picker/date_picker_style.dart' show DatePickerStyling;
// ... etc
```

---

## 성공 지표

### Phase 1 완료 기준
- ✅ 14개 컴포넌트 모두 구현 완료
- ✅ 모든 컴포넌트 `dart analyze` 통과
- ✅ Flutter API 호환성 100%
- ✅ DaisyUI 스타일 정확히 적용
- ✅ 접근성 기준 충족
- ✅ 문서화 완료

### 다음 단계 (Phase 2)
Phase 1 완료 후 중/저우선순위 컴포넌트 구현:
- Popover, HoverCard (Overlay)
- Menu, Menubar, Popup (Menu)
- Collapsible, Stepper, Steps, Table, Timeline, Tree (Layout)
- TimePicker, Autocomplete, ChipInput, StarRating, PhoneInput, InputOtp, ColorPicker (Form)
- Calendar, Carousel, CodeSnippet, KeyboardShortcut, NumberTicker (Display)

---

## 참고 문서

- [API 통합 완료 요약](./api_unified_summary.md)
- [폴더 구조 재구성 완료](./folder_restructure_complete.md)
- [네이밍 통일 완료](./naming_unification_complete.md)
- [CoUI Web 컴포넌트 API 분석](./coui_web_components_api_analysis.md)