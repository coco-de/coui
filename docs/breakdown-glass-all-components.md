# Breakdown — 전 컴포넌트 글래스

조사 138/138(카탈로그와 일치, 누락 0) → 3축 재검증 → 정정 5건 반영.

## 확정 수치

| | 수 |
|---|---|
| 표면 | **71** (functional 24 · content 47) |
| 이미 재질을 받음 | 20 |
| **작업 대상** | **51** (compose 32 · restate-marker 19) |
| 표면 아님 (제외) | 67 |

## 검증이 뒤집은 것

재검증은 조사가 **자기 자신과 모순한 자리**를 잡았다. 다섯 건 전부 근거가
조사 자신의 다른 판정이다.

| slug | 바뀐 것 | 왜 |
|---|---|---|
| `command` | functional → content | `kControlShadowRestMarker` 를 표면 마커로 오독했다. 그건 23개 파일이 다는 그림자 opt-in 이고, Overlay/Route/Popover 는 0건이며 root 가 `wFull` 이다 — 떠 있는 팔레트는 부모 폭을 채우지 않는다. |
| `tabs` | functional → content | sticky/fixed/absolute/OverlayPortal 0건. 같은 조사가 **동일한 세그먼티드 레일인 `filter` 를 content** 로 판정했고, functional 을 받은 것들(dock·navigation-bar·scaffold·toast)은 전부 코드로 도킹/오버레이를 갖는다. |
| `badge` | compose → restate-marker | Web root 가 `super(tag: 'span')` 고정인데 `OutlinedContainer` 는 `super(tag: 'div')` 하드코딩. **`validation-badge` 가 정확히 이 사유로 restate-marker 를 받았다** — 두 판정이 뒤집혀 있었다. |
| `slider` | content → 제외 | slider 자신의 risk 가 "트랙이 몇 px 이라 블러가 지각 안 되고 활성 채움이 값 신호"라고 적어 **`progress` 의 배제 사유와 같은 문장**이다. 남는 건 자식 없는 thumb 하나인데 `status`(동일 모양)·`resizable` grip·`scrollbar` thumb 이 전부 affordance 글리프로 배제됐다. |
| `range` | content → 제외 | 자기 risk 가 "slider 와 같은 결정을 받아야 한다"고 적었다. |

## already-done 의 절반은 간접 경로다

내가 준 판정 기준("Web 마커 보유 9개 밖이면 오탐")이 좁았다. Web `Popover` 는
`Popup` 컴포넌트를 합성하지 않고 `resolvePopup(...)` 출력을 빌려 쓰고,
`popup_style.dart` 가 그 className 에 마커를 넣는다. 그래서 `select` ·
`date-picker` · `color-picker` · `autocomplete` 는 **마커 목록 밖이어도
already-done 이 맞다**. 이 경로를 모르는 리뷰어는 4건을 되돌리려 할 것이므로
여기 적어 둔다.

## 작업 대상 51개

### compose — 표면 프리미티브 합성으로 되돌린다 (32)

- `command` — content
- `fab` — functional
- `filter` — content
- `theme-controller` — content
- `avatar` — content
- `banner` — content
- `chip` — content
- `code-diff` — content
- `code-snippet` — content
- `empty-state` — content
- `description-card` — content
- `mockup` — content
- `stat` — content
- `checkbox` — content
- `input-otp` — content
- `item-picker` — content
- `multiple-choice` — content
- `radio-group` — content
- `toggle` — content
- `fieldset` — content
- `formatted-input` — content
- `multi-answer-card` — content
- `object-input` — content
- `accordion` — content
- `stepper` — content
- `steps` — content
- `window` — functional
- `window-panel` — functional
- `footer` — content
- `hero-section` — content
- `pagination` — content
- `refresh-trigger` — functional


### restate-marker — 감쌀 수 없어 마커+채움 짝을 재진술 (19)

- `button` — content
- `badge` — content
- `chat` — content
- `kbd` — content
- `validation-badge` — content
- `text-area` — content
- `text-field` — content
- `time-picker` — content
- `chip-input` — content
- `file-input` — content
- `phone-input` — content
- `sortable` — content
- `table` — content
- `draggable-panel` — functional
- `drawer` — functional
- `menubar` — functional
- `tab-pane` — content
- `tabs` — content
- `toast` — functional


## 조사 범위의 알려진 구멍

`disclosure_badge` 는 양 플랫폼에 공개 export 돼 있는데 docs 카탈로그에 없어
138 목록에서 빠졌다. `CoreDisclosureBadgeStyle` 에 `backgroundColor` 필드가
아예 없는 아웃라인 전용 칩이라 채움을 publish 할 수 없어 들어왔더라도
`exclude` 였을 항목이다 — 결론은 안 바뀌지만 **목록이 카탈로그와 같지
컴포넌트 전체와 같지는 않다**는 사실은 남긴다.
