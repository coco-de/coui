# CoUI Web/Flutter API Sync Report

## Overview

coui_flutter와 coui_web의 컴포넌트 API 동기화 검증 결과입니다.

- **검증일**: 2026-02-11
- **대상**: coui_flutter vs coui_web barrel files
- **검증 범위**: 클래스명, 카테고리, 생성자 파라미터 패턴

## Class Name Sync Rate

| Category | Shared | Exact Match | Name Mismatch | Sync Rate |
|----------|--------|-------------|---------------|-----------|
| Control | 2 | 2 | 0 | 100% |
| Form | 12 | 11 | 1 | 92% |
| Display | 18 | 16 | 2 | 89% |
| Layout | 9 | 9 | 0 | 100% |
| Menu | 3 | 3 | 0 | 100% |
| Navigation | 3 | 3 | 0 | 100% |
| Overlay | 5 | 5 | 0 | 100% |
| Icon | 1 | 1 | 0 | 100% |
| **Total** | **53** | **50** | **3** | **94.3%** |

## Name Mismatches (3)

| Flutter | Web | Category | Notes |
|---------|-----|----------|-------|
| `CodeSnippet` | `CodeBlock` | Display | CoUI naming convention |
| `StarRating` | `Rating` | Form/Display | Web: display category, CoUI naming |
| `TextArea` | `Textarea` | Form | HTML standard casing |

## Category Differences (3)

| Component | Flutter Category | Web Category |
|-----------|-----------------|--------------|
| HoverCard | overlay | display |
| Breadcrumb | navigation | layout |
| Rating/StarRating | form | display |

## Platform-Specific Components

### Flutter Only (not portable to web)

Interactive/stateful components requiring Flutter framework:

| Category | Components |
|----------|-----------|
| Control | Clickable, Hover, ScrollViewInterceptor, Scrollbar |
| Form | AutoComplete, ChipInput, ColorPicker, InputOTP, ItemPicker, MultiAnswerCard, MultipleChoice, ObjectInput, PhoneInput, TimePicker |
| Display | CircularProgressIndicator, FadeScroll, KeyboardShortcut, LinearProgressIndicator, NumberTicker, ValidationBadge |
| Layout | Basic, CardImage, FocusOutline, MediaQuery, OutlinedContainer, OverflowMarquee, ScrollableClient, StageContainer |
| Menu | Popup |
| Navigation | Subfocus |
| Overlay | RefreshTrigger, Swiper |

### Web Only (CoUI/HTML-specific)

CSS/HTML components not applicable to Flutter:

| Category | Components |
|----------|-----------|
| Control | ThemeController |
| Form | Datalist, Fieldset, FileInput, Range, SwitchField |
| Display | AspectRatio, Command, Countdown, Diff, HoverGallery, Indicator, Kbd, Label, MockupBrowser, MockupCode, MockupPhone, MockupWindow, RadialProgress, ScrollArea, Stat, Status |
| Layout | Container, Dock, Footer, Grid, Hero, Join, List, Mask, Separator, Stack, Swap |
| Overlay | Filter |
| Text | Link |

## Constructor Parameter Pattern

Due to different frameworks, constructor parameters differ by design:
- **Flutter**: StatefulWidget params (focusNode, controller, animation, etc.)
- **Web**: UiComponent params (classes, css, attributes, tag, style, etc.)

Component-specific params follow platform-appropriate patterns:
- **Button**: Flutter has extensive gesture callbacks; Web uses variant/size/shape enums
- **Checkbox**: Flutter uses state enum; Web uses boolean checked
- **Card**: Flutter has styling params; Web uses CoUI variant system
- **Tabs**: Flutter uses index+onChanged; Web uses defaultValue

## Conclusion

- **Class name sync rate: 94.3%** (exceeds 90% target)
- Name mismatches are intentional (CoUI naming vs Flutter conventions)
- Constructor parameter differences are by design due to different frameworks
- Both packages cover the same conceptual component set for their respective platforms
