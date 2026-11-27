# CoUI 컴포넌트의 반복 패턴과 체인 적용 범위

## 적용 결과

아래 실측과 후보 목록은 변경 전 API를 기록한다. Flutter와 Web에서는 이제 Button·Alert·Banner의 종류, Badge·Progress의 톤, Chip의 선택 색, TextField·TextArea의 오류 모양을 체인으로 선택한다. Badge·Card·Chip·DescriptionCard·Fieldset·Stat의 `.outline`은 `variant: .outlined`를 고른다. 12개 컴포넌트에서 총 25개 getter가 바뀌었다. 기존 색만 고정하려면 `.backgroundColor(.primary)`나 선형 Progress의 `.fillColor(.primary)`를 사용한다. 기존 스타일 생성자도 `const CoreCardStyle(backgroundColor: .primary)`로 쓸 수 있다. 배경색 메서드는 공통 컴포넌트 56종과 Flutter의 ControlledStarRating에 적용했다. Frame은 기존 `backgroundColor` 인자로 같은 토큰을 받는다. [Button 사용법](../docs_core/content/components/button.md) · [Badge 사용법](../docs_core/content/components/badge.md)

SwiftUI는 `.foregroundStyle(.primary)`처럼 속성과 값을 함께 읽게 한다. 여기서 `.primary`는 전경의 강조 단계다. Compose Material 3는 `ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)`로 버튼 컨테이너의 색 역할을 지정한다. CoUI는 Dart가 인자 타입으로 정적 멤버를 찾는 표기를 사용한다. `button.primary.backgroundColor(.secondary)`에서 앞의 getter는 버튼 variant를, 괄호 안의 값은 `CoreColor.secondary`를 선택한다. [SwiftUI foregroundStyle](https://developer.apple.com/documentation/swiftui/view/foregroundstyle%28_%3A%29) · [Compose ButtonDefaults](https://developer.android.com/reference/kotlin/androidx/compose/material3/ButtonDefaults) · [Dart dot shorthands](https://dart.dev/language/dot-shorthands)

## 검토 범위

[체인 실측표](chain-axis-table.md)의 대표 컴포넌트 157개를 기준으로 Flutter와 Web의 기본 생성자, 양쪽 `withStyle`이 받는 Core 스타일 타입, 그 타입의 생성자 필드를 Dart 구문 트리로 대조했다. 기존 체인 집계에서 빠진 디렉터리 22개는 마지막에 따로 다룬다. 보조 컴포넌트와 이름 있는 생성자는 157개 집계에 포함하지 않았다.

사용 사례는 플랫폼별로 일반 문서 예제 417개 파일을 살폈다. `docs_core/lib/previews/examples/{flutter,web}`의 `*_example.dart` 중 `*_chain_example.dart`는 제외했다. 예제 안에서 컴포넌트나 Core 스타일 이름으로 직접 호출하고 이름 있는 인자를 전달한 파일 수를 센 값이다. 같은 파일에서 여러 번 사용해도 한 번으로 센다. 두 플랫폼에 대응하는 예제가 많아 수치도 각각 표시한다. 간접 호출과 소비 앱에서의 사용량은 측정 범위 밖이다.

## 먼저 적용할 작성 규칙

| 반복 패턴 | 대표 컴포넌트에서 확인한 범위 | 적용 판단 |
|---|---:|---|
| 생성자의 종류와 크기 | `variant` 39개, `size` 35개. 공통 `CoreComponentSize`를 받는 곳은 15개 | 타입이 enum인 자리에서 `variant: .secondary`, `size: .sm`처럼 이름 있는 인자와 해당 타입의 값을 함께 쓴다. 각 컴포넌트가 허용하는 값은 IDE가 제시할 수 있다. |
| 상태와 값 변경 | `enabled` 51개(양쪽 모두 bool 30개, bool? 21개), `value`와 `onChanged` 동시 제공 16개 | 생성자에 값과 변경 콜백을 인접하게 둔다. Checkbox처럼 값 이름이 `checked`인 곳은 그 도메인 용어를 쓴다. nullable `enabled`는 컴포넌트의 기존 기본 동작을 따른다. |
| 자식 슬롯 | `leading`과 `trailing` 동시 제공 16개 | 어느 위치에 어떤 위젯이 들어가는지 이름 있는 인자로 드러낸다. 아이콘과 텍스트는 각 자식에서 스타일링하고 상태별 기본색은 부모 슬롯에서 받는다. |
| 반경 | 대표 타입 48개에 두 플랫폼 공통 radius getter. 최상위 `borderRadius` 필드를 가진 곳은 58개 | 기존 getter를 재사용한다. 46개는 필드와 getter가 모두 있고 12개는 필드만 있다. CardImage는 frame, HoverCard는 panel의 반경으로 연결되므로 새 컴포넌트는 어떤 면의 반경인지 먼저 확인한다. |
| 안쪽 여백 | 49개에 동일한 `CoreEdgeInsets? padding` 필드 | 일반 예제에서 가장 자주 직접 지정한 대표 스타일 필드 중 하나. Card에서 안쪽 여백 하나를 바꾸는 구문을 먼저 비교한다. 기존 Flutter `Widget.withPadding`은 바깥에서 위젯을 감싸므로 별개의 동작이다. |
| 색과 테두리 | `backgroundColor` 55개, `borderWidth`와 `borderColor`를 모두 제공하는 곳 40개 | 슬롯 필드명이 읽히게 둔다. 기존 `.primary`는 Button에서는 배경, Progress에서는 진행 막대, CodeSnippet에서는 배경과 코드 글자색을 함께 바꾼다. 같은 토큰을 쓴다는 사실만으로 공통 단축어를 확대하기 어렵다. |
| 텍스트·간격 등 하위 슬롯 | `CoreTextStyle?` 슬롯 109개 컴포넌트, `CoreGapStyle?` 슬롯 66개 컴포넌트. 간격 슬롯은 총 115개이고 30개 컴포넌트에는 둘 이상 | `headerBodyGapStyle`, `bodyFooterGapStyle`처럼 두 요소가 드러나는 이름을 유지한다. 부모에서 통째로 스타일을 지정할 때와 자식 Text의 일부 속성만 바꿀 때를 구분한다. |

### 변경 전 검토 — Button의 variant 체인 제안

`Button(...).primary`를 `Button(variant: .primary, ...)`와 같은 뜻으로 정의하는 방안을 권한다. Flutter와 Web 모두 기존 `copyWith(variant: .primary)`를 사용하면 같은 테마와 상태별 스타일 계산을 거친다. 기본 버튼은 이미 primary이므로 생략할 수 있다. 같은 원칙을 적용하면 `.secondary`와 `.outline`도 해당 버튼 variant를 고른다.

변경 전 이 세 getter는 배경색을 지정한다. 예를 들어 `Button(variant: .outline, ...).primary`는 이전에는 outline에 primary 배경을 덮지만, 제안대로 바꾸면 primary 버튼을 선택한다. 전환 시 색을 의도한 호출은 `buttonStyle.backgroundColor`에 해당하는 스타일 패치로 옮기고, 색을 바꾸는 문서 예제와 미리보기도 함께 갱신해야 한다. 생성자와 체인 중 한 곳에서만 variant를 지정하면 호출부의 의도가 분명하다.

### 버튼과 같은 이름 충돌이 있는 컴포넌트

Flutter의 `*StyleChain` 대상 168개와 Web의 166개를 조사했다. 대상 타입의 기본 생성자가 직접 받는 Core 또는 플랫폼 enum의 멤버 이름과 해당 타입의 체인 getter 이름을 대조했다. 양쪽 모두 9개 컴포넌트에서 20개 조합이 일치했고 각 getter의 구현도 양쪽이 같았다. 그중 `TabPane.editorStrip`은 이미 `copyWith(variant: ...)`를 사용한다. 나머지 8개 컴포넌트의 19개 getter는 색 필드 하나를 바꾼다. 아래는 Button을 제외한 7개 컴포넌트의 16개 getter다. [기존 variant 체인 구현](../packages/coui_flutter/lib/src/components/navigation/tabs/tab_pane.dart)

| 컴포넌트 | 겹치는 getter | 변경 전 바꾸던 값 | 의미에 맞게 쓸 생성자 옵션 |
|---|---|---|---|
| Alert, Banner | 각각 `.info`, `.success`, `.warning` | 배경색 | `variant`. 제목·본문 등의 색과 프로젝트의 variant별 테마까지 해당 조합으로 해석한다. |
| Badge | `.primary`, `.info`, `.success`, `.warning` | 배경색 | `tone`. 의미는 tone으로, 채움·윤곽 등 표현 강도는 variant로 조합한다. |
| Progress | `.primary`, `.success`, `.warning` | 진행 막대의 채움색 | 선형 Progress의 `tone`. 테마의 tone별 스타일도 함께 선택한다. |
| Chip | `.primary` | 배경색 | `chipColor`. 선택 시 쓸 색을 나타내므로 선택 전후를 모두 비교해야 한다. |
| TextField, TextArea | 각각 `.error` | 배경색 | `variant: .error`는 시각 옵션이다. 실제 입력 오류는 오류 메시지와 폼 검증 경로로 전달한다. |

**첫 적용 후보는 Alert·Banner의 variant와 Badge의 tone이다.** 예를 들어 성공을 나타내는 윤곽 배지는 현재 API로 `tone: .success, variant: .outlined`라고 쓸 수 있다. `.success`를 tone의 축약으로 제공하려면 두 인자가 고른 조합과 프로젝트 테마가 보존되는지 확인한다. Progress는 tone별 테마를 바꿔 확인하고, Chip은 선택 전과 후를 나누어 확인한다. 입력의 `.error`는 별도로 다룬다. Web TextField의 `aria-invalid`는 검증 결과에서 계산한 `hasError`를 읽으므로 getter를 variant에 연결해도 그 자체로 검증 오류를 전달하지 않는다. [Badge의 tone 정의](../packages/coui_core/lib/src/component/contracts/badge/badge_tone.dart) · [Chip의 선택 색](../packages/coui_core/lib/src/component/contracts/chip/core_chip_color.dart) · [Web TextField](../packages/coui_web/lib/src/components/form/text_field/text_field.dart)

정확히 일치하는 이름 밖에서도 **`.outline`과 `variant: .outlined`**를 혼동하기 쉽다. Badge, Card, Chip, DescriptionCard, Fieldset, Stat에서 이 둘이 공존한다. 이전 `.outline`은 outline 색 토큰을 **배경색**에 넣는다. 윤곽 형태가 목적이면 해당 컴포넌트의 `variant: .outlined`가 명확하다. 개명이나 의미 변경 시 기존 getter의 색을 의도한 호출과 색상 순열 미리보기도 함께 이관해야 한다. [Card variant](../packages/coui_core/lib/src/component/contracts/card/card_variant.dart) · [기존 색상 순열 예제](../docs_core/lib/previews/examples/flutter/badge/badge_chain_permutations.dart)

## 실제 예제에서의 반복

| 명시적 사용 | Flutter 파일 | Web 파일 | 해석 |
|---|---:|---:|---|
| 대표 컴포넌트의 `variant:` | 98 | 98 | 각 플랫폼에서 23종에 걸쳐 사용. 공통 문서 표기부터 적용할 근거가 있다. |
| 대표 컴포넌트의 `size:` | 35 | 35 | 각 플랫폼에서 12종에 걸쳐 사용. 구체적인 enum 값은 컴포넌트가 결정한다. |
| 대표 Core 스타일 생성자의 `padding:` | 9 | 9 | 양쪽 모두 Card 8개 파일, OutlinedContainer 1개 파일. 스타일 필드가 있는 49개를 한꺼번에 확장할 만큼 수요가 넓게 관측되지는 않았다. |
| 같은 방식의 `borderRadius:` | 1 | 1 | 두 플랫폼 모두 Button 예제에서 직접 지정했다. 이 수치는 기존 반경 getter 사용을 포함하지 않는다. |

Card·Button·Badge에 `.contentPadding(...)`, `.borderColor(...)`, `.borderWidth(...)`를 시범 적용했다. 전경색 필드가 있는 Button·Badge에는 `.foregroundColor(...)`도 제공한다. ResponsiveGrid의 카드 예제는 `Card(child: ...).contentPadding(.all(CoreSpace.space16))`으로 줄었다. 각 메서드는 기존 Core 스타일의 한 필드를 병합한다. [Flutter 예제](../docs_core/lib/previews/examples/flutter/responsive_grid/responsive_grid_default_example.dart) · [Web 예제](../docs_core/lib/previews/examples/web/responsive_grid/responsive_grid_default_example.dart)

## 컴포넌트별 적용 지도

각 행은 양 플랫폼의 대표 타입 하나다. 생성자 열은 양쪽에서 공통으로 찾은 주요 인자, 스타일 열은 `withStyle`이 받는 타입의 **최상위 필드** 중 검토 대상이다. 슬롯 개수는 그 타입이 직접 받는 `CoreGapStyle?`의 수다. ‘—’는 해당 열의 조사 항목이 없다는 뜻이다. 반경·색 체인 열은 기존 실측표의 양 플랫폼 공통 축을 따른다.

| 컴포넌트 | 생성자 인자 | 스타일 필드 | 간격 슬롯 수 | 기존 토큰 체인 |
|---|---|---|---:|---|
| [Accordion](../packages/coui_flutter/lib/src/components/layout/accordion/accordion.dart) | — | borderRadius, backgroundColor, borderWidth, borderColor | 1 | 반경·색 |
| [Alert](../packages/coui_flutter/lib/src/components/overlay/alert/alert.dart) | variant, leading | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, iconStyle | 1 | 반경·색 |
| [AppBar](../packages/coui_flutter/lib/src/components/layout/app_bar/app_bar.dart) | variant, leading, trailing | padding, backgroundColor | 0 | 색 |
| [Autocomplete](../packages/coui_flutter/lib/src/components/form/autocomplete/autocomplete.dart) | enabled, value, onChanged | — | 0 | — |
| [Avatar](../packages/coui_flutter/lib/src/components/display/avatar/avatar.dart) | size | borderRadius, backgroundColor | 0 | 반경·색 |
| [Badge](../packages/coui_flutter/lib/src/components/display/badge/badge.dart) | variant, tone, size, onPressed, leading, trailing | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, labelStyle, iconStyle | 1 | 반경·색 |
| [Banner](../packages/coui_flutter/lib/src/components/display/banner/banner.dart) | variant | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, iconStyle | 3 | 반경·색 |
| [Basic](../packages/coui_flutter/lib/src/components/layout/basic/basic.dart) | leading, trailing | padding | 4 | — |
| [BottomActionBar](../packages/coui_flutter/lib/src/components/layout/bottom_action_bar/bottom_action_bar.dart) | — | padding, backgroundColor | 0 | — |
| [BottomSheet](../packages/coui_flutter/lib/src/components/layout/bottom_sheet/bottom_sheet.dart) | — | borderRadius, backgroundColor | 1 | — |
| [Breadcrumb](../packages/coui_flutter/lib/src/components/navigation/breadcrumb/breadcrumb.dart) | variant, enabled | — | 1 | — |
| [Button](../packages/coui_flutter/lib/src/components/control/button/button.dart) | variant, size, enabled, onPressed, leading, trailing | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, labelStyle | 1 | 반경·색 |
| [Calendar](../packages/coui_flutter/lib/src/components/display/calendar/calendar.dart) | value, onChanged | — | 1 | — |
| [Card](../packages/coui_flutter/lib/src/components/layout/card/card.dart) | variant | padding, borderRadius, backgroundColor, borderWidth, borderColor | 2 | 반경·색 |
| [CardImage](../packages/coui_flutter/lib/src/components/layout/card_image/card_image.dart) | enabled, onPressed, leading, trailing | — | 1 | 반경·색 |
| [Carousel](../packages/coui_flutter/lib/src/components/display/carousel/carousel.dart) | variant, size | borderRadius | 2 | 반경 |
| [CarouselBanner](../packages/coui_flutter/lib/src/components/display/carousel_banner/carousel_banner.dart) | size | padding, borderRadius, backgroundColor | 2 | — |
| [CategoryBreakdown](../packages/coui_flutter/lib/src/components/display/category_breakdown/category_breakdown.dart) | variant | labelStyle | 0 | — |
| [Chat](../packages/coui_flutter/lib/src/components/display/chat/chat.dart) | — | — | 0 | — |
| [Checkbox](../packages/coui_flutter/lib/src/components/form/checkbox/checkbox.dart) | size, enabled, checked, onChanged, trailing | labelStyle | 2 | — |
| [Chip](../packages/coui_flutter/lib/src/components/display/chip/chip.dart) | variant, size, enabled, leading, trailing | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, labelStyle | 1 | 반경·색 |
| [ChipGroup](../packages/coui_flutter/lib/src/components/display/chip_group/chip_group.dart) | onChanged | — | 2 | — |
| [ChipInput](../packages/coui_flutter/lib/src/components/form/chip_input/chip_input.dart) | enabled, onChanged | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Clickable](../packages/coui_flutter/lib/src/components/infra/clickable/clickable.dart) | enabled, onPressed | borderRadius | 0 | 반경 |
| [CodeDiff](../packages/coui_flutter/lib/src/components/display/code_diff/code_diff.dart) | — | borderWidth | 0 | — |
| [CodeSnippet](../packages/coui_flutter/lib/src/components/display/code_snippet/code_snippet.dart) | — | padding, borderRadius, backgroundColor, borderWidth, borderColor | 1 | 반경·색 |
| [Collapsible](../packages/coui_flutter/lib/src/components/layout/collapsible/collapsible.dart) | — | iconStyle | 1 | — |
| [ColorPicker](../packages/coui_flutter/lib/src/components/form/color_picker/color_picker.dart) | enabled, onChanged | borderWidth, borderColor, labelStyle | 4 | — |
| [Command](../packages/coui_flutter/lib/src/components/control/command/command.dart) | variant, size | borderRadius, backgroundColor, borderWidth, borderColor, labelStyle | 2 | 반경·색 |
| [CommandSearch](../packages/coui_flutter/lib/src/components/control/command_search/command_search.dart) | size, enabled, onPressed, leading | padding, borderRadius, backgroundColor, foregroundColor | 1 | — |
| [ContextMenu](../packages/coui_flutter/lib/src/components/menu/context_menu/context_menu.dart) | enabled | — | 0 | — |
| [Countdown](../packages/coui_flutter/lib/src/components/display/countdown/countdown.dart) | value | labelStyle | 0 | — |
| [DatePicker](../packages/coui_flutter/lib/src/components/form/date_picker/date_picker.dart) | enabled, value, onChanged | labelStyle | 2 | — |
| [DefinitionList](../packages/coui_flutter/lib/src/components/text/definition_list/definition_list.dart) | — | — | 0 | — |
| [DescriptionCard](../packages/coui_flutter/lib/src/components/display/description_card/description_card.dart) | variant, size, enabled | padding, borderRadius, backgroundColor, borderWidth, borderColor | 5 | 반경·색 |
| [Dialog](../packages/coui_flutter/lib/src/components/overlay/dialog/dialog.dart) | leading, trailing | — | 2 | — |
| [Diff](../packages/coui_flutter/lib/src/components/display/diff/diff.dart) | — | borderRadius, borderWidth, borderColor | 0 | 반경 |
| [Disclosure](../packages/coui_flutter/lib/src/components/layout/disclosure/disclosure.dart) | — | iconStyle | 1 | — |
| [DisclosureBadge](../packages/coui_flutter/lib/src/components/display/disclosure_badge/disclosure_badge.dart) | — | padding, borderRadius, foregroundColor, borderWidth, borderColor, labelStyle | 0 | — |
| [Divider](../packages/coui_flutter/lib/src/components/display/divider/divider.dart) | — | — | 0 | — |
| [Dock](../packages/coui_flutter/lib/src/components/layout/dock/dock.dart) | size | padding, backgroundColor, borderWidth, borderColor, iconStyle | 1 | 색 |
| [DotIndicator](../packages/coui_flutter/lib/src/components/display/dot_indicator/dot_indicator.dart) | size, onChanged | padding, borderRadius | 0 | 반경 |
| [DraggablePanel](../packages/coui_flutter/lib/src/components/layout/draggable_panel/draggable_panel.dart) | enabled | — | 0 | — |
| [Drawer](../packages/coui_flutter/lib/src/components/overlay/drawer/drawer.dart) | — | — | 1 | — |
| [DropdownMenu](../packages/coui_flutter/lib/src/components/menu/dropdown_menu/dropdown_menu.dart) | — | — | 0 | — |
| [EmptyState](../packages/coui_flutter/lib/src/components/display/empty_state/empty_state.dart) | variant, tone | padding, iconStyle | 3 | — |
| [Fab](../packages/coui_flutter/lib/src/components/control/fab/fab.dart) | size, onPressed | iconStyle | 0 | — |
| [FadeScroll](../packages/coui_flutter/lib/src/components/layout/fade_scroll/fade_scroll.dart) | — | — | 0 | — |
| [Fieldset](../packages/coui_flutter/lib/src/components/form/fieldset/fieldset.dart) | variant, size, enabled | padding, borderRadius, backgroundColor, borderWidth, borderColor | 2 | 반경·색 |
| [FileInput](../packages/coui_flutter/lib/src/components/form/file_input/file_input.dart) | enabled | padding, borderRadius, backgroundColor, borderWidth, borderColor, iconStyle | 0 | 반경·색 |
| [Filter](../packages/coui_flutter/lib/src/components/control/filter/filter.dart) | variant, size, enabled | padding, borderRadius, backgroundColor, iconStyle | 0 | 반경·색 |
| [FocusOutline](../packages/coui_flutter/lib/src/components/infra/focus_outline/focus_outline.dart) | — | borderRadius, borderWidth, borderColor | 0 | 반경 |
| [Footer](../packages/coui_flutter/lib/src/components/layout/footer/footer.dart) | — | padding, backgroundColor | 1 | 색 |
| [FormField](../packages/coui_flutter/lib/src/components/form/form_field/form_field.dart) | size, enabled | — | 3 | — |
| [FormLabel](../packages/coui_flutter/lib/src/components/form/form_label/form_label.dart) | size, enabled | labelStyle | 1 | — |
| [FormattedInput](../packages/coui_flutter/lib/src/components/form/formatted_input/formatted_input.dart) | enabled, value, onChanged, leading, trailing | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Frame](../packages/coui_flutter/lib/src/components/layout/frame/frame.dart) | — | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Gap](../packages/coui_flutter/lib/src/components/layout/gap/gap.dart) | — | — | 0 | — |
| [Hero](../packages/coui_flutter/lib/src/components/layout/hero/hero.dart) | — | padding, backgroundColor | 1 | 색 |
| [Hover](../packages/coui_flutter/lib/src/components/control/hover/hover.dart) | — | — | 0 | — |
| [HoverCard](../packages/coui_flutter/lib/src/components/overlay/hover_card/hover_card.dart) | — | — | 0 | 반경·색 |
| [HoverGallery](../packages/coui_flutter/lib/src/components/display/hover_gallery/hover_gallery.dart) | — | borderRadius | 0 | 반경 |
| [Icon](../packages/coui_flutter/lib/src/components/icon/icon.dart) | — | — | 0 | — |
| [IndexedSwitcher](../packages/coui_flutter/lib/src/components/navigation/indexed_switcher/indexed_switcher.dart) | — | — | 0 | — |
| [Indicator](../packages/coui_flutter/lib/src/components/display/indicator/indicator.dart) | — | — | 0 | — |
| [InputOtp](../packages/coui_flutter/lib/src/components/form/input_otp/input_otp.dart) | size, enabled, onChanged | borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [ItemPicker](../packages/coui_flutter/lib/src/components/form/item_picker/item_picker.dart) | enabled, onChanged | borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Join](../packages/coui_flutter/lib/src/components/layout/join/join.dart) | — | borderRadius | 0 | 반경 |
| [Kbd](../packages/coui_flutter/lib/src/components/display/kbd/kbd.dart) | — | — | 0 | — |
| [Label](../packages/coui_flutter/lib/src/components/display/label/label.dart) | — | iconStyle | 2 | — |
| [Link](../packages/coui_flutter/lib/src/components/text/link/link.dart) | variant, onPressed, leading, trailing | labelStyle, iconStyle | 1 | — |
| [Listing](../packages/coui_flutter/lib/src/components/layout/listing/listing.dart) | — | padding | 0 | — |
| [Loading](../packages/coui_flutter/lib/src/components/display/loading/loading.dart) | variant, tone | — | 0 | — |
| [Menu](../packages/coui_flutter/lib/src/components/menu/menu/menu.dart) | size | — | 0 | — |
| [MenuItem](../packages/coui_flutter/lib/src/components/menu/menu_item/menu_item.dart) | tone, size, enabled, onPressed, leading, trailing | padding, borderRadius, backgroundColor, foregroundColor, labelStyle | 2 | — |
| [Menubar](../packages/coui_flutter/lib/src/components/menu/menubar/menubar.dart) | variant | — | 0 | — |
| [MockupBrowser](../packages/coui_flutter/lib/src/components/display/mockup_browser/mockup_browser.dart) | — | borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [MockupCode](../packages/coui_flutter/lib/src/components/display/mockup_code/mockup_code.dart) | — | padding, borderRadius, backgroundColor | 0 | 반경·색 |
| [MockupDevice](../packages/coui_flutter/lib/src/components/display/mockup_device/mockup_device.dart) | — | borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [MockupFoldable](../packages/coui_flutter/lib/src/components/display/mockup_foldable/mockup_foldable.dart) | — | — | 0 | — |
| [MultiAnswerCard](../packages/coui_flutter/lib/src/components/form/multi_answer_card/multi_answer_card.dart) | enabled, value, onChanged | padding, borderRadius, backgroundColor, borderWidth, borderColor | 1 | 반경·색 |
| [MultipleChoice](../packages/coui_flutter/lib/src/components/form/multiple_choice/multiple_choice.dart) | enabled, value, onChanged | — | 0 | — |
| [NavigationBar](../packages/coui_flutter/lib/src/components/navigation/navigation_bar/navigation_bar.dart) | variant | padding, backgroundColor, iconStyle | 1 | 색 |
| [NavigationBarItem](../packages/coui_flutter/lib/src/components/navigation/navigation_bar_item/navigation_bar_item.dart) | variant, enabled, onPressed | padding, backgroundColor, iconStyle | 1 | — |
| [NavigationMenu](../packages/coui_flutter/lib/src/components/menu/navigation_menu/navigation_menu.dart) | variant | — | 0 | — |
| [NumberInput](../packages/coui_flutter/lib/src/components/form/number_input/number_input.dart) | variant, size, enabled, value, onChanged | — | 0 | — |
| [NumberTicker](../packages/coui_flutter/lib/src/components/display/number_ticker/number_ticker.dart) | value | — | 0 | — |
| [ObjectInput](../packages/coui_flutter/lib/src/components/form/object_input/object_input.dart) | enabled, onChanged, leading, trailing | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [OptionItem](../packages/coui_flutter/lib/src/components/form/option_item/option_item.dart) | enabled, onPressed, leading | padding, borderRadius, borderWidth, borderColor | 1 | — |
| [OptionList](../packages/coui_flutter/lib/src/components/form/option_list/option_list.dart) | — | — | 0 | — |
| [OutlinedContainer](../packages/coui_flutter/lib/src/components/infra/outlined_container/outlined_container.dart) | — | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [OverflowMarquee](../packages/coui_flutter/lib/src/components/layout/overflow_marquee/overflow_marquee.dart) | — | — | 0 | — |
| [PageHeader](../packages/coui_flutter/lib/src/components/layout/page_header/page_header.dart) | — | — | 0 | — |
| [Pagination](../packages/coui_flutter/lib/src/components/navigation/pagination/pagination.dart) | variant, enabled | iconStyle | 0 | — |
| [PanelHeader](../packages/coui_flutter/lib/src/components/layout/panel_header/panel_header.dart) | — | padding | 0 | — |
| [PhoneInput](../packages/coui_flutter/lib/src/components/form/phone_input/phone_input.dart) | enabled, onChanged | padding, borderRadius, backgroundColor, borderWidth, borderColor | 3 | 반경·색 |
| [Popover](../packages/coui_flutter/lib/src/components/overlay/popover/popover.dart) | — | — | 0 | — |
| [Popup](../packages/coui_flutter/lib/src/components/infra/popup/popup.dart) | — | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Progress](../packages/coui_flutter/lib/src/components/display/progress/progress.dart) | tone, size, value | borderRadius, backgroundColor, labelStyle | 2 | 반경·색 |
| [RadioGroup](../packages/coui_flutter/lib/src/components/form/radio_group/radio_group.dart) | variant, size, enabled, value, onChanged | labelStyle | 2 | — |
| [Range](../packages/coui_flutter/lib/src/components/form/range/range.dart) | enabled, onChanged, leading, trailing | borderRadius | 1 | 반경 |
| [RefreshTrigger](../packages/coui_flutter/lib/src/components/overlay/refresh_trigger/refresh_trigger.dart) | — | labelStyle | 1 | — |
| [Resizable](../packages/coui_flutter/lib/src/components/layout/resizable/resizable.dart) | — | — | 0 | — |
| [ResponsiveContainer](../packages/coui_flutter/lib/src/components/layout/responsive_container/responsive_container.dart) | — | — | 0 | — |
| [ResponsiveGrid](../packages/coui_flutter/lib/src/components/layout/responsive_grid/responsive_grid.dart) | — | — | 0 | — |
| [ResponsiveRowColumn](../packages/coui_flutter/lib/src/components/layout/responsive_row_column/responsive_row_column.dart) | — | — | 0 | — |
| [Scaffold](../packages/coui_flutter/lib/src/components/layout/scaffold/scaffold.dart) | variant | backgroundColor | 0 | 색 |
| [ScrollArea](../packages/coui_flutter/lib/src/components/layout/scroll_area/scroll_area.dart) | — | — | 0 | — |
| [Scrollbar](../packages/coui_flutter/lib/src/components/infra/scrollbar/scrollbar.dart) | — | — | 0 | — |
| [ScrollViewInterceptor](../packages/coui_flutter/lib/src/components/infra/scrollview/scrollview_interceptor.dart) | enabled | — | 0 | — |
| [Select](../packages/coui_flutter/lib/src/components/form/select/select.dart) | variant, size, enabled, value, onChanged | — | 0 | — |
| [SelectableText](../packages/coui_flutter/lib/src/components/text/selectable/selectable_text.dart) | — | — | 0 | — |
| [Sidebar](../packages/coui_flutter/lib/src/components/navigation/sidebar/sidebar.dart) | — | backgroundColor, borderWidth, borderColor | 1 | — |
| [SidebarGroup](../packages/coui_flutter/lib/src/components/navigation/sidebar_group/sidebar_group.dart) | leading | — | 0 | — |
| [SidebarHeader](../packages/coui_flutter/lib/src/components/navigation/sidebar_header/sidebar_header.dart) | variant, onPressed, leading, trailing | padding, borderRadius, backgroundColor, borderWidth, borderColor | 0 | — |
| [SidebarItem](../packages/coui_flutter/lib/src/components/navigation/sidebar_item/sidebar_item.dart) | enabled, onPressed, leading, trailing | padding, borderRadius, backgroundColor, labelStyle, iconStyle | 0 | — |
| [SidebarRailItem](../packages/coui_flutter/lib/src/components/navigation/sidebar_rail_item/sidebar_rail_item.dart) | enabled, onPressed | borderRadius, backgroundColor, iconStyle | 0 | — |
| [SidebarSearch](../packages/coui_flutter/lib/src/components/navigation/sidebar_search/sidebar_search.dart) | onPressed | padding, borderRadius, backgroundColor, borderWidth, borderColor, iconStyle | 0 | — |
| [SidebarSection](../packages/coui_flutter/lib/src/components/navigation/sidebar_section/sidebar_section.dart) | — | padding, labelStyle | 0 | — |
| [Skeleton](../packages/coui_flutter/lib/src/components/display/skeleton/skeleton.dart) | variant | borderRadius, backgroundColor | 0 | 반경·색 |
| [Slider](../packages/coui_flutter/lib/src/components/form/slider/slider.dart) | enabled, value, onChanged, leading, trailing | borderRadius | 1 | 반경 |
| [Sortable](../packages/coui_flutter/lib/src/components/form/sortable/sortable.dart) | enabled | iconStyle | 0 | — |
| [StageContainer](../packages/coui_flutter/lib/src/components/layout/stage_container/stage_container.dart) | — | padding | 0 | — |
| [StarRating](../packages/coui_flutter/lib/src/components/form/star_rating/star_rating.dart) | size, enabled, value, onChanged | backgroundColor | 1 | 색 |
| [Stat](../packages/coui_flutter/lib/src/components/display/stat/stat.dart) | variant, size, value | padding, borderRadius, backgroundColor, borderWidth, borderColor | 3 | 반경·색 |
| [Status](../packages/coui_flutter/lib/src/components/display/status/status.dart) | variant, size | borderRadius, labelStyle | 0 | 반경 |
| [StepItem](../packages/coui_flutter/lib/src/components/layout/step_item/step_item.dart) | trailing | padding, iconStyle | 2 | — |
| [Stepper](../packages/coui_flutter/lib/src/components/layout/stepper/stepper.dart) | enabled | labelStyle | 3 | — |
| [Steps](../packages/coui_flutter/lib/src/components/layout/steps/steps.dart) | variant | labelStyle | 3 | — |
| [Subfocus](../packages/coui_flutter/lib/src/components/infra/subfocus/subfocus.dart) | enabled | — | 0 | — |
| [Swap](../packages/coui_flutter/lib/src/components/display/swap/swap.dart) | checked | — | 0 | — |
| [SwipeActions](../packages/coui_flutter/lib/src/components/layout/swipe_actions/swipe_actions.dart) | enabled | labelStyle | 1 | — |
| [Swiper](../packages/coui_flutter/lib/src/components/overlay/swiper/swiper.dart) | variant, enabled | — | 0 | — |
| [SwitchField](../packages/coui_flutter/lib/src/components/form/switch_field/switch_field.dart) | enabled, value, onChanged | — | 2 | — |
| [Switcher](../packages/coui_flutter/lib/src/components/navigation/switcher/switcher.dart) | — | — | 0 | — |
| [TabPane](../packages/coui_flutter/lib/src/components/navigation/tabs/tab_pane.dart) | variant, onChanged, leading, trailing | borderRadius, backgroundColor, borderWidth, borderColor | 1 | 반경·색 |
| [Table](../packages/coui_flutter/lib/src/components/layout/table/table.dart) | — | borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor | 0 | 반경·색 |
| [Tabs](../packages/coui_flutter/lib/src/components/navigation/tabs/tabs.dart) | variant, size, onChanged | backgroundColor, borderWidth, borderColor | 1 | 색 |
| [Tag](../packages/coui_flutter/lib/src/components/display/tag/tag.dart) | size | padding, borderRadius, backgroundColor, foregroundColor, borderWidth, borderColor, labelStyle | 0 | — |
| [TextArea](../packages/coui_flutter/lib/src/components/form/text_area/text_area.dart) | variant, size, enabled, onChanged | padding, borderRadius, backgroundColor, borderWidth, borderColor, labelStyle, iconStyle | 4 | 반경·색 |
| [TextBlock](../packages/coui_flutter/lib/src/components/text/text_block/text_block.dart) | — | — | 0 | — |
| [TextField](../packages/coui_flutter/lib/src/components/form/text_field/text_field.dart) | variant, size, enabled, value, onChanged | padding, borderRadius, backgroundColor, borderWidth, borderColor, labelStyle, iconStyle | 0 | 반경·색 |
| [ThemeController](../packages/coui_flutter/lib/src/components/control/theme_controller/theme_controller.dart) | size, enabled | labelStyle | 1 | — |
| [TimePicker](../packages/coui_flutter/lib/src/components/form/time_picker/time_picker.dart) | enabled, value, onChanged | labelStyle | 3 | — |
| [Timeline](../packages/coui_flutter/lib/src/components/display/timeline/timeline.dart) | — | — | 2 | — |
| [Toast](../packages/coui_flutter/lib/src/components/overlay/toast/toast.dart) | variant | iconStyle | 3 | — |
| [Toggle](../packages/coui_flutter/lib/src/components/form/toggle/toggle.dart) | variant, size, enabled, value, onChanged | padding, labelStyle | 1 | — |
| [ToggleGroup](../packages/coui_flutter/lib/src/components/control/toggle_group/toggle_group.dart) | size, enabled, value, onChanged, trailing | padding, borderRadius, backgroundColor, iconStyle | 0 | — |
| [Tooltip](../packages/coui_flutter/lib/src/components/overlay/tooltip/tooltip.dart) | — | labelStyle | 0 | — |
| [Tracker](../packages/coui_flutter/lib/src/components/display/tracker/tracker.dart) | — | — | 0 | — |
| [Tree](../packages/coui_flutter/lib/src/components/layout/tree/tree.dart) | — | borderRadius, iconStyle | 3 | 반경 |
| [TrendChart](../packages/coui_flutter/lib/src/components/display/trend_chart/trend_chart.dart) | variant | — | 0 | — |
| [Validated](../packages/coui_flutter/lib/src/components/form/validated/validated.dart) | — | — | 1 | — |
| [ValidationBadge](../packages/coui_flutter/lib/src/components/display/validation_badge/validation_badge.dart) | size | borderWidth, iconStyle | 1 | — |
| [ValidatorHint](../packages/coui_flutter/lib/src/components/form/validator_hint/validator_hint.dart) | — | iconStyle | 1 | — |
| [Window](../packages/coui_flutter/lib/src/components/layout/window/window.dart) | — | — | 0 | — |
| [WindowPanel](../packages/coui_flutter/lib/src/components/layout/window_panel/window_panel.dart) | — | borderRadius, borderColor | 0 | 반경 |

## 기존 체인 집계에서 빠진 22개 디렉터리

Text는 독립적인 텍스트 체인을 이미 제공한다. RichEditor는 양쪽 생성자에 `richEditorStyle`을 받으므로 `withStyle` 확장 후보로 별도 검토할 수 있다. ToolbarGroup의 `popupStyle`은 팝업에 전달하는 하위 슬롯이다. Stacks는 `children`, `alignment`, `fit` 같은 레이아웃 인자로 읽는 편이 자연스럽다. 집계 제외 여부만으로 모든 디렉터리에 스타일 체인이 필요하다고 판단할 수 없다.

`aspect-ratio-box`, `bar-action`, `breakpoint`, `coui-localizations`, `drag-item`, `drag-overlay`, `drag-scope`, `drop-zone`, `form`, `formatter`, `hidden`, `image-properties`, `inset-shadow`, `loading-region`, `mask`, `overlay`, `rich-editor`, `scrollable-client`, `stacks`, `text`, `toolbar-group`, `touch-target`.
