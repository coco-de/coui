# UX Spec: figma-contract-components — Figma 파일 표면 규약

> 이 프로젝트의 UX 표면은 앱 화면이 아니라 **생성되는 Figma 파일 자체**다. 소비자 = 디자이너(인스턴스 사용)·DS 엔지니어(감사)·신규 합류자(학습).

## 1. 페이지 목록 (파일 내)

```text
Pages                       ← 섹션순(Display→Control→Form→Layout)·섹션 내 알파벳순
├ Display / Alert
├ Display / Avatar
├ Display / Badge
│  …
├ Control / Breadcrumb
├ Control / Button
│  …
├ Form / Autocomplete
│  …
├ Layout / Accordion
│  …
└ 🎨 Palette Generator      ← 말미 고정, 불변
```

- 구분 페이지 없음(D-17). 섹션 경계는 접두 + 물리 순서로 스캔.
- Assets 패널(라이브러리 소비 표면)은 Figma 자체 정렬을 따름 — 본 규약의 순서 주장은 파일 내 페이지 목록 한정(CH-005).

## 2. 컴포넌트 페이지 레이아웃 (3프레임)

```text
┌─ {Component} (ComponentSet — 전 축 조합) ──────────┐
│  Variant=…, Size=…, Enabled=… 그리드              │
└───────────────────────────────────────────────────┘
┌─ _Docs / Properties ──────────────────────────────┐
│  caption: packages/coui_core/.../tabs_style.dart  │
│  ┌──────────┬─────────────┬─────────┬──────────┐  │
│  │ 이름      │ 타입         │ 기본값   │ 설명      │  │
│  │ variant  │ CoreTabVariant │ underline │ …    │  │
│  │ size     │ CoreComponentSize │ md   │ …      │  │
│  │ (axes.other · v2 fields 포함 전수)            │  │
│  └──────────┴─────────────┴─────────┴──────────┘  │
└───────────────────────────────────────────────────┘
┌─ _Docs / Examples ────────────────────────────────┐
│  ① 기본 생성자(축 데이터에서 파생)                    │
│  ② .withStyle(CoreTabsStyle(...))                 │
│  ③ 토큰 getter 체인 (.surfaceContainer 류)          │
│  (mono 폰트 · composition slot 은 Text 체인 표기)   │
└───────────────────────────────────────────────────┘
```

- `_Docs /` 접두 = 생성물 표식(FRAME 이라 퍼블리시 비대상 — 표식은 사람 식별용).
- 색·타이포 전부 CoUI variable 바인딩 — 다크·고대비 모드 전환에 문서 프레임도 따라옴. 리터럴 신규 0(G7).

## 3. 인스펙터 표면

- **description**: 한국어(md frontmatter 우선, 영어 카탈로그 fallback) — 인스턴스 선택 시 우측 패널에 노출.
- **documentationLinks**: docs_site 컴포넌트 페이지 URL — description 옆 링크로 노출.
- variant 축 이름 = `Variant` / `Size` / `State` / `Enabled` (축 순서 고정 T-16) — 디자이너 드롭다운 어휘가 코드 enum 어휘와 1:1.

## 4. 접근성·가독

- 문서 프레임 텍스트 = `on-surface`/`on-surface-variant` 토큰(대비 가드 통과 팔레트 재사용), 코드 블록 = mono + `surface-container` 배경.
- 표는 auto-layout 고정 열폭 — 긴 설명은 줄바꿈(고정 높이 금지).
- 언어: 설명 한국어 우선(fallback 영어) — D-6.

## 5. 소비자 시나리오 수용 기준

| 소비자 | 시나리오 | 수용 기준 |
|---|---|---|
| 디자이너 | Tabs 를 pill 로 전환 | Assets 에서 Tabs 인스턴스 삽입 → Variant 드롭다운에 pill 존재 |
| 디자이너 | 비활성 checked 체크박스 | State=Checked + Enabled=False 조합 선택 가능 |
| DS 엔지니어 | 축 감사 | 페이지 Properties 표 = 컨트랙트 전수(축 + other + fields) |
| 신규 합류자 | 코드로 옮기기 | Examples 프레임의 스니펫을 복사해 그대로 컴파일 가능(식 스니펫) |
