---
title: Changelog
description: CoUI의 버전별 변경 사항입니다. Flutter · Web · Core 패키지는 버전을 따로 매겨 배포됩니다.
design: true
---

# Changelog

<ReleaseTimeline />

## 패키지별 CHANGELOG

타임라인은 최근 릴리스만 보여 줍니다. 전체 이력: [coui_flutter](https://github.com/coco-de/coui/blob/main/packages/coui_flutter/CHANGELOG.md) · [coui_web](https://github.com/coco-de/coui/blob/main/packages/coui_web/CHANGELOG.md) · [coui_core](https://github.com/coco-de/coui/blob/main/packages/coui_core/CHANGELOG.md).

## 현재 버전과 git 태그

패키지마다 현재 버전과, `ref:`에 쓰는 그 버전의 git 태그입니다.

### coui_flutter

<CurrentVersion package="coui_flutter" />

<CurrentVersion package="coui_flutter" tag="true" />

### coui_web

<CurrentVersion package="coui_web" />

<CurrentVersion package="coui_web" tag="true" />

### coui_core

<CurrentVersion package="coui_core" />

<CurrentVersion package="coui_core" tag="true" />

## 특정 버전에 고정하기

[빠른 시작](/getting-started#설치)의 `git:` 의존성에 `ref:`로 태그를 적으면 그 커밋에 고정됩니다. `coui_flutter` · `coui_web`이 끌어오는 `coui_core`는 pub.dev에 없어 `dependency_overrides`로 함께 가리키므로, 거기에도 그 릴리스의 `coui_core` 태그를 적습니다(`coui_core`가 오르지 않은 릴리스면 직전 태그).

```yaml
dependencies:
  coui_flutter:
    git:
      url: https://github.com/coco-de/coui.git
      path: packages/coui_flutter
      ref: coui_flutter-v0.192.1 # 예시 — 위 태그로 바꿉니다
dependency_overrides:
  coui_core:
    git:
      url: https://github.com/coco-de/coui.git
      path: packages/coui_core
      ref: coui_core-v0.190.1 # 그 릴리스의 coui_core 태그
```

Web은 `path: packages/coui_web`과 `coui_web-v`로 시작하는 태그를 씁니다. `ref:`가 없으면 `pub upgrade`마다 그때의 `main`을 따라가 릴리스 전의 브레이킹 체인지가 들어올 수 있습니다. `0.x` 동안에는 브레이킹 체인지도 마이너만 올리므로, 마이너를 올리기 전에 CHANGELOG의 `BREAKING CHANGES` 절을 확인하세요.

## 과거 릴리스 문서 (버전 스위처)

문서 사이트 헤더의 **버전** 메뉴는 일부 과거 릴리스 때 빌드해 둔 문서 스냅샷을 엽니다. 스냅샷이 없으면 메뉴도 없습니다.
