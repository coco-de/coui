# 호환성과 업그레이드

[가이드 목차](README.md) · 이전: [Figma](figma.md)

**CoUI를 수정하는 일과 소비 프로젝트가 새 버전을 받는 일은 연결된 별도 작업**입니다.
이 문서는 실제 버전을 올릴 때 확인할 경로를 설명합니다.

## 먼저 변경 영향을 구분합니다

| 변경 | 확인할 질문 |
|---|---|
| nullable Style 필드 추가 | 기존 기본값을 유지하는가? merge/copyWith/동등성과 양쪽 renderer에 연결됐는가? |
| callback/생성자 입력 추가 | 기존 호출이 그대로 컴파일되는가? 양 플랫폼이 같은 API인가? |
| 기본값·토큰 변경 | API는 같아도 기존 화면·배율·상태가 달라지는가? 소비자에게 고지할 내용은? |
| 이름 변경/삭제/required 전환 | 공개 API인가? 대체재·예고 기간·마이그레이션이 준비됐는가? |
| Figma 이름/축/구조 변경 | 기존 인스턴스·override·id/key를 보존하는가? |
| 외부 SDK/의존성 상향 | 모든 workspace 패키지, 생성기, CI의 도구 버전이 호환되는가? |

<a id="deprecation"></a>

### 공개 API의 deprecation

대체재가 동작하는 릴리스에 `@Deprecated`와 대체 이름·이유·
`(since <major>.<minor>)`를 함께 제공하고, 정해진 유지 기간 후 제거합니다.
예를 들어 `0.N`에서 예고한 것은 정책상 `0.N+2`부터 제거 가능합니다.

삭제/이름 변경 PR에는 **옛 코드 → 새 코드**를 보입니다. 의미가 달라져 자동
치환할 수 없으면 그 사실을 먼저 설명합니다. 기존 디자인 기본값을 바꿀 때도
컴파일 성공만으로 호환성을 판단하지 않습니다.

## CoUI 패키지 릴리스

기준 파일은 [release-please-config.json](../../release-please-config.json),
[release.yml](../../.github/workflows/release.yml),
[위 deprecation 정책](#deprecation)입니다.

```text
작업 PR 검사·리뷰 → main 머지
    → Release Please가 release PR 생성/갱신
    → release PR 검사·검토·머지
    → 패키지 버전 / CHANGELOG / 태그 / GitHub Release
    → 소비 프로젝트가 선택한 태그로 갱신
```

- 버전·태그·changelog는 Release Please가 소유합니다. 수동 `melos version`을
  실행하지 않습니다. `coui:release:prepare`의 옛 “version 수정 → melos version →
  pub.dev” 안내도 현재 릴리스 경로가 아닙니다.
- Flutter, Jaspr, Core 패키지의 pub.dev 배포 순서는 [패키지 배포 가이드](publishing.md)를 따릅니다.
- 패키지별 독립 버전이라 형제 태그의 **버전 숫자가 같을 필요는 없습니다**.
  관련 패키지의 태그가 같은 소스 커밋을 가리키는 조합을 확인합니다.
- `docs`만 바꾼 커밋은 패키지 버전 상승을 유발하지 않습니다. 코드에 영향이
  있는 변경은 Conventional Commits의 실제 성격에 맞춰 고지합니다.
- breaking 변경은 `!`/`BREAKING CHANGE:`로 고지합니다. 현재 `0.x`에서는
  `bump-minor-pre-major` 설정이 적용되며 `1.0`은 자동으로 선언하지 않습니다.
  일반 SemVer 설명이나 옛 주석보다 현재 설정과 정책을 확인하세요.
- `BREAKING CHANGE:`의 요약은 같은 줄에서 시작하고 squash 결과에 하나로
  남깁니다. 커밋과 PR 형식은 [PR 가이드](../../CONTRIBUTING.md#pull-requests)에서 확인합니다.

## 소비 프로젝트에서 CoUI 올리기

먼저 사용 중인 각 `coui_*` dependency와 `dependency_overrides`를 조사하고
현재 Git ref와 lockfile의 resolved commit을 기록합니다. 새 태그의 릴리스
노트를 현재 버전부터 읽습니다.

예를 들어 **소비 프로젝트의 pubspec**에서 사용하는 Git dependency는 다음
형태입니다. `<existing-release-tag>`는 GitHub에서 확인한 실제 태그로 바꿉니다.

```yaml
dependencies:
  coui_flutter:
    git:
      url: https://github.com/coco-de/coui.git
      ref: <existing-release-tag>
      path: packages/coui_flutter
```

이것은 dependency 모양만 보여주는 부분 예시입니다. 소비 프로젝트가 Core,
Web, 번역 패키지를 직접 참조하거나 override한다면 그 항목들도 함께
대조합니다. main의 최신 코드와 오래된 태그를 우연히 섞지 않습니다.

ref 수정 후 **소비 Flutter 프로젝트의 루트**에서 실행합니다.

```bash
flutter pub get
git diff -- pubspec.yaml pubspec.lock
```

예상 결과: 선택한 Git ref가 해결되고 lockfile 변경에서 실제 commit을 확인할
수 있습니다. Melos workspace나 Jaspr 전용 소비자는 해당 프로젝트의 bootstrap/
pub 절차를 사용합니다. 버전을 올렸는데 옛 코드가 보이면 로컬 path override가
우선하고 있지 않은지 확인하세요.

이어서 해당 소비 프로젝트의 생성 코드·analyzer·테스트를 실행하고 대표 화면을
확인합니다. 특히 커스텀 Theme/Style, 큰 글꼴·scaling, Light/Dark, overlay와
키보드 동작을 비교합니다. 기본값 변화가 불필요한 화면에는 기존 공개 override
경로로 의도를 명시합니다.

## 외부 의존성이나 SDK를 올리는 기여

CoUI의 버전 번호만 바꾸는 작업과 다릅니다.

1. 루트 및 영향받는 멤버 `pubspec.yaml`, `pubspec.lock`, CI의 SDK/CLI pin을
   대조합니다. Flutter 번들 Dart, analyzer, builder의 호환성을 함께 봅니다.
2. 플러그인 의존성은 `tools/figma-token-sync/package.json`과 npm lockfile을
   함께 검토합니다. 실제 변경 이후 `npm ci`로 재현 가능해야 합니다.
3. [검증 가이드](verification.md)의 해당 경로와 코드 생성, export, build를
   실행하고 산출물 diff를 검토합니다.
4. 바뀐 최소 지원 버전과 소비자 조치를 PR에 기록합니다. 모든 의존성을
   한꺼번에 올리는 명령으로 무관한 변경을 섞지 않습니다.

## Figma와 문서 전달까지 완료하기

| 표면 | 완료를 확인하는 방법 |
|---|---|
| 코드 | 작업 PR이 합쳐진 commit |
| 패키지 | 실제 태그와 GitHub Release |
| 플러그인 | 새 commit으로 만든 bundle/ZIP, 기존 plugin 업데이트 게시 |
| Figma 라이브러리 | 해당 build로 Import/Generate, 리사이즈·identity 검증 후 Publish |
| 소비 Figma 파일 | library update 수신, 기존 인스턴스·override 확인 |
| 문서 사이트 | [문서 배포](../../DOCS_DEPLOYMENT.md) 절차로 해당 콘텐츠 게시 확인 |

코드 머지만으로 위 표의 나머지가 모두 완료되지는 않습니다. Figma의
전체 갱신 순서는 [플러그인 가이드](figma.md)를 따릅니다.

문제가 발견되면 영향받는 프로젝트, 사용 중인 tag/commit과 plugin build,
재현 조건을 기록합니다. 소비자의 ref를 검증된 이전 조합으로 되돌려 확인할
수 있지만 이미 발행된 태그를 새 commit에 강제로 붙여 같은 버전의 의미를
바꾸지는 않습니다.
