# Spec — 전 컴포넌트 글래스 적용

범위: **A(판) + B(컨트롤) 전부**, 양 플랫폼. 대비 정책: **현행 하한 유지 —
못 지키는 것은 유리를 안 준다** (사용자 결정).

## 1. "제대로 적용됐다"의 정의

한 컴포넌트가 통과 판정을 받으려면 **다섯 개 전부**:

1. 자기 박스를 손으로 그리지 않고 표면 프리미티브를 **합성**한다 —
   또는 DOM 재구조가 필요해 합성이 불가하면 마커와 채움 publish 를
   `alert` 처럼 **짝으로** 재진술한다(둘 중 하나만은 금지 — 마커만 달면
   프리셋 규칙이 아무도 설정 안 한 변수를 참조해 배경이 사라진다).
2. **양 플랫폼 같은 변경에서** 닿는다. 한쪽만은 파리티 갭이다.
3. 비-유리 프리셋(default · neoBrutalism · claymorphism · neumorphism)에서
   **렌더가 한 픽셀도 안 바뀐다.**
4. 대비 하한을 지킨다 — 아래 §3.
5. edge band · stroke 억제 · forced-colors 폴백이 따라온다 (합성하면 공짜).

## 2. 측정된 사실 — 중첩은 막지 않는다

레포 메모에 "조상 필터가 backdrop root 를 새로 만들어 안쪽 유리가
불투명해진다"가 있었다. **브라우저에서 재보니 이 경로에서는 아니다** —
유리 카드 안의 유리 버튼은 카드 뒤 배경을 그대로 통과시킨다.

그 메모는 *ancestor 에 `filter` 를 건* 경우(gooey merge 실험)의 관찰이고,
`backdrop-filter` 중첩은 다른 경우다. 그래서 **A+B 는 기술적으로 막히지
않는다.**

## 3. 진짜 제약은 전경색이다

유리 카드 안 primary 버튼을 유리로 만들고 전경을 그대로 두면:

| | 대비 (하한 4.5) |
|---|---|
| 흰 글자 / 40% 유리 채움 | **1.13** ❌ |
| 어두운 글자 / 같은 채움 | **14.73** ✅ |

tinted glass(강조색을 알파로 깐 유리)도 재봤다. 흰 글자 기준, **밝은 배경
위에서는 알파 1.0(=불투명) 전까지 하한을 못 넘는다**:

| 알파 | 밝은 배경 | 어두운 배경 |
|---|---|---|
| 0.4 | 1.88 ❌ | 9.12 |
| 0.7 | 2.90 ❌ | 6.50 |
| 0.9 | 3.94 ❌ | 5.17 |
| 1.0 | 4.63 ✅ | 4.63 |

### 그래서 규칙 (결정됨) — 채움만 보던 게 틀렸다

앞선 표는 가정이 하나 숨어 있었다: **채움만이 글자와 배경 사이에 있다.**
유리는 그렇지 않다. `backdrop-filter` 는 뒤를 *어둡게* 할 수 있고, 그러면
채움을 키우지 않고도 흰 글자가 하한을 넘는다.

그래서 재질에 항이 하나 는다 — **이 재질이 뒤를 얼마나 어둡게 하는가.**

| 알파 | 밝기 | 흰 페이지 | 밝은 카드 | 사진 | 다크 |
|---|---|---|---|---|---|
| 0.30 | 1.00 (오늘) | 1.46 ❌ | 1.64 | 3.38 | 10.27 |
| 0.65 | **0.25** | **6.16** | **6.29** | **7.06** | **8.12** |

브라우저에서 확인했고 모델과 렌더가 일치했다.

### 기준선은 4.5 가 아니라 4.63 이다

출하 중인 **불투명** primary 버튼의 대비가 4.63 이다 — 이미 하한 바로
위다. 그러니 판정은 "하한을 넘나"가 아니라 **"오늘보다 나빠지지 않나"**다.

### 고른 값: 알파 0.65 / 밝기 0.25

조건 셋으로 좁혔다 — 대비 ≥ 4.63 · 채도 ≥ 솔리드의 60% · 그 안에서 알파
최소. 51 조합이 통과했고 최소 알파가 0.65 다. 최악 대비 6.16(오늘 대비
+33% 여유), 채도는 솔리드의 65%.

채도 조건은 필수다. 빼고 "가장 투명한 것"만 최적화하면 알파 0.20 을
고르는데, 대비 8.80 으로 통과하면서 **채도 11.3 의 회색 버튼**이 된다 —
밝기가 대비를 혼자 지면 색이 사라진다.

### 폐기된 것

- "포화 채움 컨트롤은 유리를 못 준다" — 폐기. 제외 없이 A+B 전부 간다.
- "primary 전경을 어둡게 바꾼다" — 폐기. 흰 글자 그대로 유리가 된다.

### 이건 이 스타일의 재해석이지 전역 결정이 아니다

다른 프리셋(default · neoBrutalism · claymorphism · neumorphism)에서
primary 버튼은 한 픽셀도 안 바뀐다. 규칙이 사는 자리는 컴포넌트가 아니라
**리퀴드 글래스 레시피**이고, 컴포넌트는 축의 존재를 계속 모른다.

판정 단위는 **variant** 다 — 어떤 variant 가 포화 채움을 갖는지에 따라
밝기 항이 필요한지가 갈린다.

## 4. 모호함 제거 — 명시적으로 범위 밖

- 글리프·인디케이터·래퍼·레이아웃: `loading` `skeleton` `progress`
  `dot_indicator` `triple_dots` `scrollbar` `focus_outline` `clickable`
  `text_block` `divider` `gap` `hidden` `media_query` `breakpoint`
  `stack_layout` `responsive_*`
- 이유: 재질은 "이 표면은 무엇으로 만들어졌나"라는 진술이고, 스피너에
  대해서는 그 진술이 참이 아니다.

## 5. 검증 방법 (게이트)

- 기존 대비 가드가 208 쌍(정상 2모드 + 고대비 2모드)을 감사한다 —
  유리 variant 가 늘면 그 감사 대상이 늘어난다.
- `surface_cast_audit.sh` 가 전 컴포넌트를 돌며 박스 없는 캐스트와
  캐스트 없는 마커를 잡는다.
- 마커/채움 짝 가드가 둘 중 하나만 있는 상태를 막는다.
- 비-유리 프리셋 무변경은 파리티 스냅샷으로 확인한다.

---

# 부록 — Apple HIG 대조 (사용자 제시)

명세를 확정한 뒤 HIG 를 읽었고, **네 군데가 바뀐다.**

## 1. 내가 유도한 밝기 항 = Apple 의 `regular` 변형

> *"The **regular** variant blurs and **adjusts the luminosity of background
> content** to maintain legibility of text and other foreground elements.
> Most system components use this variant."*

측정으로 도달한 "뒤를 얼마나 어둡게 하는가" 항이 Apple 이 `regular` 라고
부르는 것의 정의 그대로다. 독립적으로 같은 메커니즘에 도착했다는 뜻이라
이 항은 유지한다.

## 2. 변형이 하나가 아니라 둘이다

우리는 재질이 하나뿐이다. Apple 은 둘이다:

| | 무엇 | 언제 |
|---|---|---|
| **regular** | blur + 휘도 조정 | 배경이 가독성을 해칠 수 있을 때, 텍스트가 많은 것 — alert · sidebar · popover |
| **clear** | 매우 투명, 휘도 조정 없음 | 사진·영상 위에 뜨는 것 |

그리고 clear 에는 숫자가 붙어 있다:

> *"If the underlying content is bright, consider adding a **dark dimming
> layer of 35% opacity**."*

## 3. 유리 위의 버튼은 **더 얇은** 재질을 쓴다

> *"When a button appears on top of a glass window, use the **thin
> material** as the button's background."*
> *"When a button appears floating in space, use the **glass material**."*
> *"The **exception** is a button in a toolbar, context menu, alert, or
> ornament where the shape and material of the larger component make the
> button comfortably visible."*

버튼의 재질은 variant 가 아니라 **무엇 위에 앉았는지**가 정한다. 그리고
다이얼로그·메뉴 안의 버튼은 컨테이너의 재질이 이미 보이게 해주므로
자기 채움이 아예 필요 없을 수도 있다 — 원래 질문("다이얼로그 안 버튼은 왜
유리가 아니야")의 정답이 "유리여야 한다"가 아니라 "**컨테이너가 이미
그 일을 하고 있으면 채움이 없는 게 맞다**"일 수 있다는 뜻이다.

## 4. 그리고 범위 자체에 반대한다

> *"**Don't use Liquid Glass in the content layer.** … including it in the
> content layer can result in unnecessary complexity and a confusing visual
> hierarchy. Instead, use **standard materials** for elements in the content
> layer, such as app backgrounds."*
>
> *"**Use Liquid Glass effects sparingly.** … overusing this material in
> multiple custom controls can provide a subpar user experience by
> distracting from that content. **Limit these effects to the most important
> functional elements.**"*

Apple 의 구조는 두 층이다 — 콘텐츠 위에 떠 있는 **기능층**(탭바 · 사이드바
· 툴바 · 네비게이션 · 오버레이)만 Liquid Glass 이고, **콘텐츠층**(카드 ·
앱 배경 · 본문 패널)은 표준 재질이다.

예외로 명시된 것 하나: *"controls in the content layer with a transient
interactive element like sliders and toggles; in these cases, the element
takes on a Liquid Glass appearance **when a person activates it**"* —
콘텐츠층 컨트롤은 **누르는 동안만** 유리가 된다.

이건 "A+B 전부"라는 이 문서의 범위 결정과 정면으로 다르다. 결정은
사용자 몫이고, 이 부록은 근거만 싣는다.
