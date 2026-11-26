# docs_app

`docs_site` 의 **네이티브 Flutter 쌍둥이**. 같은 문서를 웹사이트가 아니라 Flutter 런타임에서 연다.

## 왜 있나

docs_site 의 "Flutter" 프리뷰 페인은 jaspr 에 임베드된 **Flutter Web(canvaskit)** 이다. 즉 매일 보는 Flutter 파리티는 *Flutter Web* 파리티지 네이티브 파리티가 아니다. docs_app 은 같은 예제·같은 토큰을 **네이티브 렌더 경로**로 그려서 그동안 검증 사각지대였던 축(텍스트 레이아웃 · 스케일링 · 제스처 · 오버레이)을 실측 가능하게 만든다.

첫날부터 값을 했다 — 네이티브에서만 드러나는 CoUI 발산 두 건을 잡았다.

## 실행

```sh
cd app/docs_app && flutter run     # 선택한 기기로 (macOS · Android · iOS …)
```

서버도, `jaspr serve` 도, adb reverse 도 **필요 없다.** Web 프리뷰는 앱이 자기 프로세스에서 렌더한다 (아래 참조). 인터넷만 있으면 된다 — Web 프리뷰의 폰트·Tailwind 를 CDN 에서 가져오기 때문 (기기 Wi-Fi/데이터로 충분).

## Web 프리뷰가 서버 없이 되는 법

Web 프리뷰는 `coui_web`(jaspr) 컴포넌트라 브라우저가 그려야 한다 — 네이티브 Flutter 는 HTML 을 못 그리므로 그 페인만 `WebView` 다. 하지만 **서버는 필요 없다**: 앱이 jaspr 서버 렌더러(`renderComponent`)로 컴포넌트를 자기 프로세스에서 완전한 HTML 문서로 렌더한 뒤 `WebView.loadHtmlString` 으로 띄운다. 그 HTML 은 `/embed` 라우트가 그리는 것과 **같은 `EmbedPage`** 라, Tailwind/폰트 CDN·CoUI CSS 변수·테마·프리뷰 호스트 CSS 가 사이트와 동일하다.

- jaspr 서버 렌더러가 `dart:io` 를 쓰므로 **네이티브 전용**이다 (macOS/Android/iOS/데스크톱). Flutter **Web** 빌드에서는 conditional import 로 그 페인만 안내로 저하한다 — 나머지는 정상.
- **정적 SSR 렌더**라 클라이언트 JS 하이드레이션이 없다 → 드롭다운·팝오버 같은 **인터랙션은 동작하지 않는다** (시각 파리티는 됨). 인터랙션 비교는 docs_site 에서.
- WebView 가 없는 호스트(위젯 테스트 등)에서는 이 페인만 안내로 저하하고 페이지는 정상.

## 어디서 뭘 읽나 (파생, 복사 아님)

사본이 없다. 전부 docs_site 원본을 읽는다.

| 자산 | 출처 |
|---|---|
| 153개 문서 페이지 | `packages/docs_site/content/**` (Flutter asset) |
| 273개 Flutter 예제 | `package:docs_site/previews/flutter_registry.dart` |
| 코드 스니펫 (Web/Flutter) | `package:docs_site/previews/{code,flutter_code}_registry.dart` |
| 컴포넌트 카탈로그 · 프리뷰 제약 · wide 셋 | `package:docs_site/shared/*` (순수 Dart, 양쪽 공유) |
| Web 프리뷰 렌더 | WebView → `{base}/embed/<component>` |

라우트는 콘텐츠에서 자동으로 나온다 — 마크다운을 추가하면 손댈 곳 없이 살아난다.

## 구조

```
lib/
  main.dart              앱 진입 — 콘텐츠 로드 후 DocsApp
  src/
    docs_app.dart        GoRouter + 테마 + 셸 배선
    content/             asset 로더 · frontmatter · 라우트 해석
    markdown/            마크다운 → CoUI 위젯 (+ tags/ 커스텀 태그)
    preview/             LivePreview — 네이티브 페인 | WebView 페인 | 코드 탭
    page/                페이지 하나를 읽어 렌더
    search/              Cmd+K 컴포넌트 팔레트
    shell/               Scaffold · AppBar · 사이드바 · TOC · 테마 토글
```

## 규칙

- **`analysis_options.yaml` 을 두지 않는다.** 애널라이저가 워크스페이스 루트까지 걸어 올라가 very_good_analysis + coui_lints 규칙을 그대로 먹게 한다. 여기에 파일을 두면(docs_site 가 그랬듯) 그 강제가 통째로 꺼진다.
- UI 파일은 **CoUI 배럴 하나만** import 한다 — `package:flutter/material.dart` 를 같이 import 하면 `avoid_framework_import` 가 뜨고 bare 이름이 ambiguous 해진다.

## 파리티 경계

**진다**: 라우트 · 콘텐츠 · 사이드바/그룹/순서 · 라이브 프리뷰 동작 · 라이트/다크.

**안 진다 (의도)**:
- **산문 CSS 캐스케이드** — jaspr_content 의 em 상대 프로즈 스케일을 Flutter 로 재현하면 CoUI 앱 안에 두 번째 디자인 시스템을 들이는 셈이다. 산문 chrome 은 CoUI 토큰에서 온다. 픽셀 파리티는 **프리뷰 페인**이 진다.
- **heading anchor id** — 사이트의 id 생성기는 한글을 통째로 버리고(`## 개요` → `""`) 중복 제거도 없다. docs_app 은 URL fragment 를 공유하지 않으므로 그 결함을 미러링하지 않는다. 보이는 TOC 라벨은 동일하다.
- **프리뷰 maxHeight** — 제약 티어는 jaspr 임베드 캔버스를 재는 값이다. 네이티브엔 잴 캔버스가 없어 위젯이 자기 높이대로 선다 (minHeight 는 두 페인 정렬을 위해 유지).

## 테스트

```sh
cd app/docs_app && flutter test
```

153개 실제 콘텐츠 페이지가 예외 없이 렌더되는지, 라우트 해석이 실제 asset 에서 도는지까지 검증한다. **패키지 디렉터리에서 실행해야 한다** (상대 경로 · asset 번들 기준).
