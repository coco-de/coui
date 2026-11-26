---
title: MockupBrowser
description: 주소창과 창 컨트롤이 있는 브라우저·앱 창 프레임 목업
category: display
platforms: [flutter, web]
related: [mockup, mockup-device, mockup-code, card]
tags: [mockup, browser, window, presentation]
---

# MockupBrowser

주소창과 창 컨트롤이 있는 브라우저·앱 창 프레임입니다. 데스크톱 앱 창은 별도 컴포넌트가 아니라 `MockupBrowser(addressBar: null)` 입니다. 세 목업의 스타일·변형·마이그레이션은 [Mockup](/components/mockup) 에 있습니다.

## Live Preview

<LivePreview component="mockup-browser" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**

- 웹 페이지를 주소창이 있는 창 프레임 안에 보여줄 때
- 창 컨트롤만 있는 데스크톱 앱 창이 필요할 때 (`addressBar: null`)

**대신 다른 컴포넌트를 사용하세요:**

- 폰·태블릿 베젤이 필요하면 `MockupDevice`
- 코드 에디터 프레임이 필요하면 `MockupCode`

## 기본 사용법 (Basic Usage)

```dart
MockupBrowser(
  addressBar: 'https://coui.cocode.im',
  child: Text('Page content'),
)
```

콘텐츠는 창 전체를 채우며 블러가 있는 반투명 툴바가 위에 겹칩니다. 탐색·주소·공유·새 탭은 높이 28의 캡슐로 표현하며 신호등은 테마의 상태색을 따릅니다. 예제와 Figma 프리뷰는 380×200입니다.

창 몸체·툴바·콘텐츠의 겉모습은 `mockupBrowserStyle` (`CoreMockupBrowserStyle`) 한 곳에서 바꿉니다.

## Props / Parameters

`W` 는 Flutter의 Widget / Web의 Jaspr Component입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `showControls` | `bool` | `true` | 창 컨트롤 점 표시 |
| `addressBar` | `String?` | `'example.com'` | 표시용 주소 문자열. null이면 브라우저 주소·탐색 아이콘 생략 |
| `child` | `W?` | `null` | 콘텐츠 카드 안에 놓을 내용 |
| `mockupBrowserStyle` | `CoreMockupBrowserStyle?` | `null` | 몸체·툴바·내용의 겉모습을 바꾸는 값 묶음 |

## 동작 스펙 (Behavior)

- 창 컨트롤·주소창·이전/다음·자물쇠·새로고침·공유·새 탭 아이콘은 장식이며 URL 이동·닫기·최소화 콜백이 없습니다. addressBar는 실제 입력창이 아닙니다.
- addressBar가 null이면 주소·탐색·액션 아이콘을 트리에서 빼고 창 프레임으로 사용합니다. showControls가 거짓이면 컨트롤 점만 생략합니다.
- child의 인터랙션은 그대로 동작하며 목업 자체에는 비활성·타이머·상태 전환이 없습니다. 기기 베젤이면 **[MockupDevice](/components/mockup-device)**, 코드 행 프레임이면 **[MockupCode](/components/mockup-code)** 입니다.

## 사용 가이드라인 (Usage Guidelines)

- 문서, 랜딩, 쇼케이스에서 화면을 창처럼 감쌀 때 씁니다. 실제 앱의 레이아웃 컨테이너로 쓰지 않습니다.
- 주소창 문구는 한 줄로 둡니다.

## 접근성 (Accessibility)

### 역할

정적 프레젠테이션 래퍼이며 브라우저 앱 역할을 자동으로 붙이지 않습니다.
안의 `child` 는 자기 의미를 유지합니다.

### 키보드

프레임 자신이 처리하는 키는 없습니다. 안의 링크·버튼은 각자의 키보드 동작을
유지합니다. 창 컨트롤 그림은 실제 닫기·최소화 버튼이 아닙니다.

### 스크린 리더

주소창 문구와 자식 콘텐츠가 읽힙니다. 프레임을 설명해야 하면 Web 은 호출부
`attributes` 로 의미와 이름을 함께 제공하고 Flutter 는 시맨틱 래퍼로 보완합니다.

### 포커스 관리

프레임은 포커스를 옮기거나 가두지 않습니다. 자식의 포커스 순서를 유지합니다.

### 알려진 제약

주소창은 편집 가능한 입력이 아니며 창 컨트롤도 동작하지 않습니다. 실제 브라우저
UI 처럼 안내하지 마세요. 화면 이미지의 대체 텍스트는 호출자가 제공해야 합니다.
공통 프레임 스펙은 [Mockup](/components/mockup) 을 보세요.
## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 몸체 | OutlinedContainer 안 Column | DOM 래퍼 안 OutlinedContainer |
| 주소 | Expanded와 한 줄 ellipsis 텍스트 | flex 주소 pill과 DOM 텍스트 |
| 콘텐츠 클립 | Padding · Container clip | inset 래퍼 · overflow 클립 |
| 호스트 속성 | key · 호출부 래퍼 | tag · id · attributes · 이벤트 전달 |
