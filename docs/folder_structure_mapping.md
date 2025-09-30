# CoUI 폴더 구조 매핑 및 재구성 계획

## 현재 상태 분석

### coui_flutter 폴더 구조 (카테고리별 정리)

```
packages/coui_flutter/lib/src/components/
├── control/          # 사용자 상호작용 컨트롤
│   ├── button.dart
│   ├── clickable.dart
│   ├── command.dart
│   ├── hover.dart
│   ├── scrollbar.dart
│   └── scrollview.dart
│
├── form/             # 폼 입력 컴포넌트 (30개)
│   ├── autocomplete.dart
│   ├── checkbox.dart
│   ├── chip_input.dart
│   ├── color_picker.dart
│   ├── control.dart
│   ├── date_picker.dart
│   ├── file_input.dart
│   ├── file_picker.dart
│   ├── form.dart
│   ├── form_field.dart
│   ├── formatted_input.dart
│   ├── formatter.dart
│   ├── image.dart
│   ├── input.dart
│   ├── input_otp.dart
│   ├── item_picker.dart
│   ├── multiple_choice.dart
│   ├── object_input.dart
│   ├── phone_input.dart
│   ├── radio_group.dart
│   ├── select.dart
│   ├── slider.dart
│   ├── sortable.dart
│   ├── star_rating.dart
│   ├── switch.dart
│   ├── text_area.dart
│   ├── text_field.dart
│   ├── time_picker.dart
│   └── validated.dart
│
├── display/          # 표시 전용 컴포넌트 (16개)
│   ├── avatar.dart
│   ├── badge.dart
│   ├── calendar.dart
│   ├── carousel.dart
│   ├── chip.dart
│   ├── circular_progress_indicator.dart
│   ├── code_snippet.dart
│   ├── divider.dart
│   ├── dot_indicator.dart
│   ├── fade_scroll.dart
│   ├── keyboard_shortcut.dart
│   ├── linear_progress_indicator.dart
│   ├── number_ticker.dart
│   ├── progress.dart
│   ├── skeleton.dart
│   └── spinner.dart
│
├── layout/           # 레이아웃 컴포넌트 (26개)
│   ├── accordion.dart
│   ├── alert.dart
│   ├── basic.dart
│   ├── breadcrumb.dart
│   ├── card.dart
│   ├── card_image.dart
│   ├── collapsible.dart
│   ├── dialog/
│   │   └── alert_dialog.dart
│   ├── focus_outline.dart
│   ├── group.dart
│   ├── hidden.dart
│   ├── media_query.dart
│   ├── outlined_container.dart
│   ├── overflow_marquee.dart
│   ├── resizable.dart
│   ├── scaffold.dart
│   ├── scrollable_client.dart
│   ├── sortable.dart
│   ├── stage_container.dart
│   ├── stepper.dart
│   ├── steps.dart
│   ├── table.dart
│   ├── timeline.dart
│   ├── tree.dart
│   └── window.dart
│
├── navigation/       # 내비게이션 컴포넌트 (8개)
│   ├── navigation_bar.dart
│   ├── pagination.dart
│   ├── subfocus.dart
│   ├── switcher.dart
│   └── tabs/
│       ├── tab_container.dart
│       ├── tab_list.dart
│       ├── tab_pane.dart
│       └── tabs.dart
│
├── menu/             # 메뉴 컴포넌트 (6개)
│   ├── context_menu.dart
│   ├── dropdown_menu.dart
│   ├── menu.dart
│   ├── menubar.dart
│   ├── navigation_menu.dart
│   └── popup.dart
│
├── overlay/          # 오버레이 컴포넌트 (9개)
│   ├── dialog.dart
│   ├── drawer.dart
│   ├── hover_card.dart
│   ├── overlay.dart
│   ├── popover.dart
│   ├── refresh_trigger.dart
│   ├── swiper.dart
│   ├── toast.dart
│   └── tooltip.dart
│
├── text/             # 텍스트 컴포넌트 (2개)
│   ├── selectable.dart
│   └── text.dart
│
├── icon/             # 아이콘 컴포넌트 (2개)
│   ├── icon.dart
│   └── triple_dots.dart
│
├── chart/            # 차트 컴포넌트 (1개)
│   └── tracker.dart
│
├── locale/           # 로케일 (1개)
│   └── coui_localizations.dart
│
└── 기타 유틸리티
    ├── animation.dart
    ├── async.dart
    ├── debug.dart
    ├── patch.dart
    └── wrapper.dart
```

**총계**: 약 110개 컴포넌트

---

### coui_web 현재 구조 (평면 구조)

```
packages/coui_web/lib/src/components/
├── alert/           (display)
├── avatar/          (display)
├── badge/           (display)
├── button/          (control)
├── card/            (layout)
├── checkbox/        (form)
├── chip/            (display)
├── divider/         (display)
├── icon/            (icon)
├── input/           (form)
├── link/            (?)
├── loading/         (display)
├── progress/        (display)
├── radio/           (form)
├── select/          (form)
├── skeleton/        (display)
├── textarea/        (form)
└── toggle/          (form)
```

**총계**: 18개 컴포넌트

---

## 컴포넌트 매핑 및 이동 계획

### 1. control/ (사용자 상호작용)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| button/ | control/button/ | ✅ 동일 |
| - | control/clickable.dart | ❌ 미구현 |
| - | control/hover.dart | ❌ 미구현 |

**이동**: `button/` → `control/button/`

---

### 2. form/ (폼 입력)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| checkbox/ | form/checkbox/ | ✅ 동일 |
| input/ | form/input/ | ✅ 동일 (+ text_field.dart) |
| radio/ | form/radio/ | ✅ 동일 |
| select/ | form/select/ | ✅ 동일 |
| textarea/ | form/textarea/ | ✅ 동일 |
| toggle/ | form/toggle/ (or switch/) | ⚠️ 이름 다름 (flutter: switch.dart) |
| - | form/autocomplete.dart | ❌ 미구현 |
| - | form/chip_input.dart | ❌ 미구현 |
| - | form/color_picker.dart | ❌ 미구현 |
| - | form/date_picker.dart | ❌ 미구현 |
| - | form/file_input.dart | ❌ 미구현 |
| - | form/slider.dart | ❌ 미구현 |
| - | form/star_rating.dart | ❌ 미구현 |
| - | form/phone_input.dart | ❌ 미구현 |
| - | form/input_otp.dart | ❌ 미구현 |
| - | form/time_picker.dart | ❌ 미구현 |

**이동**: `checkbox/`, `input/`, `radio/`, `select/`, `textarea/`, `toggle/` → `form/` 하위

---

### 3. display/ (표시 전용)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| alert/ | display/alert/ (or layout/alert/) | ⚠️ flutter는 layout/alert.dart |
| avatar/ | display/avatar/ | ✅ 동일 |
| badge/ | display/badge/ | ✅ 동일 |
| chip/ | display/chip/ | ✅ 동일 |
| divider/ | display/divider/ | ✅ 동일 |
| loading/ | display/loading/ (or spinner/) | ⚠️ flutter: spinner.dart |
| progress/ | display/progress/ | ✅ 동일 |
| skeleton/ | display/skeleton/ | ✅ 동일 |
| - | display/calendar.dart | ❌ 미구현 |
| - | display/carousel.dart | ❌ 미구현 |
| - | display/code_snippet.dart | ❌ 미구현 |
| - | display/keyboard_shortcut.dart | ❌ 미구현 |
| - | display/number_ticker.dart | ❌ 미구현 |

**이동**: `avatar/`, `badge/`, `chip/`, `divider/`, `loading/`, `progress/`, `skeleton/` → `display/` 하위

---

### 4. layout/ (레이아웃)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| card/ | layout/card/ | ✅ 동일 |
| - | layout/accordion.dart | ❌ 미구현 |
| - | layout/breadcrumb.dart | ❌ 미구현 |
| - | layout/collapsible.dart | ❌ 미구현 |
| - | layout/stepper.dart | ❌ 미구현 |
| - | layout/table.dart | ❌ 미구현 |
| - | layout/timeline.dart | ❌ 미구현 |

**이동**: `card/` → `layout/card/`

---

### 5. navigation/ (내비게이션)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| - | navigation/navigation_bar.dart | ❌ 미구현 |
| - | navigation/pagination.dart | ❌ 미구현 |
| - | navigation/tabs/ | ❌ 미구현 |

**신규 폴더** 생성 필요

---

### 6. menu/ (메뉴)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| - | menu/context_menu.dart | ❌ 미구현 |
| - | menu/dropdown_menu.dart | ❌ 미구현 |
| - | menu/popup.dart | ❌ 미구현 |

**신규 폴더** 생성 필요

---

### 7. overlay/ (오버레이)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| - | overlay/dialog.dart | ❌ 미구현 |
| - | overlay/drawer.dart | ❌ 미구현 |
| - | overlay/hover_card.dart | ❌ 미구현 |
| - | overlay/popover.dart | ❌ 미구현 |
| - | overlay/toast.dart | ❌ 미구현 |
| - | overlay/tooltip.dart | ❌ 미구현 |

**신규 폴더** 생성 필요

---

### 8. text/ (텍스트)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| - | text/text.dart | ❌ 미구현 |

**신규 폴더** 생성 필요

---

### 9. icon/ (아이콘)
| coui_web 현재 | 이동 후 위치 | coui_flutter 대응 |
|--------------|------------|-----------------|
| icon/ | icon/icon/ | ✅ 동일 |

**유지** (이미 올바른 위치)

---

### 10. link/ (분류 모호)
| coui_web 현재 | 제안 | 비고 |
|--------------|-----|-----|
| link/ | text/link/ or control/link/ | Flutter에는 없음, 카테고리 확인 필요 |

**확인 필요**: Link 컴포넌트의 성격에 따라 text/ 또는 control/로 이동

---

## 구현 우선순위

### Phase 1: 폴더 구조 재구성 (기존 컴포넌트 이동)
1. ✅ **control/** 생성 및 button 이동
2. ✅ **form/** 생성 및 이동 (checkbox, input, radio, select, textarea, toggle)
3. ✅ **display/** 생성 및 이동 (alert, avatar, badge, chip, divider, loading, progress, skeleton)
4. ✅ **layout/** 생성 및 card 이동
5. ⚠️ **link/** 컴포넌트 분류 결정 (text/ or control/)

### Phase 2: 필수 컴포넌트 구현 (High Priority)
**navigation/** (사용 빈도 높음)
- [ ] navigation_bar.dart
- [ ] pagination.dart
- [ ] tabs/ (tab_container, tab_list, tab_pane, tabs)

**overlay/** (사용 빈도 높음)
- [ ] dialog.dart
- [ ] drawer.dart
- [ ] toast.dart
- [ ] tooltip.dart
- [ ] popover.dart

**menu/**
- [ ] dropdown_menu.dart
- [ ] context_menu.dart
- [ ] popup.dart

**layout/** (추가)
- [ ] accordion.dart
- [ ] breadcrumb.dart
- [ ] collapsible.dart

### Phase 3: 폼 컴포넌트 확장 (Medium Priority)
**form/** (추가)
- [ ] date_picker.dart
- [ ] time_picker.dart
- [ ] slider.dart
- [ ] autocomplete.dart
- [ ] chip_input.dart
- [ ] star_rating.dart
- [ ] phone_input.dart
- [ ] input_otp.dart
- [ ] color_picker.dart

### Phase 4: 표시 컴포넌트 확장 (Medium Priority)
**display/** (추가)
- [ ] calendar.dart
- [ ] carousel.dart
- [ ] code_snippet.dart
- [ ] keyboard_shortcut.dart
- [ ] number_ticker.dart

### Phase 5: 레이아웃 컴포넌트 확장 (Low Priority)
**layout/** (추가)
- [ ] stepper.dart
- [ ] table.dart
- [ ] timeline.dart
- [ ] tree.dart

---

## 마이그레이션 체크리스트

### 각 컴포넌트 이동 시 수행 작업
- [ ] 폴더 생성 (필요시)
- [ ] 파일 이동 (component.dart, component_style.dart)
- [ ] import 경로 업데이트 (내부 상대 경로)
- [ ] coui_web.dart export 경로 업데이트
- [ ] DCM 린트 검사 실행
- [ ] 문서 업데이트 (api_unified_summary.md)

### 신규 컴포넌트 구현 시 수행 작업
- [ ] DaisyUI 클래스 매핑 확인
- [ ] Flutter API와 호환되는 external API 설계
- [ ] Internal web event 변환 구현
- [ ] 스타일 modifier 클래스 생성
- [ ] coui_web.dart에 export 추가
- [ ] DCM 린트 검사 실행
- [ ] 문서 업데이트

---

## 예상 문제점 및 해결 방안

### 1. Breaking Changes
**문제**: 기존 사용자의 import 경로가 변경됨
**해결**:
- Old path에서 new path로 re-export하는 deprecated 파일 생성
- 마이그레이션 가이드 제공

### 2. Toggle vs Switch 이름 충돌
**문제**: coui_web은 toggle, coui_flutter는 switch 사용
**제안**:
- Option A: toggle을 switch로 rename (breaking change)
- Option B: toggle 유지, switch wrapper 추가
- **권장**: Option B (TextField 패턴과 동일)

### 3. Alert 위치 모호성
**문제**: coui_flutter는 layout/alert.dart, 표시 전용이면 display가 적합
**제안**:
- layout/alert.dart로 이동 (Flutter 구조 따름)

### 4. Link 컴포넌트 분류
**문제**: Flutter에 없는 web 전용 컴포넌트
**제안**:
- 동작이 clickable이면 control/link/
- 텍스트 스타일링이면 text/link/

---

## 다음 단계

1. ✅ 폴더 구조 분석 완료
2. 🔄 사용자 확인 필요 사항:
   - Link 컴포넌트 분류 (control or text?)
   - Toggle vs Switch 이름 결정
   - Alert 위치 (layout or display?)
3. ⏳ 폴더 구조 재구성 실행
4. ⏳ 우선순위에 따른 신규 컴포넌트 구현