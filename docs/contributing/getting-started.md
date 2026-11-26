# 환경 설정과 첫 실행

[가이드 목차](README.md) · 다음: [구조와 용어](architecture.md)

## 1. 도구 확인

| 도구 | 필요한 작업 | 버전/설정의 기준 |
|---|---|---|
| Git | 모든 기여 | `coco-de/coui` 체크아웃 |
| Flutter + 번들 Dart | Dart 워크스페이스, Flutter 및 임베드 Web | [루트 pubspec](../../pubspec.yaml)의 SDK 범위와 [Package checks](../../.github/workflows/public-ci.yml)의 Flutter 버전 |
| Melos | 여러 패키지의 명령 실행 | [루트 pubspec](../../pubspec.yaml) |
| Jaspr CLI | `docs_site` 실행 | 아래 로컬 문서 실행 안내 |
| Node.js/npm | Figma 플러그인 | [Figma 준비](figma.md)와 플러그인 lockfile |
| Figma Desktop + Pretendard | Figma 실제 렌더 확인 | [Figma 준비](figma.md) |

패키지 검사는 Flutter `3.50.1`을 사용합니다. 워크스페이스 명령은 Melos `7.1.1` 기준입니다.
Flutter가 함께 배포하는 Dart를 사용하세요. 서로 다른 SDK 설치의 `dart`와
`flutter`가 PATH에 섞이면 의존성 해석과 포맷 결과가 달라질 수 있습니다.

어느 디렉터리에서나 실행할 수 있는 확인 명령입니다.

```bash
flutter --version
dart --version
flutter doctor
git --version
```

예상 결과: 각 버전이 출력됩니다. `flutter doctor`의 진단 중 **실행할 대상**에
필요한 도구를 준비합니다. 예를 들어 macOS 앱 실행에는 Xcode 설정이 필요합니다.

## 2. 저장소 설치

clone할 상위 디렉터리에서 시작합니다. 이미 checkout이 있다면 그 루트를 엽니다.

```bash
git clone https://github.com/coco-de/coui.git
cd coui
```

이후 **저장소 루트**에서 실행합니다. 전역 실행 파일 경로(`$HOME/.pub-cache/bin`,
Windows는 Dart가 안내하는 Pub Cache의 `bin`)가 PATH에 있어야 합니다.

```bash
dart pub global activate melos 7.1.1
flutter pub get
melos bootstrap
git status --short
```

예상 결과: 루트 workspace의 의존성이 해결되고 bootstrap hook의 locale 생성이
완료됩니다. 멤버 패키지는 `resolution: workspace`를 사용하므로 패키지마다
새 lockfile을 만들 필요가 없습니다. 상태 출력에 변경이 있으면 생성/lockfile
변경인지 먼저 읽습니다.

## 3. 필요한 코드 생성

일반적인 기존 Dart 코드 수정마다 전체 생성을 할 필요는 없습니다. 최초 설치에서
생성 파일이 없거나 생성기 입력을 바꿨다면 **루트**에서 아래 명령을 사용합니다.

```bash
melos run generate
```

예상 결과: `build_runner`를 쓰는 패키지들의 생성이 완료됩니다. 전체 workspace
생성이므로 시간이 걸릴 수 있습니다. `--delete-conflicting-outputs`를 포함하는
스크립트이니 수작업 원본을 생성 경로에 두지 마세요.

번역 원본을 바꾼 경우에는 **루트**에서 별도로 실행합니다.

```bash
melos run generate:locale
```

예상 결과: Slang locale 파일이 갱신됩니다. Figma JSON/bundle 생성은 이 명령들이
담당하지 않습니다. 해당 경로는 [Figma 가이드](figma.md)입니다.

## 4. 화면 열기

아래 블록들은 **각각 새 터미널의 저장소 루트에서 시작**합니다. 앞 블록의
`cd` 위치를 이어받지 마세요. 실행 중인 서버는 해당 터미널에서 `Ctrl+C`로 종료합니다.

### Flutter 컴포넌트 실험실

bootstrap/필요한 코드 생성이 끝났고 Chrome이 설치돼 있어야 합니다.

```bash
cd app/coui_widgetbook
flutter run -d chrome
```

예상 결과: Widgetbook이 브라우저에 열립니다. `Badge`를 찾아 크기/변형을
둘러보세요. 실행 터미널의 `r`은 hot reload, `R`은 hot restart입니다.
상수나 시작 설정 변경이 반영되지 않으면 restart합니다.

### Web 문서와 양 플랫폼 프리뷰

Jaspr CLI를 설치합니다.
CLI는 `docs_site`가 쓰는 `jaspr`와 같은 0.N 계열이어야 합니다. 0.23 계열 CLI는
0.24 프로젝트를 "Incompatible jaspr dependency"로 거부합니다.

```bash
dart pub global activate jaspr_cli 0.24.0-beta.1
cd docs_site
jaspr serve
```

예상 결과: 로그에 나온 로컬 URL(기본 `http://localhost:8080`)에서 문서 사이트가
열립니다. `/components/badge`에서 Web/Flutter 프리뷰를 비교합니다. 첫 빌드는
임베드 Flutter도 준비하므로 시간이 걸릴 수 있습니다. `melos run docs:serve`는
`docs/` 정적 파일 서버여서 이 Jaspr 사이트 실행 명령과 다릅니다.

### 네이티브 Flutter 문서 앱 (선택)

macOS 개발 도구가 준비된 경우입니다. 다른 환경에서는 `flutter devices`가
보여주는 사용 가능한 대상 ID로 바꿉니다.

```bash
cd app/docs_app
flutter run -d macos
```

예상 결과: 같은 `docs_core` 콘텐츠를 읽는 네이티브 문서 앱이 열립니다.

## 5. 다음으로 넘어가기 전

- [ ] 코드와 문서가 한 checkout의 로컬 패키지를 참조한다.
- [ ] 원하는 프리뷰 하나를 열었다.
- [ ] 생성 과정의 변경을 `git status`로 확인했다.

이제 [구조와 용어](architecture.md)를 읽고 [첫 변경](first-change.md)으로
넘어갑니다. 설치 오류는 [문제 해결](verification.md)에서 시작하세요.
