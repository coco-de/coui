/// 라이브 프리뷰 패널 — jaspr 의 `.live-preview` 를 네이티브로 옮긴 것.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/preview/flutter_pane.dart';
import 'package:docs_app/src/preview/preview_identity.dart';
import 'package:docs_app/src/preview/web_pane.dart';
import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:docs_core/shared/preview_layout.dart';

/// 코드 탭의 순서 — 탭 인덱스와 [DocsPreviewPlatform] 을 잇는 단일 출처.
///
/// `DocsPreviewPlatform.values` 를 인덱스로 찌르지 않는다: enum 선언 순서와
/// 탭 순서가 우연히 같을 뿐이라, 나중에 값을 하나 끼워 넣으면 탭이 조용히
/// 엉뚱한 코드를 보여준다.
const List<DocsPreviewPlatform> _kCodeTabs = [
  DocsPreviewPlatform.web,
  DocsPreviewPlatform.flutter,
];

/// Web | Flutter 프리뷰를 나란히 놓고 아래에 코드 탭을 붙인 패널.
///
/// 컴포넌트가 `kDocsWideComponents` 에 있으면 두 페인을 좌우가 아니라
/// 위아래로 쌓는다 — 절반 너비에서 글자 단위로 줄바꿈되는 넓은 컴포넌트들이
/// 각 플랫폼에 셀 전체 너비를 받게 하려는 것.
class DocsLivePreview extends StatefulWidget {
  /// [component] (+선택적 [variant]) 의 라이브 프리뷰 패널을 만든다.
  const DocsLivePreview({
    required this.component,
    this.variant,
    this.panelId,
    super.key,
  });

  /// 프리뷰할 컴포넌트 슬러그 (예: `button`).
  final String component;

  /// 프리뷰할 변형 (예: `primary`). 없으면 기본 프리뷰.
  final String? variant;

  /// chain 패널의 인스턴스-유일 id — 갤러리가 부여한다. non-chain 은 null.
  ///
  /// 값이 있으면 이 패널은 셔플 스토어를 구독한다: advance 마다 Flutter
  /// 페인(순열 렌더러 좌표)·Web 페인(고정-step HTML 재렌더)·코드 스니펫
  /// (base 위 getter-토큰 치환)이 함께 갱신된다 — jaspr 쪽에서 세 표면이
  /// 각자 구독/치환하던 것을 네이티브는 이 State 하나가 담당한다.
  final String? panelId;

  @override
  State<DocsLivePreview> createState() => _DocsLivePreviewState();
}

class _DocsLivePreviewState extends State<DocsLivePreview> {
  /// 코드 탭에서 지금 보고 있는 플랫폼.
  DocsPreviewPlatform _codeTab = .web;

  bool get _isChainPanel => widget.variant == 'chain' && widget.panelId != null;

  /// 현재 순열 좌표 — chain 패널이 아니면 null.
  ChainPermutation? get _chainPermutation => _isChainPanel
      ? chainPermutationAt(chainShuffleStore.stepOf(widget.panelId!))
      : null;

  @override
  void initState() {
    super.initState();
    if (_isChainPanel) {
      chainShuffleStore.addListener(widget.panelId!, handleChainStep);
    }
  }

  @override
  void dispose() {
    if (_isChainPanel) {
      chainShuffleStore.removeListener(widget.panelId!, handleChainStep);
    }
    super.dispose();
  }

  void handleChainStep() {
    setState(() {});
  }

  /// chain 패널이면 pristine base 스니펫 위 getter-토큰 치환 — registry 가
  /// 항상 base 를 주므로 (jaspr 처럼 DOM 캡처가 필요 없다) 누적 오염이 없다.
  /// 치환 어휘 밖 스니펫(T2/T3)은 fail-safe 로 원문이 돌아온다.
  String _substituted(String code) {
    final permutation = _chainPermutation;
    if (permutation == null) return code;
    return substituteChainTokens(code, permutation);
  }

  /// Web 코드 스니펫. 등록이 없으면 안내 주석.
  String get _webCode {
    final builder = kCodeSnippetRegistry[widget.component];
    if (builder == null) return '// No code example available';
    return _substituted(builder(widget.variant));
  }

  /// Flutter 코드 스니펫.
  ///
  /// Flutter 전용 스니펫이 없으면 Web 스니펫으로 떨어진다 — docs_site 와
  /// 같은 폴백이다.
  String get _flutterCode {
    final builder = kFlutterCodeSnippetRegistry[widget.component];
    if (builder == null) return _webCode;
    return _substituted(builder(widget.variant));
  }

  void handleCodeTabChanged(int index) {
    setState(() => _codeTab = _kCodeTabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;
    final stacked = kDocsWideComponents.contains(widget.component);

    return Padding(
      // `.live-preview { margin: 1.5rem 0 }`.
      padding: const .symmetric(vertical: CoreSpace.space24),
      child: OutlinedContainer(
        containerStyle: CoreOutlinedContainerStyle(
          borderColor: borderColor,
          borderRadius: const CoreBorderRadius.all(CoreRadius.radius8),
          borderWidth: CoreStrokeWidth.stroke1,
          clipBehavior: .antiAlias,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            _PreviewContainer(
              component: widget.component,
              variant: widget.variant,
              stacked: stacked,
              chainStep: _isChainPanel
                  ? chainShuffleStore.stepOf(widget.panelId!)
                  : null,
              chainPermutation: _chainPermutation,
            ),
            // `.preview-code { border-top: 1px solid … }`.
            const Divider(),
            _CodeSection(
              onChanged: handleCodeTabChanged,
              selected: _codeTab,
              code: _codeTab == .web ? _webCode : _flutterCode,
            ),
          ],
        ),
      ),
    );
  }
}

/// 두 페인을 좌우로 놓거나(기본) 위아래로 쌓는 컨테이너.
///
/// 원본에서 jaspr 은 이걸 1px `gap` 을 가진 2-열 그리드로 그리고, 그 틈으로
/// 보이는 배경이 곧 구분선이다. 네이티브에서는 그 틈을 [Divider] 로 명시한다.
class _PreviewContainer extends StatelessWidget {
  const _PreviewContainer({
    required this.component,
    required this.variant,
    required this.stacked,
    this.chainStep,
    this.chainPermutation,
  });

  final String component;
  final String? variant;
  final bool stacked;

  /// chain 셔플의 현재 step / 좌표 — non-chain 은 둘 다 null. 같은 상태의
  /// 두 표현을 나란히 나르는 이유: Web 페인은 HTML 재렌더 키로 정수 step
  /// 을, Flutter 페인은 렌더러 입력으로 해석된 좌표를 받는다.
  final int? chainStep;
  final ChainPermutation? chainPermutation;

  @override
  Widget build(BuildContext context) {
    // 두 페인이 같은 높이를 쓰게 한다 — 그래야 세로로 정렬되고, 세로 구분선도
    // 높이를 갖는다. WebView 는 콘텐츠에 맞춰 자랄 수 없어 명시 높이가 필요하고,
    // 네이티브 페인도 같은 높이를 쓰면 두 컴포넌트가 같은 y 에서 시작한다.
    // 사이트의 Web 페인이 쓰는 티어 maxHeight 와 같은 값이라 파리티도 유지된다.
    final previewHeight = docsPreviewConstraintsFor(
      component,
      variant,
    ).maxHeight;

    final web = _PreviewPane(
      platform: .web,
      previewHeight: previewHeight,
      child: DocsWebPane(
        component: component,
        variant: variant,
        chainStep: chainStep,
      ),
    );
    final flutter = _PreviewPane(
      platform: .flutter,
      previewHeight: previewHeight,
      child: DocsFlutterPane(
        component: component,
        variant: variant,
        chainPermutation: chainPermutation,
      ),
    );

    if (stacked) {
      return Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [web, const Divider(), flutter],
      );
    }

    // IntrinsicHeight 로 Row 높이를 확정한다 — `crossAxisAlignment: stretch`
    // 와 세로 구분선은 높이가 유한해야 하는데, 세로 스크롤 안에서는 높이가
    // 무한이라 확정이 필요하다. 각 페인이 SizedBox(previewHeight) 로 유한한
    // 내부 높이를 가지므로, IntrinsicHeight 가 WebView 의 intrinsic 을 직접
    // 재지 않아 (그게 예전 오버플로우 원인이었다) 안전하다. 없애면 Row 의
    // stretch 가 무한 높이에서 풀리지 않아 LivePreview 높이가 깨지고, 부모
    // 마크다운 Column 의 이후 블록들이 전부 겹쳐 그려진다.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(child: web),
          const Divider(orientation: .vertical),
          Expanded(child: flutter),
        ],
      ),
    );
  }
}

/// 라벨 + 프리뷰 내용을 담은 페인 하나 (`.preview-pane`).
class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.platform,
    required this.previewHeight,
    required this.child,
  });

  final DocsPreviewPlatform platform;

  /// 프리뷰 영역의 고정 높이 — 두 페인이 같은 값을 써 정렬된다.
  final double previewHeight;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 프리뷰 영역에 고정 높이를 준다 — 두 페인이 같은 높이라 정렬되고,
    // IntrinsicHeight 없이도 오버플로우가 안 난다.
    //
    // ClipRect 로 감싸지 않는다: Android 의 WebView 는 하이브리드 컴포지션
    // 플랫폼 뷰라, ClipRect 로 감싸면 컴포지팅이 깨져 페이지 전체 렌더가
    // 어긋난다(형제 블록들이 겹쳐 그려짐). 티어는 콘텐츠에 맞게 고르므로
    // 고정 높이만으로 넘칠 일이 거의 없다.
    return Padding(
      padding: const .all(CoreSpace.space24),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          _PreviewLabel(platform: platform),
          const Gap.space12(),
          SizedBox(height: previewHeight, child: child),
        ],
      ),
    );
  }
}

/// 점 + 대문자 라벨 (`.preview-label`).
class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({required this.platform});

  final DocsPreviewPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _PlatformDot(platform: platform),
        const Gap.space6(),
        Text(
          platform.label.toUpperCase(),
        ).labelSmall.semiBold.wide.onSurfaceVariant,
      ],
    );
  }
}

/// 플랫폼 정체성을 나타내는 6px 원형 점 (`.preview-label-dot`).
class _PlatformDot extends StatelessWidget {
  const _PlatformDot({required this.platform});

  final DocsPreviewPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: platform.dotColor.toValue(),
        shape: .circle,
      ),
      width: CoreSize.size6,
      height: CoreSize.size6,
    );
  }
}

/// Web / Flutter 탭과 그 아래 활성 코드 패널 (`.preview-code`).
class _CodeSection extends StatelessWidget {
  const _CodeSection({
    required this.selected,
    required this.onChanged,
    required this.code,
  });

  final DocsPreviewPlatform selected;
  final ValueChanged<int> onChanged;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const .symmetric(
            vertical: CoreSpace.space8,
            horizontal: CoreSpace.space16,
          ),
          child: Align(
            alignment: .centerLeft,
            child: Tabs(
              onChanged: onChanged,
              tabs: [
                for (final platform in _kCodeTabs)
                  CoreTabItem<Widget>(label: platform.label),
              ],
              selectedIndex: _kCodeTabs.indexOf(selected),
              // 코드 패널은 탭 자체가 아니라 이 위젯이 갈아끼우므로,
              // 가로 스와이프로 탭이 넘어가면 패널만 바뀌어 혼란스럽다.
              swipeable: false,
            ),
          ),
        ),
        const Divider(),
        // 복사 버튼은 CodeSnippet 이 자체로 들고 있다 — jaspr 헤더의
        // `.preview-copy-btn` 과 같은 자리를 차지한다.
        CodeSnippet(code: code, mode: 'dart'),
      ],
    );
  }
}
