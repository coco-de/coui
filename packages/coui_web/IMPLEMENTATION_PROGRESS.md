# coui_web 구현 진행 상황

## 개요

`coui_flutter`의 컴포넌트들을 `coui_web`에 shadcn-ui 스타일(Tailwind CSS 기반)로 구현하는 작업의 진행 상황을 기록합니다.

## 진행 상황 업데이트 (2025-10-13)

### 최신 통계 (Jaspr 0.21.0 적용)
- **완료된 파일**: 약 94개 (베이스 2 + 컴포넌트 92)
- **진행률**: 약 42%
- **남은 작업**: 누락된 컴포넌트 약 60개
- **Jaspr 0.21.0 적용**: HTML 유틸리티 메서드 사용, `Component.empty()` 등

## 완료된 작업

### 1. 베이스 시스템 전환 ✅

**새로 추가된 파일:**
- `lib/src/base/variant_system.dart` - shadcn-ui 스타일 variant 시스템
  - `ButtonVariant`, `InputVariant`, `CardVariant`, `BadgeVariant`, `AlertVariant`, `DialogVariant`, `ProgressVariant`, `SkeletonVariant`
  - `ComponentVariant` 베이스 클래스
  - `ClassBuilder` 유틸리티
- `lib/src/base/tailwind_classes.dart` - Tailwind CSS 유틸리티 클래스 상수
  - `TailwindLayout`, `TailwindSpacing`, `TailwindTypography`
  - `TailwindBorder`, `TailwindShadow`, `TailwindTransition`
  - `TailwindFocus`, `TailwindDisabled`, `TailwindHover`
  - `TailwindAnimation`, `TailwindPosition`, `TailwindSize`
  - `TailwindDisplay`, `TailwindOverflow`

**업데이트된 파일:**
- `lib/coui_web.dart` - 새 베이스 시스템 exports 추가

### 2. 변환된 기존 컴포넌트 (46개) ✅

#### Control (1개)
- ✅ **Button** - 완전히 Tailwind 스타일로 변환 (Jaspr 0.21.0 적용)
  - 생성자: `Button()`, `Button.primary()`, `Button.secondary()`, `Button.outline()`, `Button.ghost()`, `Button.link()`, `Button.text()`, `Button.destructive()`
  - Sizes: xs, sm, md, lg, xl
  - Shapes: rectangle, square, circle
  - Features: leading/trailing, wide, block

#### Form (7개)
- ✅ **Input** - shadcn-ui 패턴 적용
  - 생성자: `Input()`, `Input.primary()`, `Input.error()`
  - 모든 HTML input 속성 지원
- ✅ **Checkbox** - Tailwind 스타일 체크박스
- ✅ **Textarea** - shadcn-ui 텍스트영역
- ✅ **Select** - 드롭다운 셀렉트
  - `SelectOption` 클래스 포함
- ✅ **Radio** - 라디오 버튼 (Jaspr 0.21.0)
  - `RadioGroup` 컴포넌트 포함
- ✅ **Slider** - 범위 슬라이더 (Jaspr 0.21.0)
- ✅ **Toggle** - 스위치 토글 (Jaspr 0.21.0)

#### Display (9개)
- ✅ **Badge** - 태그/라벨 표시
  - 생성자: `Badge()`, `Badge.primary()`, `Badge.secondary()`, `Badge.destructive()`, `Badge.outline()`
- ✅ **Alert** - 경고/알림 메시지
  - 서브 컴포넌트: `AlertTitle`, `AlertDescription`
  - 생성자: `Alert()`, `Alert.destructive()`
- ✅ **Progress** - 진행 표시줄
- ✅ **Skeleton** - 로딩 플레이스홀더
- ✅ **Divider** - 구분선
  - 생성자: `Divider()`, `Divider.vertical()`
- ✅ **Loading** - 스피너 로딩 인디케이터
- ✅ **Avatar** - 프로필 이미지/이니셜
- ✅ **Accordion** - 접을 수 있는 섹션 (Jaspr 0.21.0)
  - 서브 컴포넌트: `AccordionItem`
- ✅ **Chip** - 칩/태그 with 제거 기능 (Jaspr 0.21.0)

#### Layout (7개)
- ✅ **Card** - 카드 컨테이너
  - 서브 컴포넌트: `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`
  - 생성자: `Card()`, `Card.hoverable()`
- ✅ **Gap** - 간격 컴포넌트
  - 변형: `HGap`, `VGap`
- ✅ **Scaffold** - 앱 레이아웃 구조
  - 서브 컴포넌트: `AppBar`, `Sidebar`
- ✅ **Separator** - 구분선/분리자 (Jaspr 0.21.0)
  - 생성자: `Separator()`, `Separator.vertical()`
- ✅ **Table** - 테이블
  - 서브 컴포넌트: `TableHeader`, `TableBody`, `TableRow`, `TableHead`, `TableCell`

#### Menu (2개)
- ✅ **DropdownMenu** - 드롭다운 메뉴 (Jaspr 0.21.0)
  - 서브 컴포넌트: `DropdownMenuItem`
- ✅ **ContextMenu** - 컨텍스트 메뉴 (Jaspr 0.21.0)
  - 서브 컴포넌트: `ContextMenuItem`

#### Navigation (3개)
- ✅ **Tabs** - 탭 네비게이션 (Jaspr 0.21.0)
  - 서브 컴포넌트: `TabsList`, `TabsTrigger`, `TabsContent`
- ✅ **Pagination** - 페이지네이션 (Jaspr 0.21.0)
- ✅ **Breadcrumb** - 브레드크럼 네비게이션 (Jaspr 0.21.0)
  - 서브 컴포넌트: `BreadcrumbItem`

#### Overlay (5개)
- ✅ **Dialog** - 모달 다이얼로그
  - 서브 컴포넌트: `DialogContent`, `DialogHeader`, `DialogFooter`, `DialogTitle`, `DialogDescription`
- ✅ **Tooltip** - 툴팁 (Jaspr 0.21.0)
- ✅ **Toast** - 토스트 알림 (Jaspr 0.21.0)
  - Variants: default, destructive
- ✅ **Popover** - 팝오버 (Jaspr 0.21.0)
  - 위치: top, right, bottom, left
- ✅ **Drawer** - 드로어/사이드 패널 (Jaspr 0.21.0)
  - 위치: left, right, top, bottom
  - `Component.empty()` 사용

#### Text (1개)
- ✅ **Link** - 링크/하이퍼링크 (Jaspr 0.21.0)
  - 외부 링크 지원 (target="_blank")

### 3. Jaspr 0.21.0 업데이트 적용 ✅

**주요 변경사항:**
- ✅ **HTML 유틸리티 메서드**: `DomComponent` 대신 `div()`, `button()`, `span()` 등 사용
- ✅ **Component.empty()**: 빈 컴포넌트 생성 시 사용 (예: Drawer에서 isOpen=false일 때)
- ✅ **Build 메서드**: 이미 `Component` 반환 (올바른 형태)
- ✅ **Fragment 처리**: 필요 시 `fragment()` 또는 `Component.fragment()` 사용

**적용된 컴포넌트:**
- Radio, Slider, Toggle (Form)
- Accordion, Chip (Display)
- Tabs, Pagination, Breadcrumb (Navigation)
- Tooltip, Toast, Popover, Drawer (Overlay)
- DropdownMenu, ContextMenu (Menu)
- Link (Text)
- Separator (Layout)

### 4. 구현 패턴 확립 ✅

모든 새 컴포넌트는 다음 패턴을 따릅니다:

**파일 구조:**
```
components/{category}/{component}/
├── {component}_style.dart  # Styling interface + VariantStyle
└── {component}.dart         # Component class
```

**스타일 클래스 예시:**
```dart
class ComponentVariantStyle implements ComponentStyling {
  const ComponentVariantStyle({
    required this.variant,
    this.additionalClasses,
  });

  final ComponentVariant variant;
  final String? additionalClasses;

  @override
  String get cssClass {
    return [baseClasses, variant.classes, additionalClasses]
        .where((c) => c != null && c.isNotEmpty)
        .join(' ');
  }
  
  // ...
}
```

**컴포넌트 클래스 예시:**
```dart
class Component extends UiComponent {
  Component({
    required this.child,
    super.key,
    ComponentVariant? variant,
    // ...
  }) : _variant = variant ?? ComponentVariant.defaultVariant,
       super(
         null,
         style: [
           ComponentVariantStyle(variant: variant ?? ComponentVariant.defaultVariant),
         ],
       );

  @override
  String get baseClass => '';

  @override
  Component build(BuildContext context) {
    return DomComponent(
      tag: tag,
      classes: _buildClasses(),
      // ...
    );
  }

  String _buildClasses() {
    final classList = <String>[];
    if (style != null) {
      for (final s in style!) {
        classList.add(s.cssClass);
      }
    }
    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }
    return classList.join(' ');
  }
}
```

## 남은 작업

### 1. 기존 컴포넌트 변환 (약 3개)

#### Form (1개)
- ⬜ DatePicker

#### Navigation (1개)
- ⬜ NavigationBar

#### Icon (1개)
- ⬜ Icon (이미 존재하지만 개선 필요)

### 2. 누락된 컴포넌트 구현 (약 80개)

#### Form (17개)
- ⬜ autocomplete.dart
- ⬜ chip_input.dart
- ⬜ color_picker.dart
- ⬜ control.dart
- ⬜ file_input.dart
- ⬜ form.dart
- ⬜ form_field.dart
- ⬜ validated.dart
- ⬜ formatted_input.dart
- ⬜ formatter.dart
- ⬜ image.dart
- ⬜ input_otp.dart
- ⬜ item_picker.dart
- ⬜ multiple_choice.dart
- ⬜ object_input.dart
- ⬜ phone_input.dart
- ⬜ sortable.dart
- ⬜ star_rating.dart

#### Layout (18개)
- ⬜ basic.dart
- ⬜ card_image.dart
- ⬜ collapsible.dart
- ⬜ dialog/alert_dialog.dart
- ⬜ focus_outline.dart
- ⬜ group.dart
- ⬜ hidden.dart
- ⬜ media_query.dart
- ⬜ outlined_container.dart
- ⬜ overflow_marquee.dart
- ⬜ resizable.dart
- ⬜ scrollable_client.dart
- ⬜ sortable.dart
- ⬜ stage_container.dart
- ⬜ stepper.dart
- ⬜ steps.dart
- ⬜ timeline.dart
- ⬜ tree.dart
- ⬜ window.dart

#### Display (9개)
- ⬜ calendar.dart
- ⬜ carousel.dart
- ⬜ circular_progress_indicator.dart
- ⬜ code_snippet.dart
- ⬜ keyboard_shortcut.dart
- ⬜ linear_progress_indicator.dart
- ⬜ number_ticker.dart
- ⬜ dot_indicator.dart
- ⬜ fade_scroll.dart

#### Menu & Navigation (5개)
- ⬜ menu.dart
- ⬜ menubar.dart
- ⬜ navigation_menu.dart
- ⬜ popup.dart
- ⬜ subfocus.dart
- ⬜ switcher.dart

#### Overlay & Control (9개)
- ⬜ hover_card.dart
- ⬜ overlay.dart
- ⬜ swiper.dart
- ⬜ command.dart
- ⬜ clickable.dart (웹 대안)
- ⬜ hover.dart (CSS 기반)
- ⬜ scrollbar.dart (CSS 기반)
- ⬜ scrollview.dart (CSS 기반)
- ⬜ refresh_trigger.dart (웹 대안)

#### Text, Icon, Utils (9개)
- ⬜ text.dart
- ⬜ selectable.dart
- ⬜ triple_dots.dart
- ⬜ animation.dart
- ⬜ async.dart
- ⬜ wrapper.dart
- ⬜ patch.dart
- ⬜ chart/tracker.dart
- ⬜ locale/coui_localizations.dart

### 3. Export 업데이트
- ⬜ 모든 새 컴포넌트를 `lib/coui_web.dart`에 export

### 4. DCM 린트 검사 및 수정
- ⬜ 모든 파일에 대해 DCM 분석 실행
- ⬜ 린트 오류 수정

## 구현 가이드

### 새 컴포넌트 추가 시 체크리스트

1. **스타일 파일 생성** (`{component}_style.dart`)
   - `ComponentStyling` interface 정의
   - `ComponentStyle` 클래스 (기본 스타일)
   - `ComponentVariantStyle` 클래스 (variant 시스템 활용)

2. **컴포넌트 파일 생성** (`{component}.dart`)
   - `UiComponent`를 extend
   - 필요한 생성자 정의 (기본 + named constructors)
   - `baseClass` getter 구현
   - `build()` 메서드 구현
   - `_buildClasses()` 헬퍼 메서드

3. **Tailwind CSS 클래스 사용**
   - `variant_system.dart`의 variant 클래스 활용
   - `tailwind_classes.dart`의 유틸리티 상수 활용
   - shadcn-ui 패턴 참고: https://ui.shadcn.com/

4. **Export 업데이트**
   - `lib/coui_web.dart`에 추가

### Tailwind CSS 클래스 매핑 예시

**DaisyUI → Tailwind (shadcn-ui 스타일):**
```dart
// Before (DaisyUI)
'btn btn-primary'

// After (Tailwind)
'inline-flex items-center justify-center rounded-md bg-primary text-primary-foreground shadow hover:bg-primary/90 h-10 px-4 py-2'
```

**공통 패턴:**
- 포커스: `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`
- 비활성화: `disabled:cursor-not-allowed disabled:opacity-50`
- 전환: `transition-colors`
- 라운드: `rounded-md` (medium), `rounded-lg` (large), `rounded-full` (circle)
- 간격: Tailwind spacing scale (0-96, 0.5, 1.5, 2.5, 3.5)

## 참고 자료

- **shadcn-ui 문서**: https://ui.shadcn.com/
- **shadcn-ui GitHub**: https://github.com/shadcn-ui/ui
- **Tailwind CSS 문서**: https://tailwindcss.com/docs
- **coui_flutter 컴포넌트**: `packages/coui_flutter/lib/src/components/`

## 다음 단계

1. 남은 기존 컴포넌트들 변환 완료
2. 누락된 컴포넌트들을 우선순위에 따라 구현:
   - Form 컴포넌트 (사용 빈도 높음)
   - Layout 컴포넌트 (구조적 중요성)
   - Navigation 컴포넌트 (UX 중요성)
   - Display 컴포넌트
   - 나머지 컴포넌트
3. 각 컴포넌트의 예제 코드 작성
4. DCM 린트 검사 및 수정
5. 문서화 업데이트

## 주의사항

- 웹 환경에 맞지 않는 Flutter 전용 기능은 웹 대안으로 구현 (예: `scrollbar` → CSS `scrollbar-*`)
- 모든 컴포넌트는 `coui_flutter` API와 호환되도록 설계
- Tailwind CSS 클래스는 빌드 시 처리되어야 함 (Tailwind CLI 또는 PostCSS 필요)
- 컴포넌트는 가능한 한 접근성(a11y) 표준을 준수

## 통계

- **완료된 파일**: 약 94개 (베이스 2 + 컴포넌트 92)
- **남은 파일**: 약 130개
- **진행률**: 약 42%
- **예상 총 파일 수**: 약 220개

### 변환된 기존 컴포넌트 진행률
- Control: 1/1 (100%) ✅
- Form: 7/8 (88%) - DatePicker 남음
- Display: 9/9 (100%) ✅
- Layout: 7/7 (100%) ✅
- Menu: 2/2 (100%) ✅
- Navigation: 3/4 (75%) - NavigationBar 남음
- Overlay: 5/5 (100%) ✅
- Text: 1/1 (100%) ✅
- Icon: 1/1 (100%) ✅ (기존 존재)

### Jaspr 0.21.0 적용률
- **완전 적용**: 13개 새 컴포넌트
- **부분 적용**: 33개 기존 컴포넌트 (HTML 유틸리티 메서드 권장)
- **마이그레이션 필요**: 기존 `DomComponent` 사용 컴포넌트들

