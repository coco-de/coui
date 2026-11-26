# Web+Flutter 듀얼 프리뷰 실시간 토큰 편집기 탐색 스파이크

- 일자: 2026-08-02
- 이슈: [#3592](https://github.com/coco-de/coui/issues/3592) (Epic E — 장기 AI · 생태계 인프라, 탐색)
- 산출물 성격: **탐색 스파이크** — "테마 축 조합 원칙의 사용자-노출 API 이식 가능성 검토가 선행 질문"(`.claude/docs/docs-benchmark-followup/zenhub/priority.md`). 이 문서는 실제 렌더링 경로를 읽어 실현 가능성을 판정하며, 구현하지 않는다.
- 관련: `docs/docs-benchmark-2026-08-01.md` §4 line 66, 78 · `.claude/rules/core/theme-axis-composition.md`(이 스파이크의 평가 기준) · `docs_site/lib/components/live_preview.dart` · `docs_site/lib/widgets/preview_app.dart`

## 한 줄 결론

**부분 실현 가능 — Web 쪽은 이미 완성된 손잡이가 있고, Flutter 쪽은 손잡이 자체가 없다.** `CoUIThemeController.setCustomTheme()` 이 임의 `CoreColorScheme` 을 런타임에 `--coui-*` CSS 변수로 밀어넣는 경로는 이미 프로덕션 코드에 존재하며 `LivePreview` 가 그저 안 쓰고 있을 뿐이다. 반면 Flutter 쪽(`PreviewApp`)은 dark/light 플래그 + 5단 표면 스타일 enum 만 200ms 폴링으로 받고, **토큰 단위 값을 받는 경로가 없다** — `theme-axis-composition.md` 의 "축은 양 플랫폼 transport 를 동시에 설계한다"(같은 손잡이가 없으면 착수 보류) 원칙을 그대로 적용하면, **이 기능은 지금 착수하면 안 되는 상태**다. 착수 가능해지려면 Flutter 쪽에 "임의 `CoreColorScheme` 을 런타임에 주입"하는 손잡이를 먼저 만들어야 하고, 그 작업이 이 스파이크가 찾아낸 유일한 실질적 착수 조건이다.

## 1. 이 스파이크가 답해야 하는 질문

daisyUI Theme Generator(슬라이더+실시간 프리뷰+export)와 Astryx `defineTheme` 을 참고해, 기존 `LivePreview`에 `CoreScheme`(정확히는 `CoreColorScheme`)/`CoreSemanticMapping` 토큰 슬라이더를 얹어 "토큰을 바꾸면 두 플랫폼이 실제로 같이 움직이는가"를 시각 검증하는 도구가 실현 가능한지. 이슈 우선순위 근거란이 명시한 선행 질문 — "테마 축 조합 원칙의 사용자-노출 API 이식 가능성" — 을 그대로 평가축으로 쓴다: **`theme-axis-composition.md` 는 이미 CoUI 안에서 "런타임에 색을 바꿔도 전 컴포넌트가 안전하게 따라오는가"를 판정하는 체크리스트를 갖고 있다.** 이 도구는 정확히 그 질문을 시각적으로 보여주는 물건이므로, 새 평가 기준을 만들 필요 없이 기존 체크리스트를 그대로 적용한다.

## 2. `LivePreview` 오늘의 구조 — 정적 쇼케이스 확인

`docs_site/lib/components/live_preview.dart`(230줄)의 `_LivePreviewPanel`(line 97-229)이 Web/Flutter 를 나란히 그린다:
- Web 쪽 — `WebPreview`(`docs_core/lib/components/web_preview.dart`) 가 `CoUIWeb(theme: ThemeData.coui, child: builder(...))` 로 고정 테마를 준다.
- Flutter 쪽 — `FlutterPreview`(`docs_site/lib/components/flutter_preview.dart`) 가 `FlutterEmbedView`(`package:jaspr_flutter_embed`)로 `PreviewApp` 을 붙인다.

**인터랙션은 코드 탭 전환과 복사 버튼뿐**(`live_preview.dart:144-171`, `docs_site/test/components/live_preview_test.dart` 로 확인) — `docs/docs-benchmark-2026-08-01.md:78` 의 "고정 variant 쇼케이스일 뿐 편집 가능한 플레이그라운드가 아님" 주장은 코드로 확인된다. 토큰/색을 바꾸는 컨트롤은 존재하지 않는다.

## 3. Web 쪽 — 손잡이가 이미 있다 (미사용 상태)

`packages/coui_web/lib/src/base/theme_controller_web.dart:356-375`:

```dart
static void setCustomTheme(
  CoreColorScheme colorScheme, {
  CoreBrightness brightness = .light,
  double radiusScaling = 1.0,
}) {
  final theme = CoreThemeData(colorScheme: colorScheme, brightness: brightness, ...);
  final vars = CssVariableGenerator.generate(theme);
  final root = web.document.documentElement;
  // ... htmlRoot.style.setProperty(entry.key, entry.value) for every --coui-* var
}
```

이 함수는 **임의 `CoreColorScheme` 을 받아 즉시 모든 `--coui-*` CSS 변수를 갱신**한다 — 브라우저가 그 변수를 참조하는 모든 요소를 다시 그리므로, Dart 쪽 리렌더/rebuild 가 전혀 필요 없다. 단순 dark/light 토글도 같은 패턴이다: `setTheme()`(`theme_controller_web.dart:182-184`)이 `data-theme` attribute 만 바꾸면 미리 생성된 `[data-theme="dark"]{...}` CSS 블록(`theme_config.dart:919-925`)이 브라우저 native 로 적용된다.

**결론**: 슬라이더 UI 가 `PrimitiveColors.generate(...)`(`packages/coui_core/lib/src/color/primitive_colors.dart:298-306`, 7개 HSL 입력 + neutralHue) → `CoreSemanticMapping.light(customPrimitives)` → `CoUIThemeController.setCustomTheme(scheme)` 를 호출하기만 하면 Web 쪽은 **오늘 당장** 실시간 반응한다. 새 인프라가 필요 없다 — 이미 있는 프로덕션 API 를 `LivePreview` 가 그동안 호출하지 않았을 뿐이다.

## 4. Flutter 쪽 — 손잡이가 없다 (핵심 갭)

`docs_site/lib/widgets/preview_app.dart`의 `_PreviewAppState`:

- `initState()`(line 87-95)에서 `document.documentElement.getAttribute('data-theme')` 를 `dart:js_interop` `eval()` 로 읽어 `_isDark` 초기값을 정한다.
- `_observeThemeChanges()`(line 97-125)가 `MutationObserver` + **200ms `Future.doWhile` 폴링**으로 `data-theme`/표면 스타일 attribute 변화를 감지하면 `setState()` 로 **`coui.CoUIApp` 전체를 하드코딩된 `CoreThemePresets.previewDark`/`previewLight` 로 재구성**한다(line 129, 139-167).

**여기가 이 스파이크의 핵심 발견이다: Flutter 쪽이 받는 것은 "다크냐 아니냐"(bool) 와 "표면 스타일 5종 중 어느 것이냐"(enum) 뿐이고, 임의 `CoreColorScheme` 값을 받는 경로가 원리적으로 없다.** `CoreThemePresets.previewDark`/`previewLight` 는 고정된 `static final` 값(`packages/coui_core/lib/src/theme/core_theme_presets.dart:20-70`)이지 슬라이더가 만든 커스텀 scheme 이 아니다. Web 처럼 "런타임에 임의 CoreColorScheme 을 주입"할 진입점이 Flutter 쪽엔 없다 — 폴링 채널이 나르는 데이터 자체가 그런 값을 표현하지 못한다.

## 5. Web-Flutter 브리지는 iframe 이 아니다 — 새 채널을 만드는 게 아니라 채널의 "대역폭"을 넓히는 문제

`package:jaspr_flutter_embed` 는 Flutter 의 멀티뷰 웹 임베딩(`flt.runWidget(MultiViewApp(...))`, `flutter_embed_view_web.dart:20-46`)을 써서 **Flutter 프레임워크와 Jaspr 코드를 같은 JS 힙 안에서** 돌린다 — iframe 도 아니고 `postMessage` 도 없다(패키지 전체에 `postMessage`/`iframe` 참조 0건). 즉 슬라이더가 만든 값을 실행 중인 Flutter 인스턴스로 밀어넣는 데 **iframe 간 메시징이라는 아키텍처 장벽은 없다** — 지금 200ms 폴링을 쓰는 이유는 그 장벽 때문이 아니라, 단지 아직 아무도 더 나은 채널(예: 두 쪽이 공유 가능한 `ValueNotifier`/전역 레지스트리)을 배선하지 않았기 때문이다.

이건 좋은 소식과 나쁜 소식을 동시에 말한다:
- **좋은 소식**: 근본적인 아키텍처 재작업(iframe 제거, postMessage 프로토콜 설계)이 필요 없다 — 같은 JS 힙 안에서 값을 주고받는 더 촘촘한 채널만 있으면 된다.
- **나쁜 소식**: "더 촘촘한 채널"은 여전히 **새로 만들어야 하는 미배선 인프라**다. 폴링에서 "dart:js_interop 로 임의 `CoreColorScheme` 을 JSON 왕복하고, 그걸 파싱해 `CoreThemeData` 를 재구성해 `CoUIApp` 에 주입"하는 형태로 확장하는 작업이며, 이 저장소에 그 형태의 선례가 없다.

## 6. `theme-axis-composition.md` 체크리스트 적용 — "양 플랫폼에 같은 손잡이가 있는가"

이슈 우선순위 근거란이 지정한 선행 질문을 그대로 적용한다. 관련 규칙 원문(`.claude/rules/core/theme-axis-composition.md` "축은 양 플랫폼 transport 를 동시에 설계한다"):

> 축은 두 플랫폼에서 **같은 손잡이**를 가질 때만 착수한다. 한쪽에만 표현 수단이 있으면 그 축은 미착수 상태로 두고, 없는 쪽의 transport 를 먼저 만든다. […] 판정: 축이 바꾸려는 값이 각 플랫폼에서 **참조 정체성을 갖는가**.

이 스파이크의 §3/§4가 정확히 이 판정에 해당하는 사실을 만들었다:

| 플랫폼 | 임의 `CoreColorScheme` 을 런타임에 주입하는 손잡이 | 참조 정체성 |
|---|---|---|
| Web | **있음** — `CoUIThemeController.setCustomTheme(scheme)` (§3) | CSS 변수 이름(`--coui-primary` 등)이 참조 정체성을 가짐 — 값을 몇 번이든 갈아끼울 수 있음 |
| Flutter | **없음** — `PreviewApp` 은 고정 프리셋 2개(dark/light) 중 하나만 select (§4) | 폴링 채널이 나르는 건 bool/enum 뿐, `CoreColorScheme` 값 자체를 나를 수단이 없음 |

판정 규칙을 그대로 따르면: **이 축(=슬라이더가 조작하는 "현재 미리보기 색상 스킴")은 "미착수 상태로 두고, 없는 쪽(Flutter)의 transport 를 먼저 만든다"** 가 결론이다. Web 쪽부터 슬라이더를 배선하면 "Web 만 실시간으로 움직이고 Flutter 는 그대로"인 반쪽 데모가 나오는데, 이 도구의 존재 이유가 정확히 "두 플랫폼이 같이 움직이는가"를 보여주는 것이므로, 반쪽 구현은 **이 도구의 핵심 가치를 부정**한다(daisyUI Theme Generator 는 애초에 단일 렌더 엔진(CSS)이라 이 문제 자체가 없다 — CoUI 가 벤치마크에서 못 훔쳐올 수밖에 없는 지점이 여기서도 반복된다, `docs/docs-benchmark-2026-08-01.md:13`).

체크리스트의 나머지 항목 중 이 도구에 유의미하게 적용되는 것들:

- **"모든 축은 하나의 seat 에 앉는다"**: Web 은 이미 지킨다(`CssVariableGenerator.generate()` 단일 진입점). Flutter 쪽 신규 배선도 `CoreThemeData` 생성 지점(`CoUIApp` 의 theme 슬롯) 하나로 들어가야지, 개별 위젯이 슬라이더 값을 직접 읽는 우회로를 만들면 안 된다.
- **"축이 만질 수 있는 필드는 전부 값 동등성에 포함된다"**: `CoreColorScheme` 은 이미 62 슬롯 전부를 `_equalitySlots`(`color_scheme.dart:1030-1097`)로 `==`/`hashCode` 에 반영하고 있음을 확인(§7) — 이 요건은 이미 충족.
- **"고대비 축과 같은 seat"**: `highContrastLight`/`highContrastDark` 는 "같은 62 슬롯을 더 강한 값으로 해석"하는 오버라이드 세트다(`semantic_mapping.dart:197-201`, §7) — 슬라이더가 만드는 커스텀 scheme 도 이 62 슬롯 구조를 그대로 따라야 고대비 축과 같은 seat 를 공유한다. 슬라이더가 임의의 새 필드를 만들어내면 안 된다.

## 7. `CoreColorScheme` / `CoreSemanticMapping` 실측 — 슬라이더가 조작할 입력의 크기

- `CoreColorScheme`(`packages/coui_core/lib/src/color/color_scheme.dart`) — 정확히 **62 슬롯**(`_equalitySlots`, line 1030-1097, `hashCode` 주석이 "62개라 `Object.hash` 로 못 담아 `hashAll` 을 쓴다"고 명시). `const` 전용이 아니다 — `fromMap()` 런타임 팩토리, `copyWith()`, `lerp()` 를 이미 갖췄다.
- `CoreSemanticMapping.light(PrimitiveColors)`(`semantic_mapping.dart:19-101`) — `PrimitiveColors` 하나를 받아 62 슬롯 전체를 계산한다.
- `PrimitiveColors.generate()`(`primitive_colors.dart:298-306`) — **7개 `({h, s, l})` HSL 레코드 + `neutralHue` 1개**, 총 8개 입력. 이것이 슬라이더 UI 가 실제로 노출해야 할 컨트롤의 개수다 — 62개 슬롯 각각을 슬라이더로 만드는 게 아니라, 8개 원시 입력을 슬라이더로 노출하면 `CoreSemanticMapping.light/dark()` 가 62 슬롯 전체를 파생시킨다. daisyUI Theme Generator 의 "소수 슬라이더 + 파생 팔레트"와 동일한 규모.

## 8. SSG 제약 — 이미 두 번 증명된 안전한 패턴

`docs_site` 는 확정적으로 정적 생성(`pubspec.yaml:104` `jaspr: { mode: static }`, `docs_site/test/infrastructure/pubspec_test.dart:29-30` 가 이를 회귀 테스트로 고정)이다. `docs_site/lib/components/surface_style_switcher.dart:24-33` 의 주석이 이 제약을 정확히 설명한다: "이 사이트는 정적으로 렌더된다: 컴포넌트의 `events:` 맵은 서버 사이드 클로저라 브라우저에 절대 도달하지 않는다."

**하지만 이 문제는 이미 이 저장소에서 두 번 풀렸다** — `FlutterPreview`/`WebPreview` 자체가 `@client` 하이드레이션 아일랜드이고, `SurfaceStyleSwitcher` + prepaint 인라인 스크립트(`localStorage` 복원) + delegated click 리스너 패턴이 이미 동작 중이다. 슬라이더 UI 는 이 두 선례를 그대로 따르는 세 번째 `@client` 아일랜드이며, **SSG 제약은 이 스파이크의 병목이 아니다** — 병목은 §4/§6 의 Flutter 쪽 transport 부재뿐이다.

## 9. 실현 가능성 종합 판정

| 구성 요소 | 실현 가능성 | 근거 |
|---|---|---|
| 슬라이더 UI (8개 HSL 입력, `@client` 아일랜드) | **가능 — 저위험** | `SurfaceStyleSwitcher`/`FlutterPreview` 선례 재사용(§8) |
| Web 프리뷰 실시간 반응 | **가능 — 오늘 당장, 신규 인프라 0** | `setCustomTheme()` 이미 프로덕션(§3) |
| Flutter 프리뷰 실시간 반응 | **불가능 — 선행 작업 필요** | 임의 scheme 을 나르는 transport 부재(§4), `theme-axis-composition.md` 판정상 착수 보류 대상(§6) |
| "두 플랫폼이 같이 움직이는가"라는 도구의 존재 목적 | **Flutter transport 없이는 달성 불가** | 반쪽 구현은 핵심 가치를 부정(§6) |

## 10. 권고 (미착수 — 방향만)

1. **선행 작업으로 명시 분리**: "Flutter 쪽에 임의 `CoreColorScheme` 런타임 주입 손잡이 만들기"는 이 스파이크가 상정한 "토큰 슬라이더 UI 만들기"와 **다른 크기의 작업**이다 — 전자는 아키텍처 인프라(같은 JS 힙 안에서 Dart↔Dart 값 전달 채널 설계), 후자는 UI 다. 착수한다면 전자를 별도 이슈로 먼저 완료해야 하고, 후자는 그 위에 얹는다.
2. **8개 입력으로 스코프를 좁혀라**: 62 슬롯을 전부 개별 슬라이더로 노출하지 않는다(§7) — `PrimitiveColors.generate()` 의 8개 HSL 입력만 노출하면 daisyUI 급 사용성과 CoUI 의 seat 구조(§6)를 동시에 만족한다.
3. **고대비 축과 뒤섞지 않는다**: 슬라이더가 만드는 커스텀 scheme 은 `highContrastLight/Dark` 오버라이드 경로와 별개로 취급 — 이 스파이크는 "임의 브랜드 색 실험" 축이지 접근성 축이 아니다.
4. **명시적으로 미룸**: export 기능(daisyUI 의 "export" 버튼처럼 슬라이더 값을 코드로 내보내는 것), 슬라이더 값의 영속화(URL 쿼리 파라미터 vs localStorage), 다중 프리뷰 패널 동시 반영(현재 `_VariantGallery` 는 컴포넌트당 여러 패널을 그린다 — 전부 같은 scheme 을 봐야 하는지, 패널별 독립인지) — 전부 "구체 스코프 미정"에 해당하며 별도 이슈로 쪼개야 할 크기.

## 11. 같이 보기

- `.claude/rules/core/theme-axis-composition.md` — 이 스파이크의 평가 기준(§6).
- `packages/coui_web/lib/src/base/theme_controller_web.dart` — Web 쪽 이미 존재하는 런타임 주입 손잡이(§3).
- `docs_site/lib/widgets/preview_app.dart` — Flutter 쪽 현재 폴링 브리지, transport 부재의 실측 위치(§4).
- `docs_site/lib/components/surface_style_switcher.dart` — `@client` 아일랜드 + prepaint 스크립트 선례(§8).
- `docs/docs-benchmark-2026-08-01.md` — 이 스파이크의 출처가 된 벤치마크.
