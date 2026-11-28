---
title: Accordion
description: 제목을 누르면 본문이 펼쳐지는 섹션을 세로로 쌓은 목록입니다. 기본은 한 번에 하나만 열립니다.
category: layout
platforms: [flutter, web]
related: [collapsible, disclosure, tabs]
tags: [accordion, expandable, panel, interactive]
template: v2
source: layout/accordion
---

# Accordion

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 항목을 여닫고, 만들어진 코드를 그대로 복사하세요.

<Playground component="accordion" />

`expanded`는 처음 상태라 한 번만 읽습니다. 그래서 플레이그라운드는 속성을 바꾸면 Accordion을 새로 만듭니다.

## 구조

Accordion은 `AccordionItem`을 위에서 아래로 놓습니다. 항목 사이와 마지막 항목 아래에는 구분선을 그립니다.

<Anatomy demo="accordion/anatomy">
<AnatomyItem part="container" name="Container">

목록 전체. 기본으로는 채움과 바깥 테두리가 없습니다.

</AnatomyItem>
<AnatomyItem select="[role=button]" name="header" side="left">

누르는 줄입니다. 위아래 여백이 16이고, 누르면 그 항목이 열리고 닫힙니다.

</AnatomyItem>
<AnatomyItem part="label" name="title">

`title` 글자. `labelXl`(15 · 500) · `onSurface`이고, 마우스를 올리면 밑줄이 생깁니다.

</AnatomyItem>
<AnatomyItem part="leading" name="chevron" side="right">

열림 표시. 16 크기의 아래 화살표이고 열리면 180° 돌아갑니다. 제목과의 사이는 20입니다.

</AnatomyItem>
<AnatomyItem select="[role=button] + div" name="content" side="right">

펼친 본문. 아래 여백이 16이고, 글자는 `bodySmall`(13) · `onSurface`입니다.

</AnatomyItem>
</Anatomy>

## 상태

<Preview demo="accordion/states" />

| 상태 | 화면 |
| --- | --- |
| 접힘 | 본문이 보이지 않고 화살표는 아래를 봅니다. |
| 펼침 | 본문이 보이고 화살표가 180° 돌아갑니다. |
| 마우스를 올림 | 제목에 밑줄이 생깁니다. |
| 키보드 포커스 | 머리 줄에 포커스 링을 그립니다. Flutter에서는 목록 상자가 상자 밖으로 나간 링을 자릅니다([알려진 제약](#알려진-제약)). |

<a id="동작-스펙-behavior"></a>

### 열기/닫기

- 머리 줄을 누르면 그 항목이 열리고 닫힙니다.
- `allowMultiple`이 `false`(기본)면 하나를 열 때 열려 있던 항목이 닫힙니다. `true`면 여러 항목을 함께 열어 둘 수 있습니다.
- 열린 항목은 컴포넌트가 스스로 기억합니다. 밖에서 열림을 정하는 값, 바뀔 때 알려 주는 콜백, 비활성 상태는 없습니다.
- Web은 열린 자리를 순서(몇 번째)로 기억합니다. 그래서 `items`의 순서를 바꾸거나 앞쪽에 항목을 넣고 빼면 같은 자리에 온 다른 항목이 열려 보입니다. Flutter는 `AccordionItem`에 `key`를 주면 열림이 항목을 따라가고, `key`가 없으면 Web처럼 자리에 남습니다.

<Preview demo="accordion/allow-multiple" />

`expanded: true`인 항목은 펼친 채로 시작합니다. 이 값은 한 번만 읽습니다. Flutter는 항목을 만들 때, Web의 `Accordion`은 자신을 만들 때 읽습니다. 나중에 값을 바꿔도 달라지지 않고, Web에서는 나중에 더한 항목에 `expanded: true`를 줘도 닫힌 채입니다.

<Note>

`allowMultiple: false`에서는 `expanded: true`를 한 항목에만 주세요. 둘 이상에 주면 두 플랫폼의 결과가 다릅니다. Flutter는 첫 화면을 그린 직후 마지막 항목만 남기고 닫습니다. Web은 모두 펼친 채로 시작합니다. 그 상태에서 열린 항목을 누르면 그 항목만 닫히고, 닫힌 항목을 열어야 나머지가 모두 닫힙니다.

</Note>

### 애니메이션

본문이 펼쳐지는 전환은 200ms(`CoreDuration.normal`), `CoreEasing.move`입니다. 화살표도 같은 시간 동안 도는데, Web은 같은 곡선을 쓰고 Flutter는 일정한 속도로 돕니다. Web에서는 본문의 안쪽 여백이 전환 없이 열 때 바로 붙고 닫을 때 바로 빠집니다. 시간은 `accordionStyle.duration`으로, 앱 전체는 `CoreAccordionTheme.style`로 바꿉니다. 동작 줄이기를 켜면 두 플랫폼 모두 500ms 이하의 전환은 바로 바뀝니다.

### 화살표 아이콘

- 색과 크기는 `chevronIconStyle`로 정합니다. `arrowIconStyle`은 크기만 읽습니다. 두 곳에 크기를 모두 주면 Flutter는 `chevronIconStyle`, Web은 `arrowIconStyle`의 크기를 씁니다.
- 색을 정하지 않으면 Flutter의 화살표는 `onSurface`이고, Web의 화살표는 머리 줄 글자색을 따릅니다. 그래서 `triggerStyle`로 글자색을 바꾸면 Web의 화살표만 함께 바뀝니다.
- 화살표 모양은 바꿀 수 없습니다.

<a id="변형-variants"></a>
<a id="아이콘-포함-커스텀-트리거"></a>

## 커스텀 헤더

`title`은 글자만 받습니다. 머리 줄에 아이콘처럼 다른 것을 함께 두려면 `trigger`를 씁니다. `trigger`를 주면 `title`은 그리지 않습니다.

| 플랫폼 | `trigger`에 넣는 것 |
| --- | --- |
| Flutter | `AccordionTrigger(child: …)`로 감싸면 여닫기 · 키보드 조작 · 펼침 상태 알림 · 화살표가 그대로 따라옵니다. 그 밖의 위젯을 넣으면 여닫기가 연결되지 않습니다. `AccordionTrigger`는 `AccordionItem`의 `trigger` 안에서만 씁니다. |
| Jaspr Web | 넣은 `Component`를 그대로 그립니다. 여닫기도 `aria-expanded`도 붙지 않고, 연결할 방법이 없습니다. 여닫는 머리 줄이 필요하면 Web에서는 `title`을 쓰세요. |

```dart
// Flutter
AccordionItem(
  trigger: AccordionTrigger(
    child: Row(
      children: [
        Icon(LucideIcons.user),
        const Gap.space8(),
        Text('개인 정보'),
      ],
    ),
  ),
  content: PersonalInfoForm(),
)
```

<a id="단일-항목-접기펼치기"></a>

`AccordionItem`은 `Accordion` 없이 혼자서도 여닫힙니다. 이때는 구분선이 없고, `Accordion`의 `accordionStyle` 대신 테마 값만 적용됩니다. 한 영역만 접으면 되는 화면에는 [Collapsible](/components/collapsible)이 더 맞습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

질문과 답, 설정의 갈래처럼 제목을 훑어보고 필요한 것만 펼쳐 읽는 목록에 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 데이터의 부모 · 자식 가지를 탐색할 때 | [Tree](/components/tree) |
| 한 영역만 접고, 열림을 코드가 정해야 할 때 | [Collapsible](/components/collapsible) |
| 항목이 서로 상관없이 열리고, 웹에서 스크립트 없이도 열려야 할 때 | [Disclosure](/components/disclosure) |
| 고른 패널 하나만 바꿔 보여 줄 때 | [Tabs](/components/tabs) |
| 본문 흐름 밖에 띄워야 할 때 | [Dialog](/components/dialog) · [Drawer](/components/drawer) |

### 접어도 되는 내용만 접기

<Split>

<Code language="dart" title="이렇게 하세요">
// 질문을 훑고 필요한 답만 펼쳐 봅니다.
Accordion(
  items: [
    for (final faq in faqs)
      AccordionItem(title: faq.question, content: Text(faq.answer)),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 꼭 입력해야 하는 폼은 접어 두면 놓치기 쉽습니다.
Accordion(
  items: [
    AccordionItem(title: '결제 정보', content: PaymentForm()),
  ],
)
</Code>

</Split>

항목 수에는 제한이 없습니다. 다만 사용자가 늘 읽어야 하고 접어도 아끼는 공간이 없는 섹션 하나는 접지 말고 그대로 보여 주세요.

<a id="faq-스타일"></a>
<a id="조합-예제"></a>

### 설정 화면

섹션마다 따로 열어 두어야 하면 `allowMultiple`을 켭니다.

```dart
Accordion(
  allowMultiple: true,
  items: [
    AccordionItem(title: '프로필 설정', content: ProfileSettingsForm()),
    AccordionItem(title: '알림 설정', content: NotificationSettingsForm()),
    AccordionItem(title: '보안 설정', content: SecuritySettingsForm()),
  ],
)
```

## 배치

폭은 놓이는 부모에 따라 정해집니다.

| 플랫폼 | 폭 |
| --- | --- |
| Flutter | 부모가 폭을 정해 주지 않으면 가장 넓은 머리 줄(제목 · 간격 · 화살표)이나 본문의 폭만큼이 됩니다. 부모가 허락하는 폭은 넘지 않습니다. 부모가 폭을 정해 주면(`SizedBox(width:)`, `crossAxisAlignment: CrossAxisAlignment.stretch` 등) 그 폭을 씁니다. |
| Jaspr Web | 블록 부모나 늘려 맞추는(stretch) 세로 flex에서는 폭을 채웁니다. 가로 flex의 자식이거나 부모가 늘이지 않으면(`items-start` 등) 내용 폭이 됩니다. 폭을 정하려면 감싸는 상자나 `classes` · `css`로 정합니다. |

### 본문 정렬

Flutter는 목록보다 좁은 본문을 **가운데**에 놓고, Web은 왼쪽에 놓습니다. Flutter에서 왼쪽에 맞추려면 본문이 폭을 채우게 합니다.

```dart
// Flutter
AccordionItem(
  title: '배송 안내',
  content: SizedBox(width: double.infinity, child: Text('2~3일 걸려요.')),
)
```

<Note>

Flutter의 Accordion은 폭을 정해 주지 않은 자리에서는 내용의 폭을 먼저 잽니다. 이때 커스텀 헤더나 본문에 `LayoutBuilder`처럼 자기 폭을 미리 알려 주지 못하는 위젯이 있으면 레이아웃 오류가 납니다. 그런 위젯을 넣을 때는 Accordion의 폭을 정해 주세요.

</Note>

<a id="스타일-시스템-style-system"></a>
<a id="파라미터와-스타일"></a>
<a id="시맨틱-vs-스타일"></a>

## 테마와 스타일

동작은 파라미터(`items` · `allowMultiple`)로, 겉모습은 `accordionStyle`(`CoreAccordionStyle`) 하나로 정합니다.

| 바꾸는 곳 | 필드 | 기본값 |
| --- | --- | --- |
| 목록 전체의 상자 | `backgroundColor` · `borderColor` · `borderWidth` · `borderRadius` | 채움 없음 · 테두리 0 · 모서리 0 |
| 머리 줄 | `triggerStyle`의 `padding` · `backgroundColor` · `labelStyle` · `foregroundColor` | 위아래 16 · `labelXl` · `onSurface` |
| 본문 | `contentPadding`의 좌우 · 아래, `contentTextStyle` | 아래 16 · `bodySmall` · `onSurface` |
| 화살표 | `chevronIconStyle` · `arrowIconStyle` · `iconGapStyle` | 16 · 간격 20 |
| 항목 사이 | `dividerColor` · `dividerThickness` · `itemSpacing` | `Divider`의 기본값 · 간격 없음 |
| 전환 | `duration` | 200ms |
| 포커스와 누름 | `clickableStyle` | 누를 때 줄어들지 않음 |

- `triggerStyle`은 표의 네 값만 읽습니다. 다른 `CoreButtonStyle` 필드는 효과가 없습니다.
- `contentPadding`의 `top`은 두 플랫폼 모두 쓰지 않습니다. 머리 줄과 본문 사이는 머리 줄의 아래 여백이 정합니다.
- 테두리를 보이려면 `borderColor`와 `borderWidth`를 함께 정합니다. Web의 Accordion은 선의 모양(`border-style`)을 정하지 않으므로, 앱의 CSS가 정하지 않으면 선이 보이지 않습니다. 이 문서 사이트에는 모든 요소의 선 모양을 정하는 CSS가 있습니다.
- `dividerColor`와 `dividerThickness` 가운데 하나만 정하면, Flutter는 나머지에 `Divider`의 기본값을 씁니다. Web은 두 값을 함께 정해야 합니다. 하나만 정하면 구분선이 보이지 않습니다.
- `itemSpacing`을 정하면 Flutter는 구분선 대신 그만큼의 간격을 둡니다. Web은 구분선을 남긴 채 그 위아래에 간격을 둬, 항목 사이가 간격의 두 배에 선 두께를 더한 만큼 벌어집니다.

### 코드 예

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>

```dart
Accordion(
  items: [
    AccordionItem(title: '자주 묻는 질문', content: Text('답변')),
  ],
  accordionStyle: CoreAccordionStyle(
    contentPadding: CoreEdgeInsets.only(bottom: CoreSpace.space24),
    dividerColor: CoreColor.token(CoreColors.outlineVariant),
    dividerThickness: CoreStrokeWidth.stroke1,
    triggerStyle: CoreButtonStyle(
      padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space12),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
    chevronIconStyle: CoreIconStyle(size: CoreIconSize.size20),
  ),
)
```

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
디자인 시스템 기본값
  → CoreComponentTheme.accordion.style   // 앱 전체
  → accordionStyle                       // Accordion 하나
```

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

만든 `Accordion`에 스타일을 이어 붙입니다.

| 체인 | 바꾸는 값 |
| --- | --- |
| `withStyle(CoreAccordionStyle(…))` | 넘긴 필드. 겹치면 뒤에 붙인 값이 이깁니다. |
| `.backgroundColor(…)` · `.borderColor(…)` · `.borderWidth(…)` | 같은 이름의 필드 |
| `.radius0` … `.radius9999` | `borderRadius`. 이름이 `CoreRadius` 상수와 같습니다. |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent` | `backgroundColor` |

Accordion에는 variant가 없어 이름이 색인 getter는 모두 **배경색**을 정합니다. `.outline`도 테두리가 아니라 `outline` 색의 배경입니다. 테두리는 `borderColor`와 `borderWidth`로 정합니다.

<Preview component="accordion" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class AccordionChainExample extends StatelessWidget {
  const AccordionChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor/borderWidth)까지.
        const Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).withStyle(
          const CoreAccordionStyle(
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHighest,
            ),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke2,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class AccordionChainExample extends StatelessComponent {
  const AccordionChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor/borderWidth)까지.
        Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).withStyle(
          const CoreAccordionStyle(
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHighest,
            ),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke2,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 머리 줄은 버튼(`Semantics(button: true)`)이고 펼침 상태를 함께 알립니다. 목록과 항목에는 역할이 없습니다. |
| Jaspr Web | 머리 줄은 `role="button"` · `tabindex="0"` · `aria-expanded`입니다. 목록과 항목의 `<div>`에는 역할이 없습니다. |

두 플랫폼 모두 머리 줄과 본문을 잇는 `aria-controls`, 본문의 `region` 역할, 제목 수준은 없습니다. 스크린 리더의 제목 목록에는 Accordion의 제목이 나오지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 머리 줄마다 한 번씩 멈춥니다. |
| `Enter` · `Space` | 포커스가 있는 항목을 여닫습니다. |
| 화살표 · `Home` · `End` | 머리 줄 사이를 옮기는 기능은 없습니다. |

Flutter에서 화살표로 포커스가 옮겨진다면 그것은 앱의 방향 이동이지 Accordion의 동작이 아닙니다.

### 스크린 리더

- 머리 줄의 이름은 `title` 글자입니다. 커스텀 헤더는 안에 넣은 내용이 이름이 됩니다.
- Web은 접힌 본문이 읽히지 않습니다. Flutter는 접힌 본문을 접근성 트리에서 빼는 처리를 따로 하지 않습니다. 화면 밖으로 잘려 빠지는 경우가 많지만, `ListView`의 항목이나 `Semantics(container: true)` 안에서는 접힌 본문의 글자도 읽힙니다.
- 여닫은 결과를 따로 알리지 않습니다. 펼침 상태는 머리 줄에 붙어 있습니다.
- 구분선은 장식이라 읽히지 않습니다.

### 포커스 관리

- 여닫을 때 포커스를 옮기거나 가두지 않습니다.
- 접힌 본문 안의 요소는 Tab 순서에서 빠집니다. Flutter는 접히는 전환이 끝나면, Web은 닫는 순간에 빠집니다.
- 본문 안에 포커스가 있는 항목이 닫히면, Flutter는 전환이 끝난 뒤 본문 밖에서 직전에 포커스가 있던 곳으로 돌립니다. 방금 누른 머리 줄이 아닐 수 있습니다. Web은 포커스를 되돌리지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `trigger`를 넣은 항목은 머리 줄로 여닫을 수 없고 `aria-expanded`도 없습니다. |
| Jaspr Web | 머리 줄(버튼)과 접히는 상자에는 속성을 더할 수 없어 `aria-controls`를 잇거나 머리 줄을 제목으로 만들 수 없습니다. `AccordionItem(attributes: …)`는 항목을 감싼 `<div>`에만 붙습니다. |
| Flutter | `ListView`의 항목이나 `Semantics(container: true)` 안에서는 접힌 본문의 글자도 읽힙니다. |
| Flutter | 머리 줄의 포커스 링이 목록 상자에서 잘립니다. 좌우 선은 늘 잘리고, 첫 항목은 위 선, 접힌 마지막 항목은 아래 선도 잘립니다. 그래서 접힌 항목이 하나뿐이면 기본값에서는 링이 보이지 않습니다. |

> 동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 영역처럼 모든 컴포넌트에 걸리는 내용은 [접근성](/accessibility) 페이지가 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`Accordion` · `AccordionItem`의 공통 파라미터는 같습니다. `AccordionTrigger`는 Flutter에만, HTML 속성과 DOM 이벤트는 Web에만 있습니다. 그리는 방식과 몇 가지 동작도 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 커스텀 헤더 | `AccordionTrigger`로 여닫기를 잇습니다. | `trigger`에는 여닫기가 붙지 않습니다. |
| 한 번에 하나일 때 `expanded` 여러 개 | 마지막 항목만 남깁니다. | 모두 펼친 채로 시작합니다. |
| `expanded`를 읽는 때 | 항목을 만들 때 | `Accordion`을 만들 때(혼자 쓰는 항목은 항목을 만들 때) |
| 열린 항목을 기억하는 기준 | 항목의 `key`(없으면 순서) | 순서(몇 번째) |
| 본문 정렬 | 목록보다 좁으면 가운데 | 왼쪽 |
| 구분선 값을 하나만 정할 때 | 나머지는 `Divider` 기본값 | 구분선이 보이지 않습니다. |
| `itemSpacing` | 구분선을 빼고 간격을 둡니다. | 구분선을 남기고 그 위아래에 간격을 둡니다. |
| 화살표 회전 | 일정한 속도 | `CoreEasing.move` |
| 접힌 본문과 스크린 리더 | 놓인 자리에 따라 읽힐 수 있습니다. | 읽히지 않습니다. |
| 포커스가 든 본문이 닫힐 때 | 직전 위치로 돌립니다. | 되돌리지 않습니다. |
| 화살표 크기를 두 곳에 줄 때 | `chevronIconStyle` | `arrowIconStyle` |
| 화살표 색(비웠을 때) | `onSurface` | 머리 줄 글자색 |
| 부모가 폭을 정하지 않을 때 | 내용의 폭 | 블록 부모 · 늘려 맞추는 세로 flex는 가득, 그 밖의 flex 자식은 내용 폭 |
| 펼침 전환 | `SizeTransition` | CSS `grid-template-rows` 전환 |
| 접힌 본문을 Tab 순서에서 빼는 때 | 접히는 전환이 끝난 뒤(`ExcludeFocus`) | 닫는 순간(`inert`) |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 파라미터 |

<a id="props-parameters"></a>

## API

`W`는 Flutter에서는 `Widget`, Jaspr Web에서는 `Component`입니다.

<a id="accordion-파라미터"></a>

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<W>` | 필수 | `AccordionItem` 목록 |
| `allowMultiple` | `bool` | `false` | 여러 항목을 함께 열 수 있게 합니다. |
| `accordionStyle` | `CoreAccordionStyle?` | `null` | 겉모습 · 전환 시간 |

### AccordionItem

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `content` | `W` | 필수 | 펼쳤을 때의 본문 |
| `title` | `String?` | `null` | 머리 줄의 글자. `title`과 `trigger` 중 하나는 있어야 합니다. |
| `trigger` | `W?` | `null` | 직접 만든 머리 줄. 있으면 `title`은 그리지 않습니다. |
| `expanded` | `bool` | `false` | 처음 상태. 한 번만 읽습니다(Flutter는 항목, Web의 `Accordion`은 자신을 만들 때). |

### `AccordionTrigger` (Flutter)

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | 머리 줄의 내용. 여닫기와 화살표가 함께 붙습니다. |

### 그 밖의 멤버

- `withStyle(CoreAccordionStyle patch)` — `accordionStyle`에 `patch`를 합친 사본을 돌려줍니다.
- `copyWith(…)` — 바꾼 값으로 사본을 만듭니다.
- Web의 `Accordion`과 `AccordionItem`은 `id`(HTML id) · `classes` · `css` · `attributes` · `eventHandlers` 같은 HTML 속성과 `onClick` 같은 이벤트 파라미터도 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreAccordionStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `duration` | `Duration?` | Expand / collapse animation duration. |
| `arrowIconStyle` | `CoreIconStyle?` | Chevron / disclosure icon style override. `size` defers to [defaultArrowIconStyle]. |
| `backgroundColor` | `CoreColor?` | Container background colour for an expanded item. |
| `borderColor` | `CoreColor?` | Outer border stroke colour. |
| `borderWidth` | `double?` | Outer border stroke width (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Outer border radius. |
| `contentPadding` | `CoreEdgeInsets?` | Padding applied to expanded content. |
| `itemSpacing` | `double?` | Vertical spacing between accordion items (logical px) — native `Column.spacing` (Flutter) / `row-gap` (Web). When `null` items share a divider line instead of a gap. |
| `dividerColor` | `CoreColor?` | Divider line colour between items. |
| `dividerThickness` | `double?` | Divider line thickness (logical px). |
| `triggerStyle` | `CoreButtonStyle?` | Look of each trigger row — its padding, fill, label text style and label colour. Laid over [defaultTriggerStyle]. |
| `contentTextStyle` | `CoreTextStyle?` | Expanded content text style (applied when the content is a plain string). |
| `chevronIconStyle` | `CoreIconStyle?` | Chevron / disclosure icon style (the rotating indicator). |
| `iconGapStyle` | `CoreGapStyle?` | 1-off spacer between the trigger label and the chevron icon — rendered by `Gap` (Flutter) / inline `gap` CSS (Web). Defers to [defaultIconGapStyle]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the trigger's `Clickable` — press scale, focus ring, cursor, keyboard activation. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

`backgroundColor`는 펼친 항목 하나가 아니라 목록 전체의 상자를 칠합니다. `contentPadding`은 `top`을 뺀 세 변에 적용됩니다. `contentTextStyle`은 본문이 글자 하나가 아니어도 적용되어, 안의 글자가 따로 정하지 않은 값을 물려줍니다. `clickableStyle`로 커서나 키보드 조작은 바꿀 수 없습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="accordion/related-collapsible" title="Collapsible">

영역 하나를 접고 펼칩니다. 열림을 코드에서 정할 수 있습니다.

</Card>
<Card demo="accordion/related-disclosure" title="Disclosure">

항목이 서로 상관없이 열립니다. 웹에서는 `<details>`로 그립니다.

</Card>
<Card demo="accordion/related-tabs" title="Tabs">

여러 패널 가운데 하나를 골라 바꿔 보여 줍니다.

</Card>
</Cards>
