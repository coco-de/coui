/// 랜딩의 스타일시트.
///
/// ## 값이 오는 곳
///
/// 이 시트는 숫자를 거의 적지 않는다. 색 · 간격 · 모서리 · 선 굵기 ·
/// 글자 크기는 `--coui-*` 변수이고, 시간과 곡선은 `site_motion.dart` 가
/// 선언한 `--site-duration-*` · `--site-easing-*` 이다. 그래서 다크 모드,
/// 서페이스 스타일, 대비 높이기, 동작 줄이기가 이 시트를 고치지 않고
/// 랜딩에 닿는다.
///
/// 참조한 변수가 실제로 있는지는 `landing_motion_test.dart` 가 본다 —
/// 없는 변수를 가리키는 선언은 브라우저가 조용히 버리고, 그 자리만
/// 다르게 그려진 채 아무 경고도 나지 않기 때문이다.
///
/// ## 면의 역할
///
/// 랜딩은 면을 네 가지로 쓴다 — 페이지, 타일, 타일 안의 들어간 면, 카드.
/// 각 역할은 시안이 연결한 토큰 하나를 두 밝기에서 함께 읽는다 — 밝기마다
/// 다른 토큰으로 바꿔 끼우지 않으므로, 밝을 때와 어두울 때의 면 순서는
/// 팔레트가 정한다. 그 대응을 `--site-*` 역할 변수 한 곳에 적고, 규칙들은
/// 역할만 읽는다.
///
/// ## 등장은 스크립트가 맡았을 때만 숨긴다
///
/// 스크롤 등장(`[data-reveal]`)의 숨김은 `html[data-site-motion]` 아래에만
/// 걸린다. 그 속성은 스크립트가 등장을 맡을 수 있을 때만 붙으므로,
/// 스크립트가 없거나 실패한 문서는 처음부터 전부 보인다.
library;

import 'site_motion.dart';

/// 랜딩 `<style>` 의 내용.
String get siteLandingCss => _vocabulary + _css;

/// 모션 변수와 순차 등장의 상한 — Dart 값이 들어가는 유일한 자리.
String get _vocabulary =>
    '.docs.landing{${SiteMotion.css}'
    '--site-stagger-last:$kSiteStaggerLastIndex;}';

const String _css = r'''
/* ── 역할 ─────────────────────────────────────────────────────── */
/* 셸(`web/docs-shell.css`)은 다크에서 역할마다 다른 토큰을 바꿔 끼운다.
   랜딩은 시안대로 두 밝기에서 같은 토큰을 읽으므로, 다크 규칙도 함께
   진술해 셸의 바꿔 끼우기를 이긴다 — 선택자의 특이도가 한 단 높다. */
.docs.landing,
[data-theme='dark'] .docs.landing {
  --site-page: var(--coui-surface);
  --site-tile: var(--coui-surface-container);
  --site-inset: var(--coui-surface-raised);
  --site-select: var(--coui-surface-container-high);
  --site-card: var(--coui-surface);
  --site-line: var(--coui-outline-subtle);
  --site-ink: var(--coui-on-surface);
  --site-ink-muted: var(--coui-on-surface-variant);
  --site-ink-subtle: var(--coui-on-surface-subtle);
  --site-gutter: max(var(--coui-space-24), calc((100% - 75rem) / 2));
  --site-reveal-offset: var(--coui-space-12);
  background: rgb(var(--site-page));
}

/* ── 공통 ─────────────────────────────────────────────────────── */
/* 문서 페이지도 쓰는 조각(`.site-sr-only` · `.site-box-link` · `.site-arrow`
   · `.site-mark`)은 셸의 시트(`web/docs-shell.css`)에 있다 — 두 레이아웃이
   그 시트를 함께 싣는다. */
/* 구획은 본문 래퍼(`section.content`)가 물려주는 산문의 글자 크기와 줄
   높이(1.75)를 받지 않고 킷의 바탕 역할로 돌아간다. `Text` 는 inline 이라,
   그것을 감싼 상자의 줄 높이가 더 크면 줄 상자가 그 높이로 벌어진다. */
.landing :where(.site-hero, .site-bento, .site-section) {
  font-size: var(--coui-text-body-medium-size);
  line-height: var(--coui-text-body-medium-line-height);
}
/* 브라우저 기본 여백만 지운다. `:where()` 라 특이도가 낮아서, 구획 안에
   놓인 킷 컴포넌트가 같은 태그에 실은 클래스를 덮지 않는다. */
.landing :where(.site-bento, .site-section) :where(h2, h3, p, ul, ol) { margin: 0; }
.landing :where(.site-bento, .site-section) :where(ul, ol) { padding: 0; list-style: none; }
.landing :where(.site-bento, .site-section) :where(h3) { font-size: inherit; font-weight: inherit; }
/* 어절 단위 줄바꿈 — 킷의 `.keepAll` 과 같은 두 선언이다. 줄보다 긴 낱말은
   상자 밖으로 넘치는 대신 낱말 안에서 꺾인다. */
.site-hero-inner h1,
.site-hero-description,
.site-tile-title,
.site-figure-note,
.site-section-head h2,
.site-section-lead { word-break: keep-all; overflow-wrap: anywhere; }

/* ── 등장 ─────────────────────────────────────────────────────── */
@keyframes site-rise {
  from { opacity: 0; transform: translateY(var(--site-reveal-offset)); }
}
.site-rise {
  animation: site-rise var(--site-duration-moderate) var(--site-easing-enter) both;
  animation-delay: calc(var(--site-stagger-step) * min(var(--i, 0), var(--site-stagger-last)));
}
[data-reveal] {
  transition:
    opacity var(--site-duration-moderate) var(--site-easing-enter),
    transform var(--site-duration-moderate) var(--site-easing-enter);
  transition-delay: calc(var(--site-stagger-step) * min(var(--i, 0), var(--site-stagger-last)));
}
html[data-site-motion] .landing [data-reveal]:not(.is-revealed) {
  opacity: 0;
  transform: translateY(var(--site-reveal-offset));
}
/* 인쇄되는 지면은 지금 모습 그대로 나간다 — 오지 않을 스크롤을 기다리는
   구획이 빈 채로 찍히지 않게, 종이에서는 등장 대상이 전부 보인다. 전환도
   끈다: 인쇄는 전환이 시작되는 순간을 찍으므로, 전환이 남아 있으면 숨김을
   풀어도 투명한 채로 나간다. */
@media print {
  html[data-site-motion] .landing [data-reveal]:not(.is-revealed) {
    opacity: 1;
    transform: none;
    transition: none;
  }
}

/* ── 히어로 ───────────────────────────────────────────────────── */
.site-hero > div { width: 100%; min-width: 0; }
.site-hero-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--coui-space-28);
  padding:
    clamp(var(--coui-space-56), 8.3vw, var(--coui-space-120))
    var(--site-gutter)
    clamp(var(--coui-space-56), 6.7vw, var(--coui-space-96));
  text-align: center;
}
.site-hero-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: var(--coui-space-6);
  padding: var(--coui-space-6) var(--coui-space-14);
  border: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  border-radius: var(--coui-radius-9999);
  background: rgb(var(--site-tile));
  transition:
    background-color var(--site-duration-fast) var(--site-easing-move),
    border-color var(--site-duration-fast) var(--site-easing-move);
}
.site-hero-eyebrow:hover {
  border-color: rgb(var(--coui-outline-variant));
  background: rgb(var(--site-select));
}
.site-hero-inner h1 {
  margin: 0;
  font-size: clamp(var(--coui-font-size-36), 5vw, var(--coui-font-size-72));
  line-height: 1.22;
  letter-spacing: -0.02em;
}
.site-hero-line { display: block; }
.site-hero-description {
  margin: 0;
  font-size: clamp(var(--coui-font-size-16), 1.3vw, var(--coui-font-size-18));
  line-height: 1.65;
  letter-spacing: -0.015em;
}
.site-hero-description > span { display: block; }
.site-hero-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: var(--coui-space-10);
  padding-top: var(--coui-space-8);
}

/* ── 벤토 ─────────────────────────────────────────────────────── */
.site-bento {
  display: grid;
  gap: var(--coui-space-16);
  padding: 0 var(--site-gutter) clamp(var(--coui-space-56), 7.8vw, var(--coui-space-112));
}
.site-bento-row { display: grid; gap: var(--coui-space-16); }
.site-bento-row--lead { --site-tile-height: 26.25rem; grid-template-columns: minmax(0, 794fr) minmax(0, 390fr); }
.site-bento-row--tokens {
  --site-tile-height: 21.25rem;
  grid-template-columns: minmax(0, 592fr) minmax(0, 288fr) minmax(0, 288fr);
}
.site-bento-row--tools { --site-tile-height: 18.75rem; grid-template-columns: repeat(2, minmax(0, 1fr)); }
.site-tile {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: var(--coui-space-24);
  min-width: 0;
  min-height: var(--site-tile-height);
  padding: var(--coui-space-32);
  border: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  border-radius: var(--coui-radius-24);
  background: rgb(var(--site-tile));
}
.site-tile-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--coui-space-12);
}
.site-tile-title { display: grid; }
.site-tile-foot { color: rgb(var(--site-ink-subtle)); }
.site-inset {
  border: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  border-radius: var(--coui-radius-16);
  background: rgb(var(--site-inset));
}

/* 컴포넌트 */
.site-figure { display: grid; gap: var(--coui-space-10); }
.site-count {
  display: flex;
  align-items: flex-end;
  gap: var(--coui-space-6);
  color: rgb(var(--site-ink));
}
.site-count-value {
  font-size: clamp(var(--coui-font-size-72), 9.6vw, var(--coui-font-size-128));
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  line-height: 1;
  letter-spacing: -0.06em;
}
.site-count-unit { padding-bottom: var(--coui-space-16); }
.site-chips { display: flex; flex-wrap: wrap; gap: var(--coui-space-8); }
.site-chip {
  display: inline-flex;
  align-items: center;
  gap: var(--coui-space-6);
  padding: var(--coui-space-6) var(--coui-space-12);
  border: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  border-radius: var(--coui-radius-9999);
  background: rgb(var(--site-inset));
  transition:
    border-color var(--site-duration-fast) var(--site-easing-move),
    transform var(--site-duration-fast) var(--site-easing-feedback);
}
.site-chip:is(:hover, :focus-visible) {
  border-color: rgb(var(--coui-outline));
  transform: translateY(calc(var(--coui-space-2) * -1));
}
.site-chip-count { color: rgb(var(--site-ink-subtle)); }

/* 테마 */
.site-theme-controls { padding: var(--coui-space-6) var(--coui-space-20); }
/* 서버는 스위치의 켜짐을 모른다 — 밝기는 브라우저가 정한다. 스크립트가 도는
   문서에서는 island 가 실제 값을 읽을 때까지 줄을 감춘다. 헤더의 밝기
   토글이 hydration 전까지 숨는 것과 같은 이유다: 틀린 상태를 그렸다가
   뒤집는 것보다 아는 순간에 그리는 편이 낫다. */
.site-theme-rows { transition: opacity var(--site-duration-fast) var(--site-easing-enter); }
html[data-site-motion] .site-theme-rows:not([data-ready]) { opacity: 0; visibility: hidden; }
.site-theme-row { padding-block: var(--coui-space-14); }
.site-theme-row + .site-theme-row { border-top: var(--coui-stroke-width-1) solid rgb(var(--site-line)); }
.site-theme-row > [role='switch'] { display: flex; width: 100%; }
.site-theme-row > [role='switch'] > span { flex: 1; justify-content: space-between; }

/* 코드 — 어두운 밝기 범위 안이라 `--coui-*` 가 다크 값이다. 면과 코드
   글자는 팔레트의 고정 단계라 페이지 밝기와 무관하게 같은 색이다. */
.site-tile--code {
  border-color: rgb(var(--coui-neutral-950));
  background: rgb(var(--coui-neutral-950));
}
.site-code-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--coui-space-12);
}
.site-code-tabs { position: relative; display: flex; gap: var(--coui-space-4); }
.site-code-tab {
  position: relative;
  z-index: 1;
  padding: var(--coui-space-6) var(--coui-space-12);
  border: 0;
  border-radius: var(--coui-radius-8);
  background: none;
  color: rgb(var(--coui-on-surface-subtle));
  cursor: pointer;
  transition: color var(--site-duration-fast) var(--site-easing-move);
}
.site-code-tab:is(:hover, [aria-selected='true']) { color: rgb(var(--coui-neutral-300)); }
[data-code-tile]:not([data-ready]) .site-code-tab[aria-selected='true'] {
  background: rgb(var(--coui-surface-container));
}
.site-code-indicator {
  position: absolute;
  inset-block: 0;
  left: 0;
  display: none;
  width: var(--tab-w, 0);
  border-radius: var(--coui-radius-8);
  background: rgb(var(--coui-surface-container));
  transform: translateX(var(--tab-x, 0));
  transition:
    transform var(--site-duration-normal) var(--site-easing-move),
    width var(--site-duration-normal) var(--site-easing-move);
}
[data-code-tile][data-ready] .site-code-indicator { display: block; }
.site-code {
  margin: 0;
  padding: 0;
  overflow-x: auto;
  background: none;
  color: rgb(var(--coui-neutral-300));
  font-family: var(--coui-text-code-md-family);
  font-size: var(--coui-text-code-md-size);
  line-height: var(--coui-text-code-md-line-height);
  letter-spacing: var(--coui-text-code-md-tracking);
  white-space: pre;
}
.site-code[hidden] { display: none; }
.site-code code, .site-response code { padding: 0; background: none; font: inherit; }
.site-code-line { display: block; }
.site-code-line--muted { color: rgb(var(--coui-on-surface-subtle)); }
[data-code-tile][data-ready] .site-code-line {
  animation: site-rise var(--site-duration-fast) var(--site-easing-enter) both;
  animation-delay: calc(var(--site-stagger-step) * min(var(--i, 0), var(--site-stagger-last)));
}
.site-code-note { color: rgb(var(--coui-on-surface-subtle)); }
@keyframes site-pop {
  from { transform: scale(0.9); }
}
[data-code-copy] [data-code-copy-label] { display: inline-block; }
[data-code-copy][data-copy-state] [data-code-copy-label] {
  animation: site-pop var(--site-duration-fast) var(--site-easing-feedback);
}

/* 타이포그래피 */
.site-type-rows { display: grid; gap: var(--coui-space-2); }
.site-type-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--coui-space-12);
  padding-block: var(--coui-space-6);
}
.site-type-row + .site-type-row { border-top: var(--coui-stroke-width-1) solid rgb(var(--site-line)); }
.site-type-sample {
  display: inline-block;
  transition: transform var(--site-duration-fast) var(--site-easing-feedback);
}
.site-type-row:hover .site-type-sample { transform: translateX(var(--coui-space-4)); }
.site-type-size {
  color: rgb(var(--site-ink-subtle));
  transition: color var(--site-duration-fast) var(--site-easing-move);
}
.site-type-row:hover .site-type-size { color: rgb(var(--site-ink)); }

/* 색상 */
.site-swatches {
  display: flex;
  align-self: center;
  gap: var(--coui-space-6);
  width: min(100%, 11rem);
  height: 6.875rem;
}
.site-swatch {
  flex: 1 1 0;
  min-width: 0;
  border-radius: var(--coui-radius-8);
  background: rgb(var(--swatch));
  forced-color-adjust: none;
  transition: flex-grow var(--site-duration-normal) var(--site-easing-move);
}
.site-swatch[data-active] { flex-grow: 2.5; }

/* Figma 라이브러리 · AI · MCP */
.site-tile--split { flex-direction: row; align-items: center; }
.site-split-copy {
  display: flex;
  flex: 1 1 0;
  flex-direction: column;
  align-items: flex-start;
  align-self: stretch;
  justify-content: space-between;
  gap: var(--coui-space-24);
  min-width: 0;
}
.site-layers {
  position: relative;
  flex: 0 0 auto;
  width: 16.875rem;
  padding: var(--coui-space-8);
  border-radius: var(--coui-radius-14);
}
.site-layer-list { display: grid; gap: var(--coui-space-2); }
.site-layer {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: var(--coui-space-10);
  padding: var(--coui-space-8) var(--coui-space-12);
  border-radius: var(--coui-radius-8);
}
.site-layers:not([data-ready]) .site-layer[data-active] { background: rgb(var(--site-select)); }
.site-layer-indicator {
  position: absolute;
  inset-inline: var(--coui-space-8);
  top: 0;
  display: none;
  height: var(--layer-h, 0);
  border-radius: var(--coui-radius-8);
  background: rgb(var(--site-select));
  transform: translateY(var(--layer-y, 0));
  transition: transform var(--site-duration-normal) var(--site-easing-move);
}
.site-layers[data-ready] .site-layer-indicator { display: block; }
.site-layer-glyph {
  flex: none;
  width: var(--coui-size-12);
  height: var(--coui-size-12);
  border: var(--coui-stroke-width-1) solid rgb(var(--coui-outline));
  border-radius: var(--coui-radius-4);
}
.site-layer-property { color: rgb(var(--site-ink-subtle)); }
.site-response {
  flex: 0 0 auto;
  margin: 0;
  padding: var(--coui-space-16);
  border-radius: var(--coui-radius-14);
  color: rgb(var(--site-ink-muted));
  font-family: var(--coui-text-code-sm-family);
  font-size: var(--coui-text-code-sm-size);
  line-height: var(--coui-text-code-sm-line-height);
  letter-spacing: var(--coui-text-code-sm-tracking);
  white-space: pre;
}
@keyframes site-flash {
  from { background: rgb(var(--site-select)); color: rgb(var(--site-ink)); }
}
[data-mcp-field] { border-radius: var(--coui-radius-4); }
[data-mcp-field].is-changed { animation: site-flash var(--site-duration-slow) var(--site-easing-exit); }

/* ── 구획 ─────────────────────────────────────────────────────── */
.site-section {
  display: grid;
  gap: var(--coui-space-40);
  padding: clamp(var(--coui-space-56), 6.7vw, var(--coui-space-96)) var(--site-gutter);
}
.site-section-head {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--coui-space-16) var(--coui-space-24);
}
/* 제목의 크기는 안의 글자 역할(headlineLarge)이 정한다 — 상자는 브라우저
   기본 크기를 지워 줄 상자가 역할보다 커지지 않게만 한다. */
.site-section-head h2 { font-size: inherit; font-weight: inherit; }
.site-section-lead { margin-top: var(--coui-space-12); }

/* 진입 카드 */
.site-entries {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--coui-space-16);
}
.site-entries > li { display: flex; }
.site-entry {
  --entry-ink: var(--coui-on-surface);
  --entry-muted: var(--coui-on-surface-variant);
  --entry-subtle: var(--coui-on-surface-subtle);
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: var(--coui-space-20);
  min-height: 13.75rem;
  padding: var(--coui-space-28);
  border: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  border-radius: var(--coui-radius-20);
  background: rgb(var(--site-card));
  color: rgb(var(--entry-ink));
  transition:
    border-color var(--site-duration-fast) var(--site-easing-move),
    transform var(--site-duration-fast) var(--site-easing-feedback);
}
.site-entry:is(:hover, :focus-visible) {
  border-color: rgb(var(--coui-outline));
  transform: translateY(calc(var(--coui-space-4) * -1));
}
.site-entry--lead {
  --entry-ink: var(--coui-inverse-on-surface);
  --entry-muted: var(--coui-inverse-on-surface);
  border-color: rgb(var(--coui-inverse-surface));
  background: rgb(var(--coui-inverse-surface));
}
.site-entry--lead:is(:hover, :focus-visible) { border-color: rgb(var(--coui-inverse-surface)); }
.site-entry-number { color: rgb(var(--entry-subtle)); }
/* 제목(`h3`)과 링크 글자는 카드의 색을 직접 받는다. 물려받게 두면 본문
   산문 시트가 제목 · 링크에 거는 색이 이겨, 채운 카드에서 두 줄이 면에
   묻힌다. */
.site-entry-title, .site-entry-action { color: rgb(var(--entry-ink)); }
.site-entry-copy { display: grid; gap: var(--coui-space-10); }
.site-entry-note { color: rgb(var(--entry-muted)); }
/* 제목은 카드마다 같은 높이에서 시작하고, 링크는 설명이 몇 줄이든 아래
   가장자리에 놓인다. */
.site-entry-action {
  display: flex;
  align-items: center;
  gap: var(--coui-space-4);
  margin-top: auto;
  text-underline-offset: 0.2em;
}
/* 화살표는 다가갔을 때만 들어온다. 장식(`aria-hidden`)이라 감춰도 잃는
   내용이 없다 — 손가락으로 쓰는 화면에서는 밑줄 친 글자가 링크다. */
.site-entry .site-arrow { opacity: 0; transform: translateX(calc(var(--coui-space-4) * -1)); }
.site-entry:is(:hover, :focus-visible) .site-arrow { opacity: 1; transform: none; }

/* 최근 업데이트 — 선은 목록이 연다. 구획 사이에는 선이 없다. */
.site-updates { border-top: var(--coui-stroke-width-1) solid rgb(var(--site-line)); }
.site-update {
  display: grid;
  grid-template-columns: 10rem 7.5rem minmax(0, 1fr) 5rem;
  align-items: center;
  padding-block: var(--coui-space-20);
  border-bottom: var(--coui-stroke-width-1) solid rgb(var(--site-line));
  transition: background-color var(--site-duration-fast) var(--site-easing-move);
}
.site-update:is(:hover, :focus-visible) { background: rgb(var(--site-tile)); }
.site-update-version, .site-update-date {
  transition: transform var(--site-duration-fast) var(--site-easing-feedback);
}
.site-update:is(:hover, :focus-visible) .site-update-version { transform: translateX(var(--coui-space-8)); }
.site-update:is(:hover, :focus-visible) .site-update-date {
  transform: translateX(calc(var(--coui-space-8) * -1));
}
.site-update-summary { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.site-update-date { color: rgb(var(--site-ink-subtle)); text-align: end; }

/* ── 푸터 ─────────────────────────────────────────────────────── */
.site-footer {
  padding:
    var(--coui-space-56)
    clamp(var(--coui-space-24), 4.45vw, var(--coui-space-64))
    var(--coui-space-64);
}
.site-footer-brand { display: grid; gap: var(--coui-space-12); }
.site-footer-logo { display: flex; align-items: center; gap: var(--coui-space-10); }
.site-footer-note { margin: 0; color: rgb(var(--site-ink-subtle)); }
.site-footer-note > span { display: block; }
/* 킷의 `Footer` 는 열 묶음을 브랜드 바로 옆에서 시작한다. 이 지면은 반대쪽
   끝에 붙이고 열 사이를 더 벌린다 — 묶음은 브랜드의 다음 형제이고 열은 그
   묶음의 자식이다. 열 사이 간격의 나머지는 `Footer` 의 `sectionSpacing` 이
   낸다. */
.site-footer-brand + div { justify-content: flex-end; }
.site-footer-brand + div > div + div { padding-inline-start: var(--coui-space-48); }
.site-footer-links {
  display: grid;
  gap: var(--coui-space-8);
  margin: 0;
  padding: 0;
  list-style: none;
}

/* ── 폭 ───────────────────────────────────────────────────────── */
/* 반으로 나뉜 타일은 설계 폭(지면 75rem 의 절반)에서만 문장과 상자가 나란히
   들어간다. 그보다 좁으면 문장 칸이 두 줄 제목을 못 담으므로 위아래로 쌓는다. */
@media (max-width: 1247px) {
  .site-tile--split { flex-direction: column; align-items: stretch; }
  .site-layers { width: auto; }
}
@media (max-width: 1099px) {
  .site-bento-row--tokens { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .site-tile--code { grid-column: 1 / -1; }
  .site-entries { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 899px) {
  .site-bento-row--lead, .site-bento-row--tools { grid-template-columns: minmax(0, 1fr); }
  .site-bento-row { --site-tile-height: 0; }
  .site-footer-brand { flex-basis: 100%; }
  .site-footer-brand + div { justify-content: flex-start; }
  .site-footer-brand + div > div { flex: 1 1 0; min-width: 0; }
  .site-footer-brand + div > div + div { padding-inline-start: 0; }
}
@media (max-width: 599px) {
  .site-bento-row--tokens, .site-entries { grid-template-columns: minmax(0, 1fr); }
  .site-tile { padding: var(--coui-space-24); border-radius: var(--coui-radius-20); }
  .site-entry { min-height: 0; }
  .site-hero-description > span { display: inline; }
  .site-update { grid-template-columns: auto minmax(0, 1fr) auto; gap: var(--coui-space-8) var(--coui-space-12); }
  .site-update-summary { grid-row: 2; grid-column: 1 / -1; white-space: normal; }
  .site-update-date { grid-row: 1; grid-column: 3; }
}
''';
