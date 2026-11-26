# Discovery — 전 컴포넌트 글래스 적용

## 물어본 것

"전체 컴포넌트에 글래스 효과를 제대로 적용" — 그런데 *전체*가 몇 개이고,
지금 몇 개에 닿으며, 안 닿는 이유가 무엇인지는 아무도 세어본 적이 없다.
그래서 판단하기 전에 셌다.

## 잰 것

| | 수 |
|---|---|
| 카탈로그 컴포넌트 | 138 |
| Web — 표면 마커를 다는 것 | **9** |
| Flutter — 재질을 받는 것 | **12** |
| Web — 자기 박스를 그리는데 마커 없음 | **50** |
| Flutter — 자기 박스를 그리는데 재질 없음 | **72** |

두 플랫폼이 이미 어긋나 있다: Flutter 는 `card_image` · `window` ·
`overlay/` 가 재질을 받고 Web 은 안 받는다. 같은 프리셋에서 같은
컴포넌트가 한쪽만 유리다.

## 안 닿는 이유 — 마커가 없어서가 아니다

표본을 열어보면 패턴이 하나다. `empty_state` 는

```dart
final surface = Container(decoration: BoxDecoration(...))
```

`description_card` 는 `DecoratedBox(decoration: BoxDecoration(...))`.
둘 다 **표면 프리미티브를 합성하지 않고 자기 박스를 손으로 그린다.**

그래서 재질이 닿을 자리가 애초에 없다. 축은 표면 프리미티브를 통해
흐르는데, 이 컴포넌트들은 그 프리미티브를 지나가지 않는다.

**이건 이미 룰 위반이다** — `core/style-contract.md` 의 "합성 = 재구현
금지": 그 surface 를 그리는 통일 컴포넌트가 존재하면 직접 그리지 말고
합성한다. 유리가 안 닿는 것은 그 위반의 *증상*이지 별개 문제가 아니다.

## 그래서 작업의 성격이 바뀐다

"마커 90개 추가"가 아니라 "손으로 그린 박스를 합성으로 되돌리기"다.
후자는 유리만 고치는 게 아니라 같이 딸려온다:

- 재질(반투명 · 블러 · 채도 · 굴절 · 베벨)
- edge band 와 stroke 억제 — 지금은 컴포넌트마다 자기 보더를 그린다
- forced-colors / prefers-contrast / reduce-transparency 폴백
- 그림자 처리와 rim

즉 90번의 markers 가 아니라, 이미 지고 있던 부채를 갚으면서 유리가
따라오는 구조다.

## 무엇이 표면이 아닌가

전부가 표면은 아니다. 박스를 그린다고 다 판(pane)은 아니다.

**제외** — 글리프 · 인디케이터 · 래퍼 · 레이아웃:
`loading` `skeleton` `progress` `dot_indicator` `triple_dots` `scrollbar`
`focus_outline` `clickable` `text_block` `divider` `gap` `hidden`
`media_query` `breakpoint` `stack_layout` `responsive_*`

이들은 재질을 받으면 오히려 틀린다 — 스피너가 유리로 만들어졌다는
진술은 참이 아니다.

## 남는 것 — 두 계층

**A. 판 (panel)** — 콘텐츠가 그 위에 앉는 면. 약 40개.
`command` `calendar` `chat` `code_snippet` `code_diff` `diff`
`description_card` `empty_state` `banner` `stat` `tracker` `mockup_*`
`table` `accordion` `collapsible` `stepper` `steps` `tree` `resizable`
`window_panel` `draggable_panel` `frame` `hero_section` `drawer` `toast`
`swiper` `menu` `menubar` `context_menu` `dropdown_menu` `navigation_menu`
`fieldset` `multi_answer_card` `multiple_choice` `item_picker`
`color_picker` `time_picker` `sortable` `refresh_trigger` `filter`

**B. 컨트롤 (control)** — 사용자가 만지는 작은 재질 조각. 약 30개.
`button` `fab` `chip` `badge` `kbd` `avatar` `checkbox` `toggle`
`radio_group` `slider` `range` `star_rating` `text_field` `text_area`
`select` `autocomplete` `phone_input` `chip_input` `formatted_input`
`object_input` `input_otp` `file_input` `validation_badge`
`disclosure_badge` `tabs` `pagination`

Apple 의 Liquid Glass 는 둘 다 유리다. 판만 하면 컨트롤이 판 위에
불투명하게 떠서 오히려 더 어색해진다 — 지금 카드 안의 Action 버튼이
정확히 그 상태다.

## 이 문서가 답하지 않는 것

A 와 B 중 무엇을 먼저 할지, 한 번에 갈지. 그건 규모 결정이고 다음
단계에서 사용자가 정한다. 측정과 근거까지가 여기 몫이다.
