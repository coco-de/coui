# 선택 컨트롤 라벨 타이포그래피 — 사이즈·굵기 결정

CoUI Design System — 2026.08 결정 사항 정리

## 1. 배경

체크박스 라벨이 얇아 보인다는 지적이 있었다. 근거로 제시된 화면은 Unibook 앱의
약관 동의 화면(`row_agreement`, Figma node `353:1503`)이었고, 그 화면의 텍스트가
CoUI 기본 `Checkbox` 라벨보다 굵고 크게 보였다.

이어서 "사이즈가 커질수록 폰트도 굵어져야 하지 않느냐"(xs/sm=Regular,
md/lg=Medium, 그 외=SemiBold)는 대안이 제시됐다. 이 문서는 그 대안을
**채택하지 않기로** 한 결정과 근거를 정리한다.

## 2. 조사 결과 — 지금 굵기(Medium/500)에 원래 근거가 있었나

없었다.

- `Checkbox`·`Toggle`·`RadioGroup` 라벨이 공유하는 `CoreFontWeight.medium`(500)은
  `c00d89600 feat: 🎨 coui_flutter DaisyUI 마이그레이션 (v0.1.0) (#8)` 커밋에서
  처음 들어왔다 — DaisyUI(Tailwind 기반 커뮤니티 킷)를 포팅하며 그대로 넘어온
  값이다.
- 이후 `849b7348c refactor(flutter): #2546 — deprecated Text chain getter 제거
  (#2615)`에서 `.sm().md()` → `.bodySmall().medium()`로 바뀐 것은 **chain API
  이름 교체**일 뿐, 굵기 값 자체를 다시 검토한 흔적은 없다.

즉 "여러 컴포넌트가 이 값을 공유한다"는 사실은 의도적 설계의 증거가 아니라,
한 번 들어온 값이 복사되고 이후 아무도 재검토하지 않았다는 사실만 보여준다.
이 문서가 존재하는 이유가 바로 그 재검토다.

## 3. 레퍼런스 재검토 — `row_agreement`는 기본 `Checkbox`가 아니다

`row_agreement`는 Unibook 파일의 `900 components-도메인 컴포넌트` 페이지에 있는
**Unibook 전용 조합 컴포넌트**다. CoUI의 기본 `Checkbox` 프리미티브가 아니다.

| | `row_agreement` (Unibook 도메인) | `Checkbox` (CoUI 기본) |
|---|---|---|
| 폰트 굵기 | Pretendard SemiBold (600) | Medium (500) |
| 폰트 크기 | 16~18px | 사이즈별 10~20px (아래 §5) |
| 위치 | 약관 동의 전용 화면 | 범용 selection control |
| 부가 요소 | `(필수)`/`(선택)` 태그 텍스트 | 없음(별도 슬롯) |

크고 진한 도메인 합성 컴포넌트를 작고 범용적인 기본 프리미티브와 1:1로 비교한
것이었다. 굵기·크기가 다른 건 두 컴포넌트가 다른 목적을 갖기 때문이지, 기본
`Checkbox` 쪽이 잘못됐다는 신호가 아니다.

## 4. "사이즈가 커지면 굵어져야 한다"는 CoUI 자체 타이포 스케일과 맞지 않는다

`packages/coui_core/lib/src/typography/typography_scale.dart`의 실제 값:

| Role | 굵기 |
|---|---|
| `displayLarge` (가장 큰 role) | **Light (300)** |
| `headlineLarge` / `titleLarge` | SemiBold (600) |
| `bodyLarge` / `bodyMedium` / `bodySmall` | Regular (400) — **세 사이즈 전부 동일** |
| `labelLarge` / `labelMedium` / `labelSmall` | Regular (400) — **세 사이즈 전부 동일** |

두 가지가 드러난다:

1. **가장 큰 role(`displayLarge`)이 가장 가볍다(Light).** "커질수록 굵게"는
   CoUI의 role 스케일에 이미 존재하지 않는 패턴이다.
2. **굵기는 role(의미)에서 오지, 그 role 내부의 사이즈 단계에서 오지 않는다.**
   `body*`/`label*` 계열은 large/medium/small 세 단계 내내 굵기가 고정이다.

체크박스 라벨이 쓰는 `bodySmall`은 이 `body` 계열이다. Checkbox의 사이즈 축
(`xs`~`xl2`)은 이 계열 안에서 **렌더 크기만 바뀌는 것**이지 다른 role로
전환되는 게 아니므로, CoUI 자체 스케일의 선례를 따르면 사이즈가 바뀌어도 굵기는
고정이어야 한다.

## 5. 현재 구현 — `Checkbox` / `Toggle` / `RadioGroup` 셋 다 동일 패턴

### Core — 사이즈는 `fontSize`만, 굵기는 관여하지 않음

`packages/coui_core/lib/src/component/contracts/checkbox/checkbox_style.dart`:

```dart
xs: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s10),
sm: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
md: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
lg: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
xl: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s18),
xl2: labelStyle: CoreTextStyle(fontSize: CoreFontSize.s20),
```

`fontWeight` 필드 자체가 없다 — 이 사이즈 사다리가 애초에 "사이즈만 스케일,
굵기는 role/위젯이 고정으로 책임진다"는 전제로 설계됐다는 뜻이다.

### 위젯 — 셋 다 같은 chain

| 컴포넌트 | 파일 | 굵기 적용 |
|---|---|---|
| `Checkbox` | `checkbox.dart:412` | `Flexible(child: content.bodySmall().medium())` |
| `Toggle` | `toggle.dart:290` | `Flexible(child: effectiveSuffix.bodySmall().medium())` |
| `RadioGroup` | `radio_group.dart:592,616` | `resolved.labelStyle` → `Text(widget.label!, style: mergedLabelStyle)` |

세 컴포넌트가 독립적으로 각자 Medium을 고른 게 아니라, 같은 `.bodySmall()` role
+ `.medium()` 오버레이 chain을 그대로 복사한 것이다. 이 사실은 §2의 결론(공유는
설계 의도의 증거가 아니다)과 §4의 근거(role 내부 사이즈 단계는 굵기 불변)를
셋 다에 동시에 적용해야 한다는 뜻이기도 하다 — Checkbox만 따로 바꾸면 셋 사이에
새로운 비일관성이 생긴다.

## 6. 결정

1. **Checkbox의 사이즈 축(`xs`~`xl2`)에 굵기를 결합하지 않는다.** `fontSize`만
   스케일하고 `fontWeight`는 role 고정값(Medium)을 유지한다 — §4의 CoUI 자체
   `body`/`label` role 스케일 선례를 따른다.
2. **`row_agreement`류 도메인 컴포넌트와의 비교로 기본 프리미티브 굵기를
   조정하지 않는다.** 도메인 컴포넌트는 자기 컨텍스트(약관 동의 등)에 맞는
   자기 값을 갖는 것이 정상이다 — §3.
3. **Checkbox·Toggle·RadioGroup은 굵기를 바꾸면 셋 다 같이 바꾼다.** 하나만
   바꾸는 것은 새 비일관성을 만든다 — §5.

## 7. 기각된 대안

| 대안 | 기각 이유 |
|---|---|
| 사이즈 축 전체에 굵기 결합 (xs/sm=Regular, md/lg=Medium, 그 외=SemiBold, "커질수록 굵게") | CoUI 자체 role 스케일과 정반대 방향(§4) — `displayLarge`가 가장 크면서 가장 가볍다 |
| 작은 사이즈만 가독성 보정으로 굵게(2단 구성, xs/sm=SemiBold·나머지=Medium) | 광학적으로는 근거가 있으나(작은 사이즈의 얇은 획은 화면에서 흐려 보임), §5의 "사이즈 사다리는 fontSize만" 전제를 깨고 Core `labelStyle`에 `fontWeight` 필드를 새로 추가해야 함. 지금 시점엔 채택하지 않음 — 필요성이 실측으로 확인되면 재검토 |
| `row_agreement` 기준으로 Checkbox 기본 굵기를 SemiBold로 상향 | §3 — 비교 대상이 같은 층위(기본 프리미티브)가 아님 |

## 8. 판정 기준 (앞으로 이 라벨 굵기를 다시 건드릴 때)

- **사이즈 축이 같은 role 안에서 크기만 바꾸는 경우** → CoUI의 `body`/`label`
  role 선례(§4)를 따라 굵기는 고정. 예외를 두려면 이 문서에 새 절로 등재하고
  실측(가독성 테스트 등) 근거를 남긴다 — 등재 없이 코드만 바뀌면 그건 결정이
  아니라 표류다(같은 원칙을 쓰는 `decision-log-state-layer-opacity.md` §3 참조).
- **도메인 전용 컴포넌트(Unibook `row_agreement`류)의 굵기**는 CoUI 기본
  프리미티브의 굵기를 바꿀 근거가 되지 않는다. 그 컴포넌트가 CoUI 위에 합성한
  것이라면, 자기 컨텍스트에 맞는 값을 자기 레벨에서(예: `Text(...).semibold`
  체인 오버라이드) 가져가면 된다.
- **Checkbox/Toggle/RadioGroup 중 하나의 굵기를 바꾸려면** 나머지 둘도 같이
  검토한다 — 셋이 같은 chain을 공유하는 한, 하나만 바뀌는 것은 새 비일관성이다.

## 같이 보기

- `decision-log-state-layer-opacity.md` — 같은 형식의 결정 문서, "등재되지 않은
  예외는 표류" 원칙의 원본.
- `packages/coui_core/lib/src/typography/typography_scale.dart` — role별 굵기
  정의(§4 근거).
- `packages/coui_core/lib/src/typography/font_weight.dart` — `CoreFontWeight`
  숫자값(regular=400 / medium=500 / semiBold=600 / bold=700).
- `packages/coui_core/lib/src/component/contracts/checkbox/checkbox_style.dart` —
  사이즈별 `labelStyle` 정의(§5).
