import 'package:coui_web/coui_web.dart';

import '../previews/web_chain_registry.dart';
import '../previews/web_registry.dart';
import '../shared/chain_permutations.dart';
import '../shared/chain_shuffle_store.dart';
import '../shared/preview_constraints.dart';
import '../shared/preview_layout.dart';
import '../shared/preview_panel_id.dart';
import '../shared/docs_locale.dart';

/// Client-side component that hydrates Web previews for interactivity.
///
/// Mirrors [FlutterPreview] pattern — a single `@client` entry point
/// that wraps all Web component previews with [Theme] context inside
/// a constraints container matching Flutter's [FlutterEmbedView].
@client
class WebPreview extends StatelessComponent {
  const WebPreview({required this.component, this.variant, this.panelId, this.chainStep, super.key});

  final String component;
  final String? variant;
  final String? panelId;
  final int? chainStep;

  @override
  Component build(BuildContext context) =>
      WebPreviewContent(component: component, variant: variant, panelId: panelId, chainStep: chainStep);
}

/// Preview content for composition inside an existing client island.
class WebPreviewContent extends StatelessComponent {
  const WebPreviewContent({
    required this.component,
    this.variant,
    this.panelId,
    this.chainStep,
    this.fitContent = false,
    super.key,
  });

  final String component;
  final String? variant;

  /// chain 패널의 인스턴스-유일 id — SSG(`live_preview.dart`)가 부여한다.
  /// non-chain 프리뷰는 null (기존 `component-variant` id 파생 유지).
  final String? panelId;

  /// chain 순열을 **고정 step** 으로 렌더한다 — 스토어 구독 없는 정적 경로.
  ///
  /// 네이티브 docs_app 의 WebView 페인이 쓰는 경로다: WebView 안에는 Dart
  /// 힙이 없어 스토어 직결이 불가능하므로, 호스트(Flutter)가 step 을 들고
  /// HTML 을 다시 렌더한다. [panelId] 와 배타적 — 브라우저(hydrated) 경로는
  /// panelId 구독, 문자열-렌더 경로는 chainStep 고정.
  final int? chainStep;

  /// 내용 높이로 그린다 — 컴포넌트 페이지(v2)의 무대 안에서 쓴다.
  ///
  /// 기본(`false`)은 Flutter 팬과 같은 높이의 판이다: `<LivePreview>` 는 두
  /// 팬을 나란히 놓으므로 높이가 같아야 한다. v2 무대는 Web 만 그리고 무대가
  /// 자기 여백을 가지므로, 그 높이를 그대로 쓰면 내용 아래에 빈 판이 남는다.
  /// 그래서 높이를 정하지 않고, 폭을 채우는 예제([docsPreviewFillsWidth])는
  /// 가운데 정렬된 무대에서도 폭을 채우게 이 상자가 무대 폭을 차지한다.
  final bool fitContent;

  @override
  Component build(BuildContext context) {
    final builder = kWebPreviewRegistry[component];
    if (builder == null) {
      return div(
        classes: 'preview-unavailable',
        [Component.text('Preview not available for "$component"')],
      );
    }

    // Web 팬·Flutter 팬이 같은 조회 함수를 쓴다 — per-variant 우선 +
    // chain 하한(2-인스턴스 예제 클리핑 방지)까지 포함한 단일 출처.
    final constraints = docsPreviewConstraintsFor(component, variant);

    // chain 패널(T1)은 셔플 스토어를 구독하는 순열 뷰로 — 그 외는 registry
    // 빌더 그대로. 렌더러가 없는 chain(T2/T3)은 registry 빌더가 chain
    // 예제를 정적으로 그린다 (버튼도 SSG 미렌더 — 계약 그대로).
    // chainStep 고정 경로(네이티브 WebView)는 구독 없이 그 좌표를 그린다.
    final chainRenderer = variant == 'chain' && (panelId != null || chainStep != null)
        ? kWebChainRegistry[component]
        : null;
    final content = chainRenderer == null
        ? builder(context, variant)
        : chainStep != null
        ? chainRenderer(chainPermutationAt(chainStep!))
        : _ChainPermutationView(panelId: panelId!, renderer: chainRenderer);

    return div(
      id: webPreviewElementId(
        component: component,
        variant: variant,
        panelId: panelId,
      ),
      // Headings at their desktop size, whatever the window: the pane shows
      // a component as authored, beside a Flutter pane pinned the same way.
      // The pin is this element's own attribute — the rule
      // `TypographyTierScope` relies on, on an element the pane already
      // has — rather than `CoUIWeb.typographyTier`, which would pin the docs
      // page's own `<html>`, or a scope wrapper, which would come between
      // this element and the `CoUIWeb` root the preview CSS selects as its
      // direct child. The overlay host and every panel a preview opens into
      // it are inside this element too.
      attributes: {kTypographyTierAttribute: CoreBreakpointTier.desktop.name},
      styles: fitContent
          ? Styles(raw: {if (docsPreviewFillsWidth(component, variant)) 'width': '100%', 'min-width': '0'})
          : Styles.combine([
              // The same stage the Flutter pane sits on: its view is created
              // with these constraints and resolves to `maxHeight` because the
              // app root fills its view. A fixed `height` (not a `max-height`
              // cap) keeps the Web pane from shrinking to its content, so the
              // two panes come out the same height by construction — why the
              // stage is a tier and not a measurement is written down in
              // `shared/preview_constraints.dart`.
              if (constraints.maxHeight != double.infinity)
                Styles(raw: {'height': '${constraints.maxHeight.toInt()}px'}),
              // `clip` (not `hidden`) as a last-resort height cap — content
              // should normally fit inside the stage (Web side flows naturally
              // without internal scroll). `overflow-clip-margin` lets a component's
              // drop-shadow / elevation paint just past the content box instead
              // of being clipped flush to its edges (e.g. the Hover / Card
              // shadow). Avoid `overflow-y: auto` here so the preview doesn't
              // race scroll gestures with the embedded Flutter view. Degrades
              // to an edge clip on browsers without `overflow-clip-margin`.
              Styles(raw: {'overflow': 'clip', 'overflow-clip-margin': '2.5rem'}),
            ]),
      [
        // `CoUIWeb` mirrors Flutter's `UiApp` — provides `Theme` +
        // applies base typography (`bodyMedium` + `onSurface` + `font-sans`)
        // on a wrapper `<div>`. This restricts CoUI base typography to
        // the preview surface so docs body markup is unaffected.
        CoUIWeb(
          theme: ThemeData.coui,
          locale: const Locale(kDocsLanguageCode),
          child: content,
        ),
      ],
    );
  }
}

/// chain 패널의 Web 팬 — 셔플 스토어를 구독해 현재 step 의 순열을 그린다.
///
/// jaspr 는 SSG 중에도 `initState` 를 실행하지만 스토어의 리스너 등록이
/// 서버 경로 no-op 이라 정적 빌드는 언제나 step 0(base 순열)을 그린다.
class _ChainPermutationView extends StatefulComponent {
  const _ChainPermutationView({required this.panelId, required this.renderer});

  final String panelId;
  final WebChainRenderer renderer;

  @override
  State<_ChainPermutationView> createState() => _ChainPermutationViewState();
}

class _ChainPermutationViewState extends State<_ChainPermutationView> {
  @override
  void initState() {
    super.initState();
    chainShuffleStore.addListener(component.panelId, handleChainStep);
  }

  @override
  void dispose() {
    chainShuffleStore.removeListener(component.panelId, handleChainStep);
    super.dispose();
  }

  void handleChainStep() {
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    final step = chainShuffleStore.stepOf(component.panelId);
    return component.renderer(chainPermutationAt(step));
  }
}
