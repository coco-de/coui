---
title: PhoneInput
description: 국가 선택과 번호 입력을 한 상자에 담은 전화번호 입력입니다. 국가 번호가 필요한 전화번호를 받을 때 씁니다.
category: form
platforms: [flutter, web]
related: [text-field, select]
tags: [interactive, form-control, phone]
template: v2
source: form/phone_input
---

# PhoneInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 PhoneInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="phone-input" />

미리보기에서 국가 번호를 눌러 나라를 바꾸거나, 번호 칸에 `+81` 처럼 `+` 로 시작하는 번호를 적어 보세요 — 국가 선택이 따라 바뀝니다. `initialCountry` · `initialNumber` 는 처음 값입니다. 만든 뒤에 다른 값을 넘기면 국가만 따라 바뀌고 번호 칸은 그대로입니다.

<a id="모양-양쪽-공통"></a>

## 구조

PhoneInput 은 상자 하나 안에 국가 선택, 얇은 구분선, 번호 칸을 차례로 놓습니다.

<Anatomy demo="phone-input/anatomy">
<AnatomyItem part="container" side="left" name="Container">

바깥 상자. 테두리와 채움은 이 상자만 그립니다 — 안의 번호 칸에는 테두리도 채움도 없습니다.

</AnatomyItem>
<AnatomyItem select="button" side="top" name="selector">

국가 선택. 국기, 국가 번호, 펼침 아이콘을 놓고, 누르면 국가 목록이 열립니다.

</AnatomyItem>
<AnatomyItem select="button + div > div" side="top" name="separator">

국가 선택과 번호 칸 사이의 얇은 구분선.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="input">

번호를 적는 칸. 비어 있으면 `placeholder` 를 보여 줍니다.

</AnatomyItem>
</Anatomy>

크기를 고르는 속성은 없습니다. 상자는 [TextField](/components/text-field) `lg` 크기의 높이(48)이고, 밀도가 compact 면 40, spacious 면 56 이 됩니다. `phoneInputStyle` 의 `height` 로 높이를 직접 주면 밀도와 상관없이 그 값입니다. 이 높이는 테두리를 포함한 값이고, Jaspr Web 에서는 페이지가 `box-sizing: border-box` 일 때 그렇습니다([플랫폼 차이](#플랫폼-차이)).

| 부분 | 기본값 |
| --- | --- |
| 상자 모서리 | 12 |
| 국가 선택의 안쪽 여백 | 앞 14 · 뒤 10 |
| 번호 칸의 안쪽 여백 | 앞뒤 12 |
| 국기 | 높이 14, 모서리 4 |
| 국기 · 국가 번호 · 펼침 아이콘 사이 | 6 |
| 국가 번호 · 번호 글자 | `bodyLarge` |
| 펼침 아이콘 | 12, `onSurfaceSubtle` |
| 구분선 높이 | 20 |

국가 목록 패널은 [ItemPicker](/components/item-picker) 의 패널과 같은 모양입니다 — 채움 `surfaceBright`, 테두리 `outlineVariant`, 모서리 12, 그림자 `lg`. 맨 위에는 검색 아이콘이 붙은 테두리 없는 검색 칸과 `Divider` 가 있고, 그 아래에 목록(안쪽 여백 6, 행 여백 8, 행 모서리 8)이 놓입니다. 고른 국가에는 `primary` 체크 표시가 붙습니다.

<a id="검색-양쪽-공통"></a>

## 국가 선택과 검색

처음 국가는 `initialValue` 의 국가, 없으면 `initialCountry`, 둘 다 없으면 대한민국(`+82`)입니다. `initialValue` 를 주면 `initialCountry` · `initialNumber` 보다 먼저 씁니다. `countries` 로 목록을 좁혀도 처음 국가는 바뀌지 않으므로, 목록에 없는 국가에서 시작하지 않게 `initialCountry` 를 함께 넘기세요.

```dart
PhoneInput(
  initialCountry: CoreCountry.unitedStates,
  initialNumber: '5551234567',
  onChanged: setPhone,
)
```

국가는 `CoreCountry` 로 지정합니다. `CoreCountry.byCode('JP')` 는 ISO 코드로 찾습니다 — 대소문자를 가리지 않고, 없는 코드면 `null` 을 돌려줍니다. 자주 쓰는 `CoreCountry.southKorea` · `CoreCountry.unitedStates` 는 상수이고, `CoreCountry.all` 에는 247개 항목이 들어 있습니다. `countries` 를 넘기지 않으면 이 전체 목록을 보여 줍니다. 그중 3개는 국가가 아닌 위성 · 국제망 항목(`code` 가 `GMS` 또는 `INT`)입니다. 목록에는 나오지만, 번호 칸에 `+882` 처럼 그 번호를 적어도 감지되지 않습니다.

국가 선택을 누르면 목록이 열리고, 맨 위의 검색 칸에서 국가 이름 · 국가 번호 · ISO 코드로 찾습니다. 대소문자를 가리지 않고 앞뒤 공백은 무시합니다. 목록을 닫으면 검색어는 비워집니다. 국가를 고르면 목록이 닫힙니다.

국가 이름은 영어입니다. 다른 언어의 이름이 필요하면 `countries` 에 직접 만든 목록을 넘기고, `initialCountry` 도 그 목록의 항목으로 주세요 — 코드 · 국가 번호 · 이름이 모두 같아야 같은 국가로 봅니다.

```dart
const korea = CoreCountry(code: 'KR', dialCode: '+82', name: '대한민국');

PhoneInput(
  countries: const [
    korea,
    CoreCountry(code: 'US', dialCode: '+1', name: '미국'),
  ],
  initialCountry: korea,
  onChanged: setPhone,
)
```

<a id="읽기-규칙-양쪽-공통"></a>

## 번호 읽기

`onChanged` 는 국가와 번호를 담은 `CorePhoneNumber` 를 넘깁니다.

| 값 | 뜻 |
| --- | --- |
| `country` | 고른 국가 |
| `number` | 국가 번호를 뺀 번호 |
| `countryCode` · `dialCode` | 국가의 ISO 코드(`KR`)와 국가 번호(`+82`) |
| `fullNumber` | `dialCode` 와 `number` 를 이은 문자열 |
| `value` | `number` 가 비어 있으면 `null`, 아니면 `fullNumber` |
| `toString()` | `number` 가 비어 있으면 빈 문자열, 아니면 `fullNumber` |

번호 칸의 글자는 고치지 않고, 값을 읽을 때만 국가 번호를 뗍니다. `filterPlusCode`(기본 `true`)는 칸의 글자가 고른 국가의 `+국가번호` 로 시작할 때 그 부분만 떼고, 나머지는 적은 그대로 둡니다. 같은 글자라도 국가를 바꾸면 새 국가 번호로 다시 읽습니다. 두 플랫폼은 같은 `CorePhoneNumber.fromInput` 으로 읽습니다.

| 번호 칸 (대한민국을 고른 상태) | `number` | `fullNumber` |
| --- | --- | --- |
| `1012345678` | `1012345678` | `+821012345678` |
| `+821012345678` | `1012345678` | `+821012345678` |
| `01012345678` | `01012345678` | `+8201012345678` |
| `821012345678` | `821012345678` | `+82821012345678` |
| `+8` (적는 중) | `+8` | `+82+8` |

<a id="왜-선행-0을-떼지-않나-0129-변경"></a>

### 앞자리 0 을 떼지 않는 이유

국내 번호 앞의 `0` 을 국제 번호에서 떼는지는 나라마다 다릅니다.

| 국가 | 번호 칸 | PhoneInput 의 `fullNumber` | 올바른 E.164 |
| --- | --- | --- | --- |
| 영국 | `07911123456` | `+4407911123456` | `+447911123456` (`0` 을 뗌) |
| 이탈리아 | `0612345678` | `+390612345678` | `+390612345678` (`0` 을 남김) |

두 번호는 모양이 같고 국가 번호만으로는 가를 수 없습니다. 가르려면 나라마다 국내 접두 번호를 적은 표가 필요한데, `CoreCountry`(`code` · `dialCode` · `name`)에도 그 원본 국가 데이터에도 그 정보가 없습니다. 그래서 PhoneInput 은 적은 그대로 읽습니다. `fullNumber` 가 E.164 형식이라고 가정하지 말고, 나라별 검사와 형식 맞추기는 따로 하세요. 국가 번호를 떼려면 `+` 를 붙여 적습니다 — 그래서 `onlyNumber` 가 켜져 있어도 맨 앞의 `+` 하나는 적을 수 있습니다.

<a id="타이핑으로-국가-감지-양쪽-공통"></a>

### 타이핑으로 국가 감지

번호 칸이 `+` 로 시작할 때만 국가 번호를 찾아 국가 선택을 바꿉니다. 가장 길게 맞는 국가 번호가 이기고, 답이 하나가 아니면 지금 선택을 그대로 둡니다. 찾는 범위는 `countries` 목록입니다.

| 번호 칸 (전체 목록) | 결과 |
| --- | --- |
| `+82…` | 대한민국 |
| `+81…` | 일본 |
| `+1242…` | 바하마 — `+1` 보다 긴 국가 번호 |
| `+1` · `+1416…` · `+1212…` | 그대로 — 미국과 캐나다가 같은 국가 번호를 씁니다 |
| `+44…` · `+7…` | 그대로 — 여러 항목이 같은 국가 번호를 씁니다 |
| `+8` | 그대로 — 맞는 국가 번호가 아직 없습니다 |
| `821012345678` | 그대로 — `+` 로 시작하지 않습니다 |

번호를 `+` 없이 적는 사용자의 국가는 바뀌지 않습니다. 답이 여럿일 때 어느 나라를 먼저 고를지 정하는 표는 두지 않습니다 — 어느 쪽을 골라도 다른 나라의 사용자에게는 매번 틀리기 때문입니다. 목록을 좁히면 답이 하나가 될 수 있습니다. 예를 들어 `countries` 가 대한민국과 미국뿐이면 `+1` 은 미국입니다.

국가 선택에서 직접 고른 국가는 번호 칸을 다시 고치기 전까지 유지됩니다. 칸에 다른 국가 하나를 가리키는 `+` 번호가 있으면, 다음 수정에서 그 국가로 바뀝니다. Flutter 는 글자를 고치지 않고 커서나 선택 범위만 옮겨도 다시 판정합니다. 같은 판정은 `CorePhoneCountryDetector.detect(text, countries)` 로 직접 부를 수 있습니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="포커스가-hover-를-이기는-방식-web"></a>

## 상태

바깥 상자의 테두리가 상태를 보여 줍니다. 비활성, Focus, Hover, 쉴 때 순서로 우선합니다.

<Preview demo="phone-input/states" />

<Note>

Hover · Focus 칸은 포인터나 키보드 없이도 보이도록, `phoneInputStyle` 에서 쉴 때의 테두리 색을 그 상태의 색으로 바꿔 그립니다. Focus 칸은 포인터를 올려도 색이 같도록 Hover 테두리 색도 함께 바꿉니다.

</Note>

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface` |
| Hover | 테두리가 `outline` 으로 진해집니다. 국가 선택에는 Hover 채움이 없습니다. |
| Focus | 테두리가 `primary` 로 바뀝니다. 굵기는 1 그대로이고 바깥 링은 그리지 않습니다. 포커스가 있으면 포인터를 올려도 `primary` 입니다. |
| 비활성 | 흐리게 만들지 않고 채움 `disabledContainer`, 테두리 `disabledOutline`, 국가 번호 · 펼침 아이콘 · 안내 글자 `disabledContent` 로 그립니다. 목록이 열리지 않고 Hover 에도 바뀌지 않습니다. |
| 구분선 | 상태와 상관없이 `outlineVariant`(`separatorColor`) |
| 목록의 행 | 포인터를 올린 행에 `surfaceContainerHigh` 채움을 깝니다. Jaspr Web 은 키보드로 옮긴 하이라이트도 같은 채움입니다. 고른 국가는 `primary` 체크 표시로 보여 줍니다. |
| 열고 닫기 | 국가 선택을 누르면 열리고, 다시 누르면 닫힙니다. 국가를 고르거나 바깥을 눌러도 닫힙니다. `Escape` 는 Jaspr Web 에서만 닫습니다. |

Jaspr Web 은 상자 안 어디에 포커스가 있어도 테두리를 `primary` 로 그립니다. 그래서 키보드로 국가 선택에 포커스해도 테두리가 바뀝니다. Hover 테두리 규칙은 포커스가 있는 동안 빠지도록 되어 있어, 두 규칙의 순서와 상관없이 Focus 색이 남습니다. 상태 색(`focusBorderColor` · `hoverBorderColor` · `hoverColor`)에 토큰이 아닌 색을 주면 그 PhoneInput 에만 적용되는 `<style>` 규칙으로 그립니다. 다만 쉴 때의 `borderColor` 에 토큰이 아닌 색을 주면 Jaspr Web 에서는 Focus 색이 보이지 않습니다([알려진 제약](#알려진-제약)).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

여러 나라의 전화번호를 받거나, 국가 번호를 따로 저장해야 할 때 씁니다. PhoneInput 은 번호를 국가와 번호로 나눠 줄 뿐, 번호가 맞는지 나라별로 검사하거나 E.164 형식으로 고치지 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 한 나라의 번호만 받을 때 | [TextField](/components/text-field) (`type: CoreInputType.tel`) |
| 정해진 자릿수 구간으로 나눠 받을 때 | [FormattedInput](/components/formatted-input) |
| 국가 선택과 번호 입력을 따로 다뤄야 할 때 | [Select](/components/select) 와 [TextField](/components/text-field) 를 함께 |

### 라벨과 안내

<Cards columns="2">
<Card demo="phone-input/do-form-field" tone="do" eyebrow="이렇게 하세요">

[FormField](/components/form-field) 로 라벨을 붙이고, `placeholder` 로 무엇을 적을지 안내합니다.

</Card>
<Card component="phone-input" tone="dont" eyebrow="이렇게 하지 마세요">

라벨도 안내도 없으면 무엇을 적어야 하는지 알기 어렵습니다.

</Card>
</Cards>

<a id="do"></a>

### 저장한 값 다시 채우기

국가와 번호를 함께 저장해 두었다면 `initialCountry` 와 `initialNumber` 로 나누지 말고 `initialValue` 하나로 넘기세요. `CorePhoneNumber` 의 생성자는 국가, 번호 순서의 위치 인자를 받습니다.

```dart
PhoneInput(
  initialValue: CorePhoneNumber(CoreCountry.byCode('KR')!, '1012345678'),
  onChanged: setPhone,
)
```

<a id="dont"></a>

### 앞자리 0 과 국가 번호

앞자리 `0` 이나 `+` 없이 적은 국가 번호가 저절로 떨어지기를 기대하지 마세요.

```dart
// 대한민국에서 시작할 때
PhoneInput(initialNumber: '0821012345678') // number: '0821012345678' 그대로
PhoneInput(initialNumber: '+821012345678') // number: '1012345678'
```

## 배치

PhoneInput 은 부모의 가로 폭을 채웁니다. 번호 칸은 `maxWidth`(기본 200)보다 넓어지지 않으므로, 부모가 넓으면 상자 안 번호 칸 뒤에 눌러도 입력되지 않는 빈자리가 남습니다. 감싸는 쪽의 폭을 줄이거나 `maxWidth` 를 키우세요. 이 폭은 번호 칸의 안쪽 여백을 포함하며, Jaspr Web 에서는 페이지가 `box-sizing: border-box` 일 때 그렇습니다([플랫폼 차이](#플랫폼-차이)).

목록 패널은 상자와 같은 폭으로 4 떨어진 아래에 열립니다. 화면 가장자리에 걸리면 뒤집거나 밀어서 보이게 하고, 페이지를 스크롤해도 닫히지 않습니다. 목록이 248 보다 길면 그 안에서 스크롤합니다(`popupMaxHeight`).

<a id="스타일-시스템-style-system"></a>
<a id="테마-커스터마이징-theme"></a>

## 테마와 스타일

보이는 값은 `phoneInputStyle`(`CorePhoneInputStyle`) 하나로 덮어씁니다. 안의 번호 칸 · 검색 칸 · 목록 패널은 각각 `numberFieldStyle`(`CoreTextFieldStyle`) · `searchFieldStyle`(`CoreTextFieldStyle`) · `popoverStyle`(`CorePopoverStyle`)로 넘깁니다.

<Split>

<Code language="dart" title="PhoneInput 하나만 바꾸기">
PhoneInput(
  phoneInputStyle: CorePhoneInputStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    maxWidth: 240,
  ),
  onChanged: setPhone,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    phoneInput: CorePhoneInputTheme(
      style: CorePhoneInputStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        flagGapStyle: CoreGapStyle(size: CoreSpace.space8),
        maxWidth: 240,
      ),
    ),
  ),
)
</Code>

</Split>

### 전화번호 값의 글자 스타일

번호 칸의 글자는 `numberFieldStyle.valueStyle` 로 바꿉니다. 두 플랫폼 모두 이 값을 안의 번호 칸에 넘깁니다.

```dart
PhoneInput(
  phoneInputStyle: const CorePhoneInputStyle(
    numberFieldStyle: CoreTextFieldStyle(
      valueStyle: CoreTextStyle(fontSize: 17, fontWeight: 600, lineHeight: 1.4),
    ),
  ),
)
```

`numberFieldStyle` 을 주지 않으면 테두리 · 채움이 없는 `bodyLarge` 칸입니다. 앱 전체 스타일과 인스턴스의 `numberFieldStyle` 은 필드마다 합쳐지고 인스턴스 값이 이깁니다. 검색 칸은 `searchFieldStyle` 로 따로 정합니다. 두 칸의 `placeholderStyle` 은 `placeholderColor` · `disabledPlaceholderColor` 보다 우선합니다. 목록의 국가 이름 글자는 `bodyTextStyle` 로 정합니다. 글자 스타일을 바꿔도 입력, 국가 선택, 비활성 동작은 달라지지 않습니다.

### 빠른 오버라이드 (Chain)

이미 만든 `PhoneInput` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `phoneInputStyle` 인자와 같게 동작합니다. `.radius16` · `.primary` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다 — `.radius16` 은 모서리를 `CoreRadius.radius16` 으로, `.primary` 는 채움을 `primary` 로 바꿉니다. 이름이 곧 값이라 어느 컴포넌트에서 써도 뜻이 같습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class PhoneInputChainExample extends StatelessWidget {
  const PhoneInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const PhoneInput(placeholder: '전화번호를 입력해 주세요').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        const PhoneInput(placeholder: '직접 지정').withStyle(
          const CorePhoneInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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
class PhoneInputChainExample extends StatelessComponent {
  const PhoneInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const PhoneInput(placeholder: '전화번호를 입력해 주세요').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        const PhoneInput(placeholder: '직접 지정').withStyle(
          const CorePhoneInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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

### 값이 정해지는 순서

```text
기본값 (CorePhoneInputStyle.default*)
  → CoreComponentTheme.phoneInput.style    // 앱 전체
  → phoneInputStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. 안의 TextField · Popover 는 각자 자기 테마를 먼저 받고, 그 위에 PhoneInput 이 넘기는 값이 얹힙니다. 그래서 `CoreTextFieldTheme` 의 테두리나 채움은 번호 칸에 보이지 않습니다 — PhoneInput 이 투명으로 덮습니다.

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 국가 선택을 이름이 "국가 선택" 인 버튼으로, 목록을 `listbox` 로 알립니다. Flutter 는 상자 전체에 "국가 선택" 이라는 이름을 붙입니다. 키보드로 목록에서 국가를 고를 수 있는 것은 Jaspr Web 뿐입니다.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 바깥 상자 | 이름이 "국가 선택" 인 `Semantics(container: true)` 하나가 국가 선택과 번호 칸을 함께 감쌉니다 | 역할 없는 `<div>` |
| 국가 선택 | 버튼 역할 없이 누르기만 받습니다(`MouseRegion` · `GestureDetector`) | `<button type="button">`, `aria-label` "국가 선택", `aria-haspopup="listbox"`, `aria-expanded` |
| 번호 칸 | 텍스트 필드, 전화번호 자동완성 힌트 | `<input type="tel">` |
| 검색 칸 | 텍스트 필드 | `<input>`, `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-autocomplete="list"`, `aria-activedescendant`. 이름은 검색 안내 문구("국가 검색")입니다 |
| 국가 목록 | 역할 없음(`ListView`) | `role="listbox"`, 이름 "국가 선택" |
| 국가 행 | 역할 없음 | `<button role="option">`, `tabindex="-1"`, `aria-selected` 는 하이라이트된 행 |
| 패널 | 감싸는 `Popover` 가 열림 여부(`expanded`)를 알립니다 | `role="dialog"`(이름 없음). 상자를 감싼 `<div>` 에 `aria-haspopup="dialog"` · `aria-expanded` |

"국가 선택" 과 검색 안내 문구는 앱의 언어를 따릅니다(영어는 `Select country` · `Search country...`).

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 번호 칸에만 닿습니다 | 국가 선택, 번호 칸 순서로 닿습니다 |
| `Enter` · `Space` (국가 선택) | 국가 선택에 포커스가 가지 않아 쓸 수 없습니다 | 목록을 열고 닫습니다 |
| `↓` · `↑` (검색 칸) | 국가를 옮기지 않습니다 | 하이라이트를 옮기고(끝에서 돌아감) 보이도록 스크롤합니다 |
| `Enter` (검색 칸) | 국가를 고르지 않습니다 | 하이라이트된 국가를 고르고 닫습니다 |
| `Home` · `End` · `←` · `→` (검색 칸) | 검색 칸의 커서를 옮깁니다 | 검색 칸의 커서를 옮깁니다 |
| `Escape` | 목록이 닫히지 않습니다 | 목록을 닫습니다 |
| 글자 입력 (검색 칸) | 목록이 바로 좁혀집니다 | 목록이 좁혀지고 첫 결과가 하이라이트됩니다 |

Jaspr Web 의 목록은 지금 국가를 하이라이트한 채로 열립니다. 하이라이트가 옮겨 가도 포커스는 검색 칸에 남고, `aria-activedescendant` 가 가리키는 행만 바뀝니다.

### 스크린 리더

- **이름** — Flutter 의 "국가 선택" 은 상자 전체의 이름이고, Jaspr Web 에서는 국가 선택 버튼의 이름입니다.
- **번호 칸** — 이름을 직접 주는 속성이 없습니다. Jaspr Web 에서는 `placeholder` 가 있으면 그것이 이름이 됩니다. 라벨이 필요하면 [FormField](/components/form-field) 의 `label` 로 붙입니다. 이 라벨은 PhoneInput 을 감싼 묶음의 이름이 됩니다 — Flutter 는 라벨을 단 `Semantics(container: true)` 이고, Jaspr Web 은 `role="group"` 입니다(`labelWidget` 을 함께 주면 Web 의 묶음에는 이름이 붙지 않습니다).
- **국가 행** — 국가 이름과 국가 번호 글자를 읽습니다. Jaspr Web 의 국기는 `aria-hidden` 인 장식입니다.
- **열림 상태** — Flutter 는 `expanded` 로, Jaspr Web 은 `aria-expanded` 로 알립니다. Web 버튼의 값은 닫은 뒤에도 남을 수 있습니다(알려진 제약).
- 국가가 바뀐 것을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

- 처음 보일 때 포커스를 가져가지 않습니다.
- 목록이 열리면 두 플랫폼 모두 검색 칸이 포커스를 받습니다. Flutter 의 검색 칸은 `autofocus` 이고, Jaspr Web 은 검색 칸으로 포커스를 옮긴 뒤 지금 국가가 보이도록 스크롤합니다.
- 목록을 닫을 때는 두 플랫폼 모두 포커스를 국가 선택으로 돌려주지 않습니다. Flutter 의 국가 선택은 포커스를 받지 않습니다.
- Jaspr Web 에서 마우스로 국가 선택을 눌러도 버튼은 포커스를 가져가지 않습니다 — 목록을 여닫을 때 테두리가 Focus 색으로 바뀌지 않게 하기 위해서입니다.
- Jaspr Web 은 포커스를 가두지 않습니다. `Tab` 으로 목록 밖으로 나가면 목록은 열린 채 남습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 국가 선택과 국가 행이 포커스를 받지 않아, 키보드로는 목록에서 국가를 고를 수 없습니다. 번호 칸에 `+81` 처럼 답이 하나인 국가 번호를 적거나, `initialCountry` · `initialValue` 로 정합니다. |
| Flutter | "국가 선택" 이름이 국가 선택이 아니라 상자 전체에 붙어, 번호 칸도 그 이름 아래에서 읽힙니다. |
| Flutter | `Escape` 로 목록이 닫히지 않습니다. |
| Flutter | 번호 칸의 커서나 선택 범위만 옮겨도 `onChanged` 가 불리고 국가를 다시 감지합니다. 칸에 다른 국가 하나를 가리키는 `+` 번호가 있으면, 목록에서 직접 고른 국가가 되돌아갑니다. |
| Flutter | `controller` 를 나중에 바꾸면 PhoneInput 이 만들었던 컨트롤러는 정리되지 않고, `controller` 를 빼면 번호 칸이 비워집니다. |
| Flutter | `phoneInputStyle` 의 `padding` · `popupMaxWidth` · `popupBorderRadius` · `popoverTopOffset` 은 적용되지 않습니다. 패널의 모서리와 간격은 `popoverStyle` 로 바꿉니다. |
| Jaspr Web | 국가 선택 버튼의 이름이 "국가 선택" 이라, 지금 고른 국가 번호는 버튼의 이름으로 전달되지 않습니다. |
| Jaspr Web | 검색어 없이 목록을 닫으면(`Escape`, 바깥 누르기, 국가 선택 다시 누르기) 국가 선택의 `aria-expanded` 가 `true` 로 남습니다. |
| Jaspr Web | 검색 결과가 없으면 안내 문구 없이 빈 목록만 보입니다. Flutter 는 "국가를 찾을 수 없어요" 를 보여 줍니다. |
| Jaspr Web | 쉴 때의 `borderColor` 에 토큰이 아닌 색을 주면, 포커스해도 테두리가 그 색 그대로라 `focusBorderColor` 가 보이지 않습니다. |
| Jaspr Web | 검색 칸의 `Enter` 는 입력기가 글자를 조합하는 중인지 확인하지 않습니다. 한글처럼 조합하는 입력에서 조합을 끝내려고 누른 `Enter` 가 국가를 고를 수 있습니다. |
| Jaspr Web | 비활성이어도 국가 선택 위의 포인터는 누를 수 있는 모양(손가락)입니다. |
| Jaspr Web | 번호 칸에 `autocomplete` 속성이 없습니다. Flutter 는 전화번호 자동완성 힌트를 줍니다. |
| 공통 | 번호 칸에 접근성 이름을 직접 줄 방법이 없습니다. Jaspr Web 의 `attributes` 는 바깥 상자에 붙습니다. |
| 공통 | 목록을 닫아도 포커스를 국가 선택으로 돌려주지 않습니다. Flutter 의 국가 선택은 포커스를 받지 않습니다. |
| 공통 | 목록 안에서 고른 행은 체크 표시로만 구분됩니다. Jaspr Web 의 `aria-selected` 는 하이라이트를 가리키고, Flutter 는 고른 상태를 따로 알리지 않습니다. |
| 공통 | `FormField(enabled: false)` · `Fieldset(enabled: false)` 로는 PhoneInput 전체가 꺼지지 않습니다. 번호 칸만 비활성이 되고, 바깥 상자와 국가 선택은 PhoneInput 의 비활성 색(`disabledContainer` · `disabledOutline` · `disabledContent`)으로 바뀌지 않습니다. 비활성 `Fieldset` 은 묶음 전체를 50% 로 흐리게 할 뿐 포인터를 막지 않아, 그 안에 바로 둔 PhoneInput 은 국가 선택이 열립니다. `FormField` 는 흐리게 하지 않고 포인터만 막으며, Jaspr Web 에서는 키보드로 국가 선택을 열 수 있습니다. 함께 끄려면 `PhoneInput(enabled: false)` 를 줍니다. |
| 공통 | 오류를 알리는 속성이 없고, 폼 검증에 실패해도 바깥 테두리는 바뀌지 않습니다. 오류 문구는 [FormField](/components/form-field) 가 보여 줍니다. |
| 공통 | 고른 국가와 맞지 않는 `+` 번호는 국가 번호가 겹칩니다 — 대한민국에서 `+447911123456` 을 적으면 `fullNumber` 가 `+82+447911123456` 입니다. `+44` · `+1` · `+7` 처럼 여럿이 함께 쓰는 국가 번호는 국가가 자동으로 바뀌지 않아 이렇게 됩니다. `PhoneValidator` 는 번호가 비었는지만 보므로 이 값도 통과합니다. |
| 공통 | `initialNumber` 는 처음 한 번만 읽습니다. `initialCountry` · `initialValue` 의 국가를 나중에 바꾸면 국가 선택만 바뀌고 `onChanged` 와 폼 값은 그때 갱신되지 않습니다. |
| 공통 | `countryGapStyle` 은 국가 선택과 번호 칸 사이를 벌리지 않습니다. |
| 공통 | 국가 이름은 영어입니다. 다른 언어는 `countries` 목록을 직접 만들어 넘겨야 합니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 같은 `PhoneInput` 과 `CoreCountry` 를 쓰고, 목록 패널은 둘 다 `Popover` 와 검색 `TextField` 로 만듭니다. 아래는 동작이나 구현이 다른 부분입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값 타입의 이름 | `PhoneNumber` (= `CorePhoneNumber`) | `PhoneInputValue` (= `CorePhoneNumber`) |
| 번호 칸 | 안의 `TextField`. `controller` 를 줄 수 있습니다 | 안의 `TextField`(`<input type="tel">`). `controller` 는 없습니다 |
| 입력 거르기 (`onlyNumber`) | `TextInputFormatters.phoneText` | `CoreInputFormatters.phoneText` |
| 모바일 키보드 | `onlyNumber` 면 전화 키패드, 아니면 일반 키보드 | 늘 `type="tel"` |
| 자동완성 | `AutofillHints.telephoneNumber` | `autocomplete` · `name` 속성 없음 |
| `onChanged` 가 불리는 때 | 번호 칸의 글자 · 커서 · 선택 범위가 바뀔 때와 목록에서 다른 국가를 고를 때 | 번호를 고칠 때와 목록에서 국가를 고를 때(같은 국가를 다시 골라도) |
| 폼이 값을 바꿔 넣을 때 | 번호 칸에 국가 번호를 붙인 전체 번호를 써넣습니다 | `onChanged` 만 부르고 번호 칸은 그대로입니다 |
| 국기 | `country_flags` 패키지의 그림(앱에 포함) | jsDelivr CDN 의 `flag-icons` SVG |
| 검색 결과가 없을 때 | 안내 문구 | 빈 목록 |
| 행의 국가 이름과 국가 번호 사이 | `dropdownItemGapStyle`(8) | `countryGapStyle`(16) |
| 긴 국가 이름 | 한 줄로 두고 말줄임 | 줄을 바꿉니다 |
| 높이와 번호 칸 최대 폭 | 높이는 테두리를, 번호 칸 폭은 안쪽 여백을 포함합니다 | `box-sizing` 을 정하지 않습니다. 페이지가 `border-box` 면 Flutter 와 같고, 브라우저 기본값(`content-box`)이면 계산상 높이에 위아래 테두리(합 2)가, 번호 칸 폭에 앞뒤 안쪽 여백(합 24)이 더해집니다 |
| 국가 선택의 키보드 조작 | 포커스를 받지 않습니다 | `<button>` 이라 `Tab` 으로 닿습니다 |
| `Escape` | 닫지 않습니다 | 닫습니다 |
| Hover 테두리 | 상자 위의 포인터를 감지해 `hoverBorderColor` 로 그립니다 | CSS `:hover:not(:focus-within)` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등(바깥 상자에 붙습니다) |

Jaspr Web 에서 국기를 자기 서버에서 불러오려면 `CouiAssetSourceScope` 로 감쌉니다. 경로에는 소문자 ISO 코드 이름의 SVG(`kr.svg`)를 둡니다.

```dart
CouiAssetSourceScope(
  flagIconsBaseUrl: '/assets/flags/4x3',
  child: PhoneInput(onChanged: setPhone),
)
```

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `controller` 만 Flutter 에 있습니다.

### 값과 국가

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `initialCountry` | `CoreCountry?` | `null` | 처음 국가. `null` 이면 대한민국(`+82`, `CorePhoneInputContract.defaultInitialCountry`)입니다. 나중에 다른 국가를 넘기면 국가 선택만 바뀝니다. |
| `initialNumber` | `String?` | `null` | 번호 칸의 처음 글자. 처음 한 번만 읽습니다. |
| `initialValue` | `PhoneNumber?` (Web `PhoneInputValue?`) | `null` | 국가와 번호를 한 번에 줍니다. `initialCountry` · `initialNumber` 보다 먼저 씁니다. |
| `countries` | `List<CoreCountry>?` | `null` | 목록 · 검색 · 국가 감지가 쓰는 국가들. `null` 이면 `CoreCountry.all` 입니다. |
| `onChanged` | `ValueChanged<PhoneNumber>?` (Web `CoreValueChanged<PhoneInputValue>?`) | `null` | 번호나 국가가 바뀌면 불립니다. 불리는 때는 [플랫폼 차이](#플랫폼-차이)를 보세요. |

Jaspr Web 의 `PhoneInput.defaultCountries` 는 `CoreCountry.all` 과 같은 목록입니다.

### 입력과 상태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `placeholder` | `String?` | `null` | 번호 칸의 안내 글자 |
| `enabled` | `bool` | `true` | `false` 면 비활성 모양으로 그리고, 번호를 고칠 수 없고 목록이 열리지 않습니다. |
| `onlyNumber` | `bool` | `true` | 숫자와 맨 앞의 `+` 하나만 적을 수 있습니다. |
| `filterPlusCode` | `bool` | `true` | 값을 읽을 때 고른 국가의 `+국가번호` 를 뗍니다. |
| `phoneInputStyle` | `CorePhoneInputStyle?` | `null` | 겉모습을 바꾸는 값 묶음 |

<a id="flutter-전용-파라미터"></a>

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `TextEditingController?` | `null` | 번호 칸의 컨트롤러. 넘기면 `initialNumber` 와 `initialValue` 의 번호는 쓰이지 않으니, 처음 글자는 컨트롤러에 담으세요. Web 은 브라우저의 `<input>` 이 편집을 맡아 이 속성이 없습니다. |

### CorePhoneNumber

`PhoneNumber`(Flutter)와 `PhoneInputValue`(Web)는 `CorePhoneNumber` 의 다른 이름이라, 한쪽에서 저장한 값을 다른 쪽에서 그대로 씁니다. 생성자는 `CorePhoneNumber(country, number)` 위치 인자입니다. `countryCode` · `dialCode` · `fullNumber` · `value` 는 두 값에서 나옵니다([번호 읽기](#번호-읽기)). PhoneInput 이 폼에 보고하는 값도 이 타입이며, 검색어는 보고하지 않습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `country` | `CoreCountry` | 필수 | 고른 국가 |
| `number` | `String` | 필수 | 국가 번호를 뺀 번호 |

### CoreCountry

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `code` | `String` | 필수 | ISO 2자리 코드(`KR`). `CoreCountry.all` 의 위성 · 국제망 항목 3개만 세 글자(`GMS` · `INT`)입니다 |
| `dialCode` | `String` | 필수 | `+` 를 포함한 국가 번호(`+82`) |
| `name` | `String` | 필수 | 목록에 보이는 이름 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CorePhoneInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `borderRadius` | `CoreBorderRadius?` | Outer border radius override. |
| `flagGapStyle` | `CoreGapStyle?` | Gap between the flag and the dial code inside the selector, passed to `Gap(gapStyle: …)`. |
| `countryGapStyle` | `CoreGapStyle?` | Gap between the country selector and the input field, passed to `Gap(gapStyle: …)`. |
| `maxWidth` | `double?` | Maximum width of the input row (logical px). |
| `padding` | `CoreEdgeInsets?` | Inner padding override. |
| `height` | `double?` | Outer container height override (logical px). |
| `borderWidth` | `double?` | Outer border stroke width override (logical px). |
| `inputFieldPadding` | `CoreEdgeInsets?` | Inner padding of the phone-number input field. |
| `selectorPadding` | `CoreEdgeInsets?` | Country selector trigger padding override. |
| `dropdownItemPadding` | `CoreEdgeInsets?` | Dropdown / search item padding override. |
| `dropdownItemGapStyle` | `CoreGapStyle?` | Gap between a dropdown item's flag and its country name, passed to `Gap(gapStyle: …)`. |
| `popupMaxWidth` | `double?` | Maximum width of the country picker popup (logical px). |
| `popupMaxHeight` | `double?` | Maximum height of the country picker popup (logical px). |
| `popoverTopOffset` | `double?` | Vertical offset between the trigger and the popup (logical px). |
| `chevronIconStyle` | `CoreIconStyle?` | Chevron icon style override — `size` defers to [defaultChevronIconStyle]. |
| `flagSize` | `double?` | Flag emoji font size in the selector (logical px). |
| `dropdownFlagSize` | `double?` | Flag emoji font size inside dropdown items (logical px). |
| `disabledOpacity` | `double?` | Opacity applied to the whole component when disabled. |
| `popupBorderRadius` | `CoreBorderRadius?` | Popup border radius override. |
| `dropdownDialCodeTextStyle` | `CoreTextStyle?` | Muted dropdown text style override — drives both the dropdown-item dial-code span and the "No results" empty hint (Flutter), and the dropdown-item dial-code span (Web). Both the typography role token and the text colour are carried inside this slot, overlaying [defaultDropdownDialCodeTextStyle]. |
| `backgroundColor` | `CoreColor?` | Outer container background fill override — defers to [defaultBackgroundColor]. |
| `borderColor` | `CoreColor?` | Outer container border colour override — defers to [defaultBorderColor]. The popup panel border rides [popoverStyle] and the selector↔input divider rides [separatorColor]. |
| `focusBorderColor` | `CoreColor?` | Outer container focused border colour override — defers to [defaultFocusBorderColor]. |
| `hoverBorderColor` | `CoreColor?` | Outer container border colour override while the pointer is over the field — defers to [defaultHoverBorderColor]. Outranked by the focused border ([focusBorderColor]) and absent while the field is disabled. Not the selector / row hover *background* — that is [hoverColor]. |
| `hoverColor` | `CoreColor?` | Hover background override (dropdown rows) — defers to [defaultHoverColor]. |
| `separatorColor` | `CoreColor?` | Selector↔input / picker divider colour override — defers to [defaultSeparatorColor]. |
| `placeholderColor` | `CoreColor?` | Placeholder text colour override (phone field + search input) — defers to [defaultPlaceholderColor]. |
| `chevronColor` | `CoreColor?` | Selector chevron icon colour override — enabled state, defers to [defaultChevronColor]. |
| `disabledChevronColor` | `CoreColor?` | Selector chevron icon colour override — disabled state, defers to [defaultDisabledChevronColor]. |
| `dialCodeTextStyle` | `CoreTextStyle?` | Selector dial-code label text style override — enabled state. Both the `labelLarge` role token and the `onSurface` colour live inside the slot, overlaying [defaultDialCodeTextStyle]. |
| `disabledDialCodeColor` | `CoreColor?` | Selector dial-code label colour override — disabled state, defers to [defaultDisabledDialCodeColor]. |
| `bodyTextStyle` | `CoreTextStyle?` | Country-name label text style override — defers to [defaultBodyTextStyle]. |
| `numberFieldStyle` | `CoreTextFieldStyle?` | Style override for the phone-number `TextField`. The default remains chromeless; use this slot for input typography without changing the country selector or search field. |
| `searchFieldStyle` | `CoreTextFieldStyle?` | Style override for the country-search `TextField` inside the dropdown. Defers to [defaultSearchFieldStyle], independently of [numberFieldStyle]. |
| `popoverStyle` | `CorePopoverStyle?` | Style for the country dropdown's `Popover` panel — its border, surface, corners and shadow are set through its `panelStyle`. Laid over [defaultPopoverStyle]. |
| `flagBorderRadius` | `CoreBorderRadius?` | Flag corner radius override — the flag glyph in the selector and in the list rows. `null` → [defaultFlagBorderRadius]. |
| `separatorHeight` | `double?` | Height override of the hairline between the selector and the number (logical px). `null` → [defaultSeparatorHeight]. |
| `disabledBackgroundColor` | `CoreColor?` | Outer container fill override while disabled. `null` → [defaultDisabledBackgroundColor]. |
| `disabledBorderColor` | `CoreColor?` | Outer container border colour override while disabled. `null` → [defaultDisabledBorderColor]. |
| `disabledPlaceholderColor` | `CoreColor?` | Number-field placeholder colour override while disabled. `null` → [defaultDisabledPlaceholderColor]. |
| `dropdownListPadding` | `CoreEdgeInsets?` | Padding of the country list inside the panel override. `null` → [defaultDropdownListPadding]. |
| `dropdownItemBorderRadius` | `CoreBorderRadius?` | Country row corner radius override. `null` → [defaultDropdownItemBorderRadius]. |
| `dropdownCheckIconStyle` | `CoreIconStyle?` | Style of the check glyph beside the selected country, laid over [defaultDropdownCheckIconStyle]. |
| `searchIconStyle` | `CoreIconStyle?` | Style of the search glyph in front of the country search field, laid over [defaultSearchIconStyle]. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 몇 설명은 지금 동작과 다릅니다.

- `flagGapStyle` — 국기와 국가 번호 사이뿐 아니라 국가 번호와 펼침 아이콘 사이에도 씁니다.
- `countryGapStyle` — 국가 선택과 번호 칸 사이는 벌리지 않습니다. Web 은 목록 행의 국가 이름과 국가 번호 사이에만 쓰고, Flutter 는 쓰지 않습니다.
- `dropdownItemGapStyle` — 국기와 국가 이름 사이뿐 아니라 체크 표시 앞에도 쓰고, Flutter 는 국가 이름과 국가 번호 사이에도 씁니다.
- `dropdownItemPadding` — 검색 칸에는 닿지 않습니다. 목록 행의 안쪽 여백이고, Flutter 는 검색 결과가 없을 때의 안내 문구에도 씁니다. 검색 칸은 `searchFieldStyle` 로 바꿉니다.
- `borderWidth` — 바깥 테두리뿐 아니라 국가 선택 옆 구분선과 검색 칸 아래 구분선의 두께도 정합니다.
- `maxWidth` — 상자 전체가 아니라 번호 칸의 최대 폭입니다(기본 200). 안쪽 여백을 포함한 폭이고, Jaspr Web 에서는 페이지가 `box-sizing: border-box` 일 때 그렇습니다.
- `dialCodeTextStyle` — 기본 글자 역할은 `bodyLarge` 입니다.
- `flagSize` · `dropdownFlagSize` — 이모지 글자 크기가 아니라 국기 그림의 높이입니다(기본 14, 가로세로 4:3).
- `padding` · `popupMaxWidth` · `popupBorderRadius` · `popoverTopOffset` — Web 만 읽습니다. Flutter 의 패널 모서리와 간격은 `popoverStyle` 의 `panelStyle.borderRadius` · `placementOffset` 으로 바꿉니다.
- `popupMaxWidth` — Web 도 기본값은 적용하지 않습니다. 값을 주면 패널이 아니라 목록의 최대 폭이 됩니다.
- `popupMaxHeight` — 패널 전체가 아니라 목록의 최대 높이입니다(기본 248).
- `chevronIconStyle` — `color` 는 `chevronColor` · `disabledChevronColor` 가 덮습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="phone-input/related-text-field" title="TextField">

[TextField](/components/text-field) — 한 나라의 번호는 `type: CoreInputType.tel` 입력 하나로 받습니다.

</Card>
<Card demo="phone-input/related-select" title="Select">

[Select](/components/select) — 국가만 따로 고르게 할 때 씁니다.

</Card>
<Card demo="phone-input/related-form-field" title="FormField">

[FormField](/components/form-field) 로 라벨과 오류 문구를 붙이고, [Form](/components/form) 안에서 값을 모아 검증합니다.

</Card>
</Cards>
