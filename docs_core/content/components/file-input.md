---
title: FileInput
description: 파일을 끌어다 놓거나 골라서 받는 점선 테두리의 드롭 영역입니다.
category: form
platforms: [flutter, web]
related: [text-field, form, button]
tags: [file, upload, input, form]
template: v2
source: form/file_input
---

# FileInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 FileInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="file-input" />

<Note>

무대의 파일 목록은 예시 이름입니다. 드롭 영역을 누르면 운영체제(Web 은 브라우저)의 파일 선택 창이 열리지만, 고른 파일은 무대에 나타나지 않습니다 — 목록은 컴포넌트가 채우지 않고 앱이 `selectedFiles` 로 넘깁니다. 파일 선택 창은 운영체제의 것이라 이 페이지는 그 창을 그리지 않습니다.

</Note>

FileInput 은 파일을 끌어다 놓을 수 있는 점선 영역과 파일 선택 버튼을 하나로 묶습니다. 영역 어디를 눌러도 파일 선택 창이 열리고, 받은 파일은 `onFilesSelected` 로 옵니다. 화면에 보일 파일 이름은 앱이 `selectedFiles` 로 넘깁니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
FileInput(
  onFilesSelected: (files) {
    setState(() => fileNames = files.map((file) => file.name).toList());
  },
  accept: ['.pdf', '.png', '.jpg'],
  multiple: true,
  hint: 'PDF, PNG, JPG · 최대 10MB',
  selectedFiles: fileNames,
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
FileInput(
  onFilesSelected: (files) {
    setState(() {
      fileNames = [for (var i = 0; i < files.length; i++) files.item(i)!.name];
    });
  },
  accept: ['.pdf', '.png', '.jpg'],
  multiple: true,
  hint: 'PDF, PNG, JPG · 최대 10MB',
  selectedFiles: fileNames,
)
```

  </TabItem>
</Tabs>

- Flutter 는 `package:coui_flutter/coui_flutter.dart` 하나만 가져오면 됩니다 — `XFile` 도 거기서 나와, 따로 가져올 패키지가 없습니다.
- Flutter 는 `List<XFile>` 을, Web 은 브라우저의 `FileList` 를 받습니다. Flutter 에서 파일 내용은 필요할 때 `readAsBytes()` · `openRead()` 로 읽습니다.
- Flutter의 파일 선택 창은 `file_drop`이 열고, iOS 14.0 이상이 필요합니다.

## 구조

FileInput 은 점선 테두리의 드롭 영역 하나입니다. 그 안에 위에서 아래로 아이콘 상자, 제목과 안내문, 버튼 줄, 선택한 파일 목록이 쌓입니다.

<Anatomy demo="file-input/anatomy">
<AnatomyItem part="container" name="drop zone">

점선 테두리의 드롭 영역. 영역 전체가 버튼 하나라 어디를 눌러도 파일 선택 창이 열리고, 파일을 끌어다 놓을 수 있습니다. 쉴 때는 채움이 없습니다.

</AnatomyItem>
<AnatomyItem select="input[type=file] + div" side="top" name="icon">

지름 48 의 원 안에 놓인 업로드 아이콘(24). `icon` 으로 아이콘만 바꿀 수 있고, 원은 그대로 남습니다.

</AnatomyItem>
<AnatomyItem part="label" side="right" name="label">

제목. 비우면 로케일의 문구("파일을 여기로 끌어다 놓으세요")가 나옵니다.

</AnatomyItem>
<AnatomyItem select="span + span" side="right" name="hint">

제목 바로 아래의 안내문. `hint` 를 줄 때만 있습니다.

</AnatomyItem>
<AnatomyItem select="button" side="left" name="browse">

파일 선택 버튼(outline `Button`). 문구는 `browseButtonText` 이고, 비우면 로케일의 "파일 선택" 입니다.

</AnatomyItem>
<AnatomyItem select="input[type=file] ~ div:last-child" side="left" name="selectedFiles">

선택한 파일 목록. `selectedFiles` 의 이름마다 파일 아이콘과 이름이 한 줄씩 놓입니다.

</AnatomyItem>
</Anatomy>

- 간격은 위에서부터 아이콘 상자 → 12 → 제목 · 안내문(사이 4) → 16 → 버튼 줄 → 12 → 파일 목록입니다. 영역의 안쪽 여백은 위아래 32 · 좌우 24, 모서리는 12 입니다.
- `allowDirectory: true` 면 파일 선택 버튼 옆에 폴더 선택 버튼(로케일의 "폴더 선택")이 12 떨어져 붙습니다(→ 폴더 선택).
- `icon` 으로 넣은 아이콘에는 `iconStyle` 과 상태별 아이콘 색이 닿지 않습니다 — 넣은 위젯이 자기 색과 크기로 그립니다. Web 에서 색을 정하지 않은 아이콘은 점선 색을 물려받습니다.
- 제목의 줄 수는 `labelMaxLines` · `labelOverflow` 로 제한합니다. 지정하지 않으면 제한 없이 줄을 바꿉니다.
- Figma 의 `Show file` 은 코드 속성이 아니라 `selectedFiles` 가 비었는지를 캔버스에 나타낸 것입니다 — 켜면 파일 목록이 보이고, 끄면 `selectedFiles` 가 `null` 이거나 빈 목록일 때의 모양입니다.

<a id="시각-피드백"></a>

## 상태

드롭 영역은 쉴 때 · Hover · 드래그 중 · 비활성의 네 모양을 가집니다. 겹치면 비활성 → 드래그 중 → Hover → 쉴 때 순서로 앞의 것이 이깁니다.

<Preview demo="file-input/states" />

<Note>

쉴 때와 비활성 칸은 실제 영역입니다. Hover 와 드래그 중 칸은 그 상태의 색을 Core 기본값에서 읽어 `fileInputStyle` 로 고정한 그림이고, 드래그 중의 실선은 점 사이 틈을 0 으로 둔 점선입니다. 실제 드래그 모양은 플레이그라운드의 영역에 파일을 끌어 올려 확인하세요.

</Note>

| 상태 | 테두리 | 채움 | 아이콘 상자 · 아이콘 | 글자 |
| --- | --- | --- | --- | --- |
| 쉴 때 | `outlineVariant` 점선 — 점 6 · 틈 4 · 두께 1 | 없음 — 놓인 면이 비칩니다 | `surfaceContainerHigh` · `onSurfaceVariant` 40 % | 제목 `onSurface`, 안내문 `onSurfaceSubtle`, 파일 이름 `onSurfaceVariant` 80 % |
| Hover | 점선이 `onSurface` 로 한 단 진해집니다 | 그대로 | 그대로 | 그대로 |
| 드래그 중 | `primary` 실선, 두께는 그대로 | `primary` 5 % | `primaryContainer` · `primary` | 그대로 |
| 비활성 | `disabledOutline` 점선 | `disabledContainer` | `disabledContainer` · `disabledContent` | 모두 `disabledContent` — 투명도를 따로 걸지 않습니다 |

- 드래그 모양은 무언가를 영역 위로 끌어 올렸을 때만 켜집니다. 포인터를 올리기만 하면(Hover) 점선 색만 바뀌고, `primary` 테두리와 채움은 드래그에만 씁니다. 드래그 중에는 포인터가 영역 위에 있어도 `primary` 가 그대로입니다. Web 은 파일이 아닌 것(페이지에서 선택한 글자 · 링크)을 끌어 와도 드래그 모양이 켜지고, 놓으면 아무것도 넘기지 않습니다.
- 비활성이면 누르기 · 끌어다 놓기 · 저장이 모두 막히고 Hover 단계가 없습니다.
- 눌러도 영역이 줄어들지 않습니다. 넓은 면이라 눌림 축소를 끄고, 비활성은 투명도 대신 비활성 색으로 그립니다(`clickableStyle` 의 기본값 `pressedScale: 1` · `disabledOpacity: 1`).
- 키보드로 포커스했을 때만 드롭 영역 둘레에 포커스 링을 그립니다.
- 색 전환은 `transitionDuration`(150ms, `move` 곡선)입니다. Web 은 점선 · 채움 색을 이 시간 동안 바꾸고, Flutter 는 채움만 바꾸며 점선 색은 바로 바뀝니다. 점선과 실선 사이는 두 플랫폼 모두 바로 바뀝니다.
- 점선 리듬(점 6 · 틈 4)은 드롭 영역만의 것입니다(`dashLength` · `dashSpacing`). 다른 점선이 쓰는 공용 `CoreDashedBorder`(3 · 2)와 다르고, 그 값은 바뀌지 않습니다. Flutter 는 점선을 직접 그리고 Web 은 SVG `stroke-dasharray` 로 그려, 두 플랫폼의 리듬이 같습니다.
- 영역 경계는 옅은 점선(`outlineVariant`)이 의도입니다. 조작부 경계의 대비(WCAG 1.4.11)는 안의 파일 선택 버튼 테두리가 맡으므로 점선을 더 진하게 되돌리지 않습니다.

<Note>

쉬는 영역은 채움이 없어 놓인 면이 비칩니다. `surfaceContainer` 로 채운 면 위에서는 아이콘 상자(`surfaceContainerHigh`)와 바탕이 한 단계만 차이 나, `surface` 위보다 흐리게 보입니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 파일 받기

파일은 세 길로 들어옵니다 — 파일 선택 창, 끌어다 놓기, 폴더 선택. 세 길 모두 같은 `accept` 로 거른 뒤 `onFilesSelected` 를 부릅니다.

### 파일 선택

- 드롭 영역 어디를 누르거나 파일 선택 버튼을 누르면 파일 선택 창이 열립니다. Flutter는 `file_drop`의 선택창을, Web은 숨긴 `<input type="file">`의 선택창을 엽니다.
- `multiple: true` 면 창에서 여러 파일을 고를 수 있습니다. `multiple: false` 여도 끌어다 놓기와 폴더 선택은 받은 파일을 모두 넘깁니다 — 하나로 자르지 않습니다.
- 선택을 취소하거나 `accept` 를 통과한 파일이 없으면 `onFilesSelected` 를 부르지 않습니다.
- Web 은 숨긴 입력이 바뀔 때만 파일을 받고, 그 입력의 값을 비우지 않습니다. 그래서 직전과 같은 파일을 창에서 다시 고르면 브라우저가 변경을 알리지 않아 `onFilesSelected` 가 불리지 않을 수 있습니다(→ 알려진 제약). Flutter 는 고를 때마다 부릅니다.
- 받은 파일로 할 일 — `selectedFiles` 갱신, 크기 확인, 업로드 — 은 앱이 합니다.

### 허용 형식

- `accept` 는 HTML `accept` 속성과 같은 꼴입니다 — 확장자(`.pdf`), 점 없는 확장자(`pdf`), MIME 타입(`application/pdf`), 와일드카드(`image/*`). 대소문자를 가리지 않고, 비우면 모든 파일을 받습니다.
- 파일 선택 창이 이 목록으로 거르고, 받은 뒤에 한 번 더 걸러 맞지 않는 파일을 조용히 뺍니다. 끌어다 놓기와 폴더 선택에는 창이 없어 두 번째 거르기만 거칩니다. 두 플랫폼이 같은 규칙(`CoreFileInputAccept.matches`)으로 거릅니다.
- MIME 항목은 파일의 MIME 정보가 없거나 맞지 않으면 확장자로도 맞춰 봅니다 — `image/png` 는 `photo.png` 를 받습니다. 와일드카드는 확장자로 맞출 수 없습니다.
- Flutter 의 파일 선택 창은 확장자로만 거릅니다. 와일드카드는 확장자로 바꿀 수 없어, 와일드카드만 적으면 창이 모든 파일을 보여 줍니다.

<Note>

Flutter 에서는 고른 파일 · 끌어다 놓은 파일 · 폴더의 파일에 MIME 정보가 없습니다(Flutter 를 웹으로 빌드한 앱에서 끌어다 놓은 파일만 예외). 그래서 `accept: ['image/*']` 처럼 와일드카드만 적은 목록은 Flutter 에서 받은 파일을 모두 버리고 `onFilesSelected` 를 부르지 않습니다. 확장자를 함께 적으세요 — `accept: ['image/*', '.png', '.jpg']`.

</Note>

### 드래그 앤 드롭

- 운영체제의 파일을 영역 위로 끌어 오면 드래그 모양으로 바뀌고, 놓으면 `onFilesSelected` 로 넘어갑니다.
- Flutter는 `file_drop`으로 OS와 브라우저의 드롭을 받고, Web은 HTML5 drop으로 받습니다.
- Web 에서 폴더를 떨어뜨리면 그 안의 파일을 하위 폴더까지 모아 넘깁니다. Flutter 는 폴더 안을 모으지 않고, 떨어뜨린 폴더를 항목 하나로 그대로 넘깁니다 — `accept` 가 있으면 확장자가 없는 그 항목은 빠집니다.
- 끌어다 놓은 파일에도 `accept` 가 적용됩니다.

### 폴더 선택

- `allowDirectory: true` 면 폴더 선택 버튼이 생깁니다. 폴더를 고르면 그 안의 파일을 하위 폴더까지 모아 `onFilesSelected` 로 넘깁니다. 켜져 있는 폴더 선택 버튼을 눌러도 파일 선택 창은 열리지 않습니다.
- Flutter 는 `dir_picker`(macOS · Windows · Linux · Android · iOS)를, Web 은 File System Access API(`showDirectoryPicker`)를 씁니다. 이 API 가 없는 브라우저(Firefox · Safari)에서는 버튼이 비활성으로 그려지고, Flutter 를 웹으로 빌드한 앱도 같습니다. Jaspr Web 은 서버가 그린 첫 화면에서도 버튼이 비활성이고, 브라우저에서 깨어난 뒤 켜집니다.
- 폴더의 파일도 `accept` 로 거릅니다. 맞는 파일이 없으면 부르지 않습니다.
- Android 의 SAF 는 파일 경로 대신 `content://` URI 를 줍니다. 그때는 `XFile` 의 경로가 그 URI 라, 내용이 필요하면 앱의 SAF 처리로 읽어야 합니다.
- 폴더 안 파일의 이름은 Flutter 를 웹으로 빌드한 앱에서만 고른 폴더 아래의 경로를 담고, 고른 폴더의 이름은 빠집니다(`사진` 을 고르면 그 안의 `2025/a.png`). 저장 버튼도 이 이름으로 짝을 지으므로, 그 앱에서는 `selectedFiles` 에 같은 이름을 넘겨야 버튼이 붙습니다. Flutter 네이티브와 Jaspr Web 은 파일 이름만 줍니다.

## 선택한 파일

`selectedFiles` 는 보여 주기만 하는 이름 목록입니다. FileInput 은 받은 파일로 이 목록을 채우지 않으므로, 앱이 `onFilesSelected` 에서 이름을 모아 넘깁니다.

<Preview component="file-input" props="selectedFiles=견적서.pdf,로고.png,배너.jpg" />

- 이름마다 파일 아이콘(14)과 이름(`labelMedium`)이 4 떨어져 한 줄을 이루고, 줄마다 아래로 4 를 띄웁니다.
- 긴 이름은 한 줄에서 말줄임표로 줄입니다.
- `null` 이거나 빈 목록이면 목록 자리가 없습니다.

### 파일 저장

- `allowSave: true` 면 컴포넌트가 실제로 받은 파일(선택 · 끌어다 놓기 · 폴더)의 줄 끝에 저장 버튼이 붙습니다. 누르면 Flutter 는 시스템 저장 창(`file_saver_ffi`)을 열고, Web 은 브라우저 다운로드로 내보냅니다.
- 버튼은 이름으로 짝을 짓습니다. `selectedFiles` 의 이름이 받은 파일의 이름과 같을 때만 붙고, 같은 이름이 여러 번 들어오면 마지막 파일을 저장합니다.
- 앱이 밖에서 넣은 이름(서버에 있는 첨부 같은)에는 파일 데이터가 없어 버튼이 붙지 않습니다. 그때는 `CoFileSaver` 를 직접 씁니다.
  - Flutter: `CoFileSaver.saveBytes(bytes:, fileName:, mimeType:)` · `CoFileSaver.saveFile(path:, fileName:)`
  - Web: `CoFileSaver.saveBytes(bytes:, fileName:, mimeType:)`
- 저장 버튼은 16 × 16(아이콘 14)으로 그려지고, 포인터는 24 까지 받습니다(→ 알려진 제약). 겉모습은 `saveButtonStyle` 로 바꿉니다.
- Web 에서 폴더 선택으로 받은 파일에는 저장 버튼이 붙지 않습니다 — 의도한 차이가 아니라 결함입니다(→ 알려진 제약).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

사용자가 파일을 올려야 할 때 씁니다 — 이미지 · 문서 첨부, 프로필 사진, 폼의 파일 칸.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 파일 대신 글자를 받을 때 | [TextField](/components/text-field) |
| 드롭 영역과 파일 목록 없이, 버튼 하나에 파일 선택을 직접 연결할 때 | [Button](/components/button) |
| 여러 필드와 함께 검증하고 제출할 때 | [Form](/components/form) — FileInput 을 그 안에 둡니다 |

<a id="do"></a>
<a id="dont"></a>

### 형식과 목록

<Cards columns="2">
<Card component="file-input" props="accept=.pdf,.png;hint=PDF, PNG · 최대 10MB" tone="do" eyebrow="이렇게 하세요">

받을 수 있는 형식과 크기 한도를 `hint` 로 적습니다. `accept` 는 파일을 거를 뿐 화면에 보이지 않고, 보조 기술도 읽지 않습니다.

</Card>
<Card component="file-input" props="accept=.pdf,.png" tone="dont" eyebrow="이렇게 하지 마세요">

허용 형식을 `accept` 에만 두지 않습니다. 사용자는 고르기 전에는 무엇을 받는지 알 수 없습니다.

</Card>
<Card component="file-input" props="multiple=true;selectedFiles=견적서.pdf,로고.png" tone="do" eyebrow="이렇게 하세요">

받은 파일의 이름을 `selectedFiles` 로 보여 줍니다. 무엇이 들어갔는지 바로 확인할 수 있습니다.

</Card>
<Card component="file-input" props="multiple=true" tone="dont" eyebrow="이렇게 하지 마세요">

파일을 받고도 목록을 비워 두지 않습니다. FileInput 은 받은 파일로 목록을 채우지 않습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

와일드카드를 쓸 때는 확장자를 함께 적습니다 — `accept: ['image/*', '.png', '.jpg']`. Flutter 는 확장자로만 파일을 맞춥니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

`accept: ['image/*']` 처럼 와일드카드만 두지 않습니다. Flutter 에서는 받은 파일이 모두 빠지고 `onFilesSelected` 가 불리지 않습니다.

</Card>
</Cards>

FileInput 은 파일 크기를 보지 않습니다. `onFilesSelected` 에서 크기를 확인하고, 넘으면 그 이유를 알리세요.

<a id="스타일-시스템-style-system"></a>
<a id="테마-커스터마이징-theme"></a>

## 테마와 스타일

내용과 동작(`label` · `hint` · `accept` · `multiple` · `allowDirectory` · `allowSave` · `enabled` · `selectedFiles`)은 위젯 속성으로 넘기고, 여백 · 간격 · 모서리 · 점선 · 상태별 색 · 글자 · 아이콘과 안쪽 부품의 스타일은 `fileInputStyle`(`CoreFileInputStyle`) 하나로 덮어씁니다. FileInput 에는 variant 와 크기 단계가 없습니다.

<Split>

<Code language="dart" title="FileInput 하나만 바꾸기">
FileInput(
  onFilesSelected: handleFiles,
  fileInputStyle: CoreFileInputStyle(
    padding: CoreEdgeInsets.symmetric(
      vertical: CoreSpace.space24,
      horizontal: CoreSpace.space16,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    dashLength: CoreSpace.space8,
    iconStyle: CoreIconStyle(size: CoreIconSize.size20),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    fileInput: CoreFileInputTheme(
      style: CoreFileInputStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        hoverBorderColor: CoreColor.token(CoreColors.primary),
      ),
    ),
  ),
)
</Code>

</Split>

`CoreFileInputTheme` 은 `style` 하나만 가집니다 — variant 가 없어 `variantStyles` 도 없습니다.

### 값이 정해지는 순서

```text
기본값 (CoreFileInputStyle.default*)
  → CoreComponentTheme.fileInput.style   // 앱 전체
  → fileInputStyle                       // FileInput 하나
```

뒤로 갈수록 우선합니다. 안쪽 부품의 스타일 중 `clickableStyle` 은 드롭 영역의 `Clickable` 에, `saveButtonStyle` 은 저장 버튼(`Button`)에 그대로 넘어가 그 컴포넌트의 기본값 위에 한 번 더 얹힙니다. 글자 스타일(`labelTextStyle` · `hintTextStyle` · `fileTextStyle`)은 기본 글자(`labelLarge` · `bodySmall` · `labelMedium`) 위에 합쳐집니다.

상태별 색은 이 순서로 정해집니다.

| 자리 | 앞의 것이 이깁니다 |
| --- | --- |
| 제목 | `labelTextStyle` 의 색 → `contentColor`, 비활성이면 `disabledContentColor`. `labelTextStyle` 에 적은 색은 비활성에서도 이깁니다. |
| 안내문 | `hintTextStyle` 의 색 → `hintColor`, 비활성이면 `disabledContentColor`. 적은 색은 비활성에서도 이깁니다. |
| 업로드 아이콘 | 비활성이면 `disabledContentColor`. 아니면 `iconStyle` 의 색 → 드래그 중에는 `dragActiveIconColor`, 그 밖에는 `subtleIconColor`. |
| 아이콘 상자 | 비활성 `disabledIconBoxColor`, 드래그 중 `dragActiveIconBoxColor`, 그 밖 `iconBoxColor`. |
| 점선 | 비활성 `disabledBorderColor`, 드래그 중 `dragOverBorderColor`, Hover `hoverBorderColor`, 쉴 때 `borderColor`. 쉴 때의 `borderColor` 는 비활성으로 새지 않습니다. |
| 채움 | 비활성 `disabledBackgroundColor`. 쉴 때는 `backgroundColor`, 없으면 채움이 없습니다. 드래그 중은 `dragActiveBackgroundColor` → `backgroundColor` → `primary` 5 %. |

<Note>

두 플랫폼이 다르게 고르는 자리가 있습니다(→ 플랫폼 차이).

- Web 에서 `borderColor` 를 주면 드래그 중에도 점선이 그 색입니다. Flutter 는 드래그 중에 `dragOverBorderColor` 를 씁니다.
- `backgroundColor` 와 `dragActiveBackgroundColor` 를 함께 주면 드래그 중 채움이 Flutter 는 `dragActiveBackgroundColor`, Web 은 `backgroundColor` 입니다.
- Web 의 파일 아이콘은 `fileIconStyle` 의 색, 없으면 점선 색을 따릅니다 — `fileIconColor` 가 닿지 않고, Hover 에서는 점선과 함께 진해집니다. Flutter 는 `fileIconColor`(비활성이면 `disabledContentColor`)가 늘 이기고, `fileIconStyle` 에서는 크기만 읽습니다.
- Web 에서 글자 스타일(`labelTextStyle` · `hintTextStyle` · `fileTextStyle`)에 적은 색은 토큰이 아닌 색일 때만 확실히 이깁니다. 토큰 색(`CoreColor.token(...)`)은 상태 색과 같은 글자에 함께 붙어, 어느 쪽이 칠해지는지 스타일시트의 순서가 정합니다.
- `fileTextStyle` 에 적은 색은 Web 에서만 쓰입니다(그것도 위의 조건에서만 확실합니다). Flutter 는 `fileNameColor` 를 씁니다.
- Web 은 글자 색(`contentColor` · `disabledContentColor` · `hintColor` · `fileNameColor`)과 `dragOverBorderColor` · `dragActiveBackgroundColor` 에 토큰 색(`CoreColor.token(...)`)만 칠합니다. 토큰이 아닌 색은 칠하지 않습니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 FileInput 에 `.withStyle(CoreFileInputStyle(...))` 를 이어 붙이면 그 값이 `fileInputStyle` 위에 합쳐지고, 겹치는 필드는 뒤에 붙인 것이 이깁니다. `.radius16` 처럼 토큰 이름과 같은 짧은 getter 도 있어 이름이 곧 값입니다(`.radius16` 은 `CoreRadius.radius16`). 모서리 getter 는 `borderRadius` 를, 색 getter(`.primary` · `.surface` … `.transparent`)는 쉬는 채움 `backgroundColor` 를 바꿉니다 — 드롭 영역은 원래 채움이 없으므로 색 getter 하나로 영역이 칠해집니다.

<Preview component="file-input" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FileInputChainExample extends StatefulWidget {
  const FileInputChainExample({super.key});

  @override
  State<FileInputChainExample> createState() => _FileInputChainExampleState();
}

class _FileInputChainExampleState extends State<FileInputChainExample> {
  List<String> _selectedFiles = const [];

  void handleFilesSelected(List<XFile> files) {
    setState(() {
      _selectedFiles = files.map((f) => f.name).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FileInput(
          onFilesSelected: handleFilesSelected,
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        FileInput(
          onFilesSelected: handleFilesSelected,
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).withStyle(
          const CoreFileInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
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
class FileInputChainExample extends StatefulComponent {
  const FileInputChainExample({super.key});

  @override
  State<FileInputChainExample> createState() => _FileInputChainExampleState();
}

class _FileInputChainExampleState extends State<FileInputChainExample> {
  List<String> _selectedFiles = const [];

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FileInput(
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles = [
                for (var i = 0; i < files.length; i++) files.item(i)!.name,
              ];
            });
          },
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        FileInput(
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles = [
                for (var i = 0; i < files.length; i++) files.item(i)!.name,
              ];
            });
          },
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).withStyle(
          const CoreFileInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
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

드롭 영역은 두 플랫폼 모두 버튼으로 읽힙니다. Web 은 그 버튼에 `aria-label` 로 이름을 주고, Flutter 의 FileInput 은 그 노드에 이름을 정해 주지 않습니다(→ 알려진 제약).

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 드롭 영역은 `Clickable` 이 얹는 버튼 노드(`Semantics(button: true, enabled: ...)`)이고, FileInput 은 이 노드에 이름을 정해 주지 않습니다. 파일 선택 · 폴더 선택 버튼은 따로 있는 버튼이고, 저장 버튼은 로케일의 "파일 저장" 라벨을 가진 버튼입니다. 숨긴 파일 입력은 없습니다 — 운영체제의 파일 선택 창을 직접 엽니다. |
| Jaspr Web | 드롭 영역의 바깥 `<div>` 에 `role="button"` · `tabindex="0"` · `aria-label`(값은 `label`, 없으면 로케일의 문구)이 붙습니다. 비활성이면 `tabindex` 가 빠지고 `aria-disabled="true"` 와 `data-disabled` 가 붙습니다. 파일을 실제로 고르는 `<input type="file">` 은 `tabindex="-1"` · `aria-hidden="true"` 로 숨겨져 있고, `accept` · `multiple` · `name` · `disabled` 를 그 요소가 가집니다. 점선을 그리는 `<svg>` 도 `aria-hidden="true"` 입니다. 파일 선택 · 폴더 선택 버튼은 `<button>` 이고, 저장 버튼은 `aria-label`("파일 저장")을 가진 `<button>` 입니다. |

Web 의 `attributes` 는 컴포넌트가 넣은 값 뒤에 합쳐지므로 `aria-label` · `role` 을 덮어쓸 수 있습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` + `Tab` | 드롭 영역, 파일 선택 버튼, (폴더 선택 버튼), (저장 버튼) 차례로 오갑니다. 비활성 영역은 어느 것도 포커스를 받지 않습니다. |
| `Enter` · `Space` | 드롭 영역이나 파일 선택 버튼에서 파일 선택 창을 엽니다. 폴더 선택 버튼에서는 폴더 선택 창을 열고, 저장 버튼에서는 저장을 시작합니다. |

Web 의 드롭 영역은 자기 자신에 포커스가 있을 때만 키를 받아, 안쪽 버튼에서 올라온 키로 창이 두 번 열리지 않습니다. 끌어다 놓기에는 키보드 동작이 따로 없습니다 — 같은 결과를 파일 선택 창으로 얻습니다.

### 스크린 리더

- Web 은 드롭 영역의 `aria-label` 이 이름입니다 — `label`, 없으면 로케일의 "파일을 여기로 끌어다 놓으세요". 영역이 `role="button"` 이라 그 안의 제목 · 안내문 · 파일 목록은 버튼의 일부로 묶이고, 리더가 따로 읽지 않을 수 있습니다. 안쪽 버튼은 각자 포커스를 받아 따로 읽힙니다.
- Flutter 의 FileInput 은 드롭 영역 노드에 라벨을 따로 붙이지 않습니다 — Web 의 `aria-label` 처럼 컴포넌트가 정해 주는 이름이 없습니다.
- `enabled: false` 는 Web 에서 `aria-disabled="true"`, Flutter 에서 `Semantics(enabled: false)` 로 알립니다.
- 받은 파일이나 목록의 변화를 알리지 않습니다 — 라이브 리전이 없습니다.

### 포커스 관리

- **진입** — 오버레이가 아니어서 그릴 때 포커스를 옮기지 않습니다.
- **이탈** — 파일 선택 창은 운영체제 · 브라우저의 것이라, 컴포넌트가 포커스를 창에 넘기지도 창이 닫힌 뒤 되돌리지도 않습니다. 창을 닫은 뒤 포커스가 어디로 가는지는 플랫폼이 정합니다.
- **트랩** — 없습니다. `Tab` 은 드롭 영역과 안쪽 버튼을 지나 그대로 밖으로 나갑니다.
- **포커스 링** — 키보드로 포커스했을 때만 드롭 영역 둘레에 링을 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 같은 "파일 열기" 동작에 정지점이 둘입니다 — 드롭 영역 자체가 버튼이고, 그 안에 파일 선택 버튼이 또 있습니다. `Tab` 을 두 번 눌러야 지나가고, 버튼 둘로 안내됩니다. |
| 공통 | 받은 파일이나 `selectedFiles` 의 변화를 알리지 않습니다. 결과를 확인하려면 사용자가 목록으로 직접 가야 합니다. |
| 공통 | 저장 버튼은 16 × 16 으로 그려지지만 포인터는 최소 24 까지 받습니다 — 빗나간 탭이 드롭 영역으로 떨어져 파일 선택 창이 열리는 것을 막기 위해서입니다. Web 은 네 방향으로 넓어지고, Flutter 는 버튼이 줄 끝에 있고 줄 높이가 버튼과 같아 파일 이름 쪽으로만 넓어집니다. 그리는 크기는 `saveButtonStyle` 로 키웁니다. |
| Jaspr Web | 숨긴 `<input type="file">` 은 보조 기술에 보이지 않아, 거기 실린 `accept` · `multiple` 을 리더가 읽지 못합니다. 허용 형식과 여러 파일 여부는 `hint` 나 `label` 에 적습니다. |
| Jaspr Web | `role="button"` 안에 `<button>` 이 들어 있어, 접근성 검사 도구가 버튼 안의 상호작용 요소로 알릴 수 있습니다. |
| Jaspr Web | 폴더 선택으로 받은 파일은 저장할 파일로 기억되지 않아, `allowSave` 를 켜도 그 줄에 저장 버튼이 붙지 않습니다. 의도한 플랫폼 차이가 아니라 결함입니다. |
| Jaspr Web | 직전과 같은 파일을 파일 선택 창에서 다시 고르면 브라우저가 변경을 알리지 않아 `onFilesSelected` 가 불리지 않을 수 있습니다 — 숨긴 입력의 값을 비우지 않기 때문입니다. 끌어다 놓기는 매번 넘깁니다. |
| Jaspr Web | 파일이 아닌 것(페이지에서 선택한 글자 · 링크)을 끌어 와도 드래그 모양이 켜집니다. 놓으면 아무것도 넘기지 않습니다. |
| Jaspr Web | `eventHandlers` 에 넘긴 `dragenter` · `dragover` · `dragleave` · `drop` 은 컴포넌트의 핸들러로 바뀌어 불리지 않습니다. |
| Jaspr Web | 토큰이 아닌 색으로 준 `contentColor` · `disabledContentColor` · `hintColor` · `fileNameColor` · `dragOverBorderColor` · `dragActiveBackgroundColor` 는 칠해지지 않습니다. |
| Flutter | 드롭 영역 노드에 FileInput 이 정해 주는 이름이 없습니다 — Web 의 `aria-label` 같은 값이 없어, 리더가 이 버튼을 무엇이라 부를지 컴포넌트가 정하지 않습니다. |
| Flutter(웹으로 빌드) | 폴더 선택 API 가 없는 브라우저에서 비활성으로 그려진 폴더 선택 버튼을 누르면, 그 탭이 드롭 영역으로 떨어져 파일 선택 창이 열릴 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API 는 같지만, 파일을 받는 방법과 몇 가지 색은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 받는 파일 | `List<XFile>` | 브라우저 `FileList` |
| 파일 선택 창 | `file_drop` — iOS 14.0 이상 | 숨긴 `<input type="file">` |
| 선택 창의 거르기 | 확장자만 — 와일드카드는 창에서 거르지 않음 | 브라우저의 `accept` 그대로 |
| 받은 파일의 MIME 정보 | 없음(웹으로 빌드한 앱의 끌어다 놓기만 있음) — 와일드카드만 적은 `accept` 가 모든 파일을 버림 | 브라우저가 채움 |
| 끌어다 놓기 | `file_drop` | HTML5 drop |
| 떨어뜨린 폴더 | 풀지 않고 항목 하나로 넘김 | 안의 파일을 하위 폴더까지 모아 넘김 |
| 폴더 선택 | `dir_picker` | `showDirectoryPicker` — 없는 브라우저와 서버가 그린 첫 화면에서는 버튼이 비활성 |
| 폴더 안 파일의 이름 | 네이티브는 이름만, 웹으로 빌드한 앱은 폴더 안 경로 포함 | 이름만 |
| 저장 | 시스템 저장 창(`file_saver_ffi`) | 브라우저 다운로드 |
| 폴더로 받은 파일의 저장 버튼 | 붙음 | 붙지 않음 — 결함 |
| 같은 파일을 다시 고를 때 | 매번 `onFilesSelected` | 브라우저가 알리지 않으면 부르지 않음 |
| Hover 감지 | `Clickable.onHover` 가 위젯 상태로 | CSS `:hover` — 위젯 상태 없음 |
| 색 전환 | 채움만 `transitionDuration` 동안, 점선은 바로 | 점선 · 채움 모두 `transitionDuration` 동안 |
| 점선 두께 | 선 굵기 규칙을 거쳐 서페이스 스타일의 선 굵기 하한이 닿음 | `rem` 길이 — 브라우저 글자 크기를 따라 굵어지고 하한이 닿지 않음 |
| `name` | 쓰이지 않음 | 숨긴 입력의 `name` — 폼과 함께 제출 |
| 파일 아이콘 색 | `fileIconColor`(비활성 `disabledContentColor`) — `fileIconStyle` 의 색은 쓰이지 않음 | `fileIconStyle` 의 색, 없으면 점선 색을 따름 |
| 드래그 중 점선 색 | `dragOverBorderColor` | `borderColor` 를 주면 그 색, 없으면 `dragOverBorderColor` |
| 드래그 중 채움 | `dragActiveBackgroundColor` 가 `backgroundColor` 를 이김 | `backgroundColor` 가 이김 |
| `fileTextStyle` 의 색 | 쓰이지 않음 — `fileNameColor` | 쓰임 |
| `labelTextStyle` · `hintTextStyle` 에 적은 토큰 색 | 상태 색을 이김 | 상태 색과 함께 붙어 스타일시트 순서가 정함 |
| 토큰이 아닌 글자 색 · 드래그 색 | 칠함 | 칠하지 않음 — 결함 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` · DOM 이벤트 |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Web 의 `Component` 입니다. variant · 크기 축이 없습니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | 제목. 비우면 로케일의 문구("파일을 여기로 끌어다 놓으세요" · "Drop files here") |
| `labelMaxLines` | `int?` | `null` | 제목의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 제목의 처리 |
| `hint` | `String?` | `null` | 제목 아래 안내문. 주지 않으면 그 줄이 없습니다. |
| `icon` | `W?` | `null` | 원 안의 아이콘. 비우면 업로드 아이콘(`LucideIcons.upload`) |
| `browseButtonText` | `String?` | `null` | 파일 선택 버튼 문구. 비우면 로케일의 문구("파일 선택" · "Browse files") |
| `selectedFiles` | `List<String>?` | `null` | 영역 아래에 보일 파일 이름. 앱이 채웁니다(→ 선택한 파일). |

### 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `accept` | `List<String>?` | `null` | 허용 형식(→ 허용 형식). 비우면 모든 파일 |
| `multiple` | `bool` | `false` | 파일 선택 창에서 여러 파일을 고르게 합니다. 끌어다 놓기 · 폴더 선택은 이 값과 상관없이 모두 넘깁니다. |
| `allowDirectory` | `bool` | `false` | 폴더 선택 버튼을 둡니다. |
| `allowSave` | `bool` | `false` | 받은 파일의 줄에 저장 버튼을 둡니다. |
| `enabled` | `bool` | `true` | false 면 누르기 · 끌어다 놓기 · 저장이 모두 막힙니다. |
| `name` | `String?` | `null` | 숨긴 `<input type="file">` 의 `name`. Web 만 씁니다. |
| `fileInputStyle` | `CoreFileInputStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | Flutter 타입 | Web 타입 | 설명 |
| --- | --- | --- | --- |
| `onFilesSelected` | `ValueChanged<List<XFile>>?` | `void Function(FileList)?` | `accept` 를 통과한 파일을 받습니다. 선택을 취소하거나 통과한 파일이 없으면 부르지 않습니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreFileInputStyle patch)` | `fileInputStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `.radius0` … `.radius9999` | `borderRadius` 를 그 이름의 `CoreRadius` 로 바꾼 사본 |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent` | `backgroundColor` 를 그 색으로 바꾼 사본 |
| `copyWith({onFilesSelected, accept, …})` | 바꾼 값으로 사본을 만듭니다. Web 은 `id` · `classes` · `css` · `attributes` 와 DOM 이벤트도 받습니다. |

Web 의 FileInput 은 드롭 영역의 바깥 `<div>` 에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 DOM 이벤트(`onClick` · `onKeyDown` …)도 받습니다. `eventHandlers` 의 `dragenter` · `dragover` · `dragleave` · `drop` 은 컴포넌트의 핸들러로 바뀌어 앱의 것이 불리지 않습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFileInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `padding` | `CoreEdgeInsets?` | Inner padding. |
| `itemSpacing` | `double?` | Spacing between vertical elements (icon / label / button / hint) — drives `Column.spacing` (Flutter) and CSS `gap` on the flex column root (Web). |
| `textSpacing` | `double?` | Spacing between the title and the hint inside the text block (logical px). `null` → [defaultTextSpacing]. |
| `actionSpacing` | `double?` | Spacing between the text block (title + hint) and the action buttons (logical px). `null` → [defaultActionSpacing]. |
| `iconBoxSize` | `double?` | Edge length of the circular box the upload icon sits in (logical px, pre-scaling). `null` → [defaultIconBoxSize]. |
| `iconBoxColor` | `CoreColor?` | Fill of the icon box at rest. `null` → [defaultIconBoxColor]. |
| `dragActiveIconBoxColor` | `CoreColor?` | Fill of the icon box while a file is dragged over the zone. `null` → [defaultDragActiveIconBoxColor]. |
| `iconBoxBorderRadius` | `CoreBorderRadius?` | Corner radius of the icon box. `null` → [defaultIconBoxBorderRadius] (fully rounded — a circle). |
| `borderRadius` | `CoreBorderRadius?` | Outer border radius. |
| `borderWidth` | `double?` | Outer border stroke width (logical px). |
| `dashLength` | `double?` | Dash segment length of the dashed drop-zone border (logical px) — every state but drag-over, which strokes solid. `null` → [defaultDashLength]. |
| `dashSpacing` | `double?` | Gap between dash segments (logical px). `null` → [defaultDashSpacing]. |
| `backgroundColor` | `CoreColor?` | Container background colour. |
| `borderColor` | `CoreColor?` | Outer border stroke colour. |
| `hoverBorderColor` | `CoreColor?` | Outer border stroke colour while the pointer hovers the zone and no file is being dragged over it. `null` → [defaultHoverBorderColor]. Drag-over keeps its own [dragOverBorderColor]; a disabled zone never takes this. |
| `fileItemSpacing` | `double?` | Spacing (and bottom margin) between selected file items — drives `Row.spacing` (Flutter) and CSS `gap` on each per-file row (Web), plus the bottom margin of each row. |
| `transitionDuration` | `Duration?` | Transition duration for the hover / focus colour crossfade on the drop-zone container. |
| `iconStyle` | `CoreIconStyle?` | Icon slot style (size + colour). |
| `fileIconStyle` | `CoreIconStyle?` | Selected-file icon slot style (size + colour) — drives the per-file row icon glyph. |
| `labelTextStyle` | `CoreTextStyle?` | Primary label text style override. |
| `hintTextStyle` | `CoreTextStyle?` | Hint text style override. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the drop zone's `Clickable` — press, focus ring and cursor overrides for the drop zone. Laid over [defaultClickableStyle] and passed to `Clickable(clickableStyle:)` as is. |
| `saveButtonStyle` | `CoreButtonStyle?` | Style for the `Button` of each file's save action — laid over [defaultSaveButtonStyle] and passed to `Button(buttonStyle:)` as is. Null means "no per-instance override"; the button still renders with the design-system default. |
| `contentColor` | `CoreColor?` | Primary-label content colour override. `null` → [defaultContentColor]. |
| `disabledContentColor` | `CoreColor?` | Disabled content colour override. `null` → [defaultDisabledContentColor]. |
| `hintColor` | `CoreColor?` | Hint content colour override. `null` → [defaultHintColor]. |
| `fileNameColor` | `CoreColor?` | Selected-file name colour override. `null` → [defaultFileNameColor]. |
| `subtleIconColor` | `CoreColor?` | Subtle upload-icon colour override (enabled). `null` → [defaultSubtleIconColor]. |
| `dragActiveIconColor` | `CoreColor?` | Upload-icon colour while a file is dragged over the zone (enabled). `null` → [defaultDragActiveIconColor]. |
| `fileIconColor` | `CoreColor?` | Selected-file icon colour override (enabled). `null` → [defaultFileIconColor]. |
| `disabledBorderColor` | `CoreColor?` | Disabled dashed-border colour override. `null` → [defaultDisabledBorderColor]. |
| `disabledBackgroundColor` | `CoreColor?` | Disabled zone fill override. `null` → [defaultDisabledBackgroundColor]. |
| `disabledIconBoxColor` | `CoreColor?` | Disabled icon-box fill override. `null` → [defaultDisabledIconBoxColor]. |
| `dragOverBorderColor` | `CoreColor?` | Drag-over border colour override — the border is solid, not dashed, while a file is over the zone. `null` → [defaultDragOverBorderColor]. |
| `dragActiveBackgroundColor` | `CoreColor?` | Drag-active background tint override. `null` → [defaultDragActiveBackgroundColor]. |
| `fileTextStyle` | `CoreTextStyle?` | Selected-file name text style override. `null` → [defaultFileTextStyle]. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 소스 주석에서 만들어지며, 몇 필드는 지금 동작과 다르거나 한쪽 플랫폼에서만 맞습니다.

- `itemSpacing` — 아이콘 상자 · 글 묶음(제목 · 안내문 · 버튼) · 파일 목록 사이와 버튼 사이의 간격입니다. 제목과 안내문 사이는 `textSpacing`, 글과 버튼 사이는 `actionSpacing` 이 정합니다.
- `borderColor` — 쉬는 점선의 색입니다. Web 에서는 드래그 중에도 이 색입니다.
- `backgroundColor` — 쉬는 채움입니다(기본은 채움 없음). `dragActiveBackgroundColor` 를 주지 않으면 드래그 중 채움도 이 색이고, Web 은 둘을 함께 줘도 이 색입니다.
- `borderWidth` — Flutter 는 서페이스 스타일의 선 굵기 하한을 따르고, Web 은 `rem` 으로 그려 브라우저 글자 크기를 따릅니다.
- `transitionDuration` — Web 은 점선 · 채움 색의 전환에, Flutter 는 채움 색의 전환에만 씁니다. 포커스 링과는 상관없습니다.
- `iconStyle` — 비활성에서는 색이 쓰이지 않고 `disabledContentColor` 가 이깁니다. `icon` 으로 넣은 아이콘에는 닿지 않습니다.
- `fileIconColor` — Flutter 에서만 쓰입니다. Web 의 파일 아이콘은 `fileIconStyle` 의 색, 없으면 점선 색을 따릅니다.
- `fileIconStyle` — 크기는 두 플랫폼에서, 색은 Web 에서만 쓰입니다.
- `fileTextStyle` — 색은 Web 에서만 쓰입니다. Flutter 는 `fileNameColor` 가 이깁니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="placeholder=파일 이름" title="TextField">

파일 대신 글자를 받습니다.

</Card>
<Card component="button" props="variant=outline" label="파일 선택" title="Button">

드롭 영역 없이 버튼 하나로 파일 선택을 직접 연결합니다. FileInput 의 파일 선택 버튼도 outline Button 입니다.

</Card>
<Card title="Form" href="/components/form" more="Form 보기">

여러 필드와 함께 검증하고 제출합니다. FileInput 을 그 안에 둡니다.

</Card>
</Cards>
