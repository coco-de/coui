---
title: 빠른 시작
description: CoUI를 설치하고 첫 화면을 만들기까지의 과정을 안내합니다. 사용할 플랫폼을 먼저 골라 주세요.
design: true
---

# 빠른 시작

## 플랫폼 선택

설치 안내는 아래 탭에서 고른 플랫폼에 맞춰 바뀝니다.

<Cards columns="2">
  <Card title="Flutter">

iOS, Android, 데스크톱 앱을 만듭니다.

`coui_flutter`

  </Card>
  <Card title="Jaspr Web">

Dart로 웹 페이지를 만듭니다.

`coui_web`

  </Card>
</Cards>

## 설치

<Tabs>
  <TabItem label="Flutter" value="flutter">

<Steps size="large">
  <Step title="패키지 설치">

프로젝트 폴더에서 아래 명령어를 실행합니다.

```bash
flutter pub add coui_flutter
```

  </Step>
  <Step title="앱을 CoUIApp으로 감싸기">

앱의 루트를 CoUIApp으로 바꾸면 테마와 토큰이 모든 화면에 적용됩니다.

<Code language="dart" title="main.dart">
void main() {
  runApp(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: const HomePage(),
    ),
  );
}
</Code>

UI 파일에서는 `package:coui_flutter/coui_flutter.dart` 하나만 import 합니다. CoUI 위젯은 접두사 없는 이름(`Button` · `Icon` · `Card`)이라 `material.dart`를 함께 import 하면 이름이 충돌합니다.

  </Step>
  <Step title="첫 컴포넌트 쓰기">

Button을 화면에 넣어 렌더링을 확인합니다.

<Code language="dart" title="home_page.dart">
Button(
  variant: CoreButtonVariant.primary,
  onPressed: save,
  child: Text('저장하기'),
)
</Code>

<Preview demo="button/do-one-primary" height="140" />

  </Step>
</Steps>

  </TabItem>
  <TabItem label="Jaspr Web" value="web">

<Steps size="large">
  <Step title="패키지 설치">

프로젝트 폴더에서 아래 명령어를 실행합니다.

```bash
dart pub add coui_web
```

  </Step>
  <Step title="앱을 CoUIWeb으로 감싸기">

앱의 루트를 CoUIWeb으로 바꾸면 테마와 토큰이 모든 화면에 적용됩니다.

<Code language="dart" title="app.dart">
class App extends StatelessComponent {
  const App({super.key});
  @override
  Component build(BuildContext context) {
    return CoUIWeb(
      theme: ThemeData.coui,
      child: const HomePage(),
    );
  }
}
</Code>

감싸지 않으면 테마를 읽는 첫 컴포넌트에서 `No Theme found in context`로 실패합니다. import 는 `package:coui_web/coui_web.dart` 하나만 씁니다 — `package:jaspr/jaspr.dart`를 함께 쓰면 `Gap` · `Position`이, 서버 엔트리에서 `package:jaspr/server.dart`를 함께 쓰면 `runApp` · `Document` · `Text`가 충돌하므로 한쪽에 `show` · `hide`를 겁니다.

  </Step>
  <Step title="토큰을 head에 싣기">

Web은 토큰의 이름만 내보내고 값은 브라우저가 `--coui-*` CSS 변수로 풉니다. `<head>`에 Tailwind와 CoUI가 만든 설정 · 변수를 함께 넣습니다. 다크 모드 변수와 서페이스 스타일 블록(`config.darkVariableBlock` · `config.surfaceStyleVariableBlocks`)은 `<style>`로 바로 넣지 않고, 실행 중에 `<style>` 요소를 만들어 붙이는 `<script>`로 넣습니다.

<Code language="dart" title="head.dart">
final config = ThemeConfig.defaults();
final head = [
  Component.element(
    tag: 'script',
    attributes: {'src': 'https://cdn.tailwindcss.com/3.4.17'},
  ),
  Component.element(tag: 'script', children: [RawText(config.tailwindConfig)]),
  Component.element(tag: 'style', children: [RawText(config.cssVariables)]),
];
</Code>

- Tailwind 는 위처럼 정확한 v3 릴리스로 고정합니다. 버전 없는 CDN 주소는 그날의 릴리스를 따라가고, 색 강제 모드의 포커스 교정이 v3 의 `outline-none` 동작에 기댑니다.
- Tailwind 의 reset(preflight)은 꺼져 있습니다. 브라우저 기본 스타일 초기화가 필요하면 앱이 넣습니다.
- CSP 로 CDN 을 막는 환경에서는 아이콘 스크립트(`iconScript(src: …)` · `normalizerSrc: …`)와 `PhoneInput` 의 국기(`CouiAssetSourceScope(flagIconsBaseUrl: …)`)에 자체 호스팅 경로를 줍니다.

  </Step>
  <Step title="첫 컴포넌트 쓰기">

Button을 화면에 넣어 렌더링을 확인합니다. 컴포넌트 코드는 Flutter와 같습니다.

<Code language="dart" title="home_page.dart">
Button(
  variant: CoreButtonVariant.primary,
  onPressed: save,
  child: Text('저장하기'),
)
</Code>

<Preview demo="button/do-one-primary" height="140" />

  </Step>
</Steps>

  </TabItem>
</Tabs>

Flutter 3.47.0 · Dart 3.11.0 · Jaspr 0.23.5 이상이 필요합니다.

### 버전 고정

pub이 각 플랫폼 패키지의 제약을 읽어 호환되는 `coui_core`를 선택합니다.
앱에서 같은 버전으로 빌드하려면 프로젝트의 `pubspec.lock`을 커밋하세요.
소스를 수정하면서 시험할 때는 플랫폼 패키지와 `coui_core`를 같은 로컬
체크아웃의 `path:`로 지정합니다.

## 다음 단계

<Cards columns="3">
  <Card title="테마 구성하기" href="/guides/theming" more="테마 가이드">

브랜드 컬러와 서페이스 스타일을 프로젝트에 맞게 정합니다.

  </Card>
  <Card title="컴포넌트 둘러보기" href="/components-overview" more="전체 보기">

160개 이상의 컴포넌트를 카테고리별로 살펴봅니다.

  </Card>
  <Card title="Figma 라이브러리" href="/guides/figma-library" more="라이브러리 열기">

디자인 파일에서 같은 이름의 컴포넌트를 씁니다.

  </Card>
</Cards>

## 글꼴

본문 서체 Pretendard 와 코드 서체 Geist Mono 를 씁니다. 코드 안의 한글은 Pretendard 로 그려집니다.

| 플랫폼 | 앱이 할 일 |
|---|---|
| Flutter | Pretendard 를 제공합니다. Geist Mono 는 `coui_flutter` 가 굵기 400 · 500 · 600 · 700 만 싣고 있어, 다른 굵기가 필요하면 앱 `pubspec.yaml` 에 `packages/coui_flutter/GeistSans` · `GeistMono` family 로 선언합니다 |
| Web | 두 서체를 모두 불러옵니다. Geist Mono 를 빠뜨리면 코드 역할이 고정폭이 아니게 됩니다. Flutter 와 같은 글리프로 그리려면 `packages/coui_flutter/lib/fonts/` 의 GeistMono OTF 를 서빙하고 `@font-face` 로 잇습니다 |
