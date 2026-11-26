# BDD Scenarios: CoUI Responsive Breakpoint Contract (반응형 Breakpoint 판정)

> **PRD**: [docs/prd-responsive-breakpoints.md](prd-responsive-breakpoints.md)
> **Seed Spec**: [docs/seed-spec-responsive-breakpoints.md](seed-spec-responsive-breakpoints.md) (v3, 최종 확정본 — Consensus Panel 3/3 APPROVE)
> **Decision Log**: [docs/decision-log-responsive-breakpoints.md](decision-log-responsive-breakpoints.md) (A~J 절)
> **기능 슬러그**: `responsive-breakpoints`

---

## 읽기 전 주의사항

1. **경계값은 전부 예시(pending Q1)** — 아래 시나리오에 등장하는 구체적 px 값(mobile=0, tablet=768(md), desktop=1024(lg))은 Seed Spec §3.2-C / PRD §5.1 의 예시 `CoreBreakpointContract.defaultBoundaries` 를 그대로 가져온 것이다. 실제 확정값은 **Q1(디자이너 + 코코드 내부 개발팀 리드 합의)** 완료 후 정해진다(PRD §8 Q1). 이 문서의 시나리오는 **경계값 자체의 최종 확정을 주장하지 않으며**, 판정 로직·fallback·override·크로스플랫폼 파리티 같은 **구조/동작**을 검증하기 위한 것이다.
2. **엔티티 요약** (PRD §5.2 그대로 인용):
   - `CoreBreakpoint` — 유일한 진짜 px 값 소스(xs/sm/md/lg/xl/xxl, 기존·불변).
   - `CoreBreakpointTier` — `{mobile, tablet, desktop}`, 자기 pixel 값을 저장하지 않는 순수 파생 enum.
   - `CoreBreakpointContract.defaultBoundaries` — tier 경계 default(behaviour 값)의 유일한 출처(Decision Log E-2).
   - `Breakpoint`(Flutter/Web 각 1개, `implements CoreBreakpointContract`) — 위젯이 아닌 non-widget 값-접근자 클래스(Decision Log E-1).
   - `resolveBreakpoint(context, {boundaries:})` — 단일 진입점 Resolver, 전역 뷰포트 폭 관측(FR-3, §3.4-A).
   - `context.breakpointTier` / `context.isDesktop` 등 `BuildContext` extension — 실사용 진입점(FR-4).
3. **NG7 전제** — 값 분기 유틸리티(`context.responsive<T>(mobile:, tablet:, desktop:)`)는 Phase 1 비목표로 최종 확정됐다(PR-0 스캔 근거, Decision Log I-1/J-3, 재도입하지 않음·재론 대상 아님). 아래 시나리오는 이 전제를 어기지 않는다 — tier/breakpoint **조회** 는 공식 API 이고, 그 조회 결과로 개발자가 직접 분기(if/switch)하는 것도 공식 지원되는 사용 형태다.
4. **태그 범례**: `@happy-path`(기본 동작) · `@cross-platform`(Flutter/Web 파리티) · `@override`(경계 override) · `@edge-case`(경계/실패 상태) · `@migration`(PR-0 실사용 교체) · `@ng7`(값 분기 유틸리티 부재 전제 확인) · `@adoption-evidence`(SC-4 채택 증거) · `@needs-design-detail`(Seed Spec/PRD 가 명시적으로 확정한 문구가 아니라 시나리오 작성자가 정책을 유추 확장한 것 — Design 단계 산출물이 확정되기 전에는 자동화 대상이 아니며, BDD 자동화 도구는 이 태그가 붙은 시나리오를 즉시 실행 가능한 시나리오와 구분해야 한다).

---

## Feature 1 — 기본 tier 판정

> 근거: Seed Spec §3.5(파라미터화·null-safe 위임), §4 FR-1/FR-2, PRD §5.1(값의 흐름 다이어그램).

```gherkin
Background:
  Given CoreBreakpoint 는 xs(0px) / sm(640px) / md(768px) / lg(1024px) / xl(1280px) / xxl(1536px) 6단 스케일이다
  And CoreBreakpointContract.defaultBoundaries 는 다음과 같다 (예시값, Q1 팀 합의 전)
    | tier    | CoreBreakpoint |
    | mobile  | xs (0px)       |
    | tablet  | md (768px)     |
    | desktop | lg (1024px)    |
```

### Scenario Outline: 뷰포트 폭에 따라 올바른 tier 가 반환된다

```gherkin
@happy-path
Scenario Outline: 뷰포트 폭 경계값에서 정확한 tier 판정
  Given override 없이 CoreBreakpointContract.defaultBoundaries 를 그대로 사용한다
  When 전역 뷰포트 폭이 "<폭_px>" 인 상태에서 resolveBreakpoint(context) 를 호출한다
  Then context.breakpointTier 는 "<기대_tier>" 를 반환한다

  Examples:
    | 폭_px | 기대_tier |
    | 0     | mobile    |
    | 639   | mobile    |
    | 640   | mobile    |
    | 767   | mobile    |
    | 768   | tablet    |
    | 1023  | tablet    |
    | 1024  | desktop   |
    | 1536  | desktop   |
    | 3000  | desktop   |
```

### Scenario: tier 경계값 자체(md=768, lg=1024)에서는 상위 tier 로 판정된다

```gherkin
@happy-path @edge-case
Scenario: 경계값과 정확히 일치하는 폭은 상위(더 넓은) tier 에 포함된다
  Given tablet 경계가 CoreBreakpoint.md(768px)로 설정되어 있다
  When 전역 뷰포트 폭이 정확히 768px 이다
  Then context.breakpointTier 는 tablet 을 반환한다 (mobile 이 아니다)
  And 767px 였다면 mobile 을 반환했을 것이다
```

### Scenario: CoreBreakpointTier 는 독립 pixel 값을 저장하지 않는다

```gherkin
@happy-path
Scenario: tier 는 CoreBreakpoint 를 그룹핑할 뿐 스스로 값을 갖지 않는다
  Given CoreBreakpointTier 의 정의 파일을 코드 레벨로 확인한다
  Then 그 파일 안에는 breakpoint px 값을 뜻하는 숫자 literal 이 존재하지 않는다 (doc-comment 제외)
  And breakpoint.toTier(boundaries:) 는 CoreBreakpoint 멤버로의 매핑 함수로만 구현되어 있다
  # 근거: Seed Spec SC-2 검증 방법, FR-1(단일 출처)
```

---

## Feature 2 — Flutter/Web 크로스플랫폼 동일 결과 (파리티 검증)

> 근거: Seed Spec §3.3(cross-platform 동일 named-properties API), §3.4(관측 vs 임계값 분리), FR-3/FR-4, SC-1, NFR-1/NFR-2.

```gherkin
@cross-platform @happy-path
Scenario: 동일 뷰포트 폭에서 Flutter 와 Web 이 동일 tier 를 반환한다
  Given Flutter 앱과 Web(jaspr) 앱이 동일한 CoreBreakpointContract.defaultBoundaries 를 공유한다
  And 두 플랫폼 모두 전역 뷰포트 폭이 900px 이다
  When Flutter 에서 context.breakpointTier 를 조회한다
  And Web 에서 context.breakpointTier 를 조회한다
  Then 두 조회 결과는 동일하게 tablet 이다
  # 근거: SC-1(공개 반환 타입 완전 동일), FR-3(동일한 tier/breakpoint 판정 결과 도출)
```

```gherkin
@cross-platform
Scenario: 조회 API 의 이름과 시그니처가 Flutter/Web 양쪽에서 100% 동일하다
  Given Flutter 의 breakpoint.dart 와 Web 의 breakpoint.dart 를 비교한다
  Then 두 파일 모두 클래스명이 Breakpoint 로 동일하다
  And 두 파일 모두 같은 상대 경로(components/layout/breakpoint/breakpoint.dart)에 위치한다
  And BuildContext extension 의 멤버 이름(breakpointTier, isDesktop 등)이 완전히 동일하다
  And 두 API 의 diff 결과는 비어 있다 (verify.md §7-8 기준과 동일)
  # 근거: FR-4, cross-platform/api.md
```

```gherkin
@cross-platform
Scenario: 관측 메커니즘은 플랫폼마다 다르지만 판정에 쓰이는 값은 동일하다
  Given Flutter 는 LayoutBuilder/MediaQuery.sizeOf 로 전역 뷰포트 폭을 관측한다
  And Web 은 ResizeObserver/전역 media query 로 전역 뷰포트 폭을 관측한다
  When 두 플랫폼이 서로 다른 관측 메커니즘으로 "같은 물리적 뷰포트 폭"을 각자 읽는다
  Then 두 플랫폼이 도출하는 CoreBreakpoint 값과 CoreBreakpointTier 값은 동일하다
  And 관측 메커니즘 자체(LayoutBuilder vs ResizeObserver)는 cross-platform 대칭 판정 대상이 아니다
  # 근거: NFR-2(플랫폼 경유 경로 비대칭 허용, 단 값은 공유), core/design-tokens.md
```

```gherkin
@cross-platform
Scenario: ResolvedBreakpoint 내부 필드 구성이 플랫폼마다 달라도 파리티 위반이 아니다
  Given Flutter 의 ResolvedBreakpoint 와 Web 의 ResolvedBreakpoint 가 각자 다른 내부 필드 구성을 가질 수 있다
  When 두 플랫폼의 공개 조회 API(context.breakpointTier 등)가 동일한 값을 반환한다
  Then 이는 파리티를 충족한 것으로 판정한다
  And ResolvedBreakpoint 데이터 클래스 자체의 필드 구성 차이는 판정 대상이 아니다
  # 근거: SC-1 명시 제외, core/layer-mapping.md(Resolved 레이어 비대칭 정당), Decision Log F-1
```

---

## Feature 3 — boundaries 부분(partial) override

> 근거: Seed Spec §3.2-C/§3.5(v3 재설계), FR-5, NFR-7(c), Decision Log E-2/F-2.

```gherkin
@override @happy-path
Scenario: desktop 경계만 override 하면 mobile/tablet 은 default 로 fallback 하고 크래시가 없다
  Given 프로젝트가 resolveBreakpoint(context, boundaries: {desktop: CoreBreakpoint.xl}) 처럼
    desktop 항목만 채운 부분 override map 을 넘긴다
  When 전역 뷰포트 폭이 900px 인 상태에서 tier 를 조회한다
  Then tablet 경계는 override map 에 없으므로 CoreBreakpointContract.defaultBoundaries 의 tablet(md=768px) 값으로 fallback 한다
  And mobile 경계도 마찬가지로 default(xs=0px) 값으로 fallback 한다
  And 900px 는 desktop override(xl=1280px) 미만이므로 tablet tier 로 판정된다
  And 이 과정에서 예외(null 크래시)가 발생하지 않는다
  # 근거: FR-5, NFR-7(c), Decision Log F-2(non-null assertion 버그 수정)
```

```gherkin
@override @edge-case
Scenario: 빈 override map 을 넘겨도 전체가 default 로 안전하게 fallback 한다
  Given resolveBreakpoint(context, boundaries: {}) 처럼 빈 맵을 넘긴다
  When 전역 뷰포트 폭이 1024px 이다
  Then mobile/tablet/desktop 세 tier 모두 CoreBreakpointContract.defaultBoundaries 값을 그대로 사용한다
  And 예외 없이 desktop tier 가 반환된다
```

```gherkin
@override
Scenario: 두 개 tier 를 동시에 override 하고 나머지 한 개만 default 로 남긴다
  Given resolveBreakpoint(context, boundaries: {tablet: CoreBreakpoint.sm, desktop: CoreBreakpoint.xxl}) 를 호출한다
  When 전역 뷰포트 폭이 700px 이다
  Then tablet 경계는 override 값(sm=640px)을 사용하고 mobile 경계는 default(xs=0px)를 사용한다
  And 700px 는 override 된 tablet 경계(640px) 이상이고 desktop override(xxl=1536px) 미만이므로 tablet tier 로 판정된다
  And 예외가 발생하지 않는다
```

```gherkin
@override
Scenario: override 값의 타입은 항상 CoreBreakpoint 멤버이며 새로운 값 체계를 만들 수 없다
  Given 프로젝트가 tier 경계를 조정하고 싶어 boundaries 파라미터를 사용한다
  Then override 로 넘길 수 있는 값의 타입은 raw px 숫자가 아니라 CoreBreakpoint enum 멤버로 제한된다
  And 이로 인해 아무리 override 를 조합해도 CoreBreakpoint 외에 독립적인 px 값 체계가 새로 생겨나지 않는다
  # 근거: Seed Spec §3.5 point 3("5번째 파편이 아닌 이유")
```

```gherkin
@override
Scenario: override 메커니즘 자체는 Q1(경계값 팀 합의) 확정 여부와 무관하게 동일하게 동작한다
  Given Q1(desktop/tablet/mobile 실제 px 경계값)이 아직 팀 합의로 확정되지 않았다
  When resolveBreakpoint(context, boundaries: {...}) 의 fallback/override 구조를 검증한다
  Then default 값이 어떤 CoreBreakpoint 멤버로 확정되든 fallback·null-safety 동작은 변하지 않는다
  And 따라서 Contract/Style/Theme 골격 구현은 Q1 확정 전에 먼저 진행할 수 있다
  # 근거: FR-5 의존성 각주("Contract/Style/Theme 골격 자체는 FR-2 와 함께 먼저 구현해도 무방")
```

---

## Feature 4 — 엣지케이스: 임베디드/극단적 리사이즈, SSR·초기 렌더, 관측 실패

> 근거: Socratic Level 4(실패 시나리오), Seed Spec §3.4-C, NFR-7(a)(b).

```gherkin
@edge-case
Scenario: 임베디드 WebView/iframe 안에서 네이티브 창 폭이 실제 체감 크기와 달라도 관측값을 그대로 신뢰한다
  Given Flutter 앱이 임베디드 WebView 또는 iframe 안에 렌더링되고 있다
  And 이 경우 "네이티브 창 폭"이 사용자가 실제 체감하는 화면 크기와 다를 수 있다
  When resolveBreakpoint(context) 가 그 상황에서 관측 가능한 폭 값을 읽는다
  Then Contract 는 별도 보정/추정 로직 없이 관측된 값을 그대로 사용해 tier 를 판정한다
  And 이 판정 결과가 실제 체감 크기와 다르더라도 이는 의도된 동작이다 (보정 로직을 추가하지 않는 것이 원칙)
  # 근거: NFR-7(a), §3.4-C("관측값은 있는 그대로 신뢰한다")
```

```gherkin
@edge-case
Scenario: 데스크톱 앱 창을 극단적으로 좁게 리사이즈해도 tier 판정이 정상 동작한다
  Given 데스크톱 Flutter 앱 창이 정상 폭(예: 1200px)에서 desktop tier 로 판정되고 있다
  When 사용자가 창을 극단적으로 좁게(예: 200px) 리사이즈한다
  Then resolveBreakpoint 는 크래시 없이 새로 관측된 200px 값을 기준으로 mobile tier 를 반환한다
  And 200px 가 responsive_framework 의 named breakpoint 범위를 벗어나는 극단값이라도 예외를 던지지 않는다
```

```gherkin
@edge-case
Scenario: Web SSR hydration 이전에는 mobile tier 를 기본값으로 한다
  Given Web(jaspr) 페이지가 아직 hydration 되지 않아 실제 뷰포트 폭을 관측할 수 없다
  When 이 시점에 context.breakpointTier 가 조회된다
  Then CoreBreakpointTier.mobile 이 기본값으로 반환된다
  And hydration 이 완료되어 실제 폭을 관측할 수 있게 되면 그 시점부터 실제 값 기반 tier 로 갱신된다
  # 근거: NFR-7(b), mobile-first 관례
```

```gherkin
@edge-case
Scenario: Flutter 첫 프레임 이전에는 mobile tier 를 기본값으로 한다
  Given Flutter 앱이 아직 첫 프레임을 그리지 않아 LayoutBuilder/MediaQuery 로 폭을 관측할 수 없다
  When 이 시점에 context.breakpointTier 가 조회된다
  Then CoreBreakpointTier.mobile 이 기본값으로 반환된다
  And "일단 desktop 으로 가정했다가 좁은 화면에서 레이아웃이 깨지는" 것보다 안전한 방향으로 폴백한다
  # 근거: NFR-7(b)
```

```gherkin
@edge-case @needs-design-detail
Scenario: 관측 자체가 실패하는 경우에도 예외 없이 mobile tier 로 안전하게 폴백한다
  Given BuildContext 에 아직 뷰포트 정보를 제공할 수 있는 조상(MediaQuery/레이아웃 정보)이 준비되지 않았다
  When 이 상태에서 resolveBreakpoint(context) 또는 context.breakpointTier 가 호출된다
  Then 예외를 던지는 대신 CoreBreakpointTier.mobile 로 안전하게 폴백한다
  And 이 폴백은 SSR hydration 이전/첫 프레임 이전 초기값 정책(NFR-7(b))과 동일한 안전 기본값을 공유한다
  # 주의: 이 시나리오는 NFR-7(b)의 "아직 관측할 수 없는 시점" 정책을
  # "관측 자체가 실패하는 일반 사례"로 확장 적용한 것이다. 정확한 실패
  # 감지/처리 메커니즘 자체의 세부 구현은 Design 단계에서 구체화가
  # 필요하다 — Seed Spec/PRD 가 명시적으로 확정한 문구는 아니다.
```

---

## Feature 5 — 실사용 마이그레이션 시나리오 (PR-0 스캔 기반 교체)

> 근거: Seed Spec §1.1-A(PR-0 스캔 결과), PRD §2.3(구체 마이그레이션 타겟 표), §4.2~4.4(적용 시나리오 A/B/C).

```gherkin
@migration @happy-path
Scenario: login_page.dart 의 largerThan(TABLET) 를 isDesktop 으로 교체해도 동일하게 동작한다
  Given login_page.dart 는 기존에 다음과 같이 구현되어 있었다(PR-0 스캔 §2.3 표 B-1)
    """
    if (context.breakpoint.largerThan(TABLET)) {
      return const DesktopLoginLayout();
    }
    return const MobileLoginLayout();
    """
  When 이 코드를 CoreBreakpointContract 기반 API 로 교체한다
    """
    if (context.isDesktop) {
      return const DesktopLoginLayout();
    }
    return const MobileLoginLayout();
    """
  And 전역 뷰포트 폭이 desktop 경계 이상이다
  Then 교체 전과 동일하게 DesktopLoginLayout 이 렌더링된다
  And 전역 뷰포트 폭이 desktop 경계 미만이면 교체 전과 동일하게 MobileLoginLayout 이 렌더링된다
  # 근거: PRD §4.2 시나리오 A, PR-0 스캔 B-1~B-5(app_router_page, store_page_banner,
  # console_router_page, publisher/instructor_application_success_page 동일 패턴)
```

```gherkin
@migration
Scenario: login_page.dart 에서 3-tier 분기가 필요하면 switch(context.breakpointTier) 로 동일하게 동작한다
  Given 화면이 mobile/tablet 을 동일하게 취급하고 desktop 만 다르게 취급해야 한다
  When 다음과 같이 tier 조회 결과로 직접 switch 분기를 구현한다
    """
    return switch (context.breakpointTier) {
      CoreBreakpointTier.desktop => const DesktopLoginLayout(),
      CoreBreakpointTier.tablet || CoreBreakpointTier.mobile => const MobileLoginLayout(),
    };
    """
  Then 이 결과는 largerThan(TABLET) 기반 bool 분기와 동일한 레이아웃을 반환한다
  # 근거: PRD §4.2
```

```gherkin
@migration
Scenario: book_responsive_container.dart 의 raw MediaQuery 비교를 새 API 로 대체한다
  Given book_responsive_container.dart 는 기존에 다음과 같이 구현되어 있었다 (PR-0 스캔 §2.3 표 C-3)
    """
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Constant.desktopBreakpoint) {        // 800
      return const DesktopReaderLayout();
    } else if (width >= Constant.tabletBreakpoint) {  // 480
      return const TabletReaderLayout();
    }
    return const MobileReaderLayout();
    """
  When 이 코드를 다음과 같이 교체한다
    """
    return switch (context.breakpointTier) {
      CoreBreakpointTier.desktop => const DesktopReaderLayout(),
      CoreBreakpointTier.tablet => const TabletReaderLayout(),
      CoreBreakpointTier.mobile => const MobileReaderLayout(),
    };
    """
  Then 3-tier 각각에 대해 대응하는 Layout 이 반환되는 구조는 동일하게 유지된다
  And Constant.tabletBreakpoint(480)/desktopBreakpoint(800) 와 CoreBreakpointContract.defaultBoundaries
    (예시: tablet=768, desktop=1024) 의 실제 px 값이 다르므로, 이 교체는 레이아웃 분기점 자체를 이동시킨다
  And 이 분기점 이동은 Q1(팀 합의) 확정 이후에만 실서비스에 적용하며,
    기존 Constant 값을 검증 없이 override 파라미터로 그대로 밀어넣지 않는다
  # 근거: PRD §4.3 시나리오 B, Q1 의존성 경고
```

```gherkin
@migration
Scenario: 앱 셸 초기화에서 ResponsiveBreakpoints.builder wrapper 를 제거해도 정상 동작한다
  Given app/kobic 의 main.dart 는 기존에 다음과 같이 구현되어 있었다 (PR-0 스캔 §2.3 표 A-1)
    """
    MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
      ),
      home: const AppRouterPage(),
    )
    """
  When 이 코드를 다음과 같이 교체한다
    """
    MaterialApp(
      home: const AppRouterPage(),
    )
    """
  Then CoreBreakpointContract 기반 조회(context.breakpointTier 등)는 앱 전역에 breakpoint 세트를 사전 등록하지 않고도
    호출 시점마다 BuildContext 로 직접 관측해 정상 동작한다
  And app/kobic_console, app/kobic_widgetbook, BDD 테스트 훅(PR-0 스캔 A-2~A-4)도 동일하게 wrapper 없이 동작한다
  # 근거: PRD §4.4 시나리오 C
```

```gherkin
@migration @adoption-evidence
Scenario: SC-4 최소 채택 증거 커버리지가 충족된다
  Given 코코드 내부 개발팀이 트리거 프로젝트(또는 근거를 남긴 대체 화면)에서 검증을 진행한다
  When 다음 세 가지를 CoreBreakpointContract 기반 API 만으로 최소 1회씩 실제로 사용한다
    | 항목                          | 예시                                        |
    | tier 조회                     | context.isDesktop (login_page.dart)        |
    | mobile/tablet/desktop 3-tier 분기 | switch(context.breakpointTier) (book_responsive_container.dart) |
    | boundaries override(구현됐다면)   | resolveBreakpoint(context, boundaries: {...}) |
  Then 화면 개수가 아니라 이 3가지 API 커버리지가 모두 확인되어야 SC-4 가 충족된 것으로 본다
  # 근거: PRD §4.5(검증 흐름), §7 SC-4, Decision Log B-3
```

```gherkin
@migration @edge-case
Scenario Outline: largerThan(TABLET) 기반 판정과 isDesktop 기반 판정이 갈리는 구간을 명시적으로 확인한다
  Given 트리거 프로젝트 앱 셸의 구 Breakpoint 등록값(MOBILE 0-450/TABLET 451-800/DESKTOP 801-1920)과
    CoreBreakpointContract.defaultBoundaries(mobile=xs/tablet=md=768/desktop=lg=1024)를 함께 고려한다
  When 전역 뷰포트 폭이 "<폭_px>" 이다
  Then 구 largerThan(TABLET) 결과는 "<구_판정>" 이고 신규 context.isDesktop 결과는 "<신규_판정>" 이다
  And 두 판정이 다르면 이는 알려진 회귀이며 팀이 명시적으로 승인한 것이어야 한다

  Examples:
    | 폭_px | 구_판정   | 신규_판정 |
    | 800   | false     | false     |
    | 801   | true      | false     |
    | 1023  | true      | false     |
    | 1024  | true      | true      |
  # 근거: ERR-6a(flow-permutation §4) — 회귀 구간 801~1023px. GAP-5(최우선,
  # Solutioning Gate D7 follow-up).
```

```gherkin
@migration @edge-case
Scenario Outline: raw MediaQuery Constant(480/800) 기반 판정과 defaultBoundaries(768/1024) 기반 판정이 갈리는 구간을 명시적으로 확인한다
  Given 트리거 프로젝트의 구 raw Constant 경계값(tabletBreakpoint=480/desktopBreakpoint=800)과
    CoreBreakpointContract.defaultBoundaries(tablet=md=768/desktop=lg=1024)를 함께 고려한다
  When 전역 뷰포트 폭이 "<폭_px>" 이다
  Then 구 Constant 기반 tier 는 "<구_tier>" 이고 신규 context.breakpointTier 결과는 "<신규_tier>" 이다
  And 두 tier 가 다르면 이는 알려진 회귀 구간이며 팀이 명시적으로 승인한 것이어야 한다

  Examples:
    | 폭_px | 구_tier | 신규_tier |
    | 0     | mobile  | mobile    |
    | 479   | mobile  | mobile    |
    | 480   | tablet  | mobile    |
    | 767   | tablet  | mobile    |
    | 768   | tablet  | tablet    |
    | 799   | tablet  | tablet    |
    | 800   | desktop | tablet    |
    | 1023  | desktop | tablet    |
    | 1024  | desktop | desktop   |
  # 근거: ERR-6b(flow-permutation §4) — 회귀 구간 1(480~767px)·회귀 구간 2
  # (800~1023px). GAP-5(최우선, Solutioning Gate D7 follow-up).
```

```gherkin
@migration @edge-case
Scenario: 한 파일 안에서 responsive_framework 와 coui_flutter 의 Breakpoint 를 동시에 import 하면 컴파일이 실패한다
  Given login_page.dart 가 아직 완전히 마이그레이션되지 않아 두 패키지를 모두 import 하려 시도한다
  Then 클래스명 충돌(Breakpoint)로 컴파일 에러가 발생하거나 prefix import 가 강제된다
  And 따라서 파일 단위 마이그레이션은 부분 적용이 아니라 원자적으로 수행해야 한다
  # 근거: GAP-3(flow-permutation §2(c)/§5) — Architecture §1.4 가 이미 구속력
  # 있는 제약으로 명문화한 "파일 단위 원자적 교체"의 실제 컴파일 실패 근거.
```

---

## Feature 6 — NG7: 값 분기 유틸리티 부재, tier 조회 결과로 직접 분기

> 근거: Seed Spec §2.2 NG7(최종 확정, 재도입하지 않음), Decision Log I-1/J-3, PRD §1.2/§1.3.

```gherkin
@ng7 @happy-path
Scenario: 개발자가 context.breakpointTier 조회 결과로 if 문을 사용해 직접 분기한다
  Given CoreBreakpointContract 는 context.responsive<T>(mobile:, tablet:, desktop:) 같은
    값 분기 유틸리티를 제공하지 않는다 (NG7, Phase 1 비목표로 최종 확정)
  When 개발자가 다음과 같이 tier 조회 결과를 if 문으로 직접 분기한다
    """
    if (context.breakpointTier == CoreBreakpointTier.desktop) {
      return const DesktopLayout();
    }
    return const MobileLayout();
    """
  Then 이 사용 형태는 공식 API(context.breakpointTier 조회)만으로 완전히 지원되는 정상 사용 패턴이다
  And 이를 위해 별도의 값 분기 유틸리티가 필요하지 않다
```

```gherkin
@ng7 @happy-path
Scenario: 개발자가 context.breakpointTier 조회 결과로 switch 문을 사용해 3-tier 분기를 구현한다
  Given CoreBreakpointContract 는 tier 조회 API 만 제공하고 값 분기 유틸리티는 제공하지 않는다
  When 개발자가 다음과 같이 switch 문으로 3-tier 각각에 대응하는 값/위젯을 직접 고른다
    """
    final columns = switch (context.breakpointTier) {
      CoreBreakpointTier.mobile => 1,
      CoreBreakpointTier.tablet => 2,
      CoreBreakpointTier.desktop => 3,
    };
    """
  Then 이 사용 형태 역시 공식 API 만으로 완전히 지원되는 정상 사용 패턴이다
  And CoUI 는 이 switch 분기 자체를 감싸는 별도 헬퍼(예: responsiveValue<T>)를 Phase 1 에서 제공하지 않는다
```

```gherkin
@ng7
Scenario: 값 분기 유틸리티(context.responsive<T>)는 Phase 1 API 표면에 존재하지 않는다
  Given PR-0 스캔 결과 트리거 프로젝트의 ResponsiveValue 실사용이 앱 셸 초기화 4곳(상수 반환에 가까운 단순 패턴)에 한정됐다
  And 실제 반복 패턴(largerThan() 8곳 + raw MediaQuery 비교 다수)은 전부 단순 tier 조회/비교였다
  When CoreBreakpointContract/Breakpoint/BuildContext extension 의 공개 API 표면을 확인한다
  Then context.responsive<T>(mobile:, tablet:, desktop:) 형태의 제네릭 값 분기 유틸리티는 존재하지 않는다
  And 이는 미구현이 아니라 최종 확정된 비목표(NG7)이며, 재도입 대상이 아니다
  # 근거: Decision Log I-1("재도입 여부 최종 판정 — 재도입하지 않음"), J-3
```

---

## 부록 — 시나리오 ↔ 요구사항 매핑 표

| Feature | 필수 시나리오 번호 | 대응 FR/NFR/SC | 대응 미해결 질문(Q) |
|---|---|---|---|
| 1. 기본 tier 판정 | 1 | FR-1, FR-2, SC-2 | Q1(경계값 자체는 예시) |
| 2. 크로스플랫폼 파리티 | 2 | FR-3, FR-4, SC-1, NFR-1, NFR-2 | Q4(멤버 네이밍) |
| 3. boundaries 부분 override | 3 | FR-5, NFR-7(c) | Q1(실제 착수 시점) |
| 4. 엣지케이스 | 4(마지막 시나리오는 `@needs-design-detail` — 자동화 보류) | NFR-7(a)(b)(c) | 없음 |
| 5. 실사용 마이그레이션 | 5 | FR-6, FR-10, SC-4 | Q1(레이아웃 분기점 이동) |
| 6. NG7 확인 | 6 | NG7(§2.2), FR-9 대체 근거 | 없음(재론 대상 아님) |

**미포함 범위(의도적)**: `context.responsive<T>` 값 분기 유틸리티의 자체 동작 검증(존재하지 않으므로 대상 아님), `ResponsiveRowColumn` 대응 컴포넌트(FR-9, `[후속]`), Q2(컴포넌트 분류)·Q3(장기 물리 통합)에 의존하는 docs_site 등록 시나리오(FR-7/FR-8 확정 전이므로 이 BDD 문서 범위 밖).
